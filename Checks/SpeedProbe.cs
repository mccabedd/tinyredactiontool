using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// Diagnostic, not a check (0.21.2): plays a real video in the editor, changes the speed while it plays and
// logs every frame put on screen, then times frame steps. Run with --speed-probe <video>.
internal static class SpeedProbe
{
    private static void PumpFor(int milliseconds)
    {
        var frame = new DispatcherFrame(); var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(milliseconds) };
        timer.Tick += (_, _) => { timer.Stop(); frame.Continue = false; }; timer.Start(); Dispatcher.PushFrame(frame);
    }
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame();
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(5) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        return task!.GetAwaiter().GetResult();
    }
    public static void Run(string video, string output)
    {
        var temp = Path.Combine(output, "speed-probe"); Directory.CreateDirectory(temp);
        var window = new MainWindow(new ManagedPolicy()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview"); var speed = (ComboBox)window.FindName("Speed");
        preview.Player.Muted = true;
        var clock = Stopwatch.StartNew();
        Console.WriteLine($"open: {Wait(() => window.OpenPathAsync(video))} in {clock.ElapsedMilliseconds} ms");
        var log = new List<(double Wall, double Shown, double Native, string Phase)>(); var phase = "1x";
        preview.PlaybackFramePresented += () => log.Add((clock.Elapsed.TotalMilliseconds, preview.Time, preview.Player.Position.TotalSeconds, phase));
        void Click(string name) => Dispatcher.CurrentDispatcher.BeginInvoke(() => ((Button)window.FindName(name)).RaiseEvent(new RoutedEventArgs(System.Windows.Controls.Primitives.ButtonBase.ClickEvent)));

        // The first Next frame after opening (the cache is warmed while opening; give it a moment as a person would).
        PumpFor(1500);
        foreach (var label in new[] { "first step after opening", "second step", "third step" })
        {
            var before = preview.Time; var t0 = clock.Elapsed.TotalMilliseconds; Click("NextFrameButton");
            while (preview.Time == before && clock.Elapsed.TotalMilliseconds - t0 < 5000) PumpFor(2);
            Console.WriteLine($"{label}: {clock.Elapsed.TotalMilliseconds - t0:0} ms");
        }
        clock.Restart(); Click("PlayButton"); PumpFor(2500);
        phase = "0.5x"; var change = clock.Elapsed.TotalMilliseconds; Dispatcher.CurrentDispatcher.BeginInvoke(() => speed.SelectedIndex = 1); PumpFor(3000);
        phase = "1x again"; var change2 = clock.Elapsed.TotalMilliseconds; Dispatcher.CurrentDispatcher.BeginInvoke(() => speed.SelectedIndex = 2); PumpFor(2000);
        // Pause, then step right away (the step people notice).
        Click("PlayButton"); PumpFor(5);
        var pausedAt = preview.Time; var p0 = clock.Elapsed.TotalMilliseconds;
        while (!(preview.UsePlayer == false && Math.Abs(preview.Time - pausedAt) < 1) && clock.Elapsed.TotalMilliseconds - p0 < 5000) PumpFor(2);
        foreach (var label in new[] { "step right after pausing", "next step", "next step" })
        {
            var before = preview.Time; var t0 = clock.Elapsed.TotalMilliseconds; Click("NextFrameButton");
            while (preview.Time == before && clock.Elapsed.TotalMilliseconds - t0 < 5000) PumpFor(2);
            Console.WriteLine($"{label}: {clock.Elapsed.TotalMilliseconds - t0:0} ms");
        }
        // Pause half way, choose 0.5x while paused, then Play: how long until the picture moves, and does the time jump?
        var slider = (Slider)window.FindName("Timeline"); Dispatcher.CurrentDispatcher.BeginInvoke(() => slider.Value = slider.Maximum * 0.45); PumpFor(1500);
        var resumeSpeed = int.Parse(Environment.GetEnvironmentVariable("TRT_PROBE_RESUME") ?? "1");
        Dispatcher.CurrentDispatcher.BeginInvoke(() => speed.SelectedIndex = resumeSpeed); PumpFor(50);
        Console.WriteLine($"resume speed: {((ComboBoxItem)speed.Items[resumeSpeed]).Content}x"); var resumeAt = preview.Time; phase = "play at 0.5x after pause";
        var r0 = clock.Elapsed.TotalMilliseconds; Click("PlayButton"); PumpFor(3000);
        var resumed = log.Where(l => l.Phase == phase).ToList();
        if (resumed.Count > 0)
            Console.WriteLine($"play after pause from {resumeAt:0.000}: first frame after {resumed[0].Wall - r0:0} ms showing {resumed[0].Shown:0.000}; then {string.Join(" ", resumed.Take(6).Select(l => $"{l.Wall - r0:0}:{l.Shown:0.000}"))}");
        Click("PlayButton"); PumpFor(300);
        // Next frame pressed while it plays: how long until an exact frame is on screen.
        Dispatcher.CurrentDispatcher.BeginInvoke(() => speed.SelectedIndex = 2); phase = "before step while playing"; Click("PlayButton"); PumpFor(1500);
        var s0 = clock.Elapsed.TotalMilliseconds; Click("NextFrameButton");
        while (preview.UsePlayer && clock.Elapsed.TotalMilliseconds - s0 < 5000) PumpFor(2);
        var shownAt = preview.Time; while (preview.Time == shownAt && clock.Elapsed.TotalMilliseconds - s0 < 5000) PumpFor(2);
        Console.WriteLine($"Next frame while playing: exact frame after {clock.Elapsed.TotalMilliseconds - s0:0} ms");
        foreach (var label in new[] { "then next", "then next" })
        {
            var before = preview.Time; var t0 = clock.Elapsed.TotalMilliseconds; Click("NextFrameButton");
            while (preview.Time == before && clock.Elapsed.TotalMilliseconds - t0 < 5000) PumpFor(2);
            Console.WriteLine($"{label}: {clock.Elapsed.TotalMilliseconds - t0:0} ms");
        }
        foreach (var group in log.GroupBy(l => l.Phase))
        {
            var items = group.ToList(); var gaps = items.Zip(items.Skip(1), (a, b) => b.Wall - a.Wall).ToList();
            Console.WriteLine($"{group.Key}: {items.Count} frames shown, biggest gap {(gaps.Count > 0 ? gaps.Max() : 0):0} ms, shown time {items[0].Shown:0.000}â†’{items[^1].Shown:0.000}, native {items[0].Native:0.000}â†’{items[^1].Native:0.000}");
        }
        Console.WriteLine("Around the change to 0.5x (wall ms after change, shown time, native time):");
        foreach (var l in log.Where(l => l.Wall > change - 300 && l.Wall < change + 1500)) Console.WriteLine($"  {l.Wall - change,7:0}  {l.Shown:0.000}  {l.Native:0.000}  {l.Phase}");
        Console.WriteLine("Around the change back to 1x:");
        foreach (var l in log.Where(l => l.Wall > change2 - 200 && l.Wall < change2 + 1000)) Console.WriteLine($"  {l.Wall - change2,7:0}  {l.Shown:0.000}  {l.Native:0.000}  {l.Phase}");
        window.Close();
    }
}
