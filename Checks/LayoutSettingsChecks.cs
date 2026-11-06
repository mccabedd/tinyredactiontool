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

// 0.10.0: David's 0.9.2 feedback (bottom row, top-right info, notices, panel closed, Export reason,
// Review in the popup, Line/Polyline window) and the Settings window.
internal static class LayoutSettingsChecks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    public static void Run(string output, Action<bool, string> check)
    {
        var savedPath = AppSettings.Path;
        AppSettings.Path = Path.Combine(output, "settings-check.json");
        if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        const int width = 200, height = 100;
        var pixels = new byte[width * height * 4]; Array.Fill(pixels, (byte)235);
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze();
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show(); window.Activate();
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        Point In(FrameworkElement e) => e.TranslatePoint(new Point(0, 0), window);
        try
        {
            window.UpdateLayout();
            // Panel closed on opening; the Panel button still opens it.
            check(Find<Border>("PropertiesPanel").Visibility == Visibility.Collapsed && Find<ColumnDefinition>("PropertiesColumn").Width.Value == 0, "the side panel is closed when the application opens");
            window.ToggleProperties(window, new RoutedEventArgs()); window.UpdateLayout();
            check(Find<Border>("PropertiesPanel").IsVisible, "the Panel button opens the side panel");
            window.ToggleProperties(window, new RoutedEventArgs()); window.UpdateLayout();

            // No status line; Size, Zoom and Theme sit at the right of the menu row.
            var menu = Find<Menu>("MainMenu"); var toolStrip = Find<Border>("ToolStrip");
            check(!Find<TextBlock>("Status").IsVisible, "the bottom status line with tool instructions is gone");
            foreach (var name in new[] { "SizeText", "ZoomText" })
            {
                var e = Find<FrameworkElement>(name); var p = In(e);
                check(e.IsVisible && p.Y < In(toolStrip).Y && p.X > In(menu).X + window.ActualWidth / 2, $"{name} is at the top right, beside the menu");
            }
            // 0.22.0 (David): Settings moved from File to the About menu.
            check(menu.Items.OfType<MenuItem>().Last().Items.OfType<MenuItem>().Any(m => ((string)m.Header).Replace("_", "") == "Settings…"), "the About menu has Settings…");

            // Bottom row: time/frame left, transport centred, Clear Editor right (0.14.0; was Cancel work).
            var clock = Find<TextBlock>("ClockText"); var back = Find<Button>("PreviousFrameButton"); var play = Find<Button>("PlayButton"); var forward = Find<Button>("NextFrameButton");
            // Laid out as a video shows it (0.17.0: pictures and an empty editor hide the time and transport).
            clock.Visibility = Find<FrameworkElement>("TransportControls").Visibility = Find<FrameworkElement>("PlaybackBar").Visibility = Visibility.Visible; window.UpdateLayout();
            var row = Find<Grid>("TransportRow"); var rowLeft = In(row).X; var playCentre = In(play).X + play.ActualWidth / 2;
            check(In(clock).X - rowLeft < 20 && In(clock).X + clock.ActualWidth < In(back).X, "time and frame number are at the left of the bottom row");
            check(In(back).X < In(play).X && In(play).X < In(forward).X && Math.Abs(playCentre - (rowLeft + row.ActualWidth / 2)) < 90, "back, play/pause and forward are centred");
            Find<FrameworkElement>("PlaybackBar").Visibility = Visibility.Collapsed;

            // Load a still image for the editing checks.
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "layout.png"), 1, new string('0', 64), width, height, 0, false) };
            typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null);
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / width, preview.ActualHeight / height);
            Point At(double x, double y) => new((preview.ActualWidth - width * scale) / 2 + x * scale, (preview.ActualHeight - height * scale) / 2 + y * scale);
            void Press(Point p) { preview.MouseDownAt(p, MouseButton.Left, 1); preview.PointerUp(); Pump(); }
            void Drag(Point from, Point to) { preview.MouseDownAt(from, MouseButton.Left, 1); preview.PointerMove(to); preview.PointerUp(); Pump(); window.UpdateLayout(); }
            void Tool(string name) { Find<Button>(name).RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump(); }
            void RefreshWindow() { typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null); window.UpdateLayout(); }

            // Notices: choosing a tool stays quiet; a result shows briefly over the picture.
            var notice = Find<Border>("NoticeBar");
            Tool("RectangleTool");
            check(notice.Visibility != Visibility.Visible, "choosing a tool shows no notice (tooltips explain tools)");
            Find<TextBlock>("Status").Text = "Project saved. Media is referenced, not embedded.";
            check(notice.Visibility == Visibility.Visible && Find<TextBlock>("NoticeText").Text.StartsWith("Project saved"), "a result message shows as a short notice");

            // Export explains itself when unavailable.
            var export = Find<Button>("ExportButton");
            check(!export.IsEnabled && ToolTipService.GetShowOnDisabled(export) && ((string)export.ToolTip).Contains("draw a redaction"), "greyed Export says what is missing (nothing drawn yet)");
            var region = new Region { Name = "Face", Start = 0, End = 1 }; region.PutManual(0, new(120, 50, 50, 30));
            region.Tracking = [new(0, .5, ReviewState.Unreviewed, "tracked"), new(.5, 1, ReviewState.Lost, "lost")];
            preview.Project.Regions.Add(region); RefreshWindow();
            // 0.14.0 (David): no Review step; followed ranges do not hold up Export.
            check(export.IsEnabled && (string)export.ToolTip == "Export with Redactions (Checked After Saving)", "with followed ranges, Export is available straight away (no Review step)");
            preview.Selected = region; RefreshWindow();
            check(Find<Border>("RegionPopup").IsVisible && window.FindName("PopupReview") == null, "the redaction popup has no Review button");
            check(!Find<Button>("PopupFollow").IsVisible && (string)Find<Button>("PopupRedact").Content == "Redact", "on a still image the popup keeps a single Redact button");
            preview.Selected = null; preview.Project.Regions.Clear(); RefreshWindow();

            // Line / Polyline window.
            var linePopup = Find<Border>("LinePopup");
            Tool("LineTool"); Drag(At(20, 20), At(80, 50));
            var line = preview.Project.Annotations.Single();
            var lineBottom = preview.ScreenRect(line.Bounds()).Bottom;
            check(linePopup.IsVisible && Find<TextBlock>("LinePopupTitle").Text == "Line" && Canvas.GetTop(linePopup) > lineBottom, "a new line opens the Line window just below it");
            check(!Find<ComboBox>("LinePopupJoin").IsVisible, "the Line window has no Joins choice (a line has no corners)");
            Find<NumberSpinner>("LinePopupWidth").Value = 8; Pump();
            Find<ComboBox>("LinePopupEnds").SelectedIndex = 3; Pump();
            check(line.Width == 8 && line.Ends == AnnotationEnds.ArrowBoth, "the Line window changes the line's width and arrowheads");
            typeof(MainWindow).GetMethod("Undo", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]); Pump(); window.UpdateLayout();
            check(preview.Project.Annotations.Single() is { Width: 8 } undone && undone.Ends != AnnotationEnds.ArrowBoth && linePopup.IsVisible, "Undo reverses a Line window change and the window stays with the line");
            Find<Button>("LinePopupClose").RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump(); window.UpdateLayout();
            check(preview.SelectedAnnotation == null && !linePopup.IsVisible, "the Line window's ✕ closes it and keeps the line");
            Tool("PolylineTool");
            preview.MouseDownAt(At(20, 70), MouseButton.Left, 1); preview.PointerMove(At(60, 70)); preview.PointerMove(At(60, 95)); preview.PointerUp(); Pump(); window.UpdateLayout();
            var polyline = preview.Project.Annotations.SingleOrDefault(a => a.Kind == AnnotationKind.Polyline);
            check(polyline != null && linePopup.IsVisible && Find<TextBlock>("LinePopupTitle").Text == "Polyline" && Find<ComboBox>("LinePopupJoin").IsVisible, "a new polyline opens the Polyline window with Joins");
            Find<Button>("LinePopupDelete").RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump(); window.UpdateLayout();
            check(polyline != null && !preview.Project.Annotations.Contains(polyline) && !linePopup.IsVisible, "the window's delete button removes the polyline");
            Tool("SelectToolButton"); Press(At(50, 35)); window.UpdateLayout();
            check(preview.SelectedAnnotation != null && linePopup.IsVisible, "clicking an existing line selects it and shows its window");
            Press(At(190, 95)); window.UpdateLayout();
            check(!linePopup.IsVisible, "clicking elsewhere closes the Line window");

            // Polygon corners (BASE-007): a handle on each corner; dragging one reshapes the polygon.
            preview.Project.Annotations.Clear(); preview.SelectAnnotation(null);
            Tool("PolygonTool");
            Press(At(120, 20)); Press(At(180, 20)); Press(At(150, 80)); Press(At(120, 20) + new Vector(1, 1));
            var polygon = preview.Project.Regions.Single(r => r.Shape == RegionShape.Polygon);
            MediaPoint Corner(int i) { var b = polygon.GeometryAt(0); return new(b.X + polygon.Polygon[i].X * b.Width, b.Y + polygon.Polygon[i].Y * b.Height); }
            bool Near(MediaPoint p, double x, double y) => Math.Abs(p.X - x) < 1 && Math.Abs(p.Y - y) < 1;
            Press(At(20, 90)); Press(At(150, 40)); window.UpdateLayout();
            var handles = (System.Collections.IDictionary)typeof(PreviewSurface).GetMethod("RegionHandles", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(preview, [polygon])!;
            // 0.21.0: plus the four (undrawn) turning zones outside the corners of its box.
            check(preview.Selected == polygon && handles.Count == 7 && handles.Keys.Cast<string>().Count(k => k.StartsWith('V')) == 3 && handles.Keys.Cast<string>().Count(k => k.StartsWith('R')) == 4,
                "a selected polygon shows a handle on each corner (and the turning zones), not the eight box handles");
            Drag(At(180, 20), At(190, 45));
            check(Near(Corner(1), 190, 45) && Near(Corner(0), 120, 20) && Near(Corner(2), 150, 80) && polygon.Polygon.Count == 3, $"dragging one corner moves only that corner (corners {Corner(0)}, {Corner(1)}, {Corner(2)})");
            Drag(At(150, 40), At(140, 40));
            check(Near(Corner(1), 180, 45) && Near(Corner(0), 110, 20), "dragging inside the polygon still moves the whole shape");
            typeof(MainWindow).GetMethod("Undo", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]); Pump();
            typeof(MainWindow).GetMethod("Undo", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]); Pump();
            polygon = preview.Project.Regions.Single(r => r.Shape == RegionShape.Polygon);
            check(Near(Corner(1), 180, 20), "Undo restores the corner");
            preview.Project.Regions.Clear(); preview.Selected = null; RefreshWindow();

            // Settings: shortcuts.
            check(AppSettings.ParseShortcut(AppSettings.DefaultScreenshotShortcut) is { Modifiers: ModifierKeys.Control, Key: Key.Snapshot } &&
                  AppSettings.ParseShortcut(AppSettings.DefaultRecordingShortcut) is { Modifiers: ModifierKeys.Control | ModifierKeys.Shift, Key: Key.Snapshot },
                "default shortcuts are Ctrl+Print Screen (screenshot) and Ctrl+Shift+Print Screen (recording)");
            check(AppSettings.ParseShortcut("A") == null && AppSettings.ParseShortcut("Shift+A") == null && AppSettings.ParseShortcut("Ctrl+Shift") == null && AppSettings.ParseShortcut("Ctrl+Nonsense") == null && AppSettings.ParseShortcut("F9") != null,
                "shortcuts need Ctrl or Alt (Print Screen and F-keys may stand alone); bad text is refused");
            var dialog = new SettingsWindow(new AppSettings());
            var shot = (TextBox)dialog.FindName("ScreenshotBox"); var rec = (TextBox)dialog.FindName("RecordingBox");
            check(shot.Text == "Ctrl+Print Screen" && rec.Text == "Ctrl+Shift+Print Screen", "Settings shows the default shortcuts in plain words");
            check(!dialog.TryShortcut(shot, ModifierKeys.Control | ModifierKeys.Shift, Key.Snapshot) && shot.Text == "Ctrl+Print Screen", "Settings refuses a shortcut already used by the other action");
            check(!dialog.TryShortcut(shot, ModifierKeys.None, Key.S), "Settings refuses a single letter as a shortcut");
            check(dialog.TryShortcut(shot, ModifierKeys.Control | ModifierKeys.Alt, Key.S) && shot.Text == "Ctrl+Alt+S", "Settings takes a new screenshot shortcut");
            ((CheckBox)dialog.FindName("SmallIconsBox")).IsChecked = true; ((RadioButton)dialog.FindName("VerticalBox")).IsChecked = true;
            var chosen = dialog.Collect(); dialog.Close();
            check(chosen.Save() && AppSettings.Load() is { SmallIcons: true, VerticalToolbar: true, ScreenshotShortcut: "Ctrl+Alt+S", RecordingShortcut: "Ctrl+Shift+PrintScreen" }, "settings are saved and read back");
            File.WriteAllText(AppSettings.Path, "{ not json");
            check(AppSettings.Load() is { SmallIcons: false, VerticalToolbar: false, ScreenshotShortcut: "Ctrl+PrintScreen" }, "an unreadable settings file falls back to the defaults");

            // Settings: small icons and vertical toolbar.
            var buttons = Find<WrapPanel>("ToolButtons").Children.OfType<Button>().Where(b => b.Visibility == Visibility.Visible).ToArray(); // Original shows only for captures (0.12.0).
            var largeHeight = buttons[0].ActualHeight;
            window.ApplySettings(new AppSettings { SmallIcons = true }); window.UpdateLayout();
            check(buttons.All(b => b.ActualHeight < largeHeight - 6 && !Descendants(b).OfType<ContentPresenter>().Any()) && buttons.All(b => b.ToolTip != null),
                "Small icons: smaller toolbar icons without captions (tooltips remain)");
            window.ApplySettings(new AppSettings { VerticalToolbar = true }); window.UpdateLayout();
            check(DockPanel.GetDock(toolStrip) == Dock.Left && buttons.All(b => b.IsVisible && In(b).X + b.ActualWidth <= In(preview).X + 1) && In(buttons[1]).Y > In(buttons[0]).Y,
                "Vertical toolbar: buttons in a column on the left of the picture");
            window.ApplySettings(new AppSettings { VerticalToolbar = true, SmallIcons = true }); window.UpdateLayout();
            check(buttons.All(b => b.IsVisible && In(b).X + b.ActualWidth <= In(preview).X + 1), "Vertical toolbar with small icons: all buttons left of the picture");
            window.ApplySettings(new AppSettings()); window.UpdateLayout();
            check(DockPanel.GetDock(toolStrip) == Dock.Top && Math.Abs(buttons[0].ActualHeight - largeHeight) < .5 && In(buttons[1]).Y == In(buttons[0]).Y, "default settings restore the horizontal toolbar with captions");
        }
        finally
        {
            AppSettings.Path = savedPath;
            preview.Project = new(); preview.Selected = null; preview.SelectAnnotation(null); window.Close();
        }
    }
    private static IEnumerable<DependencyObject> Descendants(DependencyObject parent)
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        { var child = VisualTreeHelper.GetChild(parent, i); yield return child; foreach (var nested in Descendants(child)) yield return nested; }
    }
}
