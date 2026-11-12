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
using Drawing = System.Drawing;

// 0.14.0: David's list after trying 0.13.0 (drop-down text, a ruler and docking capture
// bar, capture bar buttons and red tab in Settings, Copy/Paste, toolbar order, Clear Editor, no Review).
internal static class Release014Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static void Wait(Func<Task> operation)
    {
        Task? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(2);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.14.0 check timed out.");
        task.GetAwaiter().GetResult();
    }
    // Lets timers and animations run until the condition holds (or a few seconds pass).
    private static bool WaitFor(Func<bool> condition, double seconds = 4)
    {
        var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddSeconds(seconds);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(20) };
        timer.Tick += (_, _) => { if (condition() || DateTime.UtcNow >= deadline) frame.Continue = false; };
        timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        return condition();
    }
    private static (byte B, byte G, byte R) PixelAt(BitmapSource image, int x, int y)
    {
        var bgra = new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0); var pixel = new byte[4];
        bgra.CopyPixels(new Int32Rect(x, y, 1, 1), pixel, 4, 0); return (pixel[0], pixel[1], pixel[2]);
    }
    private static IEnumerable<DependencyObject> Descendants(DependencyObject parent)
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        { var child = VisualTreeHelper.GetChild(parent, i); yield return child; foreach (var nested in Descendants(child)) yield return nested; }
    }

    public static void Run(string output, Action<bool, string> check)
    {
        // ---- Drop-downs of numbers show their numbers (Screen Recorder frames per second, Settings). ----
        var recorder = new RecorderWindow(new AppSettings()) { Left = -20000, ShowInTaskbar = false };
        recorder.Show();
        var rates = (ComboBox)recorder.FindName("FrameRateChoice");
        rates.IsDropDownOpen = true; Pump(); rates.UpdateLayout();
        var rows = Enumerable.Range(0, rates.Items.Count).Select(i => rates.ItemContainerGenerator.ContainerFromIndex(i) as ComboBoxItem).ToList();
        var texts = rows.Select(r => r == null ? null : Descendants(r).OfType<TextBlock>().FirstOrDefault()?.Text).ToList();
        rates.IsDropDownOpen = false; recorder.Close();
        check(texts.Count == AppSettings.FrameRates.Length && texts.SequenceEqual(AppSettings.FrameRates.Select(f => f.ToString())),
            "the frames-per-second drop-down lists its numbers (they were blank before)");

        // ---- The ruler's measuring tools, worked out on a small picture. ----
        using (var picture = new Drawing.Bitmap(400, 300))
        using (var overlay = new MeasureOverlay(picture, new Drawing.Rectangle(0, 0, 400, 300), MeasureKind.Distance))
        {
            overlay.Press(new(10, 10)); overlay.Track(new(110, 10)); overlay.Release(new(110, 10));
            check(overlay.Result == "D=100 px", "the ruler's Distance tool measures between two points (D=100 px)");
            check(MeasureOverlay.Straight(new(0, 0), new(100, 7)) == new Drawing.Point(100, 0) && MeasureOverlay.Straight(new(0, 0), new(50, 47)).X == MeasureOverlay.Straight(new(0, 0), new(50, 47)).Y,
                "holding Shift keeps a measured line straight (level, upright or at 45°)");
        }
        using (var picture = new Drawing.Bitmap(400, 300))
        using (var overlay = new MeasureOverlay(picture, new Drawing.Rectangle(0, 0, 400, 300), MeasureKind.Rectangle))
        {
            overlay.Press(new(10, 10)); overlay.Track(new(59, 29)); overlay.Release(new(59, 29));
            check(overlay.Result == "W × H = 50 × 20 px", "the ruler's Rectangle tool gives width × height in pixels");
        }
        using (var picture = new Drawing.Bitmap(400, 300))
        using (var overlay = new MeasureOverlay(picture, new Drawing.Rectangle(0, 0, 400, 300), MeasureKind.Angle))
        {
            overlay.Press(new(100, 100)); overlay.Track(new(150, 120));
            var first = overlay.Result;
            overlay.Press(new(200, 100)); overlay.Track(new(100, 0)); overlay.Press(new(100, 0)); overlay.Track(new(300, 290));
            check(first == "Protractor" && overlay.AngleFixed && overlay.Result == "Angle = 90°", "the ruler's protractor: click the centre, then the two line ends, and it shows the angle (90°)");
            check(Math.Abs(MeasureOverlay.Angle(new(0, 0), new(10, 0), new(-10, -10)) - 135) < .001, "angles are measured the short way round (0–180°)");
        }

        // ---- Capture bar, ruler and Settings through the capture controller. ----
        var savedPath = AppSettings.Path;
        AppSettings.Path = Path.Combine(output, "release014-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var temp = Path.Combine(output, "release014-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        var savedDelay = CaptureController.HideDelay;
        var previousClipboard = ClipboardRetry.Text();
        try
        {
            controller.Start();
            var bar = controller.Bar!;

            // The ruler: ticks and numbers, the pointer's position, measuring a span, turning, tools.
            controller.ShowRuler();
            var ruler = controller.Ruler!;
            check(ruler.Visible && ruler.TopMost && ruler.Width == ruler.Length && ruler.Height == ruler.Thickness, "the screen ruler opens on top, horizontal");
            ruler.SetPointer(124);
            check(ruler.Readout == "124 px", "the ruler shows how far along it the pointer is (124 px)");
            ruler.MeasureSpan(150, 249);
            check(ruler.Readout == "D=99 px", "dragging along the ruler's edge measures a span (D=99 px)");
            var grip = ruler.HitTest(new(2, ruler.Thickness / 2)); var end = ruler.HitTest(new(ruler.Width - 2, ruler.Thickness / 2));
            var edge = ruler.HitTest(new(ruler.Width / 2, 2));
            check(grip == RulerPart.StartGrip && end == RulerPart.EndGrip && edge == RulerPart.Scale, "the ruler has grips at both ends for its length, and edges for measuring");
            var length = ruler.Length;
            ruler.SetLength(10);
            check(ruler.Length > 10 && ruler.Length < length, "the ruler cannot be made shorter than its tools");
            ruler.SetLength(length);
            ruler.Press(RulerPart.Turn);
            check(ruler.IsVertical && ruler.Height == ruler.Length && ruler.Width == ruler.Thickness && ruler.HitTest(new(ruler.Thickness / 2, 2)) == RulerPart.StartGrip, "the arrows button turns the ruler upright");
            ruler.Turn();
            MeasureKind? opened = null;
            controller.ShowMeasureOverlay = overlay => { opened = (MeasureKind)typeof(MeasureOverlay).GetField("kind", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.GetValue(overlay)!; return true; };
            ruler.Press(RulerPart.Angle);
            check(opened == MeasureKind.Angle, "the ruler's tool buttons open the measuring screen (here the protractor)");
            ruler.Press(RulerPart.Close); Pump();
            check(controller.Ruler == null, "the ruler's ✕ closes it");

            // Capture bar buttons: only the chosen ones, in the chosen order, with Menu last.
            var settings = controller.Settings.Copy();
            settings.BarButtons = ["Ruler", "Region", "Editor"];
            controller.Apply(settings); bar.UpdateLayout();
            var shown = ((StackPanel)bar.FindName("CaptureButtons")).Children.Cast<UIElement>().Select(c => c is Button b ? (string)b.Content : "|").ToList();
            check(shown.SequenceEqual(["Screen Ruler", "|", "Capture Rectangular Region", "|", "Open the Editor", "Menu"]),
                "the capture bar shows only the buttons chosen in Settings, in that order, with separators between groups and Menu last");
            settings = controller.Settings.Copy(); settings.BarButtons = [.. AppSettings.BarButtonIds]; settings.StripWidth = 150; controller.Apply(settings);

            // Docking: dropped at the top edge, the bar sticks there, hides into the red tab and comes back.
            CaptureController.HideDelay = TimeSpan.Zero;
            var area = CaptureController.WorkAreaOf(bar);
            bar.Left = area.Left + 200; bar.Top = area.Top + 6;
            controller.BarMoved();
            check(controller.BarDocked && Math.Abs(bar.Top - area.Top) < .5, "a bar dropped near the top edge of the screen docks there");
            controller.WatchDockedBar(true);
            var hidden = WaitFor(() => !bar.IsVisible && controller.Strip is { IsVisible: true });
            var strip = controller.Strip!;
            check(hidden && Math.Abs(strip.Width - 150) < .5 && Math.Abs(strip.Left - bar.Left) < .5 && Math.Abs(strip.Top - area.Top) < .5,
                "the docked bar slides up out of sight and leaves a red tab of the chosen width under its left end");
            strip.RaiseEvent(new MouseEventArgs(Mouse.PrimaryDevice, 0) { RoutedEvent = Mouse.MouseEnterEvent });
            var back = WaitFor(() => bar.IsVisible && !controller.BarSliding && Math.Abs(bar.Top - area.Top) < .5);
            check(back && !strip.IsVisible, "pointing at the red tab slides the bar back down");
            bar.Top = area.Top + 200; controller.BarMoved();
            check(!controller.BarDocked, "dragging the bar away from the top edge undocks it");
            bar.Left = -20000;

            // Settings: tick and order the bar's buttons; the red tab's width.
            var start = new AppSettings { BarButtons = ["Region", "Ruler"], StripWidth = 200 };
            var dialog = new SettingsWindow(start);
            var choices = dialog.BarButtonChoices.ToList();
            check(choices.Count == AppSettings.BarButtonIds.Length && (string)choices[0].Tag == "Region" && (string)choices[1].Tag == "Ruler" && choices.Take(2).All(c => c.IsChecked == true) && choices.Skip(2).All(c => c.IsChecked == false),
                "Settings lists every capture bar button: the shown ones ticked, in order, then the rest");
            ((ListBox)dialog.FindName("BarButtonList")).SelectedIndex = 1;
            dialog.MoveBarButton(dialog.FindName("BarButtonUp"), new RoutedEventArgs());
            choices = dialog.BarButtonChoices.ToList(); choices.Single(c => (string)c.Tag == "Scrolling").IsChecked = true;
            ((Slider)dialog.FindName("StripWidthSlider")).Value = 260;
            var result = dialog.Collect(); dialog.Close();
            check(result.BarButtons.SequenceEqual(["Ruler", "Region", "Scrolling"]) && result.StripWidth == 260,
                "Up moves a button left on the bar, a tick adds one, and the red tab width is saved");
            File.WriteAllText(AppSettings.Path, "{\"BarButtons\":[\"Bogus\",\"Region\",\"Region\"],\"StripWidth\":5}");
            var loaded = AppSettings.Load();
            check(loaded.BarButtons.SequenceEqual(["Region"]) && loaded.StripWidth == AppSettings.MinStripWidth, "unknown or repeated buttons and an impossible tab width in settings.json are ignored");
            File.Delete(AppSettings.Path);

            // Copy (with redactions) and Paste (as a new capture), from the editor.
            var pixels = new byte[300 * 200 * 4]; Array.Fill(pixels, (byte)120);
            var shot = BitmapSource.Create(300, 200, 96, 96, PixelFormats.Bgr32, null, pixels, 300 * 4); shot.Freeze();
            Wait(() => controller.DeliverAsync(shot));
            var editor = controller.Editor!;
            var preview = (PreviewSurface)editor.FindName("Preview");
            var region = new Region { Name = "Box", Start = 0, End = 0, ShowDecorations = false }; region.PutManual(0, new(10, 10, 50, 40));
            preview.Project.Regions.Add(region); preview.Selected = null;
            typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, null);
            check(((Button)editor.FindName("CopyButton")).IsEnabled && ((Button)editor.FindName("PasteButton")).IsEnabled, "Copy and Paste are available once a picture is open");
            Clipboard.Clear();
            Wait(() => editor.CopyPictureAsync());
            var copied = Clipboard.GetImage();
            check(copied != null && copied.PixelWidth == 300 && PixelAt(copied, 30, 30) == (0, 0, 0) && PixelAt(copied, 200, 150) == (120, 120, 120),
                "Copy puts the picture on the clipboard with its redaction applied (a black box over the area, the rest unchanged)");
            var small = BitmapSource.Create(40, 30, 96, 96, PixelFormats.Bgr32, null, new byte[40 * 30 * 4], 40 * 4); small.Freeze();
            Clipboard.SetImage(small);
            var before = preview.Project.Media!.Path;
            Wait(() => editor.PastePictureAsync());
            var pasted = preview.Project.Media;
            check(pasted != null && pasted.Width == 40 && pasted.Height == 30 && controller.Store.Owns(pasted.Path) && Path.GetFileName(pasted.Path).StartsWith("CAPTURE_") && !File.Exists(before),
                "Paste opens the clipboard picture as a new capture (and wipes the screenshot it replaced)");
            ((Button)editor.FindName("ClearScreenButton")).RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump();
            check(preview.Project.Media == null && !File.Exists(pasted!.Path), "Clear Editor clears the editor, like Clear on the toolbar");
            editor.Close(); Pump();
        }
        finally
        {
            CaptureController.HideDelay = savedDelay;
            AppSettings.Path = savedPath;
            if (controller.Editor is { } open) open.Close();
            controller.Store.WipeAll(); controller.Dispose();
            try { if (previousClipboard != null) Clipboard.SetText(previousClipboard); else Clipboard.Clear(); } catch (System.Runtime.InteropServices.COMException) { }
        }
    }
}
