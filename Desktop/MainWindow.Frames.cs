using System.IO;
using System.Windows;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Exact paused frames (0.10.2, speed): FFmpeg seeks instead of decoding from the start, decodes a
// short run of neighbouring frames in one pass, and keeps them (as PNG bytes, in memory only) so
// stepping and scrubbing over them is immediate. While stepping, the next run is loaded ahead.
// Every frame shown is still the exact frame chosen by its presentation timestamp.
public partial class MainWindow
{
    internal const int FrameWindow = 12;
    private readonly FrameCache frameCache = new();
    private CancellationTokenSource? prefetchWork;
    private double? pendingSeek, scrubTarget;
    private bool scrubbing;

    // Slider drags: show each frame as soon as the previous one is on screen, always heading for
    // the latest slider position, instead of waiting for the drag to stop.
    private async void SeekChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (updating || busy || Project.Media?.IsVideo != true) return;
        Pause(); scrubTarget = e.NewValue;
        if (scrubbing) return;
        scrubbing = true;
        try { while (scrubTarget is { } target) { scrubTarget = null; await SeekExact(target); } }
        finally { scrubbing = false; }
    }
    // Quick repeated steps count from the frame already asked for, not the one still on screen.
    private async Task Step(int delta)
    {
        if (busy || Preview.Timeline is not { } map) return;
        Pause();
        var from = map.IndexAt(pendingSeek ?? Time);
        await SeekExact(map.Frames[Math.Clamp(from + delta, 0, map.Frames.Count - 1)].Time, Math.Sign(delta));
    }
    private Task<bool> SeekExact(double seconds) => SeekExact(seconds, 1);
    private async Task<bool> SeekExact(double seconds, int direction)
    {
        if (Project.Media is not { IsVideo: true } m || Preview.Timeline is not { } map) return false;
        seekWork?.Cancel(); var request = new CancellationTokenSource(); seekWork = request;
        UpdateEditingState();
        var index = map.IndexAt(seconds); var frame = map.Frames[index];
        pendingSeek = frame.Time;
        try
        {
            BitmapSource bitmap;
            if (frameCache.TryGet(m.Sha256, frame.Pts, out var cached)) bitmap = await Task.Run(() => MediaTools.DecodePng(cached), request.Token);
            else
            {
                // A run of frames costs little more than one (FFmpeg decodes from the previous keyframe either way;
                // probed on a phone video in 0.21.2), so the neighbours come along.
                await Task.Delay(30, request.Token);
                var window = WindowAround(map, index, direction);
                var pngs = await Task.Run(() => tools.FramePngsAsync(m.Path, window, null, request.Token), request.Token);
                for (var i = 0; i < window.Count; i++) frameCache.Add(m.Sha256, window[i].Pts, pngs[i]);
                var png = pngs[window.IndexOf(frame)];
                bitmap = await Task.Run(() => MediaTools.DecodePng(png), request.Token);
            }
            if (request.IsCancellationRequested || closing) return false;
            Preview.UsePlayer = false; Preview.Image = bitmap; Preview.Time = frame.Time; Preview.Player.Position = TimeSpan.FromSeconds(frame.Time); UpdateClock(); Refresh(); Hint("Exact source-frame inspection · Adjust the redaction or track it from here.");
            Prefetch(m, map, index, direction == 0 ? 1 : direction);
            return true;
        }
        catch (OperationCanceledException) { return false; }
        catch (Exception ex) { if (!closing) Status.Text = "Frame inspection failed: " + SafeError(ex); return false; }
        finally { if (ReferenceEquals(seekWork, request)) { seekWork = null; pendingSeek = null; } request.Dispose(); if (!closing) UpdateEditingState(); }
    }
    // FrameWindow consecutive frames containing index, mostly in the direction of travel.
    internal static List<FrameStamp> WindowAround(FrameTimeline map, int index, int direction)
    {
        var before = direction < 0 ? FrameWindow - 3 : 2;
        var first = Math.Clamp(index - before, 0, Math.Max(0, map.Frames.Count - FrameWindow));
        return map.Frames.Skip(first).Take(FrameWindow).ToList();
    }
    // Loads the next run in the background when one of the next few frames isn't ready yet.
    private void Prefetch(MediaReference m, FrameTimeline map, int index, int direction, bool whileLoading = false)
    {
        if (prefetchWork is { IsCancellationRequested: false } || busy && !whileLoading || closing) return;
        var missing = Enumerable.Range(1, 4).Select(i => index + i * direction).Where(i => i >= 0 && i < map.Frames.Count)
            .FirstOrDefault(i => !frameCache.Contains(m.Sha256, map.Frames[i].Pts), -1);
        if (missing < 0) return;
        var start = direction > 0 ? missing : Math.Max(0, missing - FrameWindow + 1);
        var window = map.Frames.Skip(start).Take(FrameWindow).ToList();
        var work = new CancellationTokenSource(); prefetchWork = work;
        var token = work.Token;
        _ = Task.Run(async () =>
        {
            try
            {
                var pngs = await tools.FramePngsAsync(m.Path, window, null, token);
                for (var i = 0; i < window.Count; i++) frameCache.Add(m.Sha256, window[i].Pts, pngs[i]);
            }
            // Loading ahead is only a convenience: a failure here leaves the normal path to try again.
            catch (Exception ex) when (ex is OperationCanceledException or IOException or InvalidDataException) { }
            finally { _ = Dispatcher.BeginInvoke(() => { if (ReferenceEquals(prefetchWork, work)) prefetchWork = null; work.Dispose(); }); }
        });
    }
    private void StopFrameWork() { thumbnails.Cancel(); prefetchWork?.Cancel(); }
    internal bool FrameReady(int index) => Project.Media is { } m && Preview.Timeline is { } map && index < map.Frames.Count && frameCache.Contains(m.Sha256, map.Frames[index].Pts);
}
