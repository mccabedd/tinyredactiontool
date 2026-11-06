using System.Globalization;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// One drawing routine for annotations, used by the live preview (screen coordinates)
// and by export rasters (frame pixels), so both show the same shapes.
public static class AnnotationRenderer
{
    // map: media pixels -> target coordinates; scale: target units per media pixel.
    public static void Draw(DrawingContext dc, Annotation a, Func<MediaPoint, Point> map, double scale, double pixelsPerDip, string? textOverride = null)
    {
        // 0.19.0: Text, Rectangle and Oval turned about the centre of their box.
        if (a.UsesBox && a.Rotation != 0)
        {
            var corner = map(new(a.Box.X, a.Box.Y)); var opposite = map(new(a.Box.X + a.Box.Width, a.Box.Y + a.Box.Height));
            dc.PushTransform(new RotateTransform(a.Rotation, (corner.X + opposite.X) / 2, (corner.Y + opposite.Y) / 2));
            try { DrawUnturned(dc, a, map, scale, pixelsPerDip, textOverride); } finally { dc.Pop(); }
            return;
        }
        DrawUnturned(dc, a, map, scale, pixelsPerDip, textOverride);
    }
    private static void DrawUnturned(DrawingContext dc, Annotation a, Func<MediaPoint, Point> map, double scale, double pixelsPerDip, string? textOverride)
    {
        if (a.Kind == AnnotationKind.Picture)
        {
            // 0.26.0: a pasted picture, stretched to its box (the box keeps its shape unless Shift is held).
            if (PictureOf(a) is { } picture) dc.DrawImage(picture, new Rect(map(new(a.Box.X, a.Box.Y)), map(new(a.Box.X + a.Box.Width, a.Box.Y + a.Box.Height))));
            return;
        }
        var brush = new SolidColorBrush((Color)ColorConverter.ConvertFromString(a.Color)); brush.Freeze();
        if (a.Kind == AnnotationKind.Text)
        {
            var topLeft = map(new(a.Box.X, a.Box.Y)); var bottomRight = map(new(a.Box.X + a.Box.Width, a.Box.Y + a.Box.Height));
            var rect = new Rect(topLeft, bottomRight);
            var text = textOverride ?? a.Text;
            if (rect.Width < 0.5 || rect.Height < 0.5 || text.Length == 0) return;
            var formatted = new FormattedText(text, CultureInfo.CurrentCulture, FlowDirection.LeftToRight, Typeface(a), Math.Max(0.1, a.FontSize * scale), brush, pixelsPerDip)
            {
                // Wrap to the box width; the clip below cuts lines at the box edge, as the
                // baseline does (a height limit would drop a line that doesn't fully fit).
                MaxTextWidth = rect.Width, Trimming = TextTrimming.WordEllipsis,
                TextAlignment = a.Align switch { AnnotationAlign.Centre => TextAlignment.Center, AnnotationAlign.Right => TextAlignment.Right, _ => TextAlignment.Left }
            };
            dc.PushClip(new RectangleGeometry(rect)); dc.DrawText(formatted, rect.TopLeft); dc.Pop();
            return;
        }
        var stroke = Math.Max(0.1, a.Width * scale);
        // WPF's own dot patterns use zero-length dashes, which only show with round or square dash caps;
        // the flat-capped Outline, Ellipse, Line and Polyline lost their dots (0.16.0, David). They use
        // patterns whose dots are one line-width long instead; the round-capped Pen keeps WPF's.
        var dash = a.Kind == AnnotationKind.Freehand
            ? a.Dash switch { AnnotationDash.Dash => DashStyles.Dash, AnnotationDash.Dot => DashStyles.Dot, AnnotationDash.DashDot => DashStyles.DashDot, AnnotationDash.DashDotDot => DashStyles.DashDotDot, _ => DashStyles.Solid }
            : FlatDash(a.Dash);
        // Outline-only drawings (0.11.0): the stroke sits centred on the box edge; nothing is filled.
        if (a.Kind is AnnotationKind.Rectangle or AnnotationKind.Oval)
        {
            var box = new Rect(map(new(a.Box.X, a.Box.Y)), map(new(a.Box.X + a.Box.Width, a.Box.Y + a.Box.Height)));
            var outline = new Pen(brush, stroke) { DashStyle = dash, LineJoin = PenLineJoin.Miter, DashCap = PenLineCap.Flat }; outline.Freeze();
            if (a.Kind == AnnotationKind.Rectangle) dc.DrawRectangle(null, outline, box);
            else dc.DrawEllipse(null, outline, new Point(box.X + box.Width / 2, box.Y + box.Height / 2), box.Width / 2, box.Height / 2);
            return;
        }
        var points = a.Points.Select(map).ToArray();
        if (points.Length < 2) return;
        if (a.Kind == AnnotationKind.Freehand)
        {
            // A pen line: round joins and ends so a hand-drawn path looks smooth.
            var penLine = new Pen(brush, stroke) { DashStyle = dash, LineJoin = PenLineJoin.Round, StartLineCap = PenLineCap.Round, EndLineCap = PenLineCap.Round, DashCap = PenLineCap.Round }; penLine.Freeze();
            var path = new StreamGeometry();
            using (var context = path.Open()) { context.BeginFigure(points[0], false, false); context.PolyLineTo(points.Skip(1).ToArray(), true, true); }
            path.Freeze(); dc.DrawGeometry(null, penLine, path);
            return;
        }
        // Baseline arrowheads: filled triangles; the shaft stops 75% of the way into the head.
        var headLength = Math.Max(6 * scale, 4 * stroke); var headWidth = Math.Max(5 * scale, 3 * stroke);
        bool arrowStart = a.Ends is AnnotationEnds.ArrowStart or AnnotationEnds.ArrowBoth, arrowEnd = a.Ends is AnnotationEnds.ArrowEnd or AnnotationEnds.ArrowBoth;
        bool dotStart = a.Ends is AnnotationEnds.DotStart or AnnotationEnds.DotBoth, dotEnd = a.Ends is AnnotationEnds.DotEnd or AnnotationEnds.DotBoth;
        var shaft = (Point[])points.Clone();
        if (arrowStart) shaft[0] = Shorten(points[1], points[0], headLength * 0.75);
        if (arrowEnd) shaft[^1] = Shorten(points[^2], points[^1], headLength * 0.75);
        var pen = new Pen(brush, stroke)
        {
            DashStyle = dash,
            LineJoin = a.Join == AnnotationJoin.Round ? PenLineJoin.Round : PenLineJoin.Miter, MiterLimit = 4,
            StartLineCap = PenLineCap.Flat, EndLineCap = PenLineCap.Flat, DashCap = PenLineCap.Flat
        };
        pen.Freeze();
        var geometry = new StreamGeometry();
        using (var context = geometry.Open()) { context.BeginFigure(shaft[0], false, false); context.PolyLineTo(shaft.Skip(1).ToArray(), true, true); }
        geometry.Freeze();
        dc.DrawGeometry(null, pen, geometry);
        if (arrowStart) dc.DrawGeometry(brush, null, Arrowhead(points[1], points[0], headLength, headWidth));
        if (arrowEnd) dc.DrawGeometry(brush, null, Arrowhead(points[^2], points[^1], headLength, headWidth));
        // Dot ends (0.16.0): a filled circle centred on the end point, a little wider than the line.
        var dotRadius = Math.Max(3 * scale, 1.5 * stroke);
        if (dotStart) dc.DrawEllipse(brush, null, points[0], dotRadius, dotRadius);
        if (dotEnd) dc.DrawEllipse(brush, null, points[^1], dotRadius, dotRadius);
    }
    // A Picture annotation's PNG, decoded once per text (the same text is shared by Undo copies); null if it isn't one.
    private static readonly System.Runtime.CompilerServices.ConditionalWeakTable<string, BitmapSource> pictures = new();
    internal static BitmapSource? PictureOf(Annotation a)
    {
        if (a.Picture is not { } data) return null;
        if (pictures.TryGetValue(data, out var known)) return known;
        try
        {
            using var stream = new System.IO.MemoryStream(Convert.FromBase64String(data));
            var frame = new PngBitmapDecoder(stream, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad).Frames[0];
            frame.Freeze(); pictures.AddOrUpdate(data, frame); return frame;
        }
        catch (Exception ex) when (ex is FormatException or NotSupportedException or System.IO.IOException or System.IO.FileFormatException or ArgumentException) { return null; }
    }
    // The PNG text for a picture (0.26.0, pasting onto a picture).
    internal static string PictureText(BitmapSource picture)
    {
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(picture));
        using var stream = new System.IO.MemoryStream(); encoder.Save(stream);
        return Convert.ToBase64String(stream.ToArray());
    }
    private static readonly DashStyle FlatDot = Frozen(1, 1), FlatDashDot = Frozen(3, 1.5, 1, 1.5), FlatDashDotDot = Frozen(3, 1.5, 1, 1.5, 1, 1.5);
    private static DashStyle Frozen(params double[] pattern) { var style = new DashStyle(pattern, 0); style.Freeze(); return style; }
    internal static DashStyle FlatDash(AnnotationDash dash) => dash switch
    {
        AnnotationDash.Dash => DashStyles.Dash, AnnotationDash.Dot => FlatDot, AnnotationDash.DashDot => FlatDashDot, AnnotationDash.DashDotDot => FlatDashDotDot, _ => DashStyles.Solid
    };
    public static Typeface Typeface(Annotation a) => new(new FontFamily(a.FontFamily), a.Italic ? FontStyles.Italic : FontStyles.Normal, a.Bold ? FontWeights.Bold : FontWeights.Normal, FontStretches.Normal, new FontFamily("Segoe UI"));
    private static Point Shorten(Point from, Point to, double by)
    {
        var v = to - from; var length = v.Length;
        return length <= by || length == 0 ? from + v * 0.01 : to - v / length * by;
    }
    private static Geometry Arrowhead(Point from, Point tip, double length, double width)
    {
        var v = tip - from; if (v.Length == 0) return Geometry.Empty;
        v.Normalize(); var normal = new Vector(-v.Y, v.X); var basePoint = tip - v * length;
        var geometry = new StreamGeometry();
        using (var context = geometry.Open()) { context.BeginFigure(tip, true, true); context.PolyLineTo([basePoint + normal * width / 2, basePoint - normal * width / 2], true, true); }
        geometry.Freeze(); return geometry;
    }
}

// Annotations rasterised once per frame size, then composited into frame pixels by the
// shared renderer and the opaque-video overlay. WPF text needs an STA thread, so layers are
// drawn on one; the result is plain pixel data usable from export worker threads.
public sealed class AnnotationRaster
{
    public sealed record Layer(Annotation Annotation, int Left, int Top, int Width, int Height, byte[] Premultiplied);
    public IReadOnlyList<Layer> Layers { get; }
    private AnnotationRaster(IReadOnlyList<Layer> layers) => Layers = layers;
    public static AnnotationRaster? Create(RedactionProject project, int width, int height)
    {
        if (project.Annotations.Count == 0 || project.Media is not { } media) return null;
        var annotations = project.Annotations.OrderBy(a => a.Order).ToArray();
        List<Layer> Draw()
        {
            var sx = width / (double)media.Width; var sy = height / (double)media.Height; var scale = (sx + sy) / 2;
            var layers = new List<Layer>();
            foreach (var a in annotations)
            {
                var visual = new DrawingVisual();
                using (var dc = visual.RenderOpen()) AnnotationRenderer.Draw(dc, a, p => new Point(p.X * sx, p.Y * sy), scale, 1);
                var bounds = visual.ContentBounds; if (bounds.IsEmpty) continue;
                var left = Math.Max(0, (int)Math.Floor(bounds.Left) - 1); var top = Math.Max(0, (int)Math.Floor(bounds.Top) - 1);
                var right = Math.Min(width, (int)Math.Ceiling(bounds.Right) + 1); var bottom = Math.Min(height, (int)Math.Ceiling(bounds.Bottom) + 1);
                if (right <= left || bottom <= top) continue;
                var shifted = new DrawingVisual();
                using (var dc = shifted.RenderOpen()) { dc.PushTransform(new TranslateTransform(-left, -top)); dc.DrawDrawing(visual.Drawing); dc.Pop(); }
                var bitmap = new RenderTargetBitmap(right - left, bottom - top, 96, 96, PixelFormats.Pbgra32); bitmap.Render(shifted);
                var pixels = new byte[checked((right - left) * (bottom - top) * 4)]; bitmap.CopyPixels(pixels, (right - left) * 4, 0);
                layers.Add(new(a, left, top, right - left, bottom - top, pixels));
            }
            return layers;
        }
        if (Thread.CurrentThread.GetApartmentState() == ApartmentState.STA) return new(Draw());
        List<Layer>? result = null; Exception? failure = null;
        var thread = new Thread(() => { try { result = Draw(); } catch (Exception ex) { failure = ex; } });
        thread.SetApartmentState(ApartmentState.STA); thread.Start(); thread.Join();
        if (failure != null) throw new InvalidOperationException("Annotations could not be drawn.", failure);
        return new(result!);
    }
    // Composites active layers in creation order over straight-alpha BGRA pixels. Pixels that a
    // redaction committed after the annotation covers are left as they are (the redaction wins).
    public void Composite(byte[] pixels, int width, int height, Func<Annotation, bool> active, Func<Annotation, int, int, bool> coveredByLaterRedaction, CancellationToken cancellation = default)
    {
        foreach (var layer in Layers)
        {
            if (!active(layer.Annotation)) continue;
            cancellation.ThrowIfCancellationRequested();
            for (var y = 0; y < layer.Height; y++)
            {
                var py = layer.Top + y; if (py >= height) break;
                for (var x = 0; x < layer.Width; x++)
                {
                    var px = layer.Left + x; if (px >= width) break;
                    var s = (y * layer.Width + x) * 4; var sa = layer.Premultiplied[s + 3];
                    if (sa == 0 || coveredByLaterRedaction(layer.Annotation, px, py)) continue;
                    var d = (py * width + px) * 4; var da = pixels[d + 3] / 255d; var alpha = sa / 255d;
                    var outAlpha = alpha + da * (1 - alpha);
                    for (var c = 0; c < 3; c++)
                        pixels[d + c] = (byte)Math.Clamp(Math.Round((layer.Premultiplied[s + c] + pixels[d + c] * da * (1 - alpha)) / outAlpha), 0, 255);
                    pixels[d + 3] = (byte)Math.Round(outAlpha * 255);
                }
            }
        }
    }
    // Pixels any annotation may touch, used to exclude them from strict opaque-colour checks.
    public bool[] Footprint(int width, int height)
    {
        var mask = new bool[width * height];
        foreach (var layer in Layers)
            for (var y = 0; y < layer.Height; y++) for (var x = 0; x < layer.Width; x++)
                if (layer.Premultiplied[(y * layer.Width + x) * 4 + 3] != 0 && layer.Top + y < height && layer.Left + x < width) mask[(layer.Top + y) * width + layer.Left + x] = true;
        return mask;
    }
}
