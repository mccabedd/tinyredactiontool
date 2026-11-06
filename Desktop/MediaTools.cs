using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text.Json;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

public sealed class MediaTools : IDisposable
{
    public const string CanonicalScale = "scale=w='if(gte(sar,1),ceil(iw*sar),iw)':h='if(lt(sar,1),ceil(ih/sar),ih)':reset_sar=1";
    private readonly List<FileStream> locks = [];
    private readonly string directory = Path.Combine(AppContext.BaseDirectory, "tools");
    public MediaTools()
    {
        try
        {
            Verify("ffmpeg.exe", "643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC");
            Verify("ffprobe.exe", "84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2");
        }
        catch { Dispose(); throw; }
    }
    private void Verify(string name, string hash)
    {
        var stream = new FileStream(Path.Combine(directory, name), FileMode.Open, FileAccess.Read, FileShare.Read);
        locks.Add(stream);
        if (Convert.ToHexString(SHA256.HashData(stream)) != hash) throw new InvalidDataException("TRT's FFmpeg files have been changed. TRT will not use them.");
    }
    public Task<byte[]> RunAsync(string tool, IEnumerable<string> args, string sensitivePath, CancellationToken cancellation) =>
        RunAsync(tool, args, sensitivePath, null, cancellation);
    // Optional standard input carries only already-prepared, in-memory data (for example a redacted PNG).
    public async Task<byte[]> RunAsync(string tool, IEnumerable<string> args, string sensitivePath, ReadOnlyMemory<byte>? input, CancellationToken cancellation)
    {
        var info = new ProcessStartInfo(Path.Combine(directory, tool)) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true, RedirectStandardInput = input != null };
        foreach (var arg in args) info.ArgumentList.Add(arg);
        using var process = Process.Start(info) ?? throw new IOException("Could not start the approved media tool.");
        using var registration = cancellation.Register(() => { try { if (!process.HasExited) process.Kill(true); } catch (InvalidOperationException) { } });
        // Drain both pipes concurrently to prevent a full diagnostic pipe deadlocking media processing.
        var errorTask = process.StandardError.ReadToEndAsync(cancellation);
        using var output = new MemoryStream();
        var outputTask = process.StandardOutput.BaseStream.CopyToAsync(output, cancellation);
        if (input is { } data)
        {
            // A tool that rejects its input exits early; its exit code and diagnostics report why.
            try { await process.StandardInput.BaseStream.WriteAsync(data, cancellation); await process.StandardInput.BaseStream.FlushAsync(cancellation); }
            catch (IOException) { }
            finally { try { process.StandardInput.Close(); } catch (IOException) { } }
        }
        await outputTask;
        await process.WaitForExitAsync(cancellation);
        var error = await errorTask;
        cancellation.ThrowIfCancellationRequested();
        if (process.ExitCode != 0)
        {
            if (!string.IsNullOrEmpty(sensitivePath)) error = error.Replace(sensitivePath, "[source media]", StringComparison.OrdinalIgnoreCase);
            throw new IOException(error[..Math.Min(error.Length, 1500)]);
        }
        return output.ToArray();
    }
    private readonly Dictionary<string, HashSet<string>> capabilities = [];
    // Inspects the approved build instead of assuming common FFmpeg components exist.
    // kind is "encoders", "muxers" or "filters".
    public async Task<bool> SupportsAsync(string kind, string name, CancellationToken cancellation)
    {
        if (kind is not ("encoders" or "muxers" or "filters")) throw new ArgumentException("Unknown capability list.", nameof(kind));
        HashSet<string>? names;
        lock (capabilities) capabilities.TryGetValue(kind, out names);
        if (names == null)
        {
            var text = System.Text.Encoding.UTF8.GetString(await RunAsync("ffmpeg.exe", ["-hide_banner", "-" + kind], "", cancellation));
            names = ParseCapabilityList(text);
            lock (capabilities) capabilities[kind] = names;
        }
        return names.Contains(name);
    }
    // Listing rows are "<flags> <name> [description]" (the approved build omits descriptions);
    // legend rows are "<flags> = <meaning>".
    // Muxer rows may name several comma-separated formats.
    internal static HashSet<string> ParseCapabilityList(string text)
    {
        var names = new HashSet<string>(StringComparer.Ordinal);
        foreach (var raw in text.Split('\n'))
        {
            var parts = raw.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
            // Section headings ("Encoders:", "File formats:") end with a colon.
            if (parts.Length < 2 || parts[1] == "=" || parts[^1].EndsWith(':')) continue;
            foreach (var name in parts[1].Split(',', StringSplitOptions.RemoveEmptyEntries)) names.Add(name);
        }
        return names;
    }
    public async Task<FrameTimeline> ProbeTimelineAsync(string path, CancellationToken cancellation)
    {
        // The independent frame count runs at the same time as the timing map (0.10.4): both read the
        // whole video, and neither needs the other's result until the comparison at the end.
        using var stop = CancellationTokenSource.CreateLinkedTokenSource(cancellation);
        var countTask = RunAsync("ffprobe.exe", ["-v", "error", "-select_streams", "v:0", "-count_frames", "-show_entries", "stream=nb_read_frames", "-of", "json", path], path, stop.Token);
        try { return await ProbeTimelineAsync(path, countTask, cancellation); }
        catch { stop.Cancel(); try { await countTask; } catch (Exception) { } throw; }
    }
    private async Task<FrameTimeline> ProbeTimelineAsync(string path, Task<byte[]> countTask, CancellationToken cancellation)
    {
        var json = await RunAsync("ffprobe.exe", ["-v", "error", "-select_streams", "v:0", "-show_frames", "-show_entries", "frame=best_effort_timestamp,best_effort_timestamp_time,pkt_duration_time,duration_time", "-of", "json", path], path, cancellation);
        var timeline = TimelineFromFrames(json);
        // Independently count decoded frames; a timing map alone is insufficient.
        var countJson = await countTask;
        using var counted = JsonDocument.Parse(countJson);
        var count = int.Parse(counted.RootElement.GetProperty("streams")[0].GetProperty("nb_read_frames").GetString()!, CultureInfo.InvariantCulture);
        if (count != timeline.Frames.Count) throw new InvalidDataException("Decoded frame count does not match the timing map.");
        return timeline;
    }
    // The timing map from ffprobe's frame list (JSON).
    internal static FrameTimeline TimelineFromFrames(byte[] json)
    {
        using var doc = JsonDocument.Parse(json);
        var frames = doc.RootElement.GetProperty("frames").EnumerateArray().ToArray();
        // 0.22.0 (David's 1970 AVI): old MPEG-4 AVIs can end with a frame ffprobe gives no timestamp; the
        // decoder gives it the next one in step (checked: pts 1356 after 1355), so the map does the same.
        // A missing timestamp anywhere else still stops the video from opening.
        var raw = new List<(long Pts, double Time, double? Duration)>();
        for (var i = 0; i < frames.Length; i++)
        {
            var f = frames[i];
            double? hint = f.TryGetProperty("duration_time", out var d) ? Parse(d) : f.TryGetProperty("pkt_duration_time", out d) ? Parse(d) : null;
            if (f.TryGetProperty("best_effort_timestamp", out var pts) && f.TryGetProperty("best_effort_timestamp_time", out var at))
                raw.Add((pts.GetInt64(), Parse(at), hint));
            else if (i == frames.Length - 1 && raw.Count >= 2)
            {
                var step = raw[^1].Pts - raw[^2].Pts; var seconds = raw[^1].Time - raw[^2].Time;
                if (step <= 0 || seconds <= 0) throw new InvalidDataException("The video's last frame has no timestamp and its place can't be worked out.");
                raw.Add((raw[^1].Pts + step, raw[^1].Time + seconds, hint));
            }
            else throw new InvalidDataException($"Frame {i + 1} of the video has no timestamp, so TRT can't place it exactly.");
        }
        var stamps = new List<FrameStamp>();
        for (var i = 0; i < raw.Count; i++)
            stamps.Add(new(raw[i].Pts, raw[i].Time, i + 1 < raw.Count ? raw[i + 1].Time - raw[i].Time : raw[i].Duration ?? 0));
        var origin = stamps.Count == 0 ? 0 : stamps[0].Time;
        return new FrameTimeline(stamps.Select(f => f with { Time = f.Time - origin }), origin);
    }
    private static double Parse(JsonElement e) => double.Parse(e.GetString()!, CultureInfo.InvariantCulture);
    public async Task<BitmapSource> FrameAsync(string path, FrameStamp? frame, int? thumbnailWidth, CancellationToken cancellation) =>
        DecodePng((await FramePngsAsync(path, frame == null ? null : [frame], thumbnailWidth, cancellation))[0]);
    // Seeking (0.10.2): the input is opened at a point SeekLead seconds before the first wanted
    // frame, so FFmpeg starts at the keyframe before it instead of decoding from the start of the
    // file. Frames are still chosen by their exact presentation timestamp, so the pictures are
    // identical; if the seek ever misses a frame, the request is repeated from the start.
    internal const double SeekLead = 3;
    // Decodes a run of consecutive frames (in timeline order) in one pass, one PNG each.
    public async Task<List<byte[]>> FramePngsAsync(string path, IReadOnlyList<FrameStamp>? frames, int? thumbnailWidth, CancellationToken cancellation)
    {
        var seek = frames is { Count: > 0 } && frames[0].Time > SeekLead ? frames[0].Time - SeekLead : 0;
        var result = await DecodePngsAsync(path, frames, thumbnailWidth, seek, cancellation);
        if (frames != null && result.Count != frames.Count && seek > 0) result = await DecodePngsAsync(path, frames, thumbnailWidth, 0, cancellation);
        if (result.Count != Math.Max(1, frames?.Count ?? 1)) throw new InvalidDataException("The exact requested frame was not decoded.");
        return result;
    }
    internal async Task<List<byte[]>> DecodePngsAsync(string path, IReadOnlyList<FrameStamp>? frames, int? thumbnailWidth, double seek, CancellationToken cancellation)
    {
        var args = new List<string> { "-v", "error", "-threads", "1", "-copyts" };
        if (seek > 0) args.AddRange(["-noaccurate_seek", "-ss", seek.ToString("0.######", CultureInfo.InvariantCulture)]);
        args.AddRange(["-i", path, "-map", "0:v:0"]);
        var filters = new List<string>();
        if (frames is { Count: 1 }) filters.Add("select=eq(pts\\," + frames[0].Pts.ToString(CultureInfo.InvariantCulture) + ")");
        else if (frames is { Count: > 1 }) filters.Add($"select=between(pts\\,{frames[0].Pts.ToString(CultureInfo.InvariantCulture)}\\,{frames[^1].Pts.ToString(CultureInfo.InvariantCulture)})");
        filters.Add(CanonicalScale);
        if (thumbnailWidth != null) filters.Add($"scale={thumbnailWidth.Value}:-1");
        args.AddRange(["-vf", string.Join(',', filters)]);
        args.AddRange(["-frames:v", Math.Max(1, frames?.Count ?? 1).ToString(CultureInfo.InvariantCulture), "-fps_mode", "passthrough", "-f", "image2pipe", "-vcodec", "png", "pipe:1"]);
        return SplitPngs(await RunAsync("ffmpeg.exe", args, path, cancellation));
    }
    // image2pipe writes the PNGs back to back; each ends with its IEND chunk.
    internal static List<byte[]> SplitPngs(byte[] bytes)
    {
        var result = new List<byte[]>(); var start = 0;
        while (start + 8 <= bytes.Length)
        {
            var at = start + 8;
            while (true)
            {
                if (at + 12 > bytes.Length) return result;
                var length = (bytes[at] << 24) | (bytes[at + 1] << 16) | (bytes[at + 2] << 8) | bytes[at + 3];
                if (length < 0 || at + 12L + length > bytes.Length) return result;
                var end = bytes[at + 4] == (byte)'I' && bytes[at + 5] == (byte)'E' && bytes[at + 6] == (byte)'N' && bytes[at + 7] == (byte)'D';
                at += 12 + length;
                if (end) break;
            }
            result.Add(bytes[start..at]); start = at;
        }
        return result;
    }
    public static BitmapSource DecodePng(byte[] png, int decodeWidth = 0)
    {
        using var stream = new MemoryStream(png);
        var bitmap = new BitmapImage();
        bitmap.BeginInit(); bitmap.CacheOption = BitmapCacheOption.OnLoad; bitmap.StreamSource = stream;
        if (decodeWidth > 0) bitmap.DecodePixelWidth = decodeWidth;
        bitmap.EndInit(); bitmap.Freeze();
        return bitmap;
    }
    public void Dispose() { foreach (var stream in locks) stream.Dispose(); locks.Clear(); }
}

// Exact frames already decoded, kept as their PNG bytes (memory only, never written to disk):
// stepping and scrubbing over them needs no FFmpeg run. Least recently used frames go first.
public sealed class FrameCache
{
    private const long Budget = 256L * 1024 * 1024;
    private readonly Dictionary<(string, long), LinkedListNode<((string, long) Key, byte[] Png)>> map = [];
    private readonly LinkedList<((string, long) Key, byte[] Png)> order = new();
    private long bytes;
    public bool TryGet(string source, long pts, out byte[] png)
    {
        lock (map)
        {
            if (map.TryGetValue((source, pts), out var node)) { order.Remove(node); order.AddFirst(node); png = node.Value.Png; return true; }
            png = []; return false;
        }
    }
    public bool Contains(string source, long pts) { lock (map) return map.ContainsKey((source, pts)); }
    public void Add(string source, long pts, byte[] png)
    {
        lock (map)
        {
            if (map.ContainsKey((source, pts))) return;
            map[(source, pts)] = order.AddFirst(((source, pts), png)); bytes += png.Length;
            while (bytes > Budget && order.Last is { } last) { order.RemoveLast(); map.Remove(last.Value.Key); bytes -= last.Value.Png.Length; }
        }
    }
    public void Clear() { lock (map) { map.Clear(); order.Clear(); bytes = 0; } }
}

// One extraction at a time, cancellable debounce, and a small memory-only LRU cache.
// A frame already in the exact-frame cache is shrunk from there instead of running FFmpeg.
public sealed class ThumbnailService(MediaTools tools, FrameCache? frames = null) : IDisposable
{
    private readonly SemaphoreSlim gate = new(1);
    private readonly Dictionary<(string, long), BitmapSource> cache = [];
    private readonly Queue<(string, long)> order = [];
    private CancellationTokenSource? pending;
    public async Task<BitmapSource?> RequestAsync(string path, FrameStamp frame, string sourceFingerprint = "")
    {
        pending?.Cancel();
        var request = new CancellationTokenSource(); pending = request;
        var token = request.Token;
        try
        {
            var key = (path + "|" + sourceFingerprint, frame.Pts);
            if (cache.TryGetValue(key, out var ready)) return ready;
            if (frames != null && sourceFingerprint != "" && frames.TryGet(sourceFingerprint, frame.Pts, out var png)) return MediaTools.DecodePng(png, 224);
            await Task.Delay(100, token);
            await gate.WaitAsync(token);
            try
            {
                if (cache.TryGetValue(key, out var existing)) return existing;
                var bitmap = await tools.FrameAsync(path, frame, 224, token);
                token.ThrowIfCancellationRequested();
                cache.Add(key, bitmap); order.Enqueue(key);
                while (order.Count > 24) cache.Remove(order.Dequeue());
                return bitmap;
            }
            finally { gate.Release(); }
        }
        catch (OperationCanceledException) { return null; }
        finally { if (ReferenceEquals(pending, request)) pending = null; request.Dispose(); }
    }
    public void Cancel() { pending?.Cancel(); }
    public void Dispose() { Cancel(); }
}
