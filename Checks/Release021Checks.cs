using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 0.21.0: Undo over Trim (and Rotate, see Release019Checks), free turning of annotations from their corners,
// a captured frame's Edit opening another editor window, and the toolbar's Trim and Append buttons.
internal static class Release021Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.21.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    // Lets the window thread run until the condition holds (for work started by a button's click handler).
    private static bool Until(Func<bool> condition) => Wait(async () =>
    {
        var deadline = DateTime.UtcNow.AddMinutes(3);
        while (!condition() && DateTime.UtcNow < deadline) await Task.Delay(50);
        return condition();
    });
    private static void Click(Button button) => button.RaiseEvent(new RoutedEventArgs(System.Windows.Controls.Primitives.ButtonBase.ClickEvent, button));

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var media = Path.GetFullPath(Path.Combine(output, "..", "test-media"));
        var video = Path.Combine(media, "synthetic-with-audio.mp4"); // 10 frames, sound
        var temp = Path.Combine(output, "release021-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release021-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); var preview = (PreviewSurface)editor.FindName("Preview");
            var failures = new List<string>(); editor.WorkFailed = ex => failures.Add(ex.ToString());
            T Find<T>(string name) where T : class => (T)editor.FindName(name);
            var trimButton = Find<Button>("TrimToolButton"); var appendButton = Find<Button>("AppendToolButton"); var trimRow = Find<FrameworkElement>("TrimRow");

            // ---- A picture: no Trim or Append on the toolbar. ----
            var pixels = new byte[64 * 48 * 4]; Array.Fill(pixels, (byte)180);
            var shot = System.Windows.Media.Imaging.BitmapSource.Create(64, 48, 96, 96, System.Windows.Media.PixelFormats.Bgr32, null, pixels, 64 * 4); shot.Freeze();
            Wait(async () => { await controller.DeliverAsync(shot); return true; });
            check(preview.Project.Media is { IsVideo: false } && trimButton.Visibility != Visibility.Visible && appendButton.Visibility != Visibility.Visible,
                "with a picture open the toolbar has no Trim or Append button");

            // ---- A video: Trim and Append appear; Trim shows and hides the trim row. ----
            check(Wait(() => editor.OpenPathAsync(video)), "a video opens");
            check(Until(() => editor.FrameReady(1) && editor.FrameReady(4)), "the first frame steps are loaded while the video opens, so the first Next frame is immediate (0.21.2)");
            check(trimButton.Visibility == Visibility.Visible && appendButton.Visibility == Visibility.Visible && trimButton.IsEnabled && appendButton.IsEnabled,
                "with a video open the toolbar shows Trim and Append");
            check(trimRow.Visibility != Visibility.Visible, "the trim row starts hidden");
            Click(trimButton); editor.UpdateLayout();
            check(trimRow.Visibility == Visibility.Visible, "Trim shows the trim row above the timeline");
            var bar = Find<FrameworkElement>("PlaybackBar");
            var rowCentre = trimRow.TranslatePoint(new Point(trimRow.ActualWidth / 2, 0), bar).X;
            check(trimRow.HorizontalAlignment == HorizontalAlignment.Center && Math.Abs(rowCentre - bar.ActualWidth / 2) < 12, $"the trim row sits in the middle (0.21.1; its centre {rowCentre:0} of {bar.ActualWidth:0})");
            Click(trimButton); editor.UpdateLayout();
            check(trimRow.Visibility != Visibility.Visible, "clicking Trim again hides it");
            Click(trimButton); editor.UpdateLayout();
            check(Find<CheckBox>("InvertTrimBox").Content as string == "Invert", "the Invert tick box just says Invert");
            var iconStyle = (Style)editor.FindResource("IconButton");
            check(new[] { "MarkerAButton", "MarkerBButton", "ClearMarkersButton" }.All(n => Find<Button>(n) is var b && b.Style == iconStyle && Toolbar.GetIcon(b) != null && b.ToolTip is string),
                "Set A, Set B and Clear are icons (with their names in the tooltips)");

            // ---- Undo and Redo over a trim. ----
            var original = preview.Project.Media!.Path; var map = preview.Timeline!;
            void MarkAt(int frame, bool a) { preview.Time = preview.Timeline!.Frames[frame].Time; editor.SetMarker(a); }
            MarkAt(2, true); MarkAt(4, false);
            check(Wait(() => editor.TrimAsync(false)) && preview.Timeline!.Frames.Count == 7, $"Delete A–B trims the video (10 → 7){(failures.Count > 0 ? ": " + failures[^1] : "")}");
            var trimmed = preview.Project.Media!.Path;
            check(Wait(() => editor.StepHistoryAsync(true)) && preview.Project.Media!.Path == original && preview.Timeline!.Frames.Count == 10, "Undo brings back the whole video");
            check(Wait(() => editor.StepHistoryAsync(false)) && preview.Project.Media!.Path == trimmed && preview.Timeline!.Frames.Count == 7, "Redo trims it again");
            check(Wait(() => editor.StepHistoryAsync(true)) && preview.Timeline!.Frames.Count == 10, "and Undo again");

            // ---- The Append button asks which video (the dialog) and appends it. ----
            var asked = 0;
            editor.AppendQuestion = () => { asked++; return (video, false); };
            Dispatcher.CurrentDispatcher.BeginInvoke(() => Click(appendButton)); // As a real click: inside the window's message loop.
            check(Until(() => preview.Timeline?.Frames.Count == 20 && !editor.IsBusy) && asked == 1, $"Append opens the Append question and adds the video (10 + 10 frames){(failures.Count > 0 ? ": " + failures[^1] : "")}");
            check(Wait(() => editor.StepHistoryAsync(true)) && preview.Timeline!.Frames.Count == 10 && preview.Project.Media!.Path == original, "Undo takes the appended video off again");

            // ---- Free turning of annotations from just outside a corner. ----
            preview.Tool = "Select"; preview.Time = preview.Timeline!.Frames[0].Time;
            var outline = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(20, 20, 40, 20), Width = 2, Start = 0, End = preview.Project.Media!.Duration };
            preview.Project.Annotations.Add(outline); preview.SelectAnnotation(outline); preview.Fit(); preview.UpdateLayout();
            var box = preview.ScreenRect(outline.Box); var d = PreviewSurface.RotateZoneDistance / Math.Sqrt(2);
            var centre = new Point(box.X + box.Width / 2, box.Y + box.Height / 2); var zone = new Point(box.Left - d, box.Bottom + d);
            check(preview.HoverCursor(zone) == CustomCursors.RotateAt("RSW", 0), "just outside an outline's corner the pointer becomes the turning arrow");
            preview.MouseDownAt(zone, MouseButton.Left, 1); preview.PointerMove(PreviewSurface.Turn(zone, centre, 20)); preview.PointerMove(PreviewSurface.Turn(zone, centre, 37)); preview.PointerUp(); Pump();
            check(Math.Abs(outline.Rotation - 37) < 0.5, $"dragging there turns the outline freely (here 37°, got {outline.Rotation:0.#}°)");
            var line = new Annotation { Kind = AnnotationKind.Line, Points = [new(10, 40), new(50, 40)], Width = 2, Start = 0, End = preview.Project.Media!.Duration };
            preview.Project.Annotations.Add(line); preview.SelectAnnotation(line); preview.UpdateLayout();
            var lineBox = preview.ScreenRect(line.Bounds()); var lineCentre = new Point(lineBox.X + lineBox.Width / 2, lineBox.Y + lineBox.Height / 2);
            var lineZone = new Point(lineBox.Right + d, lineBox.Top - d);
            check(preview.HoverCursor(lineZone) == CustomCursors.RotateAt("RNE", 0), "a line has the turning zones too");
            preview.MouseDownAt(lineZone, MouseButton.Left, 1); preview.PointerMove(PreviewSurface.Turn(lineZone, lineCentre, 90)); preview.PointerUp(); Pump();
            check(Math.Abs(line.Points[0].X - 30) < 0.6 && Math.Abs(line.Points[1].X - 30) < 0.6 && Math.Abs(Math.Abs(line.Points[1].Y - line.Points[0].Y) - 40) < 0.6,
                "dragging round a line's corner turns the line about its centre (here upright)");

            // ---- Capture frame › Edit opens the frame in another editor window; the video stays. ----
            editor.FrameQuestion = () => (MainWindow.FrameUse.Edit, false);
            check(Wait(() => editor.CaptureFrameAsync()) && controller.OtherEditors.Count == 1, "Capture frame › Edit opens another editor window");
            var other = controller.OtherEditors[0]; var otherPreview = (PreviewSurface)other.FindName("Preview");
            check(otherPreview.Project.Media is { IsVideo: false } frame && Path.GetFileName(frame.Path).StartsWith("CAPTURE_") && frame.Width == preview.Project.Media!.Width,
                "the new window has the frame as a picture");
            check(controller.Editor == editor && preview.Project.Media is { IsVideo: true } && preview.Project.Media.Path == original, "the video stays open in the first window");
            other.UpdateLayout();
            check(other.PicturesOnly && other.Title.Contains("Image Editor") && ((FrameworkElement)other.FindName("AppendVideoMenuItem")).Visibility != Visibility.Visible
                && ((FrameworkElement)other.FindName("CaptureFrameMenuItem")).Visibility != Visibility.Visible && ((FrameworkElement)other.FindName("PlaybackBar")).Visibility != Visibility.Visible
                && ((FrameworkElement)other.FindName("TrimToolButton")).Visibility != Visibility.Visible && ((FrameworkElement)other.FindName("CropTool")).IsVisible,
                "the frame's window is a picture editor: picture tools (Crop and the rest), no timeline, Trim, Append or Capture frame");
            var otherFailures = new List<string>(); other.WorkFailed = ex => otherFailures.Add(ex.Message);
            check(!Wait(() => other.OpenPathAsync(video)) && otherFailures.Any(f => f.Contains("pictures only")) && otherPreview.Project.Media is { IsVideo: false },
                "the picture editor will not open a video (it says to use the main editor) and keeps its picture");
            var framePath = otherPreview.Project.Media!.Path;
            other.Close(); Pump();
            check(controller.OtherEditors.Count == 0 && !File.Exists(framePath), "closing the frame's window wipes its working copy");
            editor.Close(); Pump();
        }
        finally
        {
            AppSettings.Path = savedPath;
            foreach (var open in controller.OtherEditors.ToList()) open.Close();
            if (controller.Editor is { } main) main.Close();
            controller.Store.WipeAll(); controller.Dispose();
        }
    }
}
