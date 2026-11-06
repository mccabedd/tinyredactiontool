using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class MovingTextUiChecks
{
    public static void Run(Action<bool, string> check)
    {
        var path = Path.Combine(AppContext.BaseDirectory, "fixtures", "moving-text.mp4");
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show(); var preview = (PreviewSurface)window.FindName("Preview");
        try
        {
            Pump(window, async () =>
            {
                var load = (Task)typeof(MainWindow).GetMethod("LoadMedia", BindingFlags.NonPublic | BindingFlags.Instance)!.Invoke(window, [path, null, CancellationToken.None, false])!;
                await load;
                var region = new Region { Start = 0, End = 12, Effect = RedactionEffect.Pixelate }; region.PutManual(0, new(60, 140, 200, 40));
                preview.Project.Regions.Add(region); preview.Selected = region;
                typeof(MainWindow).GetMethod("Refresh", BindingFlags.NonPublic | BindingFlags.Instance)!.Invoke(window, null);
                Console.WriteLine("Following the actual moving-text sample through WPF");
                await window.FollowSelectedSubject();
                check(region.Keyframes.Count == 288 && region.Tracking.All(s => s.State == ReviewState.Unreviewed), "WPF Follow produces editable tracking for the actual moving text clip");
                var slider = (Slider)window.FindName("Timeline");
                var worst = 0d; var previous = 0d; var rewinds = 0; var mismatches = 0; var frames = 0;
                void Presented()
                {
                    if (preview.Time + .001 < previous) rewinds++;
                    previous = preview.Time;
                    if (Math.Abs(slider.Value - preview.Time) > .001) mismatches++;
                    var bitmap = (WriteableBitmap?)typeof(PreviewSurface).GetField("playbackImage", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(preview);
                    if (bitmap == null) return;
                    var pixels = new byte[640 * 360 * 4]; bitmap.CopyPixels(pixels, 640 * 4, 0);
                    var left = 640; var top = 360;
                    for (var y = 70; y < 300; y++) for (var x = 0; x < 640; x++)
                    {
                        var p = (y * 640 + x) * 4;
                        if (pixels[p] > 225 && pixels[p + 1] > 225 && pixels[p + 2] > 225) { left = Math.Min(left, x); top = Math.Min(top, y); }
                    }
                    var box = region.GeometryAt(preview.Time);
                    worst = Math.Max(worst, Math.Max(Math.Abs(box.X - (left + 10)), Math.Abs(box.Y - (top + 10)))); frames++;
                }
                preview.PlaybackFramePresented += Presented;
                ((Button)window.FindName("PlayButton")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
                var deadline = DateTime.UtcNow.AddSeconds(16);
                while (preview.Time < 8 && DateTime.UtcNow < deadline) await Task.Delay(30);
                preview.PlaybackFramePresented -= Presented;
                check(frames > 80 && preview.Time >= 8, "WPF silent-video preview and timeline advance for eight seconds");
                check(rewinds == 0 && mismatches == 0, "WPF playhead stays with displayed frames without backwards jumps");
                Console.WriteLine($"Actual live moving-text overlay worst alignment error: {worst:0.00}px over {frames} displayed frames");
                check(worst < 15, "live Pixelate box follows visible text within approximate preview timing tolerance");
                await window.StopSelectedRedaction();
                check(!preview.UsePlayer && region.End >= 8 && Math.Abs(region.End - preview.Time) < .001, "Stop after live Follow commits the exact displayed stop frame");
                var seek = typeof(MainWindow).GetMethod("SeekExact", BindingFlags.NonPublic | BindingFlags.Instance, [typeof(double)])!;
                await (Task<bool>)seek.Invoke(window, [2d])!;
                preview.Player.SpeedRatio = .5;
                ((Button)window.FindName("PlayButton")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
                await Task.Delay(1200);
                check(preview.Time > 2.3 && preview.Time < 2.9 && Math.Abs(slider.Value - preview.Time) < .001, "silent-video playhead resumes correctly after a backwards seek at half speed");
                await window.StopSelectedRedaction();
                var paused = preview.Time; await Task.Delay(350);
                check(Math.Abs(preview.Time - paused) < .001, "exact paused frame and playhead stay still after silent playback");
                await (Task<bool>)seek.Invoke(window, [6d])!;
                preview.Player.SpeedRatio = 2;
                ((Button)window.FindName("PlayButton")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
                await Task.Delay(1000);
                check(preview.Time > 7.4 && preview.Time < 8.5, "silent-video playhead resumes correctly after a forwards seek at double speed");
                await window.StopSelectedRedaction();
            });
        }
        finally { preview.Project = new(); preview.Selected = null; window.Close(); }
    }
    private static void Pump(MainWindow window, Func<Task> operation)
    {
        Task? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        window.Dispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("Moving text WPF test timed out.");
        task.GetAwaiter().GetResult();
    }
}
