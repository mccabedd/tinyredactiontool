using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Text, Line and Polyline annotation editing (baseline v2.5.1 behaviour, 0.9.0).
// - Line: drag; Shift snaps to 45°.  Text: drag a box, then type in the floating editor.
// - Polyline: one held-button drag drawing an axis-locked path; changing direction adds a corner.
// - A press outside accepts (deselects) the current object; drawing starts only once the
//   pointer moves, so a plain click never leaves a stray object.
public sealed partial class PreviewSurface
{
    public Annotation? SelectedAnnotation { get; set; }
    // Style for new annotations; the options bar edits this when nothing is selected.
    // 0.15.0 (David): new lines start 6 pixels wide with an arrowhead at the end (only Line and Polyline draw ends).
    public Annotation AnnotationStyle { get; } = new() { Width = 6, Ends = AnnotationEnds.ArrowEnd };
    public event Action<Annotation?>? AnnotationSelectionChanged;
    // Asks the window to open the floating text editor for a new draft or an existing Text.
    public event Action<Annotation>? TextEditRequested;
    // A click on the picture while the editor is open: confirm it (the click is consumed).
    public event Action? TextEditConfirmRequested;
    public Annotation? EditingText { get; private set; }
    // The editor's working copy (text and style), drawn live in place of EditingText.
    public Annotation? EditingPreview { get; private set; }
    // Outline drawings use their own tool names: "Rectangle" and "Oval" are the redaction tools.
    public static bool IsAnnotationTool(string tool) => tool is "Text" or "Line" or "Polyline" or "DrawRectangle" or "DrawOval" or "Freehand";
    public static AnnotationKind? AnnotationKindFor(string tool) => tool switch
    {
        "Text" => AnnotationKind.Text, "Line" => AnnotationKind.Line, "Polyline" => AnnotationKind.Polyline,
        "DrawRectangle" => AnnotationKind.Rectangle, "DrawOval" => AnnotationKind.Oval, "Freehand" => AnnotationKind.Freehand, _ => null
    };
    private const double FreehandSpacing = 2;
    private const double PolylineAxisThreshold = 8, HandleRadius = 8;
    private bool pendingAnnotation, annotationCheckpointed;
    private Annotation? creatingAnnotation, textDraft, annotationOriginal;
    private string? annotationHandle;
    private MediaPoint annotationStart;
    private readonly List<MediaPoint> polyVertices = [];
    private char polyAxis;
    private Point polySample;

    private bool Active(Annotation a) => Project.Media?.IsVideo != true || Timeline?.IsActive(a, Time) == true;
    internal Rect ScreenRect(MediaRect b) => Screen(b);
    internal bool IsShown(Annotation a) => Active(a);
    public void SelectAnnotation(Annotation? annotation)
    {
        if (annotation != null && Selected != null) { Selected = null; SelectionChanged?.Invoke(null); }
        if (SelectedAnnotation == annotation) return;
        SelectedAnnotation = annotation; AnnotationSelectionChanged?.Invoke(annotation); InvalidateVisual();
    }
    // Returns true when the press was handled as an annotation gesture.
    private bool AnnotationPointerDown(Point p, MediaPoint s, MouseButton button, int clickCount)
    {
        if (button != MouseButton.Left || Tool == "Polygon" && polygon.Count > 0) return false;
        var handleHit = SelectedAnnotation != null && Project.Annotations.Contains(SelectedAnnotation) && Active(SelectedAnnotation) ? AnnotationHandleAt(SelectedAnnotation, p) : null;
        var hit = handleHit != null ? SelectedAnnotation : Project.Annotations.Where(Active).OrderByDescending(a => a.Order).FirstOrDefault(a => HitAnnotation(a, p));
        // A redaction committed later sits on top; let it take the click.
        if (hit != null && handleHit == null && Project.Regions.Any(r => r.Order > hit.Order && Active(r) && ShapeGeometry(r, r.GeometryAt(Time)).FillContains(p))) hit = null;
        if (hit != null)
        {
            SelectAnnotation(hit);
            if (clickCount == 2 && hit.Kind == AnnotationKind.Text) { BeginTextEdit(hit); return true; }
            annotationHandle = handleHit ?? "Move"; annotationOriginal = Clone(hit); annotationStart = s; annotationCheckpointed = false;
            gesture = p; CaptureMouse(); InvalidateVisual(); return true;
        }
        if (IsAnnotationTool(Tool))
        {
            if (Selected != null) { Selected = null; SelectionChanged?.Invoke(null); }
            SelectAnnotation(null);
            pendingAnnotation = true; annotationStart = s; gesture = p; CaptureMouse(); InvalidateVisual(); return true;
        }
        SelectAnnotation(null);
        return false;
    }
    private bool AnnotationPointerMove(Point p, MediaReference m)
    {
        if (gesture is not { } start) return false;
        var s = ClampToMedia(Source(p), m);
        if (pendingAnnotation)
        {
            if ((p - start).Length < CreateThreshold) return true;
            pendingAnnotation = false; BeginAnnotation(m);
        }
        if (textDraft != null && EditingText == null)
        {
            textDraft.Box = new(Math.Min(annotationStart.X, s.X), Math.Min(annotationStart.Y, s.Y), Math.Abs(s.X - annotationStart.X), Math.Abs(s.Y - annotationStart.Y));
            InvalidateVisual(); return true;
        }
        if (creatingAnnotation is { Kind: AnnotationKind.Line } line)
        {
            line.Points[1] = Keyboard.Modifiers.HasFlag(ModifierKeys.Shift) ? Snap45(line.Points[0], s, m) : s;
            InvalidateVisual(); return true;
        }
        if (creatingAnnotation is { Kind: AnnotationKind.Polyline } polyline) { DragPolyline(polyline, p, s, start); InvalidateVisual(); return true; }
        if (creatingAnnotation is { Kind: AnnotationKind.Rectangle or AnnotationKind.Oval } shape)
        {
            // Shift draws a square or circle, as for redaction shapes.
            var dx = s.X - annotationStart.X; var dy = s.Y - annotationStart.Y;
            if (Keyboard.Modifiers.HasFlag(ModifierKeys.Shift)) { var side = Math.Min(Math.Abs(dx), Math.Abs(dy)); dx = Math.CopySign(side, dx); dy = Math.CopySign(side, dy); }
            var end = ClampToMedia(new(annotationStart.X + dx, annotationStart.Y + dy), m);
            shape.Box = new(Math.Min(annotationStart.X, end.X), Math.Min(annotationStart.Y, end.Y), Math.Abs(end.X - annotationStart.X), Math.Abs(end.Y - annotationStart.Y));
            InvalidateVisual(); return true;
        }
        if (creatingAnnotation is { Kind: AnnotationKind.Freehand } pen)
        {
            // A point every couple of screen pixels keeps the path smooth without thousands of points.
            if ((Screen(pen.Points[^1]) - p).Length >= FreehandSpacing) pen.Points.Add(s);
            InvalidateVisual(); return true;
        }
        if (annotationHandle == null || SelectedAnnotation is not { } a || annotationOriginal is not { } o) return false;
        if (!annotationCheckpointed) { BeforeEdit?.Invoke(); annotationCheckpointed = true; }
        if (annotationHandle == "Move")
        {
            a.Points = [.. o.Points]; a.Box = o.Box;
            a.Translate(s.X - annotationStart.X, s.Y - annotationStart.Y, m.Width, m.Height);
        }
        else if (IsTurnZone(annotationHandle))
        {
            var box = Screen(o.UsesBox ? o.Box : o.Bounds());
            var angle = TurnedBy(new(box.X + box.Width / 2, box.Y + box.Height / 2), start, p, o.UsesBox ? o.Rotation : 0, Keyboard.Modifiers.HasFlag(ModifierKeys.Shift));
            if (a.UsesBox) a.Rotation = angle;
            else
            {
                // Lines, polylines and pen drawings turn by moving their points about the centre of their bounds.
                var centre = ShapeTurn.Centre(o.Bounds());
                a.Points = o.Points.Select(v => ClampToMedia(ShapeTurn.Rotate(v, centre, angle), m)).ToList();
            }
        }
        else if (annotationHandle.StartsWith('P'))
        {
            var index = int.Parse(annotationHandle[1..], System.Globalization.CultureInfo.InvariantCulture);
            a.Points[index] = a.Kind == AnnotationKind.Line && Keyboard.Modifiers.HasFlag(ModifierKeys.Shift) ? Snap45(a.Points[1 - index], s, m) : s;
        }
        else
        {
            var b = o.Box; double left = b.X, top = b.Y, right = b.X + b.Width, bottom = b.Y + b.Height;
            // A turned box is resized in its own frame, keeping the opposite edge or corner where it was (0.19.0).
            var local = o.Rotation == 0 ? s : ShapeTurn.Rotate(s, ShapeTurn.Centre(b), -o.Rotation);
            if (annotationHandle.Contains('W')) left = Math.Min(right - 2, local.X); if (annotationHandle.Contains('E')) right = Math.Max(left + 2, local.X);
            if (annotationHandle.Contains('N')) top = Math.Min(bottom - 2, local.Y); if (annotationHandle.Contains('S')) bottom = Math.Max(top + 2, local.Y);
            // 0.26.0: a pasted picture keeps its shape from a corner (Shift stretches it freely).
            if (o.Kind == AnnotationKind.Picture && annotationHandle.Length == 2 && !Keyboard.Modifiers.HasFlag(ModifierKeys.Shift) && b.Width > 0 && b.Height > 0)
            {
                var ratio = b.Width / b.Height; var w = right - left; var h = bottom - top;
                if (w / h > ratio) h = w / ratio; else w = h * ratio; // Follows the larger change, as other editors do,
                var room = Math.Min(1, Math.Min((annotationHandle.Contains('W') ? right : m.Width - left) / w, (annotationHandle.Contains('N') ? bottom : m.Height - top) / h));
                w *= room; h *= room; // but stays inside the picture.
                if (annotationHandle.Contains('W')) left = right - w; else right = left + w;
                if (annotationHandle.Contains('N')) top = bottom - h; else bottom = top + h;
            }
            var box = new MediaRect(left, top, right - left, bottom - top);
            if (o.Rotation != 0)
            {
                var dragged = annotationHandle;
                MediaPoint Anchor(MediaRect r) => new(dragged.Contains('E') ? r.X : dragged.Contains('W') ? r.X + r.Width : r.X + r.Width / 2,
                                                      dragged.Contains('S') ? r.Y : dragged.Contains('N') ? r.Y + r.Height : r.Y + r.Height / 2);
                var before = ShapeTurn.Rotate(Anchor(b), ShapeTurn.Centre(b), o.Rotation); var after = ShapeTurn.Rotate(Anchor(box), ShapeTurn.Centre(box), o.Rotation);
                box = box with { X = Math.Clamp(box.X + before.X - after.X, 0, Math.Max(0, m.Width - box.Width)), Y = Math.Clamp(box.Y + before.Y - after.Y, 0, Math.Max(0, m.Height - box.Height)) };
            }
            a.Box = box;
        }
        InvalidateVisual(); return true;
    }
    private void AnnotationPointerUp()
    {
        pendingAnnotation = false;
        if (textDraft != null && EditingText == null)
        {
            // Baseline: a text box must be at least 2 × 2 media pixels.
            if (textDraft.Box.Width >= 2 && textDraft.Box.Height >= 2) BeginTextEdit(textDraft); else textDraft = null;
            InvalidateVisual();
        }
        if (creatingAnnotation is { } created)
        {
            if (created.Kind == AnnotationKind.Polyline) { created.Points = Deduplicate([.. polyVertices, created.Points[^1]]); polyVertices.Clear(); }
            if (created.Kind == AnnotationKind.Freehand) created.Points = Deduplicate(created.Points);
            var tooSmall = created.UsesBox ? created.Box.Width < 2 || created.Box.Height < 2 : created.Points.Count < 2 || created.Bounds() is var b && b.Width < 1 && b.Height < 1;
            if (tooSmall)
            { Project.Annotations.Remove(created); SelectAnnotation(null); }
            creatingAnnotation = null; Edited?.Invoke(); InvalidateVisual();
        }
        else if (annotationHandle != null)
        {
            annotationHandle = null; annotationOriginal = null;
            if (annotationCheckpointed) { annotationCheckpointed = false; Edited?.Invoke(); }
        }
    }
    private void BeginAnnotation(MediaReference m)
    {
        var kind = AnnotationKindFor(Tool) ?? AnnotationKind.Polyline;
        var a = new Annotation { Kind = kind }; a.CopyStyleFrom(AnnotationStyle);
        if (kind == AnnotationKind.Text) { a.Box = new(annotationStart.X, annotationStart.Y, 0, 0); textDraft = a; return; }
        BeforeEdit?.Invoke();
        if (a.UsesBox) a.Box = new(annotationStart.X, annotationStart.Y, 0, 0);
        else a.Points = kind == AnnotationKind.Freehand ? [annotationStart] : [annotationStart, annotationStart];
        if (kind == AnnotationKind.Polyline) { polyVertices.Clear(); polyVertices.Add(annotationStart); polyAxis = '\0'; polySample = gesture!.Value; }
        Commit(a, m);
        creatingAnnotation = a;
    }
    // Adds a finished annotation: next creation order; on video it starts at the shown frame
    // and runs to the last frame (Begin here / End here adjust it, exact frames, no buffer).
    private void Commit(Annotation a, MediaReference m)
    {
        a.Order = AnnotationRules.NextOrder(Project);
        if (m.IsVideo && Timeline != null) { a.Start = Timeline.Frames[Timeline.IndexAt(Time)].Time; a.End = Math.Max(a.Start, Timeline.Frames[^1].Time); }
        Project.Annotations.Add(a); SelectAnnotation(a);
    }
    private void DragPolyline(Annotation polyline, Point p, MediaPoint s, Point start)
    {
        var last = polyVertices[^1];
        if (polyAxis == '\0')
        {
            if ((p - start).Length < PolylineAxisThreshold) { polyline.Points = [last, last]; return; }
            var first = p - start; polyAxis = Math.Abs(first.X) >= Math.Abs(first.Y) ? 'H' : 'V'; polySample = p;
        }
        else if ((p - polySample).Length >= PolylineAxisThreshold)
        {
            var delta = p - polySample; var axis = Math.Abs(delta.X) >= Math.Abs(delta.Y) ? 'H' : 'V';
            if (axis != polyAxis)
            {
                // The corner is where the turn began: the last sample, on the old axis.
                var turn = Source(polySample);
                var corner = polyAxis == 'H' ? new MediaPoint(turn.X, last.Y) : new MediaPoint(last.X, turn.Y);
                corner = ClampToMedia(corner, Project.Media!);
                if (Distance(corner, last) >= 0.5) { polyVertices.Add(corner); last = corner; }
                polyAxis = axis;
            }
            polySample = p;
        }
        var end = polyAxis == 'H' ? new MediaPoint(s.X, last.Y) : new MediaPoint(last.X, s.Y);
        polyline.Points = [.. polyVertices, end];
    }
    private static List<MediaPoint> Deduplicate(List<MediaPoint> points)
    {
        var result = new List<MediaPoint>();
        foreach (var point in points) if (result.Count == 0 || Distance(result[^1], point) >= 0.5) result.Add(point);
        return result;
    }
    private static double Distance(MediaPoint a, MediaPoint b) => Math.Sqrt((a.X - b.X) * (a.X - b.X) + (a.Y - b.Y) * (a.Y - b.Y));
    private static MediaPoint ClampToMedia(MediaPoint p, MediaReference m) => new(Math.Clamp(p.X, 0, m.Width), Math.Clamp(p.Y, 0, m.Height));
    private static MediaPoint Snap45(MediaPoint from, MediaPoint to, MediaReference m)
    {
        var dx = to.X - from.X; var dy = to.Y - from.Y;
        var angle = Math.Round(Math.Atan2(dy, dx) / (Math.PI / 4)) * Math.PI / 4; var length = Math.Sqrt(dx * dx + dy * dy);
        return ClampToMedia(new(from.X + Math.Cos(angle) * length, from.Y + Math.Sin(angle) * length), m);
    }
    private static Annotation Clone(Annotation a)
    {
        var copy = new Annotation { Id = a.Id, Kind = a.Kind, Order = a.Order, Start = a.Start, End = a.End, Points = [.. a.Points], Box = a.Box, Text = a.Text, Rotation = a.Rotation, Picture = a.Picture };
        copy.CopyStyleFrom(a); return copy;
    }
    private bool HitAnnotation(Annotation a, Point p)
    {
        // A turned box is hit-tested in its own frame (0.19.0).
        if (a.UsesBox && a.Rotation != 0) { var box = Screen(a.Box); p = Turn(p, new(box.X + box.Width / 2, box.Y + box.Height / 2), -a.Rotation); }
        if (a.Kind is AnnotationKind.Text or AnnotationKind.Picture) return Screen(a.Box).Contains(p);
        var tolerance = Math.Max(7, a.Width * scale / 2 + 5);
        // Outlines are picked by their edge, so a redaction or drawing inside one stays reachable.
        if (a.Kind == AnnotationKind.Rectangle)
        {
            var r = Screen(a.Box); var outer = r; outer.Inflate(tolerance, tolerance);
            var inner = r; if (r.Width > 2 * tolerance && r.Height > 2 * tolerance) inner.Inflate(-tolerance, -tolerance); else inner = Rect.Empty;
            return outer.Contains(p) && !inner.Contains(p);
        }
        if (a.Kind == AnnotationKind.Oval)
        {
            var r = Screen(a.Box); var rx = Math.Max(0.5, r.Width / 2); var ry = Math.Max(0.5, r.Height / 2);
            var nx = (p.X - r.X - rx) / rx; var ny = (p.Y - r.Y - ry) / ry; var distance = Math.Sqrt(nx * nx + ny * ny);
            return Math.Abs(distance - 1) * Math.Min(rx, ry) <= tolerance;
        }
        var points = a.Points.Select(Screen).ToArray();
        for (var i = 1; i < points.Length; i++)
        {
            var segment = points[i] - points[i - 1]; var length = segment.LengthSquared;
            var t = length == 0 ? 0 : Math.Clamp(Vector.Multiply(p - points[i - 1], segment) / length, 0, 1);
            if ((p - (points[i - 1] + segment * t)).Length <= tolerance) return true;
        }
        return false;
    }
    private string? AnnotationHandleAt(Annotation a, Point p)
    {
        return AnnotationHandles(a).Where(h => (h.Value - p).Length <= ReachOf(h.Key, HandleRadius)).OrderBy(h => (h.Value - p).Length).Select(h => h.Key).FirstOrDefault();
    }
    // Box kinds: eight handles that turn with the box, and the rotate handle. Lines and polylines: a handle
    // on each point; every drawn kind (pen too) has the rotate handle above its bounds (0.19.0).
    private Dictionary<string, Point> AnnotationHandles(Annotation a)
    {
        if (a.UsesBox) return WithRotateHandle(Handles(a.Box, RegionShape.Rectangle), Screen(a.Box), a.Rotation);
        var handles = new Dictionary<string, Point>();
        if (a.Kind != AnnotationKind.Freehand) for (var i = 0; i < a.Points.Count; i++) handles["P" + i] = Screen(a.Points[i]);
        return WithRotateHandle(handles, Screen(a.Bounds()), 0);
    }
    // 0.26.0 (David): a picture pasted onto the picture, as a Picture annotation: its own size (smaller to fit), centred,
    // or at a set place; selected, ready to move and size. One Undo step. False on a video or with nothing open.
    public Annotation? AddPicture(System.Windows.Media.Imaging.BitmapSource picture, MediaPoint? centre = null)
    {
        if (Project.Media is not { IsVideo: false } m) return null;
        var data = AnnotationRenderer.PictureText(picture);
        if (data.Length > Annotation.MaxPictureCharacters) return null;
        double w = picture.PixelWidth, h = picture.PixelHeight, fit = Math.Min(1, Math.Min(m.Width / w, m.Height / h));
        w = Math.Max(1, w * fit); h = Math.Max(1, h * fit);
        var at = centre ?? new MediaPoint(m.Width / 2.0, m.Height / 2.0);
        var a = new Annotation { Kind = AnnotationKind.Picture, Picture = data, Box = new(Math.Clamp(at.X - w / 2, 0, m.Width - w), Math.Clamp(at.Y - h / 2, 0, m.Height - h), w, h) };
        BeforeEdit?.Invoke(); Commit(a, m); Edited?.Invoke(); InvalidateVisual();
        return a;
    }
    // Floating text editor protocol (MainWindow hosts the TextBox).
    public void BeginTextEdit(Annotation a) { EditingText = a; EditingPreview = Clone(a); InvalidateVisual(); TextEditRequested?.Invoke(a); }
    // Applies the editor's working copy: text and style together are one Undo step. Empty text
    // never commits: a new draft is discarded, an existing Text keeps its text (style still applies).
    // A new text also makes its style the default for the next one.
    public bool CommitTextEdit()
    {
        if (EditingText is not { } a || EditingPreview is not { } edited) return false;
        EditingText = null; EditingPreview = null;
        var changed = false; var blank = string.IsNullOrWhiteSpace(edited.Text);
        if (a == textDraft)
        {
            textDraft = null;
            if (!blank && Project.Media is { } m)
            { BeforeEdit?.Invoke(); a.Text = edited.Text; a.CopyStyleFrom(edited); AnnotationStyle.CopyStyleFrom(edited); Commit(a, m); changed = true; }
        }
        else if (Project.Annotations.Contains(a))
        {
            var text = blank ? a.Text : edited.Text;
            if (text != a.Text || !a.SameStyle(edited)) { BeforeEdit?.Invoke(); a.Text = text; a.CopyStyleFrom(edited); changed = true; }
        }
        if (changed) Edited?.Invoke();
        InvalidateVisual(); return changed;
    }
    // Esc: discard the working copy (a new draft is dropped; an existing text is unchanged).
    public void CancelTextEdit()
    {
        if (EditingText == textDraft) textDraft = null;
        EditingText = null; EditingPreview = null; InvalidateVisual();
    }
    // Drawn above redactions in creation order; a redaction committed later covers the annotation.
    private void DrawAnnotations(DrawingContext dc)
    {
        var ppd = VisualTreeHelper.GetDpi(this).PixelsPerDip;
        var regions = Project.Regions.Where(Active).ToArray();
        foreach (var a in Project.Annotations.Where(Active).OrderBy(a => a.Order))
        {
            var later = regions.Where(r => r.Order > a.Order).Select(CoverageGeometry).ToArray();
            if (later.Length > 0)
            {
                Geometry covered = later[0];
                foreach (var g in later.Skip(1)) covered = new CombinedGeometry(GeometryCombineMode.Union, covered, g);
                dc.PushClip(new CombinedGeometry(GeometryCombineMode.Exclude, new RectangleGeometry(new Rect(-1e5, -1e5, 2e5, 2e5)), covered));
            }
            AnnotationRenderer.Draw(dc, a == EditingText && EditingPreview != null ? EditingPreview : a, Screen, scale, ppd);
            if (later.Length > 0) dc.Pop();
        }
        var guide = new Pen(Brushes.DeepSkyBlue, 1) { DashStyle = DashStyles.Dash };
        if (textDraft != null)
        {
            dc.DrawRectangle(null, guide, Screen(textDraft.Box));
            if (EditingText == textDraft && EditingPreview != null) AnnotationRenderer.Draw(dc, EditingPreview, Screen, scale, ppd);
        }
        if (SelectedAnnotation is { } selected && Project.Annotations.Contains(selected) && Active(selected))
        {
            var handles = AnnotationHandles(selected);
            if (selected.UsesBox)
            {
                var box = Screen(selected.Box);
                if (selected.Rotation != 0) dc.PushTransform(new RotateTransform(selected.Rotation, box.X + box.Width / 2, box.Y + box.Height / 2));
                dc.DrawRectangle(null, guide, box);
                if (selected.Rotation != 0) dc.Pop();
                DrawHandles(dc, handles);
            }
            else
            {
                if (selected.Kind == AnnotationKind.Freehand) dc.DrawRectangle(null, guide, Screen(selected.Bounds()));
                // Hollow point handles (0.16.0): a white fill hid the line's last pixels and arrow tip, so the
                // line seemed to stop short of its end point. A dark and a light ring keep them visible.
                foreach (var point in handles.Where(h => !IsTurnZone(h.Key)))
                {
                    var at = point.Value;
                    dc.DrawRectangle(null, new Pen(Brushes.White, 3), new Rect(at.X - 4, at.Y - 4, 8, 8));
                    dc.DrawRectangle(null, new Pen(Brushes.DeepSkyBlue, 1), new Rect(at.X - 4, at.Y - 4, 8, 8));
                }
            }
        }
    }
    // Screen area a region covers in export, including its outward safety margin.
    private Geometry CoverageGeometry(Region r)
    {
        var geometry = ShapeGeometry(r, r.GeometryAt(Math.Clamp(Time, r.Start, r.End)));
        return new CombinedGeometry(GeometryCombineMode.Union, geometry, geometry.GetWidenedPathGeometry(new Pen(Brushes.Black, (1 + r.CoverageMargin) * scale * 2)));
    }
}
