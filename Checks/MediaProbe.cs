using System.IO;
using System.Windows;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// Diagnostic, not a check (0.22.0): opens real videos in the editor the normal way and, with a second one,
// appends it, reporting frame counts and any failure. Run with --media-probe <video> [<video to append>].
internal static class MediaProbe
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame();
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(20) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        return task!.GetAwaiter().GetResult();
    }
    public static void Run(string[] videos, string output)
    {
        var temp = Path.Combine(output, "media-probe"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(false);
            var editor = controller.OpenEditor(); var preview = (PreviewSurface)editor.FindName("Preview");
            editor.WorkFailed = ex => Console.WriteLine("FAILED: " + ex);
            foreach (var video in videos)
            {
                var opened = Wait(() => editor.OpenPathAsync(video));
                Console.WriteLine($"open {Path.GetFileName(video)}: {opened}, {preview.Timeline?.Frames.Count} frames, last at {preview.Timeline?.Frames[^1].Time:0.000}s");
            }
            if (videos.Length == 2)
            {
                Wait(() => editor.OpenPathAsync(videos[0])); var a = preview.Timeline!.Frames.Count;
                var appended = Wait(() => editor.AppendAsync(videos[1], false));
                Console.WriteLine($"append: {appended}, {preview.Timeline?.Frames.Count} frames (expected {a} + the second)");
            }
            editor.Close();
        }
        finally { controller.Store.WipeAll(); controller.Dispose(); }
    }
}
