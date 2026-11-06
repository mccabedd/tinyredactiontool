using System.Globalization;
using System.IO;
using System.Text;
using System.Windows;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Trim Video and Append Video (0.20.0, David). The approved FFmpeg cannot renumber timestamps (no
// setpts), so every piece that stays is encoded as its own segment with an exact output start and
// length (picture lossless, sound AAC, cut at the same moments so it stays in step), and the segments
// are joined with the concat demuxer without re-encoding. The result must have exactly the expected
// number of frames, or nothing changes. It is a working copy in TRT's private folder; the original file
// is never changed. Redactions and annotations follow their frames.
public partial class MainWindow
{
    // The trim row above the timeline is shown by the toolbar's Trim button (0.21.0, David) and hidden by it again.
    private void ToggleTrimRow(object sender, RoutedEventArgs e) => ShowTrimRow(TrimRow.Visibility != Visibility.Visible);
    internal bool TrimRowShown => TrimRow.Visibility == Visibility.Visible;
    internal void ShowTrimRow(bool show)
    {
        if (show && (busy || Project.Media?.IsVideo != true)) return;
        TrimRow.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
        TrimToolButton.SetResourceReference(BackgroundProperty, show ? "ToolSelected" : "Surface");
        TrimToolButton.SetResourceReference(ForegroundProperty, show ? "ToolSelectedText" : "Foreground");
        if (Project.Media != null) DrawRanges();
    }
    // Trim markers: frame indices on the current video's timeline.
    internal int? MarkerA { get; private set; }
    internal int? MarkerB { get; private set; }
    private void SetMarkerA(object sender, RoutedEventArgs e) => SetMarker(true);
    private void SetMarkerB(object sender, RoutedEventArgs e) => SetMarker(false);
    internal void SetMarker(bool a)
    {
        if (Preview.Timeline is not { } map || Project.Media?.IsVideo != true) return;
        var frame = map.IndexAt(Time);
        if (a) MarkerA = frame; else MarkerB = frame;
        UpdateTrimUi(); DrawRanges();
    }
    private void ClearMarkers(object sender, RoutedEventArgs e) { MarkerA = MarkerB = null; UpdateTrimUi(); DrawRanges(); }
    private (int First, int Last)? MarkedFrames => MarkerA is { } a && MarkerB is { } b ? (Math.Min(a, b), Math.Max(a, b)) : null;
    private void UpdateTrimUi()
    {
        if (TrimText == null) return;
        var map = Preview.Timeline;
        string At(int? frame) => frame is { } f && map != null && f < map.Frames.Count ? TimeSpan.FromSeconds(map.Frames[f].Time).ToString(@"hh\:mm\:ss\.fff") : "–";
        var marked = MarkedFrames;
        TrimText.Text = $"A {At(MarkerA)}   B {At(MarkerB)}" + (marked is { } m ? $"   ({m.Last - m.First + 1} frames between)" : "");
        DeleteSelectionButton.IsEnabled = !busy && marked != null && captures != null;
        DeleteSelectionButton.Content = DeletesBetween ? "Delete A–B" : "Retain A–B";
        DeleteSelectionButton.ToolTip = DeletesBetween ? "Delete the Frames from A to B" : "Delete Everything Outside A–B";
    }
    // 0.22.0 (David): Retain A–B (keep only A–B) is the default; Invert switches to Delete A–B.
    internal bool DeletesBetween => InvertTrimBox.IsChecked == true;
    private void TrimOptionChanged(object sender, RoutedEventArgs e) { UpdateTrimUi(); if (Project.Media != null) DrawRanges(); }
    private async void DeleteSelection(object sender, RoutedEventArgs e) => await TrimAsync(!DeletesBetween);
    // invert = false: delete the frames A..B; true: keep only A..B.
    internal async Task<bool> TrimAsync(bool invert)
    {
        if (busy || closing || Project.Media is not { IsVideo: true } media || Preview.Timeline is not { } map || MarkedFrames is not { } marked) return false;
        if (captures == null) { Status.Text = "Trimming needs the capture part of TRT, which is not running."; return false; }
        var keep = Enumerable.Range(0, map.Frames.Count).Where(i => invert ? i >= marked.First && i <= marked.Last : i < marked.First || i > marked.Last).ToList();
        if (keep.Count == 0) { Status.Text = "That would delete every frame. Choose a smaller part."; return false; }
        if (keep.Count == map.Frames.Count) return false;
        // The pieces to keep, as runs of frames.
        var runs = new List<(int First, int Last)>();
        foreach (var i in keep) { if (runs.Count > 0 && runs[^1].Last == i - 1) runs[^1] = (runs[^1].First, i); else runs.Add((i, i)); }
        Pause();
        var done = await ReplaceVideoAsync(async (token, store) =>
        {
            var offset = await StartOffsetAsync(media.Path, map, token);
            var audio = await HasAudioAsync(media.Path, token);
            var segments = new List<string>();
            for (var r = 0; r < runs.Count; r++)
            {
                ReportWork(r / (double)(runs.Count + 1), $"Cutting piece {r + 1} of {runs.Count}");
                segments.Add(await EncodeSegmentAsync(media.Path, map, runs[r].First, runs[r].Last, offset, audio, null, store, token));
            }
            return (segments, audio);
        }, project =>
        {
            var position = new Dictionary<int, int>(); for (var k = 0; k < keep.Count; k++) position[keep[k]] = k;
            return (map, i => position.TryGetValue(i, out var at) ? at : null, keep.Count);
        }, "Trimming the Video");
        if (done)
        {
            MarkerA = MarkerB = null; UpdateTrimUi();
            Status.Text = invert ? $"Kept frames {marked.First + 1}–{marked.Last + 1} only." : $"Deleted frames {marked.First + 1}–{marked.Last + 1}." + " Redactions and annotations moved with their frames; the original file is unchanged.";
        }
        return done;
    }

    // ---- Append video ----
    internal Func<(string Path, bool AtStart)?>? AppendQuestion { get; set; } // Checks answer without dialogs.
    private async void AppendVideo(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Media is not { IsVideo: true }) return;
        (string Path, bool AtStart)? choice = AppendQuestion?.Invoke();
        if (choice == null && AppendQuestion == null)
        {
            var dialog = new Microsoft.Win32.OpenFileDialog { Filter = "Videos|" + string.Join(";", ExplorerMenu.Extensions.SkipWhile(x => x != ".mp4").Select(x => "*" + x)), AddToRecent = false, Title = "Choose a Video to Add" };
            if (dialog.ShowDialog(this) != true) return;
            var answer = ThemedMessage.Show(this, $"Add {Path.GetFileName(dialog.FileName)} at the end of this video?\n\nYes: at the end.   No: at the beginning.", "Append Video", MessageBoxButton.YesNoCancel, MessageBoxImage.Question);
            if (answer == MessageBoxResult.Cancel) return;
            choice = (dialog.FileName, answer == MessageBoxResult.No);
        }
        if (choice is { } c) await AppendAsync(c.Path, c.AtStart);
    }
    internal async Task<bool> AppendAsync(string other, bool atStart)
    {
        if (busy || closing || Project.Media is not { IsVideo: true } media || Preview.Timeline is not { } map) return false;
        if (captures == null) { Status.Text = "Appending needs the capture part of TRT, which is not running."; return false; }
        if (!File.Exists(other)) { Status.Text = "That video no longer exists."; return false; }
        Pause();
        FrameTimeline? otherMap = null;
        var done = await ReplaceVideoAsync(async (token, store) =>
        {
            otherMap = await Task.Run(() => tools.ProbeTimelineAsync(other, token), token);
            var otherFrame = await Task.Run(() => tools.FrameAsync(other, otherMap.Frames[0], null, token), token);
            // Both parts end up the size of the open video; the added one is scaled if it has the same shape.
            if (Math.Abs((double)otherFrame.PixelWidth / otherFrame.PixelHeight - (double)media.Width / media.Height) > 0.01)
                throw new InvalidDataException($"The videos are different shapes ({media.Width} × {media.Height} and {otherFrame.PixelWidth} × {otherFrame.PixelHeight}). Append needs the same shape. Nothing was changed.");
            var audio = await HasAudioAsync(media.Path, token) && await HasAudioAsync(other, token);
            var size = (media.Width, media.Height);
            ReportWork(0.1, "Preparing the Open Video");
            var mine = await EncodeSegmentAsync(media.Path, map, 0, map.Frames.Count - 1, await StartOffsetAsync(media.Path, map, token), audio, size, store, token);
            ReportWork(0.5, "Preparing the Added Video");
            var theirs = await EncodeSegmentAsync(other, otherMap, 0, otherMap.Frames.Count - 1, await StartOffsetAsync(other, otherMap, token), audio, size, store, token);
            return (atStart ? new List<string> { theirs, mine } : [mine, theirs], audio);
        }, project =>
        {
            var shift = atStart ? otherMap!.Frames.Count : 0;
            return (map, i => i + shift, map.Frames.Count + otherMap!.Frames.Count);
        }, "Adding a Video");
        if (done) Status.Text = $"Added {Path.GetFileName(other)} at the {(atStart ? "beginning" : "end")}. Redactions and annotations stay on their frames; the original files are unchanged.";
        return done;
    }

    // ---- Shared: encode pieces, join them, load the result, move the work to the new frames ----
    // makeSegments returns the segment files (in order) and whether they carry sound; plan gives the old map,
    // where each old frame went (null = deleted) and the expected frame count of the result.
    private async Task<bool> ReplaceVideoAsync(Func<CancellationToken, CaptureStore, Task<(List<string> Segments, bool Audio)>> makeSegments,
        Func<RedactionProject, (FrameTimeline Old, Func<int, int?> NewIndex, int Expected)> plan, string title)
    {
        var store = captures!.Store; var media = Project.Media!;
        var made = new List<string>(); string? result = null; var done = false; var droppedSound = false; var before = ProjectStore.Serialize(Project);
        await RunWork(async token =>
        {
            var (segments, audio) = await makeSegments(token, store); made.AddRange(segments);
            droppedSound = !audio && await HasAudioAsync(media.Path, token);
            var list = store.NewFile("EDITED", ".txt"); made.Add(list);
            File.WriteAllText(list, string.Concat(segments.Select(s => $"file '{Path.GetFileName(s)}'\n")), new UTF8Encoding(false));
            result = store.NewFile("EDITED", ".mp4");
            ReportWork(0.9, "Joining the Pieces");
            await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-f", "concat", "-i", list, "-map", "0", "-c", "copy", "-fps_mode", "passthrough", "-map_metadata", "-1", result], media.Path, token);
            var project = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
            var (oldMap, newIndex, expected) = plan(project);
            var newMap = await Task.Run(() => tools.ProbeTimelineAsync(result, token), token);
            if (newMap.Frames.Count != expected) throw new InvalidDataException($"The new video has {newMap.Frames.Count} frames instead of {expected}. Nothing was changed.");
            MoveWorkToFrames(project, oldMap, newMap, newIndex);
            token.ThrowIfCancellationRequested();
            var hash = await ProjectStore.HashAsync(result, token);
            project.Media = media with { Path = result, Length = new FileInfo(result).Length, Sha256 = hash, Duration = newMap.Frames[^1].Time + newMap.Frames[^1].Duration };
            await LoadMedia(result, project, token, keepHistory: true);
            done = true;
        }, "Cancelled. Nothing was changed.", title);
        // The pieces are never needed again; a failed result is wiped too.
        foreach (var file in made) if (store.Owns(file)) ReleaseCapture(file);
        if (!done && result != null && store.Owns(result) && Project.Media?.Path != result) ReleaseCapture(result);
        if (done) { savedSnapshot = null; history.Checkpoint(before); } // Undo goes back to the video before (0.21.0).
        if (done && droppedSound) Status.Text = "Only one of the videos has sound, so the result has none.";
        return done;
    }
    // One run of frames as its own file, picture lossless and sound AAC. It starts half a millisecond
    // before its first frame (so rounding never drops it), takes exactly its frames (-frames:v) and cuts
    // the sound to the same length, so the joined result has no gaps and the sound stays in step.
    // (Tried on the test media: starting between frames left an empty lead and a visible gap.)
    // size scales it (Append) and fixes the format.
    private async Task<string> EncodeSegmentAsync(string source, FrameTimeline map, int first, int last, double offset, bool audio, (int Width, int Height)? size, CaptureStore store, CancellationToken token)
    {
        var span = map.Frames[last].Time + Math.Max(map.Frames[last].Duration, 0.001) - map.Frames[first].Time;
        var segment = store.NewFile("EDITED", ".mp4");
        var args = new List<string> { "-v", "error", "-y", "-i", source };
        // Always start at the piece's first frame (0.22.0): David's MKVs start their sound 0.12 s before the
        // picture, and without a start the length (-t) counted from the sound cut the last 3 frames off.
        var start = map.Frames[first].Time + offset - 0.0005;
        if (start > 0) args.AddRange(["-ss", Seconds(start)]);
        args.AddRange(["-frames:v", (last - first + 1).ToString(CultureInfo.InvariantCulture), "-t", Seconds(span), "-map", "0:v:0"]);
        if (audio) args.AddRange(["-map", "0:a:0"]);
        if (size is { } s) args.AddRange(["-vf", $"scale={s.Width}:{s.Height}"]);
        args.AddRange(["-c:v", "libx264", "-qp", "0", "-preset", "ultrafast", "-pix_fmt", "yuv420p", "-fps_mode", "passthrough", "-video_track_timescale", "90000"]);
        if (audio) args.AddRange(["-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2"]);
        args.AddRange(["-map_metadata", "-1", "-map_chapters", "-1", segment]);
        await tools.RunAsync("ffmpeg.exe", args, source, token);
        return segment;
    }
    private static string Seconds(double value) => Math.Max(0, value).ToString("0.000000", CultureInfo.InvariantCulture);
    // Frame times count from the first video frame; FFmpeg's cut positions count from the start of the file.
    private async Task<double> StartOffsetAsync(string path, FrameTimeline map, CancellationToken token)
    {
        var text = Encoding.UTF8.GetString(await tools.RunAsync("ffprobe.exe", ["-v", "error", "-show_entries", "format=start_time", "-of", "csv=p=0", path], path, token)).Trim();
        return double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var start) && double.IsFinite(start) ? map.OriginTime - start : 0;
    }
    private async Task<bool> HasAudioAsync(string path, CancellationToken token) =>
        (await tools.RunAsync("ffprobe.exe", ["-v", "error", "-select_streams", "a", "-show_entries", "stream=index", "-of", "csv=p=0", path], path, token)).Length > 0;
    // Redactions, annotations and tracking ranges follow their frames; parts on deleted frames go, and a
    // redaction keeps its shape at the edges of a cut (a keyframe is added there).
    internal static void MoveWorkToFrames(RedactionProject project, FrameTimeline oldMap, FrameTimeline newMap, Func<int, int?> newIndex)
    {
        var oldEnd = oldMap.Frames[^1].Time + oldMap.Frames[^1].Duration; var newEnd = newMap.Frames[^1].Time + newMap.Frames[^1].Duration;
        double? New(int oldFrame) => newIndex(oldFrame) is { } i && i >= 0 && i < newMap.Frames.Count ? newMap.Frames[i].Time : null;
        // The kept frames of an old time range, first and last.
        (int First, int Last)? Kept(double start, double end)
        {
            var frames = Enumerable.Range(oldMap.IndexAt(start), oldMap.IndexAt(end) - oldMap.IndexAt(start) + 1).Where(i => newIndex(i) != null).ToList();
            return frames.Count == 0 ? null : (frames[0], frames[^1]);
        }
        foreach (var r in project.Regions.ToList())
        {
            if (Kept(r.Start, r.End) is not { } kept) { project.Regions.Remove(r); continue; }
            // Running to the end stays so only while the old last frame is still the last (not after Append at the end).
            var toEnd = r.End >= oldEnd - 1e-9 && kept.Last == oldMap.Frames.Count - 1 && newIndex(kept.Last) == newMap.Frames.Count - 1;
            var edges = new[] { kept.First, kept.Last }.Select(i => new GeometryKeyframe(oldMap.Frames[i].Time, r.GeometryAt(oldMap.Frames[i].Time)));
            var keys = r.Keyframes.Where(k => newIndex(oldMap.IndexAt(k.Time)) != null).Concat(edges.Where(e => r.Keyframes.All(k => Math.Abs(k.Time - e.Time) > 1e-9)))
                .Select(k => k with { Time = New(oldMap.IndexAt(k.Time))!.Value }).GroupBy(k => k.Time).Select(g => g.OrderBy(k => k.Origin).First()).OrderBy(k => k.Time).ToList();
            r.Keyframes = keys;
            r.Start = New(kept.First)!.Value; r.End = toEnd ? newEnd : New(kept.Last)!.Value;
            r.Tracking = r.Tracking.Select(s => (s, Kept(s.Start, s.End))).Where(x => x.Item2 != null)
                .Select(x => x.s with { Start = New(x.Item2!.Value.First)!.Value, End = New(x.Item2!.Value.Last)!.Value }).ToList();
        }
        foreach (var a in project.Annotations.ToList())
        {
            if (Kept(a.Start, a.End) is not { } kept) { project.Annotations.Remove(a); continue; }
            a.Start = New(kept.First)!.Value; a.End = New(kept.Last)!.Value;
        }
        if (project.Media is { } m) project.Media = m with { Duration = newEnd };
    }
}
