using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class VideoExportChecks
{
    // Records phases synchronously, in order (Progress<T> would post them to the thread pool).
    private sealed class PhaseLog : IProgress<ExportPhase> { public List<ExportPhase> Seen { get; } = []; public void Report(ExportPhase value) => Seen.Add(value); }
    public static async Task Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var exporter = new VideoExport(tools);
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-framerate", "30000/1001", "-i", Path.Combine(output, "frame-%02d.png"), "-c:v", "libx264", Path.Combine(output, "synthetic-ntsc.mp4")], "", CancellationToken.None);
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", Path.Combine(output, "synthetic-with-audio.mp4"), "-c", "copy", "-output_ts_offset", "2.37", Path.Combine(output, "synthetic-offset.mp4")], "", CancellationToken.None);
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", Path.Combine(output, "synthetic-with-audio.mp4"), "-aspect", "3:1", "-an", "-c:v", "libx264", Path.Combine(output, "synthetic-sar.mp4")], "", CancellationToken.None);
        foreach (var name in new[] { "synthetic-with-audio.mp4", "synthetic-vfr.mp4", "synthetic-rotated.mp4", "synthetic-ntsc.mp4", "synthetic-offset.mp4", "synthetic-sar.mp4" })
        {
            var source = Path.Combine(output, name); var map = await tools.ProbeTimelineAsync(source, CancellationToken.None);
            var first = await tools.FrameAsync(source, map.Frames[0], null, CancellationToken.None);
            if (name == "synthetic-sar.mp4") check(first.PixelWidth == 192 && first.PixelHeight == 64, "non-square pixels normalise into a shared square-pixel coordinate space");
            var project = new RedactionProject { Media = new(source, new FileInfo(source).Length, await ProjectStore.HashAsync(source), first.PixelWidth, first.PixelHeight, map.Frames[^1].Time + map.Frames[^1].Duration, true) };
            var region = new Region { Start = 0, End = project.Media.Duration, Color = "#000000", ShowDecorations = false };
            foreach (var frame in map.Frames)
                region.PutManual(frame.Time, new(5 + frame.Time / project.Media.Duration * (first.PixelWidth - 25), first.PixelHeight - 18, 12, 12));
            project.Regions.Add(region);
            var destination = Path.Combine(output, "redacted-" + name); if (File.Exists(destination)) File.Delete(destination);
            var phases = new PhaseLog();
            await exporter.ExportAsync(destination, project, map, new(), null, CancellationToken.None, phases);
            check(phases.Seen.SequenceEqual([ExportPhase.Exporting, ExportPhase.Validating]), "video export reports Exporting, then Validating: " + name);
            var exportedMap = await tools.ProbeTimelineAsync(destination, CancellationToken.None);
            check(exportedMap.Frames.Count == map.Frames.Count, "video export retains decoded frame count: " + name);
            for (var i = 0; i < map.Frames.Count; i++)
            {
                var bitmap = await tools.FrameAsync(destination, exportedMap.Frames[i], null, CancellationToken.None);
                var pixels = Pixels(bitmap); var b = region.GeometryAt(map.Frames[i].Time);
                var offset = ((int)(b.Y + b.Height / 2) * bitmap.PixelWidth + (int)(b.X + b.Width / 2)) * 4;
                check(pixels[offset] < 40 && pixels[offset + 1] < 40 && pixels[offset + 2] < 40, $"decoded animated coverage {name} frame {i}");
            }
            check(await ProjectStore.HashAsync(source) == project.Media.Sha256, "video source unchanged: " + name);
            if (name == "synthetic-with-audio.mp4")
            {
                region.Keyframes.Clear(); region.PutManual(0, new(8, 44, 15, 15)); region.Start = map.Frames[4].Time; region.End = map.Frames[5].Time;
                var ranged = Path.Combine(output, "redacted-buffered.mp4"); if (File.Exists(ranged)) File.Delete(ranged);
                await exporter.ExportAsync(ranged, project, map, new(), null, CancellationToken.None);
                var rangedMap = await tools.ProbeTimelineAsync(ranged, CancellationToken.None);
                for (var i = 0; i < map.Frames.Count; i++)
                {
                    var bytes = Pixels(await tools.FrameAsync(ranged, rangedMap.Frames[i], null, CancellationToken.None)); var dark = bytes[(50 * 96 + 15) * 4] < 40;
                    check(dark == (i >= 2 && i <= 7), "inclusive two-frame buffer coverage at frame " + i);
                }
                project.Export.KeepAudio = true;
                foreach (var extension in new[] { ".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm" })
                {
                    var audioDestination = Path.Combine(output, "redacted-audio" + extension); if (File.Exists(audioDestination)) File.Delete(audioDestination);
                    await exporter.ExportAsync(audioDestination, project, map, new(), null, CancellationToken.None);
                    check(File.Exists(audioDestination), "validated format and primary-audio export: " + extension);
                }
                using var cancelled = new CancellationTokenSource();
                var cancelledPath = Path.Combine(output, "cancelled-video.mp4");
                try
                {
                    await exporter.ExportAsync(cancelledPath, project, map, new(), new InlineProgress(f => { if (f > 0.1) cancelled.Cancel(); }), cancelled.Token);
                    throw new Exception("Video cancellation was ignored.");
                }
                catch (OperationCanceledException) { check(!File.Exists(cancelledPath), "cancelled video masks do not promote output"); }
                check(!Directory.EnumerateFiles(output, "*.partial.*").Any(), "video partials removed after cancellation");
            }
        }
        var attachment = Path.Combine(output, "synthetic-attachment.txt"); await File.WriteAllTextAsync(attachment, "SYNTHETIC_PRIVATE_ATTACHMENT");
        var enriched = Path.Combine(output, "synthetic-extra-streams.mkv");
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", Path.Combine(output, "synthetic-with-audio.mp4"), "-i", Path.Combine(output, "synthetic-tone.wav"),
            "-map", "0:v:0", "-map", "0:a:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", "-metadata", "title=SYNTHETIC_PRIVATE_TITLE", "-metadata:s:a:1", "comment=SYNTHETIC_EXTRA_AUDIO", "-attach", attachment, "-metadata:s:t", "mimetype=text/plain", enriched], enriched, CancellationToken.None);
        var richMap = await tools.ProbeTimelineAsync(enriched, CancellationToken.None);
        var richMedia = new MediaReference(enriched, new FileInfo(enriched).Length, await ProjectStore.HashAsync(enriched), 96, 64, richMap.Frames[^1].Time + richMap.Frames[^1].Duration, true);
        var richRegion = new Region { Start = 0, End = richMedia.Duration }; richRegion.PutManual(0, new(8, 44, 15, 15));
        var richProject = new RedactionProject { Media = richMedia, Regions = [richRegion], Export = new() { KeepAudio = true } };
        var clean = Path.Combine(output, "redacted-extra-streams.mp4"); if (File.Exists(clean)) File.Delete(clean);
        await exporter.ExportAsync(clean, richProject, richMap, new(), null, CancellationToken.None);
        var inspection = System.Text.Encoding.UTF8.GetString(await tools.RunAsync("ffprobe.exe", ["-v", "error", "-show_streams", "-show_format", "-show_chapters", "-of", "json", clean], enriched, CancellationToken.None));
        using var info = System.Text.Json.JsonDocument.Parse(inspection); var streams = info.RootElement.GetProperty("streams").EnumerateArray().ToArray();
        check(streams.Length == 2 && streams.Count(s => s.GetProperty("codec_type").GetString() == "audio") == 1, "extra audio and attachment streams are excluded from validated export");
        check(!inspection.Contains("SYNTHETIC_", StringComparison.Ordinal), "synthetic private source metadata does not survive export");
        var extended = Path.Combine(output, "synthetic-audio-overrun.mp4");
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", Path.Combine(output, "synthetic-with-audio.mp4"), "-stream_loop", "3", "-i", Path.Combine(output, "synthetic-tone.wav"), "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", extended], extended, CancellationToken.None);
        var overrunMap = await tools.ProbeTimelineAsync(extended, CancellationToken.None);
        var overrun = richProject; overrun.Media = richMedia with { Path = extended, Length = new FileInfo(extended).Length, Sha256 = await ProjectStore.HashAsync(extended) };
        var overrunDestination = Path.Combine(output, "blocked-audio-overrun.mp4");
        try { await exporter.ExportAsync(overrunDestination, overrun, overrunMap, new(), null, CancellationToken.None); throw new Exception("Audio overrun was accepted."); }
        catch (InvalidDataException) { check(!File.Exists(overrunDestination), "audio beyond the reviewed video duration blocks promotion"); }
    }
    private sealed class InlineProgress(Action<double> changed) : IProgress<double> { public void Report(double value) => changed(value); }
    private static byte[] Pixels(BitmapSource bitmap)
    {
        var converted = new FormatConvertedBitmap(bitmap, PixelFormats.Bgra32, null, 0); var pixels = new byte[bitmap.PixelWidth * bitmap.PixelHeight * 4];
        converted.CopyPixels(pixels, bitmap.PixelWidth * 4, 0); return pixels;
    }
}
