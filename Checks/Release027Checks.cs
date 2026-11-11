using System.IO;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.27.0: David's last edits before the Development Build tag goes: "Add Image" (menu and a toolbar button beside
// Open), "Image" in the menus, a menu item for every toolbar button, Title Case wording, and his settings file as the
// defaults. `--release-027-only`.
internal static class Release027Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.27.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }

    // Words that stay small inside a Title Case phrase.
    private static readonly HashSet<string> Small = ["a", "an", "the", "and", "but", "or", "nor", "for", "as", "at", "by", "in", "of", "on", "to", "via", "per", "vs", "from", "with", "into", "onto", "than", "px", "s"];
    // The words of a label that should have a capital and don't ("Capture active window" -> "active", "window").
    internal static IEnumerable<string> LowerWords(string label)
    {
        var text = label.Replace("_", "");
        var words = Regex.Matches(text, @"(?<![\w.&#{])[a-z][a-z']*").Cast<Match>().ToList();
        foreach (var m in words)
        {
            var before = text[..m.Index].TrimEnd();
            var first = before.Length == 0 || ":(/·–—|".Contains(before[^1]);
            if (first || !Small.Contains(m.Value)) yield return m.Value;
        }
    }
    private static bool Sentence(string text) => Regex.IsMatch(text, @"\.\s|[.?!]\)?$");

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- David's settings file is the first-start default (with Add Image after Open) ----
        string[] davidToolbar =
        [
            "NewButton", "OpenButton", "AddImageButton", "OpenProjectButton", "PreviousPictureButton", "NextPictureButton", "ExportButton", "SaveProjectButton", "SaveMediaButton", "OriginalButton", "CopyButton", "PasteButton", "|",
            "UndoButton", "RedoButton", "DeleteButton", "|", "SelectToolButton", "RectangleTool", "OvalTool", "PolygonTool", "|", "TrimToolButton", "AppendToolButton", "|",
            "OpaqueTool", "BlurTool", "PixelateTool", "|", "TextTool", "DrawRectangleTool", "DrawOvalTool", "LineTool", "PolylineTool", "FreehandTool", "|",
            "CropTool", "ResizeButton", "RotateClockwiseButton", "RotateCounterClockwiseButton", "FlipHorizontalButton", "FlipVerticalButton", "|",
            "ZoomInButton", "ZoomOutButton", "FitButton", "FitWidthButton", "ActualSizeButton", "FullScreenButton", "PanTool", "SlideshowButton", "NavBarButton", "|",
            ">", "FileInfoButton", "|", "ToolClearRedactions", "ToolClearAnnotations", "ClearScreenButton", "|", "SettingsButton", "PanelButton",
        ];
        var fresh = new AppSettings();
        check(fresh.EditorToolbar.SequenceEqual(davidToolbar) && AppSettings.CleanToolbar(fresh.EditorToolbar).SequenceEqual(davidToolbar),
            "the toolbar starts in David's order, with Add Image between Open and Open Project");
        check(fresh.EditorHiddenButtons.ToHashSet().SetEquals(["OpenProjectButton", "PreviousPictureButton", "NextPictureButton", "SaveProjectButton", "SaveMediaButton", "OriginalButton", "DeleteButton",
                "FlipHorizontalButton", "FlipVerticalButton", "ZoomInButton", "ZoomOutButton", "FitWidthButton", "SlideshowButton", "NavBarButton", "SettingsButton"]) && !fresh.EditorHiddenButtons.Contains("AddImageButton"),
            "the hidden buttons are David's, and Add Image is shown (ticked)");
        check(fresh.BarButtons.SequenceEqual(["Region", "Freehand", "ActiveWindow", "WindowObject", "FullScreen", "Scrolling", "Recorder", "Editor", "Output"]) && fresh.StripWidth == 60 && fresh.HideOptionsBar
              && fresh.SlideshowSeconds == 5 && fresh.SlideshowRepeat && !fresh.NavBarInEditor && fresh.NavBarInSlideshow && fresh.NavBarPinnedInSlideshow && fresh.NavBarThumbnailSize == 72
              && fresh.ScreenshotShortcut == "Ctrl+PrintScreen" && fresh.RecordingShortcut == "Ctrl+Shift+PrintScreen" && fresh.BarShortcut == "Ctrl+Alt+B" && fresh.EditorShortcut == "Ctrl+Alt+E"
              && fresh.Output == CaptureOutput.Editor && fresh.RecordingFramesPerSecond == 15 && fresh.RecordMousePointer && fresh.RecordMouseClicks && !fresh.CaptureMousePointer && !fresh.CloseButtonQuits && fresh.ShowCaptureBar,
            "the other first-start settings are David's (capture bar buttons without the Ruler, 60-pixel red tab, options bar hidden, shortcuts...)");
        var olderToolbar = AppSettings.Parse("{\"EditorToolbar\":[\"NewButton\",\"OpenButton\",\"ExportButton\",\">\",\"PanelButton\"],\"EditorHiddenButtons\":[]}");
        check(olderToolbar.EditorToolbar.IndexOf("AddImageButton") == olderToolbar.EditorToolbar.IndexOf("OpenButton") + 1 && !olderToolbar.EditorHiddenButtons.Contains("AddImageButton"),
            "settings saved by an older TRT get Add Image right after Open, shown");
        check(SettingsWindow.ToolbarLabel("AddImageButton") == "Add Image" && Application.Current.TryFindResource("IconAddImage") is Geometry,
            "Settings › Toolbar lists Add Image, and it has its own icon");
        check(!MainWindow.AboutText.Contains("development", StringComparison.OrdinalIgnoreCase) && Regex.IsMatch(MainWindow.AboutText, @"^TinyRedactionTool \d+\.\d+\.\d+\n"),
            "the About box no longer says development build");

        // 0.27.1 (David): the simple About box, like the original TRT's, with his description where the old one had its blank area.
        var about = new AboutWindow("0.27.1") { Left = -20000, Top = 0, ShowActivated = false, WindowStartupLocation = WindowStartupLocation.Manual };
        about.Show(); about.UpdateLayout();
        var aboutTexts = Descendants<TextBlock>(about).Where(t => t.TemplatedParent is not Button && t.Parent is not Button).Select(t => t.Text).Where(t => t is not ("Copy" or "Close")).ToList(); // 0.28.0: button captions aside.
        var descriptionBlock = Descendants<TextBlock>(about).First(t => t.Text == AboutWindow.Description);
        // 0.28.0: in this TRT's style, the copyright sits under the name and version.
        check(aboutTexts.Take(6).SequenceEqual(["TinyRedactionTool v0.27.1", "Copyright (C) 2026 David McCabe", AboutWindow.Description, "Local media processing. No telemetry or media uploads.",
                  "Licensed under GPL-2.0-or-later. Source available on GitHub.", AboutWindow.SourceAddress]) && about.Title == "About TinyRedactionTool",
            $"the About box reads: name and version, copyright, David's description, local processing, licence, the address (got {string.Join(" | ", aboutTexts)})");
        check(descriptionBlock.ActualHeight > 40 && descriptionBlock.ActualWidth <= about.ActualWidth - 40 && about.ActualHeight < 460,
            $"the description wraps onto several lines inside the box ({descriptionBlock.ActualWidth:0}x{descriptionBlock.ActualHeight:0} in a {about.ActualWidth:0}x{about.ActualHeight:0} box)");
        var root = (FrameworkElement)VisualTreeHelper.GetChild(about, 0);
        var shot = new RenderTargetBitmap((int)Math.Ceiling(root.ActualWidth), (int)Math.Ceiling(root.ActualHeight), 96, 96, PixelFormats.Pbgra32);
        shot.Render(root);
        using (var file = File.Create(Path.Combine(output, "about-box.png"))) { var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot)); png.Save(file); }
        about.Close();

        var folder = Path.Combine(output, "release027"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        var temp = Path.Combine(output, "release027-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release027-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); editor.UpdateLayout(); Pump();
            check(!editor.Title.Contains("development", StringComparison.OrdinalIgnoreCase) && System.Text.RegularExpressions.Regex.IsMatch(editor.Title, @"^TinyRedactionTool \d+\.\d+\.\d+$")
                  && !Descendants<TextBlock>(editor).Any(t => t.Text.Contains("DEVELOPMENT", StringComparison.OrdinalIgnoreCase)),
                $"the window title and menu bar no longer say Development Build (title {editor.Title})");

            // ---- Menus: "Image", Add Image, and every toolbar button has a menu item ----
            var menu = (Menu)editor.FindName("MainMenu");
            List<MenuItem> All(ItemsControl parent) => parent.Items.OfType<MenuItem>().SelectMany(m => new[] { m }.Concat(All(m))).ToList();
            var items = All(menu); string Header(MenuItem m) => (m.Header as string ?? "").Replace("_", "");
            var file = menu.Items.OfType<MenuItem>().First(m => Header(m) == "File");
            // 3.1.2 (David): the File menu's order and shortcuts.
            var fileItems = file.Items.OfType<MenuItem>().Take(8).Select(m => Header(m) + (string.IsNullOrEmpty(m.InputGestureText) ? "" : " " + m.InputGestureText)).ToArray();
            check(fileItems.SequenceEqual(["New Image… Ctrl+N", "Open Media… Ctrl+O", "Export… Ctrl+E", "Save Media As… Ctrl+Shift+S", "Add Image… Ctrl+Shift+O", "Open Project…", "Save Project…", "File Info… Ctrl+I"]),
                "the File menu reads New Image, Open Media (Ctrl+O), Export (Ctrl+E), Save Media As (Ctrl+Shift+S), Add Image, Open Project, Save Project, File Info: " + string.Join(" | ", fileItems));
            check(items.Any(m => Header(m) == "Add Image…") && items.Any(m => Header(m) == "Paste onto Image") && items.Any(m => Header(m) == "Resize Image…")
                  && !items.Any(m => Header(m).Contains("picture", StringComparison.OrdinalIgnoreCase)),
                $"the menus say Image (New Image, Add Image, Paste onto Image...), never picture ({string.Join(", ", items.Select(Header).Where(h => h.Contains("icture")))})");
            var lower = items.Where(m => m.Header is string h && LowerWords(h).Any()).Select(Header).ToList();
            check(lower.Count == 0, $"every menu item is in Title Case ({string.Join(", ", lower)})");

            static string[] Clicks(UIElement element, RoutedEvent click)
            {
                var store = typeof(UIElement).GetProperty("EventHandlersStore", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(element);
                if (store == null) return [];
                var handlers = (RoutedEventHandlerInfo[]?)store.GetType().GetMethod("GetRoutedEventHandlers")!.Invoke(store, [click]) ?? [];
                return handlers.Select(h => h.Handler.Method.Name).ToArray();
            }
            var missing = new List<string>();
            foreach (var id in AppSettings.EditorButtonIds)
            {
                var button = (Button)editor.FindName(id);
                var clicks = Clicks(button, ButtonBase.ClickEvent);
                if (!items.Any(m => Equals(m.Tag, id) || Clicks(m, MenuItem.ClickEvent).Intersect(clicks).Any() && (m.Tag == null || Equals(m.Tag, button.Tag)))) missing.Add(id);
            }
            check(missing.Count == 0 && items.Any(m => Header(m) == "Trim") && items.Any(m => Header(m) == "Append Video…") && items.Any(m => Header(m) == "Clear All Annotations"),
                $"every toolbar button has a menu item: Video › Trim and Append Video, Edit › Clear All Annotations (missing {string.Join(", ", missing)})");
            check(items.Any(m => Equals(m.Tag, "Scrolling")) && items.Any(m => Header(m) == "Screen Ruler"), "the Capture menu has the capture bar's Scrolling Window and Ruler too");

            // ---- Title Case on the toolbar and in Settings ----
            var tips = AppSettings.EditorButtonIds.Select(id => (Button)editor.FindName(id)).Select(b => b.ToolTip as string ?? "").Where(t => t.Length > 0 && !Sentence(t) && LowerWords(t).Any()).ToList();
            check(tips.Count == 0, $"toolbar tooltips are in Title Case ({string.Join(" | ", tips)})");
            var settings = new SettingsWindow(new AppSettings()) { Left = -20000, ShowActivated = false, ShowInTaskbar = false };
            settings.Show(); settings.UpdateLayout(); Pump();
            var labels = new List<string>();
            foreach (var tab in Descendants<TabControl>(settings).First().Items.OfType<TabItem>())
            {
                if (tab.Header is string h) labels.Add(h);
                if (tab.Content is DependencyObject content)
                    labels.AddRange(LogicalDescendants(content).Select(d => d switch { HeaderedContentControl g when g.Header is string gh => gh, ContentControl c when c.Content is string cs => cs, TextBlock t => t.Text, _ => "" }));
            }
            var lowerLabels = labels.Where(l => l.Length > 0 && !char.IsDigit(l[0]) && !Sentence(l) && LowerWords(l).Any()).Distinct().ToList();
            settings.Close();
            check(lowerLabels.Count == 0, $"Settings labels are in Title Case ({string.Join(" | ", lowerLabels)})");
            var bar = controller.Bar!;
            var barTips = Descendants<Button>(bar).Select(b => b.ToolTip as string ?? "").Where(t => t.Length > 0 && !Sentence(t) && LowerWords(t).Any()).ToList();
            check(barTips.Count == 0, $"capture bar tooltips are in Title Case, as David asked (Capture Active Window) ({string.Join(" | ", barTips)})");

            // ---- Add Image: off without a picture, on with one, off for a video ----
            var add = (Button)editor.FindName("AddImageButton"); var open = (Button)editor.FindName("OpenButton");
            var strip = (Panel)editor.FindName("ToolButtons");
            check(add.IsVisible && strip.Children.IndexOf(add) == strip.Children.IndexOf(open) + 1 && !add.IsEnabled && (string)add.Content == "Add Image",
                "Add Image sits on the toolbar right after Open (New › Open › Add Image), greyed out with nothing open");
            var picture = Path.Combine(folder, "photo.png"); WriteImage(picture, NewPictureWindow.Blank(80, 60, Colors.Teal));
            check(Wait(() => editor.OpenPathAsync(picture)) && add.IsEnabled, "with an image open, Add Image is available");
            var extra = Path.Combine(folder, "extra.png"); WriteImage(extra, NewPictureWindow.Blank(20, 10, Colors.Orange));
            var preview = (PreviewSurface)editor.FindName("Preview");
            check(Wait(() => editor.AddPictureFilesAsync([extra])) == 1 && preview.Project.Annotations.SingleOrDefault() is { Kind: AnnotationKind.Picture }, "Add Image puts the chosen image onto the open one");
            editor.Close(); Pump();
        }
        finally { MainWindow.ApplyThemeResources("Light"); AppSettings.Path = savedPath; if (controller.Editor is { } openEditor) openEditor.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
    private static IEnumerable<DependencyObject> LogicalDescendants(DependencyObject root)
    {
        foreach (var child in LogicalTreeHelper.GetChildren(root).OfType<DependencyObject>())
        {
            yield return child;
            foreach (var deeper in LogicalDescendants(child)) yield return deeper;
        }
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
