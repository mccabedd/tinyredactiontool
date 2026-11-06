using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.18.0: David's evening of feedback, first part (Settings redesign, start with Windows, capture bar
// on/off and shortcuts, red tab place, options bar, theme in Settings, empty-editor picture, drag and drop,
// About, tooltips, eyedropper and Default/Aggressive in the popup, Clear buttons beside Panel, Save media
// as, Capture frame, secure delete after export).
internal static class Release018Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(2);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.18.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static void WritePng(string path, int width, int height, byte grey)
    {
        var pixels = new byte[width * height * 4]; Array.Fill(pixels, grey);
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgr32, null, pixels, width * 4);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(image));
        using var file = File.Create(path); encoder.Save(file);
    }
    private static MainWindow Editor(ManagedPolicy? policy = null) =>
        new(policy ?? new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- Settings: five tabs, the new choices, four shortcuts. ----
        var settings = new SettingsWindow(new AppSettings { ShowCaptureBar = false, StripAtSetPlace = true, StripPositionPercent = 80, HideOptionsBar = true, BarShortcut = "" });
        var tabs = ((TabControl)settings.FindName("Tabs")).Items.Cast<TabItem>().Select(t => (string)t.Header).ToList();
        check(tabs.SequenceEqual(["General", "Shortcuts", "Capture", "Capture Bar", "Editor", "Slideshow", "Toolbar"]), "Settings is arranged in tabs: General, Shortcuts, Capture, Capture bar, Editor, (0.25.0) Slideshow and (0.24.1) Toolbar");
        check(((CheckBox)settings.FindName("ShowBarBox")).IsChecked == false && ((RadioButton)settings.FindName("StripSetPlaceBox")).IsChecked == true && ((Slider)settings.FindName("StripPositionSlider")).Value == 80 &&
              ((CheckBox)settings.FindName("HideOptionsBarBox")).IsChecked == true && ((TextBox)settings.FindName("BarShortcutBox")).Text == "None" && ((TextBox)settings.FindName("EditorShortcutBox")).Text == "Ctrl+Alt+E",
            "Settings shows the capture bar switch, the red tab's place, the options bar choice and the two new shortcuts");
        var editorBox = (TextBox)settings.FindName("EditorShortcutBox");
        check(!settings.TryShortcut(editorBox, System.Windows.Input.ModifierKeys.Control, System.Windows.Input.Key.Snapshot) && ((TextBlock)settings.FindName("ShortcutMessage")).Text.Contains("the screenshot"),
            "a shortcut already used by another action is refused, whichever box");
        check(settings.TryShortcut(editorBox, System.Windows.Input.ModifierKeys.Control | System.Windows.Input.ModifierKeys.Alt, System.Windows.Input.Key.D), "the editor shortcut can be changed");
        ((RadioButton)settings.FindName("ThemeDarkBox")).IsChecked = true; ((CheckBox)settings.FindName("ShowBarBox")).IsChecked = true;
        var chosen = settings.Collect(); settings.Close();
        check(chosen is { ShowCaptureBar: true, StripAtSetPlace: true, StripPositionPercent: 80, HideOptionsBar: true, BarShortcut: "", EditorShortcut: "Ctrl+Alt+D" } && settings.ThemeChosen == "Dark",
            "Settings returns the new choices, including the theme");

        // ---- Start with Windows: a per-user Run entry, written to a throw-away key here. ----
        var savedRun = StartupEntry.RunKey; StartupEntry.RunKey = @"Software\TinyRedactionToolChecks\Run";
        try
        {
            StartupEntry.Install();
            using (var key = Registry.CurrentUser.OpenSubKey(StartupEntry.RunKey))
                check(StartupEntry.IsInstalled && ((string?)key?.GetValue(StartupEntry.ValueName))?.EndsWith(" --startup") == true, "Start TRT when Windows starts adds a quiet (--startup) entry for this user");
            StartupEntry.Remove();
            check(!StartupEntry.IsInstalled, "clearing it removes the entry again");
        }
        finally { StartupEntry.RunKey = savedRun; Registry.CurrentUser.DeleteSubKeyTree(@"Software\TinyRedactionToolChecks", false); }

        // ---- Capture bar switched off, shortcuts' targets, red tab at a set place. ----
        var savedPath = AppSettings.Path;
        AppSettings.Path = Path.Combine(output, "release018-settings.json");
        File.WriteAllText(AppSettings.Path, "{\"ShowCaptureBar\":false,\"StripAtSetPlace\":true,\"StripPositionPercent\":100,\"StripWidth\":100,\"BarShortcut\":\"nonsense\"}");
        var temp = Path.Combine(output, "release018-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var controller = new CaptureController(new ManagedPolicy(), false, temp) { EditorFactory = () => Editor() };
        try
        {
            controller.Start();
            var bar = controller.Bar!;
            check(!bar.IsVisible && controller.Settings.BarShortcut == AppSettings.DefaultBarShortcut, "with the capture bar switched off, TRT starts without it (and a broken shortcut falls back to the default)");
            controller.ToggleBar(); Pump();
            check(bar.IsVisible, "the show/hide shortcut shows the bar");
            bar.Left = -20000;
            controller.ToggleBar(); Pump();
            check(!bar.IsVisible, "and hides it again");
            var area = new Rect(0, 0, 1000, 600);
            check(Math.Abs(controller.StripLeft(area) - 900) < .5, "the red tab can sit at a set place along the top edge (here the right-hand end)");
            var quiet = new CaptureController(new ManagedPolicy(), false, Path.Combine(temp, "quiet")) { EditorFactory = () => Editor() };
            Directory.CreateDirectory(Path.Combine(temp, "quiet"));
            File.WriteAllText(AppSettings.Path, "{}");
            quiet.Start(showBar: false);
            check(!quiet.Bar!.IsVisible, "started with Windows (--startup), TRT stays in the notification area");
            quiet.Dispose();
        }
        finally { AppSettings.Path = savedPath; controller.Store.WipeAll(); controller.Dispose(); }

        // ---- The editor. ----
        var still = Path.Combine(output, "release018-still.png"); WritePng(still, 160, 120, 140);
        var window = Editor(); window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        void Refresh() { typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null); window.UpdateLayout(); }
        try
        {
            // Empty editor: the picture of a video and a picture page, not a sentence.
            window.UpdateLayout();
            var shot = new RenderTargetBitmap((int)preview.ActualWidth, (int)preview.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(preview);
            var pixels = new byte[shot.PixelWidth * shot.PixelHeight * 4]; shot.CopyPixels(pixels, shot.PixelWidth * 4, 0);
            var inked = 0; for (var i = 0; i < pixels.Length; i += 4) if (pixels[i] < 0xA0) inked++;
            check(inked > 3000, "the empty editor shows the overlapping-files picture");

            // Drag and drop: one supported file only.
            var data = new DataObject(DataFormats.FileDrop, new[] { still });
            check(MainWindow.DroppedMedia(data) == still && MainWindow.DroppedMedia(new DataObject(DataFormats.FileDrop, new[] { still, still })) == null &&
                  MainWindow.DroppedMedia(new DataObject(DataFormats.FileDrop, new[] { Path.Combine(output, "notes.txt") })) == null, "dropping one picture or video opens it; other drops are refused");
            check(window.AllowDrop, "the editor accepts dropped files");

            // About and tooltips.
            check(System.Text.RegularExpressions.Regex.IsMatch(MainWindow.AboutText, @"^TinyRedactionTool \d+\.\d+\.\d+\n") && MainWindow.AboutText.EndsWith(AboutWindow.Description), "the About box names the version and gives David's description (0.27.1)");
            ToolTipTiming.Apply();
            check(ToolTipService.GetInitialShowDelay(new Button()) == 250, "tooltips appear after a quarter of a second");

            // Clear buttons beside Panel; no theme switch; options bar can be hidden (but shows for cropping).
            check(window.FindName("ThemeToggle") == null && Find<StackPanel>("RightTools").Children.Contains(Find<Button>("ClearScreenButton")), "the Clear buttons sit beside Panel; the theme switch is gone");
            window.ApplySettings(new AppSettings { HideOptionsBar = true }); window.UpdateLayout();
            check(!Find<Border>("OptionsBar").IsVisible, "the options bar can be hidden");
            Wait(() => window.OpenPathAsync(still)); Refresh();
            Find<Button>("CropTool").RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump();
            // 0.21.4 (David): cropping has its own window, so a hidden options bar stays hidden.
            check(!Find<Border>("OptionsBar").IsVisible, "a hidden options bar stays hidden while cropping");
            Find<Button>("SelectToolButton").RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump();
            check(!Find<Border>("OptionsBar").IsVisible, "and goes away again after cropping");
            window.ApplySettings(new AppSettings()); window.UpdateLayout();

            // Popup: eyedropper for a coloured box; Default/Aggressive for Blur and Pixelate.
            var box = new Region { Name = "Box", Start = 0, End = 0 }; box.PutManual(0, new(20, 20, 40, 30));
            preview.Project.Regions.Add(box); preview.Selected = box; Refresh();
            check(Find<Button>("PopupEyedropper").IsVisible && !Find<ComboBox>("PopupEffectMode").IsVisible, "a coloured box's popup has the eyedropper beside its colour");
            box.Effect = RedactionEffect.Blur; Refresh();
            var mode = Find<ComboBox>("PopupEffectMode");
            check(mode.IsVisible && !Find<Button>("PopupEyedropper").IsVisible, "a Blur or Pixelate popup offers Default / Aggressive");
            mode.SelectedIndex = 1; Pump();
            check(Find<ComboBox>("EffectMode").SelectedIndex == 1, "choosing Aggressive in the popup sets it");
            check(Toolbar.GetIconFill(Find<Button>("EyedropperButton")) != null && Toolbar.GetAccentBrush(Find<Button>("PopupEyedropper")) == Find<Border>("ColorSwatchFill").Background,
                "the eyedropper is design D: a solid pipette and a swatch of the chosen colour");
            preview.Selected = null; preview.Project.Regions.Clear(); Refresh();

            // Save media as: the file exactly as it is.
            var copy = Path.Combine(output, "release018-copy.png"); if (File.Exists(copy)) File.Delete(copy);
            preview.Project.Regions.Add(box); Refresh();
            check(Wait(() => window.SaveMediaAsAsync(copy)) && File.ReadAllBytes(copy).AsSpan().SequenceEqual(File.ReadAllBytes(still)), "Save media as… saves the picture as it is, without redactions or edits");
            check(!Wait(() => window.SaveMediaAsAsync(still)) && File.Exists(still), "it never replaces the original");

            // Secure delete after export (asked once more; overwrites, then deletes).
            check(Find<CheckBox>("DeleteOriginalBox").IsEnabled, "the Panel offers Securely delete the original after export");
            var victim = Path.Combine(output, "release018-delete-me.png"); WritePng(victim, 64, 48, 90);
            Wait(() => window.OpenPathAsync(victim));
            window.ConfirmKeepQuestion = (_, _, _) => false;
            check(!Wait(() => window.SecurelyDeleteOriginalAsync(copy)) && File.Exists(victim) && preview.Project.Media != null, "answering No keeps the original");
            window.ConfirmKeepQuestion = (_, _, _) => true;
            check(Wait(() => window.SecurelyDeleteOriginalAsync(copy)) && !File.Exists(victim) && preview.Project.Media == null, "answering Yes securely deletes the original and clears the editor");
            var linked = Path.Combine(output, "release018-linked.png"); var second = Path.Combine(output, "release018-second-name.png");
            foreach (var f in new[] { linked, second }) if (File.Exists(f)) File.Delete(f);
            WritePng(linked, 32, 32, 50); CreateHardLink(second, linked, IntPtr.Zero);
            var refused = false; try { CaptureStore.OverwriteAndDelete(linked, output); } catch (IOException) { refused = true; }
            check(refused && File.Exists(linked) && File.ReadAllBytes(second).Length > 0, "secure deletion refuses a file with a second name, whose contents live on elsewhere");
        }
        finally { preview.Project = new(); preview.Selected = null; window.Close(); }
        var strict = Editor(new ManagedPolicy(DisableSourceDeletion: true)); strict.Show();
        Wait(() => strict.OpenPathAsync(still));
        check(!((CheckBox)strict.FindName("DeleteOriginalBox")).IsEnabled, "with source deletion turned off by policy, the option can't be ticked");
        strict.Close();

        // ---- Capture frame from a video. ----
        var fixture = Task.Run(async () =>
        {
            var path = await TrackingChecks.WriteVideo(tools, output, false);
            var map = await tools.ProbeTimelineAsync(path, CancellationToken.None);
            var media = new MediaReference(path, new FileInfo(path).Length, await ProjectStore.HashAsync(path), 128, 96, map.Frames[^1].Time + map.Frames[^1].Duration, true);
            return (map, media, image: await tools.FrameAsync(path, map.Frames[2], null, CancellationToken.None));
        }).GetAwaiter().GetResult();
        var video = Editor(); video.Show();
        var videoPreview = (PreviewSurface)video.FindName("Preview");
        try
        {
            videoPreview.Project = new() { Media = fixture.media }; videoPreview.Timeline = fixture.map; videoPreview.Image = fixture.image; videoPreview.Time = fixture.map.Frames[2].Time;
            typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(video, null);
            check(((MenuItem)video.FindName("CaptureFrameMenuItem")).IsEnabled && ((Button)video.FindName("CaptureFrameButton")).IsVisible, "a video offers Capture frame (File menu and a camera button by the playback controls)");
            var framePath = Path.Combine(output, "release018-frame.png"); if (File.Exists(framePath)) File.Delete(framePath);
            video.FrameQuestion = () => (MainWindow.FrameUse.Save, false);
            check(Wait(() => video.CaptureFrameAsync(framePath)) && File.Exists(framePath), "Capture frame saves the frame on screen as a picture");
            var saved = BitmapFrame.Create(new Uri(framePath), BitmapCreateOptions.IgnoreImageCache, BitmapCacheOption.OnLoad);
            check(saved.PixelWidth == 128 && saved.PixelHeight == 96, "the captured frame is the video's full size");
        }
        finally { videoPreview.Project = new(); video.Close(); }

        // Leftover captures from a crash: pasted pictures and captured frames are wiped too.
        var abandoned = Path.Combine(output, "release018-abandoned"); if (Directory.Exists(abandoned)) Directory.Delete(abandoned, true); Directory.CreateDirectory(abandoned);
        foreach (var name in new[] { "PASTED_1.png", "FRAME_1.png", "keep.txt" }) File.WriteAllBytes(Path.Combine(abandoned, name), [1, 2, 3]);
        check(CaptureStore.WipeAbandoned(abandoned) == 2 && File.Exists(Path.Combine(abandoned, "keep.txt")), "leftover pasted pictures and captured frames are wiped after a crash; other files are left alone");
    }
    [System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
    [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
    private static extern bool CreateHardLink(string newName, string existing, IntPtr security);
}
