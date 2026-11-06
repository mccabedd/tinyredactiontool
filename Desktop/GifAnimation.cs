using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace TinyRedaction.Desktop;

// Animated GIFs (0.28.0, David: "Animated gifs do not animate"). A GIF stores each frame as a patch over the one before
// (with its own place, size, delay and what to do with it afterwards), so TRT builds every whole frame the way browsers
// show it. Redactions and annotations on the image apply to every frame; export to GIF keeps the animation.
public sealed class GifAnimation
{
    public IReadOnlyList<BitmapSource> Frames { get; }
    // How long each frame shows, in milliseconds (a GIF counts in hundredths of a second).
    public IReadOnlyList<int> Delays { get; }
    public int Width { get; }
    public int Height { get; }
    public int TotalMilliseconds => Delays.Sum();
    private GifAnimation(List<BitmapSource> frames, List<int> delays, int width, int height) { Frames = frames; Delays = delays; Width = width; Height = height; }

    // Whole frames held in memory at most (the frames are kept as full pictures to play smoothly).
    internal const long MaxBytes = 512L * 1024 * 1024;

    // The animation in a GIF file, or null when it has a single frame (or is not a GIF TRT can read).
    public static GifAnimation? Load(string path, CancellationToken cancellation = default)
    {
        if (!Path.GetExtension(path).Equals(".gif", StringComparison.OrdinalIgnoreCase)) return null;
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        var decoder = new GifBitmapDecoder(stream, BitmapCreateOptions.PreservePixelFormat | BitmapCreateOptions.IgnoreColorProfile, BitmapCacheOption.OnLoad);
        if (decoder.Frames.Count < 2) return null;
        var width = Query<ushort>(decoder.Metadata, "/logscrdesc/Width", 0); var height = Query<ushort>(decoder.Metadata, "/logscrdesc/Height", 0);
        if (width == 0 || height == 0) { width = (ushort)decoder.Frames[0].PixelWidth; height = (ushort)decoder.Frames[0].PixelHeight; }
        if ((long)width * height * 4 * decoder.Frames.Count > MaxBytes) throw new InvalidDataException("This animated GIF is too large to play in the editor.");
        var canvas = new byte[width * height * 4];
        var frames = new List<BitmapSource>(); var delays = new List<int>();
        byte[]? restore = null;
        foreach (var frame in decoder.Frames)
        {
            cancellation.ThrowIfCancellationRequested();
            var metadata = frame.Metadata as BitmapMetadata;
            int left = Query<ushort>(metadata, "/imgdesc/Left", 0), top = Query<ushort>(metadata, "/imgdesc/Top", 0);
            var delay = Query<ushort>(metadata, "/grctlext/Delay", 0) * 10;
            var disposal = Query<byte>(metadata, "/grctlext/Disposal", 0);
            if (disposal == 3) restore = (byte[])canvas.Clone();
            var patch = new FormatConvertedBitmap(frame, PixelFormats.Bgra32, null, 0);
            int pw = patch.PixelWidth, ph = patch.PixelHeight;
            var pixels = new byte[pw * ph * 4]; patch.CopyPixels(pixels, pw * 4, 0);
            for (var y = 0; y < ph; y++)
            {
                var cy = top + y; if (cy < 0 || cy >= height) continue;
                for (var x = 0; x < pw; x++)
                {
                    var cx = left + x; if (cx < 0 || cx >= width) continue;
                    var from = (y * pw + x) * 4; if (pixels[from + 3] == 0) continue; // A transparent pixel shows what is under it.
                    var to = (cy * width + cx) * 4;
                    canvas[to] = pixels[from]; canvas[to + 1] = pixels[from + 1]; canvas[to + 2] = pixels[from + 2]; canvas[to + 3] = 255;
                }
            }
            var whole = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, canvas, width * 4); whole.Freeze();
            frames.Add(whole);
            // Browsers show a delay of 0 or 1 hundredth as a tenth of a second; so does TRT.
            delays.Add(delay <= 10 ? 100 : delay);
            // What happens to this frame's area before the next one is drawn.
            int x0 = Math.Max(0, left), x1 = Math.Min(width, left + pw);
            if (disposal == 2 && x1 > x0) for (var y = Math.Max(0, top); y < Math.Min(height, top + ph); y++) Array.Clear(canvas, (y * width + x0) * 4, (x1 - x0) * 4);
            else if (disposal == 3 && restore != null) { canvas = restore; restore = null; }
        }
        return new GifAnimation(frames, delays, width, height);
    }
    private static T Query<T>(BitmapMetadata? metadata, string query, T fallback)
    {
        try { return metadata?.GetQuery(query) is T value ? value : fallback; }
        catch (Exception ex) when (ex is NotSupportedException or ArgumentException or InvalidOperationException) { return fallback; }
    }
}
