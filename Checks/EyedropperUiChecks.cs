using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.6.0 eyedropper and box colour (BASE-013/014) through the actual WPF window.
internal static class EyedropperUiChecks
{
    public static void Run(string output, Action<bool, string> check)
    {
        const int width = 160, height = 90;
        var pixels = new byte[width * height * 4];
        for (var y = 0; y < height; y++) for (var x = 0; x < width; x++)
        {
            var i = (y * width + x) * 4;
            // Left half teal, right half orange, with one half-transparent pixel.
            if (x < width / 2) { pixels[i] = 0x80; pixels[i + 1] = 0x80; pixels[i + 2] = 0x10; } else { pixels[i] = 0x10; pixels[i + 1] = 0x8C; pixels[i + 2] = 0xF0; }
            pixels[i + 3] = 255;
        }
        var semi = (5 * width + 150) * 4; pixels[semi] = 0xFE; pixels[semi + 1] = 0xFE; pixels[semi + 2] = 0xFE; pixels[semi + 3] = 0x80;
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze();
        var media = new MediaReference(Path.Combine(output, "eyedropper.png"), 1, new string('0', 64), width, height, 0, false);
        check(PreviewSurface.SampleColor(image, media, new(10.4, 10.9)) == "#108080" && PreviewSurface.SampleColor(image, media, new(159.99, 89.99)) == "#F08C10",
            "eyedropper reads the exact source pixel under the pointer");
        check(PreviewSurface.SampleColor(image, media, new(150.5, 5.5)) == "#7F7F7F", "eyedropper composites a partially transparent pixel over black");
        check(PreviewSurface.SampleColor(image, media, new(-1, 4)) == null && PreviewSurface.SampleColor(image, media, new(width, 4)) == null, "eyedropper ignores points outside the media");

        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        try
        {
            // Simulate a session in which the obscuration warning has already been accepted.
            var box = new Region { Name = "Box", Start = 0, End = 0 }; box.PutManual(0, new(60, 20, 40, 30));
            var blur = new Region { Name = "Soft", Start = 0, End = 0, Effect = RedactionEffect.Blur }; blur.PutManual(0, new(10, 60, 30, 20));
            preview.Image = image;
            preview.Project = new RedactionProject { Media = media, Regions = [box, blur] };
            var regions = (ListBox)window.FindName("Regions"); regions.ItemsSource = preview.Project.Regions; regions.SelectedItem = box;
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / width, preview.ActualHeight / height);
            Point ScreenOf(double x, double y) => new((preview.ActualWidth - width * scale) / 2 + x * scale, (preview.ActualHeight - height * scale) / 2 + y * scale);
            var eyedropper = (Button)window.FindName("EyedropperButton");
            var swatch = (Border)window.FindName("ColorSwatchFill");
            check(eyedropper.IsEnabled && ((Button)window.FindName("ColorSwatch")).IsEnabled, "colour swatch and eyedropper are available for a selected Coloured box");
            eyedropper.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            // 0.9.1: the eyedropper shows TRT's own eyedropper cursor instead of a plain crosshair.
            check(preview.EyedropperActive && preview.Cursor == CustomCursors.Eyedropper, "eyedropper arms with the eyedropper cursor");
            check(preview.SampleAt(ScreenOf(20.5, 40.5)) && box.Color == "#108080" && !preview.EyedropperActive,
                "eyedropper recolours the selected Coloured box from the loaded frame and disarms");
            check(((SolidColorBrush)swatch.Background).Color == Color.FromRgb(0x10, 0x80, 0x80), "swatch shows the picked colour");
            check(box.Keyframes.Count == 1 && box.GeometryAt(0) == new MediaRect(60, 20, 40, 30), "picking a colour does not change geometry");
            typeof(MainWindow).GetMethod("Undo", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]);
            check(preview.Project.Regions[0].Color == "#000000", "Undo restores the previous box colour");
            box = preview.Project.Regions[0]; blur = preview.Project.Regions[1];

            regions.ItemsSource = preview.Project.Regions; regions.SelectedItem = null; preview.Selected = null;
            eyedropper.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            check(preview.SampleAt(ScreenOf(120.5, 10.5)) && preview.DrawingColor == "#F08C10" && box.Color == "#000000",
                "with no selected box the picked colour becomes the colour for new boxes only");
            check(preview.NewDrawingRegion(RegionShape.Rectangle).Color == "#F08C10", "newly drawn Coloured box inherits the picked colour");

            eyedropper.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            var before = preview.DrawingColor;
            check(!preview.SampleAt(new Point(-5, -5)) && !preview.EyedropperActive && preview.DrawingColor == before, "clicking outside the media cancels without changing colour");

            regions.SelectedItem = blur;
            check(!eyedropper.IsEnabled, "eyedropper is unavailable while a Blur region is selected");
            regions.SelectedItem = box;
            eyedropper.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            ((Button)window.FindName("BlurTool")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            check(!preview.EyedropperActive, "changing tools disarms the eyedropper");
            var shot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(window);
            var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot));
            using var file = File.Create(Path.Combine(output, "shell-colour-tools.png")); png.Save(file);
        }
        finally { preview.Project = new(); preview.Selected = null; window.Close(); }
    }
}
