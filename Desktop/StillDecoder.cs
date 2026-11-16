using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace TinyRedaction.Desktop;

// Faster picture opening (3.2.0, David: "Opening and Checking the File" showed on ordinary pictures). Starting FFmpeg for
// one picture took a second or more; Windows' own decoder reads a PNG, BMP or JPEG in a fraction of that. The result is
// the same as FFmpeg's: the same size and way up (JPEG EXIF orientation applied, as FFmpeg does), colour profiles ignored
// (as FFmpeg does), PNG pixels identical and JPEG within a few levels (decoder rounding). Anything else, or anything
// Windows can't read, still goes through FFmpeg. Export renders from this picture and checks the result against it.
internal static class StillDecoder
{
    internal static readonly string[] Extensions = [".png", ".bmp", ".jpg", ".jpeg", ".jpe"];
    internal static bool Handles(string path) => Extensions.Contains(Path.GetExtension(path).ToLowerInvariant());

    // The picture as plain pixels (Bgra32 with transparency, Bgr32 without), upright; null to use FFmpeg instead.
    internal static BitmapSource? Decode(string path)
    {
        if (!Handles(path)) return null;
        try
        {
            // A PNG with its own EXIF block (eXIf) may say how it was held; leave such rare files to FFmpeg.
            if (Path.GetExtension(path).Equals(".png", StringComparison.OrdinalIgnoreCase) && PngHasExif(path)) return null;
            var frame = BitmapDecoder.Create(new Uri(path), BitmapCreateOptions.IgnoreImageCache | BitmapCreateOptions.IgnoreColorProfile, BitmapCacheOption.OnLoad).Frames[0];
            var jpeg = Path.GetExtension(path).ToLowerInvariant() is ".jpg" or ".jpeg" or ".jpe";
            BitmapSource shown = jpeg && SlideshowWindow.Upright(frame) is { } turn ? new TransformedBitmap(frame, turn) : frame;
            var alpha = frame.Format == PixelFormats.Bgra32 || frame.Format == PixelFormats.Pbgra32 || frame.Format == PixelFormats.Rgba64
                        || frame.Format == PixelFormats.Prgba64 || frame.Format == PixelFormats.Rgba128Float || frame.Format == PixelFormats.Prgba128Float || frame.Palette?.Colors.Any(c => c.A < 255) == true;
            var format = alpha ? PixelFormats.Bgra32 : PixelFormats.Bgr32;
            var converted = new FormatConvertedBitmap(shown, format, null, 0);
            int w = converted.PixelWidth, h = converted.PixelHeight;
            var pixels = new byte[checked(w * h * 4)]; converted.CopyPixels(pixels, w * 4, 0);
            // Plain pixels, free of the decoder (read on another thread, it would belong to that thread).
            var plain = BitmapSource.Create(w, h, 96, 96, format, null, pixels, w * 4);
            plain.Freeze(); return plain;
        }
        catch (Exception ex) when (ex is NotSupportedException or IOException or FileFormatException or UnauthorizedAccessException or ArgumentException or InvalidOperationException or OverflowException or System.Runtime.InteropServices.COMException) { return null; }
    }
    // Looks through the chunks before the picture data for eXIf.
    private static bool PngHasExif(string path)
    {
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        var header = new byte[8]; if (stream.Read(header, 0, 8) != 8) return false;
        var chunk = new byte[8];
        while (stream.Read(chunk, 0, 8) == 8)
        {
            var length = (long)(uint)(chunk[0] << 24 | chunk[1] << 16 | chunk[2] << 8 | chunk[3]);
            var type = System.Text.Encoding.ASCII.GetString(chunk, 4, 4);
            if (type == "eXIf") return true;
            if (type is "IDAT" or "IEND") return false;
            stream.Seek(length + 4, SeekOrigin.Current);
        }
        return false;
    }
}
