using System.Globalization;

namespace TinyRedaction.Core;

public enum StillFormat { Png, Jpeg, Gif, WebP }

// Still-image output formats inherited from the v2.5.x baseline (BASE-059).
// PNG is written and verified pixel-for-pixel in process. JPG, GIF and WebP are
// encoded by the approved private FFmpeg from an already-redacted in-memory PNG;
// the source file is never given to the encoder, so source metadata cannot be copied.
public static class StillImageFormats
{
    public static StillFormat? FromPath(string path) => System.IO.Path.GetExtension(path).ToLowerInvariant() switch
    {
        ".png" => StillFormat.Png,
        ".jpg" or ".jpeg" => StillFormat.Jpeg,
        ".gif" => StillFormat.Gif,
        ".webp" => StillFormat.WebP,
        _ => null
    };
    public static string Extension(StillFormat format) => format switch
    { StillFormat.Png => ".png", StillFormat.Jpeg => ".jpg", StillFormat.Gif => ".gif", _ => ".webp" };
    public static string DisplayName(StillFormat format) => format switch
    { StillFormat.Png => "PNG", StillFormat.Jpeg => "JPG", StillFormat.Gif => "GIF", _ => "WebP" };
    // Codec name FFprobe must report for the finished file.
    public static string ProbeCodec(StillFormat format) => format switch
    { StillFormat.Png => "png", StillFormat.Jpeg => "mjpeg", StillFormat.Gif => "gif", _ => "webp" };
    public static string Encoder(StillFormat format) => format switch
    { StillFormat.Png => "png", StillFormat.Jpeg => "mjpeg", StillFormat.Gif => "gif", _ => "libwebp" };
    public static string Muxer(StillFormat format) => format switch
    { StillFormat.Gif => "gif", StillFormat.WebP => "webp", _ => "image2" };
    public static IReadOnlyList<string> RequiredFilters(StillFormat format) =>
        format == StillFormat.Gif ? ["split", "palettegen", "paletteuse"] : [];

    // Every encoder is named explicitly. Normal quality reproduces the inherited
    // baseline values (mjpeg -q:v 3, libwebp -q:v 90, palettegen/paletteuse bayer). GIF uses
    // bayer_scale=5: the default scale speckled flat opaque boxes with neighbouring
    // palette colours, so boxes were not one solid colour.
    public static IReadOnlyList<string> EncoderArguments(StillFormat format, string quality)
    {
        var level = quality == "High" ? 0 : quality == "Smaller" ? 2 : 1;
        return format switch
        {
            StillFormat.Jpeg => ["-map", "0:v:0", "-c:v", "mjpeg", "-q:v", new[] { "2", "3", "6" }[level].ToString(CultureInfo.InvariantCulture)],
            StillFormat.WebP => ["-map", "0:v:0", "-c:v", "libwebp", "-lossless", "0", "-q:v", new[] { "95", "90", "75" }[level]],
            StillFormat.Gif => ["-filter_complex", "[0:v:0]split[trtpal1][trtpal2];[trtpal1]palettegen=stats_mode=single[trtpal];[trtpal2][trtpal]paletteuse=dither=bayer:bayer_scale=5[trtgif]",
                "-map", "[trtgif]", "-c:v", "gif"],
            _ => throw new InvalidOperationException("PNG is encoded in process.")
        };
    }

    // Sanity bounds for the decoded result of a lossy/indexed encode. These detect
    // an encoder or decoder producing a different picture; they are not a proof of
    // privacy. Redaction happens before encoding, so compression cannot restore
    // replaced source pixels. MeanLimit applies to brightness (Rec. 601 luma): JPG
    // and WebP store colour at reduced resolution, so per-channel RGB differences on
    // fine saturated detail reach ~64 for WebP even though the picture is correct,
    // while luma stays within ~6. InteriorLimit is a per-channel RGB bound inside
    // flat opaque boxes.
    public static (double MeanLimit, int InteriorLimit) Tolerance(StillFormat format) => format switch
    {
        StillFormat.Png => (0, 0),
        StillFormat.Gif => (16, 48),
        _ => (12, 32)
    };

    // Interior pixels are at least `radius` pixels inside `mask`. Pixels beyond the
    // image edge count as inside, so boxes touching an edge are still checked.
    public static bool[] Erode(bool[] mask, int width, int height, int radius)
    {
        if (mask.Length != width * height) throw new ArgumentException("Mask size mismatch.");
        // Prefix sums of uncovered pixels.
        var sums = new int[(width + 1) * (height + 1)];
        for (var y = 0; y < height; y++)
        {
            var row = 0;
            for (var x = 0; x < width; x++)
            {
                row += mask[y * width + x] ? 0 : 1;
                sums[(y + 1) * (width + 1) + x + 1] = sums[y * (width + 1) + x + 1] + row;
            }
        }
        var result = new bool[mask.Length];
        for (var y = 0; y < height; y++)
            for (var x = 0; x < width; x++)
            {
                if (!mask[y * width + x]) continue;
                var x0 = Math.Max(0, x - radius); var x1 = Math.Min(width, x + radius + 1);
                var y0 = Math.Max(0, y - radius); var y1 = Math.Min(height, y + radius + 1);
                var holes = sums[y1 * (width + 1) + x1] - sums[y0 * (width + 1) + x1] - sums[y1 * (width + 1) + x0] + sums[y0 * (width + 1) + x0];
                result[y * width + x] = holes == 0;
            }
        return result;
    }

    // Compares straight BGRA buffers. Returns null when acceptable, otherwise a
    // user-readable reason. PNG requires exact equality.
    public static string? CompareDecoded(StillFormat format, byte[] expected, byte[] actual, int width, int height, bool[]? interior)
    {
        if (expected.Length != checked(width * height * 4) || actual.Length != expected.Length) return "Decoded output dimensions differ from the prepared redaction.";
        if (format == StillFormat.Png) return expected.AsSpan().SequenceEqual(actual) ? null : "Decoded output coverage differs from the prepared redaction.";
        var (meanLimit, interiorLimit) = Tolerance(format);
        double total = 0;
        for (var p = 0; p < expected.Length; p += 4)
        {
            if (actual[p + 3] < 250) return "The encoded image contains transparency that was not in the prepared redaction.";
            var worst = 0;
            for (var c = 0; c < 3; c++) worst = Math.Max(worst, Math.Abs(expected[p + c] - actual[p + c]));
            total += Math.Abs(0.114 * (expected[p] - actual[p]) + 0.587 * (expected[p + 1] - actual[p + 1]) + 0.299 * (expected[p + 2] - actual[p + 2]));
            if (interior != null && interior[p / 4] && worst > interiorLimit)
                return $"Encoded output differs inside an opaque redaction (pixel {p / 4 % width},{p / 4 / width}).";
        }
        var mean = total / ((double)width * height);
        return mean <= meanLimit ? null : $"Encoded output differs too much from the prepared redaction (mean brightness error {mean:0.0}).";
    }

    // Alpha is removed for JPG/GIF/WebP. RGB is premultiplied (composited over black)
    // first, so colour data hidden under transparent source pixels is not revealed.
    public static void FlattenOverBlack(byte[] bgra)
    {
        for (var p = 0; p < bgra.Length; p += 4)
        {
            var a = bgra[p + 3];
            if (a == 255) continue;
            for (var c = 0; c < 3; c++) bgra[p + c] = (byte)((bgra[p + c] * a + 127) / 255);
            bgra[p + 3] = 255;
        }
    }
}
