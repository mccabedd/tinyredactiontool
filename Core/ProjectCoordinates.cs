namespace TinyRedaction.Core;
public static class ProjectCoordinates
{
    public static void UpgradeLegacy(RedactionProject project, int displayWidth, int displayHeight)
    {
        if (project.CoordinateSpace != "legacy-autorotated-pixels") return;
        var media = project.Media ?? throw new InvalidDataException("Source reference missing.");
        var sx = displayWidth / (double)media.Width; var sy = displayHeight / (double)media.Height;
        foreach (var region in project.Regions)
        {
            region.Keyframes = region.Keyframes.Select(k => k with { Bounds = new(k.Bounds.X * sx, k.Bounds.Y * sy, k.Bounds.Width * sx, k.Bounds.Height * sy) }).ToList();
            region.CoverageMargin *= Math.Max(sx, sy);
            if (region.CoverageMargin > 1000) throw new InvalidDataException("Coverage margin exceeds the supported range after coordinate upgrade; loading was blocked.");
            if (sx != 1 || sy != 1)
                region.Tracking = region.Tracking.Select(s => s.State == ReviewState.Reviewed ? s with { State = ReviewState.Unreviewed, Reason = "Pixel aspect coordinates were upgraded; review coverage again." } : s).ToList();
        }
        project.Media = media with { Width = displayWidth, Height = displayHeight };
        project.CoordinateSpace = "autorotated-square-pixels-v1";
        ProjectStore.Validate(project);
    }
}
