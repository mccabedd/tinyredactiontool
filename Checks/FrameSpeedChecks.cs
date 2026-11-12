using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.10.2: faster exact frames (seek, runs of frames, cache) and the larger loss-dialog pictures.
// The 0.10.2 Review button / banner checks became "Review is gone" and toolbar-order checks in 0.14.0.
internal static class FrameSpeedChecks
{
    private static byte[] Pixels(BitmapSource image)
    {
        var bgra = new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0);
        var pixels = new byte[bgra.PixelWidth * bgra.PixelHeight * 4]; bgra.CopyPixels(pixels, bgra.PixelWidth * 4, 0); return pixels;
    }
    public static async Task RunMedia(MediaTools tools, string output, Action<bool, string> check)
    {
        var path = Path.GetFullPath(Path.Combine(output, "..", "test-media", "TRT-Moving-Text-v2.mp4"));
        check(File.Exists(path), "the 12-second moving-text sample is available for frame-speed checks");
        var probeTimer = Stopwatch.StartNew();
        var map = await tools.ProbeTimelineAsync(path, CancellationToken.None);
        Console.WriteLine($"Frame map and independent frame count (side by side): {probeTimer.ElapsedMilliseconds} ms for {map.Frames.Count} frames");
        check(map.Frames.Count == 288, "loading reads the frame map and the independent frame count side by side and they agree (288 frames)");
        using (var cancelled = new CancellationTokenSource())
        {
            cancelled.CancelAfter(20);
            var stopped = false; try { await tools.ProbeTimelineAsync(path, cancelled.Token); } catch (OperationCanceledException) { stopped = true; }
            check(stopped, "cancelling loading stops both frame readers");
        }
        var late = map.Frames.Count - 20;
        var target = map.Frames[late];
        // Exactness: the seeking path gives the same picture as decoding from the start.
        var timer = Stopwatch.StartNew();
        var fromStart = (await tools.DecodePngsAsync(path, [target], null, 0, CancellationToken.None)).Single();
        var slow = timer.ElapsedMilliseconds; timer.Restart();
        var seeking = (await tools.FramePngsAsync(path, [target], null, CancellationToken.None)).Single();
        var fast = timer.ElapsedMilliseconds;
        Console.WriteLine($"Exact frame {late + 1}/{map.Frames.Count} at {target.Time:0.000}s: from start {slow} ms, with seek {fast} ms");
        check(Pixels(MediaTools.DecodePng(fromStart)).AsSpan().SequenceEqual(Pixels(MediaTools.DecodePng(seeking))), "a seeked exact frame is pixel-identical to decoding from the start");
        check(fast < slow, "seeking makes a late exact frame quicker to show");
        // A run of frames in one pass matches the frames fetched one at a time.
        var window = MainWindow.WindowAround(map, late, 1);
        var run = await tools.FramePngsAsync(path, window, null, CancellationToken.None);
        check(run.Count == MainWindow.FrameWindow && window.IndexOf(target) == 2, "a run of 12 exact frames is decoded in one pass, mostly ahead of the frame asked for");
        var same = true;
        foreach (var i in new[] { 0, 2, window.Count - 1 })
        {
            var single = (await tools.FramePngsAsync(path, [window[i]], null, CancellationToken.None)).Single();
            same &= Pixels(MediaTools.DecodePng(run[i])).AsSpan().SequenceEqual(Pixels(MediaTools.DecodePng(single)));
        }
        check(same, "each frame in the run is pixel-identical to that frame decoded on its own");
        var back = MainWindow.WindowAround(map, late, -1);
        check(back.Contains(target) && back.IndexOf(target) == MainWindow.FrameWindow - 3, "stepping backwards loads mostly earlier frames");
        check(MainWindow.WindowAround(map, 0, -1)[0] == map.Frames[0] && MainWindow.WindowAround(map, map.Frames.Count - 1, 1)[^1] == map.Frames[^1], "runs stay inside the video at its start and end");
        check(MediaTools.SplitPngs([.. run[0], .. run[1]]).Count == 2 && MediaTools.SplitPngs(run[0][..^5]).Count == 0, "back-to-back PNGs are split exactly; a cut-off PNG is not used");
        var cache = new FrameCache();
        cache.Add("a", 1, run[0]);
        check(cache.TryGet("a", 1, out var hit) && hit == run[0] && !cache.Contains("b", 1), "decoded frames are kept per video and found again");
        // Thumbnails reuse a frame already decoded.
        using var thumbs = new ThumbnailService(tools, cache);
        timer.Restart();
        var thumb = await thumbs.RequestAsync(path, map.Frames[late - 2], "a");
        cache.Add("a", map.Frames[late - 2].Pts, run[0]);
        var cachedThumb = await thumbs.RequestAsync(path, map.Frames[late - 2], "a");
        check(thumb != null && cachedThumb is { PixelWidth: 224 }, "hover thumbnails are 224 px wide, from the cache when the frame is already decoded");
    }

    public static void RunUi(string output, Action<bool, string> check)
    {
        // Loss dialog: a click shows the picture larger, starting on a close-up of the box.
        var pixels = new byte[640 * 360 * 4]; Array.Fill(pixels, (byte)90);
        var frame = BitmapSource.Create(640, 360, 96, 96, PixelFormats.Bgra32, null, pixels, 640 * 4); frame.Freeze();
        var box = new MediaRect(600, 20, 30, 20);
        var dialog = new FollowLossReview(frame, 1, frame, 1.04, box, box) { Left = -20000, ShowInTaskbar = false };
        var area = FollowLossReview.CloseUp(frame, box);
        check(area.Contains(new Rect(box.X, box.Y, box.Width, box.Height)) && area.Left >= 0 && area.Right <= 640 && area.Top >= 0 && area.Bottom <= 360 && Math.Abs(area.Width / area.Height - 640 / 360d) < .01,
            "the close-up around a small box stays inside the frame, keeps its shape and contains the box");
        dialog.Show();
        var viewer = dialog.CreateViewer("First unmatched frame", frame, box);
        viewer.Left = -20000; viewer.Show(); viewer.UpdateLayout();
        var picture = Descendants(viewer).OfType<System.Windows.Controls.Image>().Single();
        var toggle = Descendants(viewer).OfType<Button>().First();
        check(picture.Source is DrawingImage { Width: var w } && Math.Abs(w - area.Width) < 1 && (string)toggle.Content == "Show Whole Frame" && picture.ActualWidth > 600,
            "clicking a loss picture opens a large view, first close up on the box");
        toggle.RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent));
        check(picture.Source is DrawingImage { Width: 640 } && (string)toggle.Content == "Close-Up of the Box", "the large view can show the whole frame");
        viewer.Close(); dialog.Close();

        // 0.14.0 (David): the separate Review step is gone; followed ranges no longer hold up export.
        var image = BitmapSource.Create(200, 100, 96, 96, PixelFormats.Bgra32, null, new byte[200 * 100 * 4], 800); image.Freeze();
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show();
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        var refresh = typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!;
        try
        {
            check(window.FindName("ReviewButton") == null && window.FindName("ReviewBar") == null && window.FindName("PopupReview") == null,
                "there is no Review button, Review banner or Review in the redaction popup any more");
            Region Followed(string name, double x)
            {
                var r = new Region { Name = name, Start = 0, End = 1 }; r.PutManual(0, new(x, 30, 30, 30));
                r.Tracking = [new(0, .5, ReviewState.Unreviewed, "tracked"), new(.5, .6, ReviewState.Lost, "lost")]; return r;
            }
            preview.Image = image;
            preview.Project = new RedactionProject { Media = new(Path.Combine(output, "review.png"), 1, new string('0', 64), 200, 100, 0, false), Regions = [Followed("Face", 20), Followed("Plate", 120)] };
            refresh.Invoke(window, null); window.UpdateLayout();
            check(Find<Button>("ExportButton").IsEnabled && (string)Find<Button>("ExportButton").ToolTip == "Export with Redactions (Checked After Saving)",
                "followed ranges no longer hold up Export");
            var names = Find<WrapPanel>("ToolButtons").Children.OfType<Button>().Select(b => ((string)b.Content).Replace("\n", " ")).ToList();
            int At(string name) => names.IndexOf(name);
            check(At("Save Media") == At("Export") + 1 && At("Copy") == At("Save Media") + 1 && At("Original") < 0 && At("Paste") == At("Copy") + 1 && At("Undo") == At("Paste") + 1,
                "Copy and Paste sit on the toolbar just before Undo (after Export and Save Media; 3.1.3: David's defaults; Original hidden)");
            // 0.21.0: the video-only Trim and Append follow Crop; 0.23.0: Resize sits between them, beside Crop;
            // 0.24.0: and the picture's turn and flip buttons after Resize.
            check(At("Trim") == At("Polygon") + 1 && At("Append") == At("Trim") + 1 && At("Box") == At("Append") + 1 && At("Blur") == At("Box") + 1 && At("Pixelate") == At("Blur") + 1 && At("Text") == At("Pixelate") + 1
                  && At("Crop") == At("Pen") + 1 && At("Resize") == At("Crop") + 1 && At("Rotate Right") < 0 && At("Fit") == At("Resize") + 1,
                "0.27.0 (David's order): Trim and Append after Polygon, then Box, Blur, Pixelate and the drawing tools, then Crop and Resize (3.1.3: the turn buttons hidden by default)");
            // 0.18.0 (David): the Clear buttons sit at the far right beside Panel, after a separator; none at the bottom right.
            var right = Find<StackPanel>("RightTools").Children.Cast<UIElement>().Select(c => c is Button b ? ((string)b.Content).Replace("\n", " ") : "|").ToList();
            check(right.SequenceEqual(["File Info", "|", "Clear Redactions", "Clear Annotations", "Clear Editor", "|", "Panel"]) && At("Clear Editor") < 0 && At("Panel") < 0,
                "the Clear buttons sit at the far right of the toolbar beside Panel, with a separator");
            check(window.FindName("CancelWorkButton") == null && window.FindName("ClearEditorButton") == null && window.FindName("ClearRedactionsButton") == null && window.FindName("ClearAnnotationsButton") == null,
                "there are no Clear buttons at the bottom right any more");
        }
        finally { preview.Project = new(); preview.Selected = null; window.Close(); }
    }
    private static IEnumerable<DependencyObject> Descendants(DependencyObject parent)
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
        { var child = VisualTreeHelper.GetChild(parent, i); yield return child; foreach (var nested in Descendants(child)) yield return nested; }
    }
}
