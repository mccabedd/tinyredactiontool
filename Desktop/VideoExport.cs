using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Reported as export moves from writing the file to checking it (shown in the progress popup).
public enum ExportPhase { Exporting, Validating }
public sealed class VideoExport(MediaTools tools)
{
    public async Task ExportAsync(string destination, RedactionProject project, FrameTimeline map, ManagedPolicy policy,
        IProgress<double>? progress, CancellationToken cancellation, IProgress<ExportPhase>? phase = null)
    {
        ExportGate.Check(project, policy);
        var source = project.Media!;
        if (!source.IsVideo) throw new InvalidOperationException("Choose the image exporter for still images.");
        if (project.Export.DeleteOriginal) throw new InvalidOperationException("Original-source deletion is not implemented and cannot be requested.");
        var extension = Path.GetExtension(destination).ToLowerInvariant();
        if (!new[] { ".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm" }.Contains(extension)) throw new InvalidOperationException("Unsupported video destination format.");
        if (ProjectStore.SamePath(destination, source.Path) || File.Exists(destination)) throw new IOException("Choose a new file name (not the original).");
        if (policy.BlockNetworkDestination && ManagedPolicy.IsNetwork(destination)) throw new IOException("Your organisation's policy blocks exporting to network drives.");
        using var sourceLease = new FileStream(source.Path, FileMode.Open, FileAccess.Read, FileShare.Read);
        if (!await ProjectStore.MatchesAsync(source, source.Path, cancellation)) throw new IOException("The original file has changed since it was opened. Nothing was exported.");
        var root = Path.Combine(Path.GetTempPath(), ScratchFolder, "masks-" + Guid.NewGuid().ToString("N"));
        var temporary = destination + ".partial." + Guid.NewGuid().ToString("N") + extension;
        Directory.CreateDirectory(root);
        try
        {
            phase?.Report(ExportPhase.Exporting);
            // Blur, Pixelate and (3.0.0) a crop: TRT draws every frame itself, then each is cut to the crop.
            if (project.Regions.Any(r => r.Effect != RedactionEffect.Opaque) || project.Crop != null)
            {
                await Task.Run(() => EffectVideoEncoder.EncodeAsync(temporary, project, map, progress, cancellation), cancellation);
                phase?.Report(ExportPhase.Validating);
                await ValidateAsync(temporary, source, map, project.Export.KeepAudio, cancellation, project.Crop);
                cancellation.ThrowIfCancellationRequested(); File.Move(temporary, destination, false); progress?.Report(1); return;
            }
            var concatPath = Path.Combine(root, "geometry.ffconcat");
            await Task.Run(() => WriteMasks(root, concatPath, project, map, progress, cancellation), cancellation);
            var webm = extension == ".webm";
            var args = new List<string> { "-v", "error", "-xerror", "-copyts", "-itsoffset", (-map.OriginTime).ToString("0.000000", CultureInfo.InvariantCulture), "-i", source.Path, "-f", "concat", "-safe", "0", "-itsoffset", "-0.000002", "-i", concatPath,
                "-filter_complex", "[0:v:0]" + MediaTools.CanonicalScale + "[canonical];[canonical][1:v:0]overlay=0:0:eof_action=repeat:shortest=0:format=auto[out]", "-map", "[out]", "-map_metadata", "-1", "-map_chapters", "-1", "-map_metadata:s:v", "-1", "-sn", "-dn" };
            if (project.Export.KeepAudio)
                args.AddRange(["-map", "0:a:0?", "-map_metadata:s:a", "-1", "-c:a", webm ? "libopus" : "aac"]);
            else args.Add("-an");
            args.AddRange(["-c:v", webm ? "libvpx-vp9" : "libx264", "-pix_fmt", source.Width % 2 == 0 && source.Height % 2 == 0 ? "yuv420p" : "yuv444p", "-crf", project.Export.Quality == "High" ? "16" : project.Export.Quality == "Smaller" ? "28" : "21"]);
            if (webm) args.AddRange(["-b:v", "0"]); else args.AddRange(["-preset", "medium"]);
            if (extension == ".avi") args.AddRange(["-bf", "0", "-avoid_negative_ts", "disabled"]);
            args.AddRange(["-fps_mode", "passthrough", "-enc_time_base:v:0", "filter", "-metadata", "title=", "-metadata", "comment=", "-metadata", "description=", temporary]);
            await tools.RunAsync("ffmpeg.exe", args, source.Path, cancellation);
            progress?.Report(0.65);
            phase?.Report(ExportPhase.Validating);
            await ValidateAsync(temporary, source, map, project.Export.KeepAudio, cancellation);
            cancellation.ThrowIfCancellationRequested();
            File.Move(temporary, destination, false);
            progress?.Report(1);
        }
        finally
        {
            if (File.Exists(temporary)) File.Delete(temporary);
            var parent = Path.GetFullPath(Path.Combine(Path.GetTempPath(), ScratchFolder)) + Path.DirectorySeparatorChar;
            if (!Path.GetFullPath(root).StartsWith(parent, StringComparison.OrdinalIgnoreCase)) throw new IOException("Invalid owned mask directory.");
            if (Directory.Exists(root)) Directory.Delete(root, true);
        }
    }
    // Remove History (0.28.0): scratch folders an export left behind (one ended by a crash). An export only runs while
    // its editor is busy, and Remove History waits for that, so none here is in use. Returns the files removed.
    // The export scratch folder in the temporary folder (3.0.0 clean-up: was "TinyRedactionTool.Wpf.Dev").
    internal const string ScratchFolder = "TinyRedactionTool-Export";
    private static readonly string[] ScratchFolders = [ScratchFolder, "TinyRedactionTool.Wpf.Dev"];
    internal static int RemoveLeftoverScratch(string? temporaryFolder = null)
    {
        var count = 0;
        foreach (var name in ScratchFolders)
        {
        var parent = Path.Combine(Path.GetFullPath(temporaryFolder ?? Path.GetTempPath()), name);
        if (!Directory.Exists(parent)) continue;
        foreach (var dir in Directory.GetDirectories(parent, "masks-*"))
        {
            try
            {
                if ((File.GetAttributes(dir) & FileAttributes.ReparsePoint) != 0) continue;
                count += Directory.GetFiles(dir).Length; Directory.Delete(dir, true);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        }
        }
        return count;
    }
    private static void WriteMasks(string root, string concatPath, RedactionProject project, FrameTimeline map, IProgress<double>? progress, CancellationToken cancellation)
    {
        var m = project.Media!;
        var text = new StringBuilder("ffconcat version 1.0\n");
        // Image demuxer timebase is one microsecond. Floor each absolute source PTS,
        // so geometry never lands just after its matching source frame due to rounding.
        var stamps = map.Frames.Select(f => (long)Math.Floor(f.Time * 1_000_000 + 0.00001)).ToArray();
        if (stamps.Zip(stamps.Skip(1)).Any(pair => pair.Second - pair.First < 4)) throw new InvalidDataException("Source frame intervals are too short for safe mask timestamp mapping.");
        var annotations = AnnotationRaster.Create(project, m.Width, m.Height);
        for (var i = 0; i < map.Frames.Count; i++)
        {
            cancellation.ThrowIfCancellationRequested();
            var pixels = OverlayPixels(project, map, i, annotations);
            var filename = Convert.ToHexString(SHA256.HashData(pixels)) + ".png";
            var path = Path.Combine(root, filename);
            if (!File.Exists(path))
            {
                var bitmap = BitmapSource.Create(m.Width, m.Height, 96, 96, PixelFormats.Bgra32, null, pixels, checked(m.Width * 4));
                var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
                using var file = File.Create(path); encoder.Save(file);
            }
            text.Append("file '").Append(filename).Append("'\noption framerate 1000000\n");
            var duration = i + 1 < stamps.Length ? stamps[i + 1] - stamps[i] : Math.Max(1, (long)Math.Ceiling(map.Frames[i].Duration * 1_000_000));
            text.Append("duration ").Append((duration / 1_000_000d).ToString("0.000000", CultureInfo.InvariantCulture)).Append('\n');
            progress?.Report((i + 1d) / map.Frames.Count * 0.4);
        }
        File.WriteAllText(concatPath, text.ToString(), new UTF8Encoding(false));
    }
    // Transparent frame overlay: opaque redaction coverage, then annotations in creation order
    // (straight alpha), except where a later redaction covers them.
    public static byte[] OverlayPixels(RedactionProject project, FrameTimeline map, int frameIndex, AnnotationRaster? annotations = null)
    {
        var m = project.Media!; var pixels = new byte[checked(m.Width * m.Height * 4)]; var time = map.Frames[frameIndex].Time;
        var applied = new List<(Region Region, MediaRect Bounds, double Margin)>();
        foreach (var region in project.Regions.Where(r => map.IsActive(r, time)))
        {
            var b = region.GeometryAt(Math.Clamp(time, region.Start, region.End));
            var color = (Color)ColorConverter.ConvertFromString(region.Color);
            var margin = 1 + region.CoverageMargin;
            if (region.Shape == RegionShape.Oval) margin *= Math.Max(b.Width, b.Height) / Math.Min(b.Width, b.Height);
            applied.Add((region, b, margin));
            var reach = ImageExport.Reach(region, b);
            var minX = Math.Max(0, (int)Math.Floor(reach.X - margin)); var maxX = Math.Min(m.Width, (int)Math.Ceiling(reach.X + reach.Width + margin));
            var minY = Math.Max(0, (int)Math.Floor(reach.Y - margin)); var maxY = Math.Min(m.Height, (int)Math.Ceiling(reach.Y + reach.Height + margin));
            for (var y = minY; y < maxY; y++) for (var x = minX; x < maxX; x++)
            {
                if (!ImageExport.Covered(region, b, x + 0.5, y + 0.5, margin + Math.Sqrt(0.5))) continue;
                var offset = (y * m.Width + x) * 4; pixels[offset] = color.B; pixels[offset + 1] = color.G; pixels[offset + 2] = color.R; pixels[offset + 3] = 255;
            }
        }
        annotations?.Composite(pixels, m.Width, m.Height, a => map.IsActive(a, time),
            (a, x, y) => applied.Any(e => e.Region.Order > a.Order && EffectRenderer.Covers(e.Region, e.Bounds, e.Margin, x, y)));
        return pixels;
    }
    // crop: the output must be exactly the crop's size (3.0.0); otherwise the source's.
    private async Task ValidateAsync(string path, MediaReference source, FrameTimeline expected, bool keepAudio, CancellationToken cancellation, MediaRect? crop = null)
    {
        var width = crop is { } c ? (int)c.Width : source.Width; var height = crop is { } d ? (int)d.Height : source.Height;
        var json = await tools.RunAsync("ffprobe.exe", ["-v", "error", "-show_streams", "-show_format", "-show_chapters", "-of", "json", path], source.Path, cancellation);
        using var doc = JsonDocument.Parse(json);
        var streams = doc.RootElement.GetProperty("streams").EnumerateArray().ToArray();
        if (!doc.RootElement.GetProperty("format").TryGetProperty("duration", out var durationElement) ||
            !double.TryParse(durationElement.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out var duration) || !double.IsFinite(duration) || duration <= 0)
            throw new InvalidDataException("Output duration could not be validated.");
        var durationTolerance = Math.Max(0.5, expected.Frames.Max(f => f.Duration) * 2);
        if (Math.Abs(duration - source.Duration) > durationTolerance)
            throw new InvalidDataException("Output duration differs from the displayed video timeline. Audio may extend beyond the reviewed video; export without audio or review it separately.");
        var videos = streams.Where(s => s.GetProperty("codec_type").GetString() == "video").ToArray();
        var audios = streams.Count(s => s.GetProperty("codec_type").GetString() == "audio");
        if (videos.Length != 1 || audios > (keepAudio ? 1 : 0) || streams.Length != videos.Length + audios ||
            videos[0].GetProperty("width").GetInt32() != width || videos[0].GetProperty("height").GetInt32() != height ||
            doc.RootElement.GetProperty("chapters").GetArrayLength() != 0) throw new InvalidDataException("Output stream, chapter or geometry validation failed.");
        var inputJson = await tools.RunAsync("ffprobe.exe", ["-v", "error", "-select_streams", "a:0", "-show_entries", "stream=index", "-of", "json", source.Path], source.Path, cancellation);
        using var input = JsonDocument.Parse(inputJson);
        var expectedAudio = keepAudio && input.RootElement.GetProperty("streams").GetArrayLength() > 0 ? 1 : 0;
        if (audios != expectedAudio) throw new InvalidDataException("Audio retention state does not match output.");
        var expectedVideoCodec = Path.GetExtension(path).Equals(".webm", StringComparison.OrdinalIgnoreCase) ? "vp9" : "h264";
        var expectedAudioCodec = expectedVideoCodec == "vp9" ? "opus" : "aac";
        if (videos[0].GetProperty("codec_name").GetString() != expectedVideoCodec || streams.Any(s => s.GetProperty("codec_type").GetString() == "audio" && s.GetProperty("codec_name").GetString() != expectedAudioCodec))
            throw new InvalidDataException("Unexpected output codec.");
        string[] allowed = ["encoder", "major_brand", "minor_version", "compatible_brands", "language", "handler_name", "vendor_id", "duration", "software"];
        foreach (var element in streams.Append(doc.RootElement.GetProperty("format")))
            if (element.TryGetProperty("tags", out var tags))
                foreach (var tag in tags.EnumerateObject()) if (!allowed.Contains(tag.Name.ToLowerInvariant())) throw new InvalidDataException("Unexpected output metadata key: " + tag.Name);
        var actual = await tools.ProbeTimelineAsync(path, cancellation);
        if (actual.Frames.Count != expected.Frames.Count) throw new InvalidDataException("Output frame count differs from source.");
        var nominal = expected.Frames.Select(f => f.Duration).OrderBy(d => d).ElementAt(expected.Frames.Count / 2);
        var tolerance = Math.Max(0.0015, Math.Min(0.005, nominal * 0.02));
        for (var i = 0; i < actual.Frames.Count; i++)
            if (Math.Abs(actual.Frames[i].Time - expected.Frames[i].Time) > tolerance) throw new InvalidDataException("Output frame presentation time differs from source.");
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-xerror", "-i", path, "-map", "0:v:0", "-f", "null", "-"], source.Path, cancellation);
    }
}
