namespace TinyRedaction.Core;

// Fixed appearance, local translation/scale search with zero-mean normalized
// correlation. The correlation is a diagnostic, NOT an identity confidence score.
public sealed class AppearanceTracker
{
    private const int Grid = 16;
    private readonly double[] template = new double[Grid * Grid];
    private MediaRect bounds;
    public string? Failure { get; private set; }
    public MediaRect Bounds => bounds;
    public bool Seed(byte[] gray, int width, int height, MediaRect selection)
    {
        bounds = selection;
        if (selection.Width < 6 || selection.Height < 6) { Failure = "Selection is too small at analysis resolution."; return false; }
        var samples = Sample(gray, width, height, selection);
        var mean = samples.Average(); var norm = Math.Sqrt(samples.Sum(v => (v - mean) * (v - mean)));
        if (norm / Math.Sqrt(samples.Length) < 5) { Failure = "Selection lacks stable texture; choose a clearer, larger region."; return false; }
        for (var i = 0; i < template.Length; i++) template[i] = (samples[i] - mean) / norm;
        Failure = null; return true;
    }
    public bool Advance(byte[] gray, int width, int height, CancellationToken cancellation = default)
    {
        if (Failure != null) return false;
        var candidates = new List<(MediaRect Bounds, double Score)>();
        var radius = Math.Max(8, Math.Min(24, Math.Max(bounds.Width, bounds.Height) * 0.6));
        const int step = 1;
        var gridRadius = (int)(radius / step) * step;
        var sampleBuffer = new double[Grid * Grid];
        foreach (var scale in new[] { 0.9, 0.95, 1d, 1.05, 1.1 })
        {
            var w = Math.Round(bounds.Width * scale); var h = Math.Round(bounds.Height * scale);
            for (var dy = -gridRadius; dy <= gridRadius; dy += step)
            {
                cancellation.ThrowIfCancellationRequested();
                for (var dx = -gridRadius; dx <= gridRadius; dx += step)
                {
                    var b = new MediaRect(Math.Round(bounds.X + (bounds.Width - w) / 2) + dx, Math.Round(bounds.Y + (bounds.Height - h) / 2) + dy, w, h);
                    if (b.X < 0 || b.Y < 0 || b.X + w > width || b.Y + h > height || w < 6 || h < 6) continue;
                    var samples = Sample(gray, width, height, b, sampleBuffer);
                    var sum = 0d; var squared = 0d; var dot = 0d;
                    for (var i = 0; i < samples.Length; i++) { var v = samples[i]; sum += v; squared += v * v; dot += v * template[i]; }
                    var norm = Math.Sqrt(Math.Max(0, squared - sum * sum / samples.Length));
                    if (norm > 0.001) candidates.Add((b, dot / norm));
                }
            }
        }
        if (candidates.Count == 0) { Failure = "No valid in-frame candidate; subject may have exited."; return false; }
        var best = candidates.MaxBy(c => c.Score);
        if (best.Score < 0.80) { Failure = "Selected appearance no longer matches; possible drift, occlusion or subject exit."; return false; }
        var separation = Math.Min(bounds.Width, bounds.Height) * 0.6;
        var competing = candidates.Where(c => Math.Abs(c.Bounds.X - best.Bounds.X) + Math.Abs(c.Bounds.Y - best.Bounds.Y) > separation).Select(c => c.Score).DefaultIfEmpty(-1).Max();
        if (best.Score - competing < 0.06) { Failure = "Multiple distinct positions match similarly; subject identity is ambiguous."; return false; }
        bounds = best.Bounds; return true;
    }
    private static double[] Sample(byte[] pixels, int width, int height, MediaRect b, double[]? buffer = null)
    {
        if (pixels.Length != checked(width * height)) throw new InvalidDataException("Invalid analysis frame.");
        var values = buffer ?? new double[Grid * Grid];
        for (var y = 0; y < Grid; y++) for (var x = 0; x < Grid; x++)
        {
            var px = Math.Clamp(b.X + (x + 0.5) * b.Width / Grid - 0.5, 0, width - 1);
            var py = Math.Clamp(b.Y + (y + 0.5) * b.Height / Grid - 0.5, 0, height - 1);
            var sx = (int)px; var sy = (int)py; var nx = Math.Min(width - 1, sx + 1); var ny = Math.Min(height - 1, sy + 1);
            var fx = px - sx; var fy = py - sy;
            values[y * Grid + x] = (pixels[sy * width + sx] * (1 - fx) + pixels[sy * width + nx] * fx) * (1 - fy) +
                (pixels[ny * width + sx] * (1 - fx) + pixels[ny * width + nx] * fx) * fy;
        }
        return values;
    }
}
