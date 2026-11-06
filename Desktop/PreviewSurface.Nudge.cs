using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// 3.0.0 (David): the arrow keys nudge the selected redaction, annotation or group (1 pixel; Shift, 10 pixels),
// inside the picture. A press and its key repeats are one Undo step.
public partial class PreviewSurface
{
    private (List<Region> Regions, List<Annotation> Annotations) Targets()
    {
        if (HasMultiSelection) return (MultiRegions.Where(Project.Regions.Contains).Where(Active).ToList(), MultiAnnotations.Where(Project.Annotations.Contains).Where(Active).ToList());
        if (Selected is { } r && Project.Regions.Contains(r) && Active(r)) return ([r], []);
        if (SelectedAnnotation is { } a && Project.Annotations.Contains(a) && Active(a)) return ([], [a]);
        return ([], []);
    }
    // True when there was something to nudge (the key is then used, even at the picture's edge).
    internal bool Nudge(double dx, double dy, bool newStep)
    {
        if (Project.Media is not { } m || gesture != null || EditingText != null || Tool == "Crop" || EyedropperActive) return false;
        var (regions, annotations) = Targets();
        if (regions.Count + annotations.Count == 0) return false;
        if (m.IsVideo && CanEditFrame?.Invoke() == false) return true; // Pauses on the exact frame first.
        // The shapes stay inside the picture, limited by the one nearest each edge (never pushed further out).
        var boxes = regions.Select(r => r.GeometryAt(Time)).Concat(annotations.Select(a => a.UsesBox ? a.Box : a.Bounds())).ToList();
        dx = Math.Clamp(dx, Math.Min(0, -boxes.Min(b => b.X)), Math.Max(0, m.Width - boxes.Max(b => b.X + b.Width)));
        dy = Math.Clamp(dy, Math.Min(0, -boxes.Min(b => b.Y)), Math.Max(0, m.Height - boxes.Max(b => b.Y + b.Height)));
        if (dx == 0 && dy == 0) return true;
        if (newStep) BeforeEdit?.Invoke();
        foreach (var r in regions) { var b = r.GeometryAt(Time); r.PutManual(Time, b with { X = b.X + dx, Y = b.Y + dy }); }
        foreach (var a in annotations)
        {
            if (a.UsesBox) a.Box = a.Box with { X = a.Box.X + dx, Y = a.Box.Y + dy };
            else a.Points = a.Points.Select(v => new MediaPoint(v.X + dx, v.Y + dy)).ToList();
        }
        Edited?.Invoke(); InvalidateVisual();
        return true;
    }
}
