using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace TinyRedaction.Core;

public enum RegionShape { Rectangle, Oval, Polygon }
public enum RedactionEffect { Opaque, Blur, Pixelate }
public enum KeyframeOrigin { Manual, Tracking }
public enum ReviewState { Unreviewed, Lost, Reviewed }
public readonly record struct MediaPoint(double X, double Y);
public readonly record struct MediaRect(double X, double Y, double Width, double Height)
{
    public static MediaRect Lerp(MediaRect a, MediaRect b, double t) => new(
        a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t,
        a.Width + (b.Width - a.Width) * t, a.Height + (b.Height - a.Height) * t);
    public bool Contains(MediaPoint p) => p.X >= X && p.X <= X + Width && p.Y >= Y && p.Y <= Y + Height;
    public MediaRect Clamp(double width, double height)
    {
        var x = Math.Clamp(X, 0, Math.Max(0, width - 1));
        var y = Math.Clamp(Y, 0, Math.Max(0, height - 1));
        return new(x, y, Math.Clamp(Width, 1, width - x), Math.Clamp(Height, 1, height - y));
    }
}
public sealed record GeometryKeyframe(double Time, MediaRect Bounds, KeyframeOrigin Origin = KeyframeOrigin.Manual);
public sealed record TrackingSegment(double Start, double End, ReviewState State, string Reason);
public sealed class Region
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = "Redaction";
    public RegionShape Shape { get; set; }
    public RedactionEffect Effect { get; set; }
    public string Color { get; set; } = "#000000";
    public int Strength { get; set; } = 5;
    public bool Aggressive { get; set; }
    // This flag hides only editing decorations. It never removes export coverage.
    public bool ShowDecorations { get; set; } = true;
    public double Start { get; set; }
    public double End { get; set; }
    public double CoverageMargin { get; set; }
    public List<MediaPoint> Polygon { get; set; } = [];
    public List<GeometryKeyframe> Keyframes { get; set; } = [];
    public List<TrackingSegment> Tracking { get; set; } = [];
    // 0.19.0 (David): the shape turned clockwise by this many degrees about the centre of its box.
    // Omitted when 0, so projects without rotation keep their layout.
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public double Rotation { get; set; }
    // Creation order shared with annotations (0.9.0). Omitted when 0, so older projects
    // load with every region older than any annotation.
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public long Order { get; set; }
    public override string ToString() => $"{Name} · {Shape} · {Effect}";

    public MediaRect GeometryAt(double time)
    {
        if (Keyframes.Count == 0) throw new InvalidDataException("Region has no geometry.");
        var ordered = Keyframes.OrderBy(k => k.Time).ToArray();
        if (time <= ordered[0].Time) return ordered[0].Bounds;
        for (var i = 1; i < ordered.Length; i++)
            if (time <= ordered[i].Time)
                return MediaRect.Lerp(ordered[i - 1].Bounds, ordered[i].Bounds,
                    (time - ordered[i - 1].Time) / (ordered[i].Time - ordered[i - 1].Time));
        return ordered[^1].Bounds;
    }
    public void PutManual(double time, MediaRect bounds)
    {
        if (Keyframes.Count > 0 && GeometryAt(time) != bounds)
            for (var i = 0; i < Tracking.Count; i++)
                if (Tracking[i].State == ReviewState.Reviewed)
                    Tracking[i] = Tracking[i] with { State = ReviewState.Unreviewed, Reason = "Geometry was corrected; review the animation again." };
        Keyframes.RemoveAll(k => Math.Abs(k.Time - time) < 0.0000001);
        Keyframes.Add(new(time, bounds));
        Keyframes.Sort((a, b) => a.Time.CompareTo(b.Time));
    }
    // Tracking may fill gaps but cannot silently replace a manual correction.
    public void MergeTracking(IEnumerable<GeometryKeyframe> samples)
    {
        foreach (var sample in samples)
        {
            if (Keyframes.Any(k => k.Origin == KeyframeOrigin.Manual && Math.Abs(k.Time - sample.Time) < 0.0000001)) continue;
            Keyframes.RemoveAll(k => k.Origin == KeyframeOrigin.Tracking && Math.Abs(k.Time - sample.Time) < 0.0000001);
            Keyframes.Add(sample with { Origin = KeyframeOrigin.Tracking });
        }
        Keyframes.Sort((a, b) => a.Time.CompareTo(b.Time));
    }
}
// Turning shapes (0.19.0): clockwise on screen (y grows downwards), in degrees.
public static class ShapeTurn
{
    public static MediaPoint Centre(MediaRect b) => new(b.X + b.Width / 2, b.Y + b.Height / 2);
    public static MediaPoint Rotate(MediaPoint p, MediaPoint centre, double degrees)
    {
        if (degrees == 0) return p;
        var a = degrees * Math.PI / 180; var cos = Math.Cos(a); var sin = Math.Sin(a);
        var dx = p.X - centre.X; var dy = p.Y - centre.Y;
        return new(centre.X + dx * cos - dy * sin, centre.Y + dx * sin + dy * cos);
    }
    // The upright rectangle that holds the box turned about its centre.
    public static MediaRect Extent(MediaRect b, double degrees)
    {
        if (degrees == 0) return b;
        var c = Centre(b);
        var corners = new[] { new MediaPoint(b.X, b.Y), new MediaPoint(b.X + b.Width, b.Y), new MediaPoint(b.X + b.Width, b.Y + b.Height), new MediaPoint(b.X, b.Y + b.Height) }
            .Select(p => Rotate(p, c, degrees)).ToArray();
        var left = corners.Min(p => p.X); var top = corners.Min(p => p.Y);
        return new(left, top, corners.Max(p => p.X) - left, corners.Max(p => p.Y) - top);
    }
    // An angle kept within -180..180 degrees.
    public static double Normalise(double degrees) { var d = degrees % 360; if (d > 180) d -= 360; if (d <= -180) d += 360; return Math.Abs(d) < 1e-9 ? 0 : d; }
}
public sealed record MediaReference(string Path, long Length, string Sha256, int Width, int Height, double Duration, bool IsVideo);
public sealed class ExportSettings
{
    public string Format { get; set; } = "png";
    public string Quality { get; set; } = "Normal";
    public bool KeepAudio { get; set; }
    public bool DeleteOriginal { get; set; }
}
public sealed class RedactionProject
{
    public int SchemaVersion { get; set; } = 1;
    public string Application { get; set; } = "TinyRedactionTool";
    public string CoordinateSpace { get; set; } = "autorotated-square-pixels-v1";
    public MediaReference? Media { get; set; }
    public List<Region> Regions { get; set; } = [];
    public ExportSettings Export { get; set; } = new();
    // Confirmed still-image crop in whole source pixels (0.7.0). Omitted when absent so
    // projects without a crop stay readable by 0.6.0. Applied after redaction at export;
    // the source file is never changed. 3.0.0: videos can be cropped too (every frame, at export).
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public MediaRect? Crop { get; set; }
    // Text/Line/Polyline annotations (0.9.0). Written only when present, so projects
    // without annotations keep the 0.8.x layout.
    [JsonIgnore]
    public List<Annotation> Annotations { get; set; } = [];
    [JsonPropertyName("Annotations"), JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public List<Annotation>? SavedAnnotations { get => Annotations.Count == 0 ? null : Annotations; set => Annotations = value ?? []; }
}
public static class ProjectStore
{
    public static JsonSerializerOptions Json { get; } = new()
    {
        WriteIndented = true, UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
        Converters = { new JsonStringEnumConverter() }
    };
    public static string Serialize(RedactionProject project) => JsonSerializer.Serialize(project, Json);
    public static RedactionProject Deserialize(string text)
    {
        var project = JsonSerializer.Deserialize<RedactionProject>(text, Json) ?? throw new InvalidDataException("The project file is empty.");
        using (var document = JsonDocument.Parse(text))
            if (!document.RootElement.TryGetProperty(nameof(RedactionProject.CoordinateSpace), out _)) project.CoordinateSpace = "legacy-autorotated-pixels";
        Validate(project);
        return project;
    }
    public static void Validate(RedactionProject p)
    {
        // 3.0.0 clean-up: projects saved under the old internal name keep opening.
        if (p.SchemaVersion != 1 || p.Application is not ("TinyRedactionTool" or "TinyRedactionTool.Wpf.Dev")) throw new InvalidDataException("This project was made by a different TRT version.");
        if (p.CoordinateSpace is not ("autorotated-square-pixels-v1" or "legacy-autorotated-pixels")) throw new InvalidDataException("Unsupported coordinate space.");
        if (p.Media is not { } media || media.Width < 1 || media.Height < 1 || !double.IsFinite(media.Duration) || media.Duration < 0 ||
            media.Length < 1 || media.Sha256.Length != 64 || !media.Sha256.All(Uri.IsHexDigit)) throw new InvalidDataException("Invalid source reference.");
        if (p.Regions.Select(r => r.Id).Distinct().Count() != p.Regions.Count) throw new InvalidDataException("Duplicate region identity.");
        if (p.Crop is { } crop && (p.CoordinateSpace != "autorotated-square-pixels-v1" || !ImageCrop.IsPixelRect(crop) ||
            crop.Width < 1 || crop.Height < 1 || crop.X < 0 || crop.Y < 0 || crop.X + crop.Width > media.Width || crop.Y + crop.Height > media.Height))
            throw new InvalidDataException("Invalid image crop.");
        foreach (var r in p.Regions)
        {
            if (!Enum.IsDefined(r.Shape) || !Enum.IsDefined(r.Effect) || !double.IsFinite(r.Start) || !double.IsFinite(r.End) ||
                r.Start < 0 || r.End < r.Start || r.End > media.Duration || r.Keyframes.Count == 0 ||
                !double.IsFinite(r.CoverageMargin) || r.CoverageMargin < 0 || r.CoverageMargin > 1000 ||
                r.Color.Length != 7 || r.Color[0] != '#' || !r.Color[1..].All(Uri.IsHexDigit) || r.Strength is < 1 or > 10)
                throw new InvalidDataException("Check the times, colour and margin: one is out of range.");
            var previous = -1d;
            foreach (var k in r.Keyframes.OrderBy(k => k.Time))
            {
                var b = k.Bounds;
                if (!double.IsFinite(k.Time) || k.Time < 0 || k.Time > media.Duration || k.Time <= previous ||
                    !Enum.IsDefined(k.Origin) || !double.IsFinite(b.X) || !double.IsFinite(b.Y) || !double.IsFinite(b.Width) || !double.IsFinite(b.Height) ||
                    b.X < 0 || b.Y < 0 || b.Width < 1 || b.Height < 1 || b.X + b.Width > media.Width + 0.001 || b.Y + b.Height > media.Height + 0.001)
                    throw new InvalidDataException("The box must be inside the picture.");
                previous = k.Time;
            }
            if (r.Shape == RegionShape.Polygon && (r.Polygon.Count < 3 || r.Polygon.Any(v => !double.IsFinite(v.X) || !double.IsFinite(v.Y) || v.X < 0 || v.Y < 0 || v.X > 1 || v.Y > 1)))
                throw new InvalidDataException("Polygon vertices must use normalized region coordinates.");
            if (r.Tracking.Any(s => !double.IsFinite(s.Start) || !double.IsFinite(s.End) || s.Start < 0 || s.End < s.Start || s.End > media.Duration || !Enum.IsDefined(s.State)))
                throw new InvalidDataException("Invalid tracking review range.");
            if (r.Order < 0) throw new InvalidDataException("Invalid region order.");
            if (!double.IsFinite(r.Rotation) || Math.Abs(r.Rotation) >= 360) throw new InvalidDataException("Invalid region rotation.");
        }
        AnnotationRules.Validate(p, media);
    }
    public static async Task SaveAsync(string path, RedactionProject project, CancellationToken cancellation = default)
    {
        Validate(project);
        if (SamePath(path, project.Media!.Path)) throw new IOException("Choose another name: a project can't replace the picture or video.");
        var temporary = path + ".partial." + Guid.NewGuid().ToString("N");
        try
        {
            await File.WriteAllTextAsync(temporary, Serialize(project), cancellation);
            cancellation.ThrowIfCancellationRequested();
            File.Move(temporary, path, true);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
    public static bool SamePath(string a, string b) => string.Equals(System.IO.Path.GetFullPath(a), System.IO.Path.GetFullPath(b), StringComparison.OrdinalIgnoreCase);
    public static async Task<string> HashAsync(string path, CancellationToken cancellation = default)
    {
        await using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 1024 * 1024, true);
        return Convert.ToHexString(await SHA256.HashDataAsync(stream, cancellation));
    }
    public static async Task<bool> MatchesAsync(MediaReference original, string candidate, CancellationToken cancellation = default) =>
        File.Exists(candidate) && new FileInfo(candidate).Length == original.Length &&
        string.Equals(await HashAsync(candidate, cancellation), original.Sha256, StringComparison.OrdinalIgnoreCase);
}
public sealed class EditHistory
{
    private readonly Stack<string> undo = new(), redo = new();
    public void Checkpoint(RedactionProject p) => Checkpoint(ProjectStore.Serialize(p));
    // A snapshot taken earlier (0.21.0: before the media itself was replaced by Rotate, Trim or Append).
    public void Checkpoint(string snapshot) { undo.Push(snapshot); redo.Clear(); }
    public RedactionProject Undo(RedactionProject current)
    { if (undo.Count == 0) return current; redo.Push(ProjectStore.Serialize(current)); return ProjectStore.Deserialize(undo.Pop()); }
    public RedactionProject Redo(RedactionProject current)
    { if (redo.Count == 0) return current; undo.Push(ProjectStore.Serialize(current)); return ProjectStore.Deserialize(redo.Pop()); }
    public void Clear() { undo.Clear(); redo.Clear(); }
}
