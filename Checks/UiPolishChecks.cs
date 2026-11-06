using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.9.1: David's feedback on 0.9.0: progress popup, Clear button, cursors, redaction popup,
// greyed-out video controls for still images, the text window.
internal static class UiPolishChecks
{
    public static void Run(string output, Action<bool, string> check)
    {
        const int width = 200, height = 100;
        var pixels = new byte[width * height * 4]; Array.Fill(pixels, (byte)235);
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze();
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        MethodInfo Method(string name) => typeof(MainWindow).GetMethod(name, BindingFlags.Instance | BindingFlags.NonPublic)!;
        FieldInfo Field(string name) => typeof(MainWindow).GetField(name, BindingFlags.Instance | BindingFlags.NonPublic)!;
        try
        {
            void Refresh() => Method("Refresh").Invoke(window, null);
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "polish.png"), 1, new string('0', 64), width, height, 0, false) };
            Refresh(); preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / width, preview.ActualHeight / height);
            Point At(double x, double y) => new((preview.ActualWidth - width * scale) / 2 + x * scale, (preview.ActualHeight - height * scale) / 2 + y * scale);
            void Drag(Point from, Point to) { preview.PointerDown(from, MouseButton.Left); preview.PointerMove(to); preview.PointerUp(); }
            void Click(Button b) => b.RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent));
            void Tool(string name) => Click(Find<Button>(name));

            // Still images grey out the video controls; video enables them.
            var videoControls = new[] { "PreviousFrameButton", "PlayButton", "NextFrameButton", "Speed", "Timeline" }.Select(Find<Control>).ToArray();
            check(videoControls.All(c => !c.IsEnabled) && !Find<FrameworkElement>("TransportControls").IsVisible && !Find<FrameworkElement>("Timeline").IsVisible && !Find<FrameworkElement>("ClockText").IsVisible && !Find<FrameworkElement>("RangeLane").IsVisible && !Find<FrameworkElement>("PlaybackBar").IsVisible && Find<FrameworkElement>("ClearScreenButton").IsVisible,
                "a still image hides the timeline, time and playback controls (0.17.0; 0.18.0 the whole bar), keeping the Clear buttons");
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "polish.mp4"), 1, new string('0', 64), width, height, 10, true) };
            preview.Timeline = new FrameTimeline(Enumerable.Range(0, 10).Select(i => new FrameStamp(i, i, 1))); Refresh();
            check(videoControls.All(c => c.IsEnabled && c.IsVisible) && Find<FrameworkElement>("ClockText").IsVisible, "a video shows and enables the timeline and playback controls");
            preview.Timeline = null;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "polish.png"), 1, new string('0', 64), width, height, 0, false) }; Refresh();
            var clear = Find<Button>("ClearScreenButton");
            check(clear.IsVisible && clear.IsEnabled && ((StackPanel)window.FindName("RightTools")).Children.Contains(clear), "Clear screen is on the toolbar (0.18.0: at the far right beside Panel)");

            // Progress popup: titled, determinate when progress is known, with a working Cancel.
            var overlay = Find<Grid>("WorkOverlay"); var progress = Find<ProgressBar>("WorkProgress");
            Field("busy").SetValue(window, true);
            Method("ShowWorkPopup").Invoke(window, ["Saving Project"]);
            check(overlay.Visibility == Visibility.Collapsed, "the progress popup waits a moment, so quick operations don't flash");
            Method("RevealWorkPopup").Invoke(window, [null, EventArgs.Empty]);
            check(overlay.Visibility == Visibility.Visible && Find<TextBlock>("WorkTitle").Text == "Saving Project…" && progress.IsIndeterminate, "a slower operation shows a Saving/Loading popup with a progress bar");
            Method("ReportWork").Invoke(window, [0.4, "Exporting and validating · 40%"]);
            check(!progress.IsIndeterminate && Math.Abs(progress.Value - 0.4) < 1e-9 && Find<TextBlock>("WorkDetail").Text.Contains("40%"), "the popup shows real progress and the current step");
            using (var work = new CancellationTokenSource())
            {
                Field("work").SetValue(window, work);
                Click(Find<Button>("WorkCancelButton"));
                check(work.IsCancellationRequested, "the popup's Cancel button cancels the operation");
                Field("work").SetValue(window, null);
            }
            Method("HideWorkPopup").Invoke(window, null); Field("busy").SetValue(window, false);
            check(overlay.Visibility == Visibility.Collapsed, "the popup closes when the work ends");

            // Cursors.
            check(CustomCursors.OpenHand != null && CustomCursors.ClosedHand != null && CustomCursors.Eyedropper != null, "TRT's own hand, grab and eyedropper cursors load");
            Tool("PanTool");
            check(preview.HoverCursor(At(50, 50)) == CustomCursors.OpenHand && preview.Cursor == CustomCursors.OpenHand, "Pan shows an open hand");
            preview.PointerDown(At(50, 50), MouseButton.Left);
            check(preview.Cursor == CustomCursors.ClosedHand, "panning shows a closed (grabbing) hand");
            preview.PointerUp();
            Tool("RectangleTool");
            check(preview.HoverCursor(At(50, 50)) == Cursors.Cross, "a drawing tool shows a crosshair over empty media");
            Drag(At(40, 20), At(120, 60));
            var region = preview.Project.Regions.Single();
            check(preview.HoverCursor(At(40, 20)) == Cursors.SizeNWSE && preview.HoverCursor(At(120, 40)) == Cursors.SizeWE && preview.HoverCursor(At(80, 60)) == Cursors.SizeNS,
                "the selected shape's handles show resize arrows");
            check(preview.HoverCursor(At(80, 40)) == Cursors.SizeAll, "a shape's body shows the move cursor");
            Tool("SelectToolButton");
            check(preview.HoverCursor(At(180, 90)) == null, "Select shows the normal arrow over empty media");

            // Redaction popup.
            var popup = Find<Border>("RegionPopup"); var layer = Find<Canvas>("TextEditorLayer");
            preview.Selected = region; Refresh(); window.UpdateLayout();
            var bounds = preview.RegionScreenBounds(region);
            check(popup.Visibility == Visibility.Visible && Canvas.GetTop(popup) >= bounds.Bottom && Math.Abs(Canvas.GetLeft(popup) + popup.ActualWidth / 2 - (bounds.X + bounds.Width / 2)) < 1,
                "a selected redaction shows the popup centred just below it");
            check(Find<StackPanel>("PopupColorOption").Visibility == Visibility.Visible && Find<StackPanel>("PopupStrengthOption").Visibility == Visibility.Collapsed && Find<Button>("PopupFollow").Visibility == Visibility.Collapsed,
                "a coloured box offers its colour; still images have no Follow");
            preview.PointerDown(At(80, 40), MouseButton.Left); preview.PointerMove(At(85, 42));
            check(popup.Visibility == Visibility.Collapsed, "the popup hides while the shape is dragged");
            preview.PointerUp();
            check(popup.Visibility == Visibility.Visible, "the popup returns when the drag ends");
            Click(Find<Button>("PopupBlur"));
            check(region.Effect == RedactionEffect.Blur && Find<StackPanel>("PopupStrengthOption").Visibility == Visibility.Visible, "the popup's Blur changes the redaction and offers strength");
            Find<Slider>("PopupStrength").Value = 8;
            check(region.Strength == 8, "the popup's strength changes the redaction");
            Click(Find<Button>("PopupOpaque"));
            Click(Find<Button>("PopupRedact"));
            check(preview.Selected == null && popup.Visibility == Visibility.Collapsed && preview.Project.Regions.Count == 1 && region.Effect == RedactionEffect.Opaque, "Redact accepts the redaction and closes the popup");
            Tool("RectangleTool"); Drag(At(40, 80), At(120, 99));
            window.UpdateLayout();
            var low = preview.Project.Regions.Last();
            check(popup.Visibility == Visibility.Visible && Canvas.GetTop(popup) + popup.ActualHeight <= preview.RegionScreenBounds(low).Top, "near the bottom the popup appears above the shape");
            Click(Find<Button>("PopupDelete"));
            check(preview.Project.Regions.Count == 1 && popup.Visibility == Visibility.Collapsed, "the popup's Delete removes the redaction");

            // The text window.
            Tool("TextTool");
            var panel = Find<Border>("TextEditorPanel"); var textBox = Find<TextBox>("AnnotationTextBox");
            Drag(At(10, 10), At(90, 45));
            check(panel.Visibility == Visibility.Visible && Find<ComboBox>("TextFont").SelectedItem as string == "Segoe UI" && Find<TextBox>("TextSize").Text == "24" && Find<ToggleButton>("TextAlignLeft").IsChecked == true,
                "the text window opens with the colour, font, size, bold/italic and alignment row");
            textBox.Text = "Styled";
            Find<ToggleButton>("TextBold").IsChecked = true; Find<ToggleButton>("TextBold").RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent));
            Find<ToggleButton>("TextAlignCentre").RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent));
            Click(Find<Button>("TextSizeUp"));
            check(preview.EditingPreview is { Bold: true, Align: AnnotationAlign.Centre, FontSize: 25 } && Find<ToggleButton>("TextAlignLeft").IsChecked == false, "style changes preview live in the text window");
            Click(Find<Button>("TextEditorClose"));
            var text = preview.Project.Annotations.Single();
            check(panel.Visibility == Visibility.Collapsed && text is { Text: "Styled", Bold: true, Align: AnnotationAlign.Centre, FontSize: 25 }, "closing the text window keeps the text and its style");
            check(preview.AnnotationStyle is { Bold: true, FontSize: 25 }, "the next text starts with the last used style");
            preview.PointerDown(At(50, 25), MouseButton.Left, 2); preview.PointerUp();
            Click(Find<Button>("TextSizeDown")); Click(Find<Button>("TextSizeDown"));
            window.CloseTextEditor(true);
            check(text.FontSize == 25, "Esc in the text window discards style changes too");
            preview.PointerDown(At(50, 25), MouseButton.Left, 2); preview.PointerUp();
            textBox.Text = "Restyled"; Click(Find<Button>("TextSizeDown"));
            Click(Find<Button>("TextEditorClose"));
            check(text is { Text: "Restyled", FontSize: 24 }, "a re-edit applies new text and style");
            Method("Undo").Invoke(window, [window, new RoutedEventArgs()]);
            var undone = preview.Project.Annotations.Single();
            check(undone is { Text: "Styled", FontSize: 25 }, "one Undo restores both the text and its style");

            var shot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32);
            preview.PointerDown(At(50, 25), MouseButton.Left, 2); preview.PointerUp(); window.UpdateLayout(); shot.Render(window);
            var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot)); using (var file = File.Create(Path.Combine(output, "shell-text-window.png"))) png.Save(file);
            window.CloseTextEditor(true);
            Tool("RectangleTool"); Drag(At(120, 20), At(180, 50)); window.UpdateLayout();
            shot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(window);
            png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot)); using (var file = File.Create(Path.Combine(output, "shell-region-popup.png"))) png.Save(file);
        }
        finally { preview.Project = new(); preview.Selected = null; preview.SelectAnnotation(null); window.Close(); }
    }
}
