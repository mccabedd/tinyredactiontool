using System.Globalization;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

public sealed partial class PreviewSurface : FrameworkElement
{
    public LocalPlayback Player { get; } = new();
    private WriteableBitmap? playbackImage;
    private int pendingFrame;
    private long frameVersion;
    private long effectVersion = -1;
    private string? effectState;
    private BitmapSource? effectInput, effectImage;
    public BitmapSource? Image { get; set; }
    public bool UsePlayer { get; set; }
    public RedactionProject Project { get; set; } = new();
    public FrameTimeline? Timeline { get; set; }
    public Region? Selected { get; set; }
    public string Tool { get; set; } = "Rectangle";
    public RedactionEffect DrawingEffect { get; set; } = RedactionEffect.Opaque;
    public bool DrawingAggressive { get; set; }
    public int DrawingStrength { get; set; } = 5;
    public string DrawingColor { get; set; } = "#000000";
    internal bool AllowVisualObscuration { get; set; } = true;
    public double Time { get; set; }
    public event Action? BeforeEdit;
    public event Action? PausePlayback;
    public event Action<Region?>? SelectionChanged;
    public event Action? Edited;
    public event Action? ViewportChanged;
    public event Action? PlaybackFramePresented;
    public Func<bool>? CanEditFrame { get; set; }
    // Eyedropper (BASE-014): the next left click samples the exact loaded source frame.
    // Middle-button/Space panning still works; any other click or Escape cancels.
    public event Action<string>? ColorSampled;
    public event Action? EyedropperEnded;
    private bool eyedropper;
    public bool EyedropperActive
    {
        get => eyedropper;
        set { if (eyedropper == value) return; eyedropper = value; Cursor = value ? CustomCursors.Eyedropper : null; if (!value) EyedropperEnded?.Invoke(); }
    }
    // Still-image crop tool (0.7.0). The draft is uncommitted until MainWindow confirms it.
    public MediaRect? CropDraft
    {
        get => cropDraft;
        set { var changed = cropDraft != value || cropKind != null; cropDraft = value; cropKind = null; if (!changed) return; CropDraftChanged?.Invoke(); InvalidateVisual(); }
    }
    public event Action? CropDraftChanged;
    public event Action? CropConfirmRequested;
    private MediaRect? cropDraft;
    private string? cropKind;
    private MediaPoint cropStart;
    private MediaRect? cropOriginal;
    // The visible media area: the confirmed crop, otherwise the whole frame.
    private MediaRect View => ImageCrop.Bounds(Project);
    private double scale = 1;
    private Vector pan;
    private bool fit = true;
    private Point? gesture, panStart;
    private MediaPoint sourceStart;
    private MediaRect original;
    private List<MediaPoint> originalPolygon = [];
    private string? handle;
    private bool creating, editing;
    // Rectangle/Oval: a press outside every shape only arms drawing; the region is created once
    // the pointer moves, so a plain click just accepts (deselects) the current shape.
    private bool pendingCreate;
    private const double CreateThreshold = 3, CloseRadius = 8;
    private readonly List<MediaPoint> polygon = [];
    public string ZoomLabel => fit ? $"Fit ({scale * VisualTreeHelper.GetDpi(this).DpiScaleX * 100:0}%)" : $"{scale * VisualTreeHelper.GetDpi(this).DpiScaleX * 100:0}%";
    public PreviewSurface()
    {
        Focusable = true; ClipToBounds = true;
        Player.FrameAvailable += (_, _) =>
        {
            if (Interlocked.Exchange(ref pendingFrame, 1) != 0 || Dispatcher.HasShutdownStarted) return;
            Dispatcher.BeginInvoke(System.Windows.Threading.DispatcherPriority.Render, () =>
            {
                try
                {
                    if (Player.FrameWidth < 1 || Player.FrameHeight < 1) return;
                    if (playbackImage == null || playbackImage.PixelWidth != Player.FrameWidth || playbackImage.PixelHeight != Player.FrameHeight)
                        playbackImage = new WriteableBitmap(Player.FrameWidth, Player.FrameHeight, 96, 96, PixelFormats.Bgr32, null);
                    if (Player.CopyLatest(playbackImage, out var frameTime) && UsePlayer)
                    { frameVersion++; Time = Math.Clamp(frameTime, 0, Project.Media?.Duration ?? 0); PlaybackFramePresented?.Invoke(); InvalidateVisual(); }
                }
                finally { Interlocked.Exchange(ref pendingFrame, 0); }
            });
        };
        SizeChanged += (_, _) => { if (fitWidth) { var top = pan.Y; FitWidth(); ScrollBy(top - pan.Y); } UpdateFit(); ViewportChanged?.Invoke(); InvalidateVisual(); };
    }
    private void UpdateFit() { if (fit && Project.Media != null) { var v = View; scale = Math.Max(0.001, Math.Min(ActualWidth / v.Width, ActualHeight / v.Height)); } }
    public void ResetViewport() { fit = true; fitWidth = false; pan = default; polygon.Clear(); playbackImage = null; UpdateFit(); ViewportChanged?.Invoke(); InvalidateVisual(); }
    public void Fit() { fit = true; fitWidth = false; pan = default; UpdateFit(); ViewportChanged?.Invoke(); InvalidateVisual(); }
    // 0.23.0 (David): Fit width, for reading a tall picture (a scrolling capture) from the top; the wheel then
    // scrolls down it, and Ctrl+wheel zooms.
    private bool fitWidth;
    internal bool FittingWidth => fitWidth;
    public void FitWidth()
    {
        if (Project.Media == null) return;
        var v = View; fit = false; fitWidth = true;
        var dpi = VisualTreeHelper.GetDpi(this).DpiScaleX;
        scale = Math.Clamp(ActualWidth / v.Width, 0.02 / dpi, 8 / dpi);
        pan = new(0, Math.Max(0, (v.Height * scale - ActualHeight) / 2)); // The top of the picture at the top.
        ViewportChanged?.Invoke(); InvalidateVisual();
    }
    // Scrolls a picture taller than the view, keeping it on screen.
    private void ScrollBy(double pixels)
    {
        var overflow = Math.Max(0, (View.Height * scale - ActualHeight) / 2);
        pan = new(pan.X, Math.Clamp(pan.Y + pixels, -overflow, overflow));
        ViewportChanged?.Invoke(); InvalidateVisual();
    }
    public void ActualPixels() => Zoom(1 / (VisualTreeHelper.GetDpi(this).DpiScaleX * scale), new(ActualWidth / 2, ActualHeight / 2));
    protected override void OnDpiChanged(DpiScale oldDpi, DpiScale newDpi)
    {
        base.OnDpiChanged(oldDpi, newDpi);
        if (!fit) { var ratio = oldDpi.DpiScaleX / newDpi.DpiScaleX; scale *= ratio; pan *= ratio; }
        UpdateFit(); ViewportChanged?.Invoke(); InvalidateVisual();
    }
    private Point Offset { get { if (Project.Media == null) return default; var v = View; return new((ActualWidth - v.Width * scale) / 2 - v.X * scale + pan.X, (ActualHeight - v.Height * scale) / 2 - v.Y * scale + pan.Y); } }
    private MediaPoint Source(Point p) { var o = Offset; return new((p.X - o.X) / scale, (p.Y - o.Y) / scale); }
    private Point Screen(MediaPoint p) { var o = Offset; return new(o.X + p.X * scale, o.Y + p.Y * scale); }
    private Rect Screen(MediaRect b) { var p = Screen(new MediaPoint(b.X, b.Y)); return new(p.X, p.Y, b.Width * scale, b.Height * scale); }
    public void Zoom(double factor, Point pointer)
    {
        if (Project.Media == null) return;
        var source = Source(pointer); fit = false; fitWidth = false; var dpi = VisualTreeHelper.GetDpi(this).DpiScaleX; scale = Math.Clamp(scale * factor, 0.02 / dpi, 8 / dpi);
        var v = View;
        pan = new(pointer.X - ((ActualWidth - v.Width * scale) / 2 - v.X * scale) - source.X * scale,
            pointer.Y - ((ActualHeight - v.Height * scale) / 2 - v.Y * scale) - source.Y * scale);
        InvalidateVisual();
        ViewportChanged?.Invoke();
    }
    private bool Active(Region r) => Project.Media?.IsVideo != true || Timeline?.IsActive(r, Time) == true;
    // Two tilted pages, a video (play button) and a picture (sun and hills), drawn in a 200 × 150 box (TRT's own drawing).
    internal static void DrawEmptyPicture(DrawingContext dc, Point centre, double width, Brush ink, Brush backdrop)
    {
        var scale = width / 200;
        var pen = new Pen(ink, 5) { LineJoin = PenLineJoin.Round, StartLineCap = PenLineCap.Round, EndLineCap = PenLineCap.Round };
        var page = Geometry.Parse("M0,0 L64,0 L84,20 L84,108 L0,108 Z M64,0 L64,20 L84,20");
        dc.PushTransform(new TranslateTransform(centre.X - 100 * scale, centre.Y - 75 * scale));
        dc.PushTransform(new ScaleTransform(scale, scale));
        // The video page, leaning left.
        dc.PushTransform(new TransformGroup { Children = { new RotateTransform(-11, 42, 54), new TranslateTransform(14, 22) } });
        dc.DrawGeometry(backdrop, pen, page);
        dc.DrawEllipse(ink, null, new Point(42, 62), 22, 22);
        dc.DrawGeometry(backdrop, null, Geometry.Parse("M36,51 L53,62 L36,73 Z"));
        dc.Pop();
        // The picture page, leaning right and in front.
        dc.PushTransform(new TransformGroup { Children = { new RotateTransform(7, 42, 54), new TranslateTransform(100, 18) } });
        dc.DrawGeometry(backdrop, pen, page);
        var thin = new Pen(ink, 4) { LineJoin = PenLineJoin.Round };
        dc.DrawRectangle(null, thin, new Rect(11, 38, 62, 46));
        dc.DrawEllipse(ink, null, new Point(26, 52), 6, 6);
        dc.DrawGeometry(ink, null, Geometry.Parse("M15,80 L31,62 L39,72 L53,54 L69,80 Z"));
        dc.Pop();
        dc.Pop(); dc.Pop();
    }
    protected override void OnRender(DrawingContext dc)
    {
        base.OnRender(dc);
        // Themed workspace behind the picture (grey in Light).
        dc.DrawRectangle(TryFindResource("CanvasBackdrop") as Brush ?? new SolidColorBrush(Color.FromRgb(15, 17, 21)), null, new Rect(RenderSize));
        if (Project.Media is not { } media)
        {
            effectInput = null; effectImage = null; effectState = null;
            // 0.18.0 (David): a picture of a video and a picture file instead of "Open an image or video to begin".
            var ink = TryFindResource("CanvasText") as Brush ?? Brushes.LightGray;
            var backdrop = TryFindResource("CanvasBackdrop") as Brush ?? Brushes.Black;
            var size = Math.Clamp(Math.Min(ActualWidth, ActualHeight) * 0.35, 90, 260);
            DrawEmptyPicture(dc, new(ActualWidth / 2, ActualHeight / 2 - size * 0.12), size, ink, backdrop);
            var text = new FormattedText("Open or Drop a Picture or Video Here", CultureInfo.CurrentCulture, FlowDirection.LeftToRight, new Typeface("Segoe UI"), 13, ink, VisualTreeHelper.GetDpi(this).PixelsPerDip);
            dc.DrawText(text, new(Math.Max(12, (ActualWidth - text.Width) / 2), ActualHeight / 2 + size * 0.42)); return;
        }
        var view = View;
        if (fit) scale = Math.Max(0.001, Math.Min(ActualWidth / view.Width, ActualHeight / view.Height));
        var mediaRect = Screen(new MediaRect(0, 0, media.Width, media.Height));
        // Only the confirmed crop is shown; regions outside it are clipped like the export.
        dc.PushClip(new RectangleGeometry(Screen(view)));
        var input = UsePlayer && playbackImage != null ? playbackImage : Image;
        var composed = Project.Regions.Any(r => Active(r) && r.Effect != RedactionEffect.Opaque && !SeeThrough(r));
        // Transparent parts of a picture (a freehand capture, 0.22.1) show a checkerboard, as in other editors.
        if (input != null && !UsePlayer && Project.Media is { IsVideo: false }) dc.DrawRectangle(Transparency.Checkerboard, null, mediaRect);
        if (input != null)
        {
            if (composed)
            {
                var state = ProjectStore.Serialize(Project) + Time.ToString("R", CultureInfo.InvariantCulture) + (UsePlayer ? "playing" : "") + Selected?.Id;
                var version = UsePlayer ? frameVersion : -1;
                if (effectInput != input || effectState != state || effectVersion != version)
                {
                    // See-through redactions are left out of the preview picture and drawn faintly below.
                    var shown = Project;
                    if (Project.Regions.Any(SeeThrough)) { shown = ProjectStore.Deserialize(ProjectStore.Serialize(Project)); shown.Regions.RemoveAll(c => Project.Regions.Any(r => r.Id == c.Id && SeeThrough(r))); }
                    effectImage = EffectRenderer.Render(input, shown, Time, Timeline); effectInput = input; effectState = state; effectVersion = version;
                }
                dc.DrawImage(effectImage, mediaRect);
            }
            else dc.DrawImage(input, mediaRect);
        }
        foreach (var r in Project.Regions.Where(Active))
        {
            var geometry = ShapeGeometry(r, r.GeometryAt(Math.Clamp(Time, r.Start, r.End)));
            if (SeeThrough(r))
            {
                // 0.22.0 (David): a box that stays put (no tracking) on a video is see-through while it plays and
                // while it is selected, so the end of what it should hide can be seen. Export is never affected.
                var colour = r.Effect == RedactionEffect.Opaque ? (Color)ColorConverter.ConvertFromString(r.Color) : Colors.Gray;
                dc.DrawGeometry(new SolidColorBrush(Color.FromArgb(SeeThroughAlpha, colour.R, colour.G, colour.B)), new Pen(Brushes.OrangeRed, 1.5) { DashStyle = DashStyles.Dash }, geometry);
            }
            else if (!composed && r.Effect == RedactionEffect.Opaque)
            {
                Geometry coverage = geometry;
                if (r.CoverageMargin > 0) coverage = new CombinedGeometry(GeometryCombineMode.Union, geometry, geometry.GetWidenedPathGeometry(new Pen(Brushes.Black, r.CoverageMargin * scale * 2)));
                dc.DrawGeometry(new SolidColorBrush((Color)ColorConverter.ConvertFromString(r.Color)), null, coverage);
            }
            if (r.ShowDecorations)
            {
                dc.DrawGeometry(null, new Pen(r == Selected ? Brushes.DeepSkyBlue : Brushes.Gold, r == Selected ? 2 : 1), geometry);
                if (r == Selected) DrawHandles(dc, RegionHandles(r));
            }
        }
        DrawAnnotations(dc);
        DrawMarquee(dc);
        if (polygon.Count > 0)
        {
            for (var i = 1; i < polygon.Count; i++) dc.DrawLine(new Pen(Brushes.DeepSkyBlue, 2), Screen(polygon[i - 1]), Screen(polygon[i]));
            foreach (var p in polygon) dc.DrawEllipse(Brushes.White, null, Screen(p), 3, 3);
            // Once the shape can close, ring the first point: clicking it closes the polygon.
            if (polygon.Count >= 3) dc.DrawEllipse(null, new Pen(Brushes.DeepSkyBlue, 2), Screen(polygon[0]), 6, 6);
        }
        if (Tool == "Crop" && CropDraft is { } draft && draft.Width > 0 && draft.Height > 0)
        {
            var area = Screen(view); var box = Screen(draft);
            dc.DrawGeometry(new SolidColorBrush(Color.FromArgb(145, 0, 0, 0)), null,
                new CombinedGeometry(GeometryCombineMode.Exclude, new RectangleGeometry(area), new RectangleGeometry(box)));
            var guide = new Pen(Brushes.DodgerBlue, 1);
            dc.DrawRectangle(null, guide, box);
            foreach (var fraction in new[] { 1 / 3d, 2 / 3d })
            {
                dc.DrawLine(guide, new(box.Left + box.Width * fraction, box.Top), new(box.Left + box.Width * fraction, box.Bottom));
                dc.DrawLine(guide, new(box.Left, box.Top + box.Height * fraction), new(box.Right, box.Top + box.Height * fraction));
            }
            foreach (var h in Handles(draft, RegionShape.Rectangle)) dc.DrawRectangle(Brushes.White, guide, new Rect(h.Value.X - 4, h.Value.Y - 4, 8, 8));
        }
        dc.Pop();
    }
    private Geometry ShapeGeometry(Region r, MediaRect bounds)
    {
        var rect = Screen(bounds);
        Geometry geometry;
        if (r.Shape == RegionShape.Rectangle) geometry = new RectangleGeometry(rect);
        else if (r.Shape == RegionShape.Oval) geometry = new EllipseGeometry(rect);
        else
        {
            var stream = new StreamGeometry();
            using (var context = stream.Open())
            {
                var points = r.Polygon.Select(p => new Point(rect.X + p.X * rect.Width, rect.Y + p.Y * rect.Height)).ToArray();
                if (points.Length > 0) { context.BeginFigure(points[0], true, true); context.PolyLineTo(points.Skip(1).ToArray(), true, false); }
            }
            geometry = stream;
        }
        // 0.19.0: a turned shape is drawn (and hit) turned about the centre of its box.
        if (r.Rotation != 0) geometry.Transform = new RotateTransform(r.Rotation, rect.X + rect.Width / 2, rect.Y + rect.Height / 2);
        return geometry;
    }
    internal const byte SeeThroughAlpha = 26; // About 10 %.
    internal bool SeeThrough(Region r) => Project.Media is { IsVideo: true } && r.Tracking.Count == 0 && (UsePlayer || r == Selected);
    // ---- Turning shapes (0.21.0, David): just outside each corner of the selected shape the
    // pointer becomes the turning arrow; drag there to turn the shape freely; Shift keeps to 15° steps.
    // (0.19.0 had a round handle above the shape instead.) The zones are not drawn: "RNW", "RNE", "RSE", "RSW".
    internal const double RotateZoneDistance = 14, RotateZoneRadius = 10;
    private double originalRotation; // The selected redaction's turn when the drag began.
    internal static Point Turn(Point p, Point centre, double degrees)
    {
        var turned = ShapeTurn.Rotate(new MediaPoint(p.X, p.Y), new MediaPoint(centre.X, centre.Y), degrees); return new(turned.X, turned.Y);
    }
    // The four turning zones sit diagonally out from the box's corners; every handle turns with the shape.
    private Dictionary<string, Point> WithRotateHandle(Dictionary<string, Point> handles, Rect box, double rotation)
    {
        var d = RotateZoneDistance / Math.Sqrt(2);
        handles["RNW"] = new(box.Left - d, box.Top - d); handles["RNE"] = new(box.Right + d, box.Top - d);
        handles["RSE"] = new(box.Right + d, box.Bottom + d); handles["RSW"] = new(box.Left - d, box.Bottom + d);
        if (rotation == 0) return handles;
        var centre = new Point(box.X + box.Width / 2, box.Y + box.Height / 2);
        return handles.ToDictionary(h => h.Key, h => Turn(h.Value, centre, rotation));
    }
    private static bool IsTurnZone(string key) => key[0] == 'R';
    // How close the pointer must be: the turning zones are a little larger than the square handles.
    private static double ReachOf(string key, double handleRadius) => IsTurnZone(key) ? RotateZoneRadius : handleRadius;
    private static void DrawHandles(DrawingContext dc, Dictionary<string, Point> handles)
    {
        var pen = new Pen(Brushes.DeepSkyBlue, 1);
        foreach (var h in handles.Where(h => !IsTurnZone(h.Key))) dc.DrawRectangle(Brushes.White, pen, new Rect(h.Value.X - 4, h.Value.Y - 4, 8, 8));
    }
    // The pointer's direction from the centre, in degrees (0° straight above, clockwise).
    internal static double AngleTo(Point centre, Point pointer, bool snap)
    {
        var angle = Math.Atan2(pointer.Y - centre.Y, pointer.X - centre.X) * 180 / Math.PI + 90;
        if (snap) angle = Math.Round(angle / 15) * 15;
        return ShapeTurn.Normalise(angle);
    }
    // The turn after dragging from start to pointer: the shape turns by as much as the pointer went round the centre.
    internal static double TurnedBy(Point centre, Point start, Point pointer, double startRotation, bool snap)
    {
        var angle = startRotation + AngleTo(centre, pointer, false) - AngleTo(centre, start, false);
        if (snap) angle = Math.Round(angle / 15) * 15;
        return ShapeTurn.Normalise(angle);
    }
    private Dictionary<string, Point> Handles(MediaRect b, RegionShape shape)
    {
        var r = Screen(b);
        var result = new Dictionary<string, Point> { ["N"] = new(r.X + r.Width / 2, r.Top), ["E"] = new(r.Right, r.Y + r.Height / 2), ["S"] = new(r.X + r.Width / 2, r.Bottom), ["W"] = new(r.Left, r.Y + r.Height / 2) };
        if (shape != RegionShape.Oval)
        { result["NW"] = r.TopLeft; result["NE"] = r.TopRight; result["SW"] = r.BottomLeft; result["SE"] = r.BottomRight; }
        return result;
    }
    // A polygon is edited by its corners ("V0", "V1", …: BASE-007); other shapes by their box.
    private Dictionary<string, Point> RegionHandles(Region r)
    {
        var b = r.GeometryAt(Time); var box = Screen(b);
        var handles = r.Shape != RegionShape.Polygon || r.Polygon.Count < 3 ? Handles(b, r.Shape) :
            r.Polygon.Select((v, i) => (v, i)).ToDictionary(x => "V" + x.i, x => new Point(box.X + x.v.X * box.Width, box.Y + x.v.Y * box.Height));
        return WithRotateHandle(handles, box, r.Rotation);
    }
    private string? RegionHandleAt(Region r, Point p) => RegionHandles(r).Where(h => (h.Value - p).Length <= ReachOf(h.Key, 8)).OrderBy(h => (h.Value - p).Length).Select(h => h.Key).FirstOrDefault();
    // A point in the selected shape's own (unturned) frame, about the centre it had when the drag began.
    private MediaPoint ToLocal(MediaPoint world) => Selected is { Rotation: not 0 } r ? ShapeTurn.Rotate(world, ShapeTurn.Centre(original), -r.Rotation) : world;
    // Resizing a turned box: shift the new box so the edge or corner opposite the dragged handle stays put.
    private MediaRect KeepOppositeInPlace(MediaRect bounds, string dragged, double rotation)
    {
        MediaPoint Anchor(MediaRect b) => new(dragged.Contains('E') ? b.X : dragged.Contains('W') ? b.X + b.Width : b.X + b.Width / 2,
                                               dragged.Contains('S') ? b.Y : dragged.Contains('N') ? b.Y + b.Height : b.Y + b.Height / 2);
        var before = ShapeTurn.Rotate(Anchor(original), ShapeTurn.Centre(original), rotation);
        var after = ShapeTurn.Rotate(Anchor(bounds), ShapeTurn.Centre(bounds), rotation);
        return bounds with { X = bounds.X + before.X - after.X, Y = bounds.Y + before.Y - after.Y };
    }
    // After a corner of a turned polygon moves, the rest of the polygon stays where it was on screen.
    private void KeepVertexInPlace(Region r, int keep)
    {
        var now = r.GeometryAt(Time);
        MediaPoint World(MediaRect b, MediaPoint v) => ShapeTurn.Rotate(new(b.X + v.X * b.Width, b.Y + v.Y * b.Height), ShapeTurn.Centre(b), r.Rotation);
        var before = World(original, originalPolygon[keep]); var after = World(now, r.Polygon[keep]);
        r.PutManual(Time, now with { X = now.X + before.X - after.X, Y = now.Y + before.Y - after.Y });
    }
    // Moves one corner to the pointer; the bounding box is recomputed and the corners re-expressed in it.
    private void DragVertex(Region r, int index, MediaPoint to, MediaReference m)
    {
        var points = originalPolygon.Select(v => new MediaPoint(original.X + v.X * original.Width, original.Y + v.Y * original.Height)).ToList();
        points[index] = new(Math.Clamp(to.X, 0, m.Width), Math.Clamp(to.Y, 0, m.Height));
        var left = points.Min(v => v.X); var top = points.Min(v => v.Y);
        var width = Math.Max(1, points.Max(v => v.X) - left); var height = Math.Max(1, points.Max(v => v.Y) - top);
        if (left + width > m.Width) left = m.Width - width;
        if (top + height > m.Height) top = m.Height - height;
        r.Polygon = points.Select(v => new MediaPoint(Math.Clamp((v.X - left) / width, 0, 1), Math.Clamp((v.Y - top) / height, 0, 1))).ToList();
        r.PutManual(Time, new MediaRect(left, top, width, height));
    }
    protected override void OnMouseWheel(MouseWheelEventArgs e)
    {
        if (fitWidth && !Keyboard.Modifiers.HasFlag(ModifierKeys.Control)) ScrollBy(e.Delta); // A wheel notch moves 120 pixels.
        else Zoom(e.Delta > 0 ? 1.15 : 1 / 1.15, e.GetPosition(this));
        e.Handled = true;
    }
    protected override void OnMouseDown(MouseButtonEventArgs e)
    {
        base.OnMouseDown(e);
        if (MouseDownAt(e.GetPosition(this), e.ChangedButton, e.ClickCount)) e.Handled = true;
    }
    // The real mouse-press path (press handling, then keyboard focus), callable by checks.
    internal bool MouseDownAt(Point p, MouseButton button, int clickCount)
    {
        // Handle the press before taking focus: an open text editor must see this click as
        // its confirming outside-click, not lose focus first and let the click draw.
        var handled = PointerDown(p, button, clickCount);
        // A double-click that just opened the text editor leaves focus in the editor; taking it
        // here made the editor read that as an outside click and close at once (0.9.1 bug).
        if (EditingText == null) Focus();
        return handled;
    }
    // A drag (move, resize, draw or pan) began or ended: floating panels hide meanwhile.
    public event Action? GestureStarted, GestureEnded;
    internal Rect RegionScreenBounds(Region r) => ShapeGeometry(r, r.GeometryAt(Math.Clamp(Time, r.Start, r.End))).Bounds;
    internal bool IsShown(Region r) => Active(r);
    // Pointer handling takes control coordinates so checks can drive exact gestures.
    // Returns true when the press was consumed (eyedropper or text-editor confirmation).
    internal bool PointerDown(Point p, MouseButton button, int clickCount = 1)
    {
        var handled = PointerDownCore(p, button, clickCount);
        if (gesture != null) GestureStarted?.Invoke();
        return handled;
    }
    private bool PointerDownCore(Point p, MouseButton button, int clickCount)
    {
        if (Project.Media is not { } m) return false;
        selectionBeforePress = Selected != null || SelectedAnnotation != null || MultiRegions.Count + MultiAnnotations.Count > 0;
        // Outside-click confirms the floating text editor and is consumed (baseline).
        if (EditingText != null) { if (button == MouseButton.Left) TextEditConfirmRequested?.Invoke(); return true; }
        if (EyedropperActive && button != MouseButton.Middle && !Keyboard.IsKeyDown(Key.Space))
        {
            if (button != MouseButton.Left) { EyedropperActive = false; return true; }
            SampleAt(p);
            return true;
        }
        if (button == MouseButton.Middle || button == MouseButton.Right && Tool != "Polygon" || Keyboard.IsKeyDown(Key.Space) || Tool == "Pan")
        { gesture = p; panStart = new Point(pan.X, pan.Y); Cursor = CustomCursors.ClosedHand; CaptureMouse(); return false; }
        if (Tool == "Crop")
        {
            if (button == MouseButton.Left && BeginCrop(p)) CaptureMouse();
            return false;
        }
        var s = Source(p);
        if (!View.Contains(s)) return false;
        if (CanEditFrame?.Invoke() == false) return false;
        if (MarqueePointerDown(p, s, button)) return false;
        if (AnnotationPointerDown(p, s, button, clickCount)) return false;
        // With no polygon in progress, a press on an existing shape (or the selected shape's
        // handle) selects/moves it like Rectangle and Oval do, rather than starting a polygon.
        var onShape = polygon.Count == 0 && button == MouseButton.Left &&
            (Selected != null && Active(Selected) && RegionHandleAt(Selected, p) != null ||
             Project.Regions.Any(r => Active(r) && ShapeGeometry(r, r.GeometryAt(Time)).FillContains(p)));
        if (Tool == "Polygon" && !onShape)
        {
            PausePlayback?.Invoke();
            // Baseline BASE-009: with no draft in progress, a click outside while a shape is
            // selected only accepts it; the next click begins a new polygon.
            if (polygon.Count == 0 && Selected != null && button == MouseButton.Left)
            {
                Selected = null; SelectionChanged?.Invoke(null); InvalidateVisual(); return false;
            }
            if (button == MouseButton.Right || clickCount == 2) { CompletePolygon(); return false; }
            // Clicking back on the first point closes the shape.
            if (polygon.Count >= 3 && (Screen(polygon[0]) - p).Length <= CloseRadius) { CompletePolygon(); return false; }
            if (polygon.Count > 0 && Keyboard.Modifiers.HasFlag(ModifierKeys.Shift))
            {
                var last = polygon[^1]; var dx = s.X - last.X; var dy = s.Y - last.Y;
                var angle = Math.Round(Math.Atan2(dy, dx) / (Math.PI / 4)) * Math.PI / 4; var length = Math.Sqrt(dx * dx + dy * dy);
                s = new(Math.Clamp(last.X + Math.Cos(angle) * length, 0, m.Width), Math.Clamp(last.Y + Math.Sin(angle) * length, 0, m.Height));
            }
            polygon.Add(s); InvalidateVisual(); return false;
        }
        if (button != MouseButton.Left) return false;
        var selectedHandle = Selected != null && Active(Selected) ? RegionHandleAt(Selected, p) : null;
        var hit = Project.Regions.AsEnumerable().Reverse().FirstOrDefault(r => Active(r) && ShapeGeometry(r, r.GeometryAt(Time)).FillContains(p));
        if (selectedHandle != null) hit = Selected;
        if (hit != null) { BeforeEdit?.Invoke(); editing = true; Selected = hit; handle = selectedHandle ?? "Move"; original = hit.GeometryAt(Time); originalRotation = hit.Rotation; originalPolygon = [.. hit.Polygon]; creating = false; }
        else
        {
            // Outside every shape: accept (deselect) the current one. Rectangle/Oval drawing
            // starts only if the pointer then moves; see BeginPendingCreate.
            Selected = null;
            if (Tool == "Select") { SelectionChanged?.Invoke(null); BeginMarquee(p, s); return false; }
            if (Tool is not ("Rectangle" or "Oval")) { SelectionChanged?.Invoke(null); InvalidateVisual(); return false; }
            pendingCreate = true;
        }
        gesture = p; sourceStart = s; CaptureMouse(); SelectionChanged?.Invoke(Selected); InvalidateVisual();
        return false;
    }
    // Hover feedback: open hand for Pan (or Space), resize arrows over a selected object's
    // handles, the move cursor over any object, a crosshair when a drawing tool would draw.
    internal void UpdateHoverCursor(Point p)
    {
        Cursor = HoverCursor(p);
    }
    internal Cursor? HoverCursor(Point p)
    {
        if (EyedropperActive) return CustomCursors.Eyedropper;
        if (Project.Media == null) return null;
        if (Tool == "Pan" || Keyboard.IsKeyDown(Key.Space)) return CustomCursors.OpenHand;
        if (EditingText != null || Tool == "Polygon" && polygon.Count > 0) return Cursors.Cross;
        if (SelectedAnnotation is { } a && Project.Annotations.Contains(a) && Active(a) && AnnotationHandleAt(a, p) is { } annotationHandle)
            return IsTurnZone(annotationHandle) ? CustomCursors.RotateAt(annotationHandle, a.Rotation) : annotationHandle.StartsWith('P') ? Cursors.Cross : CustomCursors.Resize(annotationHandle, a.Rotation);
        if (Selected != null && Active(Selected) && RegionHandleAt(Selected, p) is { } handle)
            return IsTurnZone(handle) ? CustomCursors.RotateAt(handle, Selected.Rotation) : handle.StartsWith('V') ? Cursors.Cross : CustomCursors.Resize(handle, Selected.Rotation);
        if (Project.Annotations.Any(x => Active(x) && HitAnnotation(x, p)) || Project.Regions.Any(r => Active(r) && ShapeGeometry(r, r.GeometryAt(Time)).FillContains(p)))
            return Cursors.SizeAll;
        return Tool == "Select" ? null : Cursors.Cross;
    }
    private void BeginPendingCreate(MediaReference m)
    {
        pendingCreate = false;
        BeforeEdit?.Invoke(); editing = true; creating = true;
        Selected = NewDrawingRegion(Tool == "Oval" ? RegionShape.Oval : RegionShape.Rectangle);
        Selected.PutManual(Time, new MediaRect(sourceStart.X, sourceStart.Y, 1, 1).Clamp(m.Width, m.Height));
        Project.Regions.Add(Selected); SelectionChanged?.Invoke(Selected);
    }
    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        // A drag needs a held button; ignore moves raised by capture changes or a lost button-up.
        if (gesture != null && e.LeftButton == MouseButtonState.Released && e.MiddleButton == MouseButtonState.Released && e.RightButton == MouseButtonState.Released) return;
        PointerMove(e.GetPosition(this));
    }
    internal void PointerMove(Point p)
    {
        if (Tool == "Crop" && panStart == null)
        {
            if (cropKind != null) DragCrop(p); else Cursor = EyedropperActive ? CustomCursors.Eyedropper : CropCursor(p);
            return;
        }
        if (gesture == null) { UpdateHoverCursor(p); return; }
        if (Project.Media is not { } m) return;
        if (panStart is { } ps) { pan = new(ps.X + p.X - gesture.Value.X, ps.Y + p.Y - gesture.Value.Y); InvalidateVisual(); return; }
        if (MarqueePointerMove(Source(p), m)) return;
        if (AnnotationPointerMove(p, m)) return;
        if (pendingCreate)
        {
            if ((p - gesture.Value).Length < CreateThreshold) return;
            BeginPendingCreate(m);
        }
        if (Selected == null) return;
        var s = Source(p); var dx = s.X - sourceStart.X; var dy = s.Y - sourceStart.Y;
        MediaRect bounds;
        if (creating)
        {
            if (Keyboard.Modifiers.HasFlag(ModifierKeys.Shift)) { var side = Math.Min(Math.Abs(dx), Math.Abs(dy)); dx = Math.CopySign(side, dx); dy = Math.CopySign(side, dy); }
            bounds = new(Math.Min(sourceStart.X, sourceStart.X + dx), Math.Min(sourceStart.Y, sourceStart.Y + dy), Math.Max(1, Math.Abs(dx)), Math.Max(1, Math.Abs(dy)));
        }
        else if (IsTurnZone(handle!))
        {
            var box = Screen(original);
            Selected.Rotation = TurnedBy(new(box.X + box.Width / 2, box.Y + box.Height / 2), gesture.Value, p, originalRotation, Keyboard.Modifiers.HasFlag(ModifierKeys.Shift));
            InvalidateVisual(); return;
        }
        else if (handle![0] == 'V')
        {
            var index = int.Parse(handle.AsSpan(1), CultureInfo.InvariantCulture);
            DragVertex(Selected, index, ClampToMedia(ToLocal(s), m), m);
            if (Selected.Rotation != 0) KeepVertexInPlace(Selected, (index + 1) % originalPolygon.Count);
            InvalidateVisual(); return;
        }
        else if (handle == "Move") bounds = original with { X = Math.Clamp(original.X + dx, 0, m.Width - original.Width), Y = Math.Clamp(original.Y + dy, 0, m.Height - original.Height) };
        else
        {
            // On a turned shape the pointer is read in the shape's own frame (0.19.0).
            if (Selected.Rotation != 0) { var local = ToLocal(s); var start = ToLocal(sourceStart); dx = local.X - start.X; dy = local.Y - start.Y; }
            var left = original.X; var top = original.Y; var right = left + original.Width; var bottom = top + original.Height;
            if (handle!.Contains('W')) left = Math.Min(right - 1, left + dx);
            if (handle.Contains('E')) right = Math.Max(left + 1, right + dx);
            if (handle.Contains('N')) top = Math.Min(bottom - 1, top + dy);
            if (handle.Contains('S')) bottom = Math.Max(top + 1, bottom + dy);
            bounds = new(left, top, right - left, bottom - top);
            if (Keyboard.Modifiers.HasFlag(ModifierKeys.Shift)) bounds = bounds with { Height = bounds.Width };
            if (Selected.Rotation != 0) bounds = KeepOppositeInPlace(bounds, handle, Selected.Rotation);
        }
        Selected.PutManual(Time, bounds.Clamp(m.Width, m.Height)); InvalidateVisual();
    }
    protected override void OnMouseUp(MouseButtonEventArgs e) { base.OnMouseUp(e); PointerUp(); }
    internal void PointerUp()
    {
        if (cropKind != null) EndCrop();
        if (panStart == null) { MarqueePointerUp(); AnnotationPointerUp(); }
        if (panStart != null) Cursor = Tool == "Pan" ? CustomCursors.OpenHand : null;
        var hadGesture = gesture != null;
        gesture = null; panStart = null; handle = null; pendingCreate = false; ReleaseMouseCapture();
        if (editing) { editing = false; Edited?.Invoke(); }
        if (hadGesture) GestureEnded?.Invoke();
    }
    // Returns true when a colour was sampled. While live playback is shown the click
    // first requests the exact paused frame and the eyedropper stays armed.
    internal bool SampleAt(Point screen)
    {
        if (!EyedropperActive || Project.Media is not { } m) return false;
        var s = Source(screen); var v = View;
        if (s.X < v.X || s.Y < v.Y || s.X >= v.X + v.Width || s.Y >= v.Y + v.Height) { EyedropperActive = false; return false; }
        if (CanEditFrame?.Invoke() == false) return false;
        var colour = Image == null ? null : SampleColor(Image, m, s);
        EyedropperActive = false;
        if (colour == null) return false;
        ColorSampled?.Invoke(colour);
        return true;
    }
    // Reads one pixel of the exact source frame in canonical media coordinates.
    // Partially transparent pixels are composited over black, as the renderer does.
    internal static string? SampleColor(BitmapSource image, MediaReference media, MediaPoint point)
    {
        if (point.X < 0 || point.Y < 0 || point.X >= media.Width || point.Y >= media.Height) return null;
        var x = Math.Clamp((int)Math.Floor(point.X * image.PixelWidth / media.Width), 0, image.PixelWidth - 1);
        var y = Math.Clamp((int)Math.Floor(point.Y * image.PixelHeight / media.Height), 0, image.PixelHeight - 1);
        var pixel = new byte[4];
        new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0).CopyPixels(new Int32Rect(x, y, 1, 1), pixel, 4, 0);
        int Flat(byte c) => (c * pixel[3] + 127) / 255;
        return $"#{Flat(pixel[2]):X2}{Flat(pixel[1]):X2}{Flat(pixel[0]):X2}";
    }
    // Baseline crop gesture: drag a new rectangle, drag one of eight handles, or drag
    // inside the draft to move it. Everything stays inside the current bounds.
    internal bool BeginCrop(Point screen)
    {
        if (Project.Media == null) return false; // 3.1.0: pictures and videos.
        var s = Source(screen); var bounds = View; var kind = "New";
        if (CropDraft is { } draft)
        {
            var hit = Handles(draft, RegionShape.Rectangle).FirstOrDefault(h => Math.Abs(h.Value.X - screen.X) <= 8 && Math.Abs(h.Value.Y - screen.Y) <= 8).Key;
            if (hit != null) kind = hit; else if (draft.Contains(s)) kind = "Move";
        }
        if (kind == "New" && !bounds.Contains(s)) return false;
        cropOriginal = CropDraft; cropStart = s;
        cropDraft = kind == "New" ? new MediaRect(s.X, s.Y, 0, 0) : CropDraft;
        cropKind = kind;
        CropDraftChanged?.Invoke(); InvalidateVisual();
        return true;
    }
    internal void DragCrop(Point screen)
    {
        if (cropKind == null) return;
        var b = View; var s = Source(screen);
        var x = Math.Clamp(s.X, b.X, b.X + b.Width); var y = Math.Clamp(s.Y, b.Y, b.Y + b.Height);
        if (cropKind == "Move" && cropOriginal is { } r)
        {
            var left = Math.Clamp(r.X + x - cropStart.X, b.X, b.X + b.Width - r.Width);
            var top = Math.Clamp(r.Y + y - cropStart.Y, b.Y, b.Y + b.Height - r.Height);
            cropDraft = r with { X = left, Y = top };
        }
        else
        {
            double left, top, right, bottom;
            if (cropKind == "New" || cropOriginal is not { } o) { left = cropStart.X; top = cropStart.Y; right = x; bottom = y; }
            else
            {
                left = o.X; top = o.Y; right = o.X + o.Width; bottom = o.Y + o.Height;
                if (cropKind.Contains('W')) left = x; if (cropKind.Contains('E')) right = x;
                if (cropKind.Contains('N')) top = y; if (cropKind.Contains('S')) bottom = y;
            }
            cropDraft = new MediaRect(Math.Min(left, right), Math.Min(top, bottom), Math.Abs(right - left), Math.Abs(bottom - top));
        }
        CropDraftChanged?.Invoke(); InvalidateVisual();
    }
    internal void EndCrop()
    {
        cropKind = null; cropOriginal = null;
        if (cropDraft is { } d && (d.Width < 1 || d.Height < 1)) cropDraft = null;
        CropDraftChanged?.Invoke(); InvalidateVisual();
    }
    private Cursor CropCursor(Point screen)
    {
        if (CropDraft is not { } draft) return Cursors.Cross;
        var hit = Handles(draft, RegionShape.Rectangle).FirstOrDefault(h => Math.Abs(h.Value.X - screen.X) <= 8 && Math.Abs(h.Value.Y - screen.Y) <= 8).Key;
        return hit switch
        {
            "NW" or "SE" => Cursors.SizeNWSE, "NE" or "SW" => Cursors.SizeNESW, "N" or "S" => Cursors.SizeNS, "E" or "W" => Cursors.SizeWE,
            _ => draft.Contains(Source(screen)) ? Cursors.SizeAll : Cursors.Cross
        };
    }
    public void CompletePolygon()
    {
        if (polygon.Count < 3 || Project.Media is not { } m) { polygon.Clear(); InvalidateVisual(); return; }
        var x = polygon.Min(p => p.X); var y = polygon.Min(p => p.Y);
        var w = polygon.Max(p => p.X) - x; var h = polygon.Max(p => p.Y) - y;
        if (w < 1 || h < 1) { polygon.Clear(); return; }
        BeforeEdit?.Invoke();
        var region = NewDrawingRegion(RegionShape.Polygon);
        region.Polygon = polygon.Select(p => new MediaPoint((p.X - x) / w, (p.Y - y) / h)).ToList();
        region.PutManual(Time, new(x, y, w, h)); Project.Regions.Add(region); Selected = region; polygon.Clear();
        SelectionChanged?.Invoke(region); Edited?.Invoke(); InvalidateVisual();
    }
    protected override void OnKeyDown(KeyEventArgs e)
    {
        if (e.Key == Key.Escape) { EyedropperActive = false; polygon.Clear(); if (Tool == "Crop") CropDraft = null; ClearMultiSelection(); InvalidateVisual(); }
        if (e.Key == Key.Enter) { if (Tool == "Crop") CropConfirmRequested?.Invoke(); else CompletePolygon(); }
        base.OnKeyDown(e);
    }
    internal Region NewDrawingRegion(RegionShape shape) => new()
    {
        Name = $"Region {Project.Regions.Count + 1}", Shape = shape, Start = Time, End = Project.Media?.Duration ?? 0,
        Effect = AllowVisualObscuration ? DrawingEffect : RedactionEffect.Opaque, Strength = DrawingStrength, Aggressive = DrawingAggressive, Color = DrawingColor,
        // Creation order shared with annotations: a later redaction covers earlier annotations.
        Order = AnnotationRules.NextOrder(Project)
    };
}
