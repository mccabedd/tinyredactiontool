using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.8.1: click-outside acceptance for Rectangle/Oval/Polygon (baseline BASE-009 and the
// "outside-click is consumed" rule), plus David's Dark/Light and transport feedback.
internal static class DrawingGestureChecks
{
    public static void Run(string output, Action<bool, string> check)
    {
        const int width = 200, height = 100;
        var pixels = new byte[width * height * 4];
        for (var i = 0; i < pixels.Length; i += 4) { pixels[i] = 235; pixels[i + 1] = 235; pixels[i + 2] = 235; pixels[i + 3] = 255; }
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze();
        // No saved theme preference: the app must start in Light.
        File.Delete(Path.Combine(AppContext.BaseDirectory, "theme.preference"));
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        var themeChoice = (ComboBox)window.FindName("ThemeChoice");
        try
        {
            check(themeChoice.SelectedIndex == 2 && ((SolidColorBrush)window.FindResource("Surface")).Color == (Color)ColorConverter.ConvertFromString("#F0F0F0"), "with no saved preference the app starts in Light");
            var refresh = typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!;
            var draft = (List<MediaPoint>)typeof(PreviewSurface).GetField("polygon", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(preview)!;
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "gesture-ui.png"), 1, new string('0', 64), width, height, 0, false) };
            refresh.Invoke(window, null);
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / width, preview.ActualHeight / height);
            Point At(double x, double y) => new((preview.ActualWidth - width * scale) / 2 + x * scale, (preview.ActualHeight - height * scale) / 2 + y * scale);
            void Click(Point p) { preview.PointerDown(p, MouseButton.Left); preview.PointerUp(); }
            void Drag(Point from, Point to) { preview.PointerDown(from, MouseButton.Left); preview.PointerMove(to); preview.PointerUp(); }
            void Tool(string name) => ((Button)window.FindName(name)).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            var regions = preview.Project.Regions;

            foreach (var (toolName, shape) in new[] { ("RectangleTool", RegionShape.Rectangle), ("OvalTool", RegionShape.Oval) })
            {
                regions.Clear(); preview.Selected = null; Tool(toolName);
                Click(At(30, 30));
                check(regions.Count == 0, shape + ": a plain click on empty media does not leave a tiny region");
                Drag(At(20, 20), At(80, 60));
                var drawn = regions.SingleOrDefault();
                check(drawn is { } d && d.Shape == shape && preview.Selected == d && Math.Abs(d.GeometryAt(0).Width - 60) < 1 && Math.Abs(d.GeometryAt(0).Height - 40) < 1, shape + ": dragging draws and selects the shape");
                Click(At(150, 80));
                check(regions.Count == 1 && preview.Selected == null, shape + ": a click outside accepts the shape and does not start another");
                preview.PointerDown(At(150, 80), MouseButton.Left); preview.PointerMove(At(150, 80) + new Vector(1, 1)); preview.PointerUp();
                check(regions.Count == 1, shape + ": a slight jiggle while clicking does not create a shape");
                Drag(At(120, 20), At(170, 70));
                check(regions.Count == 2 && preview.Selected == regions[1], shape + ": dragging outside still draws a new shape straight away");
            }

            regions.Clear(); Tool("RectangleTool"); Drag(At(140, 60), At(180, 90));
            Tool("PolygonTool");
            check(preview.Selected != null, "a shape is selected before polygon drawing starts");
            Click(At(10, 10));
            check(preview.Selected == null && draft.Count == 0 && regions.Count == 1, "Polygon: first click outside only accepts the selected shape");
            Click(At(10, 10)); Click(At(60, 10)); Click(At(40, 50));
            Click(At(10, 10) + new Vector(2, 2));
            var polygon = regions.LastOrDefault();
            check(regions.Count == 2 && polygon is { Shape: RegionShape.Polygon } && polygon.Polygon.Count == 3 && preview.Selected == polygon && draft.Count == 0, "Polygon: clicking the first point closes the shape");
            Click(At(150, 30));
            check(regions.Count == 2 && preview.Selected == null && draft.Count == 0, "Polygon: a click outside the closed shape accepts it and draws no line from its last point");
            Click(At(150, 30));
            check(draft.Count == 1 && regions.Count == 2, "Polygon: the next click begins a new polygon");
            draft.Clear();

            var play = (Button)window.FindName("PlayButton");
            check(Toolbar.GetIcon(play) == window.FindResource("IconPlay") && Toolbar.GetIcon((Button)window.FindName("EyedropperButton")) == window.FindResource("IconEyedropper"), "transport and Pick colour buttons show icons");
            var showPlay = typeof(MainWindow).GetMethod("ShowPlayButton", BindingFlags.Instance | BindingFlags.NonPublic)!;
            showPlay.Invoke(window, [true]);
            check(Toolbar.GetIcon(play) == window.FindResource("IconPause") && (string)play.Content == "Pause", "Play switches to a Pause icon while playing");
            showPlay.Invoke(window, [false]);

            // Dark: #535353 chrome, and drop-downs/buttons (enabled or disabled) must not render white.
            // The speed list shows only for videos since 0.17.0; show it here so its Dark look is still checked.
            ((FrameworkElement)window.FindName("TransportControls")).Visibility = Visibility.Visible;
            themeChoice.SelectedIndex = 1; window.UpdateLayout();
            check(((SolidColorBrush)window.FindResource("Surface")).Color == (Color)ColorConverter.ConvertFromString("#535353"), "Dark uses #535353 for the window chrome");
            foreach (var name in new[] { "EffectMode", "Speed", "ExportQuality", "StopRedactionButton", "ColorSwatch" })
            {
                var control = (FrameworkElement)window.FindName(name);
                if (!control.IsVisible) continue;
                check(MaxBrightness(control) < 130, $"Dark {name} has no white field or face");
            }
            var shot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(window);
            var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot)); using (var file = File.Create(Path.Combine(output, "shell-dark-gestures.png"))) png.Save(file);
            themeChoice.SelectedIndex = 2;
        }
        finally { preview.Project = new(); preview.Selected = null; window.Close(); }
    }
    // Brightness of the control's face, sampled away from its text and border.
    private static int MaxBrightness(FrameworkElement control)
    {
        var w = (int)Math.Ceiling(control.ActualWidth); var h = (int)Math.Ceiling(control.ActualHeight);
        var local = new DrawingVisual();
        using (var dc = local.RenderOpen())
        {
            // Composite over the themed surface, as on screen, so a faded white face still shows.
            dc.DrawRectangle((Brush)control.FindResource("Surface"), null, new Rect(0, 0, control.ActualWidth, control.ActualHeight));
            dc.DrawRectangle(new VisualBrush(control), null, new Rect(0, 0, control.ActualWidth, control.ActualHeight));
        }
        var bitmap = new RenderTargetBitmap(w, h, 96, 96, PixelFormats.Pbgra32); bitmap.Render(local);
        var pixel = new byte[4]; bitmap.CopyPixels(new Int32Rect(3, h / 2, 1, 1), pixel, 4, 0);
        return Math.Max(pixel[0], Math.Max(pixel[1], pixel[2]));
    }
}
