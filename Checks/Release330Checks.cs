using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 3.3.0 (David): Save (Ctrl+S), Save As (Ctrl+Shift+S, was Export) and Save Project; Save Media As retired; secure
// deletion its own command (Release018Checks); suggested names yyyyMMdd_HHmmss_SUFFIX.ext. Throw-away folders only.
// `--release-330-only` runs these.
internal static class Release330Checks
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(3);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("3.3.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static byte[] Pixels(BitmapSource source)
    { var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0); var bytes = new byte[source.PixelWidth * source.PixelHeight * 4]; converted.CopyPixels(bytes, source.PixelWidth * 4, 0); return bytes; }
    private static void SavePng(BitmapSource picture, string path)
    { var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(picture)); using var stream = File.Create(path); encoder.Save(stream); }
    private static string Sha(string path) => Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(path)));
    private static readonly DateTime Taken = new(2026, 11, 1, 9, 8, 7);

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        Naming(check);
        var folder = Path.Combine(output, "release330"); if (Directory.Exists(folder)) { foreach (var f in Directory.GetFiles(folder, "*", SearchOption.AllDirectories)) File.SetAttributes(f, FileAttributes.Normal); Directory.Delete(folder, true); }
        Directory.CreateDirectory(folder);
        var temp = Path.Combine(output, "release330-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release330-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
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
            var original = Path.Combine(folder, "original.png"); SavePng(Release320Checks.TextPicture(), original);
            var originalSha = Sha(original);
            check(Wait(() => controller.OpenEditor().OpenPathAsync(original)), "original.png opens");
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
            string? suggested = null; string? offeredFolder = null; var dialogs = 0;
            string? SaveAsTo(string? to) { editor.AnswerSaveAs = (f, name) => { dialogs++; offeredFolder = f; suggested = name; return to; }; return to; }

            // ---- The brief's first case: the original stays, the copy gets the later edit through Ctrl+S ----
            check(editor.SaveTarget == Path.GetFullPath(original) && editor.Title.EndsWith(" - original.png"), $"an opened file is where Save writes, named in the title ({editor.Title})");
            questions.Clear();
            check(!Wait(() => editor.SaveAsync()) && questions.Count == 0 && Sha(original) == originalSha, "Ctrl+S on an unchanged picture does nothing (no question, no writing)");
            Redact(40, 44, 110, 74);
            var copy = Path.Combine(folder, "redacted-copy.png");
            check(Wait(() => editor.SaveAsAsync(copy)) && failed == null && RedAt(copy, 60, 60) && Sha(original) == originalSha && preview.Project.Regions.Count == 1,
                $"Save As writes a redacted copy; the original is unchanged and the redaction stays editable ({failed?.Message})");
            check(editor.SaveTarget == Path.GetFullPath(copy) && editor.Title.EndsWith(" - redacted-copy.png"), $"the copy becomes the Save target, named in the title ({editor.Title})");
            Redact(195, 44, 255, 74); questions.Clear();
            check(Wait(() => editor.SaveAsync()) && questions.Count == 0 && RedAt(copy, 60, 60) && RedAt(copy, 220, 60) && Sha(original) == originalSha,
                "after another edit, Ctrl+S updates the copy (both redactions) without a question; the original's SHA-256 is unchanged");
            var copySha = Sha(copy);
            check(!Wait(() => editor.SaveAsync()) && Sha(copy) == copySha, "Ctrl+S again with nothing changed does nothing");

            // ---- Cancelling and failing leave the target and the editing as they were ----
            SaveAsTo(null); failed = null;
            check(!Wait(() => editor.SaveAsAsync()) && editor.SaveTarget == Path.GetFullPath(copy) && preview.Project.Regions.Count == 2 && dialogs == 1, "cancelling Save As keeps the target and the work");
            var locked = Path.Combine(folder, "read-only.png"); SavePng(Release320Checks.TextPicture(), locked); File.SetAttributes(locked, FileAttributes.ReadOnly);
            var lockedSha = Sha(locked);
            check(!Wait(() => editor.SaveAsAsync(locked)) && failed != null && editor.SaveTarget == Path.GetFullPath(copy) && preview.Project.Regions.Count == 2 && Sha(locked) == lockedSha,
                $"a Save As that can't write ({failed?.Message}) keeps the previous target, the work and the file it tried to replace");
            Redact(10, 10, 30, 30); File.SetAttributes(copy, FileAttributes.ReadOnly); failed = null;
            check(!Wait(() => editor.SaveAsync()) && failed != null && Sha(copy) == copySha && editor.SaveTarget == Path.GetFullPath(copy) && preview.Project.Regions.Count == 3,
                "a Ctrl+S that can't write keeps the target, the work and the copy as they were");
            File.SetAttributes(copy, FileAttributes.Normal); File.SetAttributes(locked, FileAttributes.Normal);
            check(Directory.GetFiles(folder).Length == 3, "nothing half-written is left in the folder: " + string.Join(", ", Directory.GetFiles(folder).Select(Path.GetFileName)));

            // ---- Undo and Flatten in the suggested name ----
            var other = Path.Combine(folder, "plain.png"); SavePng(Release320Checks.TextPicture(), other);
            check(Wait(() => editor.OpenPathAsync(other)), "plain.png opens");
            string Suggested() => editor.SuggestedName(".png", null);
            check(Suggested().EndsWith("_COPY.png"), $"an opened picture saved untouched is COPY ({Suggested()})");
            Redact(40, 44, 110, 74);
            check(Suggested().EndsWith("_REDACTED.png"), $"with a redaction it is REDACTED ({Suggested()})");
            Wait(() => editor.StepHistoryAsync(true));
            check(preview.Project.Regions.Count == 0 && Suggested().EndsWith("_COPY.png"), $"an undone redaction doesn't count ({Suggested()})");
            Redact(40, 44, 110, 74);
            check(Wait(() => editor.FlattenImageAsync()) && preview.Project.Regions.Count == 0 && Suggested().EndsWith("_REDACTED.png"), $"a flattened redaction still counts ({Suggested()})");
            var flattened = Path.Combine(folder, "flattened.png");
            check(Wait(() => editor.SaveAsAsync(flattened)) && RedAt(flattened, 60, 60), "the flattened picture saves with the redaction in it");
            Wait(() => editor.StepHistoryAsync(true));
            check(preview.Project.Regions.Count == 1 && Suggested().EndsWith("_REDACTED.png"), "Undo brings the separate redaction back");
            Wait(() => editor.StepHistoryAsync(true));
            check(preview.Project.Regions.Count == 0 && !preview.Project.BakedRedaction && Suggested().EndsWith("_COPY.png"), $"and undoing that too leaves an untouched picture ({Suggested()})");

            // ---- Saving over the file being edited: asked once, then reopened with the edits in it ----
            // (Ctrl+S now goes to flattened.png, the last Save As; Save As onto the opened file replaces it in place.)
            check(editor.SaveTarget == Path.GetFullPath(flattened), "after Save As, Ctrl+S goes to the file Save As wrote");
            Redact(40, 44, 110, 74); questions.Clear();
            check(Wait(() => editor.SaveAsAsync(other)) && questions.Count == 1 && questions[0].Contains("permanent") && questions[0].Contains("Save Project") && RedAt(other, 60, 60),
                "Save over the opened file explains first that the edits become permanent and that Save Project keeps them editable");
            check(preview.Project.Regions.Count == 0 && preview.Project.BakedRedaction && Suggested().EndsWith("_REDACTED.png"), "the reopened file still counts as redacted");

            // ---- Transform only, untouched capture, new image ----
            var turned = Path.Combine(folder, "turn-me.png"); SavePng(Release320Checks.TextPicture(), turned);
            check(Wait(() => editor.OpenPathAsync(turned)) && Wait(() => editor.RotateMediaAsync(TurnOp.Clockwise)) && Suggested().EndsWith("_EDITED.png"), $"turned only, it is EDITED ({Suggested()})");
            var turnedCopy = Path.Combine(folder, "turned-copy.png"); failed = null;
            check(Wait(() => editor.SaveAsAsync(turnedCopy)) && StillDecoder.Decode(turnedCopy) is { PixelWidth: 120, PixelHeight: 300 }, $"work that is only turned can be saved ({failed?.Message})");

            var capture = controller.Store.NewFile("CAPTURE", ".png", new MediaOrigin(MediaOriginKind.Screenshot, Taken));
            CaptureController.WritePng(Release320Checks.TextPicture(), capture);
            check(Wait(() => editor.OpenCaptureAsync(capture)), "a screenshot opens");
            var grabs = Path.Combine(folder, "grabs"); Directory.CreateDirectory(grabs);
            File.WriteAllText(Path.Combine(grabs, "20261101_090807_SCREENGRAB.png"), ""); File.WriteAllText(Path.Combine(grabs, "20261101_090807_SCREENGRAB_2.png"), "");
            check(editor.SuggestedName(".png", grabs) == "20261101_090807_SCREENGRAB_3.png", $"an untouched screenshot is named from when it was taken, after names already there ({editor.SuggestedName(".png", grabs)})");
            dialogs = 0; var grabbed = Path.Combine(folder, "grab.png"); SaveAsTo(grabbed);
            check(editor.SaveTarget == null && Wait(() => editor.SaveAsync()) && dialogs == 1 && suggested == "20261101_090807_SCREENGRAB.png" && Pixels(StillDecoder.Decode(grabbed)!).SequenceEqual(Pixels(StillDecoder.Decode(capture)!)),
                $"Ctrl+S on a screenshot opens Save As (suggesting {suggested}) and the untouched screenshot saves as it was");
            check(editor.SaveTarget == Path.GetFullPath(grabbed) && editor.Title.EndsWith(" - grab.png"), "and the saved file becomes the target");
            Redact(40, 44, 110, 74);
            var now = DateTime.Now;
            check(Suggested().EndsWith("_REDACTED.png") && DateTime.ParseExact(Suggested()[..15], "yyyyMMdd_HHmmss", null) is var at && Math.Abs((at - now).TotalMinutes) < 2,
                $"edited, it is REDACTED with the time of saving, not of taking ({Suggested()})");
            check(SaveNaming.RawSuffix(editor.Origin.Kind) == SaveNaming.Screengrab && editor.Origin.Time == Taken, "the raw screenshot (Original) keeps SCREENGRAB and the time it was taken, even after edits");
            editor.AnswerNewPicture = d => { d.Carry.IsChecked = false; d.WidthBox.Value = 200; d.HeightBox.Value = 100; d.White.IsChecked = true; d.Accept(); return true; };
            check(Wait(() => editor.NewPictureAsync()) && Suggested().EndsWith("_IMAGE.png"), $"a new canvas is IMAGE ({Suggested()})");
            var canvas = Path.Combine(folder, "canvas.png");
            check(Wait(() => editor.SaveAsAsync(canvas)) && StillDecoder.Decode(canvas) is { PixelWidth: 200, PixelHeight: 100 }, "an untouched new image can be saved");

            // ---- Save Project with media in TRT's temporary folder; it opens again after the temporary files are gone ----
            var shot = controller.Store.NewFile("CAPTURE", ".png", new MediaOrigin(MediaOriginKind.Screenshot, Taken));
            CaptureController.WritePng(Release320Checks.TextPicture(), shot);
            check(Wait(() => editor.OpenCaptureAsync(shot)), "another screenshot opens");
            Redact(40, 44, 110, 74);
            string? projectName = null; editor.AnswerSaveProject = (_, name) => { projectName = name; return null; };
            check(!Wait(() => editor.SaveProjectAsync()) && projectName != null && System.Text.RegularExpressions.Regex.IsMatch(projectName, @"^\d{8}_\d{6}\.trtwpf\.json$"),
                $"Save Project suggests yyyyMMdd_HHmmss.trtwpf.json ({projectName}); cancelling writes nothing");
            var projectFile = Path.Combine(folder, "work.trtwpf.json");
            check(Wait(() => editor.SaveProjectAsync(projectFile)) && File.Exists(Path.Combine(folder, "work_MEDIA.png")), "the project gets a checked copy of the screenshot beside it");
            var stored = ProjectStore.Deserialize(File.ReadAllText(projectFile));
            check(stored.Media!.Path == Path.Combine(folder, "work_MEDIA.png") && stored.Regions.Count == 1, "and points at that copy");
            editor.ConfirmKeepQuestion = (_, _, _) => true; editor.Close(); Wait(() => Task.FromResult(true));
            controller.Store.WipeAll();
            check(!File.Exists(shot), "TRT's temporary screenshot is wiped (as when TRT quits)");
            var again = controller.OpenEditor(); var againPreview = (PreviewSurface)again.FindName("Preview"); again.WorkFailed = e => failed = e; failed = null;
            check(Wait(() => again.OpenProjectAsync(projectFile)) && againPreview.Project.Regions.Count == 1 && againPreview.Project.Media!.Path == Path.Combine(folder, "work_MEDIA.png"),
                $"the project opens again afterwards, with its redaction ({failed?.Message})");
            check(again.SaveTarget == null, "a project's media is not a Save target (Save opens Save As), so the project can always open");
            again.ConfirmKeepQuestion = (_, _, _) => true; again.Close(); Wait(() => Task.FromResult(true));

            // ---- A video with sound: unchanged Ctrl+S does nothing; a replacement that drops the sound says so ----
            var videoFolder = Path.Combine(folder, "video"); Directory.CreateDirectory(videoFolder);
            var silent = Wait(() => TrackingChecks.WriteVideo(tools, videoFolder, loss: false));
            var tone = Path.Combine(videoFolder, "tone.wav");
            using (var audio = new BinaryWriter(File.Create(tone)))
            {
                const int rate = 44100; audio.Write("RIFF"u8); audio.Write(36 + rate * 2); audio.Write("WAVEfmt "u8); audio.Write(16); audio.Write((short)1); audio.Write((short)1); audio.Write(rate); audio.Write(rate * 2); audio.Write((short)2); audio.Write((short)16); audio.Write("data"u8); audio.Write(rate * 2);
                for (var i = 0; i < rate; i++) audio.Write((short)(Math.Sin(i * 2 * Math.PI * 440 / rate) * 8000));
            }
            var sounding = Path.Combine(videoFolder, "with-sound.mp4");
            Wait(async () => { await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", silent, "-i", tone, "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", "-shortest", sounding], sounding, CancellationToken.None); return true; });
            var soundSha = Sha(sounding);
            var player = controller.OpenEditor(); var playerPreview = (PreviewSurface)player.FindName("Preview");
            player.ConfirmKeepQuestion = (_, text, _) => { questions.Add(text); return answer; }; player.WorkFailed = e => failed = e;
            check(Wait(() => player.OpenPathAsync(sounding)) && playerPreview.Project.Media?.IsVideo == true, "a video with sound opens");
            questions.Clear();
            check(!Wait(() => player.SaveAsync()) && questions.Count == 0 && Sha(sounding) == soundSha, "Ctrl+S on an unchanged video with sound does nothing: the file and its sound stay");
            var r = new Region { Name = "Box", Start = 0, End = 0.15 }; r.PutManual(0, new(2, 2, 30, 30)); playerPreview.Project.Regions.Add(r);
            answer = false; questions.Clear();
            check(!Wait(() => player.SaveAsync()) && questions.Count == 1 && questions[0].Contains("has sound") && Sha(sounding) == soundSha,
                "replacing a video says first that its sound will go (answered No: unchanged)");
            answer = true;
            check(SaveNaming.Suffix(playerPreview.Project, MediaOriginKind.Frame, playerPreview.Timeline, 0.05) == SaveNaming.Redacted
                  && SaveNaming.Suffix(playerPreview.Project, MediaOriginKind.Frame, playerPreview.Timeline, 0.5) == SaveNaming.Frame,
                "a saved frame counts a redaction only on frames where it is active (REDACTED at 0.05 s, FRAME at 0.5 s)");
            check(Wait(() => player.OpenPathAsync(silent)) && player.SuggestedName(".mp4", null).EndsWith("_COPY.mp4"), "an opened video saved untouched is COPY");
            var videoCopy = Path.Combine(videoFolder, "untouched-copy.mp4"); failed = null;
            check(Wait(() => player.SaveAsAsync(videoCopy)) && File.Exists(videoCopy) && Wait(() => tools.ProbeTimelineAsync(videoCopy, CancellationToken.None)).Frames.Count == 7,
                $"an untouched video can be saved with Save As (all 7 frames, checked) ({failed?.Message})");
            player.ConfirmKeepQuestion = (_, _, _) => true; player.Close();
        }
        finally { AppSettings.Path = savedPath; foreach (var w in Application.Current.Windows.OfType<MainWindow>().ToList()) { w.ConfirmKeepQuestion = (_, _, _) => true; w.Close(); } controller.Store.WipeAll(); controller.Dispose(); }
    }

    // The naming rules on their own.
    private static void Naming(Action<bool, string> check)
    {
        RedactionProject Project(bool region = false, bool annotation = false, bool crop = false, bool bakedRedaction = false, bool bakedEdit = false)
        {
            var p = new RedactionProject { Media = new(@"C:\x\a.png", 1, new string('0', 64), 100, 100, 0, false), BakedRedaction = bakedRedaction, BakedEdit = bakedEdit };
            if (region) { var r = new Region { Name = "R", Start = 0, End = 0 }; r.PutManual(0, new(1, 1, 10, 10)); p.Regions.Add(r); }
            if (annotation) p.Annotations.Add(new Annotation { Kind = AnnotationKind.Text, Text = "Note", Box = new(1, 1, 20, 10) });
            if (crop) p.Crop = new(0, 0, 50, 50);
            return p;
        }
        check(SaveNaming.Suffix(Project(region: true, annotation: true, crop: true), MediaOriginKind.Screenshot) == "REDACTED", "a redaction wins over annotations and other edits: REDACTED");
        check(SaveNaming.Suffix(Project(annotation: true), MediaOriginKind.Screenshot) == "EDITED" && SaveNaming.Suffix(Project(crop: true), MediaOriginKind.Recording) == "EDITED"
              && SaveNaming.Suffix(Project(bakedEdit: true), MediaOriginKind.Imported) == "EDITED", "annotations, a crop or a turned/resized/trimmed picture without a redaction: EDITED");
        check(SaveNaming.Suffix(Project(bakedRedaction: true), MediaOriginKind.Imported) == "REDACTED", "a redaction already in the picture (Flatten, Save) still counts");
        var outside = Project(region: true); outside.Crop = new(50, 50, 40, 40);
        check(SaveNaming.Suffix(outside, MediaOriginKind.Imported) == "EDITED", "a redaction entirely outside the crop isn't in the saved file: EDITED, not REDACTED");
        var raw = new[] { (MediaOriginKind.Screenshot, "SCREENGRAB"), (MediaOriginKind.Recording, "RECORDING"), (MediaOriginKind.Frame, "FRAME"), (MediaOriginKind.Imported, "COPY"), (MediaOriginKind.Pasted, "COPY"), (MediaOriginKind.NewImage, "IMAGE") };
        check(raw.All(x => SaveNaming.Suffix(Project(), x.Item1) == x.Item2), "untouched: SCREENGRAB, RECORDING, FRAME, COPY (opened or pasted), IMAGE (new canvas)");
        var now = new DateTime(2026, 11, 23, 14, 5, 6);
        check(SaveNaming.TimeFor("SCREENGRAB", new(MediaOriginKind.Screenshot, Taken), now) == Taken && SaveNaming.TimeFor("REDACTED", new(MediaOriginKind.Screenshot, Taken), now) == now
              && SaveNaming.TimeFor("COPY", new(MediaOriginKind.Imported, Taken), now) == now, "untouched captures carry the time taken; rendered results the time saved");
        check(SaveNaming.Suggest(null, "REDACTED", now, ".jpg") == "20261123_140506_REDACTED.jpg" && SaveNaming.SuggestProject(null, now) == "20261123_140506.trtwpf.json",
            "names read yyyyMMdd_HHmmss_SUFFIX.ext, and projects yyyyMMdd_HHmmss.trtwpf.json");
    }
}
