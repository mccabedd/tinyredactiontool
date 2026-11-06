using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 3.0.0, after the clean-up (David): the editor opens as it was last closed, and the arrow keys nudge the selection.
// `--window-nudge-only` runs these alone.
internal static class Release300EditChecks
{
    private const int W = 200, H = 120;
    public static void Run(string output, Action<bool, string> check)
    {
        Placement(output, check);
        Nudging(output, check);
        HelpWindowChecks(output, check);
    }

    // 3.0.0 (David): Help in TRT's own window on any PC, not in a browser.
    private static void HelpWindowChecks(string output, Action<bool, string> check)
    {
        var html = File.ReadAllText(HelpManual.ManualPath);
        var manual = new HelpDocument(HelpManual.ManualPath, false);
        var navLinks = System.Text.RegularExpressions.Regex.Matches(html[..html.IndexOf("</nav>", StringComparison.Ordinal)], "href=\"#([^\"]+)\"").Count;
        check(manual.Topics.Count == navLinks && navLinks > 20 && manual.Topics.All(t => manual.Targets.ContainsKey(t.Id)),
            $"the Help window lists every section of the manual ({manual.Topics.Count}), and each one is there to show");
        check(manual.Topics.Select(t => t.Group).Distinct().SequenceEqual(["Start here", "The editor", "Videos", "Saving", "Capturing the screen", "More"]), "the contents keep the manual's groups");
        var pictureTags = System.Text.RegularExpressions.Regex.Matches(html[html.IndexOf("<main>", StringComparison.Ordinal)..], "<img ").Count;
        check(manual.MissingPictures.Count == 0 && manual.Pictures == pictureTags, $"every picture and icon in the manual is shown ({manual.Pictures} of {pictureTags}; missing {string.Join(", ", manual.MissingPictures)})");
        var text = new TextRange(manual.Document.ContentStart, manual.Document.ContentEnd).Text;
        check(text.Contains("TinyRedactionTool (TRT for short) hides private details") && text.Contains("Before you share, look at the exported file.") && text.Contains("How do I open this manual again?"),
            "the manual's text is all there, from the first section to the last question");
        // (Icons are left out of this text, so the spaces either side of an icon meet here; that is expected.)
        check(!text.Contains('<') && !text.Contains('>') && !text.Contains("&amp;") && !text.Contains("&nbsp;") && !text.Contains("onerror"), "no tags or codes show in the text");
        check(manual.Links.Count >= 2 && manual.Links.All(l => manual.Targets.ContainsKey((string)l.Tag)), "links inside the manual go to their sections");
        var tables = manual.Document.Blocks.OfType<Table>().ToList();
        var boxes = manual.Document.Blocks.OfType<Section>().ToList();
        check(tables.Count >= 12 && boxes.Count == System.Text.RegularExpressions.Regex.Matches(html, "class=\"box ").Count && manual.Document.Blocks.OfType<List>().Any(l => l.MarkerStyle == TextMarkerStyle.Decimal),
            $"tables, numbered steps and the tip, warning and stop boxes are laid out ({tables.Count} tables, {boxes.Count} boxes)");
        var sources = Path.GetFullPath(Path.Combine(output, "..", "Desktop"));
        var helpCode = string.Concat(new[] { "HelpManual.cs", "HelpWindow.cs", "HelpDocument.cs" }.Select(f => File.ReadAllText(Path.Combine(sources, f))));
        check(!helpCode.Contains("Process.Start") && !helpCode.Contains("msedge") && !helpCode.Contains("ShellExecute"), "Help never starts a browser or any other program");

        var light = new HelpDocument(HelpManual.ManualPath, false); var dark = new HelpDocument(HelpManual.ManualPath, true);
        check(((SolidColorBrush)light.Document.Background).Color == Color.FromRgb(0xFF, 0xFF, 0xFF) && ((SolidColorBrush)dark.Document.Background).Color == Color.FromRgb(0x2B, 0x2B, 0x2B) &&
              ((SolidColorBrush)dark.Document.Foreground).Color == Color.FromRgb(0xF0, 0xF0, 0xF0), "the manual is light or dark like TRT");

        var saved = MainWindow.DarkTheme;
        var window = HelpWindow.Open(null, false);
        try
        {
            window.Left = -20000; window.Top = 0; window.ShowInTaskbar = false; window.ShowActivated = false; window.WindowStartupLocation = WindowStartupLocation.Manual;
            window.Show(); window.UpdateLayout();
            check(HelpWindow.Open(null, false) == window, "Help opens one window; asking again brings the same one forward");
            check(window.Title == "TinyRedactionTool Help" && window.Icon != null && window.Viewer.Document == window.Manual.Document, "the Help window has its title, its icon and the manual");
            var items = window.Contents.Items.OfType<ListBoxItem>().Where(i => i.Tag is string).ToList();
            check(items.Count == manual.Topics.Count, "the contents list on the left has every section");
            var scroller = window.Scroller();
            var keys = items.First(i => (string)i.Tag == "keys");
            keys.IsSelected = true; window.UpdateLayout();
            var heading = window.Manual.Targets["keys"];
            var where = heading.ContentStart.GetCharacterRect(LogicalDirection.Forward);
            check(scroller != null && scroller.VerticalOffset > 1000 && where.Top >= -2 && where.Top < 80, $"clicking a section in the contents shows it at the top (offset {scroller?.VerticalOffset:0}, heading at {where.Top:0})");
            items.First().IsSelected = true; window.UpdateLayout();
            check(scroller!.VerticalOffset < 40, "and the first section goes back to the top");
            window.Manual.Links.First(l => (string)l.Tag == "settings").DoClick(); window.UpdateLayout();
            check(items.First(i => (string)i.Tag == "settings").IsSelected && window.Manual.Targets["settings"].ContentStart.GetCharacterRect(LogicalDirection.Forward).Top is >= -2 and < 80,
                "a link in the text goes to its section and marks it in the contents");
            var wasDark = window.Manual.Document.Background is SolidColorBrush { Color.R: < 0x80 };
            typeof(MainWindow).GetMethod("ApplyThemeResources", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public)!.Invoke(null, [wasDark ? "Light" : "Dark"]);
            for (var i = 0; i < 5; i++) window.Dispatcher.Invoke(() => { }, System.Windows.Threading.DispatcherPriority.Background);
            window.UpdateLayout();
            var nowDark = window.Manual.Document.Background is SolidColorBrush { Color.R: < 0x80 };
            check(nowDark != wasDark && items.Count == window.Contents.Items.OfType<ListBoxItem>().Count(i => i.Tag is string), "when TRT's theme changes, the open Help window follows");
            void Shot(string name)
            {
                window.UpdateLayout();
                var shot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(window);
                var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot)); using var file = File.Create(Path.Combine(output, name)); png.Save(file);
            }
            Shot("help-window.png");
            window.ShowTopic("what"); Shot("help-window-start.png");
            window.ShowTopic("editor"); Shot("help-window-editor.png");
            window.Close();
            check(HelpWindow.Current == null, "closing it lets the next Help open fresh");
        }
        finally
        {
            if (window.IsVisible) window.Close();
            typeof(MainWindow).GetMethod("ApplyThemeResources", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public)!.Invoke(null, [saved ? "Dark" : "Light"]);
        }
    }

    private static void Placement(string output, Action<bool, string> check)
    {
        check(MainWindow.ParsePlacement(MainWindow.PlacementText(100, 80, 1100, 780, false)) == (100, 80, 1100, 780, false) &&
              MainWindow.ParsePlacement("-1500,20,-300,900,Maximized") == (-1500, 20, -300, 900, true), "the editor's window place is kept as text and read back (other monitors included)");
        check(MainWindow.ParsePlacement(null) == null && MainWindow.ParsePlacement("rubbish") == null && MainWindow.ParsePlacement("0,0,50,50,Normal") == null && MainWindow.ParsePlacement("0,0,900,700,Sideways") == null,
            "a missing, damaged or unusably small place is ignored (the editor then opens maximised, as before)");
        var fresh = new MainWindow(new()) { ShowInTaskbar = false, ShowActivated = false };
        check(fresh.WindowState == WindowState.Maximized, "with nothing remembered, the editor still opens maximised");
        fresh.Close();

        // A real window: opened windowed at a remembered place on the main screen, then reported back as it closes.
        // Windows' window places count from the main screen's working area, so this is always on the main screen.
        int left = 40, top = 30, right = left + 1000, bottom = top + 700;
        var window = new MainWindow(new()) { ShowInTaskbar = false, ShowActivated = false };
        window.UsePlacement(MainWindow.PlacementText(left, top, right, bottom, false));
        check(window.WindowState == WindowState.Normal, "a window closed windowed opens windowed");
        window.Show(); window.UpdateLayout();
        var shown = window.CurrentPlacement();
        check(shown == MainWindow.PlacementText(left, top, right, bottom, false), $"it opens at the same size and place ({shown})");
        window.WindowState = WindowState.Minimized;
        check(window.CurrentPlacement() == MainWindow.PlacementText(left, top, right, bottom, false), "closed while minimised, it is remembered as it was before (windowed), never minimised");
        window.WindowState = WindowState.Normal; window.SetFullScreen(true);
        var full = window.CurrentPlacement();
        check(full == MainWindow.PlacementText(left, top, right, bottom, false), $"closed in F11 full screen, it is remembered as it was before full screen ({full})");
        window.SetFullScreen(false);
        window.WindowState = WindowState.Maximized; window.WindowState = WindowState.Minimized;
        check(window.CurrentPlacement() == MainWindow.PlacementText(left, top, right, bottom, true), "minimised from maximised, it is remembered maximised");
        window.Close();
        // A place on a monitor that is no longer connected: Windows brings the window onto a screen that is.
        var lost = new MainWindow(new()) { ShowInTaskbar = false, ShowActivated = false };
        lost.UsePlacement(MainWindow.PlacementText(-60000, -60000, -59000, -59300, false));
        lost.Show(); lost.UpdateLayout();
        var back = MainWindow.ParsePlacement(lost.CurrentPlacement());
        var virtualScreen = new Rect(SystemParameters.VirtualScreenLeft, SystemParameters.VirtualScreenTop, SystemParameters.VirtualScreenWidth, SystemParameters.VirtualScreenHeight);
        check(back is { Left: > -60000 } && virtualScreen.IntersectsWith(new Rect(lost.Left, lost.Top, lost.ActualWidth, lost.ActualHeight)),
            $"a window last left on a monitor that is gone opens on a screen that is there ({lost.Left:0},{lost.Top:0})");
        lost.Close();

        // Through the capture controller, as the real app opens its editor: saved when it closes, used when it opens.
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "placement-settings.json");
        try
        {
            var temp = Path.Combine(output, "placement-temp"); Directory.CreateDirectory(temp);
            using var controller = new CaptureController(new ManagedPolicy(), false, temp);
            controller.Settings.EditorPlacement = MainWindow.PlacementText(left, top, right, bottom, false);
            var editor = new MainWindow(controller.Policy) { ShowInTaskbar = false, ShowActivated = false };
            controller.RememberPlacement(editor);
            editor.Show(); editor.UpdateLayout();
            editor.WindowState = WindowState.Maximized;
            editor.Close();
            check(controller.Settings.EditorPlacement == MainWindow.PlacementText(left, top, right, bottom, true) && File.ReadAllText(AppSettings.Path).Contains("\"EditorPlacement\""),
                "closing the editor remembers how it was (here maximised, over the same restored place) in the settings file");
        }
        finally { AppSettings.Path = savedPath; }
        var exported = new AppSettings { EditorPlacement = "1,2,903,704,Normal" };
        var settings = new SettingsWindow(exported) { Left = -20000, ShowInTaskbar = false, ShowActivated = false };
        var exportFile = Path.Combine(output, "placement-export.json");
        var savedAnswer = ThemedMessage.Answer; ThemedMessage.Answer = (_, _, _) => MessageBoxResult.OK; // No "Settings exported" box on screen.
        try { settings.ExportSettingsTo(exportFile); } finally { ThemedMessage.Answer = savedAnswer; }
        check(!File.ReadAllText(exportFile).Contains("EditorPlacement"), "an exported settings file leaves out this PC's window place");
        settings.Close();
    }

    private static void Nudging(string output, Action<bool, string> check)
    {
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ShowActivated = false, ConfirmKeepQuestion = (_, _, _) => true };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        try
        {
            var refresh = typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!;
            var undo = typeof(MainWindow).GetMethod("Undo", BindingFlags.Instance | BindingFlags.NonPublic)!;
            var white = BitmapSource.Create(W, H, 96, 96, PixelFormats.Bgra32, null, Enumerable.Repeat((byte)255, W * H * 4).ToArray(), W * 4);
            preview.Image = white;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "nudge.png"), 1, new string('0', 64), W, H, 0, false) };
            refresh.Invoke(window, null);
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / W, preview.ActualHeight / H);
            Point At(double x, double y) => new((preview.ActualWidth - W * scale) / 2 + x * scale, (preview.ActualHeight - H * scale) / 2 + y * scale);
            void Drag(Point a, Point b) { preview.PointerDown(a, MouseButton.Left); preview.PointerMove(b); preview.PointerUp(); }
            void Tool(string name) => ((Button)window.FindName(name)).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            bool Key(Key key, bool repeat = false, IInputElement? from = null)
            {
                var args = new KeyEventArgs(Keyboard.PrimaryDevice, PresentationSource.FromVisual(window)!, 0, key) { RoutedEvent = Keyboard.PreviewKeyDownEvent };
                if (repeat) typeof(KeyEventArgs).GetMethod("SetRepeat", BindingFlags.Instance | BindingFlags.NonPublic)?.Invoke(args, [true]);
                (from ?? window).RaiseEvent(args); return args.Handled;
            }
            MediaRect Box(Region r) => r.GeometryAt(0);

            Tool("RectangleTool"); Drag(At(50, 40), At(90, 70));
            var region = preview.Project.Regions.Single();
            preview.Selected = region; var start = Box(region);
            check(Key(System.Windows.Input.Key.Right) && Box(region).X == start.X + 1 && Box(region).Y == start.Y, "Right nudges the selected redaction 1 pixel right");
            Key(System.Windows.Input.Key.Down); Key(System.Windows.Input.Key.Down);
            check(Box(region).Y == start.Y + 2, "Down nudges it down");
            Key(System.Windows.Input.Key.Left); Key(System.Windows.Input.Key.Up);
            check(Box(region).X == start.X && Box(region).Y == start.Y + 1 && Box(region).Width == start.Width && Box(region).Height == start.Height, "Left and Up nudge it back, and its size never changes");
            preview.Nudge(10, 0, true);
            check(Box(region).X == start.X + 10, "Shift with an arrow nudges 10 pixels");
            undo.Invoke(window, [window, new RoutedEventArgs()]);
            region = preview.Project.Regions.Single();
            check(Box(region).X == start.X && Box(region).Y == start.Y + 1, "Undo takes back one nudge");
            preview.Selected = region;
            Key(System.Windows.Input.Key.Right); Key(System.Windows.Input.Key.Right, true); Key(System.Windows.Input.Key.Right, true);
            check(Box(region).X == start.X + 3, "holding an arrow down keeps nudging");
            undo.Invoke(window, [window, new RoutedEventArgs()]);
            region = preview.Project.Regions.Single();
            check(Box(region).X == start.X, "one Undo takes back a whole held press");
            preview.Selected = region;
            preview.Nudge(-1000, -1000, true);
            check(Box(region).X == 0 && Box(region).Y == 0, "a nudge stops at the picture's edge");
            check(Key(System.Windows.Input.Key.Left) && Box(region).X == 0, "at the edge the arrow is still used, and the shape stays inside");

            Tool("LineTool"); Drag(At(120, 20), At(160, 50));
            var line = preview.Project.Annotations.Single(); var points = line.Points.ToArray();
            check(preview.SelectedAnnotation == line && Key(System.Windows.Input.Key.Down) && line.Points[0].Y == points[0].Y + 1 && line.Points[1].Y == points[1].Y + 1, "an annotation (a line) nudges too");
            Tool("SelectToolButton");
            region = preview.Project.Regions.Single();
            preview.SelectShapes([region], [line]); var regionBefore = Box(region); var lineBefore = line.Points[0];
            Key(System.Windows.Input.Key.Right);
            check(Box(region).X == regionBefore.X + 1 && line.Points[0].X == lineBefore.X + 1, "several selected shapes nudge together");

            preview.ClearMultiSelection(); preview.Selected = null; preview.SelectAnnotation(null);
            var stepped = Key(System.Windows.Input.Key.Up);
            check(!stepped && Box(region).X == regionBefore.X + 1, "with nothing selected, the arrows nudge nothing (Left and Right still go to the folder's other pictures)");
            preview.Selected = region; var list = (ListBox)window.FindName("AnnotationsList");
            var before = Box(region);
            Key(System.Windows.Input.Key.Down, false, list);
            check(Box(region) == before, "a list in the side panel keeps its arrow keys");
        }
        finally { window.Close(); }
    }
}
