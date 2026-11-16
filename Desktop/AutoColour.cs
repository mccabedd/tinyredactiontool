using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Auto redaction colour (3.2.0, David): a Solid Fill redaction takes the colour of what is around it, so black text on
// light blue is covered with light blue. The colour is read from a thin band along the shape's edge, a little inside and
// a little outside, and the most common colour wins (an average of black text on blue would be a muddy dark blue).
// The result is an ordinary solid colour: the box is still fully opaque and Export checks it as before.
internal static class AutoColour
{
    // The shape in picture pixels (turned like the shape).
    internal static Geometry MediaGeometry(Region r, MediaRect b)
    {
        var rect = new Rect(b.X, b.Y, b.Width, b.Height);
        Geometry geometry;
        if (r.Shape == RegionShape.Rectangle) geometry = new RectangleGeometry(rect);
        else if (r.Shape == RegionShape.Oval) geometry = new EllipseGeometry(rect);
        else
        {
            var stream = new StreamGeometry();
            using (var context = stream.Open())
            {
                var points = r.Polygon.Select(p => new Point(rect.X + p.X * rect.Width, rect.Y + p.Y * rect.Height)).ToArray();
                if (points.Length > 0) { context.BeginFigure(points[0], true, true); context.PolyLineTo(points.Skip(1).ToArray(), true, false); }
            }
            geometry = stream;
        }
        if (r.Rotation != 0) geometry.Transform = new RotateTransform(r.Rotation, rect.X + rect.Width / 2, rect.Y + rect.Height / 2);
        return geometry;
    }

    // "#RRGGBB" for the region at this time, or null when nothing readable is around it (fully transparent, say).
    internal static string? Sample(BitmapSource picture, Region r, double time)
    {
        var bgra = picture.Format == PixelFormats.Bgra32 ? picture : new FormatConvertedBitmap(picture, PixelFormats.Bgra32, null, 0);
        int w = bgra.PixelWidth, h = bgra.PixelHeight;
        var pixels = new byte[checked(w * h * 4)]; bgra.CopyPixels(pixels, w * 4, 0);
        return Sample(pixels, w, h, MediaGeometry(r, r.GeometryAt(time)));
    }
    internal static string? Sample(byte[] pixels, int w, int h, Geometry shape)
    {
        var outline = shape.GetFlattenedPathGeometry();
        if (outline.Bounds.IsEmpty) return null;
        var counts = new Dictionary<int, (int Count, long B, long G, long R)>();
        const int Steps = 480;
        for (var i = 0; i < Steps; i++)
        {
            outline.GetPointAtFractionLength((i + 0.5) / Steps, out var at, out var tangent);
            var length = Math.Sqrt(tangent.X * tangent.X + tangent.Y * tangent.Y);
            if (length < 1e-9) continue;
            var nx = -tangent.Y / length; var ny = tangent.X / length;
            // Inside and outside the edge: a box drawn a little loose or a little tight both find the background.
            foreach (var d in new[] { -3.0, -1.5, 1.5, 3.0 })
            {
                int x = (int)Math.Floor(at.X + nx * d), y = (int)Math.Floor(at.Y + ny * d);
                if (x < 0 || y < 0 || x >= w || y >= h) continue;
                var o = (y * w + x) * 4;
                if (pixels[o + 3] < 128) continue; // See-through pixels have no colour to match.
                var key = (pixels[o + 2] >> 4) << 8 | (pixels[o + 1] >> 4) << 4 | pixels[o] >> 4;
                counts.TryGetValue(key, out var c);
                counts[key] = (c.Count + 1, c.B + pixels[o], c.G + pixels[o + 1], c.R + pixels[o + 2]);
            }
        }
        if (counts.Count == 0) return null;
        var best = counts.Values.MaxBy(c => c.Count);
        return $"#{best.R / best.Count:X2}{best.G / best.Count:X2}{best.B / best.Count:X2}";
    }
}
