using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.24.0: David's suggestions after 0.23.0: File info as a copyable table with the GPS position, a slideshow that
// waits for a key (0 seconds), his own keys for the previous and next picture, more toolbar buttons (each in Light
// and Dark), and a toolbar he can show, hide and order, with a left and a right side. `--release-024-only`.
internal static class Release024Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.24.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static void Wait(Func<Task> operation) => Wait(async () => { await operation(); return true; });
    private static void Pause(int milliseconds) => Wait(async () => { await Task.Delay(milliseconds); return true; });
    private static ulong Rational(uint top, uint bottom) => top | (ulong)bottom << 32;

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- Keys ----
        check(AppSettings.ParseKey("Ctrl+Shift+N") is { } k && k.Key == Key.N && k.Modifiers == (ModifierKeys.Control | ModifierKeys.Shift) && AppSettings.ParseKey("Right") is { Key: Key.Right }
            && AppSettings.ParseKey("Banana") == null && AppSettings.ParseKey("Ctrl+") == null, "a picture key can be any key, with or without Ctrl, Shift or Alt");
        check(AppSettings.Parse("{\"NextPictureKey\": \"Nonsense\"}").NextPictureKey == "PageDown" && AppSettings.Parse("{\"SlideshowSeconds\": 0}").SlideshowSeconds == 0,
            "a key that isn't one goes back to Page Down; 0 seconds is a slideshow choice");

        // ---- The toolbar layout ----
        var defaults = AppSettings.CleanToolbar(null);
        check(defaults.SequenceEqual(AppSettings.DefaultEditorToolbar) && defaults.Count(id => id == ">") == 1, "the usual toolbar has every button once and one Right side line");
        var old = AppSettings.CleanToolbar(["OpenButton", "ExportButton", "|", "CropTool", ">", "PanelButton"]);
        check(old.IndexOf("ResizeButton") == old.IndexOf("CropTool") + 1 && old.IndexOf("PreviousPictureButton") > old.IndexOf("OpenButton") && old.IndexOf("PanelButton") > old.IndexOf(">") && old.Count(id => id == ">") == 1,
            "a toolbar saved before new buttons existed gets them in their usual places");

        var folder = Path.Combine(output, "release024"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        var temp = Path.Combine(output, "release024-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release024-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); var preview = (PreviewSurface)editor.FindName("Preview");
            var failures = new List<string>(); editor.WorkFailed = ex => failures.Add(ex.GetType().Name + ": " + ex.Message);
            T Find<T>(string name) where T : class => (T)editor.FindName(name);
            string[] asked = ["RotateClockwiseButton", "RotateCounterClockwiseButton", "PreviousPictureButton", "NextPictureButton", "FullScreenButton", "SlideshowButton", "ResizeButton", "FileInfoButton", "FlipHorizontalButton", "FlipVerticalButton"];
            string[] extras = ["OpenProjectButton", "SaveProjectButton", "SaveMediaButton", "DeleteButton", "FitWidthButton", "SettingsButton"];
            check(asked.All(id => editor.OnToolbar(id) == !AppSettings.DefaultHiddenEditorButtons.Contains(id)), "the buttons David asked for are on the toolbar (0.27.0: except the ones his own defaults untick): rotate both ways, previous, next, full screen, slideshow, resize, file info, flip both ways");
            check(extras.All(id => !editor.OnToolbar(id)) && editor.OnRightSide("ClearScreenButton") && editor.OnRightSide("PanelButton") && !editor.OnRightSide("OpenButton"),
                "the extra buttons (Open/Save Project, Save Copy, Delete, Fit Width, Settings) start hidden; Clear and Panel sit on the right");
            var custom = editor.Settings.Copy();
            var layout = AppSettings.CleanToolbar(null); layout.Remove("OpenButton"); layout.Insert(layout.IndexOf(">") + 1, "OpenButton");
            custom.EditorToolbar = layout; custom.EditorHiddenButtons = [.. AppSettings.DefaultHiddenEditorButtons.Except(["SettingsButton"]), "UndoButton"];
            editor.ApplySettings(custom); editor.UpdateLayout();
            var right = Find<StackPanel>("RightTools").Children.OfType<Button>().Select(b => b.Name).ToList();
            check(editor.OnRightSide("OpenButton") && right[0] == "OpenButton" && !editor.OnToolbar("UndoButton") && editor.OnToolbar("SettingsButton"),
                "a button moved below the Right side line goes to the right; an unticked one goes; a ticked extra comes");
            var separators = Find<WrapPanel>("ToolButtons").Children.Cast<UIElement>().Zip(Find<WrapPanel>("ToolButtons").Children.Cast<UIElement>().Skip(1)).Count(p => p.First is System.Windows.Shapes.Rectangle && p.Second is System.Windows.Shapes.Rectangle);
            check(separators == 0 && Find<WrapPanel>("ToolButtons").Children[0] is Button, "no separator is left at the start or doubled up when buttons around it are hidden");
            custom.VerticalToolbar = true; editor.ApplySettings(custom); editor.UpdateLayout();
            check(DockPanel.GetDock(Find<StackPanel>("RightTools")) == Dock.Bottom && editor.OnRightSide("OpenButton"), "with the toolbar vertical, the right side is at the bottom");
            editor.ApplySettings(new AppSettings()); editor.UpdateLayout();
            check(editor.OnRightSide("PanelButton") && !editor.OnRightSide("OpenButton") && editor.OnToolbar("UndoButton"), "back to the usual toolbar");

            // Settings › Editor: the list.
            var settings = new SettingsWindow(new AppSettings());
            var list = (ListBox)settings.FindName("ToolbarList");
            var items = settings.ToolbarChoices.ToList();
            check(items.Count(i => (string)i.Tag == ">") == 1 && items.Any(i => (string)i.Tag == "|") && items.OfType<CheckBox>().Any(c => (string)c.Tag == "SettingsButton" && c.IsChecked == false)
                && items.OfType<CheckBox>().Any(c => (string)c.Tag == "ResizeButton" && c.IsChecked == true && (string)c.Content == "Resize"),
                "Settings lists every button with a tick box, the separators and the Right side line");
            var open = items.FindIndex(i => (string)i.Tag == "OpenButton"); list.SelectedIndex = open; settings.MoveToolbarItem(1);
            ((CheckBox)items.First(i => (string)i.Tag == "UndoButton")).IsChecked = false;
            settings.AddToolbarSeparator(settings, new RoutedEventArgs()); var added = list.SelectedIndex;
            var chosen = settings.Collect();
            check(chosen.EditorToolbar.IndexOf("OpenButton") == open + 1 && chosen.EditorHiddenButtons.Contains("UndoButton") && chosen.EditorToolbar[added] == "|",
                "moving a button, unticking one and adding a separator are kept when OK is pressed");
            var before = chosen.EditorToolbar.Count;
            settings.RemoveToolbarSeparator(settings, new RoutedEventArgs());
            check(settings.Collect().EditorToolbar.Count == before - 1, "a separator can be removed again");
            // 0.24.1 (David: settings cut off out of reach): every tab fits, and one that didn't would scroll.
            settings.WindowStartupLocation = WindowStartupLocation.Manual; settings.Left = -20000; settings.Top = 0; settings.ShowActivated = false; settings.Show(); Pump();
            var tabs = (TabControl)settings.FindName("Tabs"); var overflow = new List<string>();
            foreach (var tab in tabs.Items.OfType<TabItem>())
            {
                tabs.SelectedItem = tab; settings.UpdateLayout(); Pump();
                if (tab.Content is ScrollViewer scroller && scroller.ExtentHeight > scroller.ViewportHeight + 1) overflow.Add($"{tab.Header} ({scroller.ExtentHeight:0} of {scroller.ViewportHeight:0})");
                if (tab.Content is not (ScrollViewer or DockPanel)) overflow.Add($"{tab.Header} (can't scroll)");
                var page = (FrameworkElement)settings.Content; var shot = new RenderTargetBitmap((int)page.ActualWidth, (int)page.ActualHeight, 96, 96, PixelFormats.Pbgra32);
                var back = new DrawingVisual(); using (var dc = back.RenderOpen()) dc.DrawRectangle((Brush)settings.FindResource("Background"), null, new Rect(0, 0, page.ActualWidth, page.ActualHeight));
                shot.Render(back); shot.Render(page);
                var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(shot));
                using var file = File.Create(Path.Combine(output, $"release0241-settings-{tab.Header.ToString()!.Replace(' ', '-')}.png")); encoder.Save(file);
            }
            check(overflow.Count == 0, $"every Settings tab fits (and would scroll if it didn't) ({string.Join(", ", overflow)})");
            tabs.SelectedItem = tabs.Items.OfType<TabItem>().First(t => (string)t.Header == "Toolbar"); settings.UpdateLayout();
            check(list.ActualHeight > 300 && tabs.Items.OfType<TabItem>().Single(t => (string)t.Header == "Editor").Content is ScrollViewer { Content: StackPanel editorPage } && !editorPage.Children.OfType<FrameworkElement>().Any(c => c.Name == "ToolbarList"),
                $"the toolbar buttons have their own Toolbar tab with room for the list ({list.ActualHeight:0} pixels); the Editor tab keeps its other settings");
            settings.SetPictureKey(false, "N"); settings.SetPictureKey(true, "Ctrl+B");
            check(settings.Collect().NextPictureKey == "N" && settings.Collect().PreviousPictureKey == "Ctrl+B" && ((TextBox)settings.FindName("NextKeyBox")).Text == "N",
                "Settings keeps the keys chosen for the next and previous picture");
            settings.Close();

            // Each new button's picture shows in Light and in Dark.
            var light = new List<string>(); var dark = new List<string>();
            foreach (var theme in new[] { "Light", "Dark" })
            {
                MainWindow.ApplyThemeResources(theme); editor.UpdateLayout(); Pump();
                foreach (var id in asked.Concat(extras.Where(e => e != "SettingsButton")))
                {
                    var button = (Button)editor.FindName(id); var custom2 = editor.Settings.Copy(); custom2.EditorHiddenButtons = []; editor.ApplySettings(custom2); editor.UpdateLayout();
                    button.SetCurrentValue(UIElement.IsEnabledProperty, true); // As when there is something to use it on (greyed out is faint on purpose).
                    button.Measure(new Size(double.PositiveInfinity, double.PositiveInfinity)); button.Arrange(new Rect(button.DesiredSize)); button.UpdateLayout();
                    var w = Math.Max(1, (int)Math.Ceiling(button.ActualWidth)); var h = Math.Max(1, (int)Math.Ceiling(button.ActualHeight));
                    var bitmap = new RenderTargetBitmap(w, h, 96, 96, PixelFormats.Pbgra32); bitmap.Render(button);
                    var pixels = new byte[w * h * 4]; bitmap.CopyPixels(pixels, w * 4, 0);
                    // Ink: pixels that stand out from the button's own background.
                    var background = ((SolidColorBrush)editor.FindResource("Surface")).Color;
                    var ink = 0;
                    for (var i = 0; i < pixels.Length; i += 4) if (pixels[i + 3] > 0 && Math.Abs(pixels[i + 2] - background.R) + Math.Abs(pixels[i + 1] - background.G) + Math.Abs(pixels[i] - background.B) > 150) ink++;
                    if (ink < 25) (theme == "Light" ? light : dark).Add($"{id} ({ink})");
                    if (id == "FileInfoButton" || id == "RotateClockwiseButton")
                    {
                        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
                        using var file = File.Create(Path.Combine(output, $"release024-{id}-{theme}.png")); encoder.Save(file);
                    }
                }
            }
            // Pictures of the whole toolbar, every button shown, for a look (not a check).
            foreach (var theme in new[] { "Light", "Dark" })
            {
                MainWindow.ApplyThemeResources(theme); var all = editor.Settings.Copy(); all.EditorHiddenButtons = []; editor.ApplySettings(all); editor.UpdateLayout(); Pump();
                var strip = Find<FrameworkElement>("ToolStrip"); var w = (int)Math.Ceiling(strip.ActualWidth); var h = (int)Math.Ceiling(strip.ActualHeight);
                var shot = new RenderTargetBitmap(Math.Max(1, w), Math.Max(1, h), 96, 96, PixelFormats.Pbgra32); shot.Render(strip);
                var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(shot));
                using var file = File.Create(Path.Combine(output, $"release024-toolbar-{theme}.png")); encoder.Save(file);
            }
            MainWindow.ApplyThemeResources("Light"); editor.ApplySettings(new AppSettings());
            check(light.Count == 0 && dark.Count == 0, $"every new button's picture shows clearly in Light and in Dark (faint: {string.Join(", ", light.Concat(dark))})");

            // File info: the GPS position, and the table copies.
            var photo = Path.Combine(folder, "gps.jpg");
            {
                var bitmap = BitmapSource.Create(64, 48, 96, 96, PixelFormats.Bgr32, null, new byte[64 * 48 * 4], 64 * 4);
                var metadata = new BitmapMetadata("jpg") { CameraModel = "GpsCam" };
                metadata.SetQuery("/app1/ifd/gps/{ushort=1}", "N"); metadata.SetQuery("/app1/ifd/gps/{ushort=2}", new[] { Rational(64, 1), Rational(7, 1), Rational(3540, 100) });
                metadata.SetQuery("/app1/ifd/gps/{ushort=3}", "W"); metadata.SetQuery("/app1/ifd/gps/{ushort=4}", new[] { Rational(21, 1), Rational(49, 1), Rational(264, 100) });
                var encoder = new JpegBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap, null, metadata, null));
                using var stream = File.Create(photo); encoder.Save(stream);
            }
            check(Wait(() => editor.OpenPathAsync(photo)), "a photo with a GPS position opens");
            var info = Wait(() => editor.ShowFileInfoAsync(show: false))!;
            // 0.25.0: the details are plain text now (Release025Checks); the GPS position is in General.
            var general = info.Report.Sections[0];
            var place = general.Lines.FirstOrDefault(l => l.Name == "GPS position").Value;
            check(general.Title == "General" && place != null && place.StartsWith("64.12650, -21.81740") && place.Contains("64° 7′ 35.4″ N") && place.Contains("21° 49′ 2.6″ W"),
                $"File info shows the GPS position, as numbers for a map and in degrees ({place})");
            check(info.Box.IsReadOnly && info.Box.Text == info.Report.Text && info.Details.Any(d => d.Name == "GPS position"),
                "the details are text to select and copy (Copy all copies all of it)");
            info.Close();
            foreach (var theme in new[] { "Light", "Dark" }) // Pictures of the window for a look (not a check).
            {
                MainWindow.ApplyThemeResources(theme);
                var look = Wait(() => editor.ShowFileInfoAsync(show: false))!;
                look.Owner = null; look.WindowStartupLocation = WindowStartupLocation.Manual; look.Left = -20000; look.Top = 0; look.ShowActivated = false; look.Show(); Pump(); look.UpdateLayout(); Pump();
                var content = (FrameworkElement)look.Content;
                var shot = new RenderTargetBitmap(640, 540, 96, 96, PixelFormats.Pbgra32);
                var back = new DrawingVisual(); using (var dc = back.RenderOpen()) dc.DrawRectangle((Brush)editor.FindResource("Background"), null, new Rect(0, 0, 640, 540));
                shot.Render(back); shot.Render(content);
                var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(shot));
                using (var file = File.Create(Path.Combine(output, $"release024-fileinfo-{theme}.png"))) encoder.Save(file);
                look.Close();
            }
            MainWindow.ApplyThemeResources("Light");
            var tagged = Path.Combine(folder, "located.mp4");
            var source = Path.GetFullPath(Path.Combine(output, "..", "test-media", "synthetic-with-audio.mp4"));
            Wait(() => tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", source, "-c", "copy", "-metadata", "location=+64.1265-021.8174/", tagged], tagged, CancellationToken.None));
            check(Wait(() => editor.OpenPathAsync(tagged)), "a video with a place written in it opens");
            info = Wait(() => editor.ShowFileInfoAsync(show: false))!;
            check(info.Report.Sections[0].Lines.FirstOrDefault(l => l.Name == "GPS position").Value?.StartsWith("64.12650, -21.81740") == true, "a video's place is shown as a GPS position too");
            info.Close();

            // The keys: the editor and the slideshow use the ones chosen.
            Png(Path.Combine(folder, "a.png"), Colors.Teal); Png(Path.Combine(folder, "b.png"), Colors.Orange); Png(Path.Combine(folder, "c.png"), Colors.Purple);
            var keyed = new AppSettings { NextPictureKey = "N", PreviousPictureKey = "B", SlideshowSeconds = 0 };
            editor.ApplySettings(keyed);
            check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "a.png"))), "a picture opens for the keys");
            // Raised inside the dispatcher, as a real key press is (the editor's awaits then resume on its thread).
            bool Press(Key key) => Wait(() =>
            {
                var args = new KeyEventArgs(Keyboard.PrimaryDevice, PresentationSource.FromVisual(editor)!, 0, key) { RoutedEvent = UIElement.PreviewKeyDownEvent };
                editor.RaiseEvent(args); return Task.FromResult(args.Handled);
            });
            check(Press(Key.N) && Wait(async () => { for (var i = 0; i < 100 && Path.GetFileName(editor.OpenedPath) != "b.png"; i++) await Task.Delay(50); return Path.GetFileName(editor.OpenedPath) == "b.png"; }),
                $"the key chosen for the next picture (N) opens the next one{(failures.Count > 0 ? ": " + failures[^1] : "")}");
            check(Press(Key.B) && Wait(async () => { for (var i = 0; i < 100 && Path.GetFileName(editor.OpenedPath) != "a.png"; i++) await Task.Delay(50); return Path.GetFileName(editor.OpenedPath) == "a.png"; }),
                "and the one for the previous picture (B) goes back");
            var show = editor.StartSlideshow(show: false)!;
            Wait(show.Begin); Pause(1500);
            check(show.Manual && show.Index == 0, "with 0 seconds the slideshow stays on the picture until a key is pressed");
            Wait(() => show.Key(Key.N)); check(show.Index == 1, "N moves the slideshow on");
            Wait(() => show.Key(Key.B)); check(show.Index == 0, "B moves it back");
            Wait(() => show.Key(Key.Right)); check(show.Index == 1, "Right still works too");
            show.Close();
            editor.ApplySettings(new AppSettings());
            editor.Close(); Pump();
        }
        finally { MainWindow.ApplyThemeResources("Light"); AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
    private static void Png(string path, Color colour)
    {
        var visual = new DrawingVisual(); using (var dc = visual.RenderOpen()) dc.DrawRectangle(new SolidColorBrush(colour), null, new Rect(0, 0, 80, 60));
        var bitmap = new RenderTargetBitmap(80, 60, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap)); using var stream = File.Create(path); encoder.Save(stream);
    }
}
