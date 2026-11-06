using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace TinyRedaction.Desktop;

// Transparent pictures (0.22.1, David: a freehand capture is exactly its shape, with no background to remove
// elsewhere). Transparency is kept in TRT's own files, the editor and PNG export; the clipboard gets a PNG copy
// (kept by most picture editors) beside the usual picture, which is flattened on white, as is a JPG.
internal static class Transparency
{
    public static bool HasTransparency(BitmapSource image)
    {
        if (!image.Format.Equals(PixelFormats.Bgra32) && !image.Format.Equals(PixelFormats.Pbgra32) && !image.Format.Equals(PixelFormats.Prgba64) && !image.Format.Equals(PixelFormats.Rgba64)) return false;
        var bgra = image.Format.Equals(PixelFormats.Bgra32) ? image : new FormatConvertedBitmap(image, PixelFormats.Bgra32, null, 0);
        var pixels = new byte[bgra.PixelWidth * bgra.PixelHeight * 4]; bgra.CopyPixels(pixels, bgra.PixelWidth * 4, 0);
        for (var i = 3; i < pixels.Length; i += 4) if (pixels[i] < 255) return true;
        return false;
    }
    // The picture over a plain background, for formats and programs without transparency.
    public static BitmapSource Flatten(BitmapSource image, Color background)
    {
        var visual = new DrawingVisual();
        using (var dc = visual.RenderOpen())
        {
            var area = new Rect(0, 0, image.PixelWidth, image.PixelHeight);
            dc.DrawRectangle(new SolidColorBrush(background), null, area); dc.DrawImage(image, area);
        }
        var target = new RenderTargetBitmap(image.PixelWidth, image.PixelHeight, 96, 96, PixelFormats.Pbgra32); target.Render(visual);
        var flat = new FormatConvertedBitmap(target, PixelFormats.Bgr32, null, 0); flat.Freeze(); return flat;
    }
    public static byte[] Png(BitmapSource image)
    {
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(image));
        using var memory = new MemoryStream(); encoder.Save(memory); return memory.ToArray();
    }
    // What goes on the clipboard: the picture (flattened on white when it has transparency) and, then, a PNG.
    public static DataObject ClipboardData(BitmapSource image)
    {
        var data = new DataObject();
        if (HasTransparency(image)) { data.SetImage(Flatten(image, Colors.White)); data.SetData("PNG", new MemoryStream(Png(image)), false); }
        else data.SetImage(image);
        return data;
    }
    // A PNG on the clipboard (with its transparency), if there is one.
    public static BitmapSource? ClipboardPng()
    {
        if (!Clipboard.ContainsData("PNG") || Clipboard.GetData("PNG") is not MemoryStream stream) return null;
        stream.Position = 0;
        // 0.22.4: another program can put something that isn't a PNG under that name; then the ordinary picture is used.
        try
        {
            var decoder = new PngBitmapDecoder(stream, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
            var frame = decoder.Frames[0]; frame.Freeze(); return frame;
        }
        catch (Exception exception) when (exception is NotSupportedException or FileFormatException or ArgumentException) { return null; }
    }
    // The editor's checkerboard behind transparent parts (white and light grey, 8 screen pixels).
    public static readonly Brush Checkerboard = CreateCheckerboard();
    private static Brush CreateCheckerboard()
    {
        var size = ScreenCapture.CheckerSize;
        var brush = new DrawingBrush
        {
            TileMode = TileMode.Tile, Viewport = new Rect(0, 0, size * 2, size * 2), ViewportUnits = BrushMappingMode.Absolute, Stretch = Stretch.None,
            Drawing = new DrawingGroup
            {
                Children =
                {
                    new GeometryDrawing(new SolidColorBrush(ScreenCapture.CheckerLight), null, new RectangleGeometry(new Rect(0, 0, size * 2, size * 2))),
                    new GeometryDrawing(new SolidColorBrush(ScreenCapture.CheckerDark), null, new GeometryGroup { Children = { new RectangleGeometry(new Rect(size, 0, size, size)), new RectangleGeometry(new Rect(0, size, size, size)) } }),
                },
            },
        };
        brush.Freeze(); return brush;
    }
}
