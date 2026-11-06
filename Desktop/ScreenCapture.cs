using System.Runtime.InteropServices;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Drawing = System.Drawing;
using DrawingImaging = System.Drawing.Imaging;

namespace TinyRedaction.Desktop;

// Screen capture (0.12.0) in real screen pixels. TRT's windows are system-DPI aware, so with monitors
// at different scaling Windows would otherwise report stretched coordinates; every grab, monitor
// query and selection overlay runs under per-monitor DPI awareness instead (the inherited v2.5.1 way).
internal static class ScreenCapture
{
    // Windows the user can pick in Window / Object mode: a top-level window and the controls inside it.
    internal sealed record WindowTarget(IntPtr Handle, Drawing.Rectangle Bounds, IReadOnlyList<Drawing.Rectangle> Objects);

    internal sealed class DpiScope : IDisposable
    {
        private readonly IntPtr previous;
        public DpiScope() { try { previous = SetThreadDpiAwarenessContext(new IntPtr(-4)); } catch (EntryPointNotFoundException) { } }
        public void Dispose() { if (previous != IntPtr.Zero) SetThreadDpiAwarenessContext(previous); }
    }

    public static Drawing.Rectangle VirtualScreen
    {
        get { using var dpi = new DpiScope(); return new(GetSystemMetrics(76), GetSystemMetrics(77), GetSystemMetrics(78), GetSystemMetrics(79)); }
    }
    public static Drawing.Point CursorPosition { get { using var dpi = new DpiScope(); return GetCursorPos(out var p) ? new(p.X, p.Y) : default; } }
    // The whole monitor at a point, or its work area (without the taskbar).
    public static Drawing.Rectangle MonitorAt(Drawing.Point point, bool workArea = false)
    {
        using var dpi = new DpiScope();
        var monitor = MonitorFromPoint(new POINT { X = point.X, Y = point.Y }, 2);
        var info = new MONITORINFO { cbSize = Marshal.SizeOf<MONITORINFO>() };
        if (!GetMonitorInfo(monitor, ref info)) return VirtualScreen;
        var r = workArea ? info.rcWork : info.rcMonitor;
        return Drawing.Rectangle.FromLTRB(r.Left, r.Top, r.Right, r.Bottom);
    }

    // Copies a screen area as it is shown now. CaptureBlt includes layered windows (menus, tooltips).
    public static Drawing.Bitmap Grab(Drawing.Rectangle region, bool includeCursor)
    {
        if (region.Width < 1 || region.Height < 1) throw new ArgumentException("The capture area is empty.");
        using var dpi = new DpiScope();
        var bitmap = new Drawing.Bitmap(region.Width, region.Height, DrawingImaging.PixelFormat.Format32bppRgb);
        try
        {
            using var graphics = Drawing.Graphics.FromImage(bitmap);
            var target = graphics.GetHdc(); var screen = GetDC(IntPtr.Zero);
            try { if (!BitBlt(target, 0, 0, region.Width, region.Height, screen, region.Left, region.Top, 0x40CC0020)) throw new System.ComponentModel.Win32Exception(); }
            finally { ReleaseDC(IntPtr.Zero, screen); graphics.ReleaseHdc(target); }
            if (includeCursor) DrawCursor(graphics, region.Location);
            return bitmap;
        }
        catch { bitmap.Dispose(); throw; }
    }
    // Draws the current mouse pointer where it is on screen; origin is the bitmap's top-left on screen.
    public static void DrawCursor(Drawing.Graphics graphics, Drawing.Point origin)
    {
        var info = new CURSORINFO { cbSize = Marshal.SizeOf<CURSORINFO>() };
        if (!GetCursorInfo(ref info) || (info.flags & 1) == 0 || info.hCursor == IntPtr.Zero) return;
        var hotX = 0; var hotY = 0;
        if (GetIconInfo(info.hCursor, out var icon))
        {
            hotX = icon.xHotspot; hotY = icon.yHotspot;
            if (icon.hbmMask != IntPtr.Zero) DeleteObject(icon.hbmMask);
            if (icon.hbmColor != IntPtr.Zero) DeleteObject(icon.hbmColor);
        }
        var hdc = graphics.GetHdc();
        try { DrawIconEx(hdc, info.ptScreenPos.X - origin.X - hotX, info.ptScreenPos.Y - origin.Y - hotY, info.hCursor, 0, 0, 0, IntPtr.Zero, 3); }
        finally { graphics.ReleaseHdc(hdc); }
    }
    public static Drawing.Bitmap Crop(Drawing.Bitmap source, Drawing.Rectangle area) => source.Clone(area, DrawingImaging.PixelFormat.Format32bppRgb);
    // Freehand region: the picture inside the drawn outline, cropped to the outline's bounds. Outside the
    // outline it is transparent (0.22.1, David: "a freeform capture should be exactly that"; it was white,
    // then a drawn checkerboard in 0.22.0). The editor shows a checkerboard behind transparent parts.
    internal const int CheckerSize = 8;
    internal static readonly System.Windows.Media.Color CheckerLight = System.Windows.Media.Colors.White, CheckerDark = System.Windows.Media.Color.FromRgb(204, 204, 204);
    public static Drawing.Bitmap CropFreehand(Drawing.Bitmap source, IReadOnlyList<Drawing.Point> outline)
    {
        if (outline.Count < 3) throw new ArgumentException("Draw a bigger freehand area.");
        var bounds = Bounds(outline); bounds.Intersect(new(0, 0, source.Width, source.Height));
        if (bounds.Width < 1 || bounds.Height < 1) throw new ArgumentException("The freehand region is outside the picture.");
        var result = new Drawing.Bitmap(bounds.Width, bounds.Height, DrawingImaging.PixelFormat.Format32bppArgb);
        using var graphics = Drawing.Graphics.FromImage(result);
        graphics.Clear(Drawing.Color.Transparent);
        graphics.CompositingMode = Drawing.Drawing2D.CompositingMode.SourceCopy; // Copy the screen pixels as they are (opaque).
        using var path = new Drawing.Drawing2D.GraphicsPath();
        path.AddPolygon(outline.Select(p => new Drawing.Point(p.X - bounds.X, p.Y - bounds.Y)).ToArray());
        graphics.SetClip(path);
        graphics.DrawImage(source, new Drawing.Rectangle(0, 0, bounds.Width, bounds.Height), bounds, Drawing.GraphicsUnit.Pixel);
        return result;
    }
    public static Drawing.Rectangle Bounds(IReadOnlyList<Drawing.Point> points) =>
        Drawing.Rectangle.FromLTRB(points.Min(p => p.X), points.Min(p => p.Y), points.Max(p => p.X) + 1, points.Max(p => p.Y) + 1);
    public static Drawing.Rectangle Normalize(Drawing.Point first, Drawing.Point last) =>
        Drawing.Rectangle.FromLTRB(Math.Min(first.X, last.X), Math.Min(first.Y, last.Y), Math.Max(first.X, last.X), Math.Max(first.Y, last.Y));
    // H.264 needs even sizes: crop inward by at most one pixel, never outside the user's area.
    public static Drawing.Rectangle EvenSize(Drawing.Rectangle region) => new(region.Left, region.Top, region.Width & ~1, region.Height & ~1);

    // A pixel-exact WPF copy (96 DPI, so one picture pixel is one canvas pixel in the editor).
    public static BitmapSource ToBitmapSource(Drawing.Bitmap bitmap)
    {
        var area = new Drawing.Rectangle(0, 0, bitmap.Width, bitmap.Height);
        // A picture with transparency (a freehand capture, 0.22.1) keeps it.
        var alpha = bitmap.PixelFormat == DrawingImaging.PixelFormat.Format32bppArgb;
        var data = bitmap.LockBits(area, DrawingImaging.ImageLockMode.ReadOnly, alpha ? DrawingImaging.PixelFormat.Format32bppArgb : DrawingImaging.PixelFormat.Format32bppRgb);
        try
        {
            var source = BitmapSource.Create(bitmap.Width, bitmap.Height, 96, 96, alpha ? PixelFormats.Bgra32 : PixelFormats.Bgr32, null, data.Scan0, data.Stride * bitmap.Height, data.Stride);
            source.Freeze(); return source;
        }
        finally { bitmap.UnlockBits(data); }
    }

    // ---- Windows under the pointer (Window / Object capture) ----
    // Visible top-level windows from front to back, each with its visible child controls. TRT's own
    // windows, minimised, hidden (cloaked) and click-through overlay windows are left out.
    public static List<WindowTarget> VisibleWindows()
    {
        using var dpi = new DpiScope();
        var own = Environment.ProcessId;
        var result = new List<WindowTarget>();
        var screen = VirtualScreen;
        EnumWindows((handle, _) =>
        {
            if (!IsWindowVisible(handle) || IsIconic(handle)) return true;
            GetWindowThreadProcessId(handle, out var process);
            if (process == own || Cloaked(handle) || (GetWindowLongPtr(handle, -20).ToInt64() & 0x20) != 0) return true;
            if (WindowBounds(handle) is not { } bounds) return true;
            bounds.Intersect(screen);
            if (bounds.Width < 4 || bounds.Height < 4) return true;
            var objects = new List<Drawing.Rectangle>();
            EnumChildWindows(handle, (child, _) =>
            {
                if (IsWindowVisible(child) && GetWindowRect(child, out var r))
                {
                    var rect = Drawing.Rectangle.FromLTRB(r.Left, r.Top, r.Right, r.Bottom); rect.Intersect(bounds);
                    if (rect.Width >= 4 && rect.Height >= 4 && rect != bounds) objects.Add(rect);
                }
                return true;
            }, IntPtr.Zero);
            result.Add(new(handle, bounds, objects));
            return true;
        }, IntPtr.Zero);
        return result;
    }
    // The frontmost window at a point; with objects, the smallest control under the point inside it.
    public static Drawing.Rectangle? Pick(IReadOnlyList<WindowTarget> windows, Drawing.Point point, bool objects)
    {
        var window = windows.FirstOrDefault(w => w.Bounds.Contains(point));
        if (window == null) return null;
        if (!objects) return window.Bounds;
        var inside = window.Objects.Where(o => o.Contains(point)).OrderBy(o => (long)o.Width * o.Height).ToList();
        return inside.Count > 0 ? inside[0] : window.Bounds;
    }
    // The window's visible frame (without the invisible resize border Windows 10/11 adds).
    public static Drawing.Rectangle? WindowBounds(IntPtr handle)
    {
        using var dpi = new DpiScope();
        if (DwmGetWindowAttribute(handle, 9, out RECT frame, Marshal.SizeOf<RECT>()) == 0 && frame.Right > frame.Left && frame.Bottom > frame.Top)
            return Drawing.Rectangle.FromLTRB(frame.Left, frame.Top, frame.Right, frame.Bottom);
        return GetWindowRect(handle, out var r) && r.Right > r.Left && r.Bottom > r.Top ? Drawing.Rectangle.FromLTRB(r.Left, r.Top, r.Right, r.Bottom) : null;
    }
    public static bool IsOwnWindow(IntPtr handle) { if (handle == IntPtr.Zero) return false; GetWindowThreadProcessId(handle, out var process); return process == Environment.ProcessId; }
    public static bool IsCapturable(IntPtr handle) => handle != IntPtr.Zero && IsWindowVisible(handle) && !IsIconic(handle) && !IsOwnWindow(handle) && !Cloaked(handle);
    public static IntPtr ForegroundWindow => GetAncestor(GetForegroundWindow(), 2);
    private static bool Cloaked(IntPtr handle) => DwmGetWindowAttribute(handle, 14, out int cloaked, sizeof(int)) == 0 && cloaked != 0;
    // Keeps a window out of screenshots and recordings (Windows 10 2004 and later).
    public static bool ExcludeFromCapture(IntPtr handle) => SetWindowDisplayAffinity(handle, 0x11);

    // ---- Foreground tracking: the Active Window button needs the window that was active before
    // the user clicked TRT's capture bar. ----
    internal sealed class ForegroundTracker : IDisposable
    {
        private readonly WinEventDelegate callback;
        private readonly IntPtr hook;
        public IntPtr LastForeignWindow { get; private set; }
        public ForegroundTracker()
        {
            callback = (_, _, handle, _, _, _, _) => { var top = GetAncestor(handle, 2); if (IsCapturable(top)) LastForeignWindow = top; };
            var current = ForegroundWindow; if (IsCapturable(current)) LastForeignWindow = current;
            hook = SetWinEventHook(3, 3, IntPtr.Zero, callback, 0, 0, 0);
        }
        public IntPtr Current => IsCapturable(ForegroundWindow) ? ForegroundWindow : IsCapturable(LastForeignWindow) ? LastForeignWindow : IntPtr.Zero;
        public void Dispose() { if (hook != IntPtr.Zero) UnhookWinEvent(hook); }
    }

    // ---- Win32 ----
    [StructLayout(LayoutKind.Sequential)] private struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] private struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] private struct CURSORINFO { public int cbSize; public int flags; public IntPtr hCursor; public POINT ptScreenPos; }
    [StructLayout(LayoutKind.Sequential)] private struct ICONINFO { [MarshalAs(UnmanagedType.Bool)] public bool fIcon; public int xHotspot, yHotspot; public IntPtr hbmMask, hbmColor; }
    [StructLayout(LayoutKind.Sequential)] private struct MONITORINFO { public int cbSize; public RECT rcMonitor, rcWork; public int dwFlags; }
    private delegate bool EnumWindowsProc(IntPtr handle, IntPtr parameter);
    private delegate void WinEventDelegate(IntPtr hook, uint eventType, IntPtr handle, int objectId, int childId, uint thread, uint time);
    [DllImport("user32.dll")] private static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    [DllImport("user32.dll")] private static extern int GetSystemMetrics(int index);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetCursorPos(out POINT point);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetCursorInfo(ref CURSORINFO info);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetIconInfo(IntPtr icon, out ICONINFO info);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool DrawIconEx(IntPtr hdc, int x, int y, IntPtr icon, int width, int height, int step, IntPtr brush, int flags);
    [DllImport("gdi32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool DeleteObject(IntPtr handle);
    [DllImport("gdi32.dll", SetLastError = true)] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool BitBlt(IntPtr target, int x, int y, int width, int height, IntPtr source, int sourceX, int sourceY, uint operation);
    [DllImport("user32.dll")] private static extern IntPtr GetDC(IntPtr window);
    [DllImport("user32.dll")] private static extern int ReleaseDC(IntPtr window, IntPtr dc);
    [DllImport("user32.dll")] private static extern IntPtr MonitorFromPoint(POINT point, int flags);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetMonitorInfo(IntPtr monitor, ref MONITORINFO info);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr parameter);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool EnumChildWindows(IntPtr parent, EnumWindowsProc callback, IntPtr parameter);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool IsWindowVisible(IntPtr handle);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool IsIconic(IntPtr handle);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetWindowRect(IntPtr handle, out RECT rect);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr handle, out int process);
    [DllImport("user32.dll")] private static extern IntPtr GetWindowLongPtr(IntPtr handle, int index);
    [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern IntPtr GetAncestor(IntPtr handle, uint flags);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool SetWindowDisplayAffinity(IntPtr handle, uint affinity);
    [DllImport("dwmapi.dll")] private static extern int DwmGetWindowAttribute(IntPtr handle, int attribute, out RECT value, int size);
    [DllImport("dwmapi.dll")] private static extern int DwmGetWindowAttribute(IntPtr handle, int attribute, out int value, int size);
    [DllImport("user32.dll")] private static extern IntPtr SetWinEventHook(uint eventMin, uint eventMax, IntPtr module, WinEventDelegate callback, uint process, uint thread, uint flags);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool UnhookWinEvent(IntPtr hook);
}
