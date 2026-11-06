using System.Text.Json.Serialization;

namespace TinyRedaction.Core;

// Text, Line and Polyline annotations (baseline v2.5.1), and outline-only Rectangle, Oval and
// Freehand drawings (0.11.0). Geometry is in canonical media pixels; widths and font sizes are
// media pixels, so exports match the media resolution. New kinds are appended (saved as numbers).
// 0.26.0 (David): Picture, a picture pasted onto a picture (most of all onto a New one), moved and sized like a box.
public enum AnnotationKind { Text, Line, Polyline, Rectangle, Oval, Freehand, Picture }
public enum AnnotationDash { Solid, Dash, Dot, DashDot, DashDotDot }
// 0.16.0: round dot ends (David), appended so older projects keep their values.
public enum AnnotationEnds { None, ArrowEnd, ArrowStart, ArrowBoth, DotEnd, DotStart, DotBoth }
public enum AnnotationJoin { Miter, Round }
public enum AnnotationAlign { Left, Centre, Right }
public sealed class Annotation
{
    public const int MinWidth = 1, MaxWidth = 20, MinFontSize = 6, MaxFontSize = 200, MaxTextLength = 10_000;
    public Guid Id { get; set; } = Guid.NewGuid();
    public AnnotationKind Kind { get; set; }
    // Shared creation order with regions: a redaction committed later covers this annotation.
    public long Order { get; set; }
    // Exact inclusive source frames on video (no redaction safety buffer); 0/0 on stills.
    public double Start { get; set; }
    public double End { get; set; }
    public string Color { get; set; } = "#FF0000";
    // Line and Polyline.
    public List<MediaPoint> Points { get; set; } = [];
    public int Width { get; set; } = 3;
    public AnnotationDash Dash { get; set; }
    public AnnotationEnds Ends { get; set; }
    public AnnotationJoin Join { get; set; }
    // Text.
    public MediaRect Box { get; set; }
    public string Text { get; set; } = "";
    public string FontFamily { get; set; } = "Segoe UI";
    public double FontSize { get; set; } = 24;
    public bool Bold { get; set; }
    public bool Italic { get; set; }
    public AnnotationAlign Align { get; set; }
    // 0.19.0: Text, Rectangle and Oval turned clockwise about their box centre (lines, polylines and pen
    // drawings are turned by moving their points). Omitted when 0.
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingDefault)]
    public double Rotation { get; set; }

    // Picture (0.26.0): the pasted picture itself, as a PNG file in base64, drawn to fill Box. Pictures only, not videos.
    public const int MaxPictureCharacters = 24 << 20;
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Picture { get; set; }

    // Text, Rectangle, Oval and Picture are placed by Box; the others by Points.
    [JsonIgnore] public bool UsesBox => Kind is AnnotationKind.Text or AnnotationKind.Rectangle or AnnotationKind.Oval or AnnotationKind.Picture;
    public override string ToString() => Kind switch
    {
        AnnotationKind.Text => "Text · " + (Text.ReplaceLineEndings(" ") is var t && t.Length > 28 ? t[..28] + "…" : Text.ReplaceLineEndings(" ")),
        AnnotationKind.Rectangle or AnnotationKind.Oval => $"{Kind} outline · {Box.Width:0} × {Box.Height:0}",
        AnnotationKind.Freehand => "Freehand drawing",
        AnnotationKind.Picture => $"Picture · {Box.Width:0} × {Box.Height:0}",
        _ => $"{Kind} · {Points.Count} points"
    };
    public MediaRect Bounds()
    {
        if (UsesBox) return Box;
        var x = Points.Min(p => p.X); var y = Points.Min(p => p.Y);
        return new(x, y, Points.Max(p => p.X) - x, Points.Max(p => p.Y) - y);
    }
    // Moves the whole annotation, kept inside the media.
    public void Translate(double dx, double dy, double mediaWidth, double mediaHeight)
    {
        var b = Bounds();
        dx = Math.Clamp(dx, -b.X, mediaWidth - b.X - b.Width); dy = Math.Clamp(dy, -b.Y, mediaHeight - b.Y - b.Height);
        if (UsesBox) Box = Box with { X = Box.X + dx, Y = Box.Y + dy };
        else Points = Points.Select(p => new MediaPoint(p.X + dx, p.Y + dy)).ToList();
    }
    // Style shared by new annotations of every kind; geometry, text and timing are not copied.
    public void CopyStyleFrom(Annotation other)
    {
        Color = other.Color; Width = other.Width; Dash = other.Dash; Ends = other.Ends; Join = other.Join;
        FontFamily = other.FontFamily; FontSize = other.FontSize; Bold = other.Bold; Italic = other.Italic; Align = other.Align;
    }
    public bool SameStyle(Annotation other) =>
        Color == other.Color && Width == other.Width && Dash == other.Dash && Ends == other.Ends && Join == other.Join && FontFamily == other.FontFamily &&
        FontSize == other.FontSize && Bold == other.Bold && Italic == other.Italic && Align == other.Align;
    public static bool ValidColor(string colour) => colour.Length == 7 && colour[0] == '#' && colour[1..].All(Uri.IsHexDigit);
}
public static class AnnotationRules
{
    public static long NextOrder(RedactionProject p) => Math.Max(p.Regions.Select(r => r.Order).DefaultIfEmpty(0).Max(), p.Annotations.Select(a => a.Order).DefaultIfEmpty(0).Max()) + 1;
    public static void Validate(RedactionProject p, MediaReference media)
    {
        if (p.Annotations.Select(a => a.Id).Concat(p.Regions.Select(r => r.Id)).Distinct().Count() != p.Annotations.Count + p.Regions.Count)
            throw new InvalidDataException("Duplicate annotation identity.");
        bool Inside(MediaPoint v) => double.IsFinite(v.X) && double.IsFinite(v.Y) && v.X >= -0.001 && v.Y >= -0.001 && v.X <= media.Width + 0.001 && v.Y <= media.Height + 0.001;
        foreach (var a in p.Annotations)
        {
            if (!Enum.IsDefined(a.Kind) || !Enum.IsDefined(a.Dash) || !Enum.IsDefined(a.Ends) || !Enum.IsDefined(a.Join) || !Enum.IsDefined(a.Align) ||
                !Annotation.ValidColor(a.Color) || a.Width is < Annotation.MinWidth or > Annotation.MaxWidth || a.Order < 0 ||
                !double.IsFinite(a.Start) || !double.IsFinite(a.End) || a.Start < 0 || a.End < a.Start || a.End > media.Duration ||
                !media.IsVideo && (a.Start != 0 || a.End != 0) || !double.IsFinite(a.Rotation) || Math.Abs(a.Rotation) >= 360 || a.Rotation != 0 && !a.UsesBox ||
                a.Picture != null && a.Kind != AnnotationKind.Picture)
                throw new InvalidDataException("Invalid annotation parameters.");
            if (a.Kind == AnnotationKind.Text)
            {
                var b = a.Box;
                if (string.IsNullOrWhiteSpace(a.Text) || a.Text.Length > Annotation.MaxTextLength || string.IsNullOrWhiteSpace(a.FontFamily) || a.FontFamily.Length > 200 ||
                    !double.IsFinite(a.FontSize) || a.FontSize < Annotation.MinFontSize || a.FontSize > Annotation.MaxFontSize ||
                    !Inside(new(b.X, b.Y)) || !Inside(new(b.X + b.Width, b.Y + b.Height)) || !(b.Width >= 1) || !(b.Height >= 1) || a.Points.Count != 0)
                    throw new InvalidDataException("Invalid text annotation.");
            }
            else if (a.Kind == AnnotationKind.Picture)
            {
                var b = a.Box;
                if (media.IsVideo || a.Picture is not { Length: > 8 and <= Annotation.MaxPictureCharacters } data || !data.StartsWith("iVBORw0KGgo", StringComparison.Ordinal) || a.Points.Count != 0 || a.Text.Length != 0 ||
                    !Inside(new(b.X, b.Y)) || !Inside(new(b.X + b.Width, b.Y + b.Height)) || !(b.Width >= 1) || !(b.Height >= 1))
                    throw new InvalidDataException("Invalid picture annotation.");
                // Complete base64 (it is decoded, as a PNG, only when drawn).
                if (data.Length % 4 != 0 || data.TrimEnd('=').Any(c => !(char.IsAsciiLetterOrDigit(c) || c is '+' or '/'))) throw new InvalidDataException("Invalid picture annotation.");
            }
            else if (a.Kind is AnnotationKind.Rectangle or AnnotationKind.Oval)
            {
                var b = a.Box;
                if (!Inside(new(b.X, b.Y)) || !Inside(new(b.X + b.Width, b.Y + b.Height)) || !(b.Width >= 1) || !(b.Height >= 1) || a.Points.Count != 0 || a.Text.Length != 0)
                    throw new InvalidDataException("Invalid drawing annotation.");
            }
            else if (a.Points.Count < 2 || a.Kind == AnnotationKind.Line && a.Points.Count != 2 || !a.Points.All(Inside))
                throw new InvalidDataException("Invalid line annotation.");
        }
    }
}
