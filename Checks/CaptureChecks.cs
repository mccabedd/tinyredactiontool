using System.IO;
using System.Security.Cryptography;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;
using Drawing = System.Drawing;

// 0.12.0: the capture bar, screenshots, screen recording, the capture folder and Original.
internal static class CaptureChecks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static void Wait(Func<Task> operation)
    {
        Task? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(2);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("Capture check timed out.");
        task.GetAwaiter().GetResult();
    }
    private static BitmapSource Picture(int width, int height, byte blue, byte green, byte red)
    {
        var pixels = new byte[width * height * 4];
        for (var i = 0; i < pixels.Length; i += 4) { pixels[i] = blue; pixels[i + 1] = green; pixels[i + 2] = red; pixels[i + 3] = 255; }
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgr32, null, pixels, width * 4); image.Freeze(); return image;
    }
    private static string Sha(string path) => Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(path)));
    [System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
    [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
    private static extern bool CreateHardLink(string newName, string existing, IntPtr security);

    public static void RunModel(string output, Action<bool, string> check)
    {
        // Selection geometry.
        check(ScreenCapture.Normalize(new(50, 40), new(10, 20)) == new Drawing.Rectangle(10, 20, 40, 20), "a selection dragged up and left is the same area as one dragged down and right");
        check(ScreenCapture.EvenSize(new(3, 5, 101, 77)) == new Drawing.Rectangle(3, 5, 100, 76), "a recording area is trimmed inward to even sizes (never outside the selection)");
        var windows = new List<ScreenCapture.WindowTarget>
        {
            new(1, new(100, 100, 400, 300), [new(120, 150, 200, 100), new(130, 160, 50, 30)]),
            new(2, new(0, 0, 1000, 800), []),
        };
        check(ScreenCapture.Pick(windows, new(140, 170), false) == new Drawing.Rectangle(100, 100, 400, 300), "Window capture picks the frontmost window under the pointer");
        check(ScreenCapture.Pick(windows, new(140, 170), true) == new Drawing.Rectangle(130, 160, 50, 30) && ScreenCapture.Pick(windows, new(300, 380), true) == new Drawing.Rectangle(100, 100, 400, 300),
            "Object capture picks the smallest control under the pointer, or the whole window outside its controls");
        check(ScreenCapture.Pick(windows, new(900, 700), true) == new Drawing.Rectangle(0, 0, 1000, 800) && ScreenCapture.Pick(windows, new(2000, 10), true) == null, "behind a window the next window is picked; off every window nothing is");

        // Freehand: inside kept, outside white, cropped to the outline.
        using (var source = new Drawing.Bitmap(60, 40, Drawing.Imaging.PixelFormat.Format32bppRgb))
        {
            using (var g = Drawing.Graphics.FromImage(source)) g.Clear(Drawing.Color.FromArgb(200, 30, 30));
            using var cut = ScreenCapture.CropFreehand(source, [new(10, 5), new(50, 5), new(30, 35)]);
            var inside = cut.GetPixel(20, 5); var outside = cut.GetPixel(1, 28); var outsideToo = cut.GetPixel(9, 28);
            check(cut.Width == 41 && cut.Height == 31 && inside.R == 200 && inside.G == 30 && inside.A == 255 && outside.A == 0 && outsideToo.A == 0 && outside.R == 0 && outside.G == 0 && outside.B == 0,
                "a freehand capture keeps the picture inside the outline (opaque) and is transparent outside, with nothing hidden under it (0.22.1), cropped to the outline");
            var wpf = ScreenCapture.ToBitmapSource(source);
            var pixel = new byte[4]; wpf.CopyPixels(new Int32Rect(5, 5, 1, 1), pixel, 4, 0);
            check(wpf.PixelWidth == 60 && wpf.PixelHeight == 40 && wpf.DpiX == 96 && pixel[2] == 200 && pixel[1] == 30 && pixel[0] == 30, "a capture becomes a pixel-exact picture at 96 DPI");
        }
        // A real grab of a small screen area (the content depends on the screen; the size must not).
        var screen = ScreenCapture.VirtualScreen;
        using (var grab = ScreenCapture.Grab(new(screen.X, screen.Y, 37, 23), true))
            check(screen.Width > 0 && grab.Width == 37 && grab.Height == 23, "a screen grab returns exactly the requested pixels, in real screen pixels");

        // Capture folder.
        var temp = Path.Combine(output, "capture-store"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        using (var store = new CaptureStore(temp))
        {
            var first = store.NewFile("SCREENSHOT", ".png"); var second = store.NewFile("SCREENSHOT", ".png");
            File.WriteAllBytes(first, [1, 2, 3]); File.WriteAllBytes(second, [4, 5, 6]);
            check(first != second && Path.GetDirectoryName(first) == store.Root && Path.GetFileName(store.Root!).StartsWith(CaptureStore.FolderPrefix) && Path.GetFileName(first).StartsWith("SCREENSHOT_") && store.Owns(first),
                "captures get their own names in a private TRT folder in the temporary folder");
            check(CaptureStore.AbandonedFolders(temp).Count == 0, "a running session's capture folder is not taken for a leftover");
            var outsider = Path.Combine(temp, "not-a-capture.png"); File.WriteAllBytes(outsider, [9]);
            var refused = false; try { store.Wipe(outsider); } catch (IOException) { refused = true; }
            check(refused && File.Exists(outsider), "TRT refuses to wipe a file it did not capture");
            CaptureStore.ZeroFill(first, store.Root!);
            check(File.ReadAllBytes(first).SequenceEqual(new byte[3]), "wiping first overwrites a capture with zeros and checks them");
            store.Wipe(first);
            check(!File.Exists(first) && !store.Owns(first), "then the capture is deleted");
            var link = Path.Combine(output, "capture-store-link.bin"); if (File.Exists(link)) File.Delete(link);
            check(CreateHardLink(link, second, IntPtr.Zero), "test setup: a second name for a capture");
            refused = false; try { store.Wipe(second); } catch (IOException) { refused = true; }
            check(refused && File.ReadAllBytes(second).SequenceEqual(new byte[] { 4, 5, 6 }) && File.ReadAllBytes(link).SequenceEqual(new byte[] { 4, 5, 6 }), "TRT refuses to wipe a capture that also has another name, so nothing elsewhere is overwritten");
            File.Delete(link);
            store.MarkKept(second);
            check(store.IsKept(second) && store.Unkept.Count == 0, "a saved or exported capture is remembered as kept");
            check(store.WipeAll().Count == 0 && !File.Exists(second) && store.Root == null && !Directory.Exists(Path.GetDirectoryName(second)), "quitting wipes every capture and removes TRT's capture folder");
        }
        // Leftovers from a session that did not close normally: only TRT's own capture names are wiped.
        var leftover = Path.Combine(temp, CaptureStore.FolderPrefix + "leftover"); Directory.CreateDirectory(leftover);
        File.WriteAllBytes(Path.Combine(leftover, ".session.lock"), []); File.WriteAllBytes(Path.Combine(leftover, "RECORDING_20260101_000000.mp4"), [7, 7]); File.WriteAllBytes(Path.Combine(leftover, "notes.txt"), [1]);
        check(CaptureStore.AbandonedFolders(temp).SequenceEqual([leftover]), "a capture folder whose session has ended is found at start-up");
        check(CaptureStore.WipeAbandoned(leftover) == 1 && !File.Exists(Path.Combine(leftover, "RECORDING_20260101_000000.mp4")) && File.Exists(Path.Combine(leftover, "notes.txt")),
            "leftover cleanup wipes TRT's captures and leaves other files alone");

        // Settings.
        var savedPath = AppSettings.Path;
        try
        {
            AppSettings.Path = Path.Combine(output, "capture-settings-model.json");
            var defaults = new AppSettings();
            check(defaults.Output == CaptureOutput.Editor && !defaults.CaptureMousePointer && defaults.CaptureDelaySeconds == 0 && defaults.RecordingFramesPerSecond == 15 && defaults.RecordMousePointer && !defaults.CloseButtonQuits && defaults.RecordingArea == RecordingArea.Region,
                "capture defaults: to the editor, no pointer in screenshots, no delay, 15 frames per second with the pointer, ✕ hides TRT in the notification area");
            new AppSettings { Output = CaptureOutput.File, CaptureDelaySeconds = 3, RecordingFramesPerSecond = 25, CloseButtonQuits = true, RecordingArea = RecordingArea.Window }.Save();
            check(AppSettings.Load() is { Output: CaptureOutput.File, CaptureDelaySeconds: 3, RecordingFramesPerSecond: 25, CloseButtonQuits: true, RecordingArea: RecordingArea.Window } && File.ReadAllText(AppSettings.Path).Contains("\"File\""),
                "capture settings are saved (in words) and read back");
            File.WriteAllText(AppSettings.Path, JsonSerializer.Serialize(new { CaptureDelaySeconds = 7, RecordingFramesPerSecond = 1000 }));
            check(AppSettings.Load() is { CaptureDelaySeconds: 0, RecordingFramesPerSecond: 15 }, "values the Settings window cannot offer fall back to the defaults");
        }
        finally { AppSettings.Path = savedPath; }
    }

    public static void RunUi(string output, Action<bool, string> check)
    {
        var savedPath = AppSettings.Path;
        AppSettings.Path = Path.Combine(output, "capture-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var temp = Path.Combine(output, "capture-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var previousClipboard = ClipboardRetry.Text();
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        string? asked = null; var answer = true;
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, text, _) => { asked = text; return answer; } };
        controller.Ask = (_, text, _) => { asked = text; return false; };
        try
        {
            controller.Start();
            var bar = controller.Bar!; bar.Left = -20000; bar.UpdateLayout();
            T Find<T>(string name) => (T)bar.FindName(name);
            var names = Find<StackPanel>("CaptureButtons").Children.OfType<Button>().Select(b => b.Name).ToArray();
            check(names.SequenceEqual(["RegionButton", "FreehandButton", "ActiveWindowButton", "WindowObjectButton", "FullScreenButton", "ScrollingButton", "RecorderButton", "EditorButton", "OutputButton", "MenuButton"]),
                "the capture bar starts with David's buttons in his order (0.27.0): rectangle, freehand, active window, window/object, full screen, scrolling window, recorder, then editor, output and menu (the Ruler is off)");
            check(bar.IsVisible && bar.Topmost && bar.WindowStyle == WindowStyle.None && Find<TextBlock>("TitleText").Text == "TinyRedactionTool" && Find<Button>("MinimiseButton").IsVisible && Find<Button>("CloseButton").IsVisible,
                "the capture bar is a small always-on-top panel with its own title row, – and ✕");
            check((string)Find<Button>("RegionButton").ToolTip == "Capture a Rectangle: Drag Round the Area" && (string)Find<Button>("RecorderButton").ToolTip == "Record the Screen as a Video" && Find<StackPanel>("CaptureButtons").Children.OfType<Button>().All(b => b.ToolTip != null),
                "every capture button has a tooltip, in David's shorter wording (0.21.3)");
            controller.SetOutput(CaptureOutput.Clipboard);
            check(Toolbar.GetIcon(Find<Button>("OutputButton")) == bar.FindResource("IconToClipboard") && Find<MenuItem>("ToClipboardItem").IsChecked && !Find<MenuItem>("ToEditorItem").IsChecked && AppSettings.Load().Output == CaptureOutput.Clipboard,
                "choosing To Clipboard changes the Output button's picture and is remembered");

            // To the clipboard: the picture as captured, no file left behind.
            Wait(() => controller.DeliverAsync(Picture(64, 48, 10, 200, 30)));
            var copied = Clipboard.GetImage();
            check(copied != null && copied.PixelWidth == 64 && copied.PixelHeight == 48 && controller.Store.Files.Count == 0 && controller.LastNotice == "Copied to the clipboard", "To Clipboard copies the screenshot and keeps no file");

            // To the editor.
            controller.SetOutput(CaptureOutput.Editor);
            Wait(() => controller.DeliverAsync(Picture(80, 50, 30, 30, 200)));
            var editor = controller.Editor!;
            T E<T>(string name) => (T)editor.FindName(name);
            var preview = E<PreviewSurface>("Preview");
            var firstCapture = preview.Project.Media?.Path;
            check(firstCapture != null && controller.Store.Owns(firstCapture) && File.Exists(firstCapture) && preview.Image?.PixelWidth == 80 && Path.GetFileName(firstCapture).StartsWith("SCREENSHOT_"),
                "To Editor opens the screenshot in the editor from TRT's capture folder");
            check(E<MenuItem>("OriginalMenuItem").IsEnabled && E<MenuItem>("CaptureMenu").IsVisible && E<MenuItem>("QuitMenuItem").Visibility == Visibility.Visible && ((string)E<Button>("OriginalButton").ToolTip).Contains("as Captured, Without Edits"),
                "the editor shows Original and a Capture menu for a capture");

            // A second capture while the first is unsaved: the editor asks; keeping the first wipes the new one.
            answer = false; asked = null;
            Wait(() => controller.DeliverAsync(Picture(40, 30, 0, 0, 0)));
            check(asked != null && preview.Project.Media?.Path == firstCapture && controller.Store.Files.Count == 1, "a new capture asks before replacing an unsaved one, and keeping the current one leaves it open (the new one is offered for saving, then wiped)");
            answer = true;

            // Original: save a verified copy, copy, and wipe TRT's capture; the editor carries on with the copy.
            var annotation = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(5, 5, 20, 20), Width = 2, Color = "#FF0000", Order = 1 };
            preview.Project.Annotations.Add(annotation);
            var kept = Path.Combine(output, "kept-original.png"); if (File.Exists(kept)) File.Delete(kept);
            var hash = preview.Project.Media!.Sha256;
            bool result = false; Wait(async () => result = await editor.KeepOriginalAsync(kept, true, true));
            check(result && File.Exists(kept) && Sha(kept) == hash && !File.Exists(firstCapture) && controller.Store.Files.Count == 0,
                "Original saves a copy identical to the capture, then wipes TRT's capture");
            check(preview.Project.Media?.Path == Path.GetFullPath(kept) && preview.Project.Annotations.Contains(annotation) && !E<MenuItem>("OriginalMenuItem").IsEnabled,
                "after wiping, the editor carries on with the saved copy and keeps the annotations");
            var clip = Clipboard.GetImage();
            check(clip != null && clip.PixelWidth == 80 && clip.PixelHeight == 50, "Original copies the screenshot as captured to the clipboard");
            var decoded = BitmapDecoder.Create(new Uri(kept), BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad).Frames[0];
            var pixel = new byte[4]; new FormatConvertedBitmap(decoded, PixelFormats.Bgra32, null, 0).CopyPixels(new Int32Rect(10, 5, 1, 1), pixel, 4, 0);
            check(pixel[2] == 200 && pixel[0] == 30, "the saved original has no annotation in it");

            // Clearing an unsaved capture asks first and wipes it.
            preview.Project.Annotations.Clear();
            typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, null);
            Wait(() => controller.DeliverAsync(Picture(30, 20, 90, 90, 90)));
            var second = preview.Project.Media!.Path;
            asked = null;
            typeof(MainWindow).GetMethod("Clear", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, [editor, new RoutedEventArgs()]); Pump();
            check(asked?.Contains("has not been saved or exported") == true && preview.Project.Media == null && !File.Exists(second) && controller.Store.Files.Count == 0, "clearing an unsaved screenshot asks first, then wipes it");

            // Original without saving, and closing the editor.
            Wait(() => controller.DeliverAsync(Picture(30, 20, 90, 90, 90)));
            var third = preview.Project.Media!.Path;
            Wait(async () => result = await editor.KeepOriginalAsync(null, false, true));
            check(result && preview.Project.Media == null && !File.Exists(third), "Original can wipe a capture without saving (after asking) and closes it");
            Wait(() => controller.DeliverAsync(Picture(30, 20, 90, 90, 90)));
            var fourth = preview.Project.Media!.Path;
            editor.Close(); Pump();
            check(controller.Editor == null && !File.Exists(fourth), "closing the editor wipes the capture it was showing");
            check(controller.Bar!.IsVisible, "closing the editor leaves the capture bar running");

            // The dialogs.
            var keep = new KeepCaptureWindow(true, @"C:\Videos\RECORDING_1.mp4", null);
            ((CheckBox)keep.FindName("SaveBox")).IsChecked = false; ((CheckBox)keep.FindName("CopyBox")).IsChecked = true;
            check(!((Button)keep.FindName("OkButton")).IsEnabled && ((TextBlock)keep.FindName("Message")).Text.Contains("also save"), "copying a recording needs a saved copy (the clipboard holds the file)");
            ((CheckBox)keep.FindName("CopyBox")).IsChecked = false; ((CheckBox)keep.FindName("DeleteBox")).IsChecked = true;
            check(((Button)keep.FindName("OkButton")).IsEnabled && ((TextBlock)keep.FindName("Message")).Text.Contains("closes it in the editor"), "deleting without saving explains that the capture closes");
            keep.Close();
            var blocked = new KeepCaptureWindow(false, @"C:\Pictures\SCREENSHOT_1.png", "Your organisation's policy turns off deleting originals.");
            check(!((CheckBox)blocked.FindName("DeleteBox")).IsEnabled && ((CheckBox)blocked.FindName("DeleteBox")).IsChecked != true && ((CheckBox)blocked.FindName("SaveBox")).IsChecked == true,
                "deleting is off by default and unavailable when policy forbids it");
            blocked.Close();
            var recorderWindow = new RecorderWindow(new AppSettings { RecordingArea = RecordingArea.FullScreen, RecordingFramesPerSecond = 20, RecordMousePointer = false });
            check(((RadioButton)recorderWindow.FindName("FullScreenChoice")).IsChecked == true && recorderWindow.FramesPerSecond == 20 && !recorderWindow.MousePointer, "the Screen Recorder window starts from the last choices");
            ((RadioButton)recorderWindow.FindName("WindowChoice")).IsChecked = true; ((CheckBox)recorderWindow.FindName("PointerChoice")).IsChecked = true;
            recorderWindow.Collect(); recorderWindow.Close();
            check(recorderWindow.Area == RecordingArea.Window && recorderWindow.MousePointer, "the Screen Recorder window returns the chosen area and pointer setting");
            var settings = new SettingsWindow(new AppSettings { CaptureDelaySeconds = 5, CloseButtonQuits = true });
            check(((ComboBox)settings.FindName("DelayChoice")).SelectedItem is 5 && ((RadioButton)settings.FindName("CloseQuitsBox")).IsChecked == true, "Settings shows the capture choices");
            ((ComboBox)settings.FindName("FrameRateChoice")).SelectedItem = 30; ((CheckBox)settings.FindName("CapturePointerBox")).IsChecked = true; ((ComboBox)settings.FindName("FullScreenChoice")).SelectedIndex = 1;
            var collected = settings.Collect(); settings.Close();
            check(collected is { RecordingFramesPerSecond: 30, CaptureMousePointer: true, FullScreenAllMonitors: true, CaptureDelaySeconds: 5, CloseButtonQuits: true }, "Settings returns the capture choices");

            // Policy: no deletion.
            using var strict = new CaptureController(new ManagedPolicy(DisableSourceDeletion: true), false, temp);
            strict.EditorFactory = () => new MainWindow(strict.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
            strict.Start(); strict.Bar!.Left = -20000;
            Wait(() => strict.DeliverAsync(Picture(30, 20, 90, 90, 90)));
            var guarded = (PreviewSurface)strict.Editor!.FindName("Preview");
            var capturePath = guarded.Project.Media!.Path; var copyPath = Path.Combine(output, "kept-policy.png"); if (File.Exists(copyPath)) File.Delete(copyPath);
            Wait(async () => result = await strict.Editor!.KeepOriginalAsync(copyPath, false, true));
            check(result && File.Exists(copyPath) && File.Exists(capturePath) && guarded.Project.Media.Path == capturePath, "with source deletion disabled by policy, Original saves but never wipes");
            strict.Editor!.Close(); Pump();
        }
        finally
        {
            AppSettings.Path = savedPath;
            if (controller.Editor is { } open) { open.ConfirmKeepQuestion = (_, _, _) => true; open.Close(); }
            controller.Store.WipeAll(); controller.Dispose();
            try { if (previousClipboard != null) Clipboard.SetText(previousClipboard); else Clipboard.Clear(); } catch (System.Runtime.InteropServices.COMException) { }
        }
    }

    // The recorder writes a real MP4 through the approved FFmpeg; paused time is left out.
    public static async Task RunMedia(MediaTools tools, string output, Action<bool, string> check)
    {
        var path = Path.Combine(output, "recording-check.mp4"); if (File.Exists(path)) File.Delete(path);
        var ffmpeg = Path.Combine(AppContext.BaseDirectory, "tools", "ffmpeg.exe");
        var refused = false; try { _ = new ScreenRecorder(ffmpeg, path, new(0, 0, 101, 60), 10, false); } catch (ArgumentException) { refused = true; }
        check(refused, "the recorder refuses an odd-sized area (H.264 needs even sizes)");
        var shade = 0;
        Drawing.Bitmap Frame()
        {
            var bitmap = new Drawing.Bitmap(96, 64, Drawing.Imaging.PixelFormat.Format32bppRgb);
            using var g = Drawing.Graphics.FromImage(bitmap); g.Clear(Drawing.Color.FromArgb(shade = (shade + 25) % 256, 80, 160));
            return bitmap;
        }
        using var recorder = new ScreenRecorder(ffmpeg, path, new(0, 0, 96, 64), 10, false, Frame);
        recorder.Start();
        await Task.Delay(1000); recorder.Pause();
        await Task.Delay(800); var pausedAt = recorder.Elapsed; await Task.Delay(300);
        check(recorder.IsPaused && recorder.Elapsed == pausedAt, "a paused recording's clock stands still");
        recorder.Resume(); await Task.Delay(500); recorder.RequestStop();
        await recorder.Completion.WaitAsync(TimeSpan.FromSeconds(60));
        check(recorder.Error == "" && File.Exists(path), "a recording is written by the approved FFmpeg without errors");
        var json = System.Text.Encoding.UTF8.GetString(await tools.RunAsync("ffprobe.exe", ["-v", "error", "-select_streams", "v:0", "-count_frames", "-show_entries", "stream=codec_name,width,height,nb_read_frames:format=nb_streams", "-of", "json", path], path, CancellationToken.None));
        using var doc = JsonDocument.Parse(json);
        var stream = doc.RootElement.GetProperty("streams")[0];
        var frames = int.Parse(stream.GetProperty("nb_read_frames").GetString()!);
        check(stream.GetProperty("codec_name").GetString() == "h264" && stream.GetProperty("width").GetInt32() == 96 && stream.GetProperty("height").GetInt32() == 64 && doc.RootElement.GetProperty("format").GetProperty("nb_streams").GetInt32() == 1,
            "the recording is an H.264 MP4 of the recorded area with one stream (no sound)");
        check(frames >= 12 && frames <= 20 && frames == recorder.FrameCount, $"the recording holds about 1.5 s at 10 frames per second; the 0.8 s pause is left out ({frames} frames)");
    }
}
