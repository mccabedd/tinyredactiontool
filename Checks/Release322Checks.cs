using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 3.2.2 (David): File › Save (Ctrl+S) replaces the opened file with the redacted version (written and checked first,
// then swapped in; asked once per file); Export replaces an existing file only when confirmed, never the open one;
// the title bar names the open file. All in a throw-away folder. `--release-322-only` runs these.
internal static class Release322Checks
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(3);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("3.2.2 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static byte[] Pixels(BitmapSource source)
    { var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0); var bytes = new byte[source.PixelWidth * source.PixelHeight * 4]; converted.CopyPixels(bytes, source.PixelWidth * 4, 0); return bytes; }
    private static void SavePng(BitmapSource picture, string path)
    { var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(picture)); using var stream = File.Create(path); encoder.Save(stream); }
    private static bool Held(string path)
    { try { using var _ = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.None); return false; } catch (IOException) { return true; } }

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var folder = Path.Combine(output, "release322"); if (Directory.Exists(folder)) { foreach (var f in Directory.GetFiles(folder)) File.SetAttributes(f, FileAttributes.Normal); Directory.Delete(folder, true); }
        Directory.CreateDirectory(folder);
        var first = Path.Combine(folder, "01.png"); var second = Path.Combine(folder, "02.png"); var other = Path.Combine(folder, "other.png");
        foreach (var path in new[] { first, second, other }) SavePng(Release320Checks.TextPicture(), path);
        var temp = Path.Combine(output, "release322-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release322-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var questions = new List<string>(); var answer = true; Exception? failed = null;
        var controller = new CaptureController(new ManagedPolicy(), false, temp) { ReplaceInShownTab = true };
        controller.EditorFactory = () => new MainWindow(controller.Policy)
        {
            WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ShowActivated = false,
            ConfirmKeepQuestion = (_, text, _) => { questions.Add(text); return answer; }, WorkFailed = e => failed = e,
        };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            check(Wait(() => controller.OpenEditor().OpenPathAsync(first)), "01.png opens in the editor");
            var editor = controller.Editor!; var preview = (PreviewSurface)editor.FindName("Preview");
            void Refresh() { typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(editor, null); editor.UpdateLayout(); }
            Point On(double x, double y) { var r = preview.ScreenRect(new MediaRect(x, y, 0, 0)); return new(r.X, r.Y); }
            void Redact(double x0, double y0, double x1, double y1)
            {
                preview.Selected = null; preview.DrawingEffect = RedactionEffect.Opaque; preview.Tool = "Rectangle"; preview.Fit(); preview.UpdateLayout(); Refresh();
                preview.MouseDownAt(On(x0, y0), System.Windows.Input.MouseButton.Left, 1); preview.PointerMove(On((x0 + x1) / 2, (y0 + y1) / 2)); preview.PointerMove(On(x1, y1)); preview.PointerUp(); Refresh();
                editor.ApplyColor("#FF0000", "Chose"); Refresh();
            }
            bool RedAt(string path, int x, int y) { var p = Pixels(StillDecoder.Decode(path)!); var o = (y * 300 + x) * 4; return p[o + 2] == 255 && p[o + 1] == 0 && p[o] == 0; }
            var version = System.Text.RegularExpressions.Regex.Match(MainWindow.AboutText, @"\d+\.\d+\.\d+").Value;
            check(editor.Title == $"TinyRedactionTool {version} - 01.png", $"the title bar names the open file: {editor.Title}");

            // Save over the opened file: asked once, written and checked first, then swapped in and opened again.
            Redact(40, 44, 110, 74);
            check(preview.Project.Regions.Count == 1 && !RedAt(first, 60, 60), "a redaction is drawn on 01.png (the file itself is still unredacted)");
            questions.Clear(); failed = null;
            var saved = Wait(() => editor.SaveAsync());
            check(saved && failed == null && questions.Count == 1 && questions[0].StartsWith("Replace 01.png with this version?") && questions[0].Contains("Save Project"),
                $"File › Save asks once before replacing 01.png ({string.Join(" | ", questions)}{failed?.Message})");
            check(RedAt(first, 60, 60) && !RedAt(first, 20, 20), "01.png now holds the redacted picture (red where the redaction was, the rest as before)");
            check(preview.Project.Regions.Count == 0 && preview.Project.Media?.Path == Path.GetFullPath(first) && editor.Title.EndsWith(" - 01.png") && preview.Image != null && Pixels(preview.Image)[(60 * 300 + 60) * 4 + 2] == 255,
                "the saved file is opened again, with the redaction now part of the picture");
            check(Held(first), "TRT holds the saved file again (read-locked) once it is reopened");
            check(Directory.GetFiles(folder).Length == 3, "no half-written or extra files are left beside it: " + string.Join(", ", Directory.GetFiles(folder).Select(Path.GetFileName)));
            Redact(195, 44, 255, 74); questions.Clear();
            check(Wait(() => editor.SaveAsync()) && questions.Count == 0 && RedAt(first, 220, 60) && RedAt(first, 60, 60), "a second Save of the same file doesn't ask again and keeps both redactions");

            // A replace that Windows refuses (a read-only file): the original stays as it was, and so does the work.
            Redact(10, 10, 30, 30); File.SetAttributes(first, FileAttributes.ReadOnly); failed = null;
            var before = File.ReadAllBytes(first);
            check(!Wait(() => editor.SaveAsync()) && failed != null && File.ReadAllBytes(first).SequenceEqual(before) && preview.Project.Regions.Count == 1 && Held(first),
                $"when the file can't be replaced, Save says so ({failed?.Message}); the file and the redaction stay, and TRT holds the file again");
            File.SetAttributes(first, FileAttributes.Normal);
            check(Directory.GetFiles(folder).Length == 3, "and the checked copy written beside it is removed");

            // Answering No leaves the file alone.
            answer = true; check(Wait(() => editor.OpenPathAsync(second)) && editor.Title.EndsWith(" - 02.png"), "02.png opens (title: " + editor.Title + ")");
            Redact(40, 44, 110, 74); answer = false; questions.Clear(); var unchanged = File.ReadAllBytes(second);
            check(!Wait(() => editor.SaveAsync()) && questions.Count == 1 && File.ReadAllBytes(second).SequenceEqual(unchanged), "answering No to the Save question leaves 02.png as it was");
            answer = true;

            // Export: an existing file is replaced only when confirmed, never the open one.
            failed = null; var otherBefore = File.ReadAllBytes(other);
            check(!Wait(() => editor.ExportToAsync(other, null)) && failed != null && File.ReadAllBytes(other).SequenceEqual(otherBefore), "Export still refuses an existing file unless replacing it was confirmed");
            failed = null;
            check(Wait(() => editor.ExportToAsync(other, ExportReplace.Existing)) && failed == null && RedAt(other, 60, 60) && !RedAt(second, 60, 60),
                $"after Windows' \"replace?\" is answered Yes, Export replaces other.png with the redacted version ({failed?.Message})");
            check(editor.IsOpenFile(second) && !editor.IsOpenFile(other), "Export knows which file is open in TRT (that one goes through File › Save)");
            failed = null;
            check(!Wait(() => editor.ExportToAsync(second, ExportReplace.Existing)) && failed != null && File.ReadAllBytes(second).SequenceEqual(unchanged), "Export never replaces the file open in TRT, even when asked");
            check(Directory.GetFiles(folder).Length == 3, "no extra files are left in the folder");

            // Save on a video: the player lets go of the file, the checked video is swapped in, and it opens again.
            var videoFolder = Path.Combine(folder, "video"); Directory.CreateDirectory(videoFolder);
            var video = Wait(() => TrackingChecks.WriteVideo(tools, videoFolder, loss: false));
            foreach (var png in Directory.GetFiles(videoFolder, "*.png")) File.Delete(png);
            check(Wait(() => editor.OpenPathAsync(video)) && preview.Project.Media?.IsVideo == true && editor.Title.EndsWith(" - tracking-pan.mp4"), "a video opens, named in the title (" + editor.Title + ")");
            var frames = preview.Timeline?.Frames.Count ?? 0;
            Redact(2, 2, 40, 40); questions.Clear(); failed = null;
            var videoSaved = Wait(() => editor.SaveAsync());
            check(videoSaved && failed == null && questions.Count == 1 && questions[0].Contains("the unedited video will be gone"), $"Save on a video asks once and replaces it ({failed?.Message})");
            var first0 = Wait(() => tools.FrameAsync(video, null, null, CancellationToken.None)); var v = Pixels(first0); var at = (20 * first0.PixelWidth + 20) * 4;
            check(v[at + 2] > 200 && v[at + 1] < 70 && v[at] < 70 && preview.Timeline?.Frames.Count == frames && preview.Project.Regions.Count == 0 && Held(video),
                $"the saved video is redacted, keeps its {frames} frames, and is open and held again (pixel {v[at + 2]},{v[at + 1]},{v[at]})");
            check(Directory.GetFiles(videoFolder).Length == 1, "nothing else is left beside the video");

            // A New Image has no file yet: no name in the title.
            editor.AnswerNewPicture = d => { d.Carry.IsChecked = false; d.WidthBox.Value = 200; d.HeightBox.Value = 100; d.White.IsChecked = true; d.Accept(); return true; };
            check(Wait(() => editor.NewPictureAsync()) && editor.Title == $"TinyRedactionTool {version}", $"a New Image has no file name in the title ({editor.Title})");
            editor.Close();
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } open) { open.ConfirmKeepQuestion = (_, _, _) => true; open.Close(); } controller.Store.WipeAll(); controller.Dispose(); }
    }
}
