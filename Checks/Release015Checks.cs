using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.15.0: David's list after trying 0.14.0 (Actual Size, line ends/dashes as pictures, one width
// adjuster, defaults width 6 with an arrow, eyedropper icon, no Visual obscuration question, drawing
// tool order, Clear all redactions, and the Tracking stopped dialog).
internal static class Release015Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static IEnumerable<DependencyObject> Descendants(DependencyObject parent)
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        { var child = VisualTreeHelper.GetChild(parent, i); yield return child; foreach (var nested in Descendants(child)) yield return nested; }
    }
    public static void Run(string output, Action<bool, string> check)
    {
        var image = BitmapSource.Create(400, 300, 96, 96, PixelFormats.Bgra32, null, new byte[400 * 300 * 4], 1600); image.Freeze();
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        window.ApplySettings(new AppSettings { HideOptionsBar = false }); // 0.27.0: David's defaults hide the options bar; these checks use it.
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        void Click(string name) { Find<ButtonBase>(name).RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump(); window.UpdateLayout(); }
        void Refresh() { typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null); window.UpdateLayout(); }
        try
        {
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(System.IO.Path.Combine(output, "release015.png"), 1, new string('0', 64), 400, 300, 0, false) };
            Refresh();

            // Toolbar: drawing tools in David's order; Actual Size after Fit.
            var names = Find<WrapPanel>("ToolButtons").Children.OfType<Button>().Select(b => ((string)b.Content).Replace("\n", " ")).ToList();
            var text = names.IndexOf("Text");
            check(names.Skip(text).Take(6).SequenceEqual(["Text", "Outline", "Ellipse", "Line", "Polyline", "Pen"]), "drawing tools read Text, Outline, Ellipse, Line, Polyline, Pen");
            check(names.IndexOf("Actual Size") == names.IndexOf("Fit") + (names.Contains("Fit Width") ? 2 : 1), "Actual Size sits just after Fit (and Fit Width, shown by David's 3.1.3 defaults)");
            preview.Fit(); Click("ActualSizeButton");
            check(Find<TextBlock>("ZoomText").Text == "100%", "Actual Size shows the picture at 100%");

            // No "Visual obscuration" question: choosing Blur just selects it (a question would stop this check).
            Click("BlurTool");
            check(preview.DrawingEffect == RedactionEffect.Blur, "choosing Blur no longer asks the Visual obscuration question");
            Click("OpaqueTool");

            // Line options: width 6 and an arrow at the end by default; one ▲▼ width box; pictures for ends and dashes.
            Click("LineTool");
            var width = Find<NumberSpinner>("AnnotationWidth"); var popupWidth = Find<NumberSpinner>("LinePopupWidth");
            check(preview.AnnotationStyle.Width == 6 && preview.AnnotationStyle.Ends == AnnotationEnds.ArrowEnd && width.Value == 6 && Find<ComboBox>("AnnotationEnds").SelectedIndex == (int)AnnotationEnds.ArrowEnd,
                "new lines start 6 pixels wide with an arrowhead at the end");
            width.Step(1);
            check(preview.AnnotationStyle.Width == 7 && popupWidth.Value == 7, "the ▲ of the width box widens new lines, and the Line window's width box follows");
            width.Box.Text = "99"; width.Commit();
            check(width.Value == Annotation.MaxWidth && preview.AnnotationStyle.Width == Annotation.MaxWidth, "a typed width beyond the limit is pulled back to 20");
            width.Box.Text = "abc"; width.Commit();
            check(width.Value == Annotation.MaxWidth && width.Box.Text == "20", "typing something that is not a number leaves the width as it was");
            width.Value = 6;
            var ends = Find<ComboBox>("AnnotationEnds"); var dashes = Find<ComboBox>("AnnotationDash");
            check(ends.Items.Count == 7 && dashes.Items.Count == 5 && ends.ItemTemplate != null && dashes.ItemTemplate != null && Find<ComboBox>("LinePopupEnds").Items.Count == 7,
                "Ends and Dashes list pictures (arrow and dot ends, five line styles), in the options bar and the Line window");
            dashes.IsDropDownOpen = true; Pump(); dashes.UpdateLayout();
            var row = dashes.ItemContainerGenerator.ContainerFromIndex(1) as ComboBoxItem;
            var dashPath = row == null ? null : Descendants(row).OfType<System.Windows.Shapes.Path>().FirstOrDefault();
            dashes.IsDropDownOpen = false;
            check(dashPath?.StrokeDashArray is { Count: > 0 }, "the Dash choice is drawn as a dashed line");
            Click("TextTool");
            check(Find<NumberSpinner>("AnnotationSize").Value == preview.AnnotationStyle.FontSize, "text size uses the same ▲▼ box");

            // Eyedropper: a solid pipette (0.18.0: design D, filled in the text colour, with a colour swatch).
            check(Toolbar.GetIconFill(Find<Button>("EyedropperButton")) is Geometry pipette && pipette.Bounds.Width > 8 && Toolbar.GetAccent(Find<Button>("EyedropperButton")) != null,
                "the eyedropper is a solid pipette");

            // Clear all redactions: beside Clear Editor; Undo brings them back.
            var clearAll = Find<Button>("ToolClearRedactions");
            check(!clearAll.IsEnabled, "Clear all redactions is greyed out when there are none");
            var region = new Region { Name = "Box", Start = 0, End = 0 }; region.PutManual(0, new(10, 10, 40, 30));
            preview.Project.Regions.Add(region); preview.Project.Annotations.Add(new Annotation { Kind = AnnotationKind.Line, Points = [new(1, 1), new(50, 50)] });
            Refresh();
            var row2 = (StackPanel)VisualTreeHelper.GetParent(clearAll);
            check(clearAll.IsEnabled && row2.Children.IndexOf(clearAll) + 2 == row2.Children.IndexOf(Find<Button>("ClearScreenButton")), "Clear all redactions sits beside Clear Editor (0.16.0: with Clear all annotations between)");
            Click("ToolClearRedactions");
            check(preview.Project.Regions.Count == 0 && preview.Project.Annotations.Count == 1 && preview.Project.Media != null, "Clear all redactions removes the redactions only (the picture and annotations stay)");
            typeof(MainWindow).GetMethod("Undo", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]);
            check(preview.Project.Regions.Count == 1, "Undo brings the cleared redactions back");
        }
        finally { preview.Project = new(); preview.Selected = null; window.Close(); }

        // Tracking stopped dialog: plain words, no "Keep range for later", Continue redaction.
        var frame = BitmapSource.Create(64, 48, 96, 96, PixelFormats.Bgra32, null, new byte[64 * 48 * 4], 256); frame.Freeze();
        var dialog = new FollowLossReview(frame, 1, frame, 1.04, new(4, 4, 8, 8), new(4, 4, 8, 8)) { Left = -20000, ShowInTaskbar = false };
        var last = new FollowLossReview(frame, 1, frame, 1.04, null, null, canContinue: false) { Left = -20000, ShowInTaskbar = false };
        var words = string.Join(" ", new[] { dialog.Title, ((TextBlock)dialog.FindName("MatchedLabel")).Text, ((TextBlock)dialog.FindName("UnmatchedLabel")).Text, ((TextBlock)dialog.FindName("Explanation")).Text });
        check(dialog.Title == "Tracking Stopped" && dialog.FindName("KeepButton") == null && ((Button)dialog.FindName("ContinueButton")).IsEnabled && !words.Contains("ollow"),
            "the Tracking stopped dialog speaks of tracking, has no Keep range for later and offers Continue redaction");
        check(!((Button)last.FindName("ContinueButton")).IsEnabled, "Continue redaction is greyed out on the redaction's last frame");
        dialog.Close(); last.Close();
    }
}
