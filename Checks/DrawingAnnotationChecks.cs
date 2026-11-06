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

// 0.11.0: outline-only Rectangle and Ellipse drawings and the freehand Pen.
internal static class DrawingAnnotationChecks
{
    private const int W = 200, H = 100;
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static byte[] Pixels(BitmapSource image)
    {
        var converted = new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0);
        var pixels = new byte[converted.PixelWidth * converted.PixelHeight * 4]; converted.CopyPixels(pixels, converted.PixelWidth * 4, 0); return pixels;
    }
    private static bool Red(byte[] p, int x, int y) { var i = (y * W + x) * 4; return p[i + 2] > 195 && p[i + 1] < 60 && p[i] < 60; }
    private static bool White(byte[] p, int x, int y) { var i = (y * W + x) * 4; return p[i] > 250 && p[i + 1] > 250 && p[i + 2] > 250; }
    public static void Run(string output, Action<bool, string> check)
    {
        var whitePixels = new byte[W * H * 4]; Array.Fill(whitePixels, (byte)255);
        var image = BitmapSource.Create(W, H, 96, 96, PixelFormats.Bgra32, null, whitePixels, W * 4); image.Freeze();
        var media = new MediaReference(Path.Combine(output, "drawings.png"), 1, new string('0', 64), W, H, 0, false);

        // Model: saved, validated and rendered in export.
        var rectangle = new Annotation { Kind = AnnotationKind.Rectangle, Box = new(20, 20, 60, 40), Width = 4, Color = "#FF0000", Order = 1 };
        var oval = new Annotation { Kind = AnnotationKind.Oval, Box = new(110, 20, 60, 60), Width = 4, Color = "#FF0000", Order = 2 };
        var pen = new Annotation { Kind = AnnotationKind.Freehand, Points = [new(20, 85), new(60, 75), new(100, 90)], Width = 4, Color = "#FF0000", Order = 3 };
        var project = new RedactionProject { Media = media, Annotations = [rectangle, oval, pen] };
        ProjectStore.Validate(project);
        var reloaded = ProjectStore.Deserialize(ProjectStore.Serialize(project));
        check(reloaded.Annotations.Select(a => a.Kind).SequenceEqual([AnnotationKind.Rectangle, AnnotationKind.Oval, AnnotationKind.Freehand]) && reloaded.Annotations[0].Box == rectangle.Box && reloaded.Annotations[2].Points.Count == 3,
            "rectangle, ellipse and pen drawings are saved in the project and read back");
        bool Rejected(Action<Annotation> change, Annotation source)
        {
            var copy = ProjectStore.Deserialize(ProjectStore.Serialize(project)); change(copy.Annotations[project.Annotations.IndexOf(source)]);
            try { ProjectStore.Validate(copy); return false; } catch (InvalidDataException) { return true; }
        }
        check(Rejected(a => a.Box = a.Box with { Width = 0 }, rectangle) && Rejected(a => a.Points = [new(1, 1), new(2, 2)], oval) && Rejected(a => a.Box = new(150, 20, 80, 20), rectangle) && Rejected(a => a.Points = [new(5, 5)], pen),
            "invalid drawings are refused (empty box, stray points, outside the picture, a one-point pen line)");
        var pixels = Pixels(EffectRenderer.Render(image, project, 0, null, default, AnnotationRaster.Create(project, W, H)));
        check(Red(pixels, 20, 40) && Red(pixels, 50, 20) && White(pixels, 50, 40), "a rectangle outline exports its edge only, with the inside left untouched");
        check(Red(pixels, 110, 50) && Red(pixels, 140, 20) && White(pixels, 140, 50) && White(pixels, 112, 22), "an ellipse outline exports its curve only");
        check(Red(pixels, 20, 85) && Red(pixels, 60, 75), "a pen drawing exports along its path");
        check(rectangle.ToString().StartsWith("Rectangle outline") && oval.ToString().StartsWith("Oval outline") && pen.ToString() == "Freehand drawing", "drawings are named clearly in the Annotations list");

        // Drawing and editing in the window.
        var window = new MainWindow(new()) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false };
        window.Show(); window.Activate();
        var preview = (PreviewSurface)window.FindName("Preview");
        T Find<T>(string name) => (T)window.FindName(name);
        try
        {
            preview.Image = image;
            preview.Project = new RedactionProject { Media = media };
            typeof(MainWindow).GetMethod("Refresh", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, null);
            preview.ResetViewport(); window.UpdateLayout(); preview.Fit(); preview.UpdateLayout();
            var scale = Math.Min(preview.ActualWidth / W, preview.ActualHeight / H);
            Point At(double x, double y) => new((preview.ActualWidth - W * scale) / 2 + x * scale, (preview.ActualHeight - H * scale) / 2 + y * scale);
            void Press(Point p) { preview.MouseDownAt(p, MouseButton.Left, 1); preview.PointerUp(); Pump(); window.UpdateLayout(); }
            void Drag(Point from, Point to) { preview.MouseDownAt(from, MouseButton.Left, 1); preview.PointerMove(to); preview.PointerUp(); Pump(); window.UpdateLayout(); }
            void Tool(string name) { Find<Button>(name).RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent)); Pump(); }
            var buttons = Find<WrapPanel>("ToolButtons").Children.OfType<Button>().ToList();
            // 0.15.0 order (David): Text, Outline, Ellipse, Line, Polyline, Pen.
            check(buttons.IndexOf(Find<Button>("DrawRectangleTool")) == buttons.IndexOf(Find<Button>("TextTool")) + 1 && buttons.IndexOf(Find<Button>("FreehandTool")) == buttons.IndexOf(Find<Button>("PolylineTool")) + 1,
                "Outline, Ellipse and Pen sit with Text, Line and Polyline on the toolbar");

            Tool("DrawRectangleTool");
            check(Find<Button>("DrawRectangleTool").Background == window.FindResource("ToolSelected") && !Find<StackPanel>("EndsOptions").IsVisible && Find<TextBlock>("AnnotationOptionsLabel").Text == "Rectangle Outline (new)",
                "the Outline tool shows pressed, and its options have no arrowheads");
            Drag(At(20, 20), At(80, 60));
            var drawn = preview.Project.Annotations.Single();
            check(drawn.Kind == AnnotationKind.Rectangle && Math.Abs(drawn.Box.X - 20) < 1 && Math.Abs(drawn.Box.Width - 60) < 1 && Math.Abs(drawn.Box.Height - 40) < 1 && preview.SelectedAnnotation == drawn,
                "dragging with Outline draws a rectangle outline, selected");
            check(Find<Border>("LinePopup").IsVisible && Find<TextBlock>("LinePopupTitle").Text == "Rectangle Outline" && !Find<ComboBox>("LinePopupEnds").IsVisible && !Find<ComboBox>("LinePopupJoin").IsVisible,
                "a new outline opens its style window (colour, width, dash) without arrowheads or joins");
            Find<NumberSpinner>("LinePopupWidth").Value = 9; Pump();
            check(drawn.Width == 9, "the style window changes the outline's width");
            Drag(At(80, 60), At(100, 70));
            check(Math.Abs(drawn.Box.Width - 80) < 1 && Math.Abs(drawn.Box.Height - 50) < 1, "a corner handle resizes the outline");
            Press(At(190, 95));
            check(preview.SelectedAnnotation == null, "a click outside accepts the outline");
            Tool("SelectToolButton");
            Press(At(55, 45));
            check(preview.SelectedAnnotation == null, "clicking inside an outline doesn't pick it, so things inside stay reachable");
            Press(At(20, 45));
            check(preview.SelectedAnnotation == drawn, "clicking on an outline's edge selects it");
            Drag(At(20, 45), At(25, 45));
            check(Math.Abs(drawn.Box.X - 25) < 1, "dragging the edge moves the outline");

            Tool("DrawOvalTool");
            Drag(At(110, 20), At(170, 80));
            var ellipse = preview.Project.Annotations.Single(a => a.Kind == AnnotationKind.Oval);
            check(Math.Abs(ellipse.Box.Width - 60) < 1 && Find<TextBlock>("LinePopupTitle").Text == "Ellipse Outline", "dragging with Ellipse draws an ellipse outline");
            Press(At(190, 95)); Tool("SelectToolButton");
            Press(At(140, 50));
            check(preview.SelectedAnnotation == null, "the middle of an ellipse doesn't pick it");
            Press(At(110, 50));
            check(preview.SelectedAnnotation == ellipse, "clicking on an ellipse's curve selects it");
            Press(At(190, 95));

            Tool("FreehandTool");
            preview.MouseDownAt(At(20, 90), MouseButton.Left, 1);
            foreach (var x in new[] { 30, 40, 50, 60, 70 }) preview.PointerMove(At(x, 90 - (x % 20 == 0 ? 6 : 0)));
            preview.PointerUp(); Pump(); window.UpdateLayout();
            var freehand = preview.Project.Annotations.SingleOrDefault(a => a.Kind == AnnotationKind.Freehand);
            check(freehand != null && freehand.Points.Count >= 5 && preview.SelectedAnnotation == freehand && Find<TextBlock>("LinePopupTitle").Text == "Pen",
                "dragging with Pen draws a freehand line through the pointer's path");
            check(freehand != null && preview.HoverCursor(Point.Add(At(freehand.Points[1].X, freehand.Points[1].Y), new Vector(0, 0))) == Cursors.SizeAll, "a pen line has no point handles; it moves as a whole");
            var count = preview.Project.Annotations.Count;
            typeof(MainWindow).GetMethod("Undo", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic)!.Invoke(window, [window, new RoutedEventArgs()]); Pump();
            check(preview.Project.Annotations.Count == count - 1, "Undo removes the last drawing");
        }
        finally { preview.Project = new(); preview.SelectAnnotation(null); window.Close(); }
    }
}
