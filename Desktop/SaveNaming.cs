using System.IO;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// 3.3.0 (David): what a file is, for the suggested name when it is saved.
internal enum MediaOriginKind { Imported, Screenshot, Recording, Frame, Pasted, NewImage }
internal readonly record struct MediaOrigin(MediaOriginKind Kind, DateTime Time);

// Suggested file names (3.3.0, David): yyyyMMdd_HHmmss_SUFFIX.ext in local time.
//   REDACTED: the output has a Solid, Blur or Pixelate redaction (drawn, or already part of the picture after Flatten
//             or a Save), with or without other edits.
//   EDITED:   annotations or other edits (crop, resize, rotate, flip, trim, append) and no redaction.
//   Untouched: SCREENGRAB (screenshot), RECORDING (screen recording), FRAME (video frame), COPY (a file that was opened,
//             or a pasted picture, saved separately), IMAGE (a new canvas).
// Only what is in the output counts: undone redactions are gone, and a saved video frame counts only the redactions
// and annotations active on that frame. Untouched screenshots, recordings and frames carry the time they were taken;
// everything else the time it is saved. A name already in the folder gets _2, _3... before the extension.
internal static class SaveNaming
{
    public const string Redacted = "REDACTED", Edited = "EDITED", Screengrab = "SCREENGRAB", Recording = "RECORDING", Frame = "FRAME", Copy = "COPY", Image = "IMAGE";

    public static string Suffix(RedactionProject project, MediaOriginKind origin, FrameTimeline? map = null, double? frameTime = null)
    {
        // A redaction entirely outside the crop is not in the saved file.
        bool InCrop(Region r) => project.Crop is not { } c ||
            r.Keyframes.Select(k => k.Bounds).Append(r.GeometryAt(r.Start)).Any(b => b.X < c.X + c.Width && b.X + b.Width > c.X && b.Y < c.Y + c.Height && b.Y + b.Height > c.Y);
        bool RegionShown(Region r) => InCrop(r) && (frameTime is not { } t || map == null || map.IsActive(r, t));
        bool AnnotationShown(Annotation a) => frameTime is not { } t || map == null || map.IsActive(a, t);
        if (project.BakedRedaction || project.Regions.Any(RegionShown)) return Redacted;
        if (project.BakedEdit || project.Crop != null || project.Annotations.Any(AnnotationShown)) return Edited;
        return RawSuffix(origin);
    }
    public static string RawSuffix(MediaOriginKind origin) => origin switch
    {
        MediaOriginKind.Screenshot => Screengrab,
        MediaOriginKind.Recording => Recording,
        MediaOriginKind.Frame => Frame,
        MediaOriginKind.NewImage => Image,
        _ => Copy,
    };
    public static bool Untouched(string suffix) => suffix is not (Redacted or Edited);
    // Untouched screenshots, recordings and frames: when they were taken; everything else: now (when it is saved).
    public static DateTime TimeFor(string suffix, MediaOrigin origin, DateTime now) =>
        suffix is Screengrab or Recording or Frame && origin.Kind is MediaOriginKind.Screenshot or MediaOriginKind.Recording or MediaOriginKind.Frame ? origin.Time : now;

    public static string Suggest(string? folder, string suffix, DateTime time, string extension) => Unique(folder, $"{time:yyyyMMdd_HHmmss}_{suffix}", extension);
    // Save Project: yyyyMMdd_HHmmss.trtwpf.json.
    public static string SuggestProject(string? folder, DateTime time) => Unique(folder, $"{time:yyyyMMdd_HHmmss}", ProjectExtension);
    public const string ProjectExtension = ".trtwpf.json";
    internal static string Unique(string? folder, string stem, string extension)
    {
        var name = stem + extension;
        if (string.IsNullOrEmpty(folder) || !Directory.Exists(folder)) return name;
        for (var i = 2; File.Exists(Path.Combine(folder, name)); i++) name = $"{stem}_{i}{extension}";
        return name;
    }
}
