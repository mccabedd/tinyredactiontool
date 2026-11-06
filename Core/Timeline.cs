namespace TinyRedaction.Core;

public sealed record FrameStamp(long Pts, double Time, double Duration);
public sealed class FrameTimeline
{
    public IReadOnlyList<FrameStamp> Frames { get; }
    public double OriginTime { get; }
    public FrameTimeline(IEnumerable<FrameStamp> frames, double originTime = 0)
    {
        if (!double.IsFinite(originTime)) throw new InvalidDataException("Invalid source timestamp origin.");
        OriginTime = originTime;
        var array = frames.ToArray();
        if (array.Length == 0) throw new InvalidDataException("The file has no frames that this application can read.");
        for (var i = 0; i < array.Length; i++)
            if (!double.IsFinite(array[i].Time) || !double.IsFinite(array[i].Duration) || array[i].Duration <= 0 ||
                (i > 0 && (array[i].Time <= array[i - 1].Time || array[i].Pts <= array[i - 1].Pts)))
                throw new InvalidDataException("Frame identity is ambiguous.");
        Frames = array;
    }
    public int IndexAt(double seconds)
    {
        var lo = 0; var hi = Frames.Count - 1;
        while (lo < hi) { var mid = (lo + hi + 1) / 2; if (Frames[mid].Time <= seconds) lo = mid; else hi = mid - 1; }
        return lo;
    }
    public (int Start, int End) BufferedRange(double start, double end)
    { return (Math.Max(0, IndexAt(start) - 2), Math.Min(Frames.Count - 1, IndexAt(end) + 2)); }
    public bool IsActive(Region region, double time)
    { var range = BufferedRange(region.Start, region.End); var index = IndexAt(time); return index >= range.Start && index <= range.End; }
    // Annotations use exact inclusive frames, without the redaction safety buffer.
    public bool IsActive(Annotation annotation, double time)
    { var index = IndexAt(time); return index >= IndexAt(annotation.Start) && index <= IndexAt(annotation.End); }
}
public static class ExportGate
{
    public static void Check(RedactionProject project, ManagedPolicy policy)
    {
        ProjectStore.Validate(project);
        if (project.Regions.Count == 0 && project.Annotations.Count == 0 && project.Crop == null) throw new InvalidOperationException("Add a redaction, annotation or crop first.");
        // 0.14.0: David removed the separate tracking Review step, so followed ranges no longer block export.
        if (policy.DisableVisualObscuration && project.Regions.Any(r => r.Effect != RedactionEffect.Opaque)) throw new InvalidOperationException("Your organisation's policy does not allow Blur or Pixelate.");
        if (policy.DisableAudioRetention && project.Export.KeepAudio) throw new InvalidOperationException("Your organisation's policy does not allow keeping the sound.");
        if (policy.DisableSourceDeletion && project.Export.DeleteOriginal) throw new InvalidOperationException("Your organisation's policy does not allow deleting originals.");
    }
}
