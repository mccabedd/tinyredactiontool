namespace TinyRedaction.Core;

// Still-image crop geometry (inherited "Crop Image" tool): whole source pixels,
// always inside the current bounds (the image, or an already confirmed crop).
public static class ImageCrop
{
    public static bool IsPixelRect(MediaRect r) =>
        double.IsFinite(r.X) && double.IsFinite(r.Y) && double.IsFinite(r.Width) && double.IsFinite(r.Height) &&
        r.X == Math.Floor(r.X) && r.Y == Math.Floor(r.Y) && r.Width == Math.Floor(r.Width) && r.Height == Math.Floor(r.Height);
    // Baseline Get-CropPixelRectangle: expand the draft outward to whole pixels and
    // intersect with the bounds. Null when nothing remains.
    // Screen-to-source conversion can leave 69.9999999 for an exact pixel edge; values
    // within 1e-6 of a whole pixel are treated as that pixel so the crop does not grow.
    public static MediaRect? PixelRect(MediaRect draft, MediaRect bounds)
    {
        static double Snap(double v) => Math.Abs(v - Math.Round(v)) < 1e-6 ? Math.Round(v) : v;
        var left = Math.Max(Math.Floor(Snap(bounds.X)), Math.Floor(Snap(draft.X)));
        var top = Math.Max(Math.Floor(Snap(bounds.Y)), Math.Floor(Snap(draft.Y)));
        var right = Math.Min(Math.Ceiling(Snap(bounds.X + bounds.Width)), Math.Ceiling(Snap(draft.X + draft.Width)));
        var bottom = Math.Min(Math.Ceiling(Snap(bounds.Y + bounds.Height)), Math.Ceiling(Snap(draft.Y + draft.Height)));
        return right <= left || bottom <= top ? null : new MediaRect(left, top, right - left, bottom - top);
    }
    public static MediaRect Bounds(RedactionProject project) =>
        project.Crop ?? (project.Media is { } m ? new MediaRect(0, 0, m.Width, m.Height) : default);
    // Copies the crop rectangle out of a full-size BGRA buffer.
    public static byte[] CropBgra(byte[] pixels, int width, int height, MediaRect crop)
    {
        if (!IsPixelRect(crop) || crop.X < 0 || crop.Y < 0 || crop.X + crop.Width > width || crop.Y + crop.Height > height)
            throw new InvalidDataException("Invalid image crop.");
        int x = (int)crop.X, y = (int)crop.Y, w = (int)crop.Width, h = (int)crop.Height;
        var result = new byte[checked(w * h * 4)];
        for (var row = 0; row < h; row++) Buffer.BlockCopy(pixels, ((y + row) * width + x) * 4, result, row * w * 4, w * 4);
        return result;
    }
    public static bool[] CropMask(bool[] mask, int width, MediaRect crop)
    {
        int x = (int)crop.X, y = (int)crop.Y, w = (int)crop.Width, h = (int)crop.Height;
        var result = new bool[w * h];
        for (var row = 0; row < h; row++) Array.Copy(mask, (y + row) * width + x, result, row * w, w);
        return result;
    }
}
