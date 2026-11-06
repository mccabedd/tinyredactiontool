using System.IO;
using System.Reflection;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// Pictures for the Help manual (0.28.0): TRT's own windows, menus and toolbar icons, drawn off-screen into PNG files,
// so the manual shows exactly what the app looks like. `--help-shots <folder>` (not part of the checks).
internal static class HelpShots
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("Help shot timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static void Settle(int ms = 300) => Wait(async () => { await Task.Delay(ms); return 0; });

    public static void Run(string folder, string testOutput)
    {
        Directory.CreateDirectory(folder); var icons = Path.Combine(folder, "icons"); Directory.CreateDirectory(icons);
        WriteHelpIcon(folder);
        ThemedMessage.Answer = (_, _, _) => MessageBoxResult.Yes;
        var temp = Path.Combine(testOutput, "help-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(temp, "settings.json");
        MainWindow.ApplyThemeResources("Light");
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1280, Height = 760, Left = -20000, Top = 0, ShowInTaskbar = false, ShowActivated = false, ConfirmKeepQuestion = (_, _, _) => true };
        var places = new Dictionary<string, object>();
        try
        {
            controller.Start(); var bar = controller.Bar!; bar.Left = -20000; Pump();
            var editor = controller.OpenEditor(); editor.SetTheme("Light"); editor.UpdateLayout(); Pump();
            bar.UpdateLayout(); Settle();
            Save(bar, Path.Combine(folder, "capture-bar.png"));
            foreach (var button in Descendants<Button>(bar).Where(b => b.Content is string && Toolbar.GetIcon(b) != null))
                Save(button, Path.Combine(icons, "bar-" + Slug((string)button.Content) + ".png"));
            // Every toolbar button shown once, for the icon pictures.
            var all = editor.Settings.Copy(); all.EditorHiddenButtons.Clear(); all.HideOptionsBar = false; editor.ApplySettings(all); editor.UpdateLayout(); Settle();
            var preview = (PreviewSurface)editor.FindName("Preview");
            var sample = Path.Combine(temp, "Sample Letter.png"); WriteImage(sample, SampleLetter());
            Wait(() => editor.OpenPathAsync(sample)); editor.UpdateLayout(); Settle();
            foreach (var id in AppSettings.EditorButtonIds)
                if (editor.FindName(id) is Button { IsVisible: true } b) Save(b, Path.Combine(icons, Slug(id) + ".png"));
            foreach (var id in new[] { "EyedropperButton", "PlayButton", "PreviousFrameButton", "NextFrameButton", "CaptureFrameButton", "MarkerAButton", "MarkerBButton", "ClearMarkersButton" })
                if (editor.FindName(id) is Button { IsVisible: true } b) Save(b, Path.Combine(icons, Slug(id) + ".png"));

            Save((FrameworkElement)editor.FindName("OptionsBar"), Path.Combine(folder, "options-bar.png"));
            // The editor as it starts (David's toolbar), with a redaction, an arrow and a text note.
            editor.ApplySettings(new AppSettings()); editor.UpdateLayout(); Settle();
            var project = preview.Project;
            var box = new Region { Name = "Account Number", Start = 0, End = 0, Effect = RedactionEffect.Opaque }; box.PutManual(0, new MediaRect(420, 352, 330, 46)); project.Regions.Add(box);
            var blur = new Region { Name = "Signature", Start = 0, End = 0, Effect = RedactionEffect.Blur }; blur.PutManual(0, new MediaRect(96, 548, 260, 70)); project.Regions.Add(blur);
            project.Annotations.Add(new Annotation { Kind = AnnotationKind.Line, Points = [new(830, 300), new(770, 352)], Width = 6, Ends = AnnotationEnds.ArrowEnd, Color = "#D32F2F" });
            project.Annotations.Add(new Annotation { Kind = AnnotationKind.Text, Text = "Hidden before sharing", Box = new MediaRect(720, 250, 300, 44), FontSize = 26, Bold = true, Color = "#D32F2F" });
            Refresh(editor); preview.Fit(); editor.UpdateLayout(); Settle();
            Save(editor, Path.Combine(folder, "editor.png"));
            places["editor"] = Places(editor, ["MainMenu", "ToolStrip", "OptionsBar", "Preview"]);

            // A selected redaction with its window (Box, Blur, Pixelate, colour, Redact).
            preview.Selected = box; Refresh(editor); editor.UpdateLayout(); Settle();
            Save(editor, Path.Combine(folder, "editor-selected.png"));
            Save((FrameworkElement)editor.FindName("RegionPopup"), Path.Combine(folder, "redaction-window.png"));
            preview.Selected = null; Refresh(editor);

            // The side panel (Panel button) with Export Options open.
            editor.ToggleProperties(editor, new RoutedEventArgs()); editor.UpdateLayout(); Settle();
            foreach (var expander in Descendants<Expander>(editor)) expander.IsExpanded = (string)expander.Header == "Export Options";
            editor.UpdateLayout(); foreach (var scroller in Descendants<ScrollViewer>((FrameworkElement)editor.FindName("PropertiesPanel"))) scroller.ScrollToEnd(); editor.UpdateLayout(); Settle();
            Save((FrameworkElement)editor.FindName("PropertiesPanel"), Path.Combine(folder, "side-panel.png"));
            editor.ToggleProperties(editor, new RoutedEventArgs()); editor.UpdateLayout();


            // Dark theme.
            editor.SetTheme("Dark"); editor.UpdateLayout(); Settle();
            Save(editor, Path.Combine(folder, "editor-dark.png"));
            editor.SetTheme("Light"); editor.UpdateLayout(); Settle();

            // A video: the timeline, the trim row and a redaction.
            var video = Path.Combine(temp, "Street.mp4");
            using (var tools = new MediaTools()) Wait(async () => { await SampleVideoAsync(tools, video); return 0; });
            if (File.Exists(video) && Wait(() => editor.OpenPathAsync(video)))
            {
                editor.ShowTrimRow(true);
                var moving = new Region { Name = "Number Plate", Start = 0, End = 3, Effect = RedactionEffect.Pixelate }; moving.PutManual(0, new MediaRect(186, 236, 108, 30)); preview.Project.Regions.Add(moving);
                Refresh(editor); preview.Fit(); editor.UpdateLayout(); Settle(600);
                foreach (var id in new[] { "TrimToolButton", "AppendToolButton", "PlayButton", "PreviousFrameButton", "NextFrameButton", "CaptureFrameButton", "MarkerAButton", "MarkerBButton", "ClearMarkersButton" })
                    if (editor.FindName(id) is Button { IsVisible: true } b) Save(b, Path.Combine(icons, Slug(id) + ".png"));
                Save(editor, Path.Combine(folder, "editor-video.png"));
                Save((FrameworkElement)editor.FindName("PlaybackBar"), Path.Combine(folder, "timeline.png"));
                places["video"] = Places(editor, ["PlaybackBar", "TrimRow", "TransportRow"]);
            }

            // Menus (each drop-down drawn on its own).
            var menu = (Menu)editor.FindName("MainMenu");
            foreach (var top in menu.Items.OfType<MenuItem>().Where(m => m.IsVisible))
            {
                top.IsSubmenuOpen = true; editor.UpdateLayout(); Settle(150);
                if (top.Template.FindName("PART_Popup", top) is Popup { Child: FrameworkElement child }) { child.UpdateLayout(); Save(child, Path.Combine(folder, "menu-" + Slug(((string)top.Header).Replace("_", "")) + ".png")); }
                top.IsSubmenuOpen = false;
            }
            // Windows: Settings (each tab), New Image, Resize, About, a message box, the Screen Recorder.
            var settings = new SettingsWindow(new AppSettings()) { Left = -20000, ShowActivated = false, ShowInTaskbar = false };
            settings.Show(); settings.UpdateLayout(); Settle();
            var tabs = Descendants<TabControl>(settings).First();
            foreach (var tab in tabs.Items.OfType<TabItem>()) { tabs.SelectedItem = tab; settings.UpdateLayout(); Settle(150); Save(settings, Path.Combine(folder, "settings-" + Slug((string)tab.Header) + ".png")); }
            settings.Close();
            Show(new NewPictureWindow(null, null), Path.Combine(folder, "new-image.png"));
            Show(new ResizeWindow(1200, 800), Path.Combine(folder, "resize.png"));
            Show(new AboutWindow("3.0.0"), Path.Combine(folder, "about.png"));
            Show(new ThemedMessage("Wipe TRT's old captures and working copies, clear Undo, and forget the folders TRT last used?\n\nWhat is open in the editor stays. Files you saved or exported are not touched.", "Remove History", MessageBoxButton.YesNo, MessageBoxImage.Question), Path.Combine(folder, "remove-history.png"));
            Show(new RecorderWindow(new AppSettings()), Path.Combine(folder, "recorder.png"));
            editor.Close(); Pump();
            File.WriteAllText(Path.Combine(folder, "places.json"), JsonSerializer.Serialize(places, new JsonSerializerOptions { WriteIndented = true }));
            Console.WriteLine($"Help pictures written to {folder}");
        }
        finally { ThemedMessage.Answer = null; AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }

    private static void Refresh(MainWindow editor) => typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(editor, null);
    // Where the parts of a window are, as fractions of its size (for the numbered labels in the manual).
    private static Dictionary<string, double[]> Places(Window window, string[] names)
    {
        var root = (FrameworkElement)VisualTreeHelper.GetChild(window, 0);
        var result = new Dictionary<string, double[]>();
        foreach (var name in names)
            if (window.FindName(name) is FrameworkElement { IsVisible: true } element)
            {
                var r = element.TransformToAncestor(root).TransformBounds(new Rect(0, 0, element.ActualWidth, element.ActualHeight));
                result[name] = [r.X / root.ActualWidth, r.Y / root.ActualHeight, r.Width / root.ActualWidth, r.Height / root.ActualHeight];
            }
        return result;
    }
    private static void Show(Window window, string path)
    {
        window.Left = -20000; window.Top = 0; window.ShowActivated = false; window.ShowInTaskbar = false; window.WindowStartupLocation = WindowStartupLocation.Manual;
        window.Show(); window.UpdateLayout(); Settle(); Save(window, path); window.Close();
    }
    private static void Save(FrameworkElement element, string path)
    {
        if (element is MainWindow main && main.FindName("NoticeBar") is UIElement notice) notice.Visibility = Visibility.Collapsed; // The passing notice.
        var target = element is Window w ? (FrameworkElement)VisualTreeHelper.GetChild(w, 0) : element;
        if (target.ActualWidth < 1 || target.ActualHeight < 1) return;
        const double scale = 1.5; // Sharper on high-resolution screens.
        var shot = new RenderTargetBitmap((int)Math.Ceiling(target.ActualWidth * scale), (int)Math.Ceiling(target.ActualHeight * scale), 96 * scale, 96 * scale, PixelFormats.Pbgra32);
        var visual = new DrawingVisual();
        using (var dc = visual.RenderOpen())
        {
            var background = (target as Control)?.Background ?? (target as Panel)?.Background ?? (target as Border)?.Background ?? (element as Window)?.Background;
            if (background != null && target is not Button) dc.DrawRectangle(background, null, new Rect(0, 0, target.ActualWidth, target.ActualHeight));
            dc.DrawRectangle(new VisualBrush(target) { Stretch = Stretch.None, AlignmentX = AlignmentX.Left, AlignmentY = AlignmentY.Top }, null, new Rect(0, 0, target.ActualWidth, target.ActualHeight));
        }
        shot.Render(visual); WriteImage(path, shot);
    }
    private static string Slug(string text) => new string(text.Replace("…", "").Where(c => char.IsLetterOrDigit(c) || c == ' ').ToArray()).Trim().Replace(' ', '-').ToLowerInvariant();

    // A short made-up street video (a car with a made-up number plate drives past), for the video pictures.
    private static async Task SampleVideoAsync(MediaTools tools, string path)
    {
        const int width = 640, height = 360, frames = 60;
        using var transport = new MemoryStream();
        var stream = new TimestampedPngStream(transport);
        await stream.BeginAsync(width, height, frames / 20.0, 0.05, CancellationToken.None);
        for (var i = 0; i < frames; i++)
        {
            var x = 120 + i * 2.0;
            var visual = new DrawingVisual();
            using (var dc = visual.RenderOpen())
            {
                dc.DrawRectangle(new LinearGradientBrush(Color.FromRgb(0x9C, 0xC9, 0xEE), Color.FromRgb(0xDD, 0xEE, 0xF8), 90), null, new Rect(0, 0, width, 210));
                dc.DrawRectangle(new SolidColorBrush(Color.FromRgb(0x5E, 0x63, 0x6B)), null, new Rect(0, 210, width, 150));
                for (var d = 0; d < 6; d++) dc.DrawRectangle(Brushes.White, null, new Rect(d * 120 - (i * 2 % 120), 300, 60, 6));
                dc.DrawRectangle(new SolidColorBrush(Color.FromRgb(0xB0, 0xA8, 0x9A)), null, new Rect(380, 90, 200, 120));
                dc.DrawRoundedRectangle(new SolidColorBrush(Color.FromRgb(0xC6, 0x28, 0x28)), null, new Rect(x - 70, 170, 280, 90), 18, 18);
                dc.DrawRoundedRectangle(new SolidColorBrush(Color.FromRgb(0x9F, 0xD3, 0xF0)), null, new Rect(x - 30, 182, 90, 34), 6, 6);
                dc.DrawEllipse(Brushes.Black, null, new Point(x - 20, 262), 24, 24); dc.DrawEllipse(Brushes.Black, null, new Point(x + 160, 262), 24, 24);
                dc.DrawRectangle(new SolidColorBrush(Color.FromRgb(0xF7, 0xD3, 0x2E)), new Pen(Brushes.Black, 1.5), new Rect(x + 66, 236, 108, 30));
                dc.DrawText(new FormattedText("AB12 CDE", System.Globalization.CultureInfo.InvariantCulture, FlowDirection.LeftToRight, new Typeface("Arial Black"), 17, Brushes.Black, 1.0), new Point(x + 74, 239));
            }
            var bitmap = new RenderTargetBitmap(width, height, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual);
            var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap)); using var png = new MemoryStream(); encoder.Save(png);
            await stream.FrameAsync(png.ToArray(), i * 50_000L, 50_000, CancellationToken.None);
        }
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-f", "matroska", "-i", "pipe:0", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", path], path, transport.ToArray(), CancellationToken.None);
    }
    // The manual's own icon (3.0.0, David's mock-up): the TRT icon with a yellow warning triangle and a black question
    // mark over its lower right. Edge shows it on the Help window's title bar and the taskbar.
    internal static void WriteHelpIcon(string folder)
    {
        var icon = BitmapDecoder.Create(AboutWindow.AppIcon, BitmapCreateOptions.None, BitmapCacheOption.OnLoad)
            .Frames.OrderByDescending(f => f.PixelWidth).First();
        foreach (var size in new[] { 256, 48, 32, 16 })
        {
            var visual = new DrawingVisual();
            using (var dc = visual.RenderOpen())
            {
                dc.DrawImage(icon, new Rect(0, 0, size, size));
                var s = size / 256.0;
                var triangle = new StreamGeometry();
                using (var g = triangle.Open())
                {
                    g.BeginFigure(new Point(178 * s, 92 * s), true, true);
                    g.LineTo(new Point(252 * s, 222 * s), true, false);
                    g.LineTo(new Point(104 * s, 222 * s), true, false);
                }
                triangle.Freeze();
                dc.DrawGeometry(new SolidColorBrush(Color.FromRgb(0xFF, 0xD4, 0x00)), new Pen(Brushes.Black, Math.Max(1, 7 * s)) { LineJoin = PenLineJoin.Round }, triangle);
                var mark = new FormattedText("?", System.Globalization.CultureInfo.InvariantCulture, FlowDirection.LeftToRight,
                    new Typeface(new FontFamily("Segoe UI"), FontStyles.Normal, FontWeights.Black, FontStretches.Normal), 104 * s, Brushes.Black, 1.0);
                dc.DrawText(mark, new Point(178 * s - mark.Width / 2, 210 * s - mark.Baseline));
            }
            var bitmap = new RenderTargetBitmap(size, size, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual);
            WriteImage(Path.Combine(folder, size == 256 ? "help-icon.png" : $"help-icon-{size}.png"), bitmap);
        }
    }
    // A made-up letter to redact (no real person): a name, an address, an account number and a signature.
    private static BitmapSource SampleLetter()
    {
        const int width = 1100, height = 720;
        var visual = new DrawingVisual();
        using (var dc = visual.RenderOpen())
        {
            dc.DrawRectangle(new SolidColorBrush(Color.FromRgb(0xF4, 0xF1, 0xEA)), null, new Rect(0, 0, width, height));
            dc.DrawRectangle(Brushes.White, new Pen(new SolidColorBrush(Color.FromRgb(0xD8, 0xD2, 0xC4)), 1), new Rect(60, 40, width - 120, height - 80));
            var ink = new SolidColorBrush(Color.FromRgb(0x22, 0x2A, 0x36)); var soft = new SolidColorBrush(Color.FromRgb(0x6B, 0x74, 0x80));
            void Text(string text, double x, double y, double size, Brush brush, bool bold = false, string font = "Segoe UI")
                => dc.DrawText(new FormattedText(text, System.Globalization.CultureInfo.InvariantCulture, FlowDirection.LeftToRight, new Typeface(new FontFamily(font), FontStyles.Normal, bold ? FontWeights.Bold : FontWeights.Normal, FontStretches.Normal), size, brush, 1.5), new Point(x, y));
            dc.DrawRectangle(new SolidColorBrush(Color.FromRgb(0x2D, 0x5B, 0x8C)), null, new Rect(96, 76, 54, 54));
            Text("Example Energy Ltd", 166, 80, 26, ink, true); Text("Customer Services · 1 Sample Street · Exampletown", 166, 114, 14, soft);
            Text("Ms Jane Example", 96, 176, 18, ink, true); Text("12 Placeholder Road", 96, 202, 16, ink); Text("Sampleford  SF1 2AB", 96, 226, 16, ink);
            Text("5 November 2026", 840, 176, 16, soft);
            Text("Your new account details", 96, 286, 22, ink, true);
            Text("Thank you for joining us. Please keep these details safe:", 96, 322, 16, ink);
            Text("Account number:", 96, 362, 18, ink); Text("8274 1093 5561 2048", 430, 358, 26, ink, true, "Consolas");
            Text("Customer reference:", 96, 410, 18, ink); Text("EX-55-1029-AB", 430, 408, 20, ink, false, "Consolas");
            Text("If anything here looks wrong, please call us on the number on our website.", 96, 468, 16, ink);
            Text("Yours sincerely,", 96, 512, 16, ink);
            Text("A. N. Other", 110, 556, 42, new SolidColorBrush(Color.FromRgb(0x1F, 0x3C, 0x88)), false, "Segoe Script");
            Text("Customer Services Manager", 96, 628, 14, soft);
        }
        var bitmap = new RenderTargetBitmap(width, height, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual); bitmap.Freeze(); return bitmap;
    }
    private static IEnumerable<T> Descendants<T>(DependencyObject root) where T : DependencyObject
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(root); i++)
        {
            var child = VisualTreeHelper.GetChild(root, i);
            if (child is T found) yield return found;
            foreach (var deeper in Descendants<T>(child)) yield return deeper;
        }
    }
    private static void WriteImage(string path, BitmapSource picture)
    {
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(picture)); using var stream = File.Create(path); encoder.Save(stream);
    }
}
