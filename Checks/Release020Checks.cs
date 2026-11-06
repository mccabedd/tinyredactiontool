using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.20.0: Trim Video (A/B markers, delete or keep only A–B) and Append Video, with sound kept in step.
internal static class Release020Checks
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.20.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    // A picture's brightness fingerprint, to tell frames apart (lossless copies match exactly; allow a little).
    private static double Brightness(BitmapSource image)
    {
        var bgra = new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0); var pixels = new byte[bgra.PixelWidth * bgra.PixelHeight * 4]; bgra.CopyPixels(pixels, bgra.PixelWidth * 4, 0);
        double sum = 0; for (var i = 0; i < pixels.Length; i += 4) sum += pixels[i] * .11 + pixels[i + 1] * .59 + pixels[i + 2] * .3; return sum / (pixels.Length / 4);
    }
    private static bool Same(double a, double b) => Math.Abs(a - b) < 1.5;

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var media = Path.GetFullPath(Path.Combine(output, "..", "test-media"));
        var withSound = Path.Combine(media, "synthetic-offset.mp4");   // 10 frames, sound, video starts 0.023 s into the file
        var plain = Path.Combine(media, "synthetic-with-audio.mp4");   // 10 frames, sound, same size
        var otherShape = Path.Combine(media, "synthetic-rotated.mp4"); // shown upright: a different shape
        var hash = Wait(() => ProjectStore.HashAsync(withSound));

        var temp = Path.Combine(output, "release020-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release020-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); var preview = (PreviewSurface)editor.FindName("Preview");
            var failures = new List<string>(); editor.WorkFailed = ex => failures.Add(ex.ToString());
            void Refresh() { typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, null); editor.UpdateLayout(); }
            void MarkAt(int frame, bool a) { preview.Time = preview.Timeline!.Frames[frame].Time; editor.SetMarker(a); }
            double FrameBrightness(string path, FrameTimeline map, int frame) => Brightness(Wait(() => tools.FrameAsync(path, map.Frames[frame], null, CancellationToken.None)));

            // ---- Delete A–B on a video with sound. ----
            check(Wait(() => editor.OpenPathAsync(withSound)), "a video with sound opens for trimming");
            var map = preview.Timeline!;
            var originalFrame7 = FrameBrightness(withSound, map, 7);
            var region = new Region { Name = "Face", Start = 0, End = preview.Project.Media!.Duration, ShowDecorations = false };
            region.PutManual(map.Frames[0].Time, new(10, 10, 20, 20)); region.PutManual(map.Frames[8].Time, new(50, 20, 20, 20));
            preview.Project.Regions.Add(region);
            preview.Project.Annotations.Add(new Annotation { Kind = AnnotationKind.Line, Points = [new(1, 1), new(20, 20)], Start = map.Frames[5].Time, End = map.Frames[6].Time });
            Refresh();
            MarkAt(4, true); MarkAt(6, false); Refresh();
            check(editor.MarkerA == 4 && editor.MarkerB == 6 && ((System.Windows.Controls.Button)editor.FindName("DeleteSelectionButton")).IsEnabled, "Set A and Set B mark frames; Delete A–B becomes available");
            check(Wait(() => editor.TrimAsync(false)), "Delete A–B trims the video");
            var trimmed = preview.Project.Media!; var newMap = preview.Timeline!;
            check(newMap.Frames.Count == 7 && Path.GetFileName(trimmed.Path).StartsWith("EDITED_") && controller.Store.Owns(trimmed.Path), "the three marked frames are gone (10 → 7), in a working copy");
            check(Same(FrameBrightness(trimmed.Path, newMap, 4), originalFrame7), "the frame after the cut is the old frame 8 (the cut is frame-exact)");
            check(newMap.Frames.Zip(newMap.Frames.Skip(1)).All(p => Math.Abs(p.Second.Time - p.First.Time - 0.1) < 0.002), "the frames run on evenly: no gap where the cut was");
            var soundJson = System.Text.Encoding.UTF8.GetString(Wait(() => tools.RunAsync("ffprobe.exe", ["-v", "error", "-show_entries", "stream=codec_type,duration", "-of", "csv=p=0", trimmed.Path], trimmed.Path, CancellationToken.None)));
            var durations = soundJson.Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(l => l.Trim().Split(',')).ToDictionary(p => p[0], p => double.Parse(p[1], System.Globalization.CultureInfo.InvariantCulture));
            check(durations.ContainsKey("audio") && Math.Abs(durations["audio"] - durations["video"]) < 0.05, $"the sound is kept and ends with the picture (video {durations.GetValueOrDefault("video"):0.000} s, sound {durations.GetValueOrDefault("audio"):0.000} s)");
            var moved = preview.Project.Regions.Single();
            check(moved.Keyframes.Any(k => Math.Abs(k.Time - newMap.Frames[5].Time) < 1e-9 && k.Bounds == new MediaRect(50, 20, 20, 20)) && moved.End == trimmed.Duration, "the redaction's keyframes stay on their frames and it still runs to the end");
            check(preview.Project.Annotations.Count == 0, "an annotation that was only on deleted frames is gone");
            check(Wait(() => ProjectStore.HashAsync(withSound)) == hash, "the original video file is unchanged");

            // ---- Invert: keep only A–B. ----
            MarkAt(1, true); MarkAt(4, false);
            ((System.Windows.Controls.CheckBox)editor.FindName("InvertTrimBox")).IsChecked = true;
            check(Wait(() => editor.TrimAsync(true)) && preview.Timeline!.Frames.Count == 4, $"Invert keeps only the frames from A to B (here 4){(failures.Count > 0 ? ": " + failures[^1] : "")}");
            check(editor.MarkerA == null && editor.MarkerB == null, "the marks are cleared once the trimmed video is in place");
            ((System.Windows.Controls.CheckBox)editor.FindName("InvertTrimBox")).IsChecked = false;

            // ---- Append: at the end, then at the beginning; a different shape is refused. ----
            check(Wait(() => editor.OpenPathAsync(plain)), "another video opens for appending");
            var plainMap = preview.Timeline!;
            var keyed = new Region { Name = "Plate", Start = 0, End = preview.Project.Media!.Duration, ShowDecorations = false };
            keyed.PutManual(plainMap.Frames[3].Time, new(5, 5, 10, 10)); preview.Project.Regions.Add(keyed); Refresh();
            failures.Clear();
            check(Wait(() => editor.AppendAsync(withSound, false)) && preview.Timeline!.Frames.Count == 20, $"Append at the end joins the two videos (10 + 10 frames){(failures.Count > 0 ? ": " + failures[^1] : "")}");
            var joined = preview.Timeline!;
            check(joined.Frames.Zip(joined.Frames.Skip(1)).All(p => p.Second.Time - p.First.Time is > 0.09 and < 0.11), "the joined video runs on evenly across the join");
            bool KeyedAt(int frame) => preview.Project.Regions.Single().Keyframes.Any(k => Math.Abs(k.Time - preview.Timeline!.Frames[frame].Time) < 1e-9 && k.Bounds == new MediaRect(5, 5, 10, 10));
            var plate = preview.Project.Regions.Single();
            check(KeyedAt(3) && Math.Abs(plate.End - joined.Frames[9].Time) < 1e-9, "redactions stay on their frames when a video is added at the end (and do not spill into the added part)");
            check(Wait(() => editor.AppendAsync(plain, true)) && preview.Timeline!.Frames.Count == 30 && KeyedAt(13) && !KeyedAt(3),
                "Append at the beginning moves the redactions along by the added frames");
            var before = preview.Project.Media!.Path;
            failures.Clear();
            check(!Wait(() => editor.AppendAsync(otherShape, false)) && preview.Project.Media!.Path == before && preview.Timeline!.Frames.Count == 30 && failures.Any(f => f.Contains("different shapes")),
                "a video of a different shape is refused with a plain message, and nothing changes");
            editor.Close();
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
}
