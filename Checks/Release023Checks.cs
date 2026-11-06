using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.23.0: David's picks: previous/next picture in the folder, Resize, File info, full
// screen and Fit width, and a slideshow. `--release-023-only` runs these alone.
internal static class Release023Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.23.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static void Wait(Func<Task> operation) => Wait(async () => { await operation(); return true; });
    private static void Png(string path, int width, int height, Color colour, Action<DrawingContext>? draw = null)
    {
        var visual = new DrawingVisual();
        using (var dc = visual.RenderOpen()) { dc.DrawRectangle(new SolidColorBrush(colour), null, new Rect(0, 0, width, height)); draw?.Invoke(dc); }
        var bitmap = new RenderTargetBitmap(width, height, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual);
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap));
        using var stream = File.Create(path); encoder.Save(stream);
    }

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- The folder's pictures, in File Explorer's order ----
        var folder = Path.Combine(output, "release023-folder"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        string At(string name) => Path.Combine(folder, name);
        Png(At("shot 10.png"), 160, 90, Colors.SteelBlue); Png(At("shot 2.png"), 160, 90, Colors.IndianRed); Png(At("shot 1.png"), 200, 100, Colors.SeaGreen);
        File.WriteAllText(At("notes.txt"), "not a picture");
        File.WriteAllText(At("broken.png"), "not really a picture");
        Png(At("hidden.png"), 20, 20, Colors.Black); File.SetAttributes(At("hidden.png"), FileAttributes.Hidden);
        var order = MainWindow.FolderPictures(folder).Select(Path.GetFileName).ToList();
        check(order.SequenceEqual(["broken.png", "shot 1.png", "shot 2.png", "shot 10.png"]), $"a folder's pictures come in File Explorer's order, numbers as numbers (2 before 10), hidden files and other files left out ({string.Join(", ", order)})");
        check(MainWindow.Neighbour(At("shot 2.png"), 1) == At("shot 10.png") && MainWindow.Neighbour(At("shot 2.png"), -1) == At("shot 1.png") && MainWindow.Neighbour(At("shot 10.png"), 1) == null,
            "the next and previous picture follow that order; there is none after the last");
        check(MainWindow.Neighbour(At("shot 3.png"), 1) == At("shot 10.png") && MainWindow.Neighbour(At("shot 3.png"), -1) == At("shot 2.png"),
            "a picture that has gone from the folder still has its place in the order");

        var temp = Path.Combine(output, "release023-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release023-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); var preview = (PreviewSurface)editor.FindName("Preview");
            var failures = new List<string>(); editor.WorkFailed = ex => failures.Add(ex.Message);
            T Find<T>(string name) where T : class => (T)editor.FindName(name);
            string Opened() => Path.GetFileName(editor.OpenedPath ?? "");

            // Previous and next.
            check(Wait(() => editor.OpenPathAsync(At("shot 1.png"))) && Find<Button>("NextPictureButton").IsEnabled && Find<Button>("PreviousPictureButton").IsEnabled, "a picture opened from a folder enables Previous and Next");
            check(Wait(() => editor.StepPictureAsync(1)) && Opened() == "shot 2.png" && preview.Project.Media!.Width == 160, "Next opens the next picture in the folder");
            check(Wait(() => editor.StepPictureAsync(1)) && Opened() == "shot 10.png", "and the one after (shot 10 after shot 2)");
            check(!Wait(() => editor.StepPictureAsync(1)) && Opened() == "shot 10.png", "after the last picture Next stays put and says so");
            check(Wait(() => editor.StepPictureAsync(-1)) && Opened() == "shot 2.png", "Previous goes back");

            // Resize: the picture and everything on it.
            check(Wait(() => editor.OpenPathAsync(At("shot 1.png"))), "a 200 × 100 picture opens for Resize");
            var region = new Region { Name = "Face" }; region.PutManual(0, new(40, 20, 60, 40)); preview.Project.Regions.Add(region);
            var note = new Annotation { Kind = AnnotationKind.Text, Text = "Hello", Box = new(100, 50, 80, 30), FontSize = 24, Width = 4 }; preview.Project.Annotations.Add(note);
            check(Wait(() => editor.ResizePictureAsync(100, 50)) && preview.Project.Media!.Width == 100 && preview.Image!.PixelWidth == 100 && preview.Image.PixelHeight == 50,
                $"Resize makes the picture 100 × 50{(failures.Count > 0 ? ": " + failures[^1] : "")}");
            var box = preview.Project.Regions[0].GeometryAt(0); var text = preview.Project.Annotations[0];
            check(Math.Abs(box.X - 20) < 0.01 && Math.Abs(box.Width - 30) < 0.01 && Math.Abs(text.Box.X - 50) < 0.01 && Math.Abs(text.FontSize - 12) < 0.01 && text.Width == 2,
                $"the redaction, the text, its size and its line width are scaled with it ({box}, {text.Box}, {text.FontSize})");
            check(Opened() == "shot 1.png" && File.Exists(At("shot 1.png")) && new FileInfo(At("shot 1.png")).Length > 0, "the original file is unchanged and still the one in the folder");
            Wait(() => editor.StepHistoryAsync(true));
            check(preview.Project.Media!.Width == 200 && preview.Image!.PixelWidth == 200 && Math.Abs(preview.Project.Regions[0].GeometryAt(0).X - 40) < 0.01, "Undo puts the picture back at 200 × 100 with its redaction");
            var resize = new ResizeWindow(200, 100);
            resize.Type(true, "50");
            check(resize.NewWidth == 50 && resize.NewHeight == 25, "in the Resize window a new width sets the height when the proportions are kept");
            resize.UsePercent(true); resize.Type(true, "150");
            check(resize.NewWidth == 300 && resize.NewHeight == 150, "and a percentage works too (150 %: 300 × 150)");
            resize.KeepProportions(false); resize.Type(false, "40");
            check(resize.NewWidth == 300 && resize.NewHeight == 40, "without keeping proportions each side is its own");
            resize.Close();

            // File info: what the export removes.
            var tagged = Path.Combine(output, "release023-tagged.mp4");
            var source = Path.GetFullPath(Path.Combine(output, "..", "test-media", "synthetic-with-audio.mp4"));
            Wait(() => tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", source, "-c", "copy", "-metadata", "title=Secret meeting", "-metadata", "artist=A. Person", "-metadata", "location=+64.1265-021.8174/", tagged], tagged, CancellationToken.None));
            check(Wait(() => editor.OpenPathAsync(tagged)), "a video with a title, an artist and a place written in it opens");
            var info = Wait(() => editor.ShowFileInfoAsync(show: false));
            check(info != null && info.Details.Any(d => d.Name == "title" && d.Value == "Secret meeting") && info.Details.Any(d => d.Name == "artist") && info.Details.Any(d => d.Name.Contains("location")),
                $"File info lists them ({string.Join("; ", info?.Details.Select(d => $"{d.Name}={d.Value}") ?? [])})");
            check(info?.Summary.Contains("Export removes all of them") == true && info.Summary.Contains("Save media as"), "and says Export removes them, Save media as… keeps them");
            info?.Close();
            var photo = Path.Combine(output, "release023-photo.jpg");
            {
                var bitmap = BitmapSource.Create(64, 48, 96, 96, PixelFormats.Bgr32, null, new byte[64 * 48 * 4], 64 * 4);
                var metadata = new BitmapMetadata("jpg") { CameraManufacturer = "TestMaker", CameraModel = "TestCam 1" };
                var encoder = new JpegBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(bitmap, null, metadata, null));
                using var stream = File.Create(photo); encoder.Save(stream);
            }
            check(Wait(() => editor.OpenPathAsync(photo)), "a photo with its camera written in it opens");
            info = Wait(() => editor.ShowFileInfoAsync(show: false));
            check(info != null && info.Details.Any(d => d.Value.Contains("TestCam 1")), $"File info lists the camera from the photo's EXIF ({string.Join("; ", info?.Details.Select(d => $"{d.Name}={d.Value}") ?? [])})");
            info?.Close();
            // What File info promises: the export has none of it.
            var exportedPhoto = Path.Combine(output, "release023-photo-export.jpg"); if (File.Exists(exportedPhoto)) File.Delete(exportedPhoto);
            var exportProject = ProjectStore.Deserialize(ProjectStore.Serialize(preview.Project));
            var cover = new Region { Name = "Box" }; cover.PutManual(0, new(4, 4, 10, 10)); exportProject.Regions.Add(cover);
            Wait(async () => { await ImageExport.ExportAsync(exportedPhoto, exportProject, new(), preview.Image!, CancellationToken.None, tools); return true; });
            var left = Wait(() => FileDetails.ReadAsync(tools, exportedPhoto, CancellationToken.None));
            check(File.Exists(exportedPhoto) && !left.Any(d => d.Value.Contains("TestCam") || d.Value.Contains("TestMaker")), $"the exported photo has no camera details left ({string.Join("; ", left.Select(d => $"{d.Name}={d.Value}"))})");

            // Fit width and full screen.
            var tall = Path.Combine(output, "release023-tall.png"); Png(tall, 300, 3000, Colors.Beige);
            check(Wait(() => editor.OpenPathAsync(tall)), "a tall picture (a scrolling capture) opens");
            preview.FitWidth(); editor.UpdateLayout();
            var shown = preview.ScreenRect(new MediaRect(0, 0, 300, 3000));
            check(preview.FittingWidth && Math.Abs(shown.Width - preview.ActualWidth) < 1 && Math.Abs(shown.Top) < 1, $"Fit width fills the width and starts at the top ({shown})");
            preview.RaiseEvent(new MouseWheelEventArgs(Mouse.PrimaryDevice, 0, -120) { RoutedEvent = UIElement.MouseWheelEvent });
            var scrolled = preview.ScreenRect(new MediaRect(0, 0, 300, 3000));
            check(preview.FittingWidth && Math.Abs(scrolled.Top + 120) < 1 && Math.Abs(scrolled.Width - shown.Width) < 1, $"the wheel then scrolls down it instead of zooming ({scrolled})");
            editor.SetFullScreen(true); editor.UpdateLayout();
            check(editor.IsFullScreen && editor.WindowStyle == WindowStyle.None && Find<FrameworkElement>("MenuRow").Visibility == Visibility.Collapsed && Find<FrameworkElement>("ToolStrip").Visibility == Visibility.Collapsed,
                "full screen hides the menus and toolbars and the window frame");
            editor.SetFullScreen(false); editor.UpdateLayout();
            check(!editor.IsFullScreen && editor.WindowStyle == WindowStyle.SingleBorderWindow && Find<FrameworkElement>("MenuRow").Visibility == Visibility.Visible && Find<FrameworkElement>("ToolStrip").Visibility == Visibility.Visible,
                "and Esc or F11 brings them back");

            // Slideshow (not shown on screen here).
            check(Wait(() => editor.OpenPathAsync(At("shot 2.png"))), "a picture opens before the slideshow");
            var show = editor.StartSlideshow(show: false)!;
            Wait(show.Begin);
            check(show.Index == 2 && show.Shown != null && show.Note.StartsWith("3 / 4"), $"the slideshow starts at the open picture, in the folder's order ({show.Note})");
            Wait(() => show.Key(Key.Right)); check(show.Index == 3 && show.Shown!.PixelWidth == 160, "Right shows the next picture");
            Wait(() => show.Key(Key.Right)); check(show.Index == 1, $"after the last it starts again, and a file that isn't a picture is skipped (now {show.Index + 1})");
            Wait(() => show.Key(Key.Left)); check(show.Index == 3, "Left goes back (round to the last)");
            show.TogglePause(); check(show.Paused && show.Note.StartsWith("Paused"), "Space pauses it");
            Wait(() => show.Key(Key.Home)); check(show.Index == 1, "Home goes to the first picture it can show");
            show.Close();
            check(AppSettings.Parse("{\"SlideshowSeconds\": 7}").SlideshowSeconds == 5 && AppSettings.Parse("{\"SlideshowSeconds\": 10}").SlideshowSeconds == 10 && new AppSettings().SlideshowRepeat,
                "the slideshow's time per picture is one of Settings' choices (5 s and repeat by default)");
            editor.Close(); Pump();
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
}
