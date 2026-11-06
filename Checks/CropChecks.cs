using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.7.0 still-image crop: geometry, project rules and export after redaction.
internal static class CropChecks
{
    public static async Task Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var bounds = new MediaRect(0, 0, 100, 50);
        check(ImageCrop.PixelRect(new(10.4, 5.6, 20.2, 10.1), bounds) == new MediaRect(10, 5, 21, 11), "crop draft expands outward to whole source pixels");
        check(ImageCrop.PixelRect(new(-20, 40, 50, 30), bounds) == new MediaRect(0, 40, 30, 10), "crop draft is limited to the current bounds");
        check(ImageCrop.PixelRect(new(120, 10, 5, 5), bounds) == null && ImageCrop.PixelRect(new(10, 10, 0, 0), bounds) == null, "empty or outside crop drafts are refused");
        check(ImageCrop.PixelRect(new(0, 0, 500, 500), new(20, 10, 30, 20)) == new MediaRect(20, 10, 30, 20), "a second crop stays inside the confirmed crop");
        check(ImageCrop.PixelRect(new(69.99999999, 29.9999999999, 130.00000001, 60.0000000001), bounds with { Width = 300, Height = 300 }) == new MediaRect(70, 30, 130, 60),
            "rounding noise at an exact pixel edge does not grow the crop");

        const int width = 120, height = 80;
        var pixels = new byte[width * height * 4];
        for (var y = 0; y < height; y++) for (var x = 0; x < width; x++)
        { var i = (y * width + x) * 4; pixels[i] = (byte)(x * 2); pixels[i + 1] = (byte)(y * 3); pixels[i + 2] = (byte)((x + y) % 2 == 0 ? 220 : 30); pixels[i + 3] = 255; }
        var source = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); source.Freeze();
        var sourcePath = Path.Combine(output, "crop-source.png"); if (File.Exists(sourcePath)) File.Delete(sourcePath);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(source));
        using (var file = File.Create(sourcePath)) encoder.Save(file);
        var hash = await ProjectStore.HashAsync(sourcePath);
        var project = new RedactionProject { Media = new(sourcePath, new FileInfo(sourcePath).Length, hash, width, height, 0, false), Crop = new MediaRect(10, 20, 50, 30) };
        ProjectStore.Validate(project);
        check(true, "valid whole-pixel image crop is accepted");
        void Rejects(Action<RedactionProject> change, string name)
        {
            var candidate = ProjectStore.Deserialize(ProjectStore.Serialize(project)); change(candidate);
            try { ProjectStore.Validate(candidate); check(false, name); } catch (InvalidDataException) { check(true, name); }
        }
        Rejects(p => p.Crop = new MediaRect(10.5, 20, 50, 30), "fractional crop is rejected");
        Rejects(p => p.Crop = new MediaRect(100, 20, 50, 30), "crop beyond the image is rejected");
        Rejects(p => p.Crop = new MediaRect(10, 20, 0, 30), "empty crop is rejected");
        Rejects(p => p.Media = p.Media! with { IsVideo = true, Duration = 1 }, "video crop is rejected");
        Rejects(p => p.CoordinateSpace = "legacy-autorotated-pixels", "crop requires current square-pixel coordinates");
        var withCrop = ProjectStore.Serialize(project);
        check(ProjectStore.Deserialize(withCrop).Crop == project.Crop, "project saves and restores the confirmed crop");
        var withoutCrop = ProjectStore.Serialize(new RedactionProject { Media = project.Media });
        check(!withoutCrop.Contains("\"Crop\""), "projects without a crop keep the 0.6.0 file layout");
        ExportGate.Check(project, new());
        check(true, "a crop alone can be exported, like the inherited Export Cropped Image");
        try { ExportGate.Check(new RedactionProject { Media = project.Media }, new()); check(false, "export with neither redaction nor crop is blocked"); }
        catch (InvalidOperationException) { check(true, "export with neither redaction nor crop is blocked"); }
        var history = new EditHistory(); history.Checkpoint(project); project.Crop = new MediaRect(0, 0, 10, 10);
        project = history.Undo(project);
        check(project.Crop == new MediaRect(10, 20, 50, 30), "Undo restores the previous crop");

        // Crop only: exact source sub-rectangle.
        var cropOnly = Path.Combine(output, "crop-only.png"); if (File.Exists(cropOnly)) File.Delete(cropOnly);
        await ImageExport.ExportAsync(cropOnly, project, new(), source, CancellationToken.None, tools);
        var exported = Decode(cropOnly);
        check(exported.Width == 50 && exported.Height == 30, "cropped PNG has the crop dimensions");
        check(exported.Pixels.AsSpan().SequenceEqual(ImageCrop.CropBgra(pixels, width, height, project.Crop!.Value)), "cropped PNG is exactly the selected source pixels");

        // Crop is applied after redaction: an opaque box and a Blur straddling the crop edge.
        var box = new Region { Start = 0, End = 0, ShowDecorations = false }; box.PutManual(0, new(40, 30, 40, 15)); project.Regions.Add(box);
        var blur = new Region { Start = 0, End = 0, Effect = RedactionEffect.Blur, ShowDecorations = false }; blur.PutManual(0, new(0, 35, 25, 12)); project.Regions.Add(blur);
        var redacted = Path.Combine(output, "crop-redacted.png"); if (File.Exists(redacted)) File.Delete(redacted);
        await ImageExport.ExportAsync(redacted, project, new(), source, CancellationToken.None, tools);
        var full = new FormatConvertedBitmap(EffectRenderer.Render(source, project, 0, null), PixelFormats.Bgra32, null, 0);
        var fullPixels = new byte[width * height * 4]; full.CopyPixels(fullPixels, width * 4, 0);
        var result = Decode(redacted);
        check(result.Pixels.AsSpan().SequenceEqual(ImageCrop.CropBgra(fullPixels, width, height, project.Crop!.Value)),
            "crop is taken from the fully redacted image, including regions that cross its edge");
        var inside = ((35 - 20) * 50 + (45 - 10)) * 4;
        check(result.Pixels[inside] == 0 && result.Pixels[inside + 1] == 0 && result.Pixels[inside + 2] == 0, "opaque replacement remains inside the crop");

        foreach (var extension in new[] { ".jpg", ".gif", ".webp" })
        {
            var path = Path.Combine(output, "crop-redacted" + extension); if (File.Exists(path)) File.Delete(path);
            await ImageExport.ExportAsync(path, project, new(), source, CancellationToken.None, tools);
            var frame = await tools.FrameAsync(path, null, null, CancellationToken.None);
            check(frame.PixelWidth == 50 && frame.PixelHeight == 30, extension + " export uses the crop dimensions");
        }
        check(await ProjectStore.HashAsync(sourcePath) == hash, "cropping and exporting never changes the original image");
    }
    private static (int Width, int Height, byte[] Pixels) Decode(string path)
    {
        using var stream = File.OpenRead(path);
        var frame = new PngBitmapDecoder(stream, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad).Frames[0];
        var converted = new FormatConvertedBitmap(frame, PixelFormats.Bgra32, null, 0);
        var bytes = new byte[frame.PixelWidth * frame.PixelHeight * 4]; converted.CopyPixels(bytes, frame.PixelWidth * 4, 0);
        return (frame.PixelWidth, frame.PixelHeight, bytes);
    }
}
