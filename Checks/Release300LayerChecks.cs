using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 3.0.0 (David, 9 November 2026): layers (Move Up / Move Down beside each list, Duplicate, Flatten Image),
// Begin Here and End Here in a video annotation's own window, and cropping videos. `--layers-only` runs these alone.
internal static class Release300LayerChecks
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(3);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("3.0.0 layer check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static bool Until(Func<bool> done, int milliseconds = 8000) => Wait(async () => { for (var i = 0; i < milliseconds / 40 && !done(); i++) await Task.Delay(40); return done(); });
    private static void Click(Button button) => Wait(() => { button.RaiseEvent(new RoutedEventArgs(Button.ClickEvent)); return Task.FromResult(true); });
    private static byte[] Pixels(BitmapSource source)
    { var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0); var bytes = new byte[source.PixelWidth * source.PixelHeight * 4]; converted.CopyPixels(bytes, source.PixelWidth * 4, 0); return bytes; }
    private static (byte B, byte G, byte R) At(BitmapSource image, int x, int y)
    {
        var pixel = new byte[4]; new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0).CopyPixels(new Int32Rect(x, y, 1, 1), pixel, 4, 0);
        return (pixel[0], pixel[1], pixel[2]);
    }
    private static BitmapSource Grey(int width, int height, byte value)
    {
        var pixels = new byte[width * height * 4]; Array.Fill(pixels, value);
        for (var i = 3; i < pixels.Length; i += 4) pixels[i] = 255;
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze(); return image;
    }
    private static Region Box(string name, double x, double y, double w, double h, string colour = "#000000", double end = 0)
    {
        var r = new Region { Name = name, Start = 0, End = end, Color = colour, ShowDecorations = false };
        r.PutManual(0, new(x, y, w, h)); return r;
    }

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        StackRules(output, check);
        EditorChecks(tools, output, check);
        VideoCropExport(tools, output, check);
    }

    // ---- The one stack behind both lists. ----
    private static void StackRules(string output, Action<bool, string> check)
    {
        var media = new MediaReference(Path.Combine(output, "layers.png"), 1, new string('0', 64), 100, 60, 0, false);
        var r1 = Box("R1", 10, 10, 30, 20); var r2 = Box("R2", 50, 10, 30, 20);
        var a1 = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(5, 5, 40, 30) }; var a2 = new Annotation { Kind = AnnotationKind.Line, Points = [new(0, 50), new(90, 50)] };
        r1.Order = 1; a1.Order = 2; r2.Order = 3; a2.Order = 4;
        var p = new RedactionProject { Media = media, Regions = [r1, r2], Annotations = [a1, a2] };
        check(Layers.Stack(p).SequenceEqual([r1, a1, r2, a2]) && Layers.RegionsTopFirst(p).SequenceEqual([r2, r1]) && Layers.AnnotationsTopFirst(p).SequenceEqual([a2, a1]),
            "redactions and annotations share one stack; each list shows its part, top layer first");
        check(Layers.Move(p, r1, true) == r2 && Layers.Stack(p).SequenceEqual([a1, r2, r1, a2]) && p.Regions.SequenceEqual([r2, r1]) && Layers.RegionsTopFirst(p).SequenceEqual([r1, r2]),
            "Move Up takes a redaction above the next redaction (the list order changes, and so does the order they are drawn in)");
        check(!Layers.CanMove(p, a2, true) && Layers.Move(p, a2, true) == null, "the top layer can't move up");
        check(Layers.Move(p, a1, true) == a2 && Layers.Stack(p).SequenceEqual([r2, r1, a2, a1]), "Move Up takes an annotation above the next annotation, past redactions between them");
        check(Layers.Move(p, r1, true) == a1 && Layers.Stack(p).SequenceEqual([r2, a2, a1, r1]), "with no redaction above, Move Up takes it to the very top (above the annotations)");
        check(Layers.Move(p, r1, false) == r2 && Layers.Stack(p).SequenceEqual([r1, r2, a2, a1]), "Move Down takes it below the next redaction down");
        check(Layers.Stack(p).Select(x => x is Region r ? r.Order : ((Annotation)x).Order).SequenceEqual([1L, 2, 3, 4]), "after a move the layers are numbered 1, 2, 3 … with no ties");
        ProjectStore.Validate(ProjectStore.Deserialize(ProjectStore.Serialize(p)));
        check(Layers.Stack(ProjectStore.Deserialize(ProjectStore.Serialize(p))).Select(x => x is Region r ? r.Name : ((Annotation)x).Kind.ToString()).SequenceEqual(["R1", "R2", "Line", "Rectangle"]),
            "the layer order is saved in the project and comes back");
        // Old projects (every Order 0) keep their drawing order: redactions in list order, annotations above them.
        var old = new RedactionProject { Media = media, Regions = [Box("A", 0, 0, 5, 5), Box("B", 5, 5, 5, 5)], Annotations = [new Annotation { Kind = AnnotationKind.Line, Points = [new(0, 0), new(9, 9)] }] };
        check(Layers.Stack(old).Select(x => x is Region r ? r.Name : "line").SequenceEqual(["A", "B", "line"]), "older projects without layer numbers keep the order they were drawn in");

        // What it changes in the picture: an outline under a black box is hidden; moved above it, it shows on the box.
        var box = Box("Box", 20, 10, 40, 30); box.Order = 2;
        var outline = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(10, 20, 60, 10), Width = 4, Color = "#FF0000", Order = 1 };
        var picture = new RedactionProject { Media = media, Regions = [box], Annotations = [outline] };
        BitmapSource Render() => EffectRenderer.Render(Grey(100, 60, 200), picture, 0, null, default, AnnotationRaster.Create(picture, 100, 60));
        var under = Render();
        check(At(under, 40, 20) == (0, 0, 0) && At(under, 10, 25).R == 255, $"an annotation below a redaction is hidden where the redaction is ({At(under, 40, 20)}, {At(under, 10, 25)})");
        Layers.Move(picture, outline, true);
        var over = Render();
        check(At(over, 40, 20) is { R: 255, G: 0 } && At(over, 40, 25) == (0, 0, 0), "moved above it, the annotation is drawn on top of the redaction");
        check(Pixels(over).Where((_, i) => i % 4 != 3).Count(v => v == 200) == Pixels(under).Where((_, i) => i % 4 != 3).Count(v => v == 200),
            "the order never brings back hidden picture: the same picture pixels are covered either way");
        var blur = Box("Blur", 20, 10, 40, 30); blur.Effect = RedactionEffect.Blur; blur.Order = 1;
        var stripes = new byte[100 * 60 * 4]; for (var i = 0; i < stripes.Length; i += 4) { var v = (byte)(i / 4 % 2 == 0 ? 255 : 0); stripes[i] = stripes[i + 1] = stripes[i + 2] = v; stripes[i + 3] = 255; }
        var striped = BitmapSource.Create(100, 60, 96, 96, PixelFormats.Bgra32, null, stripes, 400); striped.Freeze();
        var blurProject = new RedactionProject { Media = media, Regions = [blur], Annotations = [new Annotation { Kind = AnnotationKind.Line, Points = [new(0, 55), new(99, 55)], Order = 2 }] };
        var blurred = EffectRenderer.Render(striped, blurProject, 0, null, default, AnnotationRaster.Create(blurProject, 100, 60));
        check(At(blurred, 40, 25).R is > 60 and < 195, "an annotation above a Blur doesn't undo the blur");

        // Copies move 10 pixels so they can be seen, back the other way at an edge, and never leave the picture.
        check(Layers.CopyOffset([new MediaRect(10, 10, 20, 20)], 100, 60) == (10, 10) && Layers.CopyOffset([new MediaRect(75, 35, 20, 20)], 100, 60) == (-10, -10) &&
              Layers.CopyOffset([new MediaRect(0, 0, 100, 60)], 100, 60) == (0, 0), "a duplicate is offset by 10 pixels, inside the picture");
    }

    private static void EditorChecks(MediaTools tools, string output, Action<bool, string> check)
    {
        var temp = Path.Combine(output, "release300-layers-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release300-layers-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ShowActivated = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            Wait(async () => { await controller.DeliverAsync(Grey(200, 100, 200)); return true; });
            var editor = controller.Editor!; var preview = (PreviewSurface)editor.FindName("Preview");
            T Find<T>(string name) where T : class => (T)editor.FindName(name);
            void Refresh() { typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(editor, null); editor.UpdateLayout(); }
            void Undo() => Wait(() => editor.StepHistoryAsync(true));
            var status = Find<TextBlock>("Status");
            if (Find<Border>("PropertiesPanel").Visibility != Visibility.Visible) editor.ToggleProperties(editor, new RoutedEventArgs());
            editor.UpdateLayout();

            var bottom = Box("Bottom", 10, 10, 40, 30); var top = Box("Top", 60, 10, 40, 30, "#FF0000");
            var arrow = new Annotation { Kind = AnnotationKind.Line, Points = [new(20, 80), new(120, 80)], Width = 4, Color = "#0000FF" };
            var outline = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(130, 40, 50, 40), Width = 3, Color = "#00FF00" };
            bottom.Order = 1; top.Order = 2; arrow.Order = 3; outline.Order = 4;
            preview.Project.Regions.AddRange([bottom, top]); preview.Project.Annotations.AddRange([arrow, outline]); Refresh();
            var regions = Find<ListBox>("Regions"); var annotations = Find<ListBox>("AnnotationsList");
            check(regions.Items.Cast<Region>().SequenceEqual([top, bottom]) && annotations.Items.Cast<Annotation>().SequenceEqual([outline, arrow]), "both lists show the top layer first");
            var up = Find<Button>("RegionUpButton"); var down = Find<Button>("RegionDownButton");
            check(up.IsVisible && down.IsVisible && Find<Button>("AnnotationUpButton").IsVisible && Find<Button>("AnnotationDownButton").IsVisible,
                "up and down arrows sit beside the Regions and Annotations lists");
            var listBox = regions.TransformToAncestor(editor).TransformBounds(new Rect(regions.RenderSize)); var arrowBox = up.TransformToAncestor(editor).TransformBounds(new Rect(up.RenderSize));
            check(arrowBox.Left >= listBox.Right - 1 && arrowBox.Top >= listBox.Top - 1 && arrowBox.Bottom <= listBox.Bottom + 1, "the arrows are just to the right of the list");
            check(!up.IsEnabled && !down.IsEnabled && !Find<Button>("DuplicateRegionButton").IsEnabled, "with nothing selected the arrows and Duplicate are off");
            void Shot(string name)
            {
                editor.UpdateLayout();
                var bitmap = new RenderTargetBitmap((int)editor.ActualWidth, (int)editor.ActualHeight, 96, 96, PixelFormats.Pbgra32); bitmap.Render(editor);
                var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(bitmap)); using var file = File.Create(Path.Combine(output, name)); png.Save(file);
            }
            preview.Selected = bottom; Refresh();
            Shot("layers-pane.png");
            check(up.IsEnabled && !down.IsEnabled, "for the bottom redaction, only Move Up is on");
            Click(up);
            check(regions.Items.Cast<Region>().SequenceEqual([bottom, top]) && preview.Project.Regions.SequenceEqual([top, bottom]) && regions.SelectedItem == bottom && status.Text.Contains("above \"Top\""),
                "Move Up puts the redaction above the other one, keeps it selected, and says so");
            Undo(); Refresh();
            check(preview.Project.Regions.Select(r => r.Name).SequenceEqual(["Bottom", "Top"]), "Undo puts the layers back");
            bottom = preview.Project.Regions[0]; top = preview.Project.Regions[1]; arrow = preview.Project.Annotations.Single(a => a.Kind == AnnotationKind.Line); outline = preview.Project.Annotations.Single(a => a.Kind == AnnotationKind.Rectangle);
            preview.Selected = null; preview.SelectAnnotation(arrow); Refresh();
            check(Find<Button>("AnnotationUpButton").IsEnabled && Find<Button>("AnnotationDownButton").IsEnabled && !up.IsEnabled && !down.IsEnabled,
                "an annotation's arrows are on for it (it can go below the redactions too); the Regions arrows are off");
            Click(Find<Button>("AnnotationUpButton"));
            check(annotations.Items.Cast<Annotation>().First() == arrow, "Move Up on the Annotations list moves the annotation up");
            check(editor.MoveSelectedLayer(false, null) && annotations.Items.Cast<Annotation>().Last() == arrow, "Edit › Layers › Move Down (Ctrl+[) moves the selected layer down");

            // Duplicate.
            preview.SelectAnnotation(null); preview.Selected = top; Refresh();
            Click(Find<Button>("DuplicateRegionButton"));
            var copy = preview.Project.Regions.Last();
            check(preview.Project.Regions.Count == 3 && copy != top && copy.Id != top.Id && copy.Name == "Top Copy" && copy.GeometryAt(0) == new MediaRect(70, 20, 40, 30) &&
                  copy.Color == top.Color && preview.Selected == copy && regions.Items.Cast<Region>().First() == copy, "Duplicate makes a selected copy on top, 10 pixels right and down");
            Undo(); Refresh();
            check(preview.Project.Regions.Count == 2, "Undo removes the copy");
            preview.Selected = null; preview.SelectAnnotation(preview.Project.Annotations.Single(a => a.Kind == AnnotationKind.Rectangle)); Refresh();
            check(editor.DuplicateSelectedLayer(null) && preview.Project.Annotations.Count == 3 && preview.SelectedAnnotation is { Kind: AnnotationKind.Rectangle } dup && dup.Box == new MediaRect(140, 50, 50, 40),
                "Duplicate Layer (Ctrl+D) copies an annotation too");
            Undo(); Refresh();
            check(Find<MenuItem>("LayersMenu").Items.OfType<MenuItem>().Select(m => (string)m.Header).SequenceEqual(["Move _Up", "Move _Down", "Du_plicate Layer", "Delete _Layer", "_Flatten Image"]),
                "Edit › Layers has Move Up, Move Down, Duplicate Layer, Delete Layer and Flatten Image");

            // Flatten Image.
            var before = preview.Project.Media!; var flatten = Find<Button>("FlattenImageButton");
            check(flatten.IsEnabled, "Flatten Image is on for a picture with layers");
            check(Wait(() => editor.FlattenImageAsync()), "Flatten Image runs");
            var flat = preview.Image!;
            check(preview.Project.Regions.Count == 0 && preview.Project.Annotations.Count == 0 && preview.Project.Media!.Path != before.Path && Path.GetFileName(preview.Project.Media.Path).StartsWith("EDITED_") &&
                  controller.Store.Owns(preview.Project.Media.Path) && File.Exists(before.Path), "after Flatten the lists are empty and the picture is a working copy (the original is kept)");
            check(At(flat, 30, 20) == (0, 0, 0) && At(flat, 80, 20) == (0, 0, 255) && At(flat, 70, 80) == (255, 0, 0) && At(flat, 5, 95) == (200, 200, 200),
                "the redactions and annotations are now part of the picture");
            check(!flatten.IsEnabled, "with nothing left, Flatten Image is off");
            Undo(); Refresh();
            check(preview.Project.Regions.Count == 2 && preview.Project.Annotations.Count == 2 && preview.Project.Media!.Path == before.Path && At(preview.Image!, 30, 20) == (200, 200, 200),
                "Undo separates them again, on the original picture");

            // A video: Flatten is off; an annotation's own window has green Begin Here and red End Here.
            var video = Wait(() => TrackingChecks.WriteVideo(tools, output, false));
            check(Wait(() => editor.OpenPathAsync(video)), "a video opens");
            var map = preview.Timeline!;
            var mark = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(20, 20, 40, 30), Width = 3, Start = 0, End = map.Frames[^1].Time, Order = 1 };
            var note = new Annotation { Kind = AnnotationKind.Text, Box = new(70, 20, 50, 20), Text = "Hi", Start = 0, End = map.Frames[^1].Time, Order = 2 };
            preview.Project.Annotations.AddRange([mark, note]); Refresh();
            check(!flatten.IsEnabled, "Flatten Image is off for a video");
            var seek = typeof(MainWindow).GetMethod("SeekExact", BindingFlags.NonPublic | BindingFlags.Instance, [typeof(double)])!;
            Wait(() => (Task<bool>)seek.Invoke(editor, [map.Frames[6].Time])!);
            preview.SelectAnnotation(mark); Refresh();
            var popup = Find<Border>("LinePopup"); var begin = Find<Button>("LinePopupBegin"); var end = Find<Button>("LinePopupEnd");
            Shot("layers-video-popup.png");
            check(popup.IsVisible && begin.IsVisible && end.IsVisible && Find<StackPanel>("LinePopupStyle").IsVisible, "a video annotation's window shows Begin Here and End Here");
            check(begin.Background is SolidColorBrush { Color: { R: 0x2E, G: 0x7D, B: 0x32 } } && end.Background is SolidColorBrush { Color: { R: 0xB3, G: 0x26, B: 0x1E } } &&
                  (string)begin.Content == "Begin Here" && (string)end.Content == "End Here", "Begin Here is green and End Here is red");
            Click(end);
            check(Until(() => Math.Abs(mark.End - map.Frames[6].Time) < 1e-9) && mark.Start == 0, "End Here ends the annotation on the frame shown");
            Wait(() => (Task<bool>)seek.Invoke(editor, [map.Frames[2].Time])!);
            preview.SelectAnnotation(mark); Refresh();
            Click(begin);
            check(Until(() => Math.Abs(mark.Start - map.Frames[2].Time) < 1e-9) && Math.Abs(mark.End - map.Frames[6].Time) < 1e-9, "Begin Here starts it on the frame shown");
            preview.SelectAnnotation(note); Refresh();
            check(popup.IsVisible && begin.IsVisible && !Find<StackPanel>("LinePopupStyle").IsVisible, "a text on a video gets the window too, with just Begin Here, End Here and Delete");

            // Video crop in the editor.
            preview.SelectAnnotation(null); Refresh();
            var cropTool = Find<Button>("CropTool");
            check(cropTool.IsEnabled, "Crop is on for a video");
            Click(cropTool);
            preview.CropDraft = new MediaRect(11, 7, 51, 41); Refresh();
            check(Find<Button>("ConfirmCropButton").IsEnabled, "a crop box can be drawn on a video");
            editor.ConfirmCropDraft();
            check(preview.Project.Crop == new MediaRect(11, 7, 50, 40), "a video crop is whole pixels with an even width and height");
            check(Find<TextBlock>("SizeText").Text.Contains("50 × 40"), "the size shown is the cropped size");
            Undo(); Refresh();
            check(preview.Project.Crop == null, "Undo takes the video crop off");
            editor.Close();
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }

    // ---- Cropped video export: every frame is the crop of what the uncropped export would show. ----
    private static void VideoCropExport(MediaTools tools, string output, Action<bool, string> check)
    {
        // The synthetic video with sound is made later in a full run; a fresh test-output folder uses the silent test video.
        var source = Path.Combine(output, "synthetic-with-audio.mp4");
        var sound = File.Exists(source);
        if (!sound) source = Wait(() => TrackingChecks.WriteVideo(tools, output, false));
        var map = Wait(() => tools.ProbeTimelineAsync(source, CancellationToken.None));
        var first = Wait(() => tools.FrameAsync(source, map.Frames[0], null, CancellationToken.None));
        var media = new MediaReference(source, new FileInfo(source).Length, Wait(() => ProjectStore.HashAsync(source)), first.PixelWidth, first.PixelHeight, map.Frames[^1].Time + map.Frames[^1].Duration, true);
        var box = Box("Box", 4, 4, 20, 16, "#000000", media.Duration);
        var label = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(30, 10, 20, 20), Width = 3, Color = "#FF0000", Start = 0, End = map.Frames[^1].Time, Order = 5 };
        var crop = new MediaRect(2, 2, 60, 40);
        var project = new RedactionProject { Media = media, Regions = [box], Annotations = [label], Crop = crop, Export = new() { KeepAudio = sound } };
        var exporter = new VideoExport(tools);
        foreach (var extension in new[] { ".mp4", ".webm" })
        {
            var destination = Path.Combine(output, "release300-cropped" + extension); if (File.Exists(destination)) File.Delete(destination);
            Wait(async () => { await exporter.ExportAsync(destination, project, map, new(), null, CancellationToken.None); return true; });
            var exported = Wait(() => tools.ProbeTimelineAsync(destination, CancellationToken.None));
            var frame = Wait(() => tools.FrameAsync(destination, exported.Frames[3], null, CancellationToken.None));
            check(frame.PixelWidth == 60 && frame.PixelHeight == 40 && exported.Frames.Count == map.Frames.Count, $"a cropped video exports at the crop's size, with every frame ({extension})");
            if (extension != ".mp4") continue;
            var worst = 0d;
            for (var i = 0; i < map.Frames.Count; i++)
            {
                var exact = Wait(() => tools.FrameAsync(source, map.Frames[i], null, CancellationToken.None));
                var full = EffectRenderer.Render(exact, project, map.Frames[i].Time, map, default, AnnotationRaster.Create(project, media.Width, media.Height));
                var expected = Pixels(new CroppedBitmap(full, new Int32Rect(2, 2, 60, 40)));
                var actual = Pixels(Wait(() => tools.FrameAsync(destination, exported.Frames[i], null, CancellationToken.None)));
                worst = Math.Max(worst, expected.Zip(actual).Select((p, index) => index % 4 == 3 ? 0 : Math.Abs(p.First - p.Second)).Average());
            }
            check(worst < 9, $"each exported frame is the crop of the redacted, annotated frame (worst average difference {worst:0.0})");
            check(At(frame, 10, 10) is { R: < 40, G: < 40, B: < 40 }, "the redaction is still there in the cropped video");
        }
        var json = Wait(() => tools.RunAsync("ffprobe.exe", ["-v", "error", "-show_entries", "stream=codec_type,pix_fmt", "-of", "csv=p=0", Path.Combine(output, "release300-cropped.mp4")], source, CancellationToken.None));
        var streams = System.Text.Encoding.UTF8.GetString(json);
        check(streams.Contains("yuv420p") && streams.Contains("audio") == sound, "the cropped MP4 uses the usual colour format and keeps the sound when asked");
        check(Wait(() => ProjectStore.HashAsync(source)) == media.Sha256, "the original video is unchanged");
    }
}
