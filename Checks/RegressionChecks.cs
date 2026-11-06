using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.9.2: regressions David found in 0.9.1, driven through the real mouse-press path.
internal static class RegressionChecks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    public static void Run(string output, Action<bool, string> check)
    {
        const int width = 200, height = 100;
        var pixels = new byte[width * height * 4]; Array.Fill(pixels, (byte)235);
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze();
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show(); window.Activate();
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        try
        {
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "regression.png"), 1, new string('0', 64), width, height, 0, false) };
            typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null);
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / width, preview.ActualHeight / height);
            Point At(double x, double y) => new((preview.ActualWidth - width * scale) / 2 + x * scale, (preview.ActualHeight - height * scale) / 2 + y * scale);
            void Press(Point p, int clicks = 1) { preview.MouseDownAt(p, MouseButton.Left, clicks); preview.PointerUp(); Pump(); }
            void Drag(Point from, Point to) { preview.MouseDownAt(from, MouseButton.Left, 1); preview.PointerMove(to); preview.PointerUp(); Pump(); }
            void Tool(string name) { ((Button)window.FindName(name)).RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump(); }
            var panel = Find<Border>("TextEditorPanel"); var textBox = Find<TextBox>("AnnotationTextBox");

            // 1. Double-click on an existing text reopens the editor and it stays open.
            Tool("TextTool");
            Drag(At(10, 10), At(90, 45));
            textBox.Text = "Hello"; window.CloseTextEditor(false);
            var text = preview.Project.Annotations.Single();
            Press(At(150, 80));
            Press(At(50, 25)); Press(At(50, 25), 2);
            check(panel.Visibility == Visibility.Visible && preview.EditingText == text && textBox.Text == "Hello",
                "double-clicking an existing text reopens the text window and it stays open (real mouse path)");
            window.CloseTextEditor(true); Pump();

            // 2. The Redact button's caption is white in Light (and Dark), on the visible popup.
            Tool("RectangleTool"); Drag(At(120, 60), At(180, 90)); window.UpdateLayout();
            check(Find<Border>("RegionPopup").Visibility == Visibility.Visible, "the redaction popup is showing for the new box");
            foreach (var theme in new[] { 2, 1 })
            {
                Find<ComboBox>("ThemeChoice").SelectedIndex = theme; Pump();
                var redact = Find<Button>("PopupRedact"); redact.ApplyTemplate(); redact.UpdateLayout();
                var caption = Descendants(redact).OfType<TextBlock>().FirstOrDefault();
                check(caption?.Foreground is SolidColorBrush { Color: var c } && c == Colors.White, $"the popup's Redact caption is white in {(theme == 2 ? "Light" : "Dark")}");
            }
            Find<ComboBox>("ThemeChoice").SelectedIndex = 2; Pump();
            preview.Project.Regions.Clear(); preview.Selected = null; Press(At(10, 95));

            // 3. With the Polygon tool, clicking an existing shape selects it rather than starting a polygon.
            Tool("PolygonTool");
            var draft = (List<MediaPoint>)typeof(PreviewSurface).GetField("polygon", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.GetValue(preview)!;
            Press(At(120, 20)); Press(At(180, 20)); Press(At(150, 80)); Press(At(120, 20) + new Vector(2, 2));
            var polygon = preview.Project.Regions.Single(r => r.Shape == RegionShape.Polygon);
            Press(At(20, 90));
            check(preview.Selected == null && draft.Count == 0, "a click outside the closed polygon accepts it");
            Press(At(150, 40));
            check(preview.Selected == polygon && draft.Count == 0 && preview.Project.Regions.Count == 1, "with Polygon, clicking the shape selects it instead of starting a new polygon");
            var before = polygon.GeometryAt(0);
            Drag(At(150, 40), At(140, 45));
            check(draft.Count == 0 && Math.Abs(polygon.GeometryAt(0).X - before.X + 10) < 1, "with Polygon, dragging the shape moves it");
            Press(At(20, 90)); Press(At(20, 90));
            check(draft.Count == 1, "with Polygon, a click on empty media still starts a new polygon");
            draft.Clear();
        }
        finally { preview.Project = new(); preview.Selected = null; preview.SelectAnnotation(null); window.Close(); }
    }
    private static IEnumerable<DependencyObject> Descendants(DependencyObject parent)
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        { var child = VisualTreeHelper.GetChild(parent, i); yield return child; foreach (var nested in Descendants(child)) yield return nested; }
    }
}
