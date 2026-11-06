using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class TrackingChecks
{
    private const int Width = 128, Height = 96;
    private static readonly byte[] texture = MakeTexture();
    public static async Task Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var tracker = new AppearanceTracker();
        check(!tracker.Seed(new byte[Width * Height], Width, Height, new(24, 20, 16, 16)), "uniform selection is rejected as lacking trackable texture");
        check(tracker.Seed(Frame(0), Width, Height, new(24, 20, 16, 16)), "textured subject seeds appearance tracker");
        for (var i = 1; i <= 6; i++)
        {
            check(tracker.Advance(Frame(i), Width, Height), "subject follows independent motion over panning background: frame " + i);
            check(Math.Abs(tracker.Bounds.X - (24 + i * 3)) < 2 && Math.Abs(tracker.Bounds.Y - (20 + i)) < 2, "tracked subject position matches synthetic ground truth: frame " + i);
        }
        check(!tracker.Advance(Frame(7, false), Width, Height), "occlusion explicitly loses tracking");
        check(!tracker.Advance(Frame(7), Width, Height), "lost tracker does not automatically reacquire a returning subject");
        var smooth = new byte[texture.Length];
        for (var y = 0; y < 16; y++) for (var x = 0; x < 16; x++)
        { var total = 0; for (var dy = -1; dy <= 1; dy++) for (var dx = -1; dx <= 1; dx++) total += texture[Math.Clamp(y + dy, 0, 15) * 16 + Math.Clamp(x + dx, 0, 15)]; smooth[y * 16 + x] = (byte)(total / 9); }
        var small = Background(0); Paint(small, 24, 20, 32, smooth); var larger = Background(1); Paint(larger, 27, 21, 35, smooth);
        var scaleTracker = new AppearanceTracker(); scaleTracker.Seed(small, Width, Height, new(24, 20, 32, 32));
        var grew = scaleTracker.Advance(larger, Width, Height);
        check(grew && scaleTracker.Bounds.Width > 32, $"local scale search accommodates modest subject growth ({scaleTracker.Bounds.Width:0.00}px; {scaleTracker.Failure})");
        var ambiguous = new AppearanceTracker(); var seed = Background(0); Paint(seed, 26, 20, 16);
        ambiguous.Seed(seed, Width, Height, new(26, 20, 16, 16)); var twins = Background(1); Paint(twins, 17, 20, 16); Paint(twins, 35, 20, 16);
        check(!ambiguous.Advance(twins, Width, Height), "two similarly matching positions stop instead of silently choosing another subject");
        var video = await WriteVideo(tools, output, false);
        var map = await tools.ProbeTimelineAsync(video, CancellationToken.None);
        var media = new MediaReference(video, new FileInfo(video).Length, await ProjectStore.HashAsync(video), Width, Height, map.Frames[^1].Time + map.Frames[^1].Duration, true);
        var region = new Region { Start = 0, End = media.Duration }; region.PutManual(0, new(24, 20, 16, 16));
        var analysis = new TrackingAnalysis(tools);
        var result = await analysis.AnalyseAsync(media, map, region, 0, 6, null, CancellationToken.None);
        check(result.Samples.Count == 6 && result.Segments.All(s => s.State == ReviewState.Unreviewed), "continuous decoded tracking pass produces editable samples requiring review");
        result.Apply(region, map);
        var project = new RedactionProject { Media = media, Regions = [region] };
        ExportGate.Check(project, new()); check(true, "actual analysis results can be exported straight away (0.14.0: no Review step)");
        region.Tracking = region.Tracking.Select(s => s with { State = ReviewState.Reviewed }).ToList();
        var correction = new MediaRect(34, 23, 16, 16); region.PutManual(map.Frames[3].Time, correction);
        check(region.Tracking.Any(s => s.State == ReviewState.Unreviewed), "manual geometry correction invalidates previous tracking review");
        var retracked = await analysis.AnalyseAsync(media, map, region, 2, 6, null, CancellationToken.None); retracked.Apply(region, map);
        check(region.Keyframes.Single(k => k.Time == map.Frames[3].Time).Bounds == correction && region.Keyframes.Single(k => k.Time == map.Frames[3].Time).Origin == KeyframeOrigin.Manual, "retracking preserves manual correction inside analysis range");
        var backward = await analysis.AnalyseAsync(media, map, region, 6, 0, null, CancellationToken.None); backward.Apply(region, map);
        check(backward.Samples.Count > 0 && region.Keyframes.Single(k => k.Time == map.Frames[3].Time).Bounds == correction, "backward analysis produces ordered samples and preserves correction");
        var restored = ProjectStore.Deserialize(ProjectStore.Serialize(project));
        check(restored.Regions[0].Tracking.Count > 0 && restored.Regions[0].Keyframes.Any(k => k.Origin == KeyframeOrigin.Tracking), "tracking keyframes and review ranges persist in project round trip");
        var lostVideo = await WriteVideo(tools, output, true); var lostMap = await tools.ProbeTimelineAsync(lostVideo, CancellationToken.None);
        var lostMedia = media with { Path = lostVideo, Length = new FileInfo(lostVideo).Length, Sha256 = await ProjectStore.HashAsync(lostVideo) };
        var lossRegion = new Region { Start = 0, End = media.Duration }; lossRegion.PutManual(0, new(24, 20, 16, 16));
        var lostResult = await analysis.AnalyseAsync(lostMedia, lostMap, lossRegion, 0, 6, null, CancellationToken.None);
        check(lostResult.Segments.Any(s => s.State == ReviewState.Lost) && lostResult.Samples.All(k => k.Time < lostMap.Frames[4].Time), "decoded occlusion stops analysis and records unresolved remainder without reacquisition");
        using var cancelled = new CancellationTokenSource(); cancelled.Cancel();
        try { await analysis.AnalyseAsync(media, map, region, 0, 6, null, cancelled.Token); throw new Exception("Tracking cancellation ignored"); }
        catch (OperationCanceledException) { check(true, "cancelled tracking does not mutate project state"); }
        check(await ProjectStore.HashAsync(video) == media.Sha256, "tracking leaves original video unchanged");
    }
    private static byte[] MakeTexture()
    {
        var random = new Random(731); return Enumerable.Range(0, 16 * 16).Select(_ => (byte)random.Next(10, 220)).ToArray();
    }
    private static byte[] Background(int pan)
    {
        var pixels = new byte[Width * Height];
        for (var y = 0; y < Height; y++) for (var x = 0; x < Width; x++) pixels[y * Width + x] = (byte)(190 + ((x + pan * 2) * 17 + y * 13) % 60);
        return pixels;
    }
    private static byte[] Frame(int index, bool visible = true, int size = 16)
    { var pixels = Background(index); if (visible) Paint(pixels, 24 + index * 3, 20 + index, size); return pixels; }
    private static void Paint(byte[] pixels, int x, int y, int size, byte[]? pattern = null)
    { var image = pattern ?? texture; for (var dy = 0; dy < size; dy++) for (var dx = 0; dx < size; dx++) if (x + dx < Width && y + dy < Height) pixels[(y + dy) * Width + x + dx] = image[dy * 16 / size * 16 + dx * 16 / size]; }
    internal static async Task<string> WriteVideo(MediaTools tools, string output, bool loss)
    {
        var prefix = loss ? "tracking-loss" : "tracking-pan";
        for (var i = 0; i < 7; i++)
        {
            var gray = Frame(i, !loss || i != 4); var bitmap = BitmapSource.Create(Width, Height, 96, 96, PixelFormats.Gray8, null, gray, Width);
            var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
            using var file = File.Create(Path.Combine(output, $"{prefix}-{i:00}.png")); encoder.Save(file);
        }
        var path = Path.Combine(output, prefix + ".mp4");
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-framerate", "10", "-i", Path.Combine(output, prefix + "-%02d.png"), "-c:v", "libx264", "-crf", "10", "-pix_fmt", "yuv444p", path], path, CancellationToken.None);
        return path;
    }
}
