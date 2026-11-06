using System.Diagnostics;
using System.Globalization;
using System.IO;
using Drawing = System.Drawing;
using DrawingImaging = System.Drawing.Imaging;

namespace TinyRedaction.Desktop;

// Screen recording (0.12.0). The approved FFmpeg has no screen-grabbing input, so TRT grabs the area
// itself at a steady rate and streams the raw pixels to the approved FFmpeg, which writes an H.264
// MP4 (no sound). When a grab is late, the previous picture is repeated for the missed moments,
// so the video keeps real time. Paused time is not recorded.
internal sealed class ScreenRecorder : IDisposable
{
    private readonly string ffmpeg, output;
    private readonly Drawing.Rectangle region;
    private readonly int fps;
    private readonly bool cursor;
    private readonly Func<Drawing.Bitmap>? provider;
    private readonly Stopwatch clock = new();
    private readonly ManualResetEventSlim wake = new(false);
    private readonly TaskCompletionSource completion = new(TaskCreationOptions.RunContinuationsAsynchronously);
    private readonly object pauseLock = new();
    private Thread? worker;
    private Process? process;
    private volatile bool stopping, paused;
    private volatile int frames;
    private bool disposed;
    public string Error { get; private set; } = "";
    public int FrameCount => frames;
    public bool IsPaused => paused;
    public TimeSpan Elapsed { get { lock (pauseLock) return clock.Elapsed; } }
    public Task Completion => completion.Task;
    public string OutputPath => output;
    // 0.13.0: a yellow ring round the pointer while a mouse button is held (and briefly after), so clicks show.
    public bool ShowClicks { get; init; }
    private long lastClick = long.MinValue / 2;

    // provider replaces the screen grab (checks use it); it must return region-sized bitmaps.
    public ScreenRecorder(string ffmpegPath, string outputPath, Drawing.Rectangle area, int framesPerSecond, bool includeCursor, Func<Drawing.Bitmap>? frameProvider = null)
    {
        if (framesPerSecond is < 1 or > 60) throw new ArgumentOutOfRangeException(nameof(framesPerSecond));
        if (area.Width < 2 || area.Height < 2 || area.Width % 2 != 0 || area.Height % 2 != 0) throw new ArgumentException("The recording area needs an even width and height of at least 2 pixels.");
        if (!Path.IsPathRooted(ffmpegPath) || !Path.IsPathRooted(outputPath)) throw new ArgumentException("Recording paths must be absolute.");
        ffmpeg = ffmpegPath; output = outputPath; region = area; fps = framesPerSecond; cursor = includeCursor; provider = frameProvider;
    }
    public void Start()
    {
        if (worker != null || disposed) throw new InvalidOperationException("A recorder records once.");
        worker = new Thread(Record) { IsBackground = true, Name = "TRT screen recording" };
        worker.Start();
    }
    public void Pause() { lock (pauseLock) { if (paused || stopping) return; paused = true; clock.Stop(); } }
    public void Resume() { lock (pauseLock) { if (!paused) return; paused = false; clock.Start(); } wake.Set(); }
    public void RequestStop() { stopping = true; wake.Set(); }

    private void Record()
    {
        Task<string>? errors = null;
        try
        {
            using var dpi = new ScreenCapture.DpiScope();
            var info = new ProcessStartInfo(ffmpeg) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardInput = true, RedirectStandardError = true, RedirectStandardOutput = true };
            foreach (var arg in new[] { "-hide_banner", "-loglevel", "error", "-n", "-f", "rawvideo", "-pixel_format", "bgr0", "-video_size", $"{region.Width}x{region.Height}",
                "-framerate", fps.ToString(CultureInfo.InvariantCulture), "-i", "pipe:0", "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "20", "-pix_fmt", "yuv420p",
                "-map_metadata", "-1", "-metadata", "title=", "-movflags", "+faststart", output }) info.ArgumentList.Add(arg);
            process = Process.Start(info) ?? throw new IOException("Could not start the approved media tool.");
            errors = process.StandardError.ReadToEndAsync();
            _ = process.StandardOutput.BaseStream.CopyToAsync(Stream.Null);
            var input = process.StandardInput.BaseStream;
            var row = region.Width * 4; var buffer = new byte[row * region.Height];
            lock (pauseLock) clock.Start();
            while (!stopping)
            {
                if (paused) { wake.Wait(250); wake.Reset(); continue; }
                using (var image = provider?.Invoke() ?? ScreenCapture.Grab(region, cursor))
                {
                    if (image.Width != region.Width || image.Height != region.Height) throw new InvalidDataException("The recorded picture changed size.");
                    if (ShowClicks) DrawClick(image);
                    var data = image.LockBits(new(0, 0, image.Width, image.Height), DrawingImaging.ImageLockMode.ReadOnly, DrawingImaging.PixelFormat.Format32bppRgb);
                    try { for (var y = 0; y < region.Height; y++) System.Runtime.InteropServices.Marshal.Copy(data.Scan0 + y * data.Stride, buffer, y * row, row); }
                    finally { image.UnlockBits(data); }
                }
                var target = (long)Math.Floor(Elapsed.TotalSeconds * fps) + 1;
                if (target - frames > fps * 10L) throw new IOException("Screen recording could not keep up. Try a smaller area or fewer frames per second.");
                while (frames < target) { input.Write(buffer, 0, buffer.Length); frames++; }
                var delay = frames * 1000.0 / fps - Elapsed.TotalMilliseconds;
                if (delay >= 1 && !stopping) { wake.Wait((int)delay); if (!stopping) wake.Reset(); }
            }
        }
        catch (Exception ex) { Error = ex.Message; }
        finally
        {
            lock (pauseLock) clock.Stop();
            if (process != null)
            {
                try { process.StandardInput.Close(); } catch (IOException) { }
                try
                {
                    if (!process.WaitForExit(60000)) { process.Kill(true); Error = "The recording could not be finished in time."; process.WaitForExit(2000); }
                    else if (process.ExitCode != 0 && Error.Length == 0) Error = "The recording could not be written.";
                    var detail = errors?.GetAwaiter().GetResult().Replace(output, "[recording]", StringComparison.OrdinalIgnoreCase).Trim() ?? "";
                    if (Error.Length > 0 && detail.Length > 0) Error += " " + detail[..Math.Min(500, detail.Length)];
                }
                catch (Exception ex) when (ex is InvalidOperationException or IOException) { if (Error.Length == 0) Error = ex.Message; }
                process.Dispose(); process = null;
            }
            completion.TrySetResult();
        }
    }
    private void DrawClick(Drawing.Bitmap image)
    {
        var now = Environment.TickCount64;
        if ((GetAsyncKeyState(0x01) & 0x8000) != 0 || (GetAsyncKeyState(0x02) & 0x8000) != 0) lastClick = now;
        if (now - lastClick > 300) return;
        var at = ScreenCapture.CursorPosition; var x = at.X - region.X; var y = at.Y - region.Y; const int radius = 18;
        using var g = Drawing.Graphics.FromImage(image);
        g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.AntiAlias;
        using var fill = new Drawing.SolidBrush(Drawing.Color.FromArgb(90, 255, 220, 0));
        using var ring = new Drawing.Pen(Drawing.Color.FromArgb(230, 255, 200, 0), 3);
        g.FillEllipse(fill, x - radius, y - radius, radius * 2, radius * 2); g.DrawEllipse(ring, x - radius, y - radius, radius * 2, radius * 2);
    }
    [System.Runtime.InteropServices.DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
    public void Dispose()
    {
        if (disposed) return;
        disposed = true; RequestStop();
        if (worker != null && worker.IsAlive && !worker.Join(65000)) { try { process?.Kill(true); } catch (InvalidOperationException) { } worker.Join(2000); }
        if (worker == null || !worker.IsAlive) wake.Dispose();
    }
}
