using System.Buffers.Binary;
using System.Diagnostics;
using System.IO;
using System.Runtime.CompilerServices;
using System.Text;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;
public sealed record AnalysisFrame(int Index, int Width, int Height, byte[] Gray);
public sealed record TrackingLoss(int? LastMatchedIndex, int FirstUnmatchedIndex, string Reason);
public sealed record TrackingResult(double Start, double End, double SeedTime, MediaRect SeedBounds,
    List<GeometryKeyframe> Samples, List<TrackingSegment> Segments)
{
    public TrackingLoss? Loss { get; init; }
    public void Apply(Region region, FrameTimeline map)
    {
        region.Keyframes.RemoveAll(k => k.Origin == KeyframeOrigin.Tracking && k.Time >= Start && k.Time <= End);
        region.PutManual(SeedTime, SeedBounds); region.MergeTracking(Samples);
        var retained = new List<TrackingSegment>();
        foreach (var old in region.Tracking)
        {
            if (old.End < Start || old.Start > End) { retained.Add(old); continue; }
            var before = map.IndexAt(Start) - 1; var after = map.IndexAt(End) + 1;
            if (old.Start < Start && before >= 0 && map.Frames[before].Time >= old.Start) retained.Add(old with { End = Math.Min(old.End, map.Frames[before].Time) });
            if (old.End > End && after < map.Frames.Count && map.Frames[after].Time <= old.End) retained.Add(old with { Start = Math.Max(old.Start, map.Frames[after].Time) });
        }
        region.Tracking = retained.Concat(Segments).OrderBy(s => s.Start).ToList();
    }
}
public sealed class TrackingAnalysis(MediaTools tools)
{
    public async Task<TrackingResult> AnalyseAsync(MediaReference media, FrameTimeline map, Region region, int seedIndex,
        int targetIndex, IProgress<double>? progress, CancellationToken cancellation)
    {
        var start = Math.Min(seedIndex, targetIndex); var end = Math.Max(seedIndex, targetIndex);
        if (start < 0 || end >= map.Frames.Count || seedIndex == targetIndex) throw new InvalidOperationException("Tracking needs at least two frames.");
        using var sourceLease = new FileStream(media.Path, FileMode.Open, FileAccess.Read, FileShare.Read);
        if (!await ProjectStore.MatchesAsync(media, media.Path, cancellation)) throw new IOException("The original file has changed since it was opened. Tracking stopped.");
        var factor = Math.Min(1, 640d / Math.Max(media.Width, media.Height));
        var width = Math.Max(1, (int)Math.Round(media.Width * factor)); var height = Math.Max(1, (int)Math.Round(media.Height * factor));
        var sx = width / (double)media.Width; var sy = height / (double)media.Height;
        MediaRect Proxy(MediaRect b) => new(b.X * sx, b.Y * sy, b.Width * sx, b.Height * sy);
        MediaRect Canonical(MediaRect b) => new MediaRect(b.X / sx, b.Y / sy, b.Width / sx, b.Height / sy).Clamp(media.Width, media.Height);
        var seedTime = map.Frames[seedIndex].Time; var seedBounds = region.GeometryAt(seedTime);
        var samples = new List<GeometryKeyframe>(); var segments = new List<TrackingSegment>();
        var tracker = new AppearanceTracker(); var lastValid = seedTime; var initialized = false; var processed = 0;
        int? lastMatched = null; TrackingLoss? loss = null;
        bool Process(AnalysisFrame frame)
        {
            cancellation.ThrowIfCancellationRequested(); var time = map.Frames[frame.Index].Time;
            var manual = region.Keyframes.FirstOrDefault(k => k.Origin == KeyframeOrigin.Manual && Math.Abs(k.Time - time) < 0.0000001);
            var success = !initialized ? tracker.Seed(frame.Gray, width, height, Proxy(seedBounds)) :
                manual != null ? tracker.Seed(frame.Gray, width, height, Proxy(manual.Bounds)) : tracker.Advance(frame.Gray, width, height, cancellation);
            initialized = true;
            if (!success)
            {
                loss = new(lastMatched, frame.Index, tracker.Failure ?? "Tracking could not match the subject.");
                segments.Add(new(Math.Min(time, map.Frames[targetIndex].Time), Math.Max(time, map.Frames[targetIndex].Time), ReviewState.Lost,
                    tracker.Failure ?? "Tracking stopped; no automatic reacquisition."));
                return false;
            }
            if (frame.Index != seedIndex && manual == null) samples.Add(new(time, Canonical(tracker.Bounds), KeyframeOrigin.Tracking));
            lastMatched = frame.Index; lastValid = time; processed++; progress?.Report(processed / (double)(end - start + 1)); return true;
        }
        if (targetIndex > seedIndex)
        {
            await foreach (var frame in DecodeAsync(media.Path, start, end, width, height, cancellation))
                if (!Process(frame)) break;
        }
        else
        {
            if ((long)width * height * (end - start + 1) > 128L * 1024 * 1024) throw new InvalidOperationException("That is too long to track backward. Choose a shorter part.");
            var frames = new List<AnalysisFrame>();
            await foreach (var frame in DecodeAsync(media.Path, start, end, width, height, cancellation)) frames.Add(frame);
            for (var i = frames.Count - 1; i >= 0; i--) if (!Process(frames[i])) break;
        }
        if (samples.Count > 0) segments.Add(new(Math.Min(seedTime, lastValid), Math.Max(seedTime, lastValid), ReviewState.Unreviewed, "Appearance tracking requires review of every frame; identity is not guaranteed."));
        return new(map.Frames[start].Time, map.Frames[end].Time, seedTime, seedBounds, samples, segments) { Loss = loss };
    }
    private async IAsyncEnumerable<AnalysisFrame> DecodeAsync(string path, int start, int end, int width, int height,
        [EnumeratorCancellation] CancellationToken cancellation)
    {
        var info = new ProcessStartInfo(Path.Combine(AppContext.BaseDirectory, "tools", "ffmpeg.exe"))
        { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true };
        foreach (var arg in new[] { "-v", "error", "-i", path, "-map", "0:v:0", "-vf", $"select=between(n\\,{start}\\,{end})," + MediaTools.CanonicalScale + $",scale={width}:{height}",
            "-frames:v", (end - start + 1).ToString(System.Globalization.CultureInfo.InvariantCulture), "-fps_mode", "passthrough", "-f", "image2pipe", "-vcodec", "png", "pipe:1" }) info.ArgumentList.Add(arg);
        // Keep the verified MediaTools lease alive for this single continuous analysis process.
        GC.KeepAlive(tools);
        using var process = Process.Start(info) ?? throw new IOException("Could not start analysis decoder.");
        using var registration = cancellation.Register(() => { try { if (!process.HasExited) process.Kill(true); } catch (InvalidOperationException) { } });
        var errors = process.StandardError.ReadToEndAsync();
        try
        {
            var stdout = process.StandardOutput.BaseStream;
            for (var index = start; index <= end; index++)
            {
                using var encoded = await ReadPngAsync(stdout, cancellation);
                var bitmap = new BitmapImage(); bitmap.BeginInit(); bitmap.CacheOption = BitmapCacheOption.OnLoad; bitmap.StreamSource = encoded; bitmap.EndInit();
                if (bitmap.PixelWidth != width || bitmap.PixelHeight != height) throw new InvalidDataException("Analysis dimensions changed.");
                var gray = new FormatConvertedBitmap(bitmap, PixelFormats.Gray8, null, 0); var pixels = new byte[checked(width * height)]; gray.CopyPixels(pixels, width, 0);
                yield return new(index, width, height, pixels);
            }
            var extra = new byte[1]; if (await stdout.ReadAsync(extra, cancellation) != 0) throw new InvalidDataException("Unexpected extra analysis frame.");
            await process.WaitForExitAsync(cancellation);
            if (process.ExitCode != 0)
            {
                var error = (await errors).Replace(path, "[source media]", StringComparison.OrdinalIgnoreCase);
                throw new IOException(error[..Math.Min(error.Length, 1500)]);
            }
        }
        finally
        {
            if (!process.HasExited) { process.Kill(true); await process.WaitForExitAsync(); }
            await errors;
        }
    }
    internal static async Task<MemoryStream> ReadPngAsync(Stream input, CancellationToken cancellation, long maxFrameBytes = 32 * 1024 * 1024)
    {
        var result = new MemoryStream();
        try
        {
            var signature = new byte[8]; await input.ReadExactlyAsync(signature, cancellation);
            if (!signature.AsSpan().SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 })) throw new InvalidDataException("Invalid analysis PNG stream.");
            result.Write(signature);
            while (true)
            {
                var header = new byte[8]; await input.ReadExactlyAsync(header, cancellation); var length = BinaryPrimitives.ReadInt32BigEndian(header);
                if (length < 0 || length > 16 * 1024 * 1024 || result.Length + length + 12 > maxFrameBytes) throw new InvalidDataException("Decoded frame exceeds its memory limit.");
                var data = new byte[length + 4]; await input.ReadExactlyAsync(data, cancellation); result.Write(header); result.Write(data);
                if (Encoding.ASCII.GetString(header, 4, 4) == "IEND") break;
            }
            result.Position = 0; return result;
        }
        catch { result.Dispose(); throw; }
    }
}
