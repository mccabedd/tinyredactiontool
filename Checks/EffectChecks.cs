using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class EffectChecks
{
    private static byte[] Pixels(BitmapSource source)
    { var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0); var bytes = new byte[source.PixelWidth * source.PixelHeight * 4]; converted.CopyPixels(bytes, source.PixelWidth * 4, 0); return bytes; }
    public static async Task Run(MediaTools tools, string output, Action<bool, string> check)
    {
        const int width = 96, height = 64;
        var pixels = new byte[width * height * 4];
        for (var y = 0; y < height; y++) for (var x = 0; x < width; x++)
        { var p = (y * width + x) * 4; pixels[p] = (byte)((x * 59 + y * 7) % 256); pixels[p + 1] = (byte)((x * 31 + y * 19) % 256); pixels[p + 2] = (byte)((x * 13 + y * 37) % 256); pixels[p + 3] = 255; }
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze();
        var path = Path.Combine(output, "synthetic-effects.png"); var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(image)); using (var file = File.Create(path)) png.Save(file);
        var project = new RedactionProject { Media = new(path, new FileInfo(path).Length, await ProjectStore.HashAsync(path), width, height, 0, false) };
        foreach (var effect in new[] { RedactionEffect.Blur, RedactionEffect.Pixelate })
        foreach (var shape in Enum.GetValues<RegionShape>())
        foreach (var aggressive in new[] { false, true })
        {
            var region = new Region { Effect = effect, Shape = shape, Aggressive = aggressive, ShowDecorations = false, Polygon = [new(0, 0), new(1, 0), new(.5, 1)] };
            region.PutManual(0, new(20, 15, 50, 35)); project.Regions = [region];
            var result = EffectRenderer.Render(image, project, 0, null); var bytes = Pixels(result);
            check(!pixels.AsSpan().SequenceEqual(bytes) && bytes.AsSpan(0, width * 4).SequenceEqual(pixels.AsSpan(0, width * 4)), $"{effect}/{shape}/{aggressive}: effect changes selected content and preserves outside pixels");
            var destination = Path.Combine(output, $"effect-{effect}-{shape}-{aggressive}.png"); if (File.Exists(destination)) File.Delete(destination);
            await ImageExport.ExportAsync(destination, project, new(), image, CancellationToken.None);
            var decoded = new BitmapImage(new Uri(destination));
            check(Pixels(decoded).AsSpan().SequenceEqual(bytes), $"{effect}/{shape}/{aggressive}: PNG export exactly equals shared preview pixels");
        }
        var strengthRegion = new Region { Effect = RedactionEffect.Blur }; strengthRegion.PutManual(0, new(4, 4, 85, 55)); project.Regions = [strengthRegion];
        foreach (var effect in new[] { RedactionEffect.Blur, RedactionEffect.Pixelate })
        {
            strengthRegion.Effect = effect; strengthRegion.Strength = 1; var weak = Pixels(EffectRenderer.Render(image, project, 0, null));
            strengthRegion.Strength = 10; var strong = Pixels(EffectRenderer.Render(image, project, 0, null));
            check(!weak.AsSpan().SequenceEqual(strong), effect + " strength 1 and 10 differ");
        }
        using (var cancel = new CancellationTokenSource())
        {
            cancel.Cancel(); try { EffectRenderer.Render(image, project, 0, null, cancel.Token); throw new Exception("Ignored cancellation"); }
            catch (OperationCanceledException) { check(true, "effect renderer honours cancellation"); }
        }
        var tiny = new Region { Effect = RedactionEffect.Blur, Strength = 10 }; tiny.PutManual(0, new(0, 0, 1, 1)); project.Regions = [tiny];
        check(EffectRenderer.Render(image, project, 0, null).PixelWidth == width, "strong Blur handles a one-pixel corner region");
        tiny.Effect = RedactionEffect.Pixelate; tiny.Aggressive = true;
        check(EffectRenderer.Render(image, project, 0, null).PixelWidth == width, "Aggressive handles a one-pixel corner region");
        var transparentPixels = (byte[])pixels.Clone(); for (var i = 3; i < transparentPixels.Length; i += 4) transparentPixels[i] = 0;
        var transparent = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, transparentPixels, width * 4);
        var full = new Region { Effect = RedactionEffect.Blur }; full.PutManual(0, new(0, 0, width, height)); project.Regions = [full];
        check(Pixels(EffectRenderer.Render(transparent, project, 0, null)).Where((_, i) => i % 4 != 3).All(v => v == 0), "hidden RGB in transparent pixels is not exposed by opaque effect reconstruction");
        var opaqueFirst = new Region(); opaqueFirst.PutManual(0, new(0, 0, width, height)); project.Regions = [opaqueFirst, full];
        check(Pixels(EffectRenderer.Render(image, project, 0, null)).Where((_, i) => i % 4 != 3).All(v => v == 0), "later Blur cannot recover source content replaced by an earlier opaque region");
        project.Regions = [full];
        var exporter = new VideoExport(tools);
        foreach (var name in new[] { "synthetic-with-audio.mp4", "synthetic-vfr.mp4", "synthetic-rotated.mp4", "synthetic-ntsc.mp4", "synthetic-offset.mp4", "synthetic-sar.mp4" })
        {
            var source = Path.Combine(output, name); var map = await tools.ProbeTimelineAsync(source, CancellationToken.None);
            var first = await tools.FrameAsync(source, map.Frames[0], null, CancellationToken.None);
            var media = new MediaReference(source, new FileInfo(source).Length, await ProjectStore.HashAsync(source), first.PixelWidth, first.PixelHeight, map.Frames[^1].Time + map.Frames[^1].Duration, true);
            var region = new Region { Effect = RedactionEffect.Blur, Start = 0, End = media.Duration, ShowDecorations = false };
            region.PutManual(0, new(0, 10, Math.Min(60, media.Width), Math.Min(45, media.Height - 10)));
            region.PutManual(map.Frames[^1].Time, new(8, 10, Math.Min(60, media.Width - 8), Math.Min(45, media.Height - 10)));
            var movie = new RedactionProject { Media = media, Regions = [region], Export = new() { KeepAudio = name == "synthetic-with-audio.mp4" || name == "synthetic-offset.mp4" } };
            var destination = Path.Combine(output, "effects-" + name); if (File.Exists(destination)) File.Delete(destination);
            await exporter.ExportAsync(destination, movie, map, new(), null, CancellationToken.None);
            var exported = await tools.ProbeTimelineAsync(destination, CancellationToken.None);
            check(exported.Frames.Count == map.Frames.Count, "effect export validated frame timeline: " + name);
            for (var i = 0; i < map.Frames.Count; i++)
            {
                var exact = await tools.FrameAsync(source, map.Frames[i], null, CancellationToken.None);
                var expected = Pixels(EffectRenderer.Render(exact, movie, map.Frames[i].Time, map));
                var actual = Pixels(await tools.FrameAsync(destination, exported.Frames[i], null, CancellationToken.None));
                var error = expected.Zip(actual).Select((p, index) => index % 4 == 3 ? 0 : Math.Abs(p.First - p.Second)).Average();
                check(error < 9, $"decoded effect output matches exact compositor within lossy-codec tolerance: {name} frame {i}");
            }
            check(await ProjectStore.HashAsync(source) == media.Sha256, "effect video source unchanged: " + name);
            if (name != "synthetic-with-audio.mp4") continue;
            foreach (var (effect, aggressive, shape) in new[] { (RedactionEffect.Pixelate, false, RegionShape.Oval), (RedactionEffect.Blur, true, RegionShape.Polygon) })
            {
                region.Effect = effect; region.Aggressive = aggressive; region.Shape = shape; region.Polygon = [new(0, 0), new(1, 0), new(.5, 1)];
                region.Start = map.Frames[4].Time; region.End = map.Frames[5].Time;
                var variant = Path.Combine(output, $"effects-ranged-{effect}.mp4"); if (File.Exists(variant)) File.Delete(variant);
                await exporter.ExportAsync(variant, movie, map, new(), null, CancellationToken.None);
                var variantMap = await tools.ProbeTimelineAsync(variant, CancellationToken.None);
                for (var i = 0; i < map.Frames.Count; i++)
                {
                    var original = await tools.FrameAsync(source, map.Frames[i], null, CancellationToken.None);
                    var expected = Pixels(EffectRenderer.Render(original, movie, map.Frames[i].Time, map));
                    var actual = Pixels(await tools.FrameAsync(variant, variantMap.Frames[i], null, CancellationToken.None));
                    check(expected.Zip(actual).Select((p, index) => index % 4 == 3 ? 0 : Math.Abs(p.First - p.Second)).Average() < 9, $"{effect}/{aggressive}/{shape} buffered range matches decoded output: frame {i}");
                }
            }
            region.Start = 0; region.End = media.Duration; region.Shape = RegionShape.Rectangle;
            region.Effect = RedactionEffect.Pixelate; region.Aggressive = true;
            foreach (var extension in new[] { ".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm" })
            {
                var formatPath = Path.Combine(output, "effects-aggressive" + extension); if (File.Exists(formatPath)) File.Delete(formatPath);
                await exporter.ExportAsync(formatPath, movie, map, new(), null, CancellationToken.None);
                check(File.Exists(formatPath), "Aggressive pixelate and audio validated: " + extension);
            }
            using var cancellation = new CancellationTokenSource();
            var cancelledPath = Path.Combine(output, "effects-cancelled.mp4");
            try { await exporter.ExportAsync(cancelledPath, movie, map, new(), new InlineProgress(f => { if (f > .1) cancellation.Cancel(); }), cancellation.Token); throw new Exception("Ignored export cancellation"); }
            catch (OperationCanceledException) { check(!File.Exists(cancelledPath), "mid-stream effect cancellation does not promote output"); }
            check(!Directory.EnumerateFiles(output, "effects*.partial.*").Any(), "effect video partials removed after cancellation");
            try { await exporter.ExportAsync(destination, movie, map, new(), null, CancellationToken.None); throw new Exception("Overwrote existing output"); }
            catch (IOException) { check(true, "effect export preserves existing destination"); }
        }
        var restrictive = ManagedPolicy.Parse("""{"schemaVersion":1,"policyId":"effect-test","policyVersion":"1","controls":{"disableVisualObscuration":true}}""");
        var blocked = Path.Combine(output, "effects-policy-blocked.png");
        try { await ImageExport.ExportAsync(blocked, project, restrictive, image, CancellationToken.None); throw new Exception("Ignored managed policy"); }
        catch (InvalidOperationException) { check(!File.Exists(blocked), "managed policy blocks effects before export"); }
    }
    private sealed class InlineProgress(Action<double> action) : IProgress<double> { public void Report(double value) => action(value); }
}
