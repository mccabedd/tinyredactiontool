using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.16.0: David's list after trying 0.15.0 (dotted lines, dot ends, hollow end-point handles, clear
// buttons, Panel last, bigger transport icons, Playback Speed, Light/Dark switch).
internal static class Release016Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    // Draws one annotation on a white 200 × 100 picture and returns which pixels came out red.
    private static bool[] Red(Annotation a)
    {
        var visual = new DrawingVisual();
        using (var dc = visual.RenderOpen()) { dc.DrawRectangle(Brushes.White, null, new Rect(0, 0, 200, 100)); AnnotationRenderer.Draw(dc, a, p => new Point(p.X, p.Y), 1, 1); }
        var bitmap = new RenderTargetBitmap(200, 100, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual);
        var pixels = new byte[200 * 100 * 4]; bitmap.CopyPixels(pixels, 800, 0);
        return Enumerable.Range(0, 200 * 100).Select(i => pixels[i * 4 + 2] > 200 && pixels[i * 4 + 1] < 90).ToArray();
    }
    // Along y = 50 from x = 20 to 180: how many red pixels, and how many separate red runs.
    private static (int Red, int Runs) Along(bool[] red)
    {
        int count = 0, runs = 0; var inside = false;
        for (var x = 20; x <= 180; x++) { var r = red[50 * 200 + x]; if (r) count++; if (r && !inside) runs++; inside = r; }
        return (count, runs);
    }
    public static void Run(string output, Action<bool, string> check)
    {
        // Dots show in Line, Polyline, Outline and Ellipse, not only Pen.
        Annotation Line(AnnotationDash dash, AnnotationKind kind = AnnotationKind.Line) => new() { Kind = kind, Width = 4, Dash = dash, Ends = AnnotationEnds.None, Points = [new(10, 50), new(190, 50)] };
        var dotted = Along(Red(Line(AnnotationDash.Dot))); var dashDot = Along(Red(Line(AnnotationDash.DashDot))); var dashDotDot = Along(Red(Line(AnnotationDash.DashDotDot, AnnotationKind.Polyline)));
        check(dotted.Runs > 10 && dotted.Red > 40, $"a dotted line shows its dots ({dotted.Runs} dots)");
        check(dashDot.Runs > 8 && dashDotDot.Runs > dashDot.Runs, "dash-dot and dash-dot-dot lines show their dots too (Line and Polyline)");
        var outline = new Annotation { Kind = AnnotationKind.Rectangle, Width = 4, Dash = AnnotationDash.Dot, Box = new(20, 30, 160, 40) };
        var top = Red(outline); var dots = 0; var was = false;
        for (var x = 25; x < 175; x++) { var r = top[30 * 200 + x]; if (r && !was) dots++; was = r; }
        check(dots > 10, "a dotted Outline shows its dots");
        var ellipse = Red(new Annotation { Kind = AnnotationKind.Oval, Width = 4, Dash = AnnotationDash.Dot, Box = new(20, 10, 160, 80) });
        check(ellipse.Count(r => r) > 60, "a dotted Ellipse shows its dots");

        // Dot ends.
        var plain = Red(Line(AnnotationDash.Solid)); var dotEnd = Line(AnnotationDash.Solid); dotEnd.Ends = AnnotationEnds.DotBoth; var ends = Red(dotEnd);
        check(!plain[46 * 200 + 190] && ends[46 * 200 + 190] && ends[46 * 200 + 10] && !ends[46 * 200 + 100], "Dots both ends draws a round dot, wider than the line, on each end");
        check(Enum.GetValues<AnnotationEnds>().Length == 7 && LineStyleItem.Ends.Count == 7, "the Ends list offers dot ends as well as arrows");

        var image = BitmapSource.Create(400, 300, 96, 96, PixelFormats.Bgra32, null, new byte[400 * 300 * 4], 1600); image.Freeze();
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        void Click(string name) { Find<ButtonBase>(name).RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump(); window.UpdateLayout(); }
        void Refresh() { typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null); window.UpdateLayout(); }
        try
        {
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(System.IO.Path.Combine(output, "release016.png"), 1, new string('0', 64), 400, 300, 0, false) };
            var region = new Region { Name = "Box", Start = 0, End = 0 }; region.PutManual(0, new(10, 10, 40, 30));
            preview.Project.Regions.Add(region); preview.Project.Annotations.Add(new Annotation { Kind = AnnotationKind.Line, Points = [new(1, 1), new(50, 50)] });
            Refresh();

            // Clear buttons on the toolbar and at the bottom; Panel at the far right.
            // 0.18.0: the Clear buttons moved beside Panel (RightTools).
            var names = Find<StackPanel>("RightTools").Children.OfType<Button>().Select(b => ((string)b.Content).Replace("\n", " ")).ToList();
            check(names.SequenceEqual(["File Info", "Clear Redactions", "Clear Annotations", "Clear Editor", "Panel"]), "the toolbar ends with Clear Redactions, Clear Annotations and Clear Editor, then Panel (0.27.0: David's defaults put File Info first on the right)");
            // 0.16.1: the captions are on two lines, so the buttons are narrower than one-line captions.
            var clearEditorTool = Find<Button>("ClearScreenButton");
            check(((string)clearEditorTool.Content).Contains('\n') && clearEditorTool.ActualWidth < 52, "Clear Editor, Clear Redactions and Clear Annotations have two-line captions (narrower buttons)");
            // 0.16.2 (David): the Clear buttons show their words without an icon, so every toolbar button is the same height.
            // Compared row by row: a narrow window wraps the toolbar onto two rows.
            var toolRow = Find<WrapPanel>("ToolButtons");
            var heights = toolRow.Children.OfType<Button>().Where(b => b.IsVisible).GroupBy(b => Math.Round(b.TranslatePoint(new Point(0, 0), toolRow).Y)).Select(g => g.Select(b => Math.Round(b.ActualHeight, 1)).Distinct().Count()).Distinct().ToList();
            var tallest = Find<WrapPanel>("ToolButtons").Children.OfType<Button>().Where(b => b.IsVisible && !Toolbar.GetWordsOnly(b)).Max(b => b.DesiredSize.Height);
            check(Find<StackPanel>("RightTools").Children.OfType<Button>().Where(Toolbar.GetWordsOnly).All(b => b.DesiredSize.Height <= tallest + .1), "the two-line Clear captions fit within the height of the icon buttons");
            check(Toolbar.GetWordsOnly(clearEditorTool) && heights.SequenceEqual([1]), "every toolbar button in a row is the same height (the Clear buttons are words only)");
            // 0.16.1 (David): Panel at the far right of the toolbar strip.
            var panelButton = Find<Button>("PanelButton"); var strip = Find<Border>("ToolStrip");
            var panelRight = panelButton.TranslatePoint(new Point(panelButton.ActualWidth, 0), strip).X;
            check(!Find<WrapPanel>("ToolButtons").Children.Contains(panelButton) && strip.ActualWidth - panelRight < 12, "Panel sits at the far right of the toolbar");
            // 0.18.0: the bottom-row Clear buttons moved to the toolbar beside Panel (checked in FrameSpeedChecks).
            Click("ToolClearAnnotations");
            check(preview.Project.Annotations.Count == 0 && preview.Project.Regions.Count == 1 && !Find<Button>("ToolClearAnnotations").IsEnabled, "Clear Annotations removes the annotations only, and then greys out");
            typeof(MainWindow).GetMethod("Undo", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]); Refresh();
            check(preview.Project.Annotations.Count == 1, "Undo brings the cleared annotations back");
            Click("ToolClearRedactions");
            check(preview.Project.Regions.Count == 0 && preview.Project.Annotations.Count == 1, "Clear Redactions on the toolbar removes the redactions only");

            // Bottom row.
            check(Toolbar.GetIconSize(Find<Button>("PreviousFrameButton")) == 30 && Toolbar.GetIconSize(Find<Button>("NextFrameButton")) == 30 && Toolbar.GetIconSize(Find<Button>("PlayButton")) == 35,
                "frame back/forward icons are 50% larger and play/pause 75% larger");
            var speed = Find<ComboBox>("Speed"); var row = (StackPanel)speed.Parent;
            check(speed.Width == 50 && row.Children[row.Children.IndexOf(speed) - 1] is TextBlock { Text: "Playback Speed" }, "the narrower speed list is labelled Playback Speed");

            // 0.18.0 (David): the top-right Light/Dark switch is gone; the theme is chosen in Settings.
            var choice = Find<ComboBox>("ThemeChoice");
            check(window.FindName("ThemeToggle") == null && !choice.IsVisible, "the Light/Dark switch is gone from the top right (the theme is in Settings)");
            window.SetTheme("Dark"); Pump();
            check(choice.SelectedIndex == 1 && MainWindow.DarkTheme && ((SolidColorBrush)window.FindResource("Surface")).Color == (Color)ColorConverter.ConvertFromString("#535353"), "choosing Dark (as Settings does) turns Dark on");
            window.SetTheme("Light"); Pump();
            check(choice.SelectedIndex == 2 && !MainWindow.DarkTheme, "choosing Light goes back to Light");
        }
        finally { Find<ComboBox>("ThemeChoice").SelectedIndex = 2; preview.Project = new(); preview.Selected = null; window.Close(); }

        // Copy and Paste switch on after a picture is opened the real way (0.16.0: they stayed grey,
        // because they were only updated while loading was still busy).
        var picture = System.IO.Path.Combine(output, "release016-open.png");
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(image));
        using (var file = System.IO.File.Create(picture)) encoder.Save(file);
        var editor = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        editor.Show();
        try
        {
            Task<bool>? opening = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(1);
            var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
            timer.Tick += (_, _) => { if (opening?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
            Dispatcher.CurrentDispatcher.BeginInvoke(() => { opening = editor.OpenPathAsync(picture); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
            check(opening?.IsCompleted == true && opening.Result && ((Button)editor.FindName("CopyButton")).IsEnabled && ((Button)editor.FindName("PasteButton")).IsEnabled,
                "after opening a picture, Copy and Paste are available straight away");
        }
        finally { editor.Close(); }
    }
}
