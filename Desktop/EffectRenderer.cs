using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Shared CPU compositor: exact paused preview, image export and effect-video export.
// Live playback uses the same math at proxy resolution and is an approximation.
public static class EffectRenderer
{
    private static readonly int[] Radii = [10, 12, 16, 20, 26, 33, 42, 54, 68, 86];
    private static readonly int[] Divisors = [6, 9, 12, 15, 18, 24, 30, 38, 48, 60];

    // annotations: rasterised for this frame size (AnnotationRaster.Create). The live preview
    // passes none and draws annotations as vectors on top instead.
    public static BitmapSource Render(BitmapSource source, RedactionProject project, double time,
        FrameTimeline? timeline, CancellationToken cancellation = default, AnnotationRaster? annotations = null)
    {
        var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0);
        var w = source.PixelWidth; var h = source.PixelHeight;
        var pixels = new byte[checked(w * h * 4)]; converted.CopyPixels(pixels, w * 4, 0);
        var m = project.Media ?? throw new InvalidOperationException("Missing media.");
        var sx = w / (double)m.Width; var sy = h / (double)m.Height;
        var applied = new List<(Region Region, MediaRect Bounds, double Margin)>();
        foreach (var r in project.Regions)
        {
            cancellation.ThrowIfCancellationRequested();
            if (m.IsVideo && timeline?.IsActive(r, time) != true) continue;
            var original = r.GeometryAt(m.IsVideo ? Math.Clamp(time, r.Start, r.End) : 0);
            var b = new MediaRect(original.X * sx, original.Y * sy, original.Width * sx, original.Height * sy);
            var margin = (1 + r.CoverageMargin) * Math.Max(sx, sy);
            if (r.Shape == RegionShape.Oval) margin *= Math.Max(b.Width, b.Height) / Math.Min(b.Width, b.Height);
            applied.Add((r, b, margin));
            var reach = ImageExport.Reach(r, b);
            var left = Math.Max(0, (int)Math.Floor(reach.X - margin)); var right = Math.Min(w, (int)Math.Ceiling(reach.X + reach.Width + margin));
            var top = Math.Max(0, (int)Math.Floor(reach.Y - margin)); var bottom = Math.Min(h, (int)Math.Ceiling(reach.Y + reach.Height + margin));
            var pw = right - left; var ph = bottom - top;
            if (pw <= 0 || ph <= 0) continue;
            byte[]? patch = null;
            var colour = (Color)ColorConverter.ConvertFromString(r.Color);
            if (r.Effect != RedactionEffect.Opaque)
            {
                patch = new byte[checked(pw * ph * 4)];
                for (var y = 0; y < ph; y++) Buffer.BlockCopy(pixels, ((top + y) * w + left) * 4, patch, y * pw * 4, pw * 4);
                // Flatten alpha before pooling: hidden RGB must not reappear in an opaque patch.
                for (var p = 0; p < patch.Length; p += 4)
                { for (var c = 0; c < 3; c++) patch[p + c] = (byte)((patch[p + c] * patch[p + 3] + 127) / 255); patch[p + 3] = 255; }
                if (r.Aggressive) patch = Aggressive(patch, pw, ph, r.Effect, cancellation);
                else if (r.Effect == RedactionEffect.Pixelate)
                {
                    var divisor = Divisors[r.Strength - 1] * Math.Max(sx, sy);
                    var gw = Math.Clamp((int)Math.Floor(pw / divisor), 1, pw); var gh = Math.Clamp((int)Math.Floor(ph / divisor), 1, ph);
                    patch = Resize(Resize(patch, pw, ph, gw, gh, true, cancellation), gw, gh, pw, ph, false, cancellation);
                }
                else
                {
                    var radius = Math.Max(1, (int)Math.Round(Radii[r.Strength - 1] * Math.Max(sx, sy)));
                    // Three separable box passes; the crop bounds prevent sampling unrelated areas.
                    for (var pass = 0; pass < 3; pass++) patch = Box(patch, pw, ph, radius, cancellation);
                }
            }
            for (var y = top; y < bottom; y++)
            {
                cancellation.ThrowIfCancellationRequested();
                for (var x = left; x < right; x++)
                {
                    if (!ImageExport.Covered(r, b, x + .5, y + .5, margin + Math.Sqrt(.5))) continue;
                    var p = (y * w + x) * 4;
                    if (patch == null) { pixels[p] = colour.B; pixels[p + 1] = colour.G; pixels[p + 2] = colour.R; }
                    else Buffer.BlockCopy(patch, ((y - top) * pw + x - left) * 4, pixels, p, 3);
                    pixels[p + 3] = 255;
                }
            }
        }
        annotations?.Composite(pixels, w, h, a => !m.IsVideo || timeline?.IsActive(a, time) == true,
            (a, x, y) => applied.Any(e => e.Region.Order > a.Order && Covers(e.Region, e.Bounds, e.Margin, x, y)), cancellation);
        var result = BitmapSource.Create(w, h, 96, 96, PixelFormats.Bgra32, null, pixels, checked(w * 4)); result.Freeze(); return result;
    }

    // The exact pixel test of the region pass: same integer bounds, same coverage rule.
    internal static bool Covers(Region r, MediaRect b, double margin, int x, int y) =>
        ImageExport.Reach(r, b) is var reach && x >= Math.Floor(reach.X - margin) && x < Math.Ceiling(reach.X + reach.Width + margin) && y >= Math.Floor(reach.Y - margin) && y < Math.Ceiling(reach.Y + reach.Height + margin) &&
        ImageExport.Covered(r, b, x + .5, y + .5, margin + Math.Sqrt(.5));
    private static byte[] Box(byte[] input, int w, int h, int radius, CancellationToken cancellation)
    {
        var temp = new byte[input.Length]; var output = new byte[input.Length];
        // Sliding windows, clamped at crop edges. Work is linear in the patch size.
        for (var y = 0; y < h; y++)
        {
            cancellation.ThrowIfCancellationRequested();
            for (var c = 0; c < 3; c++)
            {
                long sum = 0; for (var dx = -radius; dx <= radius; dx++) sum += input[(y * w + Math.Clamp(dx, 0, w - 1)) * 4 + c];
                for (var x = 0; x < w; x++)
                { temp[(y * w + x) * 4 + c] = (byte)((sum + radius) / (radius * 2 + 1)); sum += input[(y * w + Math.Clamp(x + radius + 1, 0, w - 1)) * 4 + c] - input[(y * w + Math.Clamp(x - radius, 0, w - 1)) * 4 + c]; }
            }
        }
        for (var x = 0; x < w; x++)
        {
            cancellation.ThrowIfCancellationRequested();
            for (var c = 0; c < 3; c++)
            {
                long sum = 0; for (var dy = -radius; dy <= radius; dy++) sum += temp[(Math.Clamp(dy, 0, h - 1) * w + x) * 4 + c];
                for (var y = 0; y < h; y++)
                { output[(y * w + x) * 4 + c] = (byte)((sum + radius) / (radius * 2 + 1)); sum += temp[(Math.Clamp(y + radius + 1, 0, h - 1) * w + x) * 4 + c] - temp[(Math.Clamp(y - radius, 0, h - 1) * w + x) * 4 + c]; }
            }
        }
        for (var p = 3; p < output.Length; p += 4) output[p] = 255; return output;
    }

    private static byte[] Aggressive(byte[] input, int w, int h, RedactionEffect effect, CancellationToken cancellation)
    {
        // Inherited 5-cell long axis, 4x lattice, overlapping 8x8 reflected pool,
        // 8 luma levels and 7 neutral-centred chroma symbols. Reconstruction only
        // receives this tiny quantised proxy, never the protected source patch.
        var gw = w >= h ? 5 : Math.Max(2, (int)Math.Round(5d * w / h));
        var gh = h > w ? 5 : Math.Max(2, (int)Math.Round(5d * h / w));
        var lw = gw * 4; var lh = gh * 4;
        var lattice = Resize(input, w, h, lw, lh, true, cancellation); var proxy = new byte[gw * gh * 4];
        int Reflect(int n, int length) { while (n < 0 || n >= length) n = n < 0 ? -n - 1 : 2 * length - n - 1; return n; }
        double Chroma(double value)
        {
            double[] symbols = [-48, -24, -10, 0, 10, 24, 48]; var delta = Math.Clamp(value - 128, -127, 127);
            return 128 + symbols.OrderBy(v => Math.Abs(delta - v)).First();
        }
        for (var y = 0; y < gh; y++) for (var x = 0; x < gw; x++)
        {
            double blue = 0, green = 0, red = 0;
            for (var dy = 0; dy < 8; dy++) for (var dx = 0; dx < 8; dx++)
            { var p = (Reflect(y * 4 - 2 + dy, lh) * lw + Reflect(x * 4 - 2 + dx, lw)) * 4; blue += lattice[p]; green += lattice[p + 1]; red += lattice[p + 2]; }
            blue = Math.Round(blue / 64); green = Math.Round(green / 64); red = Math.Round(red / 64);
            var luma = .2126 * red + .7152 * green + .0722 * blue;
            var cb = Chroma(128 + (blue - luma) * .5389); var cr = Chroma(128 + (red - luma) * .6350);
            var qy = Math.Round(Math.Clamp(luma, 0, 255) / (255d / 7)) * (255d / 7);
            red = qy + 1.5748 * (cr - 128); blue = qy + 1.8556 * (cb - 128); green = (qy - .2126 * red - .0722 * blue) / .7152;
            var at = (y * gw + x) * 4; proxy[at] = (byte)Math.Round(Math.Clamp(blue, 0, 255)); proxy[at + 1] = (byte)Math.Round(Math.Clamp(green, 0, 255)); proxy[at + 2] = (byte)Math.Round(Math.Clamp(red, 0, 255)); proxy[at + 3] = 255;
        }
        var divisor = effect == RedactionEffect.Pixelate ? 18 : 20;
        var cw = Math.Max(gw, Math.Max(2, w / divisor)); var ch = Math.Max(gh, Math.Max(2, h / divisor));
        var cosmetic = Resize(proxy, gw, gh, cw, ch, true, cancellation);
        if (effect == RedactionEffect.Pixelate) return Resize(cosmetic, cw, ch, w, h, false, cancellation);
        var sw = Math.Max(gw, (cw + 1) / 2); var sh = Math.Max(gh, (ch + 1) / 2);
        return Resize(Resize(cosmetic, cw, ch, sw, sh, true, cancellation), sw, sh, w, h, true, cancellation);
    }

    private static byte[] Resize(byte[] input, int w, int h, int dw, int dh, bool smooth, CancellationToken cancellation)
    {
        var output = new byte[checked(dw * dh * 4)];
        for (var y = 0; y < dh; y++)
        {
            cancellation.ThrowIfCancellationRequested();
            var fy = Math.Clamp((y + .5) * h / dh - .5, 0, h - 1); var y0 = (int)fy; var y1 = Math.Min(h - 1, y0 + 1); var ty = fy - y0;
            for (var x = 0; x < dw; x++)
            {
                var dest = (y * dw + x) * 4;
                if (!smooth) Buffer.BlockCopy(input, (Math.Min(h - 1, y * h / dh) * w + Math.Min(w - 1, x * w / dw)) * 4, output, dest, 3);
                else
                {
                    var fx = Math.Clamp((x + .5) * w / dw - .5, 0, w - 1); var x0 = (int)fx; var x1 = Math.Min(w - 1, x0 + 1); var tx = fx - x0;
                    for (var c = 0; c < 3; c++) output[dest + c] = (byte)Math.Round((1 - ty) * ((1 - tx) * input[(y0 * w + x0) * 4 + c] + tx * input[(y0 * w + x1) * 4 + c]) + ty * ((1 - tx) * input[(y1 * w + x0) * 4 + c] + tx * input[(y1 * w + x1) * 4 + c]));
                }
                output[dest + 3] = 255;
            }
        }
        return output;
    }
}
