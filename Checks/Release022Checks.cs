using System.IO;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;
using Drawing = System.Drawing;

// 0.22.0: David's findings after a few days of use (missing last timestamp in an old AVI, Append losing frames
// when the sound starts before the picture, scrolling capture on web pages) and his edits (tracking by default,
// see-through manual boxes, trim bands and Retain A–B, About menu, thinner red tab, marquee touching, checkerboard
// outside freehand captures, settings export/import).
internal static class Release022Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.22.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static bool Until(Func<bool> condition) => Wait(async () =>
    {
        var deadline = DateTime.UtcNow.AddMinutes(3);
        while (!condition() && DateTime.UtcNow < deadline) await Task.Delay(50);
        return condition();
    });
    private static Color Sample(FrameworkElement element, Point point)
    {
        element.UpdateLayout();
        var bitmap = new RenderTargetBitmap((int)Math.Ceiling(element.ActualWidth), (int)Math.Ceiling(element.ActualHeight), 96, 96, PixelFormats.Pbgra32);
        var local = new DrawingVisual();
        using (var drawing = local.RenderOpen()) drawing.DrawRectangle(new VisualBrush(element), null, new Rect(0, 0, element.ActualWidth, element.ActualHeight));
        bitmap.Render(local);
        var bytes = new byte[4]; bitmap.CopyPixels(new Int32Rect((int)point.X, (int)point.Y, 1, 1), bytes, 4, 0);
        return Color.FromRgb(bytes[2], bytes[1], bytes[0]);
    }

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- A frame list whose last frame has no timestamp (David's 1970 AVI) ----
        static byte[] Frames(params string[] items) => Encoding.UTF8.GetBytes("{\"frames\":[" + string.Join(",", items) + "]}");
        const string f1 = "{\"best_effort_timestamp\":3,\"best_effort_timestamp_time\":\"0.120000\",\"duration_time\":\"0.040000\"}";
        const string f2 = "{\"best_effort_timestamp\":4,\"best_effort_timestamp_time\":\"0.160000\",\"duration_time\":\"0.040000\"}";
        const string bare = "{\"duration_time\":\"0.040000\"}";
        var map = MediaTools.TimelineFromFrames(Frames(f1, f2, bare));
        check(map.Frames.Count == 3 && map.Frames[2].Pts == 5 && Math.Abs(map.Frames[2].Time - 0.08) < 1e-9 && Math.Abs(map.Frames[1].Duration - 0.04) < 1e-9,
            "a last frame without a timestamp gets the next one in step (as the decoder gives it), so the video opens");
        var refused = false; try { MediaTools.TimelineFromFrames(Frames(f1, bare, f2)); } catch (InvalidDataException) { refused = true; }
        check(refused, "a missing timestamp in the middle still stops the video from opening (its frames can't be placed exactly)");

        // ---- Scrolling capture: rows drawn slightly differently after a scroll still line up ----
        using (var a = new Drawing.Bitmap(200, 300, Drawing.Imaging.PixelFormat.Format32bppRgb))
        using (var b = new Drawing.Bitmap(200, 300, Drawing.Imaging.PixelFormat.Format32bppRgb))
        {
            var random = new Random(22); var rows = Enumerable.Range(0, 340).Select(_ => (Shade: random.Next(40, 200), Width: random.Next(20, 180))).ToArray();
            void Paint(Drawing.Bitmap bitmap, int offset, int noise)
            {
                for (var y = 0; y < 300; y++)
                    for (var x = 0; x < 200; x++)
                    {
                        var row = rows[y + offset]; var v = x < row.Width ? row.Shade : 245;
                        v = Math.Clamp(v + (noise == 0 ? 0 : (x + y) % 3 - 1) * noise, 0, 255);
                        bitmap.SetPixel(x, y, Drawing.Color.FromArgb(v, v, v));
                    }
            }
            Paint(a, 0, 0); Paint(b, 40, 3);
            check(ScrollingCapture.FindShift(a, b, 0, 0) == 40, "scrolling capture joins pictures whose rows were drawn a little differently (fractional scrolling on scaled screens)");
        }

        // ---- Freehand capture: a checkerboard outside the outline ----
        check(ScreenCapture.CheckerSize == 8, "the checkerboard has 8-pixel squares");

        // ---- Red tab: half as thick ----
        var strip = new MinimizedStrip();
        check(strip.Height == 3, "the red tab is half as thick as before (3 pixels)");
        strip.Close();

        // ---- Settings export / import ----
        var settingsFile = Path.Combine(output, "release022-settings-export.json");
        var settings = new SettingsWindow(new AppSettings { StripWidth = 150 }) { ChooseSettingsFile = _ => settingsFile };
        check(settings.ExportSettingsTo(settingsFile) && AppSettings.Parse(File.ReadAllText(settingsFile)).StripWidth == 150, "Export settings writes the settings to a .json file");
        var changed = AppSettings.Parse(File.ReadAllText(settingsFile)); changed.StripWidth = 260; changed.HideOptionsBar = true;
        var importFile = Path.Combine(output, "release022-settings-import.json"); File.WriteAllText(importFile, changed.ToJson());
        check(settings.ImportSettingsFrom(importFile) && ((Slider)settings.FindName("StripWidthSlider")).Value == 260 && ((CheckBox)settings.FindName("HideOptionsBarBox")).IsChecked == true && settings.Collect().StripWidth == 260,
            "Import settings fills the window from the file (OK then uses them)");
        var junk = Path.Combine(output, "release022-not-settings.json"); File.WriteAllText(junk, "hello");
        check(!settings.ImportSettingsFrom(junk) && settings.SettingsFileMessage!.Contains("isn't a TRT settings file") && settings.Collect().StripWidth == 260, "a file that isn't TRT settings is refused and nothing changes");
        // 0.22.4 (David): the theme travels with the exported settings.
        RadioButton Theme(string name) => (RadioButton)settings.FindName($"Theme{name}Box");
        Theme("Dark").IsChecked = true;
        check(settings.ExportSettingsTo(settingsFile) && AppSettings.Parse(File.ReadAllText(settingsFile)).Theme == "Dark", "Export settings includes the theme (Dark)");
        Theme("Light").IsChecked = true;
        check(settings.ImportSettingsFrom(settingsFile) && Theme("Dark").IsChecked == true && settings.Collect().Theme == null,
            "Import settings chooses the exported theme again (OK then uses it; it stays out of the stored settings)");
        settings.Close();

        // ---- In the editor ----
        var media = Path.GetFullPath(Path.Combine(output, "..", "test-media"));
        var plain = Path.Combine(media, "synthetic-with-audio.mp4");
        var late = Path.Combine(output, "release022-picture-after-sound.mkv"); // Sound from 0 s, picture from 0.3 s (like David's MKVs).
        Wait(() => tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-i", plain, "-itsoffset", "0.3", "-i", plain, "-map", "1:v:0", "-map", "0:a:0", "-c", "copy", late], late, CancellationToken.None));
        var temp = Path.Combine(output, "release022-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release022-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); var preview = (PreviewSurface)editor.FindName("Preview");
            var failures = new List<string>(); editor.WorkFailed = ex => failures.Add(ex.Message);
            T Find<T>(string name) where T : class => (T)editor.FindName(name);
            void Refresh() { typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(editor, null); editor.UpdateLayout(); }

            // Menus: "About" with About and Settings only; Settings no longer in File.
            var menus = Find<Menu>("MainMenu").Items.OfType<MenuItem>().ToList();
            var about = Find<MenuItem>("AboutMenu"); var file = menus.First(m => (string)m.Header == "_File");
            // 3.0.0 (David): Help again, now with the manual: Help > Help, Settings, About.
            check(about != null && (string)about.Header == "_Help" && about.Items.OfType<MenuItem>().Select(m => ((string)m.Header).Replace("…", "")).SequenceEqual(["_Help", "_Settings", "_About"]),
                "the last menu is Help, with Help (the manual), Settings and About");
            check(!file.Items.OfType<MenuItem>().Any(m => ((string)m.Header).Contains("ttings")), "Settings is no longer in the File menu");

            // Videos whose sound starts before the picture: Append and Trim keep every frame.
            check(Wait(() => editor.OpenPathAsync(late)) && preview.Timeline!.Frames.Count == 10, "a video whose picture starts 0.3 s after its sound opens (10 frames)");
            check(Wait(() => editor.AppendAsync(plain, false)) && preview.Timeline!.Frames.Count == 20, $"Append keeps every frame when the sound starts first (10 + 10 = {preview.Timeline?.Frames.Count}){(failures.Count > 0 ? ": " + failures[^1] : "")}");
            check(Wait(() => editor.OpenPathAsync(late)), "the late-picture video opens again");
            editor.ShowTrimRow(true);
            void MarkAt(int frame, bool a) { preview.Time = preview.Timeline!.Frames[frame].Time; editor.SetMarker(a); }
            MarkAt(2, true); MarkAt(5, false); editor.UpdateLayout();
            var lane = Find<Canvas>("RangeLane");
            int Bands(string tag) => lane.Children.OfType<System.Windows.Shapes.Rectangle>().Count(r => (string?)r.Tag == tag);
            var button = Find<Button>("DeleteSelectionButton");
            check(!editor.DeletesBetween && (string)button.Content == "Retain A–B" && Bands("TrimDelete") == 2 && Bands("TrimKeep") == 1,
                "Retain A–B is the default: the frames outside A–B are marked red (to delete), A–B green");
            var deleteBrush = lane.Children.OfType<System.Windows.Shapes.Rectangle>().First(r => (string?)r.Tag == "TrimDelete").Fill;
            check(deleteBrush is DrawingBrush, "the red bands are drawn with X's");
            Find<CheckBox>("InvertTrimBox").IsChecked = true; editor.UpdateLayout();
            check(editor.DeletesBetween && (string)button.Content == "Delete A–B" && Bands("TrimDelete") == 1 && Bands("TrimKeep") == 2, "Invert swaps them: A–B red (to delete), the rest green");
            Find<CheckBox>("InvertTrimBox").IsChecked = false; editor.UpdateLayout();
            Dispatcher.CurrentDispatcher.BeginInvoke(() => button.RaiseEvent(new RoutedEventArgs(System.Windows.Controls.Primitives.ButtonBase.ClickEvent, button)));
            check(Until(() => preview.Timeline?.Frames.Count == 4 && !editor.IsBusy), $"Retain A–B keeps frames 3–6 only (4 frames, now {preview.Timeline?.Frames.Count}){(failures.Count > 0 ? ": " + failures[^1] : "")}");

            // A box that stays put on a video is see-through while selected (and while playing); tracked boxes are not.
            check(Wait(() => editor.OpenPathAsync(plain)), "a video opens for the see-through box");
            preview.Time = preview.Timeline!.Frames[2].Time;
            var box = new Region { Name = "Face", Start = 0, End = preview.Project.Media!.Duration, Color = "#000000" }; box.PutManual(0, new(10, 10, 60, 40));
            preview.Project.Regions.Add(box); preview.Selected = box; Refresh(); preview.Fit(); preview.UpdateLayout();
            var centre = preview.ScreenRect(new MediaRect(40, 30, 0, 0)).TopLeft;
            check(preview.SeeThrough(box) && Sample(preview, centre) is var seen && seen.R + seen.G + seen.B > 60, "a selected box that stays put (no tracking) shows the picture through it");
            preview.Selected = null; Refresh();
            check(!preview.SeeThrough(box) && Sample(preview, centre) is var solid && solid.R + solid.G + solid.B < 10, "once let go (and paused) it is solid again");
            box.Tracking = [new TrackingSegment(0, box.End, ReviewState.Unreviewed, "Tracked")]; preview.Selected = box; Refresh();
            check(!preview.SeeThrough(box), "a tracked box stays solid");
            preview.Selected = null; preview.Project.Regions.Clear(); Refresh();

            // Marquee: a shape the box only touches is selected too.
            var pixels = new byte[200 * 120 * 4]; Array.Fill(pixels, (byte)200);
            var shot = BitmapSource.Create(200, 120, 96, 96, PixelFormats.Bgr32, null, pixels, 800); shot.Freeze();
            Wait(async () => { await controller.DeliverAsync(shot); return true; });
            var region = new Region { Name = "Box" }; region.PutManual(0, new(10, 10, 40, 40)); preview.Project.Regions.Add(region);
            preview.Tool = "Select"; preview.Selected = null; Refresh(); preview.Fit(); preview.UpdateLayout();
            Point At(double x, double y) => preview.ScreenRect(new MediaRect(x, y, 0, 0)).TopLeft;
            preview.MouseDownAt(At(30, 30), MouseButton.Left, 1); preview.PointerMove(At(60, 50)); preview.PointerMove(At(90, 80)); preview.PointerUp(); Pump();
            // One shape becomes the ordinary selection.
            check(preview.Selected == region || preview.MultiRegions.Contains(region), "dragging a dashed box over part of a shape selects it");
            // ---- 0.22.1 ----
            // Timeline tooltips that say what each line means, and a key on the lane itself.
            check(Wait(() => editor.OpenPathAsync(plain)), "a video opens for the timeline tooltips");
            var face = new Region { Name = "Face", Start = 0.2, End = 0.8 }; face.PutManual(0.2, new(10, 10, 20, 20));
            face.Keyframes.Add(new GeometryKeyframe(0.3, new(12, 10, 20, 20), KeyframeOrigin.Tracking));
            face.Tracking = [new TrackingSegment(0.2, 0.6, ReviewState.Unreviewed, "Tracked"), new TrackingSegment(0.6, 0.8, ReviewState.Lost, "Lost")];
            preview.Project.Regions.Add(face); preview.Project.Annotations.Add(new Annotation { Kind = AnnotationKind.Line, Points = [new(1, 1), new(20, 20)], Start = 0.1, End = 0.5 });
            Refresh();
            var tips = Find<Canvas>("RangeLane").Children.OfType<FrameworkElement>().Select(e => e.ToolTip as string).Where(t => t != null).ToList();
            check(tips.Contains("Redaction \"Face\": 0.200–0.800 s") && tips.Contains("Box placed by you at 0.200 s") && tips.Contains("Box placed by tracking at 0.300 s")
                && tips.Contains("Tracking followed the subject: 0.200–0.600 s") && tips.Contains("Tracking lost the subject: 0.600–0.800 s (check this part)") && tips.Any(t => t!.StartsWith("Annotation \"") && t.EndsWith(": 0.100–0.500 s")),
                $"the timeline lines say what they are, to the millisecond ({string.Join(" | ", tips.Distinct().Take(8))})");
            check(Find<Canvas>("RangeLane").ToolTip is string key && key.Contains("Red: Redaction") && key.Contains("Violet: Annotation"), "between the lines, the lane's tooltip is a key to the colours");
            preview.Project.Regions.Clear(); preview.Project.Annotations.Clear(); Refresh();

            // A freehand capture is transparent outside its outline, in the editor, on the clipboard and in PNG export.
            using (var screen = new Drawing.Bitmap(120, 90, Drawing.Imaging.PixelFormat.Format32bppRgb))
            {
                using (var g = Drawing.Graphics.FromImage(screen)) g.Clear(Drawing.Color.FromArgb(30, 120, 200));
                using var cut = ScreenCapture.CropFreehand(screen, [new(10, 10), new(110, 10), new(60, 80)]);
                var picture = ScreenCapture.ToBitmapSource(cut);
                check(picture.Format == PixelFormats.Bgra32 && Transparency.HasTransparency(picture), "a freehand capture keeps its transparency when it is handed on");
                Wait(async () => { await controller.DeliverAsync(picture); return true; });
                var bytes = File.ReadAllBytes(preview.Project.Media!.Path);
                check(bytes[25] == 6 && preview.Image is { } shown && Transparency.HasTransparency(shown), "it opens in the editor with its transparency (its PNG keeps an alpha channel)");
                preview.Fit(); Pump(); preview.UpdateLayout(); Sample(preview, new(0, 0)); // drawing once settles the fitted scale
                var corner = preview.ScreenRect(new MediaRect(3, 65, 0, 0)).TopLeft; // bottom-left corner: inside the cut-out's box, outside the triangle
                var inside = corner.X >= 0 && corner.Y >= 0 && corner.X < preview.ActualWidth && corner.Y < preview.ActualHeight;
                var c = inside ? Sample(preview, corner) : default;
                check(inside && c.R > 190 && c.G > 190 && c.B > 190, $"the editor shows a light checkerboard where the picture is transparent (got {c} at {corner} in {preview.ActualWidth}x{preview.ActualHeight}; picture {preview.ScreenRect(new MediaRect(0, 0, preview.Project.Media!.Width, preview.Project.Media.Height))}, {preview.Project.Media.Width}x{preview.Project.Media.Height})");
                check(CaptureController.CopyImage(picture) && Transparency.ClipboardPng() is { } onClipboard && Transparency.HasTransparency(onClipboard) && Clipboard.ContainsImage(),
                    "Copy puts a PNG with the transparency on the clipboard, beside the ordinary picture");
                check(Wait(() => editor.PastePictureAsync()) && preview.Image is { } pasted && Transparency.HasTransparency(pasted), "Paste brings a transparent PNG back with its transparency");
                var export = Path.Combine(output, "release022-freehand.png"); if (File.Exists(export)) File.Delete(export);
                var project = ProjectStore.Deserialize(ProjectStore.Serialize(preview.Project));
                var mark = new Region { Name = "Box" }; mark.PutManual(0, new(40, 20, 20, 10)); project.Regions.Add(mark);
                Wait(async () => { await ImageExport.ExportAsync(export, project, new(), preview.Image!, CancellationToken.None, tools); return true; });
                var exported = BitmapFrame.Create(new Uri(export), BitmapCreateOptions.PreservePixelFormat | BitmapCreateOptions.IgnoreImageCache, BitmapCacheOption.OnLoad);
                check(Transparency.HasTransparency(exported), "a PNG export keeps the transparency");
            }
            editor.Close(); Pump();
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }

        // ---- 0.22.1: scrolling capture keeps only the part that moves (no browser tabs, bars or side bars) ----
        using (var before = new Drawing.Bitmap(300, 240, Drawing.Imaging.PixelFormat.Format32bppRgb))
        using (var after = new Drawing.Bitmap(300, 240, Drawing.Imaging.PixelFormat.Format32bppRgb))
        {
            // The lines on the first two screens are short (up to 150 px); a longer one comes later.
            var random = new Random(5); var rows = Enumerable.Range(0, 300).Select(i => (Shade: random.Next(30, 220), Width: random.Next(30, i < 230 ? 150 : 250))).ToArray();
            void Paint(Drawing.Bitmap bitmap, int offset)
            {
                for (var y = 0; y < 240; y++)
                    for (var x = 0; x < 300; x++)
                    {
                        int v;
                        if (y < 40) v = x % 50 < 25 ? 90 : 60;                  // Tabs and address bar: still.
                        else if (x >= 256) v = (y / 20) % 2 == 0 ? 20 : 160;    // A side bar of icons: still.
                        else { var row = rows[y - 40 + offset]; v = x < row.Width ? row.Shade : 250; }
                        bitmap.SetPixel(x, y, Drawing.Color.FromArgb(v, v, v));
                    }
            }
            Paint(before, 0); Paint(after, 30);
            var moving = ScrollingCapture.MovingPart(before, after);
            check(moving is { } m2 && m2.Top == 40 && m2.Left == 0 && m2.Right == 256 && m2.Bottom == 240, $"after the first scroll only the page is kept: no bars above, no side bar, but all its width, so longer lines later aren't cut ({moving})");
            if (moving is { } part)
            {
                using var a2 = ScreenCapture.Crop(before, part); using var b2 = ScreenCapture.Crop(after, part);
                check(ScrollingCapture.FindShift(a2, b2, 0, 0) == 30, "and the kept part lines up again (a still side bar stopped the joining before)");
            }
        }
        Scrolling(check);
    }

    // ---- 0.22.2: web pages (David: still failed on every site; no choice of pane). No screen needed: `--scrolling-only`. ----
    public static void Scrolling(Action<bool, string> check)
    {
        // A page of "text": a line every 20 rows of dark word blocks on a light background, different per line.
        static int[] Page(int width, int rows, int seed)
        {
            var random = new Random(seed); var page = new int[width * rows];
            for (var y = 0; y < rows; y++)
            {
                var line = y / 20; var inLine = y % 20;
                for (var x = 0; x < width; x++) page[y * width + x] = 0xF4F4F4;
                if (inLine < 5 || inLine > 13) continue;
                var words = new Random(seed * 7919 + line); var x0 = 6;
                while (x0 < width - 10) { var word = words.Next(8, 40); for (var x = x0; x < Math.Min(width - 6, x0 + word); x++) page[y * width + x] = (x + inLine) % 3 == 0 ? 0x303030 : 0x505860; x0 += word + words.Next(4, 10); }
            }
            return page;
        }
        static Drawing.Bitmap Picture(int width, int height, Func<int, int, int> colour)
        {
            var bitmap = new Drawing.Bitmap(width, height, Drawing.Imaging.PixelFormat.Format32bppRgb);
            var data = bitmap.LockBits(new(0, 0, width, height), Drawing.Imaging.ImageLockMode.WriteOnly, Drawing.Imaging.PixelFormat.Format32bppRgb);
            var pixels = new int[width * height];
            for (var y = 0; y < height; y++) for (var x = 0; x < width; x++) pixels[y * width + x] = colour(x, y);
            for (var y = 0; y < height; y++) System.Runtime.InteropServices.Marshal.Copy(pixels, y * width, data.Scan0 + y * data.Stride, width);
            bitmap.UnlockBits(data); return bitmap;
        }
        // A browser window: still bars on top (30 rows); a file pane on the left (0-139) that slides up by 40 as the page
        // scrolls (a code site's sticks once it reaches the top), a divider, and the page on the right moving by 100, whose
        // scroll bar handle shows only after the scroll (in some browsers).
        var leftPage = Page(140, 900, 11); var rightPage = Page(258, 900, 12);
        int Window(int x, int y, int leftOffset, int rightOffset, bool handle)
        {
            if (y < 30) return (x / 7 + y / 5) % 2 == 0 ? 0x202428 : 0x3A3F44;
            if (x < 140) return leftPage[(y - 30 + leftOffset) * 140 + x];
            if (x < 142) return 0x606060;
            if (x >= 390) return handle && y >= 100 && y < 160 && x >= 392 && x < 398 ? 0x8A8A8A : 0xF4F4F4;
            return rightPage[(y - 30 + rightOffset) * 258 + (x - 142)];
        }
        using (var before = Picture(400, 300, (x, y) => Window(x, y, 0, 0, false)))
        using (var after = Picture(400, 300, (x, y) => Window(x, y, 40, 100, true)))
        {
            var pane = ScrollingCapture.MovingPane(before, after, new(270, 200));
            check(pane is { } p && p.Left >= 142 && p.Left <= 160 && p.Right <= 392 && p.Right >= 360 && p.Top >= 28 && p.Top <= 40 && p.Bottom == 300,
                $"clicking in the page pane keeps just that pane: not the file pane that slid differently, the divider, the bars or the scroll bar ({pane})");
            if (pane is { } kept)
            {
                using var a2 = ScreenCapture.Crop(before, kept); using var b2 = ScreenCapture.Crop(after, kept);
                check(ScrollingCapture.FindShift(a2, b2, 0, 0) == 100, "and that pane lines up (100 pixels)");
            }
            var leftPane = ScrollingCapture.MovingPane(before, after, new(70, 200));
            check(leftPane is { } l && l.Right <= 141 && l.Width >= 100, $"clicking in the file pane keeps the file pane ({leftPane})");
        }
        // A bar that sticks to the top only once scrolled, a still chat button over the text, and lines that look
        // alike apart from a number: the true 100-pixel move is still found.
        var alike = Page(300, 900, 13);
        int Alike(int x, int y, int offset, bool bar)
        {
            if (bar && y < 30) return (x / 9) % 2 == 0 ? 0x24292F : 0x30363D;
            if (x >= 240 && x < 280 && y >= 150 && y < 190) return (x + y) % 4 == 0 ? 0x1F6FEB : 0x0969DA;
            var row = y + offset; var line = row / 20;
            if (row % 20 >= 5 && row % 20 <= 13 && x >= 6 && x < 40) return ((x / 4 * 7 + line * 3) % 11 < 3) ? 0x000000 : 0xF4F4F4; // The line's number.
            if (row % 20 >= 5 && row % 20 <= 13 && x >= 60 && x < 230) return (x / 6) % 3 == 0 ? 0x303030 : 0xF4F4F4;        // The same words on every line.
            return 0xF4F4F4;
        }
        using (var before = Picture(300, 260, (x, y) => Alike(x, y, 0, false)))
        using (var after = Picture(300, 260, (x, y) => Alike(x, y, 100, true)))
            check(ScrollingCapture.FindShift(before, after, 0, 0) == 100,
                $"a bar that appears once scrolled, a still button and look-alike lines don't fool the joining ({ScrollingCapture.FindShift(before, after, 0, 0)})");
        // The top of the page above the pane in the first picture is kept, up to the browser's bars.
        using (var before = Picture(200, 200, (x, y) => y < 30 ? ((x / 7) % 2 == 0 ? 0x202428 : 0x3A3F44) : rightPage[(y - 30) * 258 + x]))
        using (var after = Picture(200, 200, (x, y) => y < 30 ? ((x / 7) % 2 == 0 ? 0x202428 : 0x3A3F44) : rightPage[(y - 30 + 100) * 258 + x]))
            check(ScrollingCapture.PageAbove(before, after, new(0, 70, 200, 130)) is var above && above >= 30 && above <= 40,
                $"the page above the pane in the first picture is kept, not the browser's bars ({above} rows of 40; blank rows right under the bars can't be told apart)");

        // ---- 0.22.3: web panes highlighted before the click, like an application's panes (David's video) ----
        // A code site's file page names its columns: the file pane (with its tree inside) and the text beside it.
        Drawing.Rectangle Column(int left, int width) => new(left, 180, width, 808);
        var github = WebPanes.SideBySide([Column(112, 321), Column(128, 273), Column(433, 940)]);
        check(github.Count == 2 && github.Contains(Column(112, 321)) && github.Contains(Column(433, 940)),
            $"a page's side-by-side columns are its panes; the file tree inside the file pane is not another ({string.Join(" ", github)})");
        check(WebPanes.SideBySide([Column(144, 885)]).Count == 0, "a page's main column alone is not a pane (the whole page scrolls)");
        var all = new List<Drawing.Rectangle> { new(112, 180, 1276, 808) }; all.AddRange(github);
        check(WebPanes.At(all, new(250, 700)) == Column(112, 321) && WebPanes.At(all, new(900, 600)) == Column(433, 940) && WebPanes.At(all, new(1380, 600)) == all[0],
            "the pane under the pointer is the one outlined (the page itself outside the columns)");
        // A page that names no columns: a divider down it splits it (a two-pane viewer).
        using (var viewer = Picture(600, 300, (x, y) => x is >= 300 and < 304 ? 0x333333 : y % 20 is > 5 and < 12 && (x / 5) % 3 != 0 && x % 300 > 10 && x % 300 < 280 ? 0x505860 : 0x0F1418))
        {
            var split = WebPanes.Dividers(viewer, new(1000, 100, 600, 300)).ToList();
            check(split.Count == 2 && split[0].X == 1000 && Math.Abs(split[1].X - 1300) <= 4 && split.All(p => p.Height == 300),
                $"a page with a divider down it has two panes ({string.Join(" ", split)})");
        }
        using (var plain = Picture(600, 300, (x, y) => y % 20 is > 5 and < 12 && (x / 5) % 3 != 0 && x > 10 && x < 580 ? 0x505860 : 0x0F1418))
            check(!WebPanes.Dividers(plain, new(0, 0, 600, 300)).Any(), "a page of text alone has no divider");
    }
}
