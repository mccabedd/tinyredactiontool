using System.Globalization;
using System.IO;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// 0.19.0 (David): Edit › Rotate turns or flips the whole picture or video; Edit › Transform turns or
// flips the selected shape(s). Redactions, annotations and the crop follow the picture.
public enum TurnOp { Clockwise, CounterClockwise, Half, FlipHorizontal, FlipVertical }

public partial class MainWindow
{
    private static TurnOp OpFor(object sender) => Enum.Parse<TurnOp>((string)((FrameworkElement)sender).Tag);

    // ---- The whole picture or video ----
    // Where a point of the old picture ends up (old size width × height).
    internal static MediaPoint TurnPoint(MediaPoint p, TurnOp op, double width, double height) => op switch
    {
        TurnOp.Clockwise => new(height - p.Y, p.X),
        TurnOp.CounterClockwise => new(p.Y, width - p.X),
        TurnOp.Half => new(width - p.X, height - p.Y),
        TurnOp.FlipHorizontal => new(width - p.X, p.Y),
        _ => new(p.X, height - p.Y),
    };
    internal static MediaRect TurnRect(MediaRect r, TurnOp op, double width, double height)
    {
        var a = TurnPoint(new(r.X, r.Y), op, width, height); var b = TurnPoint(new(r.X + r.Width, r.Y + r.Height), op, width, height);
        return new(Math.Min(a.X, b.X), Math.Min(a.Y, b.Y), Math.Abs(b.X - a.X), Math.Abs(b.Y - a.Y));
    }
    private static bool Quarter(TurnOp op) => op is TurnOp.Clockwise or TurnOp.CounterClockwise;
    private static bool Flip(TurnOp op) => op is TurnOp.FlipHorizontal or TurnOp.FlipVertical;
    // A polygon's corners are kept relative to its box (0..1); the box turns, so the corners are re-expressed.
    private static MediaPoint TurnNormalised(MediaPoint v, TurnOp op) => op switch
    {
        TurnOp.Clockwise => new(1 - v.Y, v.X),
        TurnOp.CounterClockwise => new(v.Y, 1 - v.X),
        TurnOp.Half => new(1 - v.X, 1 - v.Y),
        TurnOp.FlipHorizontal => new(1 - v.X, v.Y),
        _ => new(v.X, 1 - v.Y),
    };
    // Moves every redaction, annotation and the crop with the picture. Returns the new size.
    internal static (int Width, int Height) TurnProjectGeometry(RedactionProject project, TurnOp op)
    {
        var m = project.Media!; double w = m.Width, h = m.Height;
        var newW = Quarter(op) ? m.Height : m.Width; var newH = Quarter(op) ? m.Width : m.Height;
        foreach (var r in project.Regions)
        {
            r.Keyframes = r.Keyframes.Select(k => k with { Bounds = TurnRect(k.Bounds, op, w, h) }).ToList();
            r.Polygon = r.Polygon.Select(v => TurnNormalised(v, op)).ToList();
            if (Flip(op)) r.Rotation = ShapeTurn.Normalise(-r.Rotation);
        }
        foreach (var a in project.Annotations)
        {
            if (!a.UsesBox) { a.Points = a.Points.Select(p => TurnPoint(p, op, w, h)).ToList(); continue; }
            if (a.Kind == AnnotationKind.Text)
            {
                // Text keeps its own box and turns with the picture, so it still reads along its line.
                var centre = TurnPoint(ShapeTurn.Centre(a.Box), op, w, h);
                a.Rotation = ShapeTurn.Normalise(op switch { TurnOp.Clockwise => a.Rotation + 90, TurnOp.CounterClockwise => a.Rotation - 90, TurnOp.Half => a.Rotation + 180, _ => -a.Rotation });
                a.Box = new MediaRect(Math.Clamp(centre.X - a.Box.Width / 2, 0, Math.Max(0, newW - a.Box.Width)), Math.Clamp(centre.Y - a.Box.Height / 2, 0, Math.Max(0, newH - a.Box.Height)),
                    Math.Min(a.Box.Width, newW), Math.Min(a.Box.Height, newH));
            }
            else
            {
                a.Box = TurnRect(a.Box, op, w, h);
                if (Flip(op)) a.Rotation = ShapeTurn.Normalise(-a.Rotation);
            }
        }
        if (project.Crop is { } crop) project.Crop = TurnRect(crop, op, w, h);
        project.Media = m with { Width = newW, Height = newH };
        return (newW, newH);
    }
    private static BitmapSource TurnBitmap(BitmapSource source, TurnOp op)
    {
        Transform transform = op switch
        {
            TurnOp.Clockwise => new RotateTransform(90), TurnOp.CounterClockwise => new RotateTransform(270), TurnOp.Half => new RotateTransform(180),
            TurnOp.FlipHorizontal => new ScaleTransform(-1, 1), _ => new ScaleTransform(1, -1),
        };
        var turned = new TransformedBitmap(source, transform); turned.Freeze(); return turned;
    }
    private static string VideoFilter(TurnOp op) => op switch
    {
        TurnOp.Clockwise => "transpose=1", TurnOp.CounterClockwise => "transpose=2", TurnOp.Half => "hflip,vflip", TurnOp.FlipHorizontal => "hflip", _ => "vflip",
    };
    private async void RotateMedia(object sender, RoutedEventArgs e) => await RotateMediaAsync(OpFor(sender));
    // The turned picture or video is a new working copy in TRT's private capture folder (wiped like a
    // capture); the original file is never changed. Undo goes back to the file before (0.21.0).
    internal async Task<bool> RotateMediaAsync(TurnOp op)
    {
        if (busy || closing || Project.Media is not { } media) return false;
        if (captures == null) { Status.Text = "Rotating needs the capture part of TRT, which is not running."; return false; }
        if (Project.Media.IsVideo && (Preview.UsePlayer || playing)) Pause();
        var done = false; string? made = null; var before = ProjectStore.Serialize(Project);
        await RunWork(async token =>
        {
            var project = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
            var oldMap = Preview.Timeline;
            var (width, height) = TurnProjectGeometry(project, op);
            if (!media.IsVideo)
            {
                if (Preview.Image is not { } image) throw new InvalidOperationException("The picture is not loaded.");
                made = captures.Store.NewFile("EDITED", ".png");
                CaptureController.WritePng(TurnBitmap(image, op), made);
            }
            else
            {
                made = captures.Store.NewFile("EDITED", ".mp4");
                ReportWork(0, "Turning the Video (This Can Take a While)");
                List<string> Args(bool copyAudio) =>
                [
                    "-v", "error", "-y", "-i", media.Path, "-map", "0:v:0", "-map", "0:a?", "-vf", VideoFilter(op),
                    "-c:v", "libx264", "-qp", "0", "-preset", "ultrafast", "-c:a", copyAudio ? "copy" : "aac",
                    "-copyts", "-fps_mode", "passthrough", "-map_metadata", "-1", "-map_chapters", "-1", made,
                ];
                try { await tools.RunAsync("ffmpeg.exe", Args(true), media.Path, token); }
                catch (Exception ex) when (ex is IOException or InvalidDataException) { await tools.RunAsync("ffmpeg.exe", Args(false), media.Path, token); }
                // Frames keep their times; if the container rounded them, keyframes follow their frames.
                var newMap = await Task.Run(() => tools.ProbeTimelineAsync(made, token), token);
                if (oldMap == null || newMap.Frames.Count != oldMap.Frames.Count) throw new InvalidDataException("The turned video has a different number of frames. Nothing was changed.");
                RetimeToFrames(project, oldMap, newMap);
            }
            token.ThrowIfCancellationRequested();
            var hash = await ProjectStore.HashAsync(made, token);
            project.Media = media with { Path = made, Length = new FileInfo(made).Length, Sha256 = hash, Width = width, Height = height,
                Duration = project.Media!.IsVideo ? project.Media.Duration : 0 };
            await LoadMedia(made, project, token, keepHistory: true);
            done = true;
        }, "Rotating cancelled. Nothing was changed.", media.IsVideo ? "Turning the Video" : "Turning the Picture");
        if (!done) { if (made != null && captures.Store.Owns(made) && Project.Media?.Path != made) ReleaseCapture(made); return false; }
        history.Checkpoint(before);
        savedSnapshot = null; // The turned working copy is new work.
        Status.Text = $"{(media.IsVideo ? "Video" : "Picture")} {OpName(op)}. Redactions and annotations moved with it; the original file is unchanged.";
        return true;
    }
    private static string OpName(TurnOp op) => op switch
    {
        TurnOp.Clockwise => "turned 90° clockwise", TurnOp.CounterClockwise => "turned 90° counter-clockwise", TurnOp.Half => "turned 180°",
        TurnOp.FlipHorizontal => "flipped horizontally", _ => "flipped vertically",
    };
    // Keyframes and ranges follow their frames into the new video's frame times.
    internal static void RetimeToFrames(RedactionProject project, FrameTimeline oldMap, FrameTimeline newMap)
    {
        double Map(double t) => newMap.Frames[oldMap.IndexAt(t)].Time;
        var duration = newMap.Frames[^1].Time + newMap.Frames[^1].Duration;
        foreach (var r in project.Regions)
        {
            var end = r.End >= oldMap.Frames[^1].Time + oldMap.Frames[^1].Duration - 1e-9 ? duration : Map(r.End);
            r.Start = Map(r.Start); r.End = Math.Max(r.Start, end);
            r.Keyframes = r.Keyframes.GroupBy(k => Map(k.Time)).Select(g => g.First() with { Time = g.Key }).OrderBy(k => k.Time).ToList();
            r.Tracking = r.Tracking.Select(s => s with { Start = Map(s.Start), End = Map(s.End) }).ToList();
        }
        foreach (var a in project.Annotations) { a.Start = Map(a.Start); a.End = Math.Max(a.Start, Map(a.End)); }
        if (project.Media is { } m) project.Media = m with { Duration = duration };
    }

    // ---- The selected shape(s) ----
    private void TransformSelection(object sender, RoutedEventArgs e) => TransformSelected(OpFor(sender));
    // Turns or flips the selected redaction(s) and annotation(s) as one group about the group's centre.
    internal bool TransformSelected(TurnOp op)
    {
        if (busy || Project.Media is not { } m) return false;
        var regions = Preview.MultiRegions.Count > 0 ? Preview.MultiRegions.ToList() : Preview.Selected is { } one ? [one] : [];
        var annotations = Preview.MultiAnnotations.Count > 0 ? Preview.MultiAnnotations.ToList() : SelectedAnnotation is { } a ? [a] : [];
        regions = regions.Where(Project.Regions.Contains).ToList(); annotations = annotations.Where(Project.Annotations.Contains).ToList();
        if (regions.Count + annotations.Count == 0) { Status.Text = "Select a shape first (or drag a box round several with Select)."; return false; }
        if (Preview.UsePlayer || playing) Pause();
        history.Checkpoint(Project);
        var time = Time;
        // The group's centre, from every shape's turned outline.
        var extents = regions.Select(r => ShapeTurn.Extent(r.GeometryAt(time), r.Rotation)).Concat(annotations.Select(x => x.UsesBox ? ShapeTurn.Extent(x.Box, x.Rotation) : x.Bounds())).ToList();
        var left = extents.Min(b => b.X); var top = extents.Min(b => b.Y);
        var centre = new MediaPoint((left + extents.Max(b => b.X + b.Width)) / 2, (top + extents.Max(b => b.Y + b.Height)) / 2);
        var angle = op switch { TurnOp.Clockwise => 90, TurnOp.CounterClockwise => -90, TurnOp.Half => 180, _ => 0 };
        MediaPoint Move(MediaPoint p) => op switch
        {
            TurnOp.FlipHorizontal => new(2 * centre.X - p.X, p.Y), TurnOp.FlipVertical => new(p.X, 2 * centre.Y - p.Y), _ => ShapeTurn.Rotate(p, centre, angle),
        };
        MediaRect Place(MediaRect box)
        {
            var c = Move(ShapeTurn.Centre(box));
            var x = Math.Clamp(c.X - box.Width / 2, 0, Math.Max(0, m.Width - box.Width)); var y = Math.Clamp(c.Y - box.Height / 2, 0, Math.Max(0, m.Height - box.Height));
            return new(x, y, Math.Min(box.Width, m.Width), Math.Min(box.Height, m.Height));
        }
        foreach (var r in regions)
        {
            r.PutManual(time, Place(r.GeometryAt(time)).Clamp(m.Width, m.Height));
            if (op == TurnOp.FlipHorizontal) { r.Polygon = r.Polygon.Select(v => new MediaPoint(1 - v.X, v.Y)).ToList(); r.Rotation = ShapeTurn.Normalise(-r.Rotation); }
            else if (op == TurnOp.FlipVertical) { r.Polygon = r.Polygon.Select(v => new MediaPoint(v.X, 1 - v.Y)).ToList(); r.Rotation = ShapeTurn.Normalise(-r.Rotation); }
            else r.Rotation = ShapeTurn.Normalise(r.Rotation + angle);
        }
        foreach (var x in annotations)
        {
            if (!x.UsesBox) { x.Points = x.Points.Select(p => { var q = Move(p); return new MediaPoint(Math.Clamp(q.X, 0, m.Width), Math.Clamp(q.Y, 0, m.Height)); }).ToList(); continue; }
            x.Box = Place(x.Box);
            // Flipped text stays readable: only its place and the sense of its turn change.
            x.Rotation = ShapeTurn.Normalise(Flip(op) ? -x.Rotation : x.Rotation + angle);
        }
        Refresh(); Preview.InvalidateVisual();
        Status.Text = $"{(regions.Count + annotations.Count == 1 ? "Shape" : $"{regions.Count + annotations.Count} shapes")} {OpName(op)}. Undo puts {(regions.Count + annotations.Count == 1 ? "it" : "them")} back.";
        return true;
    }
}
