using System.Text.Json;

namespace TinyRedaction.Core;

// 3.0.0 (David): layers. Redactions and annotations share one stack, bottom to top by Order (a redaction
// and an annotation with the same Order: the annotation is on top, as the renderers draw them). The Regions
// and Annotations lists each show their part of it, top first. Move Up takes an item above the next item of
// its own kind (and any of the other kind between them); with none of its kind above, to the very top.
// Whatever the order, a redaction always hides the picture under it: an annotation above a redaction is
// drawn over the redacted pixels, never the original ones.
public static class Layers
{
    // Every redaction and annotation, bottom first.
    public static List<object> Stack(RedactionProject p) =>
        p.Regions.Select((r, i) => (Item: (object)r, r.Order, Kind: 0, Index: i))
            .Concat(p.Annotations.Select((a, i) => (Item: (object)a, a.Order, Kind: 1, Index: i)))
            .OrderBy(x => x.Order).ThenBy(x => x.Kind).ThenBy(x => x.Index).Select(x => x.Item).ToList();
    // Gives the stack's items the orders 1, 2, 3 … and puts the redactions list in the same order (the
    // renderers apply redactions in list order).
    public static void Apply(RedactionProject p, List<object> stack)
    {
        for (var i = 0; i < stack.Count; i++)
            if (stack[i] is Region r) r.Order = i + 1; else ((Annotation)stack[i]).Order = i + 1;
        p.Regions = p.Regions.OrderBy(r => r.Order).ToList();
    }
    // The Regions list, top first.
    public static IReadOnlyList<Region> RegionsTopFirst(RedactionProject p) => Stack(p).OfType<Region>().Reverse().ToList();
    public static IReadOnlyList<Annotation> AnnotationsTopFirst(RedactionProject p) => Stack(p).OfType<Annotation>().Reverse().ToList();
    public static bool CanMove(RedactionProject p, object item, bool up)
    {
        var stack = Stack(p); var i = stack.IndexOf(item);
        return i >= 0 && (up ? i < stack.Count - 1 : i > 0);
    }
    // Returns what the item now sits above (moving up) or below (moving down), or null when it can't move.
    public static object? Move(RedactionProject p, object item, bool up)
    {
        var stack = Stack(p); var i = stack.IndexOf(item);
        if (i < 0 || (up ? i == stack.Count - 1 : i == 0)) return null;
        var kind = item.GetType();
        var j = up ? stack.FindIndex(i + 1, x => x.GetType() == kind) : stack.FindLastIndex(i - 1, x => x.GetType() == kind);
        var passed = j >= 0 ? stack[j] : up ? stack[^1] : stack[0];
        stack.RemoveAt(i);
        if (j < 0) { if (up) stack.Add(item); else stack.Insert(0, item); }
        else stack.Insert(j, item); // Up: the removal moved that item down one, so j is just above it; down: just below it.
        Apply(p, stack);
        return passed;
    }
    // A copy with a new identity, on top of everything.
    public static Region Copy(RedactionProject p, Region r)
    {
        var copy = JsonSerializer.Deserialize<Region>(JsonSerializer.Serialize(r, ProjectStore.Json), ProjectStore.Json)!;
        copy.Id = Guid.NewGuid(); copy.Name = r.Name + " Copy"; copy.Order = AnnotationRules.NextOrder(p);
        return copy;
    }
    public static Annotation Copy(RedactionProject p, Annotation a)
    {
        var copy = JsonSerializer.Deserialize<Annotation>(JsonSerializer.Serialize(a, ProjectStore.Json), ProjectStore.Json)!;
        copy.Id = Guid.NewGuid(); copy.Order = AnnotationRules.NextOrder(p);
        return copy;
    }
    // How far a copy moves so it can be seen: 10 pixels right and down, or back the other way at the
    // picture's edge, never outside it. boxes: every place the shape takes (a video redaction's keyframes).
    public static (double X, double Y) CopyOffset(IReadOnlyList<MediaRect> boxes, double width, double height, double step = 10)
    {
        double Pick(double low, double high) => step <= high ? step : -step >= low ? -step : Math.Clamp(step, Math.Min(0, low), Math.Max(0, high));
        return (Pick(-boxes.Min(b => b.X), width - boxes.Max(b => b.X + b.Width)), Pick(-boxes.Min(b => b.Y), height - boxes.Max(b => b.Y + b.Height)));
    }
}
