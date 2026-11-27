using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 3.5.0 (David): the unsaved screenshot questions (one sentence per line; [Cancel] at the left, [No] [Yes] at the right,
// Yes the default), and tabs: each screenshot, recording or opened file in a tab of its own, a dashed box round an area
// copied with Copy and pasted into another tab, File › Save All Tabs and Close All Tabs. Throw-away folders only.
// `--release-350-only` runs these.
internal static class Release350Checks
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(3);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("3.5.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static void Pump() { var frame = new DispatcherFrame(); Dispatcher.CurrentDispatcher.BeginInvoke(DispatcherPriority.Background, () => frame.Continue = false); Dispatcher.PushFrame(frame); }
    private static IEnumerable<T> Descendants<T>(DependencyObject root) where T : DependencyObject
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(root); i++)
        {
            var child = VisualTreeHelper.GetChild(root, i);
            if (child is T found) yield return found;
            foreach (var deeper in Descendants<T>(child)) yield return deeper;
        }
    }
    // A picture: the left half one colour, the right half another.
    private static BitmapSource Halves(int width, int height, Color left, Color right)
    {
        var pixels = new byte[width * height * 4];
        for (var y = 0; y < height; y++)
            for (var x = 0; x < width; x++)
            {
                var c = x < width / 2 ? left : right; var o = (y * width + x) * 4;
                pixels[o] = c.B; pixels[o + 1] = c.G; pixels[o + 2] = c.R; pixels[o + 3] = 255;
            }
        var bitmap = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); bitmap.Freeze(); return bitmap;
    }
    private static Color At(BitmapSource picture, int x, int y)
    {
        var converted = new FormatConvertedBitmap(picture, PixelFormats.Bgra32, null, 0); var p = new byte[4];
        converted.CopyPixels(new Int32Rect(x, y, 1, 1), p, 4, 0); return Color.FromRgb(p[2], p[1], p[0]);
    }

    public static void Run(string output, Action<bool, string> check)
    {
        Dialogs(check);
        var folder = Path.Combine(output, "release350"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        var temp = Path.Combine(output, "release350-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release350-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var asked = new List<(string Text, string Title)>(); var answers = new Queue<MessageBoxResult>(); Exception? failed = null;
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy)
        {
            WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ShowActivated = false,
            ConfirmKeepQuestion = (_, _, _) => true, WorkFailed = e => failed = e,
            // The screenshot questions take the queued answers; "Discard your unsaved changes?" (edits after Save As) is Yes.
            UnsavedQuestion = (_, text, title) => { if (title != "Unsaved Screenshot") return MessageBoxResult.Yes; asked.Add((text, title)); return answers.Count > 0 ? answers.Dequeue() : MessageBoxResult.Yes; },
        };
        string Shot(BitmapSource picture, MediaOriginKind kind = MediaOriginKind.Screenshot)
        { var path = controller.Store.NewFile("CAPTURE", ".png", new MediaOrigin(kind, DateTime.Now)); CaptureController.WritePng(picture, path); return path; }
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            controller.Settings.Output = CaptureOutput.Editor;
            var red = Colors.Red; var blue = Color.FromRgb(0, 0, 255); var green = Color.FromRgb(0, 160, 0);

            // ---- The unsaved screenshot questions, from the editor ----
            var first = controller.OpenEditor();
            check(Wait(() => first.OpenCaptureAsync(Shot(Halves(200, 100, red, blue)))), "a screenshot opens in the first tab");
            asked.Clear(); answers.Enqueue(MessageBoxResult.No);
            check(first.AskDiscard() == MessageBoxResult.No && asked is [{ Text: "This screenshot has not been saved.\nAny changes will be lost.\nContinue?", Title: "Unsaved Screenshot" }],
                $"closing an unsaved screenshot asks, one sentence per line: This screenshot has not been saved. / Any changes will be lost. / Continue? ({asked.FirstOrDefault().Text})");
            asked.Clear(); answers.Enqueue(MessageBoxResult.Cancel);
            var second = Shot(Halves(120, 80, blue, blue));
            check(!Wait(() => first.OpenCaptureAsync(second)) && controller.Tabs.Count == 1 && first.ShownMediaPath != second
                  && asked is [{ Text: "Discard and open the new screenshot instead?\nThe current screenshot has not been saved.\nAny changes will be lost.", Title: "Unsaved Screenshot" }],
                $"a new screenshot over an unsaved one asks: Discard and open the new screenshot instead? / The current screenshot has not been saved. / Any changes will be lost. Cancel keeps it ({asked.FirstOrDefault().Text})");
            asked.Clear(); answers.Enqueue(MessageBoxResult.No);
            check(Wait(() => first.OpenCaptureAsync(second)) && controller.Tabs.Count == 2 && controller.Editor != first && controller.Editor!.ShownMediaPath == second
                  && first.ShownMediaPath != null && first.ShownMediaPath != second && !first.IsVisible && controller.Editor.IsVisible,
                "No keeps the current screenshot and opens the new one in a tab of its own (shown; the first tab is kept, out of view)");

            // ---- New screenshots and opened files get their own tab ----
            var tabsBefore = controller.Tabs.Count;
            Wait(async () => { await controller.DeliverAsync(Halves(160, 90, green, green)); return true; });
            check(controller.Tabs.Count == tabsBefore + 1 && controller.Editor!.TabTitle.StartsWith("Screenshot ") && asked.Count == 1,
                $"a new screenshot opens in a new tab without asking ({controller.Editor?.TabTitle})");
            var greenFile = Path.Combine(folder, "green.png"); CaptureController.WritePng(Halves(200, 100, green, green), greenFile);
            Wait(async () => { await controller.OpenPathInEditorAsync(greenFile); return true; });
            var opened = controller.Editor!;
            check(controller.Tabs.Count == tabsBefore + 2 && opened.TabTitle == "green.png" && opened.ShownMediaPath == Path.GetFullPath(greenFile),
                $"a file opened from File Explorer goes to a new tab, named after the file ({opened.TabTitle})");
            var empty = controller.NewEmptyTab(opened);
            check(controller.Tabs.Count == tabsBefore + 3 && controller.Editor == empty && empty.IsEmptyTab && empty.TabTitle == "New Tab", "Ctrl+T (or +) adds an empty New Tab and shows it");
            Wait(async () => { await controller.OpenPathInEditorAsync(greenFile); return true; });
            check(controller.Tabs.Count == tabsBefore + 3 && empty.ShownMediaPath == Path.GetFullPath(greenFile), "a file opened while an empty tab is shown goes into that tab");
            controller.CloseTab(empty);
            check(controller.Tabs.Count == tabsBefore + 2 && !controller.Tabs.Contains(empty) && controller.Editor is { IsVisible: true }, "closing a tab with nothing unsaved asks nothing and shows the tab beside it");
            empty = controller.NewEmptyTab(controller.Editor!);

            // ---- The tab bar ----
            empty.UpdateLayout(); Pump();
            var headers = ((WrapPanel)empty.FindName("TabHeaders")).Children.OfType<Border>().ToList();
            var names = headers.Select(h => Descendants<TextBlock>(h).First().Text).ToList();
            check(((Border)empty.FindName("TabBar")).Visibility == Visibility.Visible && names.SequenceEqual(controller.Tabs.Select(t => t.TabTitle))
                  && ((WrapPanel)empty.FindName("TabHeaders")).Children.OfType<Button>().Any(b => (string)b.Content == "+"),
                $"the tab bar names every tab in order and has a + for a new tab ({string.Join(" | ", names)})");
            controller.SelectTab(first);
            check(controller.Editor == first && first.IsVisible && controller.Tabs.Count(t => t.IsVisible) == 1, "clicking a tab shows it in place of the other (one tab in view)");
            controller.StepTab(first, -1);
            check(controller.Editor == controller.Tabs[^1], "Ctrl+Shift+Tab from the first tab goes round to the last");
            controller.StepTab(controller.Editor!, 1);
            check(controller.Editor == first, "Ctrl+Tab goes to the next tab");

            // ---- Select an area in tab 1, copy it, paste it into the empty tab ----
            var preview = (PreviewSurface)first.FindName("Preview");
            void Refresh(MainWindow w) { typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(w, null); w.UpdateLayout(); }
            Point On(PreviewSurface p, double x, double y) { var r = p.ScreenRect(new MediaRect(x, y, 0, 0)); return new(r.X, r.Y); }
            void Drag(MainWindow w, PreviewSurface p, double x0, double y0, double x1, double y1, string tool)
            {
                p.Selected = null; p.Tool = tool; p.Fit(); p.UpdateLayout(); Refresh(w);
                p.MouseDownAt(On(p, x0, y0), System.Windows.Input.MouseButton.Left, 1); p.PointerMove(On(p, (x0 + x1) / 2, (y0 + y1) / 2)); p.PointerMove(On(p, x1, y1)); p.PointerUp(); Refresh(w);
            }
            Drag(first, preview, 10, 10, 60, 50, "Select");
            check(preview.SelectedArea is { } area && Math.Abs(area.X - 10) <= 1 && Math.Abs(area.Width - 50) <= 2 && Math.Abs(area.Height - 40) <= 2,
                $"with Select, a dashed box round an empty part of the picture is kept as the selected area ({preview.SelectedArea})");
            check(Wait(() => first.CopyPictureAsync()), "Copy with an area selected works");
            var copied = Transparency.ClipboardPng() ?? Clipboard.GetImage();
            check(copied != null && Math.Abs(copied.PixelWidth - (int)preview.SelectedArea!.Value.Width) == 0 && Math.Abs(copied.PixelHeight - (int)preview.SelectedArea.Value.Height) == 0 && At(copied, 5, 5) == red,
                $"Copy puts just that area on the clipboard ({copied?.PixelWidth} × {copied?.PixelHeight}, red)");
            controller.SelectTab(empty);
            check(Wait(() => empty.PastePictureAsync()) && empty.ShownMediaPath != null && ((PreviewSurface)empty.FindName("Preview")).Project.Media is { Width: var w1 } && w1 == copied!.PixelWidth,
                "Paste in the empty tab makes the copied area its picture");

            // ---- Tab 2's area, with a redaction in it, pasted onto the same tab as an item ----
            controller.SelectTab(opened);
            var openedPreview = (PreviewSurface)opened.FindName("Preview");
            openedPreview.DrawingEffect = RedactionEffect.Opaque;
            Drag(opened, openedPreview, 30, 30, 70, 60, "Rectangle");
            check(openedPreview.Project.Regions.Count == 1, "a redaction is drawn in the opened file's tab");
            Drag(opened, openedPreview, 20, 20, 100, 80, "Select");
            check(openedPreview.SelectedArea is { Width: > 70 } && openedPreview.Selected != null,
                "a dashed box round the redaction keeps the area and selects the redaction it touches");
            check(Wait(() => opened.CopyPictureAsync()), "Copy in the second tab works");
            var second2 = Transparency.ClipboardPng() ?? Clipboard.GetImage();
            check(second2 != null && At(second2, 2, 2) == green && At(second2, 30, 25) != green,
                "the copied area has the picture and the redaction over it (it is copied as it would be saved)");
            controller.SelectTab(empty);
            var emptyPreview = (PreviewSurface)empty.FindName("Preview");
            check(Wait(() => empty.PastePictureAsync()) && emptyPreview.Project.Annotations is [{ Kind: AnnotationKind.Picture }] && emptyPreview.Project.Media!.Width == copied!.PixelWidth,
                "Paste in a tab that has a picture puts the copy onto it as an item to move and size (the first copy stays the picture)");
            emptyPreview.Tool = "Select"; emptyPreview.Fit(); emptyPreview.UpdateLayout();
            emptyPreview.MouseDownAt(On(emptyPreview, 1, 1), System.Windows.Input.MouseButton.Left, 1); emptyPreview.PointerUp();
            check(emptyPreview.SelectedArea == null, "a click lets go of a selected area");

            // ---- Save All Tabs ----
            var n = 0;
            foreach (var tab in controller.Tabs) tab.AnswerSaveAs = (_, name) => Path.Combine(folder, $"saved{++n}-{name}");
            var unsaved = controller.Tabs.Count(t => t.NeedsSave);
            var shownBefore = controller.Editor;
            var saved = Wait(() => controller.SaveAllTabsAsync());
            check(failed == null && saved == unsaved && unsaved >= 4 && controller.Tabs.All(t => !t.NeedsSave) && controller.Editor == shownBefore,
                $"Save All Tabs saves each tab with unsaved work in turn ({saved} of {unsaved}), then shows the tab it started from ({failed?.Message})");
            var shot = Shot(Halves(64, 64, red, red));
            Wait(async () => { await controller.OpenPathInEditorAsync(greenFile); return true; }); // Another tab, unchanged: nothing to save.
            var stopTab = controller.NewEmptyTab(controller.Editor!); Wait(() => stopTab.OpenCaptureAsync(shot)); stopTab.AnswerSaveAs = (_, _) => null;
            controller.SelectTab(first);
            check(Wait(() => controller.SaveAllTabsAsync()) == 0 && controller.Editor == stopTab && stopTab.NeedsSave,
                "Save All Tabs stops at a tab whose Save As is cancelled and shows it");

            // ---- Close All Tabs: No keeps a tab and goes on, Cancel stops ----
            asked.Clear(); answers.Clear(); answers.Enqueue(MessageBoxResult.Cancel);
            check(!controller.CloseAllTabs(keepEditorOpen: true) && asked.Count == 1 && controller.Tabs.Count == 1 && controller.Tabs[0] == stopTab && stopTab.IsVisible,
                $"Close All Tabs closes the saved tabs without asking; Cancel on the unsaved screenshot stops there, with it shown ({controller.Tabs.Count} left)");
            var keep = Shot(Halves(64, 64, blue, blue)); var keepTab = controller.NewEmptyTab(controller.Editor!); Wait(() => keepTab.OpenCaptureAsync(keep));
            asked.Clear(); answers.Enqueue(MessageBoxResult.No); answers.Enqueue(MessageBoxResult.Yes);
            check(!controller.CloseAllTabs(keepEditorOpen: true) && asked.Count == 2 && controller.Tabs.Count == 1 && controller.Tabs[0] == stopTab && stopTab.IsVisible,
                "No keeps that tab and goes on to the next (Yes closes it): only the kept tab is left, and shown");
            asked.Clear(); answers.Enqueue(MessageBoxResult.Yes);
            check(controller.CloseAllTabs(keepEditorOpen: true) && controller.Tabs.Count == 1 && controller.Editor is { IsEmptyTab: true, IsLoaded: true },
                "Yes to every question closes them all; the editor stays open with one empty tab");

            // ---- The window's own ✕ with several tabs closes them all ----
            var a = controller.Editor!; Wait(() => a.OpenCaptureAsync(Shot(Halves(50, 50, red, red))));
            var b = controller.NewEmptyTab(a); Wait(() => b.OpenCaptureAsync(Shot(Halves(50, 50, blue, blue))));
            var c = controller.NewEmptyTab(b);
            asked.Clear(); answers.Enqueue(MessageBoxResult.No); answers.Enqueue(MessageBoxResult.Yes);
            c.Close(); Pump();
            check(asked.Count == 2 && controller.Tabs.Count == 1 && controller.Tabs[0] == a && a.IsVisible && controller.Editor == a,
                $"closing the window asks about each unsaved tab; the one answered No stays open and is shown ({asked.Count} questions, {controller.Tabs.Count} left)");
            asked.Clear(); answers.Enqueue(MessageBoxResult.Yes);
            a.Close(); Pump();
            check(controller.Tabs.Count == 0 && controller.Editor == null, "closing the last tab's window closes the editor");

            // ---- File menu ----
            var menuEditor = controller.OpenEditor(); menuEditor.UpdateLayout();
            var file = ((Menu)menuEditor.FindName("MainMenu")).Items.OfType<MenuItem>().First(m => (m.Header as string)?.Replace("_", "") == "File");
            var order = file.Items.Cast<object>().Select(i => i is Separator ? "----" : ((MenuItem)i).Header is string h ? h.Replace("_", "") : "?").ToList();
            var at = order.IndexOf("File Info…");
            check(at >= 0 && order.Skip(at).Take(6).SequenceEqual(["File Info…", "----", "Save All Tabs", "Close All Tabs", "----", "Save or Copy the Original Capture…"]),
                $"File menu: File Info, then Save All Tabs and Close All Tabs between separators, then Save or Copy the Original Capture ({string.Join(" | ", order.Skip(Math.Max(0, at)).Take(6))})");
        }
        finally
        {
            AppSettings.Path = savedPath;
            foreach (var w in Application.Current.Windows.OfType<MainWindow>().ToList()) { w.ConfirmKeepQuestion = (_, _, _) => true; w.UnsavedQuestion = (_, _, _) => MessageBoxResult.Yes; w.Close(); }
            controller.Store.WipeAll(); controller.Dispose();
        }
    }

    // [Cancel] at the left, [No] [Yes] at the right; Yes the default; one line per sentence; narrower than before.
    private static void Dialogs(Action<bool, string> check)
    {
        const string text = "Discard and open the new screenshot instead?\nThe current screenshot has not been saved.\nAny changes will be lost.";
        var box = new ThemedMessage(text, "Unsaved Screenshot", MessageBoxButton.YesNoCancel, MessageBoxImage.Warning, split: true) { Left = -20000, Top = 0, ShowActivated = false, WindowStartupLocation = WindowStartupLocation.Manual };
        var old = new ThemedMessage("Open the new screenshot instead?\n\nThe current screenshot has not been saved or exported. Any changes will be lost.", "Unsaved Screenshot", MessageBoxButton.YesNo, MessageBoxImage.Warning) { Left = -20000, Top = 0, ShowActivated = false, WindowStartupLocation = WindowStartupLocation.Manual };
        try
        {
            box.Show(); box.UpdateLayout(); old.Show(); old.UpdateLayout();
            var buttons = Descendants<Button>(box).OrderBy(b => b.TranslatePoint(new Point(), box).X).ToList();
            var captions = buttons.Select(b => b.Content as string).ToList();
            double X(Button b) => b.TranslatePoint(new Point(), box).X;
            check(captions.SequenceEqual(["Cancel", "No", "Yes"]) && X(buttons[1]) - (X(buttons[0]) + buttons[0].ActualWidth) > 20,
                $"the box reads [Cancel] at the left, then [No] [Yes] at the right ({string.Join(", ", captions)})");
            check(buttons[2].IsDefault && !buttons[1].IsDefault && buttons[0].IsCancel, "Yes is the default (Enter); Esc is Cancel");
            var message = Descendants<TextBlock>(box).First(t => t.Text == text);
            check(message.TextWrapping == TextWrapping.NoWrap && message.ActualHeight > 3 * 15 && message.ActualHeight < 4 * 19 + 2, $"one sentence per line, three lines ({message.ActualHeight:0} px high)");
            check(box.ActualWidth < old.ActualWidth, $"the box is narrower than the old one ({box.ActualWidth:0} < {old.ActualWidth:0} px)");
            var answer = MessageBoxResult.None;
            var saved = ThemedMessage.Answer; ThemedMessage.Answer = (t, c, b) => { answer = b == MessageBoxButton.YesNoCancel ? MessageBoxResult.Yes : MessageBoxResult.None; return answer; };
            try { check(ThemedMessage.ShowUnsaved(null, text, "Unsaved Screenshot") == MessageBoxResult.Yes, "checks can answer the three-way box like the others"); }
            finally { ThemedMessage.Answer = saved; }
        }
        finally { box.Close(); old.Close(); }
    }
}
