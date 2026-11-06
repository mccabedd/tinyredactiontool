using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Marching-ants selection (0.19.0, David): with Select, drag on an empty part of the picture to draw a
// dashed box; every redaction and annotation it touches is selected (0.22.0; before, only those wholly inside). Drag any of them to move
// them together; Delete removes them; Edit › Transform turns or flips them as a group.
public partial class PreviewSurface
{
    public List<Region> MultiRegions { get; } = [];
    public List<Annotation> MultiAnnotations { get; } = [];
    internal bool HasMultiSelection => MultiRegions.Count + MultiAnnotations.Count > 1;
    private MediaPoint? marqueeStart, marqueeEnd;
    private bool groupMoving;
    private List<(Region Region, MediaRect Bounds)> groupRegions = [];
    private List<(Annotation Annotation, MediaRect Box, List<MediaPoint> Points)> groupAnnotations = [];
    private readonly DispatcherTimer ants = new() { Interval = TimeSpan.FromMilliseconds(120) };
    private double antsOffset;
    public event Action? MultiSelectionChanged;
    // With Select, a click on the picture away from every shape when nothing was selected (0.28.0: animated GIFs).
    public event Action? PictureClicked;
    private bool selectionBeforePress;

    internal void ClearMultiSelection()
    {
        if (MultiRegions.Count + MultiAnnotations.Count == 0 && marqueeStart == null) return;
        MultiRegions.Clear(); MultiAnnotations.Clear(); marqueeStart = marqueeEnd = null; ants.Stop();
        MultiSelectionChanged?.Invoke(); InvalidateVisual();
    }
    // Selects exactly these shapes (checks use this; the marquee ends here too).
    internal void SelectShapes(IEnumerable<Region> regions, IEnumerable<Annotation> annotations)
    {
        MultiRegions.Clear(); MultiAnnotations.Clear();
        MultiRegions.AddRange(regions); MultiAnnotations.AddRange(annotations);
        if (MultiRegions.Count + MultiAnnotations.Count == 1)
        {
            // One shape: the ordinary single selection, with its handles and popup.
            var region = MultiRegions.FirstOrDefault(); var annotation = MultiAnnotations.FirstOrDefault();
            MultiRegions.Clear(); MultiAnnotations.Clear(); ants.Stop();
            if (region != null) { SelectAnnotation(null); Selected = region; SelectionChanged?.Invoke(region); }
            else SelectAnnotation(annotation);
        }
        else if (HasMultiSelection)
        {
            Selected = null; SelectionChanged?.Invoke(null); SelectAnnotation(null);
            EnsureAnts();
        }
        MultiSelectionChanged?.Invoke(); InvalidateVisual();
    }
    private void EnsureAnts()
    {
        if (ants.IsEnabled) return;
        ants.Tick -= MarchAnts; ants.Tick += MarchAnts; ants.Start();
    }
    private void MarchAnts(object? sender, EventArgs e)
    {
        if (marqueeStart == null && !HasMultiSelection) { ants.Stop(); return; }
        antsOffset = (antsOffset + 1) % 8; InvalidateVisual();
    }
    private MediaRect ShapeExtent(Region r) => ShapeTurn.Extent(r.GeometryAt(Math.Clamp(Time, r.Start, r.End)), r.Rotation);
    private static MediaRect ShapeExtent(Annotation a) => a.UsesBox ? ShapeTurn.Extent(a.Box, a.Rotation) : a.Bounds();

    // Called from the pointer handlers. True when the marquee or a group move took the press.
    private bool MarqueePointerDown(Point p, MediaPoint s, MouseButton button)
    {
        if (button != MouseButton.Left) return false;
        if (HasMultiSelection)
        {
            var onMember = MultiRegions.Any(r => Active(r) && ShapeGeometry(r, r.GeometryAt(Time)).FillContains(p)) || MultiAnnotations.Any(a => Active(a) && HitAnnotation(a, p));
            if (onMember)
            {
                BeforeEdit?.Invoke(); editing = true; groupMoving = true;
                groupRegions = MultiRegions.Select(r => (r, r.GeometryAt(Time))).ToList();
                groupAnnotations = MultiAnnotations.Select(a => (a, a.Box, a.Points.ToList())).ToList();
                gesture = p; sourceStart = s; CaptureMouse(); return true;
            }
            ClearMultiSelection();
        }
        return false;
    }
    // With Select, a press on empty picture starts the dashed box.
    private bool BeginMarquee(Point p, MediaPoint s)
    {
        if (Tool != "Select") return false;
        marqueeStart = marqueeEnd = s; gesture = p; CaptureMouse(); EnsureAnts(); InvalidateVisual(); return true;
    }
    private bool MarqueePointerMove(MediaPoint s, MediaReference m)
    {
        if (marqueeStart != null) { marqueeEnd = ClampToMedia(s, m); InvalidateVisual(); return true; }
        if (!groupMoving) return false;
        var dx = s.X - sourceStart.X; var dy = s.Y - sourceStart.Y;
        // The group stays inside the picture: the move is limited by the shape nearest each edge.
        var extents = groupRegions.Select(g => ShapeTurn.Extent(g.Bounds, g.Region.Rotation))
            .Concat(groupAnnotations.Select(g => g.Annotation.UsesBox ? ShapeTurn.Extent(g.Box, g.Annotation.Rotation) : Bounds(g.Points))).ToList();
        dx = Math.Clamp(dx, -extents.Min(b => b.X), m.Width - extents.Max(b => b.X + b.Width));
        dy = Math.Clamp(dy, -extents.Min(b => b.Y), m.Height - extents.Max(b => b.Y + b.Height));
        foreach (var (region, bounds) in groupRegions) region.PutManual(Time, (bounds with { X = bounds.X + dx, Y = bounds.Y + dy }).Clamp(m.Width, m.Height));
        foreach (var (annotation, box, points) in groupAnnotations)
        {
            if (annotation.UsesBox) annotation.Box = box with { X = box.X + dx, Y = box.Y + dy };
            else annotation.Points = points.Select(v => new MediaPoint(v.X + dx, v.Y + dy)).ToList();
        }
        InvalidateVisual(); return true;
    }
    private static MediaRect Bounds(List<MediaPoint> points)
    {
        var x = points.Min(v => v.X); var y = points.Min(v => v.Y);
        return new(x, y, points.Max(v => v.X) - x, points.Max(v => v.Y) - y);
    }
    private void MarqueePointerUp()
    {
        if (groupMoving) { groupMoving = false; groupRegions = []; groupAnnotations = []; return; }
        if (marqueeStart is not { } a || marqueeEnd is not { } b) return;
        marqueeStart = marqueeEnd = null;
        var box = new MediaRect(Math.Min(a.X, b.X), Math.Min(a.Y, b.Y), Math.Abs(b.X - a.X), Math.Abs(b.Y - a.Y));
        // 0.22.0 (David): a shape the box touches is selected, not only one wholly inside it.
        bool Touches(MediaRect r) => r.X <= box.X + box.Width && r.X + r.Width >= box.X && r.Y <= box.Y + box.Height && r.Y + r.Height >= box.Y;
        // 0.28.0 (David): a plain click on the picture (not one that only put a selection away) plays or pauses an animated GIF.
        if (box.Width < 2 || box.Height < 2) { SelectShapes([], []); if (!selectionBeforePress) PictureClicked?.Invoke(); return; }
        SelectShapes(Project.Regions.Where(r => Active(r) && Touches(ShapeExtent(r))), Project.Annotations.Where(x => Active(x) && Touches(ShapeExtent(x))));
    }
    private void DrawMarquee(DrawingContext dc)
    {
        var black = new Pen(Brushes.Black, 1); var white = new Pen(Brushes.White, 1) { DashStyle = new DashStyle([4, 4], antsOffset) };
        void Ants(Rect r) { dc.DrawRectangle(null, black, r); dc.DrawRectangle(null, white, r); }
        if (marqueeStart is { } a && marqueeEnd is { } b)
            Ants(Screen(new MediaRect(Math.Min(a.X, b.X), Math.Min(a.Y, b.Y), Math.Abs(b.X - a.X), Math.Abs(b.Y - a.Y))));
        if (!HasMultiSelection) return;
        foreach (var r in MultiRegions.Where(Project.Regions.Contains).Where(Active)) Ants(Screen(ShapeExtent(r)));
        foreach (var x in MultiAnnotations.Where(Project.Annotations.Contains).Where(Active)) Ants(Screen(ShapeExtent(x)));
    }
}
