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
using Drawing = System.Drawing;

// 0.13.0: David's list after trying 0.12.0 (red strip, ruler, scrolling capture, clipboard toast,
// recorder options, Save menu, actual size, dark tooltips, Open with TRT, single instance).
internal static class Release013Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static void Wait(Func<Task> operation)
    {
        Task? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(2);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.13.0 check timed out.");
        task.GetAwaiter().GetResult();
    }
    // A tall page of unique rows, seen through a 200-row window with a fixed 20-row header and 15-row footer.
    private static Drawing.Bitmap View(int offset)
    {
        var bitmap = new Drawing.Bitmap(120, 200, Drawing.Imaging.PixelFormat.Format32bppRgb);
        for (var y = 0; y < 200; y++)
        {
            var colour = y < 20 ? Drawing.Color.FromArgb(20, 60, 200) : y >= 185 ? Drawing.Color.FromArgb(200, 60, 20) : Row(offset + y - 20);
            for (var x = 0; x < 120; x++) bitmap.SetPixel(x, y, x >= 110 ? Drawing.Color.FromArgb(offset % 256, 0, 0) : colour); // The right edge changes like a scroll bar.
        }
        return bitmap;
    }
    private static Drawing.Color Row(int y) => Drawing.Color.FromArgb(y & 255, y >> 8, 128);

    public static void Run(string output, Action<bool, string> check)
    {
        // Scrolling capture: joining overlapping pictures.
        var offsets = new List<int>(); for (var o = 0; o < 435; o += 70) offsets.Add(o); offsets.Add(435);
        var frames = offsets.Select(View).ToList();
        check(ScrollingCapture.FindShift(frames[0], frames[1], 20, 15) == 70 && ScrollingCapture.FindShift(frames[^2], frames[^1], 20, 15) == 435 - offsets[^2] && ScrollingCapture.FindShift(frames[0], View(0), 20, 15) == 0,
            "scrolling capture measures how far the content moved (and notices when it did not move)");
        check(ScrollingCapture.Margins(frames[0], frames[1]) == (20, 15), "a fixed header and footer are recognised");
        using (var joined = ScrollingCapture.Stitch(frames))
        {
            var rowsRight = Enumerable.Range(0, 600).All(y => joined.GetPixel(5, 20 + y) == Row(y));
            check(joined.Height == 635 && joined.GetPixel(5, 0) == Drawing.Color.FromArgb(20, 60, 200) && rowsRight && joined.GetPixel(5, 634) == Drawing.Color.FromArgb(200, 60, 20),
                "scrolling capture joins the pictures into the whole page, with the header and footer once");
        }
        foreach (var frame in frames) frame.Dispose();

        // Right-click menu, written to a throw-away key.
        var savedRoot = ExplorerMenu.ClassesRoot; ExplorerMenu.ClassesRoot = @"Software\TinyRedactionToolChecks\Classes";
        try
        {
            ExplorerMenu.Install();
            using var verb = Registry.CurrentUser.OpenSubKey($@"{ExplorerMenu.ClassesRoot}\SystemFileAssociations\.mp4\shell\{ExplorerMenu.VerbName}");
            using var command = verb?.OpenSubKey("command");
            check(ExplorerMenu.IsInstalled && (string?)verb?.GetValue("") == "Open with TRT" && ((string?)command?.GetValue(""))?.EndsWith("\"%1\"") == true && ExplorerMenu.Extensions.Contains(".png") && ExplorerMenu.Extensions.Contains(".mkv"),
                "\"Open with TRT\" is added for pictures and videos, passing the file to TRT");
            ExplorerMenu.Remove();
            check(!ExplorerMenu.IsInstalled, "clearing the setting removes \"Open with TRT\" again");
        }
        finally { ExplorerMenu.ClassesRoot = savedRoot; Registry.CurrentUser.DeleteSubKeyTree(@"Software\TinyRedactionToolChecks", false); }

        // One TRT at a time: a second start hands its file to the first.
        using (var first = new SingleInstance())
        {
            if (first.IsFirst)
            {
                string? received = "none"; first.Listen(p => received = p);
                var file = Path.Combine(output, "handed over.png");
                var sent = SingleInstance.Send(file);
                var deadline = DateTime.UtcNow.AddSeconds(5); while (received == "none" && DateTime.UtcNow < deadline) Thread.Sleep(20);
                using var second = new SingleInstance();
                check(sent && received == file && !second.IsFirst, "a second start of TRT hands its file to the running one");
            }
            else Console.WriteLine("SKIP single-instance hand-over: a development TRT is running on this laptop.");
        }

        // Dark tooltips.
        var tip = new ToolTip { Content = "Readable" };
        MainWindow.ApplyThemeResources("Dark");
        var anchor = new Button { Content = "Hover", ToolTip = tip };
        var host = new Window { Content = anchor, Left = -20000, ShowInTaskbar = false, Width = 200, Height = 80 }; host.Show(); tip.PlacementTarget = anchor; tip.IsOpen = true; Pump(); tip.UpdateLayout();
        var dark = tip.Background is SolidColorBrush back && tip.Foreground is SolidColorBrush fore && back.Color == Color.FromRgb(0x53, 0x53, 0x53) && fore.Color == Color.FromRgb(0xF0, 0xF0, 0xF0);
        tip.IsOpen = false; host.Close(); MainWindow.ApplyThemeResources("Light");
        check(dark, "tooltips use the theme's colours (light text on grey in Dark), not white on white");

        // Screen Recorder window.
        var recorder = new RecorderWindow(new AppSettings { RecordMouseClicks = false });
        var record = (Button)recorder.FindName("RecordButton");
        check(((CheckBox)recorder.FindName("ClicksChoice")).IsChecked == false && record.Background is SolidColorBrush red && red.Color == Color.FromRgb(0xD3, 0x2F, 0x2F) && record.Foreground == Brushes.White,
            "the Screen Recorder has a Show mouse clicks choice and a red Record button with white text");
        var icons = new[] { "RegionChoice", "WindowChoice", "FullScreenChoice", "WorkAreaChoice" }.All(n => ((RadioButton)recorder.FindName(n)).Content is StackPanel { Children.Count: 2 } panel && panel.Children[0] is Grid);
        ((CheckBox)recorder.FindName("ClicksChoice")).IsChecked = true; recorder.Collect(); recorder.Close();
        check(icons && recorder.MouseClicks, "each What to record choice has its own picture; the clicks choice is returned");
        check(new AppSettings().RecordMouseClicks, "mouse clicks show in recordings unless switched off");

        // Capture bar: no taskbar button, red strip, ruler, clipboard toast, actual size, Save menu.
        var savedPath = AppSettings.Path;
        AppSettings.Path = Path.Combine(output, "release013-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var temp = Path.Combine(output, "release013-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        var previousClipboard = ClipboardRetry.Text();
        try
        {
            controller.Start();
            var bar = controller.Bar!;
            check(!bar.ShowInTaskbar, "the capture bar has no taskbar button");
            controller.MinimizeToStrip(); Pump();
            var strip = controller.Strip!;
            check(!bar.IsVisible && strip.IsVisible && strip.Height <= 8 && strip.Background is SolidColorBrush s && s.Color.R > 180 && s.Color.G < 80 && Math.Abs(strip.Top - SystemParameters.WorkArea.Top) < 1,
                "– turns the capture bar into a thin red strip at the top of the screen");
            strip.RaiseEvent(new MouseEventArgs(Mouse.PrimaryDevice, 0) { RoutedEvent = Mouse.MouseEnterEvent }); Pump();
            check(bar.IsVisible && !strip.IsVisible, "pointing at the red strip brings the capture bar back");
            bar.Left = -20000;
            // The 0.13.0 ruler checks moved to Release014Checks with the new ruler.

            var pixels = new byte[300 * 200 * 4]; Array.Fill(pixels, (byte)120);
            var picture = BitmapSource.Create(300, 200, 96, 96, PixelFormats.Bgr32, null, pixels, 300 * 4); picture.Freeze();
            Clipboard.Clear();
            Wait(() => controller.DeliverAsync(picture));
            var clip = Clipboard.GetImage();
            check(clip?.PixelWidth == 300 && CaptureToast.LastText == "Copied to the clipboard", "a screenshot to the editor is also put on the clipboard, with a \"Copied to the clipboard\" toast");
            var editor = controller.Editor!;
            check(((TextBlock)editor.FindName("ZoomText")).Text == "100%", "a capture opens in the editor at actual size (100%), not fitted");
            // 0.24.0: a Save Project button exists for Settings › Editor › Buttons, but it is off unless ticked.
            check(!editor.OnToolbar("SaveProjectButton") && editor.FindName("SaveProjectMenuItem") is MenuItem save && ((string)save.Header).Replace("_", "") == "Save Project…" && save.IsEnabled,
                "Save is no longer on the toolbar; File › Save Project… remains");
            editor.Close(); Pump();
        }
        finally
        {
            AppSettings.Path = savedPath;
            if (controller.Editor is { } open) open.Close();
            controller.Store.WipeAll(); controller.Dispose();
            try { if (previousClipboard != null) Clipboard.SetText(previousClipboard); else Clipboard.Clear(); } catch (System.Runtime.InteropServices.COMException) { }
        }
    }
}
