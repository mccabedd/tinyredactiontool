using System.IO;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.19.0: turning shapes (rotate handle, Edit › Transform), turning the whole picture or video
// (Edit › Rotate) and the marching-ants Select.
internal static class Release019Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(3);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.19.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static BitmapSource Grey(int width, int height, byte value)
    {
        var pixels = new byte[width * height * 4]; Array.Fill(pixels, value);
        for (var i = 3; i < pixels.Length; i += 4) pixels[i] = 255;
        var image = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4); image.Freeze(); return image;
    }
    private static byte Blue(BitmapSource image, int x, int y)
    {
        var bgra = new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0); var pixel = new byte[4];
        bgra.CopyPixels(new Int32Rect(x, y, 1, 1), pixel, 4, 0); return pixel[0];
    }
    private static Region Box(double x, double y, double w, double h, double rotation = 0, RegionShape shape = RegionShape.Rectangle)
    {
        var r = new Region { Name = "Box", Start = 0, End = 0, Shape = shape, Rotation = rotation, ShowDecorations = false };
        r.PutManual(0, new(x, y, w, h)); return r;
    }

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- Turned redactions are covered, exported and checked exactly as drawn. ----
        var turned = Box(30, 45, 40, 10, 90);
        check(ImageExport.Covered(turned, turned.GeometryAt(0), 50, 32, 0) && !ImageExport.Covered(turned, turned.GeometryAt(0), 66, 50, 0) && ImageExport.Reach(turned, turned.GeometryAt(0)) is { Width: < 10.01, Height: > 39.99 },
            "a redaction turned 90° covers its turned outline, not its old one");
        var media = new MediaReference(Path.Combine(output, "release019.png"), 1, new string('0', 64), 100, 100, 0, false);
        var project = new RedactionProject { Media = media, Regions = [turned] };
        var rendered = EffectRenderer.Render(Grey(100, 100, 200), project, 0, null);
        check(Blue(rendered, 50, 30) == 0 && Blue(rendered, 50, 68) == 0 && Blue(rendered, 32, 50) == 200 && Blue(rendered, 68, 50) == 200, "the export renderer blacks out the turned box (up and down), not the old one (left and right)");
        var diagonal = Box(30, 45, 40, 10, 45); project.Regions = [diagonal];
        rendered = EffectRenderer.Render(Grey(100, 100, 200), project, 0, null);
        check(Blue(rendered, 62, 62) == 0 && Blue(rendered, 38, 62) == 200, "a 45° turn covers the diagonal");
        var blurred = Box(30, 45, 40, 10, 90); blurred.Effect = RedactionEffect.Pixelate; project.Regions = [blurred];
        var source = Grey(100, 100, 0); var stripes = new byte[100 * 100 * 4];
        for (var y = 0; y < 100; y++) for (var x = 0; x < 100; x++) { var v = (byte)((x + y) % 2 == 0 ? 255 : 0); var i = (y * 100 + x) * 4; stripes[i] = stripes[i + 1] = stripes[i + 2] = v; stripes[i + 3] = 255; }
        source = BitmapSource.Create(100, 100, 96, 96, PixelFormats.Bgra32, null, stripes, 400); source.Freeze();
        rendered = EffectRenderer.Render(source, project, 0, null);
        check(Blue(rendered, 50, 30) is > 60 and < 195 && Blue(rendered, 32, 50) is 0 or 255, "a turned Pixelate box changes its turned area only");
        var png = Path.Combine(output, "release019-export.png"); if (File.Exists(png)) File.Delete(png);
        var still = Path.Combine(output, "release019-source.png");
        { var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(Grey(100, 100, 200))); using var f = File.Create(still); encoder.Save(f); }
        var exportProject = new RedactionProject { Media = media with { Path = still, Length = new FileInfo(still).Length, Sha256 = Wait(() => ProjectStore.HashAsync(still)) }, Regions = [Box(30, 45, 40, 10, 90)] };
        Wait(async () => { await ImageExport.ExportAsync(png, exportProject, new(), Grey(100, 100, 200), CancellationToken.None, tools); return true; }); // Pumps the window thread the export continues on.
        var exported = BitmapFrame.Create(new Uri(png), BitmapCreateOptions.IgnoreImageCache, BitmapCacheOption.OnLoad);
        check(Blue(exported, 50, 30) == 0 && Blue(exported, 32, 50) == 200, "a turned redaction passes the validated PNG export");

        // ---- Turned annotations. ----
        var outline = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(30, 45, 40, 10), Width = 2, Rotation = 90, Color = "#0000FF" };
        var raster = AnnotationRaster.Create(new RedactionProject { Media = media, Annotations = [outline] }, 100, 100)!;
        var layer = raster.Layers.Single();
        check(layer.Height > 35 && layer.Width < 16, "an outline turned 90° is drawn standing up");
        check(new Annotation { Kind = AnnotationKind.Line, Points = [new(1, 1), new(5, 5)], Rotation = 30 } is var bad && Throws(() => AnnotationRules.Validate(new RedactionProject { Media = media, Annotations = [bad] }, media)),
            "only box annotations keep a turn angle (lines are turned by moving their points)");

        // ---- Turning the whole picture: geometry follows. ----
        var picture = new RedactionProject
        {
            Media = media with { Width = 200, Height = 100 },
            Regions = [Box(10, 20, 30, 40)],
            Annotations = [new Annotation { Kind = AnnotationKind.Line, Points = [new(0, 0), new(200, 100)] }, new Annotation { Kind = AnnotationKind.Text, Text = "Hi", Box = new(10, 10, 60, 20) }],
            Crop = new(0, 0, 100, 50),
        };
        picture.Regions.Add(Box(100, 20, 40, 20, 0, RegionShape.Polygon)); picture.Regions[1].Polygon = [new(0, 0), new(1, 0), new(0, 1)];
        var size = MainWindow.TurnProjectGeometry(picture, TurnOp.Clockwise);
        check(size == (100, 200) && picture.Regions[0].GeometryAt(0) == new MediaRect(40, 10, 40, 30) && picture.Crop == new MediaRect(50, 0, 50, 100),
            "rotating the picture 90° moves redactions and the crop with it");
        check(picture.Annotations[0].Points.SequenceEqual([new MediaPoint(100, 0), new MediaPoint(0, 200)]) && picture.Annotations[1].Rotation == 90 && picture.Regions[1].Polygon.SequenceEqual([new MediaPoint(1, 0), new MediaPoint(1, 1), new MediaPoint(0, 0)]),
            "lines, text (turned with the picture) and polygon corners follow too");
        MainWindow.TurnProjectGeometry(picture, TurnOp.CounterClockwise);
        check(picture.Regions[0].GeometryAt(0) == new MediaRect(10, 20, 30, 40) && picture.Annotations[1].Rotation == 0, "turning back puts everything where it was");

        // ---- In the editor: Edit › Rotate on a real picture and a real video; Transform; the rotate handle; marching ants. ----
        var temp = Path.Combine(output, "release019-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release019-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var pixels = new byte[200 * 100 * 4]; Array.Fill(pixels, (byte)200);
            for (var y = 0; y < 10; y++) for (var x = 0; x < 10; x++) { var i = (y * 200 + x) * 4; pixels[i] = pixels[i + 1] = pixels[i + 2] = 0; } // Dark top-left corner.
            var shot = BitmapSource.Create(200, 100, 96, 96, PixelFormats.Bgr32, null, pixels, 800); shot.Freeze();
            Wait(async () => { await controller.DeliverAsync(shot); return true; });
            var editor = controller.Editor!; var preview = (PreviewSurface)editor.FindName("Preview");
            void Refresh() { typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, null); editor.UpdateLayout(); }
            var region = Box(10, 20, 30, 40); preview.Project.Regions.Add(region); Refresh();
            var before = preview.Project.Media!.Path;
            check(Wait(() => editor.RotateMediaAsync(TurnOp.Clockwise)), "Edit › Rotate turns a picture");
            var after = preview.Project.Media!;
            check(after.Width == 100 && after.Height == 200 && Path.GetFileName(after.Path).StartsWith("EDITED_") && controller.Store.Owns(after.Path) && File.Exists(before),
                "the turned picture is a working copy in TRT's private folder (the screenshot is kept for Undo)");
            check(Blue(preview.Image!, 95, 5) < 50 && Blue(preview.Image!, 5, 5) > 150 && preview.Project.Regions.Single().GetHashCode() != 0 && preview.Project.Regions[0].GeometryAt(0) == new MediaRect(40, 10, 40, 30),
                "the picture turned clockwise (its dark corner moved to the top right) and the redaction moved with it");
            // 0.21.0 (David): Undo and Redo step over Rotate.
            check(Wait(() => editor.StepHistoryAsync(true)) && preview.Project.Media!.Path == before && preview.Image!.PixelWidth == 200 && Blue(preview.Image!, 5, 5) < 50
                && preview.Project.Regions[0].GeometryAt(0) == new MediaRect(10, 20, 30, 40), "Undo brings back the picture as it was, with the redaction where it was");
            check(Wait(() => editor.StepHistoryAsync(false)) && preview.Project.Media!.Path == after.Path && preview.Image!.PixelWidth == 100 && preview.Project.Regions[0].GeometryAt(0) == new MediaRect(40, 10, 40, 30),
                "Redo turns it again");

            // Transform: the selected shape turns; a flipped polygon mirrors.
            var r = preview.Project.Regions[0]; preview.Selected = r; Refresh();
            check(editor.TransformSelected(TurnOp.Clockwise) && preview.Project.Regions[0].Rotation == 90, "Edit › Transform turns the selected redaction");
            typeof(MainWindow).GetMethod("Undo", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, [editor, new RoutedEventArgs()]);
            check(preview.Project.Regions[0].Rotation == 0, "Undo takes the turn back");

            // 0.21.0: free turning from just outside a corner. Dragging from the top-right zone a quarter
            // of the way round the centre turns the shape 90°; then by 30° more, to 120° (any angle, not only steps).
            var shape = preview.Project.Regions[0]; preview.Selected = shape; preview.Tool = "Select"; Refresh();
            preview.Fit(); preview.UpdateLayout();
            var box = preview.ScreenRect(shape.GeometryAt(0)); var d = PreviewSurface.RotateZoneDistance / Math.Sqrt(2);
            var centre = new Point(box.X + box.Width / 2, box.Y + box.Height / 2);
            var zone = new Point(box.Right + d, box.Top - d);
            check(preview.HoverCursor(zone) == CustomCursors.RotateAt("RNE", 0), "just outside a selected shape's corner the pointer becomes the turning arrow for that corner");
            check(new[] { new Point(box.Left - d, box.Top - d), zone, new Point(box.Right + d, box.Bottom + d), new Point(box.Left - d, box.Bottom + d) }.Select(preview.HoverCursor).Distinct().Count() == 4
                && new[] { "RNW", "RNE", "RSE", "RSW" }.Select(z => CustomCursors.RotateAt(z, 0)).SequenceEqual(new[] { new Point(box.Left - d, box.Top - d), zone, new Point(box.Right + d, box.Bottom + d), new Point(box.Left - d, box.Bottom + d) }.Select(preview.HoverCursor)),
                "each of the four corners has its own turning arrow (0.21.1)");
            check(!CustomCursors.IsRotate(preview.HoverCursor(new Point(box.Right, box.Top))), "on the corner itself it still resizes");
            preview.MouseDownAt(zone, MouseButton.Left, 1); preview.PointerMove(PreviewSurface.Turn(zone, centre, 45)); preview.PointerMove(PreviewSurface.Turn(zone, centre, 90)); preview.PointerUp(); Pump();
            check(Math.Abs(shape.Rotation - 90) < 0.5, "dragging round from the corner turns the shape (here 90°)");
            var turnedZone = PreviewSurface.Turn(zone, centre, 90);
            check(preview.HoverCursor(turnedZone) == CustomCursors.RotateAt("RSE", 0), "the turning zones turn with the shape, and so does their arrow (the old top-right corner now has the bottom-right arrow)");
            preview.MouseDownAt(turnedZone, MouseButton.Left, 1); preview.PointerMove(PreviewSurface.Turn(turnedZone, centre, 30)); preview.PointerUp(); Pump();
            check(Math.Abs(shape.Rotation - 120) < 0.5, $"turning is free, not in steps (now {shape.Rotation:0.#}°)");
            shape.Rotation = 90; Refresh();

            // Marching ants: drag round two shapes, move them together, delete them together.
            var second = Box(10, 150, 20, 20); preview.Project.Regions.Add(second);
            preview.Project.Annotations.Add(new Annotation { Kind = AnnotationKind.Rectangle, Box = new(60, 150, 20, 20), Width = 2 });
            preview.Selected = null; Refresh(); preview.Fit(); preview.UpdateLayout();
            Point At(double x, double y) { var media = preview.ScreenRect(new MediaRect(x, y, 0, 0)); return new(media.X, media.Y); }
            preview.MouseDownAt(At(2, 140), MouseButton.Left, 1); preview.PointerMove(At(50, 160)); preview.PointerMove(At(95, 190)); preview.PointerUp(); Pump();
            check(preview.MultiRegions.SequenceEqual([second]) && preview.MultiAnnotations.Count == 1 && preview.HasMultiSelection, "dragging a dashed box with Select selects every shape inside it");
            preview.MouseDownAt(At(20, 160), MouseButton.Left, 1); preview.PointerMove(At(25, 155)); preview.PointerUp(); Pump();
            check(Math.Abs(second.GeometryAt(0).X - 15) < 0.01 && Math.Abs(preview.MultiAnnotations[0].Box.X - 65) < 0.01, $"dragging one of them moves the whole group ({second.GeometryAt(0).X}, {preview.MultiAnnotations[0].Box.X})");
            check(editor.TransformSelected(TurnOp.FlipHorizontal) && second.GeometryAt(0).X == 65 && preview.Project.Annotations[^1].Box.X == 15, "Transform flips the group as one");
            var count = preview.Project.Regions.Count + preview.Project.Annotations.Count;
            typeof(MainWindow).GetMethod("DeleteRegion", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, [editor, new RoutedEventArgs()]);
            check(preview.Project.Regions.Count + preview.Project.Annotations.Count == count - 2, "Delete removes the whole group");

            // A real video: turned losslessly, frames keep their times, keyframes follow their frames.
            var video = Wait(() => TrackingChecks.WriteVideo(tools, output, false));
            var videoHash = Wait(() => ProjectStore.HashAsync(video));
            check(Wait(() => editor.OpenPathAsync(video)), "a video opens for turning");
            var map = preview.Timeline!; var tracked = Box(10, 20, 30, 40); tracked.End = preview.Project.Media!.Duration; tracked.PutManual(map.Frames[3].Time, new(40, 30, 30, 40));
            preview.Project.Regions.Add(tracked); Refresh();
            check(Wait(() => editor.RotateMediaAsync(TurnOp.Clockwise)), "Edit › Rotate turns a video");
            var newMap = preview.Timeline!; var turnedVideo = preview.Project.Media!;
            check(turnedVideo.Width == 96 && turnedVideo.Height == 128 && newMap.Frames.Count == map.Frames.Count && newMap.Frames.Select(f => f.Time).Zip(map.Frames.Select(f => f.Time)).All(p => Math.Abs(p.First - p.Second) < 0.002),
                "the turned video has the same frames at the same times");
            var moved = preview.Project.Regions.Single();
            check(moved.Keyframes.Count == 2 && Math.Abs(moved.Keyframes[1].Time - newMap.Frames[3].Time) < 1e-9 && moved.Keyframes[1].Bounds == new MediaRect(96 - 30 - 40, 40, 40, 30),
                "its redaction keyframes stay on their frames and turn with the picture");
            check(Wait(() => ProjectStore.HashAsync(video)) == videoHash, "the original video file is unchanged");
            editor.Close(); Pump();
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
    private static bool Throws(Action action) { try { action(); return false; } catch (InvalidDataException) { return true; } }
}
