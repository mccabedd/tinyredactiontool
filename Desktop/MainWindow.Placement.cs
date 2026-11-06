using System.Globalization;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;

namespace TinyRedaction.Desktop;

// 3.0.0 (David): the editor opens the way it was last closed: maximised, or in a window of the same size and place.
// Windows' own window placement is used, so a window last left on a monitor that is no longer there comes back
// onto a screen that is, and mixed monitor scaling is handled by Windows.
public partial class MainWindow
{
    private WindowState lastShownState = WindowState.Maximized;
    private NativeRect? placementToRestore;

    // Settings text: "left,top,right,bottom,Maximized" or "...,Normal" (the restored window, in screen pixels).
    internal static string PlacementText(int left, int top, int right, int bottom, bool maximized) =>
        string.Join(",", new[] { left, top, right, bottom }.Select(v => v.ToString(CultureInfo.InvariantCulture))) + (maximized ? ",Maximized" : ",Normal");
    internal static (int Left, int Top, int Right, int Bottom, bool Maximized)? ParsePlacement(string? text)
    {
        var parts = text?.Split(',', StringSplitOptions.TrimEntries);
        if (parts is not { Length: 5 } || parts[4] is not ("Maximized" or "Normal")) return null;
        var numbers = new int[4];
        for (var i = 0; i < 4; i++) if (!int.TryParse(parts[i], NumberStyles.Integer, CultureInfo.InvariantCulture, out numbers[i])) return null;
        var (left, top, right, bottom) = (numbers[0], numbers[1], numbers[2], numbers[3]);
        // A window too small to use, or one of an impossible size, is not restored.
        if (right - left < 200 || bottom - top < 150 || right - left > 40000 || bottom - top > 40000) return null;
        return (left, top, right, bottom, parts[4] == "Maximized");
    }

    // Before the window is first shown: open as last closed. Without a saved placement it opens maximised, as before.
    internal void UsePlacement(string? text)
    {
        if (ParsePlacement(text) is not { } saved) return;
        WindowState = saved.Maximized ? WindowState.Maximized : WindowState.Normal;
        lastShownState = WindowState;
        placementToRestore = new NativeRect { Left = saved.Left, Top = saved.Top, Right = saved.Right, Bottom = saved.Bottom };
    }
    private void RestorePlacement()
    {
        if (placementToRestore is not { } rect) return;
        placementToRestore = null;
        var handle = new WindowInteropHelper(this).Handle;
        if (handle == IntPtr.Zero) return;
        // SW_HIDE only sets where the restored window goes; WPF then shows it maximised or not (WindowState).
        var placement = new WindowPlacement { Length = Marshal.SizeOf<WindowPlacement>(), ShowCommand = 0, NormalPosition = rect };
        SetWindowPlacement(handle, ref placement);
    }
    private void TrackShownState()
    {
        if (WindowState != WindowState.Minimized && !IsFullScreen) lastShownState = WindowState;
    }

    // While closing: how the window is now. Minimised counts as the state it had before; F11 full screen as the
    // state before full screen (it opens maximised then, not in full screen).
    internal string? CurrentPlacement()
    {
        var handle = new WindowInteropHelper(this).Handle;
        if (handle == IntPtr.Zero) return null;
        var placement = new WindowPlacement { Length = Marshal.SizeOf<WindowPlacement>() };
        if (!GetWindowPlacement(handle, ref placement)) return null;
        var maximized = IsFullScreen ? beforeFullScreen!.Value.State == WindowState.Maximized
            : WindowState == WindowState.Minimized ? lastShownState == WindowState.Maximized
            : WindowState == WindowState.Maximized;
        var r = placement.NormalPosition;
        return PlacementText(r.Left, r.Top, r.Right, r.Bottom, maximized);
    }

    [StructLayout(LayoutKind.Sequential)] private struct NativeRect { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] private struct NativePoint { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)]
    private struct WindowPlacement { public int Length, Flags, ShowCommand; public NativePoint MinPosition, MaxPosition; public NativeRect NormalPosition; }
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetWindowPlacement(IntPtr window, ref WindowPlacement placement);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool SetWindowPlacement(IntPtr window, ref WindowPlacement placement);
}
