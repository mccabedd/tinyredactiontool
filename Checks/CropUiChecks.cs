using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.7.0 Crop Image tool through the actual WPF window.
internal static class CropUiChecks
{
    public static void Run(string output, Action<bool, string> check)
    {
        const int width = 200, height = 100;
        var pixels = new byte[width * height * 4];
        for (var i = 0; i < pixels.Length; i += 4) { pixels[i] = 235; pixels[i + 1] = 235; pixels[i + 2] = 235; pixels[i + 3] = 255; }
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze();
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        try
        {
            var cropTool = (Button)window.FindName("CropTool");
            var confirm = (Button)window.FindName("ConfirmCropButton");
            var remove = (Button)window.FindName("RemoveCropButton");
            var refresh = typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!;
            // Video: 3.0.0 (David) crop works on videos too (the full video checks are in Release300LayerChecks).
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "crop-video.mp4"), 1, new string('0', 64), width, height, 1, true) };
            refresh.Invoke(window, null);
            cropTool.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            check(cropTool.IsEnabled && preview.Tool == "Crop", "Crop tool is available for a video (3.0.0)");
            preview.Tool = "Rectangle"; preview.CropDraft = null;

            var box = new Region { Name = "Box", Start = 0, End = 0 }; box.PutManual(0, new(120, 40, 30, 30));
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "crop-ui.png"), 1, new string('0', 64), width, height, 0, false), Regions = [box] };
            refresh.Invoke(window, null);
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            check(cropTool.IsEnabled && remove.Visibility != Visibility.Visible, "Crop tool is available for a still image");
            cropTool.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            check(preview.Tool == "Crop" && confirm.Visibility == Visibility.Visible && !confirm.IsEnabled, "Crop tool shows Confirm crop, disabled until a rectangle is drawn");

            var scale = Math.Min(preview.ActualWidth / width, preview.ActualHeight / height);
            Point At(double x, double y) => new((preview.ActualWidth - width * scale) / 2 + x * scale, (preview.ActualHeight - height * scale) / 2 + y * scale);
            check(preview.BeginCrop(At(40, 20)), "dragging on the image starts a crop rectangle");
            preview.DragCrop(At(160.4, 80.6)); preview.EndCrop();
            check(preview.CropDraft is { } d1 && Math.Abs(d1.X - 40) < .01 && Math.Abs(d1.Width - 120.4) < .01 && confirm.IsEnabled, "crop rectangle follows the drag and enables Confirm crop");
            check(preview.Project.Crop == null, "drawing a crop does not change the image until confirmed");
            // 0.21.4 (David): Confirm and Cancel in their own window under the crop rectangle, not in the options bar.
            window.UpdateLayout();
            var popup = (Border)window.FindName("CropPopup"); var cancel = (Button)window.FindName("CancelCropButton");
            var optionsBar = (Border)window.FindName("OptionsBar");
            var draftOnScreen = preview.ScreenRect(preview.CropDraft!.Value);
            check(popup.IsVisible && confirm.IsVisible && cancel.IsVisible && IsInside(confirm, popup) && !IsInside(confirm, optionsBar) && (Canvas.GetTop(popup) >= draftOnScreen.Bottom || Canvas.GetTop(popup) + popup.ActualHeight <= draftOnScreen.Top),
                "Confirm crop and Cancel crop are in their own window under the crop rectangle, not in the options bar");
            check(cancel.Background is SolidColorBrush { Color: { R: 0xB3, G: 0x26, B: 0x1E } } && cancel.Foreground is SolidColorBrush { Color: var white } && white == Colors.White,
                "Cancel crop is red with white text");
            check(Toolbar.GetAccent(cropTool) == null, "the Crop icon is drawn as lines only (no filled square, which hid it in Dark mode)");
            preview.BeginCrop(At(160.4, 80.6)); preview.DragCrop(At(170, 90)); preview.EndCrop();
            check(preview.CropDraft is { } d2 && Math.Abs(d2.X + d2.Width - 170) < .01 && Math.Abs(d2.Y + d2.Height - 90) < .01 && Math.Abs(d2.X - 40) < .01, "corner handle resizes the crop");
            preview.BeginCrop(At(100, 50)); preview.DragCrop(At(400, 50)); preview.EndCrop();
            check(preview.CropDraft is { } d3 && Math.Abs(d3.X + d3.Width - width) < .01 && Math.Abs(d3.Width - 130) < .01, "dragging inside moves the crop and keeps it inside the image");
            preview.BeginCrop(At(70 + 65, 20)); preview.DragCrop(At(135, 30)); preview.EndCrop();
            check(preview.CropDraft is { } d4 && Math.Abs(d4.Y - 30) < .01, "edge handle resizes one side");

            window.ConfirmCropDraft();
            var crop = preview.Project.Crop;
            check(crop == new MediaRect(70, 30, 130, 60) && preview.Tool == "Rectangle" && preview.CropDraft == null, "Confirm crop applies whole source pixels and returns to drawing");
            check(remove.Visibility == Visibility.Visible && confirm.Visibility != Visibility.Visible, "Remove crop is offered after cropping");
            window.UpdateLayout(); preview.UpdateLayout();
            var cropScale = Math.Min(preview.ActualWidth / 130, preview.ActualHeight / 60);
            Point Cropped(double x, double y) => new((preview.ActualWidth - 130 * cropScale) / 2 + (x - 70) * cropScale, (preview.ActualHeight - 60 * cropScale) / 2 + (y - 30) * cropScale);
            check(Sample(preview, Cropped(135, 55)) is var black && black.R < 5 && black.G < 5 && black.B < 5, "view fits the crop and redactions stay on the same source pixels");
            check(Sample(preview, Cropped(75, 35)) is var grey && grey.R > 200, "cropped view shows the selected image area");
            Render(window, Path.Combine(output, "shell-crop-applied.png"));

            cropTool.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            check(!preview.BeginCrop(Cropped(20, 10)), "a second crop cannot start outside the current crop");
            preview.BeginCrop(Cropped(80, 40)); preview.DragCrop(new Point(-500, -500)); preview.EndCrop();
            check(preview.CropDraft is { } d5 && Math.Abs(d5.X - 70) < .01 && Math.Abs(d5.Y - 30) < .01, "a second crop is limited to the current crop");
            Render(window, Path.Combine(output, "shell-crop-draft.png"));
            preview.CropDraft = null;
            window.ConfirmCropDraft();
            check(preview.Project.Crop == crop, "Confirm without a rectangle changes nothing");
            preview.BeginCrop(Cropped(80, 40)); preview.DragCrop(Cropped(120, 70)); preview.EndCrop();
            window.CancelCropDraft(); window.UpdateLayout();
            check(preview.Tool == "Rectangle" && preview.CropDraft == null && preview.Project.Crop == crop && !((Border)window.FindName("CropPopup")).IsVisible,
                "Cancel crop drops the rectangle, leaves the Crop tool and keeps the crop already applied");

            typeof(MainWindow).GetMethod("Undo", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]);
            check(preview.Project.Crop == null && preview.Project.Regions.Count == 1, "Undo removes the crop and keeps the redaction");
            typeof(MainWindow).GetMethod("Redo", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]);
            check(preview.Project.Crop == crop, "Redo restores the crop");
            remove.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            check(preview.Project.Crop == null && remove.Visibility != Visibility.Visible, "Remove crop shows the whole image again");
            check(((Button)window.FindName("ExportButton")).IsEnabled, "export remains available");
            // Regression: leaving Crop active while the image goes away (Clear screen, opening a video,
            // closing) recursed between the draft and the toolbar until the stack overflowed.
            cropTool.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            preview.BeginCrop(At(10, 10)); preview.DragCrop(At(50, 50)); preview.EndCrop();
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "crop-video.mp4"), 1, new string('0', 64), width, height, 1, true) };
            refresh.Invoke(window, null);
            check(preview.CropDraft == null || preview.Tool == "Crop", "switching to a video while cropping is safe (no recursion)");
            cropTool.IsEnabled = true; preview.Tool = "Crop";
            preview.Project = new RedactionProject();
            refresh.Invoke(window, null);
            check(preview.Tool == "Rectangle", "clearing the workspace while cropping safely leaves the Crop tool");
        }
        finally { preview.Project = new(); preview.Selected = null; window.Close(); }
    }
    private static bool IsInside(DependencyObject child, DependencyObject parent)
    {
        for (var at = child; at != null; at = VisualTreeHelper.GetParent(at)) if (at == parent) return true;
        return false;
    }
    private static Color Sample(PreviewSurface preview, Point point)
    {
        preview.UpdateLayout();
        var bitmap = new RenderTargetBitmap((int)Math.Ceiling(preview.ActualWidth), (int)Math.Ceiling(preview.ActualHeight), 96, 96, PixelFormats.Pbgra32);
        var local = new DrawingVisual();
        using (var drawing = local.RenderOpen()) drawing.DrawRectangle(new VisualBrush(preview), null, new Rect(0, 0, preview.ActualWidth, preview.ActualHeight));
        bitmap.Render(local);
        var bytes = new byte[4]; bitmap.CopyPixels(new Int32Rect((int)point.X, (int)point.Y, 1, 1), bytes, 4, 0);
        return Color.FromRgb(bytes[2], bytes[1], bytes[0]);
    }
    private static void Render(Window window, string path)
    {
        var shot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(window);
        var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot));
        using var file = File.Create(path); png.Save(file);
    }
}
