using System.Globalization;
using System.IO;
using System.Text.Json;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;
public static class ImageExport
{
    // PNG, JPG, GIF and WebP (BASE-059). The redacted picture is always prepared by
    // the shared CPU renderer first. PNG is encoded and verified pixel-for-pixel here.
    // Other formats send only that prepared, in-memory picture to the approved FFmpeg,
    // then the finished file is structurally probed, decoded and compared before it
    // is moved to the requested destination.
    // animation (0.28.0): an animated GIF's whole frames. Exported as GIF it stays animated, with the redactions and
    // annotations on every frame; exported as anything else it is the frame shown (source).
    public static async Task ExportAsync(string destination, RedactionProject project, ManagedPolicy policy, BitmapSource source, CancellationToken cancellation, MediaTools? tools = null, GifAnimation? animation = null)
    {
        ExportGate.Check(project, policy);
        if (project.Media!.IsVideo) throw new InvalidOperationException("Choose the video exporter for video media.");
        if (project.Export.DeleteOriginal || project.Export.KeepAudio) throw new InvalidOperationException("Source deletion and audio retention are not implemented in this build.");
        var format = StillImageFormats.FromPath(destination) ?? throw new InvalidOperationException("Choose a PNG, JPG, GIF or WebP destination.");
        if (format != StillFormat.Png && tools == null) throw new InvalidOperationException("The approved media tools are required for " + StillImageFormats.DisplayName(format) + " export.");
        if (ProjectStore.SamePath(destination, project.Media.Path)) throw new IOException("Export can't replace the original.");
        if (File.Exists(destination)) throw new IOException("Choose a new destination. Existing files are never replaced.");
        if (policy.BlockNetworkDestination && ManagedPolicy.IsNetwork(destination)) throw new IOException("Your organisation's policy blocks exporting to network drives.");
        if (!await ProjectStore.MatchesAsync(project.Media, project.Media.Path, cancellation)) throw new IOException("The original file has changed since it was opened. Nothing was exported.");
        if (format != StillFormat.Png) await RequireCapabilitiesAsync(tools!, format, cancellation);
        if (format == StillFormat.Gif && animation is { Frames.Count: > 1 }) { await ExportAnimatedGifAsync(destination, project, animation, tools!, cancellation); return; }
        var sourceWidth = project.Media.Width; var sourceHeight = project.Media.Height;
        // A confirmed crop is applied after every redaction has been rendered at full size.
        var crop = project.Crop ?? new MediaRect(0, 0, sourceWidth, sourceHeight);
        var width = (int)crop.Width; var height = (int)crop.Height;
        // The source is held read-locked by the workspace for the entire export transaction.
        var annotations = AnnotationRaster.Create(project, sourceWidth, sourceHeight);
        var pixels = await Task.Run(() =>
        {
            var prepared = EffectRenderer.Render(source, project, 0, null, cancellation, annotations);
            var converted = new FormatConvertedBitmap(prepared, PixelFormats.Bgra32, null, 0);
            if (converted.PixelWidth != sourceWidth || converted.PixelHeight != sourceHeight) throw new InvalidDataException("Source dimensions differ.");
            var buffer = new byte[checked(sourceWidth * sourceHeight * 4)];
            converted.CopyPixels(buffer, sourceWidth * 4, 0);
            if (project.Crop != null) buffer = ImageCrop.CropBgra(buffer, sourceWidth, sourceHeight, crop);
            if (format != StillFormat.Png) StillImageFormats.FlattenOverBlack(buffer);
            return buffer;
        }, cancellation);
        var temporary = destination + ".partial." + Guid.NewGuid().ToString("N") + StillImageFormats.Extension(format);
        try
        {
            var png = await Task.Run(() => EncodePng(pixels, width, height), cancellation);
            cancellation.ThrowIfCancellationRequested();
            if (format == StillFormat.Png)
            {
                using (var output = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                { await output.WriteAsync(png, cancellation); output.Flush(true); }
            }
            else
            {
                // Single-frame Matroska/PNG transport: the same proven input path as effect video.
                using var transport = new MemoryStream();
                var stream = new TimestampedPngStream(transport);
                await stream.BeginAsync(width, height, 0.04, 0.04, cancellation);
                await stream.FrameAsync(png, 0, 40_000, cancellation);
                var args = new List<string> { "-v", "error", "-xerror", "-f", "matroska", "-i", "pipe:0" };
                args.AddRange(StillImageFormats.EncoderArguments(format, project.Export.Quality));
                args.AddRange(["-frames:v", "1", "-an", "-sn", "-dn", "-map_metadata", "-1", "-map_chapters", "-1", "-f", StillImageFormats.Muxer(format)]);
                if (format == StillFormat.Jpeg) args.AddRange(["-update", "1"]);
                args.Add(temporary);
                await tools!.RunAsync("ffmpeg.exe", args, project.Media.Path, transport.ToArray(), cancellation);
                if (!File.Exists(temporary) || new FileInfo(temporary).Length == 0) throw new InvalidDataException("The encoder did not produce an image.");
                await ValidateStructureAsync(tools, temporary, format, width, height, cancellation);
            }
            cancellation.ThrowIfCancellationRequested();
            // Verify every decoded output pixel (PNG) or bounded difference (lossy/indexed), not just file existence.
            var decoded = format == StillFormat.Png ? await Task.Run(() => DecodeWpf(temporary), cancellation)
                : await tools!.FrameAsync(temporary, null, null, cancellation);
            var actual = await Task.Run(() => Bgra(decoded, width, height), cancellation);
            var interior = format == StillFormat.Png ? null : await Task.Run(() =>
            {
                var full = OpaqueInterior(project, sourceWidth, sourceHeight, annotations);
                return project.Crop == null ? full : ImageCrop.CropMask(full, sourceWidth, crop);
            }, cancellation);
            var issue = StillImageFormats.CompareDecoded(format, pixels, actual, width, height, interior);
            if (issue != null) throw new InvalidDataException(issue);
            cancellation.ThrowIfCancellationRequested();
            // The destination must remain absent until finalisation; never overwrite.
            File.Move(temporary, destination, false);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
    // An animated GIF (0.28.0): each whole frame is redacted by the same renderer as a still, sent to the approved FFmpeg
    // with its own timing, and written as one GIF that plays for ever. The finished file must have exactly as many
    // frames, each decoded and compared with its prepared frame as a still GIF is (including inside opaque boxes).
    private static async Task ExportAnimatedGifAsync(string destination, RedactionProject project, GifAnimation animation, MediaTools tools, CancellationToken cancellation)
    {
        var media = project.Media!;
        var sourceWidth = media.Width; var sourceHeight = media.Height;
        if (animation.Width != sourceWidth || animation.Height != sourceHeight) throw new InvalidDataException("The animation's size differs from the image.");
        var crop = project.Crop ?? new MediaRect(0, 0, sourceWidth, sourceHeight);
        var width = (int)crop.Width; var height = (int)crop.Height;
        var annotations = AnnotationRaster.Create(project, sourceWidth, sourceHeight);
        var prepared = await Task.Run(() => animation.Frames.Select(frame =>
        {
            cancellation.ThrowIfCancellationRequested();
            var rendered = EffectRenderer.Render(frame, project, 0, null, cancellation, annotations);
            var converted = new FormatConvertedBitmap(rendered, PixelFormats.Bgra32, null, 0);
            if (converted.PixelWidth != sourceWidth || converted.PixelHeight != sourceHeight) throw new InvalidDataException("Source dimensions differ.");
            var buffer = new byte[checked(sourceWidth * sourceHeight * 4)];
            converted.CopyPixels(buffer, sourceWidth * 4, 0);
            if (project.Crop != null) buffer = ImageCrop.CropBgra(buffer, sourceWidth, sourceHeight, crop);
            StillImageFormats.FlattenOverBlack(buffer);
            return buffer;
        }).ToList(), cancellation);
        var temporary = destination + ".partial." + Guid.NewGuid().ToString("N") + ".gif";
        try
        {
            using var transport = new MemoryStream();
            var stream = new TimestampedPngStream(transport);
            await stream.BeginAsync(width, height, animation.TotalMilliseconds / 1000.0, animation.Delays[^1] / 1000.0, cancellation);
            long at = 0;
            for (var i = 0; i < prepared.Count; i++)
            {
                var png = await Task.Run(() => EncodePng(prepared[i], width, height), cancellation);
                await stream.FrameAsync(png, at, animation.Delays[i] * 1000L, cancellation);
                at += animation.Delays[i] * 1000L;
            }
            var count = prepared.Count.ToString(CultureInfo.InvariantCulture);
            // One palette per frame (new=1), as a still GIF has, so each frame keeps its own colours.
            var args = new List<string> { "-v", "error", "-xerror", "-f", "matroska", "-i", "pipe:0",
                "-filter_complex", "[0:v:0]split[trtpal1][trtpal2];[trtpal1]palettegen=stats_mode=single[trtpal];[trtpal2][trtpal]paletteuse=new=1:dither=bayer:bayer_scale=5[trtgif]",
                "-map", "[trtgif]", "-c:v", "gif", "-fps_mode", "passthrough", "-loop", "0",
                "-frames:v", count, "-an", "-sn", "-dn", "-map_metadata", "-1", "-map_chapters", "-1", "-f", "gif", temporary };
            await tools.RunAsync("ffmpeg.exe", args, media.Path, transport.ToArray(), cancellation);
            if (!File.Exists(temporary) || new FileInfo(temporary).Length == 0) throw new InvalidDataException("The encoder did not produce an image.");
            await ValidateStructureAsync(tools, temporary, StillFormat.Gif, width, height, cancellation, prepared.Count);
            cancellation.ThrowIfCancellationRequested();
            var written = await Task.Run(() => GifAnimation.Load(temporary, cancellation), cancellation)
                ?? throw new InvalidDataException("The exported GIF is not animated.");
            if (written.Frames.Count != prepared.Count) throw new InvalidDataException("The exported GIF has a different number of frames.");
            var interior = await Task.Run(() =>
            {
                var full = OpaqueInterior(project, sourceWidth, sourceHeight, annotations);
                return project.Crop == null ? full : ImageCrop.CropMask(full, sourceWidth, crop);
            }, cancellation);
            for (var i = 0; i < prepared.Count; i++)
            {
                var actual = await Task.Run(() => Bgra(written.Frames[i], width, height), cancellation);
                var issue = StillImageFormats.CompareDecoded(StillFormat.Gif, prepared[i], actual, width, height, interior);
                if (issue != null) throw new InvalidDataException($"Frame {i + 1}: {issue}");
            }
            cancellation.ThrowIfCancellationRequested();
            File.Move(temporary, destination, false);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
    private static async Task RequireCapabilitiesAsync(MediaTools tools, StillFormat format, CancellationToken cancellation)
    {
        var missing = new List<string>();
        if (!await tools.SupportsAsync("encoders", StillImageFormats.Encoder(format), cancellation)) missing.Add(StillImageFormats.Encoder(format) + " encoder");
        if (!await tools.SupportsAsync("muxers", StillImageFormats.Muxer(format), cancellation)) missing.Add(StillImageFormats.Muxer(format) + " output");
        foreach (var filter in StillImageFormats.RequiredFilters(format))
            if (!await tools.SupportsAsync("filters", filter, cancellation)) missing.Add(filter + " filter");
        if (missing.Count > 0)
            throw new NotSupportedException($"TRT's FFmpeg can't write {StillImageFormats.DisplayName(format)} here. PNG still works.");
    }
    private static byte[] EncodePng(byte[] pixels, int width, int height)
    {
        var bitmap = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); bitmap.Freeze();
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
        using var memory = new MemoryStream(); encoder.Save(memory); return memory.ToArray();
    }
    private static BitmapSource DecodeWpf(string path)
    {
        using var input = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        var decoded = new PngBitmapDecoder(input, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
        if (decoded.Frames.Count != 1) throw new InvalidDataException("Output structure mismatch.");
        return decoded.Frames[0];
    }
    private static byte[] Bgra(BitmapSource image, int width, int height)
    {
        if (image.PixelWidth != width || image.PixelHeight != height) throw new InvalidDataException("Output structure mismatch.");
        var converted = new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0);
        var bytes = new byte[checked(width * height * 4)]; converted.CopyPixels(bytes, width * 4, 0); return bytes;
    }
    // Pixels well inside opaque coverage (one JPEG block from any edge) that no later
    // Blur/Pixelate region can have altered. Those must stay close to the prepared colour.
    internal static bool[] OpaqueInterior(RedactionProject project, int width, int height, AnnotationRaster? annotations = null)
    {
        var mask = new bool[width * height];
        // Annotation pixels drawn over a box are not the box colour; erosion below also
        // keeps the strict check a block away from their anti-aliased edges.
        var drawn = annotations?.Footprint(width, height);
        for (var index = 0; index < project.Regions.Count; index++)
        {
            var r = project.Regions[index];
            var b = r.GeometryAt(0);
            var margin = 1 + r.CoverageMargin;
            if (r.Shape == RegionShape.Oval) margin *= Math.Max(b.Width, b.Height) / Math.Min(b.Width, b.Height);
            var reach = Reach(r, b);
            var minX = Math.Max(0, (int)Math.Floor(reach.X - margin)); var maxX = Math.Min(width, (int)Math.Ceiling(reach.X + reach.Width + margin));
            var minY = Math.Max(0, (int)Math.Floor(reach.Y - margin)); var maxY = Math.Min(height, (int)Math.Ceiling(reach.Y + reach.Height + margin));
            for (var y = minY; y < maxY; y++) for (var x = minX; x < maxX; x++)
            {
                if (r.Effect != RedactionEffect.Opaque) { mask[y * width + x] = false; continue; }
                if (Covered(r, b, x + 0.5, y + 0.5, margin)) mask[y * width + x] = true;
            }
        }
        if (drawn != null) for (var i = 0; i < mask.Length; i++) if (drawn[i]) mask[i] = false;
        return StillImageFormats.Erode(mask, width, height, 8);
    }
    // The area a region's pixel loops must scan: its box, or for a turned shape the upright box around it (0.19.0).
    internal static MediaRect Reach(Region r, MediaRect b) => r.Rotation == 0 ? b : ShapeTurn.Extent(b, r.Rotation);
    internal static bool Covered(Region r, MediaRect b, double x, double y, double margin)
    {
        if (r.Rotation != 0)
        {
            // Test the point in the shape's own (unturned) frame (0.19.0).
            var local = ShapeTurn.Rotate(new MediaPoint(x, y), ShapeTurn.Centre(b), -r.Rotation); x = local.X; y = local.Y;
            if (r.Shape == RegionShape.Rectangle) return Math.Abs(x - b.X - b.Width / 2) <= b.Width / 2 + margin && Math.Abs(y - b.Y - b.Height / 2) <= b.Height / 2 + margin;
        }
        if (r.Shape == RegionShape.Rectangle) return true;
        if (r.Shape == RegionShape.Oval)
        {
            var rx = b.Width / 2 + margin; var ry = b.Height / 2 + margin;
            return Math.Pow((x - b.X - b.Width / 2) / rx, 2) + Math.Pow((y - b.Y - b.Height / 2) / ry, 2) <= 1;
        }
        var vertices = r.Polygon.Select(p => new MediaPoint(b.X + p.X * b.Width, b.Y + p.Y * b.Height)).ToArray();
        var inside = false;
        for (var i = 0; i < vertices.Length; i++)
        {
            var a = vertices[i]; var c = vertices[(i + 1) % vertices.Length];
            if ((a.Y > y) != (c.Y > y) && x < (c.X - a.X) * (y - a.Y) / (c.Y - a.Y) + a.X) inside = !inside;
            var dx = c.X - a.X; var dy = c.Y - a.Y; var length = dx * dx + dy * dy;
            var t = length == 0 ? 0 : Math.Clamp(((x - a.X) * dx + (y - a.Y) * dy) / length, 0, 1);
            if (Math.Pow(x - a.X - t * dx, 2) + Math.Pow(y - a.Y - t * dy, 2) <= margin * margin) return true;
        }
        return inside;
    }
    // Only the expected single image stream, codec and dimensions; no chapters or
    // metadata beyond encoder bookkeeping; exactly one decodable frame.
    private static async Task ValidateStructureAsync(MediaTools tools, string path, StillFormat format, int width, int height, CancellationToken cancellation, int expectedFrames = 1)
    {
        var json = await tools.RunAsync("ffprobe.exe", ["-v", "error", "-count_frames", "-show_streams", "-show_format", "-show_chapters", "-of", "json", path], "", cancellation);
        using var doc = JsonDocument.Parse(json);
        var streams = doc.RootElement.GetProperty("streams").EnumerateArray().ToArray();
        if (streams.Length != 1 || streams[0].GetProperty("codec_type").GetString() != "video" ||
            streams[0].GetProperty("codec_name").GetString() != StillImageFormats.ProbeCodec(format) ||
            streams[0].GetProperty("width").GetInt32() != width || streams[0].GetProperty("height").GetInt32() != height)
            throw new InvalidDataException("Output stream, codec or dimension validation failed.");
        if (!streams[0].TryGetProperty("nb_read_frames", out var frames) ||
            !int.TryParse(frames.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var count) || count != expectedFrames)
            throw new InvalidDataException(expectedFrames == 1 ? "The output must contain exactly one image frame." : $"The output must contain exactly {expectedFrames} frames.");
        if (doc.RootElement.TryGetProperty("chapters", out var chapters) && chapters.GetArrayLength() != 0) throw new InvalidDataException("Output contains chapters.");
        string[] allowed = ["encoder", "software", "comment"];
        foreach (var element in streams.Append(doc.RootElement.GetProperty("format")))
            if (element.TryGetProperty("tags", out var tags))
                foreach (var tag in tags.EnumerateObject())
                    if (!allowed.Contains(tag.Name.ToLowerInvariant()) || tag.Name.Equals("comment", StringComparison.OrdinalIgnoreCase) && !string.IsNullOrEmpty(tag.Value.GetString()) && !tag.Value.GetString()!.StartsWith("Lavc", StringComparison.Ordinal))
                        throw new InvalidDataException("Unexpected output metadata key: " + tag.Name);
    }
}
