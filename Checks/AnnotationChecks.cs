using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.9.0 Text, Line and Polyline annotations (baseline v2.5.1 behaviour).
internal static class AnnotationChecks
{
    private const int W = 200, H = 100;
    private static BitmapSource White()
    {
        var pixels = new byte[W * H * 4]; Array.Fill(pixels, (byte)255);
        var image = BitmapSource.Create(W, H, 96, 96, PixelFormats.Bgra32, null, pixels, W * 4); image.Freeze(); return image;
    }
    private static Annotation Line(double x1, double y1, double x2, double y2, long order, int width = 4) =>
        new() { Kind = AnnotationKind.Line, Points = [new(x1, y1), new(x2, y2)], Width = width, Color = "#FF0000", Order = order };
    private static byte[] Pixels(BitmapSource image)
    {
        var converted = new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0);
        var pixels = new byte[converted.PixelWidth * converted.PixelHeight * 4]; converted.CopyPixels(pixels, converted.PixelWidth * 4, 0); return pixels;
    }
    private static bool Red(byte[] p, int width, int x, int y, int tolerance = 60) { var i = (y * width + x) * 4; return p[i + 2] > 255 - tolerance && p[i + 1] < tolerance && p[i] < tolerance; }
    private static bool Shade(byte[] p, int width, int x, int y, int value, int tolerance = 40) { var i = (y * width + x) * 4; return Math.Abs(p[i] - value) <= tolerance && Math.Abs(p[i + 1] - value) <= tolerance && Math.Abs(p[i + 2] - value) <= tolerance; }

    // Model, persistence, validation, exact timing and the shared renderer.
    public static void RunModel(string output, Action<bool, string> check)
    {
        var media = new MediaReference(Path.Combine(output, "annotation-model.png"), 1, new string('0', 64), W, H, 0, false);
        var plain = new RedactionProject { Media = media };
        var box = new Region { Shape = RegionShape.Rectangle, Start = 0, End = 0 }; box.PutManual(0, new(10, 10, 20, 20)); plain.Regions.Add(box);
        var plainJson = ProjectStore.Serialize(plain);
        check(!plainJson.Contains("\"Annotations\"") && !plainJson.Contains("\"Order\""), "projects without annotations keep the 0.8 file layout");
        var project = ProjectStore.Deserialize(plainJson);
        project.Annotations.Add(new Annotation { Kind = AnnotationKind.Text, Box = new(20, 20, 120, 40), Text = "Hello\nworld", FontFamily = "Arial", FontSize = 30, Bold = true, Italic = true, Align = AnnotationAlign.Right, Color = "#00FF00", Order = 1 });
        project.Annotations.Add(new Annotation { Kind = AnnotationKind.Polyline, Points = [new(5, 5), new(50, 5), new(50, 60)], Width = 7, Dash = AnnotationDash.DashDot, Ends = AnnotationEnds.ArrowBoth, Join = AnnotationJoin.Round, Order = 2 });
        var restored = ProjectStore.Deserialize(ProjectStore.Serialize(project));
        var text = restored.Annotations[0]; var poly = restored.Annotations[1];
        check(restored.Annotations.Count == 2 && text.Text == "Hello\nworld" && text.FontFamily == "Arial" && text.FontSize == 30 && text.Bold && text.Italic && text.Align == AnnotationAlign.Right && text.Box == new MediaRect(20, 20, 120, 40) &&
              poly.Points.Count == 3 && poly.Width == 7 && poly.Dash == AnnotationDash.DashDot && poly.Ends == AnnotationEnds.ArrowBoth && poly.Join == AnnotationJoin.Round && poly.Order == 2,
            "annotations and their styles survive save and load");
        var history = new EditHistory(); history.Checkpoint(restored); restored.Annotations.RemoveAt(1);
        restored = history.Undo(restored);
        check(restored.Annotations.Count == 2 && restored.Annotations[1].Kind == AnnotationKind.Polyline, "Undo restores a removed annotation");
        check(AnnotationRules.NextOrder(restored) == 3, "new objects take the next shared creation order");
        void Rejects(Action<Annotation> change, string name)
        {
            var candidate = ProjectStore.Deserialize(ProjectStore.Serialize(project)); change(candidate.Annotations[0].Kind == AnnotationKind.Text && name.StartsWith("line", StringComparison.Ordinal) ? candidate.Annotations[1] : candidate.Annotations[0]);
            try { ProjectStore.Validate(candidate); } catch (InvalidDataException) { check(true, "validation rejects " + name); return; }
            check(false, "validation rejects " + name);
        }
        Rejects(a => a.Text = "  ", "empty text");
        Rejects(a => a.FontSize = 5, "a font below 6 px");
        Rejects(a => a.FontSize = 201, "a font above 200 px");
        Rejects(a => a.Color = "red", "a malformed colour");
        Rejects(a => a.Start = 1, "timing on a still image");
        Rejects(a => a.Box = new(150, 20, 80, 20), "a text box outside the media");
        Rejects(a => a.Width = 21, "line width above 20");
        Rejects(a => a.Points = [new(5, 5)], "line with a single point");
        Rejects(a => { a.Kind = AnnotationKind.Line; }, "line kind with three points");
        Rejects(a => a.Points = [new(5, 5), new(300, 5)], "line point outside the media");
        Rejects(a => a.Id = project.Regions[0].Id, "line sharing a region identity");

        // Exact inclusive annotation frames versus the two-frame redaction buffer.
        var map = new FrameTimeline(Enumerable.Range(0, 10).Select(i => new FrameStamp(i, i, 1)));
        var timed = new Annotation { Start = 3, End = 5 }; var buffered = new Region { Start = 3, End = 5 };
        check(Enumerable.Range(0, 10).Where(i => map.IsActive(timed, i)).SequenceEqual([3, 4, 5]) &&
              Enumerable.Range(0, 10).Where(i => map.IsActive(buffered, i)).SequenceEqual([1, 2, 3, 4, 5, 6, 7]), "annotations use exact inclusive frames without the redaction buffer");

        // Shared renderer: drawing, arrowheads, text, layering against redactions.
        var still = new RedactionProject { Media = media };
        var line = Line(20, 50, 180, 50, 1); still.Annotations.Add(line);
        var pixels = Pixels(EffectRenderer.Render(White(), still, 0, null, default, AnnotationRaster.Create(still, W, H)));
        check(Red(pixels, W, 100, 50) && Shade(pixels, W, 100, 40, 255, 5), "a line renders in its colour and nowhere else");
        check(Shade(Pixels(EffectRenderer.Render(White(), still, 0, null)), W, 100, 50, 255, 5), "the live preview image leaves annotations to the vector overlay");
        line.Ends = AnnotationEnds.ArrowEnd; line.Width = 2;
        var arrow = Pixels(EffectRenderer.Render(White(), still, 0, null, default, AnnotationRaster.Create(still, W, H)));
        line.Ends = AnnotationEnds.None;
        var plainLine = Pixels(EffectRenderer.Render(White(), still, 0, null, default, AnnotationRaster.Create(still, W, H)));
        // Width 2: head 8 px long, 6 px wide at its base (x 172), so row 51 at x 174 is inside the head only.
        check(Red(arrow, W, 174, 51, 90) && !Red(plainLine, W, 174, 51, 90), "an arrow end draws a filled head wider than the line");
        line.Width = 4;
        var cover = new Region { Shape = RegionShape.Rectangle, Effect = RedactionEffect.Opaque, Color = "#000000", Start = 0, End = 0, Order = 5 }; cover.PutManual(0, new(90, 40, 20, 20)); still.Regions.Add(cover);
        line.Order = 3;
        pixels = Pixels(EffectRenderer.Render(White(), still, 0, null, default, AnnotationRaster.Create(still, W, H)));
        check(Shade(pixels, W, 100, 50, 0, 5) && Red(pixels, W, 60, 50), "a redaction committed later covers an earlier annotation");
        line.Order = 7;
        pixels = Pixels(EffectRenderer.Render(White(), still, 0, null, default, AnnotationRaster.Create(still, W, H)));
        check(Red(pixels, W, 100, 50), "an annotation committed later is drawn over an earlier redaction");
        still.Regions.Clear(); still.Annotations.Clear();
        still.Annotations.Add(new Annotation { Kind = AnnotationKind.Text, Box = new(40, 20, 120, 60), Text = "TEST", FontSize = 40, Bold = true, Color = "#FF0000", Order = 1 });
        pixels = Pixels(EffectRenderer.Render(White(), still, 0, null, default, AnnotationRaster.Create(still, W, H)));
        var inside = 0; var outside = 0;
        for (var y = 0; y < H; y++) for (var x = 0; x < W; x++)
            if (!Shade(pixels, W, x, y, 255, 10)) { if (x >= 40 && x < 160 && y >= 20 && y < 80) inside++; else outside++; }
        check(inside > 150 && outside == 0, "text renders inside its box and is clipped to it");
        still.Annotations[0].Box = new(40, 20, 120, 30);
        pixels = Pixels(EffectRenderer.Render(White(), still, 0, null, default, AnnotationRaster.Create(still, W, H)));
        inside = 0; outside = 0;
        for (var y = 0; y < H; y++) for (var x = 0; x < W; x++)
            if (!Shade(pixels, W, x, y, 255, 10)) { if (x >= 40 && x < 160 && y >= 20 && y < 50) inside++; else outside++; }
        check(inside > 150 && outside == 0, "text taller than its box still shows, cut at the box edge");
        var offThread = Task.Run(() => AnnotationRaster.Create(still, W, H)).GetAwaiter().GetResult();
        check(offThread?.Layers.Count == 1, "annotation layers can be prepared from an export worker thread");

        // Coloured-box video overlay: exact frames and later-redaction cover.
        var video = new RedactionProject { Media = media with { Duration = 10, IsVideo = true } };
        var timedLine = Line(20, 50, 180, 50, 1); timedLine.Start = 3; timedLine.End = 5; video.Annotations.Add(timedLine);
        var raster = AnnotationRaster.Create(video, W, H);
        bool Drawn(int frame) => VideoExport.OverlayPixels(video, map, frame, raster)[(50 * W + 100) * 4 + 3] > 200;
        check(!Drawn(2) && Drawn(3) && Drawn(5) && !Drawn(6), "video overlays draw an annotation on exactly its inclusive frames");
        var videoCover = new Region { Shape = RegionShape.Rectangle, Color = "#000000", Start = 0, End = 10, Order = 9 }; videoCover.PutManual(0, new(90, 40, 20, 20)); video.Regions.Add(videoCover);
        var overlay = VideoExport.OverlayPixels(video, map, 4, raster);
        check(overlay[(50 * W + 100) * 4 + 2] == 0 && overlay[(50 * W + 100) * 4 + 3] == 255 && overlay[(50 * W + 60) * 4 + 2] > 200, "video overlays let a later redaction cover the annotation");
    }

    // Validated still exports (PNG and lossy) with annotations, including text over a coloured box.
    public static async Task RunStillExport(MediaTools tools, string output, Action<bool, string> check)
    {
        var sourcePath = Path.Combine(output, "annotation-source.png"); if (File.Exists(sourcePath)) File.Delete(sourcePath);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(White()));
        using (var file = File.Create(sourcePath)) encoder.Save(file);
        var project = new RedactionProject { Media = new(sourcePath, new FileInfo(sourcePath).Length, await ProjectStore.HashAsync(sourcePath), W, H, 0, false) };
        var box = new Region { Shape = RegionShape.Rectangle, Color = "#000000", Start = 0, End = 0, ShowDecorations = false, Order = 1 }; box.PutManual(0, new(100, 10, 90, 80)); project.Regions.Add(box);
        project.Annotations.Add(Line(10, 50, 90, 50, 2, 6));
        project.Annotations.Add(new Annotation { Kind = AnnotationKind.Text, Box = new(105, 20, 80, 60), Text = "Note", FontSize = 30, Color = "#FFFFFF", Order = 3 });
        foreach (var extension in new[] { ".png", ".jpg", ".webp" })
        {
            var destination = Path.Combine(output, "annotated" + extension); if (File.Exists(destination)) File.Delete(destination);
            await ImageExport.ExportAsync(destination, project, new(), White(), CancellationToken.None, tools);
            var decoded = Pixels(await tools.FrameAsync(destination, null, null, CancellationToken.None));
            var whiteText = 0; for (var y = 20; y < 80; y++) for (var x = 105; x < 185; x++) if (Shade(decoded, W, x, y, 255, 60)) whiteText++;
            check(Red(decoded, W, 50, 50, 70) && Shade(decoded, W, 150, 85, 0, 40) && whiteText > 40, extension + " export draws the line and the text over the box, validated");
        }
        // Annotation-only projects can be exported.
        project.Regions.Clear();
        var only = Path.Combine(output, "annotated-only.png"); if (File.Exists(only)) File.Delete(only);
        await ImageExport.ExportAsync(only, project, new(), White(), CancellationToken.None, tools);
        check(File.Exists(only), "a project with only annotations can be exported");
    }

    // Real FFmpeg video exports: coloured-box overlay path and the Blur/Pixelate path.
    public static async Task RunVideoExport(MediaTools tools, string output, Action<bool, string> check)
    {
        var exporter = new VideoExport(tools);
        var source = Path.Combine(output, "synthetic-with-audio.mp4"); var map = await tools.ProbeTimelineAsync(source, CancellationToken.None);
        var first = await tools.FrameAsync(source, map.Frames[0], null, CancellationToken.None);
        int width = first.PixelWidth, height = first.PixelHeight;
        foreach (var withBlur in new[] { false, true })
        {
            var project = new RedactionProject { Media = new(source, new FileInfo(source).Length, await ProjectStore.HashAsync(source), width, height, map.Frames[^1].Time + map.Frames[^1].Duration, true) };
            var line = Line(4, height / 2.0, width - 4, height / 2.0, 1, 8); line.Start = map.Frames[4].Time; line.End = map.Frames[6].Time; project.Annotations.Add(line);
            if (withBlur) { var blur = new Region { Effect = RedactionEffect.Blur, Start = 0, End = project.Media.Duration, Order = 2 }; blur.PutManual(0, new(2, 2, 12, 12)); project.Regions.Add(blur); }
            var destination = Path.Combine(output, withBlur ? "annotated-effect.mp4" : "annotated-overlay.mp4"); if (File.Exists(destination)) File.Delete(destination);
            await exporter.ExportAsync(destination, project, map, new(), null, CancellationToken.None);
            var exported = await tools.ProbeTimelineAsync(destination, CancellationToken.None);
            var shown = new List<int>();
            for (var i = 2; i <= 8; i++)
            {
                var pixels = Pixels(await tools.FrameAsync(destination, exported.Frames[i], null, CancellationToken.None));
                if (Red(pixels, width, width / 2, height / 2, 90)) shown.Add(i);
            }
            check(shown.SequenceEqual([4, 5, 6]), $"{(withBlur ? "effect" : "coloured-box")} video export draws the annotation on exactly frames 5–7 (got {string.Join(",", shown.Select(i => i + 1))})");
        }
    }

    // The actual WPF editor: gestures, text editor, options, undo and video timing.
    public static void RunUi(string output, Action<bool, string> check)
    {
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        try
        {
            var refresh = typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!;
            var undo = typeof(MainWindow).GetMethod("Undo", BindingFlags.Instance | BindingFlags.NonPublic)!;
            var redo = typeof(MainWindow).GetMethod("Redo", BindingFlags.Instance | BindingFlags.NonPublic)!;
            preview.Image = White();
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "annotation-ui.png"), 1, new string('0', 64), W, H, 0, false) };
            refresh.Invoke(window, null);
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / W, preview.ActualHeight / H);
            Point At(double x, double y) => new((preview.ActualWidth - W * scale) / 2 + x * scale, (preview.ActualHeight - H * scale) / 2 + y * scale);
            void Click(Point p, int count = 1) { preview.PointerDown(p, MouseButton.Left, count); preview.PointerUp(); }
            void Drag(params Point[] path) { preview.PointerDown(path[0], MouseButton.Left); foreach (var p in path.Skip(1)) preview.PointerMove(p); preview.PointerUp(); }
            void Tool(string name) => ((Button)window.FindName(name)).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            var annotations = preview.Project.Annotations;

            // A redaction drawn first, so creation order can be compared.
            Tool("RectangleTool"); Drag(At(150, 10), At(190, 40));
            var region = preview.Project.Regions.Single();
            Tool("LineTool");
            check(((StackPanel)window.FindName("AnnotationOptions")).Visibility == Visibility.Visible && ((StackPanel)window.FindName("EffectOptions")).Visibility == Visibility.Collapsed,
                "choosing Line shows the annotation options in place of the effect options");
            Click(At(30, 70));
            check(annotations.Count == 0 && preview.Selected == null, "Line: a plain click accepts the selection and draws nothing");
            Drag(At(20, 20), At(60, 40), At(100, 60));
            var line = annotations.SingleOrDefault();
            check(line is { Kind: AnnotationKind.Line } && Math.Abs(line.Points[0].X - 20) < 1 && Math.Abs(line.Points[1].X - 100) < 1 && Math.Abs(line.Points[1].Y - 60) < 1 &&
                  preview.SelectedAnnotation == line && line.Order > region.Order && line.Color == "#FF0000" && line.Width == 6 && line.Ends == AnnotationEnds.ArrowEnd, "Line: dragging draws a red 6-pixel arrow above earlier redactions (0.15.0 defaults)");
            undo.Invoke(window, [window, new RoutedEventArgs()]);
            check(preview.Project.Annotations.Count == 0, "Undo removes a new line");
            redo.Invoke(window, [window, new RoutedEventArgs()]);
            annotations = preview.Project.Annotations; line = annotations.Single();
            check(annotations.Count == 1, "Redo restores it");
            preview.SelectAnnotation(line); window.UpdateLayout();
            var widthBox = (NumberSpinner)window.FindName("AnnotationWidth"); widthBox.Value = 10;
            check(line.Width == 10, "options bar changes the selected annotation");
            undo.Invoke(window, [window, new RoutedEventArgs()]); annotations = preview.Project.Annotations; line = annotations.Single();
            check(line.Width == 6, "Undo restores the previous style");
            var before = line.Points.ToArray();
            Drag(At(60, 40), At(70, 45));
            line = preview.Project.Annotations.Single();
            check(Math.Abs(line.Points[0].X - before[0].X - 10) < 1 && Math.Abs(line.Points[1].Y - before[1].Y - 5) < 1, "dragging a selected line moves it");
            Click(At(150, 80));
            check(preview.SelectedAnnotation == null && preview.Project.Annotations.Count == 1, "a click outside accepts the line without drawing another");

            Tool("PolylineTool");
            Drag(At(10, 90), At(40, 90), At(80, 90), At(80, 85), At(80, 70), At(80, 60));
            var polyline = preview.Project.Annotations.Last();
            check(polyline.Kind == AnnotationKind.Polyline && polyline.Points.Count == 3 && Math.Abs(polyline.Points[0].Y - polyline.Points[1].Y) < 0.01 && Math.Abs(polyline.Points[1].X - polyline.Points[2].X) < 0.01 &&
                  Math.Abs(polyline.Points[2].Y - 60) < 1, "Polyline: a held drag draws an axis-locked path with a right-angled corner");

            Tool("TextTool");
            var panel = (Border)window.FindName("TextEditorPanel"); var textBox = (TextBox)window.FindName("AnnotationTextBox");
            Drag(At(20, 10), At(60, 20), At(120, 40));
            check(panel.Visibility == Visibility.Visible && preview.EditingText != null && preview.Project.Annotations.Count == 2, "Text: dragging a box opens the floating editor without adding anything yet");
            textBox.Text = "Line one\nLine two";
            Click(At(150, 90));
            var text = preview.Project.Annotations.LastOrDefault();
            check(panel.Visibility == Visibility.Collapsed && text is { Kind: AnnotationKind.Text, Text: "Line one\nLine two" } && preview.Project.Annotations.Count == 3 && preview.EditingText == null,
                "Text: a click outside confirms the multiline text and is consumed");
            Drag(At(20, 60), At(60, 80), At(100, 90)); textBox.Text = "discard me"; window.CloseTextEditor(true);
            check(preview.Project.Annotations.Count == 3 && panel.Visibility == Visibility.Collapsed, "Text: Escape discards a new text");
            Drag(At(20, 60), At(60, 80), At(100, 90)); textBox.Text = "   "; window.CloseTextEditor(false);
            check(preview.Project.Annotations.Count == 3, "Text: empty text is never added");
            Click(At(40, 25), 2);
            check(panel.Visibility == Visibility.Visible && textBox.Text == "Line one\nLine two", "Text: double-click reopens the editor");
            textBox.Text = "changed"; window.CloseTextEditor(true);
            check(text!.Text == "Line one\nLine two", "Text: Escape keeps the previous text");
            Click(At(40, 25), 2); textBox.Text = "Edited"; window.CloseTextEditor(false);
            check(text.Text == "Edited", "Text: Done stores the edited text");
            Click(At(40, 25), 2); textBox.Text = ""; window.CloseTextEditor(false);
            check(text.Text == "Edited", "Text: emptying an existing text keeps the previous text");
            var annotationsList = (ListBox)window.FindName("AnnotationsList");
            check(annotationsList.Items.Count == 3, "the Annotations panel lists every annotation");
            preview.SelectAnnotation(text); window.UpdateLayout(); preview.InvalidateVisual(); window.UpdateLayout();
            var shot = new RenderTargetBitmap((int)window.ActualWidth, (int)window.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(window);
            var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot)); using (var file = File.Create(Path.Combine(output, "shell-annotations.png"))) png.Save(file);
            window.RaiseEvent(new KeyEventArgs(Keyboard.PrimaryDevice, PresentationSource.FromVisual(window)!, 0, Key.Delete) { RoutedEvent = Keyboard.PreviewKeyDownEvent });
            check(preview.Project.Annotations.Count == 2 && !preview.Project.Annotations.Contains(text), "Delete removes the selected annotation");

            // Video: a new annotation starts at the shown frame and runs to the end; Begin/End here are exact.
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "annotation-ui.mp4"), 1, new string('0', 64), W, H, 10, true) };
            preview.Timeline = new FrameTimeline(Enumerable.Range(0, 10).Select(i => new FrameStamp(i, i, 1))); preview.Time = 2;
            refresh.Invoke(window, null); window.UpdateLayout();
            Tool("LineTool"); Drag(At(20, 20), At(60, 40), At(100, 60));
            var timed = preview.Project.Annotations.Single();
            check(timed.Start == 2 && timed.End == 9, "video: a new annotation starts at the shown frame and runs to the last frame");
            preview.Time = 6;
            typeof(MainWindow).GetMethod("SetAnnotationBoundary", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(window, [false]);
            check(timed.End == 6 && preview.Timeline.IsActive(timed, 6) && !preview.Timeline.IsActive(timed, 7), "video: End here makes the shown frame the last annotated frame");
            preview.Time = 4;
            typeof(MainWindow).GetMethod("SetAnnotationBoundary", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(window, [true]);
            check(timed.Start == 4 && !preview.Timeline.IsActive(timed, 3), "video: Begin here makes the shown frame the first annotated frame");
            preview.Timeline = null;
        }
        finally { preview.Project = new(); preview.Selected = null; preview.SelectAnnotation(null); window.Close(); }
    }
}
