using System.IO;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace TinyRedaction.Desktop;

// TRT's own cursors (open hand for Pan, closed hand while panning, eyedropper), drawn as
// vectors and packed into a standard 32×32 32-bit .cur in memory. No external assets.
public static class CustomCursors
{
    private static Cursor? openHand, closedHand, eyedropper;
    public static Cursor OpenHand => openHand ??= Hand(false);
    public static Cursor ClosedHand => closedHand ??= Hand(true);
    public static Cursor Eyedropper => eyedropper ??= Create(dc =>
    {
        var body = Geometry.Parse("M17,11 L7,21 L5.5,25.5 L10,24 L20,14 Z M15.5,9 L22,15.5 M18,6 A4,4 0 1 1 25,13 L22,16 L15,9 Z");
        dc.DrawGeometry(Brushes.White, new Pen(Brushes.Black, 1.3) { LineJoin = PenLineJoin.Round }, body);
    }, 5, 26);
    // Resize arrows for the eight handles (N/S, E/W and the two diagonals).
    public static Cursor Resize(string handle) => handle switch
    {
        "NW" or "SE" => Cursors.SizeNWSE, "NE" or "SW" => Cursors.SizeNESW, "N" or "S" => Cursors.SizeNS, _ => Cursors.SizeWE
    };
    // 0.19.0: on a turned shape, the arrows follow the turn (the handle's direction rounded to 45°).
    public static Cursor Resize(string handle, double rotation)
    {
        var baseAngle = handle switch { "E" => 0, "SE" => 45, "S" => 90, "SW" => 135, "W" => 180, "NW" => 225, "N" => 270, _ => 315 };
        var step = (int)Math.Round(((baseAngle + rotation) % 180 + 180) % 180 / 45) % 4;
        return step switch { 0 => Cursors.SizeWE, 1 => Cursors.SizeNWSE, 2 => Cursors.SizeNS, _ => Cursors.SizeNESW };
    }
    // The turning cursor shown just outside a selected shape's corners (0.21.0): a curved
    // arrow with a head at each end, TRT's own drawing. 0.21.1 (David): one per corner, the curve bending
    // round that corner (top-left, top-right, bottom-right, bottom-left), and following a turned shape.
    private static readonly Cursor?[] rotate = new Cursor?[4];
    private static Cursor RotateQuarter(int quarter) => rotate[quarter] ??= Create(dc =>
    {
        dc.PushTransform(new RotateTransform(quarter * 90, 15, 15));
        var arc = Geometry.Parse("M7,22 A15,15 0 0 1 22,7");
        dc.DrawGeometry(null, new Pen(Brushes.White, 4.4) { StartLineCap = PenLineCap.Flat, EndLineCap = PenLineCap.Flat }, arc);
        dc.DrawGeometry(null, new Pen(Brushes.Black, 2) { StartLineCap = PenLineCap.Flat, EndLineCap = PenLineCap.Flat }, arc);
        var heads = Geometry.Parse("M2.5,20 L11.5,20 L7,27.5 Z M20,2.5 L20,11.5 L27.5,7 Z");
        dc.DrawGeometry(Brushes.Black, new Pen(Brushes.White, 1.2) { LineJoin = PenLineJoin.Round }, heads);
        dc.Pop();
    }, 15, 15);
    // The top-left one (kept for callers that need any turning cursor).
    public static Cursor Rotate => RotateQuarter(0);
    // For a turning zone ("RNW", "RNE", "RSE", "RSW") of a shape turned by rotation degrees.
    public static Cursor RotateAt(string zone, double rotation)
    {
        var corner = zone switch { "RNE" => 1, "RSE" => 2, "RSW" => 3, _ => 0 };
        var quarter = ((corner + (int)Math.Round(rotation / 90)) % 4 + 4) % 4;
        return RotateQuarter(quarter);
    }
    public static bool IsRotate(Cursor? cursor) => cursor != null && Array.IndexOf(rotate, cursor) >= 0;
    private static Cursor Hand(bool closed)
    {
        return Create(dc =>
        {
            Geometry shape = new RectangleGeometry(new Rect(9, 13, 15.5, 14), 4.5, 4.5);
            var tops = closed ? new[] { 11.5, 10.5, 11, 12 } : new[] { 6.5, 4.5, 5, 7.5 };
            for (var i = 0; i < 4; i++)
                shape = new CombinedGeometry(GeometryCombineMode.Union, shape, new RectangleGeometry(new Rect(9 + i * 3.9, tops[i], 3.6, 18 - tops[i]), 1.8, 1.8));
            var thumb = new RectangleGeometry(new Rect(4.5, closed ? 16 : 14, 3.6, closed ? 7 : 10), 1.8, 1.8) { Transform = new RotateTransform(closed ? -20 : -38, 6.3, 21) };
            shape = new CombinedGeometry(GeometryCombineMode.Union, shape, thumb);
            dc.DrawGeometry(Brushes.White, new Pen(Brushes.Black, 1.2) { LineJoin = PenLineJoin.Round }, shape);
            for (var i = 1; i < 4; i++) dc.DrawLine(new Pen(Brushes.Black, 0.8), new Point(9 + i * 3.9 - 0.15, closed ? 14 : 13), new Point(9 + i * 3.9 - 0.15, 17));
        }, 16, 16);
    }
    private static Cursor Create(Action<DrawingContext> draw, int hotX, int hotY)
    {
        const int size = 32;
        var visual = new DrawingVisual();
        using (var dc = visual.RenderOpen()) draw(dc);
        var bitmap = new RenderTargetBitmap(size, size, 96, 96, PixelFormats.Pbgra32); bitmap.Render(visual);
        var pixels = new byte[size * size * 4]; bitmap.CopyPixels(pixels, size * 4, 0);
        // Un-premultiply for the straight-alpha DIB that cursors use.
        for (var i = 0; i < pixels.Length; i += 4)
            if (pixels[i + 3] is > 0 and < 255) for (var c = 0; c < 3; c++) pixels[i + c] = (byte)Math.Min(255, pixels[i + c] * 255 / pixels[i + 3]);
        using var stream = new MemoryStream(); using var w = new BinaryWriter(stream);
        const int maskStride = 4, imageBytes = 40 + size * size * 4 + size * maskStride;
        w.Write((short)0); w.Write((short)2); w.Write((short)1);                       // ICONDIR: cursor, one image
        w.Write((byte)size); w.Write((byte)size); w.Write((byte)0); w.Write((byte)0);   // ICONDIRENTRY
        w.Write((short)hotX); w.Write((short)hotY); w.Write(imageBytes); w.Write(6 + 16);
        w.Write(40); w.Write(size); w.Write(size * 2); w.Write((short)1); w.Write((short)32); // BITMAPINFOHEADER (height includes mask)
        w.Write(0); w.Write(size * size * 4); w.Write(0); w.Write(0); w.Write(0); w.Write(0);
        for (var y = size - 1; y >= 0; y--) w.Write(pixels, y * size * 4, size * 4);      // bottom-up colour rows
        w.Write(new byte[size * maskStride]);                                              // AND mask: alpha decides
        w.Flush(); stream.Position = 0;
        return new Cursor(stream);
    }
}
