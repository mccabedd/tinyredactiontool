using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.25.0: David's last push before the development tag goes: File info laid out as a plain text report, TRT as the
// default app for pictures (not videos), and the navigation bar (the folder's pictures along the bottom) in the editor
// and the slideshow. `--release-025-only`.
internal static class Release025Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.25.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static void Wait(Func<Task> operation) => Wait(async () => { await operation(); return true; });
    private static void Pause(int milliseconds) => Wait(async () => { await Task.Delay(milliseconds); return true; });
    private static bool Until(Func<bool> done, int milliseconds = 6000) => Wait(async () => { for (var i = 0; i < milliseconds / 50 && !done(); i++) await Task.Delay(50); return done(); });
    // A click raised inside the dispatcher, as a real one is (the handlers' awaits then resume on its thread).
    private static void Click(Button button) => Wait(() => { button.RaiseEvent(new RoutedEventArgs(System.Windows.Controls.Primitives.ButtonBase.ClickEvent)); return Task.CompletedTask; });

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- File info: the ways of writing sizes, times, rates and names ----
        check(FileDetails.Size(8_430_000_000) == "7.85 GiB" && FileDetails.Size(512) == "512 Bytes" && FileDetails.Size(150_000) == "146 KiB",
            $"sizes are written as: 7.85 GiB ({FileDetails.Size(8_430_000_000)}), 146 KiB, 512 Bytes");
        check(FileDetails.Duration(6560) == "1 h 49 min" && FileDetails.Duration(205) == "3 min 25 s" && FileDetails.Duration(5.12) == "5 s 120 ms",
            "durations: 1 h 49 min, 3 min 25 s, 5 s 120 ms");
        check(FileDetails.BitRate(10_200_000) == "10.2 Mb/s" && FileDetails.BitRate(128_000) == "128 kb/s" && FileDetails.BitRate(9_999_000) == "9 999 kb/s",
            "bit rates: 10.2 Mb/s, 128 kb/s, 9 999 kb/s");
        check(FileDetails.FrameRate("24000/1001") == "23.976 (24000/1001) FPS" && FileDetails.FrameRate("25/1") == "25.000 FPS" && FileDetails.FrameRate("0/0") == null,
            "frame rates: 23.976 (24000/1001) FPS and 25.000 FPS");
        check(FileDetails.TagName("DateTimeOriginal") == "Date taken" && FileDetails.TagName("GPSLatitude") == "GPS latitude" && FileDetails.TagName("ExposureTime") == "Exposure time"
              && FileDetails.TagName("encoder") == "Writing application" && FileDetails.TagName("com.apple.quicktime.make") == "com.apple.quicktime.make",
            $"details get readable names (Date taken, GPS latitude, Exposure time, Writing application; got {FileDetails.TagName("GPSLatitude")})");

        // ---- Default app for pictures, in a throw-away key ----
        var savedRoot = PictureApp.SoftwareRoot; PictureApp.SoftwareRoot = @"Software\TinyRedactionToolChecks";
        try
        {
            Registry.CurrentUser.DeleteSubKeyTree(PictureApp.SoftwareRoot, false);
            check(!PictureApp.IsRegistered, "TRT starts out not registered for pictures");
            PictureApp.Register();
            using (var command = Registry.CurrentUser.OpenSubKey(PictureApp.CommandKey))
            using (var png = Registry.CurrentUser.OpenSubKey($@"{PictureApp.SoftwareRoot}\Classes\.png\OpenWithProgids"))
            using (var associations = Registry.CurrentUser.OpenSubKey($@"{PictureApp.CapabilitiesKey}\FileAssociations"))
            using (var registered = Registry.CurrentUser.OpenSubKey($@"{PictureApp.SoftwareRoot}\RegisteredApplications"))
            {
                check(PictureApp.IsRegistered && ((string?)command?.GetValue(""))?.EndsWith("\"%1\"") == true && png?.GetValueNames().Contains(PictureApp.ProgId) == true
                      && (string?)associations?.GetValue(".jpg") == PictureApp.ProgId && (string?)associations?.GetValue(".heic") == PictureApp.ProgId
                      && (string?)registered?.GetValue(PictureApp.RegisteredName) == PictureApp.CapabilitiesKey,
                    "ticking it registers TRT for this user as an app for pictures (PNG, JPG, HEIC...), for Windows' Default apps page");
                check(associations?.GetValueNames().Any(n => n is ".mp4" or ".mkv" or ".avi" or ".mov") == false && Registry.CurrentUser.OpenSubKey($@"{PictureApp.SoftwareRoot}\Classes\.mp4") == null,
                    "videos are left alone");
            }
            check(!PictureApp.Refresh(), "starting the same TRT again changes nothing");
            using (var command = Registry.CurrentUser.OpenSubKey(PictureApp.CommandKey, true)) command!.SetValue("", "\"C:\\old place\\TinyRedactionTool-0.24.1.exe\" \"%1\"");
            check(PictureApp.Refresh() && Registry.CurrentUser.OpenSubKey(PictureApp.CommandKey)?.GetValue("") as string == ExplorerMenu.Command,
                "a TRT started from a new place points the registration at itself");
            PictureApp.Remove();
            using (var png = Registry.CurrentUser.OpenSubKey($@"{PictureApp.SoftwareRoot}\Classes\.png\OpenWithProgids"))
            using (var registered = Registry.CurrentUser.OpenSubKey($@"{PictureApp.SoftwareRoot}\RegisteredApplications"))
                check(!PictureApp.IsRegistered && png?.GetValueNames().Contains(PictureApp.ProgId) != true && registered?.GetValue(PictureApp.RegisteredName) == null
                      && Registry.CurrentUser.OpenSubKey(PictureApp.CapabilitiesKey) == null,
                    "clearing it removes TRT's registration again");
        }
        finally { Registry.CurrentUser.DeleteSubKeyTree(PictureApp.SoftwareRoot, false); PictureApp.SoftwareRoot = savedRoot; }

        // ---- Settings ----
        check(AppSettings.Parse("{\"NavBarThumbnailSize\": 13}").NavBarThumbnailSize == 72 && new AppSettings() is { NavBarInEditor: false, NavBarInSlideshow: true, NavBarPinnedInSlideshow: true },
            "the navigation bar settings start as: not in the editor, pinned in the slideshow; an unknown picture size goes back to Medium");
        {
            var settings = new SettingsWindow(new AppSettings { NavBarInEditor = true, NavBarPinnedInSlideshow = false, NavBarThumbnailSize = 96 });
            T Box<T>(string name) where T : class => (T)settings.FindName(name);
            var tabs = ((TabControl)settings.FindName("Tabs")).Items.Cast<TabItem>().ToList();
            var slideshowTab = tabs.FirstOrDefault(t => (string)t.Header == "Slideshow");
            bool On(TabItem? tab, string name) => tab != null && settings.FindName(name) is FrameworkElement element && IsInside(element, tab);
            check(On(slideshowTab, "SlideshowTimeChoice") && On(slideshowTab, "NavBarEditorBox") && On(slideshowTab, "NavBarPinnedBox") && On(tabs.First(), "DefaultPictureAppBox"),
                "Settings has a Slideshow tab (the slideshow and the navigation bar) and the default-app choice on General");
            check(Box<CheckBox>("NavBarEditorBox").IsChecked == true && Box<CheckBox>("NavBarPinnedBox").IsChecked == false && Box<NumberSpinner>("NavBarHeightBox").Value == 96,
                "Settings shows the navigation bar choices");
            Box<CheckBox>("NavBarEditorBox").IsChecked = false; Box<CheckBox>("NavBarPinnedBox").IsChecked = true; Box<NumberSpinner>("NavBarHeightBox").Value = 48;
            var result = settings.Collect();
            check(!result.NavBarInEditor && result.NavBarPinnedInSlideshow && result.NavBarThumbnailSize == 48, "and keeps the ones chosen");
            check(SettingsWindow.ToolbarLabel("NavBarButton") == "Nav Bar" && AppSettings.DefaultEditorToolbar.Contains("NavBarButton"), // 0.27.0: David's defaults keep it unticked.
                "the Nav Bar button is on the toolbar and in Settings › Toolbar");
            settings.Close();
        }

        var folder = Path.Combine(output, "release025"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        var temp = Path.Combine(output, "release025-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release025-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor();
            var failures = new List<string>(); editor.WorkFailed = ex => failures.Add(ex.GetType().Name + ": " + ex.Message);
            string Failure() => failures.Count > 0 ? ": " + failures[^1] : "";

            // ---- File info as text ----
            var photo = Path.Combine(folder, "photo.jpg");
            {
                var bitmap = BitmapSource.Create(64, 48, 96, 96, PixelFormats.Bgr32, null, new byte[64 * 48 * 4], 64 * 4);
                var metadata = new BitmapMetadata("jpg") { CameraModel = "InfoCam", CameraManufacturer = "Nox" };
                var encoder = new JpegBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap, null, metadata, null));
                using var stream = File.Create(photo); encoder.Save(stream);
            }
            check(Wait(() => editor.OpenPathAsync(photo)), "a photo opens for File info");
            var info = Wait(() => editor.ShowFileInfoAsync(show: false))!;
            var lines = info.Report.Text.Split('\n').Select(l => l.TrimEnd('\r')).ToList();
            var colons = lines.Where(l => l.Contains(" : ")).Select(l => l.IndexOf(" : ", StringComparison.Ordinal)).Distinct().ToList();
            check(lines[0] == "General" && lines.Contains("Image") && colons.Count == 1 && lines.Any(l => l.StartsWith("Format") && l.EndsWith(": JPEG")) && lines.Any(l => l.StartsWith("Width") && l.EndsWith(": 64 pixels"))
                  && lines.Any(l => l.StartsWith("Camera model") && l.EndsWith(": InfoCam")) && lines.Any(l => l.StartsWith("File size")),
                $"File info reads as a plain text report: General, then Image, the colons in one column (got {string.Join(" | ", lines.Take(12))})");
            check(info.Box.IsReadOnly && info.Box.FontFamily.Source.StartsWith("Consolas") && info.Box.TextWrapping == TextWrapping.NoWrap && info.Box.Text == info.Report.Text,
                "it is plain text in a fixed-width font, to select and copy");
            info.Close();
            foreach (var theme in new[] { "Light", "Dark" }) // Pictures of the window for a look (not a check).
            {
                MainWindow.ApplyThemeResources(theme);
                var look = Wait(() => editor.ShowFileInfoAsync(show: false))!;
                Snap(look, Path.Combine(output, $"release025-fileinfo-{theme}.png"));
            }
            MainWindow.ApplyThemeResources("Light");
            var video = Path.GetFullPath(Path.Combine(output, "..", "test-media", "synthetic-with-audio.mp4"));
            check(Wait(() => editor.OpenPathAsync(video)), "a video opens for File info");
            info = Wait(() => editor.ShowFileInfoAsync(show: false))!;
            var titles = info.Report.Sections.Select(s => s.Title).ToList();
            string? Line(string section, string name) => info.Report.Sections.FirstOrDefault(s => s.Title == section).Lines?.FirstOrDefault(l => l.Name == name).Value;
            check(titles.Take(3).SequenceEqual(["General", "Video", "Audio"]) && Line("General", "Format") == "MPEG-4" && Line("General", "Duration") != null && Line("General", "Overall bit rate")?.EndsWith("b/s") == true
                  && Line("Video", "Width")?.EndsWith(" pixels") == true && Line("Video", "Frame rate")?.EndsWith("FPS") == true && Line("Audio", "Sampling rate")?.EndsWith(" kHz") == true && Line("Audio", "Channel(s)") != null,
                $"a video gets General, Video and Audio sections with its format, size, rates and channels ({string.Join(", ", titles)}; {Line("General", "Format")}, {Line("Video", "Format")})");
            Snap(info, Path.Combine(output, "release025-fileinfo-video.png"));

            // ---- The navigation bar in the editor ----
            foreach (var (name, colour) in new[] { ("a.png", Colors.Teal), ("b.png", Colors.Orange), ("c.png", Colors.Purple) }) Png(Path.Combine(folder, name), colour);
            check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "a.png"))), "a picture opens for the navigation bar");
            check(AppSettings.DefaultEditorToolbar.Contains("NavBarButton") && !editor.NavBarShown, "the Nav Bar button is on the toolbar, and the bar starts hidden");
            Click((Button)editor.FindName("NavBarButton"));
            var nav = editor.NavBar ?? throw new InvalidOperationException("The Nav Bar button made no navigation bar.");
            check(editor.NavBarShown && nav.Items.Count == 4 && nav.Items[nav.SelectedIndex].Name == "a.png" && editor.Settings.NavBarInEditor,
                $"the Nav Bar button shows the folder's pictures with the open one chosen, and is remembered ({nav.Items.Count} pictures){Failure()}");
            check(nav.Pinned && !nav.CanUnpin && !nav.PinButton.IsEnabled && (string)nav.PinButton.ToolTip == "Always Pinned in the Editor", "in the editor the bar is pinned and can't be unpinned");
            check(Until(() => nav.Items.Where(i => i.Name.EndsWith(".png")).All(i => i.Picture != null)), "the small pictures are read");
            Click(nav.NextButton);
            check(Until(() => Path.GetFileName(editor.OpenedPath) == "b.png" && nav.SelectedIndex >= 0 && nav.Items[nav.SelectedIndex].Name == "b.png"), $"Next opens the next picture and the bar follows ({Path.GetFileName(editor.OpenedPath)}, chosen {nav.SelectedIndex}){Failure()}");
            Click(nav.PreviousButton);
            check(Until(() => Path.GetFileName(editor.OpenedPath) == "a.png"), "Previous goes back");
            Wait(() =>
            {
                nav.UpdateLayout();
                var container = (ListBoxItem)nav.Strip.ItemContainerGenerator.ContainerFromIndex(nav.Items.ToList().FindIndex(i => i.Name == "c.png"));
                container.RaiseEvent(new MouseButtonEventArgs(Mouse.PrimaryDevice, 0, MouseButton.Left) { RoutedEvent = UIElement.PreviewMouseLeftButtonDownEvent });
                return Task.CompletedTask;
            });
            check(Until(() => Path.GetFileName(editor.OpenedPath) == "c.png"), $"clicking a small picture opens it{Failure()}");
            Snap(editor, Path.Combine(output, "release025-editor-navbar.png"));
            Click(nav.CloseButton);
            check(!editor.NavBarShown && !editor.Settings.NavBarInEditor, "Close hides the bar, and that is remembered too");

            // ---- The navigation bar in the slideshow ----
            editor.ApplySettings(new AppSettings { SlideshowSeconds = 5, NavBarInSlideshow = true, NavBarPinnedInSlideshow = true });
            check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "a.png"))), "a picture opens for the slideshow");
            var show = editor.StartSlideshow(show: false)!;
            Wait(show.Begin);
            var bar = show.Nav ?? throw new InvalidOperationException("The slideshow has no navigation bar.");
            check(show.NavOpen && show.NavPinned && Grid.GetRow(bar) == 1 && bar.Items.Count == 4 && bar.SelectedIndex == show.Index && bar.CanUnpin,
                "the slideshow starts with the navigation bar pinned at the bottom, under the picture");
            var start = show.Index;
            Click(bar.NextButton); check(Until(() => show.Index == start + 1 && bar.SelectedIndex == start + 1), "its Next moves the slideshow on, and the bar follows");
            Click(bar.PreviousButton); check(Until(() => show.Index == start), "its Previous goes back");
            Click(bar.PlayButton); check(show.Paused, "its Play/Pause pauses the slideshow");
            Click(bar.PlayButton); check(!show.Paused, "and plays it again");
            Click(bar.PinButton);
            check(!show.NavPinned && !bar.Pinned && Grid.GetRow(bar) == 0 && !show.NavHidden, "unpinning lays the bar over the picture");
            check(Until(() => show.NavHidden, 3000) && show.RedTab?.Visibility == Visibility.Visible && !bar.IsHitTestVisible,
                "with the pointer away, the unpinned bar slides out of sight and leaves a red tab, like the capture bar");
            Wait(() => { show.RedTab!.RaiseEvent(new MouseEventArgs(Mouse.PrimaryDevice, 0) { RoutedEvent = Mouse.MouseEnterEvent }); return Task.CompletedTask; });
            check(!show.NavHidden && bar.IsHitTestVisible && show.RedTab!.Visibility == Visibility.Collapsed, "pointing at the red tab brings it back");
            Click(bar.PinButton); Pause(1200);
            check(show.NavPinned && !show.NavHidden && Grid.GetRow(bar) == 1, "pinned again, it stays");
            Click(bar.CloseButton);
            check(!show.NavOpen && show.RedTab!.Visibility == Visibility.Collapsed, "Close closes the bar completely");
            Wait(() => show.Key(Key.Tab)); check(show.NavOpen, "Tab brings it back");
            show.Close();
            editor.ApplySettings(new AppSettings { SlideshowSeconds = 5, NavBarInSlideshow = true, NavBarPinnedInSlideshow = false });
            show = editor.StartSlideshow(show: false)!;
            Wait(show.Begin);
            check(!show.NavPinned && Until(() => show.NavHidden, 3000), "set to start unpinned, the bar shows for a moment, then slides away");
            show.Close();
            editor.ApplySettings(new AppSettings { NavBarInSlideshow = false });
            show = editor.StartSlideshow(show: false)!;
            Wait(show.Begin);
            check(show.Nav == null && !show.NavOpen, "set not to show, the slideshow starts without it");
            show.Close();
            editor.ApplySettings(new AppSettings());
            editor.Close(); Pump();
        }
        finally { MainWindow.ApplyThemeResources("Light"); AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
    private static bool IsInside(DependencyObject element, DependencyObject container)
    {
        for (DependencyObject? at = element; at != null; at = LogicalTreeHelper.GetParent(at) ?? (at is Visual or System.Windows.Media.Media3D.Visual3D ? VisualTreeHelper.GetParent(at) : null))
            if (at == container) return true;
        return false;
    }
    // A picture of a window (shown off-screen first) for a look; not a check.
    private static void Snap(Window window, string path)
    {
        var shown = window.IsVisible;
        if (!shown) { window.Owner = null; window.WindowStartupLocation = WindowStartupLocation.Manual; window.Left = -20000; window.Top = 0; window.ShowActivated = false; window.Show(); }
        Pump(); window.UpdateLayout(); Pump();
        var content = (FrameworkElement)window.Content;
        var w = (int)Math.Max(1, content.ActualWidth); var h = (int)Math.Max(1, content.ActualHeight);
        var shot = new RenderTargetBitmap(w, h, 96, 96, PixelFormats.Pbgra32);
        var back = new DrawingVisual(); using (var dc = back.RenderOpen()) dc.DrawRectangle((Brush)Application.Current.FindResource("Background"), null, new Rect(0, 0, w, h));
        shot.Render(back); shot.Render(content);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(shot));
        using (var file = File.Create(path)) encoder.Save(file);
        if (!shown) window.Close();
    }
    private static void Png(string path, Color colour)
    {
        var visual = new DrawingVisual(); using (var dc = visual.RenderOpen()) dc.DrawRectangle(new SolidColorBrush(colour), null, new Rect(0, 0, 80, 60));
        var bitmap = new RenderTargetBitmap(80, 60, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap)); using var stream = File.Create(path); encoder.Save(stream);
    }
}
