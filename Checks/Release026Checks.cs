using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.26.0: David's findings on 0.25.0: the navigation bar resizes by dragging its top edge and stays away while a video
// is open; File info's scroll bars are thin and its selection solid; a New picture to draw on, and
// pictures pasted onto a picture as items to move and size. `--release-026-only`.
internal static class Release026Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.26.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static void Wait(Func<Task> operation) => Wait(async () => { await operation(); return true; });
    private static bool Until(Func<bool> done, int milliseconds = 6000) => Wait(async () => { for (var i = 0; i < milliseconds / 50 && !done(); i++) await Task.Delay(50); return done(); });
    private static void Raise(UIElement element, RoutedEventArgs args) => Wait(() => { element.RaiseEvent(args); return Task.CompletedTask; });

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- File info: EXIF written out ----
        check(FileDetails.ExifValue("ExposureTime", "1:297") == "1/297 s" && FileDetails.ExifValue("FNumber", "1244236:699009") == "f/1.78" && FileDetails.ExifValue("FocalLength", "251773:37217") == "6.765 mm",
            $"camera numbers read as a camera app shows them: 1/297 s, f/1.78, 6.765 mm (got {FileDetails.ExifValue("FocalLength", "251773:37217")})");
        check(FileDetails.ExifValue("ExifVersion", "48, 50, 51, 50") == "0232" && FileDetails.ExifValue("DateTimeOriginal", "2026:10:21 09:08:53") == "2026-10-21 09:08:53"
              && FileDetails.ExifValue("Flash", "16") == "Did not fire" && FileDetails.ExifValue("XResolution", "72:1") == "72" && FileDetails.ExifValue("MeteringMode", "5") == "Pattern",
            "versions, dates and codes are written out (0232, 2026-10-21 09:08:53, Did not fire, 72, Pattern)");
        check(FileDetails.TagName("ExifIFD/ExposureTime") == "Exposure time" && FileDetails.TagName("ExifIFD/0xA434") == "Lens model" && FileDetails.TagName("0x013C") == "Host computer" && FileDetails.TagName("ExifIFD/0x9999") == "Tag 0x9999",
            $"EXIF names lose FFmpeg's folder, and numbered ones get their names (Lens model; got {FileDetails.TagName("ExifIFD/0xA434")})");
        check(AppContext.TryGetSwitch("Switch.System.Windows.Controls.Text.UseAdornerForTextboxSelectionRendering", out var adorner) && !adorner, "text selections are drawn behind the text (so they can be solid)");

        // ---- The Picture annotation in the project ----
        var media = new MediaReference("C:\\x.png", 1, new string('0', 64), 200, 100, 0, false);
        string Png(int w, int h, Color c) => AnnotationRenderer.PictureText(NewPictureWindow.Blank(w, h, c));
        var good = new RedactionProject { Media = media, Annotations = { new Annotation { Kind = AnnotationKind.Picture, Picture = Png(20, 10, Colors.Red), Box = new(10, 10, 40, 20), Order = 1 } } };
        bool Valid(RedactionProject p) { try { AnnotationRules.Validate(p, p.Media!); return true; } catch (InvalidDataException) { return false; } }
        var copy = ProjectStore.Deserialize(ProjectStore.Serialize(good));
        check(Valid(good) && copy.Annotations.Count == 1 && copy.Annotations[0].Kind == AnnotationKind.Picture && copy.Annotations[0].Picture == good.Annotations[0].Picture!, "a pasted picture is kept in the project file, and checked when it is read");
        Annotation Bad(Action<Annotation> change) { var a = new Annotation { Kind = AnnotationKind.Picture, Picture = Png(4, 4, Colors.Red), Box = new(0, 0, 4, 4), Order = 1 }; change(a); return a; }
        check(!Valid(new RedactionProject { Media = media, Annotations = { Bad(a => a.Picture = "not a picture") } }) && !Valid(new RedactionProject { Media = media, Annotations = { Bad(a => a.Box = new(190, 0, 40, 4)) } })
              && !Valid(new RedactionProject { Media = media with { IsVideo = true, Duration = 1 }, Annotations = { Bad(_ => { }) } }) && !Valid(new RedactionProject { Media = media, Annotations = { Bad(a => { a.Kind = AnnotationKind.Rectangle; }) } }),
            "a project with a broken picture, one outside the picture, one on a video, or picture data on another kind is refused");

        var folder = Path.Combine(output, "release026"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        var temp = Path.Combine(output, "release026-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release026-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); var preview = (PreviewSurface)editor.FindName("Preview");
            var failures = new List<string>(); editor.WorkFailed = ex => failures.Add(ex.GetType().Name + ": " + ex.Message);
            string Failure() => failures.Count > 0 ? ": " + failures[^1] : "";

            // ---- Navigation bar: drag to resize; not with a video ----
            foreach (var (name, colour) in new[] { ("a.png", Colors.Teal), ("b.png", Colors.Orange) }) WriteImage(Path.Combine(folder, name), NewPictureWindow.Blank(120, 80, colour));
            editor.ApplySettings(new AppSettings { NavBarInEditor = true });
            check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "a.png"))) && editor.NavBarShown, $"a picture opens with the navigation bar{Failure()}");
            var nav = editor.NavBar ?? throw new InvalidOperationException("No navigation bar.");
            nav.UpdateLayout(); Pump();
            double ItemHeight() { nav.UpdateLayout(); return nav.Strip.ItemContainerGenerator.ContainerFromIndex(0) is ListBoxItem item ? item.ActualHeight : 0; }
            var before = ItemHeight(); var barBefore = nav.ActualHeight;
            check(nav.SizeEdge.Cursor == Cursors.SizeNS && nav.ThumbnailSize == 72, "the bar's top edge shows the up-and-down cursor");
            Raise(nav.SizeEdge, new DragStartedEventArgs(0, 0));
            Raise(nav.SizeEdge, new DragDeltaEventArgs(0, -20)); Raise(nav.SizeEdge, new DragDeltaEventArgs(0, -20));
            var during = nav.ThumbnailSize;
            Raise(nav.SizeEdge, new DragCompletedEventArgs(0, 0, false));
            var after = ItemHeight();
            check(during == 112 && nav.PictureHeight == 112 && after > before + 30 && nav.ActualHeight > barBefore + 30 && editor.Settings.NavBarThumbnailSize == 112,
                $"dragging the edge up makes the bar and its pictures taller as it goes, and the size is kept ({before:0} -> {after:0} pixels high)");
            Raise(nav.SizeEdge, new DragStartedEventArgs(0, 0)); Raise(nav.SizeEdge, new DragDeltaEventArgs(0, 500)); Raise(nav.SizeEdge, new DragCompletedEventArgs(0, 0, false));
            check(nav.ThumbnailSize == NavigationBar.MinPictureSize && editor.Settings.NavBarThumbnailSize == (int)NavigationBar.MinPictureSize, "dragging it down goes no smaller than the smallest size");
            check(Until(() => nav.Items.All(i => i.Picture != null)), "the small pictures are read again after a resize");
            {
                var settings = new SettingsWindow(new AppSettings { NavBarThumbnailSize = 112 });
                var height = (NumberSpinner)settings.FindName("NavBarHeightBox");
                check(height.Value == 112 && settings.Collect().NavBarThumbnailSize == 112,
                    "Settings › Slideshow › Nav Bar Height shows a dragged height (112 pixels), and keeps it (0.28.0)");
                height.Value = 300; check(settings.Collect().NavBarThumbnailSize == AppSettings.MaxNavBarSize, "a height above the largest is pulled back to 256 pixels");
                height.Value = 48; check(settings.Collect().NavBarThumbnailSize == 48, "typing 48 there sets 48 pixels");
                settings.Close();
            }
            var video = Path.GetFullPath(Path.Combine(output, "..", "test-media", "synthetic-with-audio.mp4"));
            check(Wait(() => editor.OpenPathAsync(video)) && !editor.NavBarShown && editor.NavBarWanted && !((Button)editor.FindName("NavBarButton")).IsEnabled,
                $"with a video open the navigation bar stays away (and its button is off), without forgetting it is wanted (shown {editor.NavBarShown}, wanted {editor.NavBarWanted}, button {((Button)editor.FindName("NavBarButton")).IsEnabled}){Failure()}");
            check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "b.png"))) && editor.NavBarShown, "the next picture brings it back");
            editor.ApplySettings(new AppSettings());

            // ---- File info: thin scroll bars, solid selection ----
            var info = Wait(() => editor.ShowFileInfoAsync(show: false))!;
            info.Owner = null; info.WindowStartupLocation = WindowStartupLocation.Manual; info.Left = -20000; info.Top = 0; info.ShowActivated = false; info.Width = 300; info.Height = 260; info.Show(); Pump(); info.UpdateLayout(); Pump();
            var bars = Descendants<ScrollBar>(info.Box).Where(b => b.IsVisible).ToList();
            check(bars.Count > 0 && bars.All(b => (b.Orientation == Orientation.Vertical ? b.ActualWidth : b.ActualHeight) <= 10),
                $"File info's scroll bars are thin ({string.Join(", ", bars.Select(b => $"{(b.Orientation == Orientation.Vertical ? b.ActualWidth : b.ActualHeight):0}"))} pixels)");
            info.Box.SelectAll(); Pump();
            check(info.Box.SelectionOpacity == 1 && info.Box.SelectionTextBrush is SolidColorBrush { Color: var text } && text == Colors.White && info.Box.SelectionBrush is SolidColorBrush { Color: var blue } && blue == Color.FromRgb(0, 0x78, 0xD7),
                "and the selection is solid blue with white text");
            foreach (var theme in new[] { "Light", "Dark" })
            {
                MainWindow.ApplyThemeResources(theme); info.Width = 520; info.Height = 360; Pump(); info.UpdateLayout(); Pump(); info.Box.Select(0, 200); Pump();
                Snap(info, Path.Combine(output, $"release026-fileinfo-{theme}.png"));
            }
            MainWindow.ApplyThemeResources("Light");
            info.Close();

            // ---- New picture ----
            NewPictureWindow? asked = null;
            editor.AnswerNewPicture = dialog =>
            {
                asked = dialog;
                dialog.Presets.SelectedItem = ((List<NewPictureWindow.Preset>)dialog.Presets.ItemsSource).First(p => p.Name == "Full HD");
                dialog.Portrait.IsChecked = true; // Turns 1920 × 1080 on its side.
                var turned = dialog.WidthBox.Value == 1080 && dialog.HeightBox.Value == 1920;
                dialog.WidthBox.Value = 400; dialog.HeightBox.Value = 300; dialog.Clear.IsChecked = true; dialog.Carry.IsChecked = false;
                dialog.Accept(); return turned;
            };
            check(Wait(() => editor.NewPictureAsync()) && preview.Project.Media is { Width: 400, Height: 300, IsVideo: false } && editor.IsNewPicture && preview.Image is { } blank && Alpha(blank, 200, 150) == 0,
                $"New makes a transparent 400 × 300 picture (Portrait turned Full HD on its side first){Failure()}");
            check(asked != null && asked.Presets.SelectedItem is NewPictureWindow.Preset { Name: "Custom" } && asked.Landscape.IsChecked == true, "a typed size counts as Custom, and 400 × 300 as Landscape");
            check(((Button)editor.FindName("OriginalButton")).Visibility != Visibility.Visible && editor.OnToolbar("NewButton") && AppSettings.DefaultEditorToolbar[0] == "NewButton",
                "a New picture has no Original button; New is first on the toolbar");
            editor.AnswerNewPicture = dialog => { dialog.Carry.IsChecked = false; dialog.WidthBox.Value = 200; dialog.HeightBox.Value = 100; dialog.Coloured.IsChecked = true; dialog.Chosen = Color.FromRgb(10, 120, 200); dialog.Accept(); return true; };
            check(Wait(() => editor.NewPictureAsync()) && preview.Image is { } coloured && Pixel(coloured, 100, 50) == Color.FromArgb(255, 10, 120, 200), "or one in a chosen colour");

            // ---- Pasting onto it ----
            var red = NewPictureWindow.Blank(50, 40, Colors.Red);
            var pasted = preview.AddPicture(red);
            check(pasted is { Kind: AnnotationKind.Picture } && pasted.Box == new MediaRect(75, 30, 50, 40) && preview.SelectedAnnotation == pasted && preview.Project.Annotations.Contains(pasted),
                "a picture pasted onto it sits in the middle at its own size, chosen, ready to move");
            var big = preview.AddPicture(NewPictureWindow.Blank(800, 200, Colors.Lime))!;
            check(Math.Abs(big.Box.Width - 200) < 0.01 && Math.Abs(big.Box.Height - 50) < 0.01, "a picture larger than the canvas is made smaller to fit, keeping its shape");
            Wait(() => editor.StepHistoryAsync(true));
            check(!preview.Project.Annotations.Any(a => a.Id == big.Id) && preview.Project.Annotations.Any(a => a.Id == pasted!.Id), "Undo takes a pasted picture away again");
            pasted = preview.Project.Annotations.First(a => a.Kind == AnnotationKind.Picture);
            preview.SelectAnnotation(pasted); Pump(); preview.UpdateLayout();
            var corner = preview.ScreenRect(pasted.Box).BottomRight;
            preview.MouseDownAt(corner, MouseButton.Left, 1); preview.PointerMove(corner + new Vector(40, 4)); preview.PointerUp(); Pump();
            var sized = preview.Project.Annotations.First(a => a.Id == pasted.Id).Box;
            check(sized.Width > 55 && Math.Abs(sized.Width / sized.Height - 1.25) < 0.02, $"dragging a corner makes it bigger and keeps its shape ({sized.Width:0.#} × {sized.Height:0.#})");
            var centre = preview.ScreenRect(sized); var from = new Point(centre.X + centre.Width / 2, centre.Y + centre.Height / 2);
            preview.MouseDownAt(from, MouseButton.Left, 1); preview.PointerMove(from + new Vector(-30, -10)); preview.PointerUp(); Pump();
            var moved = preview.Project.Annotations.First(a => a.Id == pasted.Id).Box;
            check(moved.X < sized.X - 2 && moved.Y < sized.Y - 0.5 && Math.Abs(moved.Width - sized.Width) < 0.01, $"dragging inside it moves it ({sized.X:0.#},{sized.Y:0.#} -> {moved.X:0.#},{moved.Y:0.#}; regions {preview.Project.Regions.Count})");
            var rendered = MainWindow.RenderForCopy(preview.Image!, preview.Project, 0, null, CancellationToken.None);
            check(Pixel(rendered, (int)(moved.X + moved.Width / 2), (int)(moved.Y + moved.Height / 2)) == Colors.Red && Pixel(rendered, 5, 5) == Color.FromArgb(255, 10, 120, 200),
                "Copy and Export draw the pasted picture where it is put");
            WriteImage(Path.Combine(output, "release026-new-picture.png"), rendered);
            // Paste with a picture on the clipboard: onto a New picture it adds an item.
            var clipboardWorks = false;
            try { Clipboard.SetImage(NewPictureWindow.Blank(30, 30, Colors.Yellow)); clipboardWorks = true; } catch (System.Runtime.InteropServices.COMException) { }
            if (clipboardWorks)
            {
                var count = preview.Project.Annotations.Count;
                check(Wait(() => editor.PastePictureAsync()) && preview.Project.Annotations.Count == count + 1 && preview.Project.Annotations[^1].Kind == AnnotationKind.Picture && editor.IsNewPicture,
                    $"Paste (Ctrl+V) on a New picture adds the clipboard picture as an item{Failure()}");
                check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "a.png"))) && !editor.IsNewPicture && Wait(() => editor.PasteOntoPictureAsync()) == 1 && preview.Project.Annotations.Count(a => a.Kind == AnnotationKind.Picture) == 1,
                    "on an opened picture Paste onto picture (Ctrl+Shift+V) adds it as an item too");
            }
            else check(false, "the clipboard could not be used for the Paste checks (is the laptop locked?)");
            // ---- 0.26.1 (David): a screenshot, then New for more room, then more screenshots, without losing any ----
            var questions = 0; var answerQuestion = editor.ConfirmKeepQuestion;
            editor.ConfirmKeepQuestion = (owner, text, title) => { questions++; return answerQuestion(owner, text, title); };
            var shot = controller.Store.NewFile("TEST", ".png"); CaptureController.WritePng(NewPictureWindow.Blank(120, 80, Colors.Teal), shot);
            check(Wait(() => editor.OpenCaptureAsync(shot)) && !editor.IsNewPicture, "a screenshot opens in the editor");
            questions = 0; NewPictureWindow? carryDialog = null;
            editor.AnswerNewPicture = dialog => { carryDialog = dialog; dialog.WidthBox.Value = 600; dialog.HeightBox.Value = 400; dialog.White.IsChecked = true; dialog.Accept(); return true; };
            check(Wait(() => editor.NewPictureAsync()) && editor.IsNewPicture && preview.Project.Media is { Width: 600, Height: 400 } && questions == 0
                  && preview.Project.Annotations.SingleOrDefault() is { Kind: AnnotationKind.Picture, Box: { Width: 120, Height: 80 } },
                $"New puts the screenshot onto the bigger picture, without asking about the unsaved screenshot ({questions} questions){Failure()}");
            check(carryDialog?.Carry.IsChecked == true && ((List<NewPictureWindow.Preset>)carryDialog.Presets.ItemsSource)[0].Name == "The Current Image",
                "the New window offers to keep the current picture (ticked), and its size");
            var second = controller.Store.NewFile("TEST", ".png"); CaptureController.WritePng(NewPictureWindow.Blank(60, 40, Colors.Orange), second);
            check(Wait(() => editor.AddCaptureOntoNewPictureAsync(second)) && preview.Project.Annotations.Count(a => a.Kind == AnnotationKind.Picture) == 2 && !File.Exists(second) && editor.IsNewPicture && questions == 0,
                "another screenshot goes onto the New picture as an item (and its capture file is wiped)");
            check(Wait(() => editor.AddPictureFilesAsync([Path.Combine(folder, "a.png"), Path.Combine(folder, "b.png"), video])) == 2 && preview.Project.Annotations.Count == 4 && editor.IsNewPicture,
                "File › Add picture puts picture files onto it (a video in the choice is left out)");
            check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "a.png"))) && !editor.IsNewPicture && !Wait(() => editor.AddCaptureOntoNewPictureAsync(Path.Combine(folder, "b.png"))),
                "on an ordinary picture a screenshot opens as before");
            editor.ConfirmKeepQuestion = answerQuestion;
            check(Wait(() => editor.OpenPathAsync(video)) && Wait(() => editor.PasteOntoPictureAsync()) == 0, "nothing is pasted onto a video");
            editor.Close(); Pump();
        }
        finally { MainWindow.ApplyThemeResources("Light"); AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
    private static IEnumerable<T> Descendants<T>(DependencyObject root) where T : DependencyObject
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(root); i++)
        {
            var child = VisualTreeHelper.GetChild(root, i);
            if (child is T found) yield return found;
            foreach (var deeper in Descendants<T>(child)) yield return deeper;
        }
    }
    private static Color Pixel(BitmapSource picture, int x, int y)
    {
        var bgra = new FormatConvertedBitmap(picture, PixelFormats.Bgra32, null, 0); var p = new byte[4];
        bgra.CopyPixels(new Int32Rect(x, y, 1, 1), p, 4, 0); return Color.FromArgb(p[3], p[2], p[1], p[0]);
    }
    private static byte Alpha(BitmapSource picture, int x, int y) => Pixel(picture, x, y).A;
    private static void WriteImage(string path, BitmapSource picture)
    {
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(picture)); using var stream = File.Create(path); encoder.Save(stream);
    }
    private static void Snap(Window window, string path)
    {
        var content = (FrameworkElement)window.Content;
        var w = (int)Math.Max(1, content.ActualWidth); var h = (int)Math.Max(1, content.ActualHeight);
        var shot = new RenderTargetBitmap(w, h, 96, 96, PixelFormats.Pbgra32);
        var back = new DrawingVisual(); using (var dc = back.RenderOpen()) dc.DrawRectangle((Brush)Application.Current.FindResource("Background"), null, new Rect(0, 0, w, h));
        shot.Render(back); shot.Render(content);
        WriteImage(path, shot);
    }
}
