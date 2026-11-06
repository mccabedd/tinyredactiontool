using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class Program
{
    private static int passed;
    private static void Check(bool condition, string name) { if (!condition) throw new Exception("FAILED: " + name); Console.WriteLine("PASS " + name); passed++; }
    private static void Reject(Action action, string name)
    { try { action(); } catch (Exception) { Check(true, name); return; } throw new Exception("FAILED: accepted " + name); }
    [STAThread]
    private static int Main(string[] args) => Run(args).GetAwaiter().GetResult();
    private static async Task<int> Run(string[] args)
    {
        try
        {
            var output = Path.GetFullPath(args.Length == 0 ? "test-output" : args[0]); Directory.CreateDirectory(output);
            if (args.Contains("--scene-change-only")) { SynchronizationContext.SetSynchronizationContext(null); await MovingTextChecks.Run(Path.GetFullPath(args[1]), Check, true); return 0; }
            if (args.Contains("--moving-playback-only")) { SynchronizationContext.SetSynchronizationContext(null); await MovingTextChecks.Playback(Path.GetFullPath(args[1]), Check); return 0; }
            if (args.Contains("--moving-text-only")) { SynchronizationContext.SetSynchronizationContext(null); await MovingTextChecks.Run(Path.GetFullPath(args[1]), Check); return 0; }
            // Just one release's checks, for quick runs while working on it (the full run still runs them all).
            if (args.Contains("--release-020-only")) { new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent(); using var only = new MediaTools(); Release020Checks.Run(only, output, Check); Console.WriteLine($"{passed} checks passed."); return 0; }
            if (args.Contains("--scroll-diag")) { await ScrollProbe.Diagnose(args.Skip(Array.IndexOf(args, "--scroll-diag") + 1).ToArray()); return 0; }
            if (args.Contains("--overlay-panes")) { ScrollProbe.OverlayPanes(args.Skip(Array.IndexOf(args, "--overlay-panes") + 1).ToArray()); return 0; }
            if (args.Contains("--web-panes")) { ScrollProbe.WebPanesAt(args.Skip(Array.IndexOf(args, "--web-panes") + 1).ToArray()); return 0; }
            if (args.Contains("--pane-probe")) { ScrollProbe.Pane(args.Skip(Array.IndexOf(args, "--pane-probe") + 1).ToArray()); return 0; }
            if (args.Contains("--scroll-probe")) { await ScrollProbe.Run(args.Skip(Array.IndexOf(args, "--scroll-probe") + 1).ToArray()); return 0; }
            if (args.Contains("--media-probe"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                MediaProbe.Run(args.Skip(Array.IndexOf(args, "--media-probe") + 1).ToArray(), output); return 0;
            }
            if (args.Contains("--speed-probe"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                SpeedProbe.Run(args[Array.IndexOf(args, "--speed-probe") + 1], output); return 0;
            }
            if (args.Contains("--scrolling-only")) { Release022Checks.Scrolling(Check); Console.WriteLine($"{passed} checks passed."); return 0; }
            if (Array.IndexOf(args, "--help-shots") is var shots and >= 0 && shots + 1 < args.Length)
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                HelpShots.Run(Path.GetFullPath(args[shots + 1]), output); return 0;
            }
            if (args.Contains("--window-nudge-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                Release300EditChecks.Run(output, Check); Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-300-only")) { Release300Checks.Run(Check); Console.WriteLine($"{passed} checks passed."); return 0; }
            if (args.Contains("--release-028-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t028 = new MediaTools()) Release028Checks.Run(t028, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-027-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t027 = new MediaTools()) Release027Checks.Run(t027, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-026-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t026 = new MediaTools()) Release026Checks.Run(t026, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-025-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t025 = new MediaTools()) Release025Checks.Run(t025, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-024-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t024 = new MediaTools()) Release024Checks.Run(t024, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-023-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t023 = new MediaTools()) Release023Checks.Run(t023, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-022-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t022 = new MediaTools()) Release022Checks.Run(t022, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--layout-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                LayoutSettingsChecks.Run(output, Check); Console.WriteLine($"{passed} checks passed."); return 0;
            }
            if (args.Contains("--release-021-only"))
            {
                new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }.InitializeComponent();
                using (var t019 = new MediaTools()) Release019Checks.Run(t019, output, Check);
                using (var t021 = new MediaTools()) Release021Checks.Run(t021, output, Check);
                Console.WriteLine($"{passed} checks passed."); return 0;
            }
            RenderShell(output);
            DrawingGestureChecks.Run(output, Check);
            AnnotationChecks.RunModel(output, Check);
            AnnotationChecks.RunUi(output, Check);
            UiPolishChecks.Run(output, Check);
            RegressionChecks.Run(output, Check);
            LayoutSettingsChecks.Run(output, Check);
            FrameSpeedChecks.RunUi(output, Check);
            DrawingAnnotationChecks.Run(output, Check);
            CaptureChecks.RunModel(output, Check);
            CaptureChecks.RunUi(output, Check);
            Release013Checks.Run(output, Check);
            Release014Checks.Run(output, Check);
            Release015Checks.Run(output, Check);
            Release016Checks.Run(output, Check);
            using (var release018Tools = new MediaTools()) Release018Checks.Run(release018Tools, output, Check);
            using (var release019Tools = new MediaTools()) Release019Checks.Run(release019Tools, output, Check);
            using (var release020Tools = new MediaTools()) Release020Checks.Run(release020Tools, output, Check);
            using (var release021Tools = new MediaTools()) Release021Checks.Run(release021Tools, output, Check);
            using (var release022Tools = new MediaTools()) Release022Checks.Run(release022Tools, output, Check);
            using (var release023Tools = new MediaTools()) Release023Checks.Run(release023Tools, output, Check);
            using (var release024Tools = new MediaTools()) Release024Checks.Run(release024Tools, output, Check);
            using (var release025Tools = new MediaTools()) Release025Checks.Run(release025Tools, output, Check);
            using (var release026Tools = new MediaTools()) Release026Checks.Run(release026Tools, output, Check);
            using (var release027Tools = new MediaTools()) Release027Checks.Run(release027Tools, output, Check);
            using (var release028Tools = new MediaTools()) Release028Checks.Run(release028Tools, output, Check);
            Release300Checks.Run(Check);
            Release300EditChecks.Run(output, Check);
            if (args.Contains("--still-only"))
            {
                EyedropperUiChecks.Run(output, Check);
                CropUiChecks.Run(output, Check);
                SynchronizationContext.SetSynchronizationContext(null);
                using var stillTools = new MediaTools(); await StillImageChecks.Run(stillTools, output, Check); await CropChecks.Run(stillTools, output, Check);
                await AnnotationChecks.RunStillExport(stillTools, output, Check);
                Console.WriteLine($"{passed} still-image, eyedropper and crop checks passed."); return 0;
            }
            FollowLossChecks.Run(output, Check);
            if (args.Contains("--loss-ui-only")) { Console.WriteLine($"{passed} loss review checks passed."); return 0; }
            MovingTextUiChecks.Run(Check);
            if (args.Contains("--moving-ui-only")) { Console.WriteLine($"{passed} moving text UI checks passed."); return 0; }
            FollowUiChecks.Run(output, Check);
            EyedropperUiChecks.Run(output, Check);
            CropUiChecks.Run(output, Check);
            if (args.Contains("--follow-ui-only")) { Console.WriteLine($"{passed} WPF Follow checks passed."); return 0; }
            SynchronizationContext.SetSynchronizationContext(null);
            if (args.Contains("--tracking-only"))
            {
                using var trackingTools = new MediaTools(); await TrackingChecks.Run(trackingTools, output, Check);
                Console.WriteLine($"{passed} tracking checks passed."); return 0;
            }
            using (var speedTools = new MediaTools()) await FrameSpeedChecks.RunMedia(speedTools, output, Check);
            using (var recordingTools = new MediaTools()) await CaptureChecks.RunMedia(recordingTools, output, Check);
            var region = new Region { Start = 0, End = 1 };
            region.PutManual(0, new(10, 10, 20, 20)); region.PutManual(1, new(50, 30, 40, 30));
            Check(region.GeometryAt(0.5) == new MediaRect(30, 20, 30, 25), "timestamp interpolation midpoint");
            Check(region.GeometryAt(-1) == region.Keyframes[0].Bounds && region.GeometryAt(9) == region.Keyframes[1].Bounds, "endpoint geometry is held");
            region.MergeTracking([new(0, new(0, 0, 1, 1)), new(0.3, new(20, 20, 22, 22))]);
            Check(region.Keyframes[0].Origin == KeyframeOrigin.Manual && region.Keyframes[0].Bounds.X == 10 && region.Keyframes.Count == 3, "tracking merge preserves manual correction");
            var map = new FrameTimeline([new(0, 0, 0.02), new(20, 0.02, 0.08), new(100, 0.10, 0.03), new(130, 0.13, 0.07), new(200, 0.20, 0.04)]);
            Check(map.IndexAt(0.0999) == 1 && map.IndexAt(0.10) == 2, "VFR timestamp boundary");
            Check(map.BufferedRange(0.1, 0.13) == (0, 4), "two logical-frame temporal buffer");
            var trackingRange = new Region { Start = .02, End = .20 };
            Check(MainWindow.TrackingRangeIssue(map, trackingRange, .02, true) == null, "forward tracking accepts different seed and end frames");
            Check(MainWindow.TrackingRangeIssue(map, trackingRange, .20, false) == null, "backward tracking accepts different seed and start frames");
            Check(MainWindow.TrackingRangeIssue(map, trackingRange, .20, true)?.Contains("Go back to its beginning") == true, "tracking at end explains how to start forward tracking");
            Check(MainWindow.TrackingRangeIssue(map, trackingRange, .02, false)?.Contains("Go to its end") == true, "tracking at start explains how to start backward tracking");
            Check(MainWindow.TrackingRangeIssue(map, trackingRange, 0, true)?.Contains("between the redaction's Begin and End") == true, "tracking outside range explains moving inside it");
            trackingRange.End = .09;
            Check(MainWindow.TrackingRangeIssue(map, trackingRange, .02, true)?.Contains("one frame long") == true, "same VFR frame endpoints explain extending Begin / End");
            Reject(() => new FrameTimeline([new(0, 0, 1), new(0, 1, 1)]), "duplicate source PTS rejected");
            var policy = ManagedPolicy.Parse("""{"schemaVersion":1,"policyId":"test","policyVersion":"1","controls":{"disableAudioRetention":true,"disableVisualObscuration":true}}""");
            Check(policy.DisableAudioRetention && policy.DisableVisualObscuration && !policy.BlockNetworkSource, "managed controls default and enforce");
            Reject(() => ManagedPolicy.Parse("""{"schemaVersion":1,"policyId":"test","policyVersion":"1","controls":{"disableAudioRetention":"true"}}"""), "non-Boolean policy rejected");
            Reject(() => ManagedPolicy.Parse("""{"schemaVersion":1,"policyId":"test","policyVersion":"1","controls":{"unknown":false}}"""), "unknown policy control rejected");
            Reject(() => ManagedPolicy.Parse("""{"schemaVersion":1,"policyId":"test","policyVersion":"1","controls":{"disableAudioRetention":true,"disableAudioRetention":false}}"""), "duplicate policy control rejected");

            const int width = 96, height = 64;
            var pixels = Enumerable.Repeat((byte)255, width * height * 4).ToArray();
            var source = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); source.Freeze();
            var sourcePath = Path.Combine(output, "synthetic-source.png");
            var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(source));
            using (var file = File.Create(sourcePath)) encoder.Save(file);
            var sourceHash = await ProjectStore.HashAsync(sourcePath);
            var project = new RedactionProject { Media = new(sourcePath, new FileInfo(sourcePath).Length, sourceHash, width, height, 0, false) };
            var opaque = new Region { Start = 0, End = 0, ShowDecorations = false };
            opaque.PutManual(0, new(20, 20, 30, 20)); project.Regions.Add(opaque);
            var history = new EditHistory(); history.Checkpoint(project); opaque.Color = "#FF0000";
            project = history.Undo(project); Check(project.Regions[0].Color == "#000000", "undo restores meaningful edit");
            project = history.Redo(project); Check(project.Regions[0].Color == "#FF0000", "redo restores meaningful edit");
            project.Regions[0].Tracking.Add(new(0, 0, ReviewState.Lost, "Subject exited"));
            ExportGate.Check(project, new()); Check(true, "followed ranges no longer block export (0.14.0: David removed the Review step)"); project.Regions[0].Tracking.Clear();
            project.Regions[0].Effect = RedactionEffect.Blur;
            Reject(() => ExportGate.Check(project, policy), "policy enforced at export boundary"); project.Regions[0].Effect = RedactionEffect.Opaque;
            var projectFile = Path.Combine(output, "roundtrip.trtwpf.json"); await ProjectStore.SaveAsync(projectFile, project);
            var restored = ProjectStore.Deserialize(await File.ReadAllTextAsync(projectFile));
            Check(restored.Regions[0].ShowDecorations == false && restored.Regions[0].Keyframes.Count == 1, "project preserves geometry and decoration-only visibility");
            var legacyJson = System.Text.Json.Nodes.JsonNode.Parse(ProjectStore.Serialize(project))!.AsObject(); legacyJson.Remove("CoordinateSpace");
            var legacy = ProjectStore.Deserialize(legacyJson.ToJsonString());
            Check(legacy.CoordinateSpace == "legacy-autorotated-pixels", "old development projects identify their legacy coordinate convention");
            ProjectCoordinates.UpgradeLegacy(legacy, width * 2, height);
            Check(legacy.Regions[0].GeometryAt(0).X == 40 && legacy.Regions[0].GeometryAt(0).Width == 60 && legacy.CoordinateSpace == "autorotated-square-pixels-v1", "legacy geometry migrates safely when square-pixel aspect correction changes dimensions");
            Check(await ProjectStore.MatchesAsync(project.Media!, sourcePath), "source fingerprint matches original");
            var different = Path.Combine(output, "different.dat"); await File.WriteAllTextAsync(different, "different source");
            Check(!await ProjectStore.MatchesAsync(project.Media!, different), "different relink rejected");
            Reject(() => ProjectStore.Deserialize(ProjectStore.Serialize(project).Replace("\"SchemaVersion\": 1", "\"SchemaVersion\": 99")), "future project schema rejected");
            foreach (var shape in Enum.GetValues<RegionShape>())
            {
                project.Regions[0].Shape = shape;
                project.Regions[0].Polygon = [new(0, 0), new(1, 0), new(0.5, 1)];
                var destination = Path.Combine(output, "opaque-" + shape + ".png"); if (File.Exists(destination)) File.Delete(destination);
                await ImageExport.ExportAsync(destination, project, new(), source, CancellationToken.None);
                using var file = File.OpenRead(destination);
                var bitmap = new FormatConvertedBitmap(new PngBitmapDecoder(file, BitmapCreateOptions.None, BitmapCacheOption.OnLoad).Frames[0], PixelFormats.Bgra32, null, 0);
                var actual = new byte[pixels.Length]; bitmap.CopyPixels(actual, width * 4, 0);
                Check(actual[(25 * width + 35) * 4 + 2] == 255 && actual[(25 * width + 35) * 4 + 1] == 0 && actual[(25 * width + 35) * 4 + 3] == 255, shape + " has opaque replacement despite hidden decorations");
                Check(actual[0] == 255 && actual[1] == 255, shape + " preserves uncovered pixels");
            }
            var collision = Path.Combine(output, "existing.png"); await File.WriteAllTextAsync(collision, "existing destination");
            try { await ImageExport.ExportAsync(collision, project, new(), source, CancellationToken.None); throw new Exception("Destination collision accepted"); }
            catch (IOException) { Check(await File.ReadAllTextAsync(collision) == "existing destination", "failed finalisation preserves destination"); }
            using (var cancelled = new CancellationTokenSource())
            {
                cancelled.Cancel(); var cancelledPath = Path.Combine(output, "cancelled.png");
                try { await ImageExport.ExportAsync(cancelledPath, project, new(), source, cancelled.Token); throw new Exception("Cancellation ignored"); }
                catch (OperationCanceledException) { Check(!File.Exists(cancelledPath), "cancelled export not promoted"); }
            }
            Check(await ProjectStore.HashAsync(sourcePath) == sourceHash, "source unchanged after image exports and failures");
            Check(!Directory.EnumerateFiles(output, "*.partial.*").Any(), "partial files cleaned up");
            using var tools = new MediaTools();
            var video = Path.Combine(output, "synthetic-with-audio.mp4");
            for (var i = 0; i < 10; i++)
            {
                var framePixels = (byte[])pixels.Clone();
                for (var y = 20; y < 35; y++) for (var x = 5 + i * 4; x < 20 + i * 4; x++)
                { var offset = (y * width + x) * 4; framePixels[offset] = 0; framePixels[offset + 1] = 0; framePixels[offset + 2] = 0; }
                var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, framePixels, width * 4);
                var frameEncoder = new PngBitmapEncoder(); frameEncoder.Frames.Add(BitmapFrame.Create(image));
                using var file = File.Create(Path.Combine(output, $"frame-{i:00}.png")); frameEncoder.Save(file);
            }
            var audioPath = Path.Combine(output, "synthetic-tone.wav");
            using (var audio = new BinaryWriter(File.Create(audioPath)))
            {
                const int rate = 44100; audio.Write("RIFF"u8); audio.Write(36 + rate * 2); audio.Write("WAVEfmt "u8); audio.Write(16); audio.Write((short)1); audio.Write((short)1); audio.Write(rate); audio.Write(rate * 2); audio.Write((short)2); audio.Write((short)16); audio.Write("data"u8); audio.Write(rate * 2);
                for (var i = 0; i < rate; i++) audio.Write((short)(Math.Sin(i * 2 * Math.PI * 440 / rate) * 8000));
            }
            await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-framerate", "10", "-i", Path.Combine(output, "frame-%02d.png"), "-i", audioPath, "-c:v", "libx264", "-c:a", "aac", "-shortest", video], video, CancellationToken.None);
            var timeline = await tools.ProbeTimelineAsync(video, CancellationToken.None);
            Check(timeline.Frames.Count == 10 && timeline.IndexAt(0.59) == 5, "real media decoded frame timeline");
            var exact = await tools.FrameAsync(video, timeline.Frames[5], null, CancellationToken.None);
            Check(exact.PixelWidth == 96 && exact.PixelHeight == 64, "exact source PTS frame extraction");
            try { await tools.FrameAsync(video, new(99999999, 0, 1), null, CancellationToken.None); throw new Exception("Missing exact PTS accepted"); }
            catch (InvalidDataException) { Check(true, "missing exact PTS fails closed"); }
            using var thumbnails = new ThumbnailService(tools);
            var thumbnail = await thumbnails.RequestAsync(video, timeline.Frames[4]);
            Check(thumbnail?.PixelWidth == 224, "memory-only hover thumbnail generated");
            var concat = Path.Combine(output, "vfr.ffconcat");
            await File.WriteAllTextAsync(concat, "ffconcat version 1.0\nfile 'frame-00.png'\nduration 0.04\nfile 'frame-01.png'\nduration 0.16\nfile 'frame-02.png'\nduration 0.08\nfile 'frame-03.png'\nduration 0.24\nfile 'frame-04.png'\n");
            var vfr = Path.Combine(output, "synthetic-vfr.mp4");
            await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", concat, "-fps_mode", "passthrough", "-c:v", "libx264", vfr], vfr, CancellationToken.None);
            var vfrMap = await tools.ProbeTimelineAsync(vfr, CancellationToken.None);
            Check(vfrMap.Frames.Count == 5 && vfrMap.Frames.Select(f => Math.Round(f.Duration, 2)).Distinct().Count() > 1, "real VFR frame intervals preserved and decoded count reconciled");
            Check((await tools.FrameAsync(vfr, vfrMap.Frames[2], null, CancellationToken.None)).PixelWidth == 96, "exact VFR PTS inspection");
            var rotated = Path.Combine(output, "synthetic-rotated.mp4");
            await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-display_rotation", "90", "-i", video, "-c", "copy", rotated], rotated, CancellationToken.None);
            var rotatedMap = await tools.ProbeTimelineAsync(rotated, CancellationToken.None);
            var rotatedFrame = await tools.FrameAsync(rotated, rotatedMap.Frames[0], null, CancellationToken.None);
            Check(rotatedFrame.PixelWidth == 64 && rotatedFrame.PixelHeight == 96, "rotation metadata produces canonical autorotated inspection dimensions");
            Check(rotatedMap.Frames.Select(f => f.Time).SequenceEqual(timeline.Frames.Select(f => f.Time)), "rotation preserves source frame timeline");
            await VideoExportChecks.Run(tools, output, Check);
            await EffectChecks.Run(tools, output, Check);
            await StillImageChecks.Run(tools, output, Check);
            await CropChecks.Run(tools, output, Check);
            await AnnotationChecks.RunStillExport(tools, output, Check);
            await AnnotationChecks.RunVideoExport(tools, output, Check);
            await PlaybackChecks.Run(tools, output, Check);
            await TrackingChecks.Run(tools, output, Check);
            await WorkflowChecks.Run(tools, output, Check);
            Console.WriteLine($"{passed} checks passed. Synthetic playback, tracking and export checks are not certification of audible AV synchronisation, every codec, or full feature parity.");
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex); return 1; }
    }
    private static void RenderShell(string output)
    {
        Console.WriteLine("Rendering WPF test window: creating application");
        var app = new App { ShutdownMode = ShutdownMode.OnExplicitShutdown, StartDesktopWindow = false }; app.InitializeComponent();
        Console.WriteLine("Rendering WPF test window: creating window");
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        Console.WriteLine("Rendering WPF test window: showing window");
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        Check(!((ComboBox)window.FindName("EffectMode")).IsEnabled && !((Slider)window.FindName("EffectStrength")).IsEnabled, "opaque startup disables inapplicable mode and strength controls");
        // Simulate a session in which the obscuration warning has already been accepted.
        foreach (var (toolName, effect) in new[] { ("BlurTool", RedactionEffect.Blur), ("PixelateTool", RedactionEffect.Pixelate) })
        {
            var tool = (Button)window.FindName(toolName); tool.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            Check(tool.IsVisible && preview.Selected == null && preview.DrawingEffect == effect && preview.Tool == "Rectangle", toolName + " can be selected before drawing or selecting a region");
            foreach (var shape in Enum.GetValues<RegionShape>())
                Check(preview.NewDrawingRegion(shape).Effect == effect, toolName + " is inherited by newly drawn " + shape);
        }
        ((Button)window.FindName("OpaqueTool")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
        const int imageWidth = 192, imageHeight = 108;
        var imagePixels = new byte[imageWidth * imageHeight * 4];
        for (var y = 0; y < imageHeight; y++) for (var x = 0; x < imageWidth; x++)
        { var i = (y * imageWidth + x) * 4; var shade = (byte)((x / 12 + y / 12) % 2 == 0 ? 238 : 206); imagePixels[i] = shade; imagePixels[i + 1] = shade; imagePixels[i + 2] = shade; imagePixels[i + 3] = 255; }
        preview.Image = BitmapSource.Create(imageWidth, imageHeight, 96, 96, PixelFormats.Bgra32, null, imagePixels, imageWidth * 4); preview.Image.Freeze();
        var visualRegion = new Region { Name = "Sensitive area", Start = 0, End = 0 }; visualRegion.PutManual(0, new(48, 30, 48, 28));
        preview.Project = new RedactionProject { Media = new(Path.Combine(output, "synthetic-visual.png"), 1, new string('0', 64), imageWidth, imageHeight, 0, false), Regions = [visualRegion] };
        var regions = (ListBox)window.FindName("Regions"); regions.ItemsSource = preview.Project.Regions; regions.SelectedIndex = 0;
        preview.ResetViewport();
        Console.WriteLine("Rendering WPF test window: rendering layouts");
        foreach (var (name, width, height, theme) in new[] { ("shell-dark", 1240, 800, 1), ("shell-light-compact", 900, 800, 2), ("shell-light-small", 900, 580, 2) })
        {
            window.Width = width; window.Height = height; ((ComboBox)window.FindName("ThemeChoice")).SelectedIndex = theme;
            window.UpdateLayout();
            preview.Fit();
            preview.UpdateLayout();
            var rendered = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); rendered.Render(window);
            var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(rendered));
            using var file = File.Create(Path.Combine(output, name + ".png")); png.Save(file);
            Check(window.IsVisible && window.ActualWidth == width, name + " runtime layout instantiated and rendered");
            var tool = (Button)window.FindName("BlurTool"); var toolPoint = tool.TranslatePoint(new Point(0, 0), window);
            Check(tool.IsVisible && toolPoint.Y + tool.ActualHeight < preview.TranslatePoint(new Point(0, 0), window).Y && toolPoint.X + tool.ActualWidth < window.ActualWidth, name + " Blur tool stays above the canvas without opening properties");
            var previewTop = preview.TranslatePoint(new Point(0, 0), window).Y;
            var toolButtons = ((WrapPanel)window.FindName("ToolButtons")).Children.OfType<Button>().Where(b => b.Visibility == Visibility.Visible).ToArray(); // Original shows only for captures (0.12.0).
            Check(toolButtons.Length >= 18 && toolButtons.All(b => b.IsVisible && b.TranslatePoint(new Point(b.ActualWidth, b.ActualHeight), window) is var corner && corner.X <= window.ActualWidth && corner.Y <= previewTop),
                name + " every toolbar button is visible, inside the window and above the workspace");
            Console.WriteLine($"{name} toolbar rows: {toolButtons.Select(b => Math.Round(b.TranslatePoint(new Point(0, 0), window).Y)).Distinct().Count()}, workspace {preview.ActualWidth:0}×{preview.ActualHeight:0}");
            var menu = (Menu)window.FindName("MainMenu");
            Check(menu.Items.OfType<MenuItem>().Where(m => m.Visibility == Visibility.Visible).Select(m => ((string)m.Header).Replace("_", "")).SequenceEqual(["File", "Edit", "Draw", "Redact", "View", "Video", "Help"]) && menu.Items.OfType<MenuItem>().Where(m => m.Visibility == Visibility.Visible).All(m => m.IsVisible && m.TranslatePoint(new Point(m.ActualWidth, 0), window).X <= window.ActualWidth),
                name + " menu bar shows File, Edit, Draw, Redact, View, Video and Help (0.22.0: About replaced Help; 0.27.0: Video; 3.0.0: Help with the manual; Capture joins them when the capture bar opened the editor)");
            var scale = Math.Min(preview.ActualWidth / imageWidth, preview.ActualHeight / imageHeight);
            var centre = new Point((preview.ActualWidth - imageWidth * scale) / 2 + 72 * scale, (preview.ActualHeight - imageHeight * scale) / 2 + 44 * scale);
            Check(BlackAt(preview, centre), name + " source-coordinate redaction aligns through fit/letterboxing");
            preview.Zoom(1.3, centre); Check(BlackAt(preview, centre), name + " pointer-centred zoom preserves source alignment");
            preview.ActualPixels(); Check(preview.ZoomLabel == "100%", "100% zoom is expressed in physical screen pixels");
            // The hover thumbnail geometry is checked on this still-image shell, so its timeline (hidden for pictures since 0.17.0) is shown here.
            ((FrameworkElement)window.FindName("PlaybackBar")).Visibility = Visibility.Visible; var timeline = (Slider)window.FindName("Timeline"); timeline.Visibility = Visibility.Visible; timeline.Maximum = 10; timeline.Value = 4; window.UpdateLayout();
            var popup = (Border)window.FindName("HoverPopup"); var layer = (Canvas)window.FindName("HoverLayer");
            popup.Visibility = Visibility.Visible; ((System.Windows.Controls.Image)window.FindName("HoverImage")).Source = preview.Image;
            ((TextBlock)window.FindName("HoverTime")).Text = "00:00:04.000"; window.UpdateLayout();
            foreach (var fraction in new[] { .1, .25, .5, .75, .9 })
            {
                var x = timeline.ActualWidth * fraction; var time = window.PrepareTimelineHover(x);
                window.UpdateLayout();
                var cursor = timeline.TranslatePoint(new Point(x, 0), layer);
                var expectedX = Math.Clamp(cursor.X, popup.ActualWidth / 2, layer.ActualWidth - popup.ActualWidth / 2);
                var actual = popup.TranslatePoint(new Point(popup.ActualWidth / 2, popup.ActualHeight), layer);
                Check(Math.Abs(actual.X - expectedX) < .01 && actual.Y < cursor.Y, name + " actual thumbnail bounds stay above cursor, with edge clamping, at " + fraction);
                var screenActual = popup.PointToScreen(new Point(popup.ActualWidth / 2, 0)); var screenExpected = layer.PointToScreen(new Point(expectedX, 0));
                Check(Math.Abs(screenActual.X - screenExpected.X) < 1, name + " rendered thumbnail screen coordinate does not accumulate cursor offsets at " + fraction);
                Check(Math.Abs(time / timeline.Maximum - fraction) < .04, name + " hover frame maps to cursor rather than playhead at " + fraction);
                if (name == "shell-dark" && fraction == .5)
                {
                    var hoverShot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); hoverShot.Render(window);
                    var hoverPng = new PngBitmapEncoder(); hoverPng.Frames.Add(BitmapFrame.Create(hoverShot)); using var hoverFile = File.Create(Path.Combine(output, "shell-hover-overlay.png")); hoverPng.Save(hoverFile);
                }
            }
            popup.Visibility = Visibility.Collapsed;
        }
        // Menu entries drive the same toolbar buttons, and the active drawing tool shows pressed.
        var mainMenu = (Menu)window.FindName("MainMenu");
        var polygonItem = ((MenuItem)mainMenu.Items[2]).Items.OfType<MenuItem>().Single(m => (string?)m.Tag == "PolygonTool");
        polygonItem.RaiseEvent(new RoutedEventArgs(MenuItem.ClickEvent));
        Check(preview.Tool == "Polygon" && ((Button)window.FindName("PolygonTool")).Background == window.FindResource("ToolSelected") && ((Button)window.FindName("RectangleTool")).Background == window.FindResource("Surface"),
            "Draw menu selects the same tool as the toolbar and shows it pressed");
        ((Button)window.FindName("RectangleTool")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
        // Dark theme: drop-down menus draw on a light popup, so their captions must stay dark.
        ((ComboBox)window.FindName("ThemeChoice")).SelectedIndex = 1;
        var fileMenu = (MenuItem)mainMenu.Items[0]; fileMenu.IsSubmenuOpen = true; window.UpdateLayout();
        var openItem = fileMenu.Items.OfType<MenuItem>().First(m => (m.Header as string)?.Contains("Open Media") == true); openItem.UpdateLayout(); // 0.26.0: New picture comes first.
        // Underlined access-key captions are drawn by the TextBlock inside AccessText.
        var caption = Descendants(openItem).OfType<AccessText>().Where(a => a.Text.Contains("Open Media")).SelectMany(a => Descendants(a).OfType<TextBlock>()).FirstOrDefault();
        // 0.28.0 (David): menus follow the theme: in Dark, light captions on a dark drop-down.
        var dropDown = (fileMenu.Template.FindName("PART_Popup", fileMenu) as System.Windows.Controls.Primitives.Popup)?.Child as Border;
        Check(caption?.Foreground is SolidColorBrush { Color: var menuText } && menuText.R > 200 && menuText.G > 200 && menuText.B > 200
              && dropDown?.Background is SolidColorBrush { Color: var menuBack } && menuBack.R < 80 && menuBack.G < 80 && menuBack.B < 80, "Dark theme drop-down menus are dark, with light captions (0.28.0)");
        fileMenu.IsSubmenuOpen = false;
        visualRegion.Effect = RedactionEffect.Blur;
        regions.SelectedItem = null; regions.SelectedItem = visualRegion;
        checkEffects();
        // Exercise the natural UI actions on a selected synthetic video region.
        var workflowRegion = new Region { Name = "Follow this subject", Start = 2, End = 10 };
        workflowRegion.PutManual(2, new(48, 30, 48, 28)); workflowRegion.MergeTracking([new(5, new(55, 30, 48, 28), KeyframeOrigin.Tracking), new(9, new(65, 30, 48, 28), KeyframeOrigin.Tracking)]);
        workflowRegion.Tracking.Add(new(2, 9, ReviewState.Unreviewed, "Check the followed subject"));
        preview.Project = new RedactionProject { Media = new(Path.Combine(output, "synthetic-visual-video.mp4"), 1, new string('0', 64), imageWidth, imageHeight, 10, true), Regions = [workflowRegion] };
        preview.Timeline = new FrameTimeline(Enumerable.Range(0, 10).Select(i => new FrameStamp(i, i, 1))); preview.Time = 2;
        regions.ItemsSource = preview.Project.Regions; regions.SelectedItem = workflowRegion;
        typeof(MainWindow).GetMethod("UpdateClock", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null);
        window.UpdateLayout();
        Check(((Button)window.FindName("FollowSubjectButton")).IsEnabled && ((Button)window.FindName("StopRedactionButton")).IsEnabled, "natural Follow and Stop actions are available for a newly drawn video region");
        // 0.10.0: the side panel starts closed, so Follow is reached from the redaction popup.
        Check(!((Expander)window.FindName("RegionDetails")).IsExpanded && ((Button)window.FindName("PopupFollow")).IsVisible && ((Button)window.FindName("PopupFollow")).IsEnabled, "natural workflow does not require advanced tracking or keyframes");
        // 0.10.1 (David's option 1): on video the popup offers two plain choices.
        var popupRedact = (Button)window.FindName("PopupRedact"); var popupFollow = (Button)window.FindName("PopupFollow");
        Check((string)popupRedact.Content == "Done" && (string)popupFollow.Content == "Track Again", "a tracked video redaction's popup offers Done and Track again");
        var savedTracking = workflowRegion.Tracking; workflowRegion.Tracking = [];
        typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null); window.UpdateLayout();
        // 0.13.0 (David's design): Start Redaction with a tick box; Follow again only once tracked. 0.22.0: tracking by default, the box is "Enable Manual Redaction".
        var popupTrack = (CheckBox)window.FindName("PopupTrack"); var popupStop = (Button)window.FindName("PopupStop");
        Check(popupRedact.IsVisible && (string)popupRedact.Content == "Start Redaction" && popupTrack.IsVisible && popupTrack.IsEnabled && popupTrack.IsChecked != true && (string)popupTrack.Content == "Enable Manual Redaction" && !popupFollow.IsVisible && !popupStop.IsVisible,
            "a new video redaction's popup offers Start Redaction and an unticked Enable Manual Redaction box");
        Check(((string)popupTrack.ToolTip).Contains("Instead of Tracking") && ((string)popupRedact.ToolTip).Contains("Track the Subject"),
            "by default Start Redaction tracks the subject");
        popupTrack.IsChecked = true; window.UpdateLayout();
        Check(((string)popupRedact.ToolTip).Contains("the Box Stays") && ((string)popupRedact.ToolTip).Contains("Stop Redaction"), "ticking Enable Manual Redaction makes the box stay put until Stop Redaction");
        popupTrack.IsChecked = false;
        preview.Time = 5; typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null); window.UpdateLayout();
        Check(popupStop.IsVisible && (string)popupRedact.Content == "Done" && !popupTrack.IsVisible, "on a later frame the popup offers Stop Redaction");
        preview.Time = 2;        workflowRegion.Tracking = savedTracking;
        typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null); window.UpdateLayout();
        var flowShot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); flowShot.Render(window);
        var flowPng = new PngBitmapEncoder(); flowPng.Frames.Add(BitmapFrame.Create(flowShot)); using (var file = File.Create(Path.Combine(output, "shell-follow-workflow.png"))) flowPng.Save(file);
        preview.Time = 5; window.StopSelectedRedaction().GetAwaiter().GetResult();
        Check(workflowRegion.Start == 2 && workflowRegion.End == 5 && workflowRegion.Keyframes.All(k => k.Time <= 5), "Stop UI action uses displayed frame and removes the followed tail");
        Check(workflowRegion.Tracking.All(s => s.State == ReviewState.Unreviewed), "Stop UI retains the remaining review requirement");
        preview.Timeline = null;
        void checkEffects()
        {
            window.Width = 1240; window.Height = 800; window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            Check(((ComboBox)window.FindName("EffectChoice")).SelectedIndex == 1 && ((Slider)window.FindName("EffectStrength")).IsEnabled, "loaded Blur region displays effect controls without changing geometry");
            ((Button)window.FindName("PixelateTool")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            Check(visualRegion.Effect == RedactionEffect.Pixelate, "visible Pixelate tool immediately changes a selected region");
            ((Button)window.FindName("BlurTool")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            window.UpdateLayout(); preview.UpdateLayout();
            var rendered = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); rendered.Render(window);
            var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(rendered));
            using var file = File.Create(Path.Combine(output, "shell-effects.png")); png.Save(file);
        }
        preview.Project = new RedactionProject(); preview.Selected = null;
        window.Close();
        var restricted = new MainWindow(ManagedPolicy.Parse("""{"schemaVersion":1,"policyId":"ui-test","policyVersion":"1","controls":{"disableVisualObscuration":true}}"""))
            { WindowState = WindowState.Normal, Left = -20000, ShowInTaskbar = false };
        restricted.Show();
        Check(!((Button)restricted.FindName("BlurTool")).IsEnabled && ((Button)restricted.FindName("OpaqueTool")).IsEnabled, "managed policy applies to visible tools before opening any media");
        var restrictedPreview = (PreviewSurface)restricted.FindName("Preview");
        restrictedPreview.Project = new RedactionProject { Media = new(Path.Combine(output, "synthetic-visual.png"), 1, new string('0', 64), imageWidth, imageHeight, 0, false), Regions = [visualRegion] };
        var restrictedRegions = (ListBox)restricted.FindName("Regions"); restrictedRegions.ItemsSource = restrictedPreview.Project.Regions; restrictedRegions.SelectedIndex = 0;
        var effectChoice = (ComboBox)restricted.FindName("EffectChoice");
        Check(effectChoice.IsEnabled && !((ComboBoxItem)effectChoice.Items[1]).IsEnabled && !((ComboBoxItem)effectChoice.Items[2]).IsEnabled, "managed effect UI keeps Coloured box available and disables Blur/Pixelate");
        effectChoice.SelectedIndex = 0;
        Check(visualRegion.Effect == RedactionEffect.Opaque, "managed session can convert an existing obscuration region to opaque replacement");
        Check(!((Button)restricted.FindName("BlurTool")).IsEnabled && !((Button)restricted.FindName("PixelateTool")).IsEnabled, "managed policy disables direct obscuration tools");
        var redactMenu = ((MenuItem)((Menu)restricted.FindName("MainMenu")).Items[3]).Items.OfType<MenuItem>().ToArray();
        Check(redactMenu.Single(m => (string?)m.Tag == "BlurTool") is { IsEnabled: false } && redactMenu.Single(m => (string?)m.Tag == "PixelateTool") is { IsEnabled: false } && redactMenu.Single(m => (string?)m.Tag == "OpaqueTool").IsEnabled,
            "managed policy also disables Blur and Pixelate in the Redact menu");
        restrictedPreview.DrawingEffect = RedactionEffect.Blur;
        Check(restrictedPreview.NewDrawingRegion(RegionShape.Rectangle).Effect == RedactionEffect.Opaque, "managed drawing boundary cannot create prohibited Blur from a stale drawing default");
        restrictedPreview.Project = new(); restrictedPreview.Selected = null; restricted.Close();
    }
    private static IEnumerable<DependencyObject> Descendants(DependencyObject parent)
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        {
            var child = VisualTreeHelper.GetChild(parent, i); yield return child;
            foreach (var nested in Descendants(child)) yield return nested;
        }
    }
    private static bool BlackAt(PreviewSurface preview, Point point)
    {
        preview.UpdateLayout();
        var bitmap = new RenderTargetBitmap((int)Math.Ceiling(preview.ActualWidth), (int)Math.Ceiling(preview.ActualHeight), 96, 96, PixelFormats.Pbgra32);
        // Capture the control in local coordinates; Render(preview) includes its
        // layout offset within the parent and can sample an editing handle.
        var local = new DrawingVisual();
        using (var drawing = local.RenderOpen()) drawing.DrawRectangle(new VisualBrush(preview), null, new Rect(0, 0, preview.ActualWidth, preview.ActualHeight));
        bitmap.Render(local);
        var bytes = new byte[4]; bitmap.CopyPixels(new Int32Rect((int)point.X, (int)point.Y, 1, 1), bytes, 4, 0);
        var black = bytes[0] < 5 && bytes[1] < 5 && bytes[2] < 5;
        if (!black)
        {
            Console.WriteLine($"Preview sample {point} in {preview.ActualWidth}x{preview.ActualHeight} ({preview.ZoomLabel}): {string.Join(',', bytes)}");
            var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(bitmap)); using var file = File.Create(Path.Combine(AppContext.BaseDirectory, "preview-failure.png")); png.Save(file);
        }
        return black;
    }
}
