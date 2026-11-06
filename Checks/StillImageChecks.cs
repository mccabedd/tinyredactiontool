using System.IO;
using System.Text.Json;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.6.0 still-image output parity: PNG, JPG, GIF and WebP (BASE-059) through the
// approved FFmpeg, with capability inspection, validation and failure boundaries.
internal static class StillImageChecks
{
    public static async Task Run(MediaTools tools, string output, Action<bool, string> check)
    {
        check(StillImageFormats.FromPath("a.PNG") == StillFormat.Png && StillImageFormats.FromPath("a.jpeg") == StillFormat.Jpeg &&
              StillImageFormats.FromPath("a.jpg") == StillFormat.Jpeg && StillImageFormats.FromPath("a.gif") == StillFormat.Gif &&
              StillImageFormats.FromPath("a.webp") == StillFormat.WebP && StillImageFormats.FromPath("a.bmp") == null && StillImageFormats.FromPath("a") == null,
            "still export accepts exactly PNG, JPG/JPEG, GIF and WebP destinations");
        foreach (var format in new[] { StillFormat.Jpeg, StillFormat.Gif, StillFormat.WebP })
            foreach (var quality in new[] { "High", "Normal", "Smaller" })
            {
                var args = StillImageFormats.EncoderArguments(format, quality);
                check(args.SkipWhile(a => a != "-c:v").Skip(1).FirstOrDefault() == StillImageFormats.Encoder(format), $"{format} {quality} names its encoder explicitly");
            }
        check(StillImageFormats.EncoderArguments(StillFormat.Jpeg, "Normal").Contains("3") && StillImageFormats.EncoderArguments(StillFormat.WebP, "Normal").Contains("90"),
            "Normal quality keeps inherited JPG/WebP encoder settings");

        var parsed = typeof(MediaTools).GetMethod("ParseCapabilityList", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic)!;
        var listing = (HashSet<string>)parsed.Invoke(null, ["Filters:\r\n  T.. = Timeline support\r\n  A = Audio input/output\r\n ... split  V->N  Pass on.\r\n File formats:\r\n --\r\n  E gif,webp  Two formats\r\n Encoders:\r\n ------\r\n VFS..D mjpeg                \r\n V....D libx264               (codec h264)\r\n"])!;
        check(listing.SetEquals(["split", "gif", "webp", "mjpeg", "libx264"]), "FFmpeg capability parser ignores legends and reads comma-separated and description-less names");

        var mask = new bool[20 * 20];
        for (var y = 2; y < 18; y++) for (var x = 2; x < 18; x++) mask[y * 20 + x] = true;
        var eroded = StillImageFormats.Erode(mask, 20, 20, 3);
        check(eroded[10 * 20 + 10] && !eroded[4 * 20 + 4] && eroded[5 * 20 + 5] && !eroded[0], "opaque interior erosion keeps only pixels away from coverage edges");
        var edge = Enumerable.Repeat(true, 16).ToArray();
        check(StillImageFormats.Erode(edge, 4, 4, 2).All(b => b), "coverage touching the image edge is still checked");
        var transparent = new byte[] { 200, 100, 50, 0, 200, 100, 50, 128, 1, 2, 3, 255 };
        StillImageFormats.FlattenOverBlack(transparent);
        check(transparent[0] == 0 && transparent[3] == 255 && transparent[4] == 100 && transparent[7] == 255 && transparent[8] == 1,
            "JPG/GIF/WebP flattening hides RGB stored under transparent pixels");
        var reference = new byte[4 * 4 * 4]; for (var i = 3; i < reference.Length; i += 4) reference[i] = 255;
        var revealed = (byte[])reference.Clone(); revealed[0] = revealed[1] = revealed[2] = 200;
        check(StillImageFormats.CompareDecoded(StillFormat.Jpeg, reference, revealed, 4, 4, Enumerable.Repeat(true, 16).ToArray()) != null, "lossy validation rejects a changed opaque interior");
        check(StillImageFormats.CompareDecoded(StillFormat.Png, reference, revealed, 4, 4, null) != null, "PNG validation remains exact");
        var cleared = (byte[])reference.Clone(); cleared[3] = 0;
        check(StillImageFormats.CompareDecoded(StillFormat.Gif, reference, cleared, 4, 4, null) != null, "lossy validation rejects unexpected transparency");

        foreach (var (kind, name) in new[] { ("encoders", "mjpeg"), ("encoders", "gif"), ("encoders", "libwebp"), ("muxers", "image2"), ("muxers", "gif"), ("muxers", "webp"),
            ("filters", "split"), ("filters", "palettegen"), ("filters", "paletteuse") })
            check(await tools.SupportsAsync(kind, name, CancellationToken.None), $"approved FFmpeg provides {name} ({kind})");
        check(!await tools.SupportsAsync("encoders", "trt-not-a-real-encoder", CancellationToken.None), "capability inspection does not assume unknown components");

        // A photographic-style source with detail, a partially transparent corner and
        // four regions: red box, black oval, polygon and Blur.
        const int width = 241, height = 157; // odd sizes on purpose
        var pixels = new byte[width * height * 4];
        for (var y = 0; y < height; y++) for (var x = 0; x < width; x++)
        {
            var i = (y * width + x) * 4;
            pixels[i] = (byte)(x * 255 / width); pixels[i + 1] = (byte)(y * 255 / height); pixels[i + 2] = (byte)((x / 7 + y / 5) % 2 == 0 ? 230 : 40); pixels[i + 3] = 255;
        }
        for (var y = 0; y < 12; y++) for (var x = 0; x < 12; x++) { var i = (y * width + x) * 4; pixels[i] = 250; pixels[i + 1] = 250; pixels[i + 2] = 250; pixels[i + 3] = 0; }
        var source = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); source.Freeze();
        var sourcePath = Path.Combine(output, "still-formats-source.png");
        if (File.Exists(sourcePath)) File.Delete(sourcePath);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(source));
        using (var file = File.Create(sourcePath)) encoder.Save(file);
        var sourceHash = await ProjectStore.HashAsync(sourcePath);
        var project = new RedactionProject { Media = new(sourcePath, new FileInfo(sourcePath).Length, sourceHash, width, height, 0, false) };
        Region Add(RegionShape shape, RedactionEffect effect, MediaRect bounds, string color)
        {
            var region = new Region { Shape = shape, Effect = effect, Color = color, Start = 0, End = 0, ShowDecorations = false };
            if (shape == RegionShape.Polygon) region.Polygon = [new(0, 0), new(1, 0), new(1, 1), new(0, 1)];
            region.PutManual(0, bounds); project.Regions.Add(region); return region;
        }
        Add(RegionShape.Rectangle, RedactionEffect.Opaque, new(20, 30, 70, 50), "#C83214");
        Add(RegionShape.Oval, RedactionEffect.Opaque, new(120, 20, 80, 60), "#000000");
        Add(RegionShape.Polygon, RedactionEffect.Opaque, new(130, 100, 60, 40), "#FFFFFF");
        Add(RegionShape.Rectangle, RedactionEffect.Blur, new(20, 100, 60, 40), "#000000");
        foreach (var (extension, format) in new[] { (".jpg", StillFormat.Jpeg), (".jpeg", StillFormat.Jpeg), (".gif", StillFormat.Gif), (".webp", StillFormat.WebP) })
            foreach (var quality in format == StillFormat.Gif ? new[] { "Normal" } : new[] { "High", "Normal", "Smaller" })
            {
                project.Export.Quality = quality;
                var destination = Path.Combine(output, "still-" + quality + extension); if (File.Exists(destination)) File.Delete(destination);
                await ImageExport.ExportAsync(destination, project, new(), source, CancellationToken.None, tools);
                var json = await tools.RunAsync("ffprobe.exe", ["-v", "error", "-show_streams", "-show_format", "-of", "json", destination], "", CancellationToken.None);
                using var probe = JsonDocument.Parse(json);
                var streams = probe.RootElement.GetProperty("streams").EnumerateArray().ToArray();
                check(streams.Length == 1 && streams[0].GetProperty("codec_name").GetString() == StillImageFormats.ProbeCodec(format) &&
                      streams[0].GetProperty("width").GetInt32() == width && streams[0].GetProperty("height").GetInt32() == height, $"{extension} {quality} export has one {StillImageFormats.ProbeCodec(format)} image at source size");
                var decoded = new FormatConvertedBitmap(await tools.FrameAsync(destination, null, null, CancellationToken.None), PixelFormats.Bgra32, null, 0);
                var actual = new byte[width * height * 4]; decoded.CopyPixels(actual, width * 4, 0);
                byte[] At(int x, int y) => actual.AsSpan((y * width + x) * 4, 4).ToArray();
                bool Near(byte[] bgra, int r, int g, int b, int tolerance) => Math.Abs(bgra[2] - r) <= tolerance && Math.Abs(bgra[1] - g) <= tolerance && Math.Abs(bgra[0] - b) <= tolerance;
                check(Near(At(55, 55), 0xC8, 0x32, 0x14, 32) && Near(At(160, 50), 0, 0, 0, 32) && Near(At(160, 120), 255, 255, 255, 32),
                    $"{extension} {quality} keeps rectangle, oval and polygon replacement colours");
                check(Near(At(4, 4), 0, 0, 0, 40), $"{extension} {quality} does not reveal colour hidden under transparent source pixels");
                check(!File.Exists(destination + ".partial") && !Directory.EnumerateFiles(output, "still-*.partial.*").Any(), $"{extension} {quality} leaves no partial file");
            }
        var collision = Path.Combine(output, "still-existing.jpg"); await File.WriteAllTextAsync(collision, "existing destination");
        try { await ImageExport.ExportAsync(collision, project, new(), source, CancellationToken.None, tools); throw new Exception("JPG destination collision accepted"); }
        catch (IOException) { check(await File.ReadAllTextAsync(collision) == "existing destination", "JPG export never replaces an existing destination"); }
        try { await ImageExport.ExportAsync(Path.Combine(output, "still-without-tools.webp"), project, new(), source, CancellationToken.None); throw new Exception("WebP without approved tools accepted"); }
        catch (InvalidOperationException) { check(!File.Exists(Path.Combine(output, "still-without-tools.webp")), "non-PNG export requires the approved media tools"); }
        try { await ImageExport.ExportAsync(Path.Combine(output, "still-unsupported.bmp"), project, new(), source, CancellationToken.None, tools); throw new Exception("BMP accepted"); }
        catch (InvalidOperationException) { check(true, "unsupported still format is rejected before encoding"); }
        using (var cancelled = new CancellationTokenSource())
        {
            cancelled.Cancel(); var cancelledPath = Path.Combine(output, "still-cancelled.gif"); if (File.Exists(cancelledPath)) File.Delete(cancelledPath);
            try { await ImageExport.ExportAsync(cancelledPath, project, new(), source, cancelled.Token, tools); throw new Exception("GIF cancellation ignored"); }
            catch (OperationCanceledException) { check(!File.Exists(cancelledPath), "cancelled GIF export is not promoted"); }
        }
        // 0.14.0: the Review gate is gone, so the export gate is shown with a policy rule instead.
        var effect = project.Regions[0].Effect; project.Regions[0].Effect = RedactionEffect.Blur;
        try { await ImageExport.ExportAsync(Path.Combine(output, "still-gated.webp"), project, new(DisableVisualObscuration: true), source, CancellationToken.None, tools); throw new Exception("export gate bypassed"); }
        catch (InvalidOperationException) { check(!File.Exists(Path.Combine(output, "still-gated.webp")), "the export gate applies to every still format"); }
        project.Regions[0].Effect = effect;
        project.Regions[3].Effect = RedactionEffect.Pixelate;
        var restricted = ManagedPolicy.Parse("""{"schemaVersion":1,"policyId":"still","policyVersion":"1","controls":{"disableVisualObscuration":true}}""");
        try { await ImageExport.ExportAsync(Path.Combine(output, "still-policy.jpg"), project, restricted, source, CancellationToken.None, tools); throw new Exception("policy bypassed"); }
        catch (InvalidOperationException) { check(!File.Exists(Path.Combine(output, "still-policy.jpg")), "managed obscuration policy applies to JPG export"); }
        check(await ProjectStore.HashAsync(sourcePath) == sourceHash, "source unchanged after JPG/GIF/WebP exports and failures");
    }
}
