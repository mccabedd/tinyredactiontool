using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;
using TinyRedaction.Core;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace TinyRedaction.Desktop;

internal enum CaptureMode { ActiveWindow, Object, Rectangle, Freehand, FullScreen, Scrolling }

// Runs TRT as a capture tool (0.12.0, David: "Yes, capture bar"). TRT opens as a small
// capture bar with a notification-area icon; the editor opens when a capture goes to it or when asked.
// The capture shortcuts work while TRT runs, even with the bar hidden. Captures for the editor are
// kept in the session's CaptureStore and wiped when no longer needed.
internal sealed class CaptureController : IDisposable
{
    private const int ScreenshotKey = 1, RecordingKey = 2, BarKey = 3, EditorKey = 4;
    private bool wasBarOff;
    private readonly ManagedPolicy policy;
    private readonly bool interactive;
    private readonly MediaTools tools;
    private readonly CaptureStore store;
    private readonly string temporaryFolder;
    private CaptureBar? bar;
    private Forms.NotifyIcon? tray;
    private Forms.ContextMenuStrip? trayMenu;
    private Forms.ToolStripMenuItem? stopItem;
    private ScreenCapture.ForegroundTracker? foreground;
    private HwndSource? hotkeyWindow;
    private MainWindow? editor;
    private bool busy, quitting, trayHintShown, disposed;
    private ScreenRecorder? recorder;
    private RecordingBorder? recordingBorder;
    private RecordingBar? recordingBar;
    private DispatcherTimer? recordingClock;
    private bool discardRecording;
    private List<Window> hiddenForRecording = [];
    public AppSettings Settings { get; private set; } = new();
    internal CaptureStore Store => store;
    internal CaptureBar? Bar => bar;
    internal MainWindow? Editor => editor;
    internal ManagedPolicy Policy => policy;
    internal bool IsRecording => recorder != null;
    internal string? LastNotice { get; private set; }
    internal bool ScreenshotShortcutWorks { get; private set; }
    internal bool RecordingShortcutWorks { get; private set; }
    private static string FFmpeg => Path.Combine(AppContext.BaseDirectory, "tools", "ffmpeg.exe");

    // interactive = false (checks): no tray icon, shortcuts or foreground tracking, and settings
    // are not read from or saved to disk unless the caller sets AppSettings.Path.
    public CaptureController(ManagedPolicy managedPolicy, bool interactive = true, string? temporary = null)
    {
        policy = managedPolicy; this.interactive = interactive;
        temporaryFolder = Path.GetFullPath(temporary ?? Path.GetTempPath());
        tools = new MediaTools(); // Verifies and locks the approved FFmpeg used for recording.
        store = new CaptureStore(temporaryFolder);
    }

    // showBar = false: started with Windows (0.18.0), quietly in the notification area.
    public void Start(bool showBar = true)
    {
        Settings = AppSettings.Load();
        MainWindow.ApplySavedTheme();
        bar = new CaptureBar(this);
        bar.Closing += (_, e) =>
        {
            if (quitting) return;
            e.Cancel = true;
            if (Settings.CloseButtonQuits) bar.Dispatcher.BeginInvoke(Quit); else HideToTray(true);
        };
        PlaceBar();
        if (interactive)
        {
            CreateTray();
            foreground = new ScreenCapture.ForegroundTracker();
            hotkeyWindow = HwndSource.FromHwnd(new WindowInteropHelper(bar).EnsureHandle());
            hotkeyWindow.AddHook(HotkeyHook);
            RegisterHotkeys();
        }
        // 0.18.0: with the capture bar switched off in Settings (or a quiet start) TRT lives in the notification area.
        wasBarOff = !Settings.ShowCaptureBar;
        if (showBar && Settings.ShowCaptureBar)
        {
            bar.Show();
            if (Settings.BarTop is { } savedTop && Math.Abs(savedTop - WorkAreaOf(bar).Top) < 1) BarMoved(); // Was docked last time.
        }
        if (interactive)
        {
            bar.Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle, () => { ReportShortcutProblems(); OfferAbandonedCleanup(); });
        }
    }
    private void PlaceBar()
    {
        if (bar == null) return;
        bar.WindowStartupLocation = WindowStartupLocation.Manual;
        var area = SystemParameters.WorkArea;
        var screen = new Rect(SystemParameters.VirtualScreenLeft, SystemParameters.VirtualScreenTop, SystemParameters.VirtualScreenWidth, SystemParameters.VirtualScreenHeight);
        if (Settings.BarLeft is { } left && Settings.BarTop is { } top && screen.Contains(new Point(left + 40, top + 10)))
        { bar.Left = left; bar.Top = top; }
        else { bar.Left = area.Left + area.Width / 2 - 170; bar.Top = area.Top + 8; }
    }

    // ---- Notification area ----
    private void CreateTray()
    {
        trayMenu = new Forms.ContextMenuStrip();
        trayMenu.Items.Add("Show Capture Bar", null, (_, _) => ShowBar());
        trayMenu.Items.Add("Open Editor", null, (_, _) => OpenEditor());
        trayMenu.Items.Add(new Forms.ToolStripSeparator());
        trayMenu.Items.Add("Capture Rectangular Region", null, async (_, _) => await CaptureAsync(CaptureMode.Rectangle));
        trayMenu.Items.Add("Capture Scrolling Window", null, async (_, _) => await CaptureAsync(CaptureMode.Scrolling));
        trayMenu.Items.Add("Screen Recorder…", null, (_, _) => ShowRecorder(null));
        trayMenu.Items.Add("Screen Ruler", null, (_, _) => ShowRuler());
        stopItem = new Forms.ToolStripMenuItem("Stop Recording", null, (_, _) => StopRecording(false)) { Visible = false };
        trayMenu.Items.Add(stopItem);
        trayMenu.Items.Add(new Forms.ToolStripSeparator());
        trayMenu.Items.Add("Help", null, (_, _) => HelpManual.Open(null));
        trayMenu.Items.Add("Remove History…", null, (_, _) => AskRemoveHistory(null));
        trayMenu.Items.Add("Quit TinyRedactionTool", null, (_, _) => Quit());
        // 0.28.0 (David): the notification-area menu follows Light and Dark too.
        WindowTheme.Apply(trayMenu, MainWindow.DarkTheme);
        MainWindow.ThemeApplied += TrayThemeChanged;
        Drawing.Icon? icon = null;
        try { using var stream = Application.GetResourceStream(new Uri("pack://application:,,,/Assets/icon.ico")).Stream; icon = new Drawing.Icon(stream, Forms.SystemInformation.SmallIconSize); }
        catch (Exception ex) when (ex is IOException or ArgumentException) { icon = Drawing.SystemIcons.Application; }
        tray = new Forms.NotifyIcon { Icon = icon, Text = "TinyRedactionTool", ContextMenuStrip = trayMenu, Visible = true };
        tray.MouseClick += (_, e) => { if (e.Button == Forms.MouseButtons.Left) ShowBar(); };
        // 0.17.0 (David): a double-click on the icon opens the editor.
        tray.MouseDoubleClick += (_, e) => { if (e.Button == Forms.MouseButtons.Left) OpenEditor(); };
    }
    internal void ShowBar()
    {
        if (bar == null) return;
        strip?.Hide();
        bar.Show(); if (bar.WindowState == WindowState.Minimized) bar.WindowState = WindowState.Normal;
        if (BarDocked) bar.Top = WorkAreaOf(bar).Top;
        bar.Activate();
    }
    // – on the capture bar (0.13.0): the bar becomes a red tab at the top of the
    // screen; pointing at the tab brings the bar back where it was.
    private MinimizedStrip? strip;
    internal MinimizedStrip? Strip => strip;
    internal void MinimizeToStrip()
    {
        if (bar == null || !bar.IsVisible) return;
        var area = WorkAreaOf(bar);
        bar.Hide(); ShowStrip(area);
    }
    private void ShowStrip(Rect area)
    {
        if (bar == null) return;
        if (strip == null) { strip = new MinimizedStrip(); strip.Restore += (_, _) => RestoreFromStrip(); }
        strip.Place(StripLeft(area), area, Settings.StripWidth);
        strip.Show();
    }
    // Left edge of the red tab: under the bar's left end, or at the place chosen in Settings (0.18.0).
    internal double StripLeft(Rect area) => bar == null ? area.Left : !Settings.StripAtSetPlace ? bar.Left :
        area.Left + (area.Width - Math.Clamp(Settings.StripWidth, AppSettings.MinStripWidth, AppSettings.MaxStripWidth)) * Math.Clamp(Settings.StripPositionPercent, 0, 100) / 100.0;
    // The show/hide shortcut (0.18.0): shows a hidden bar (also from the red tab), hides a visible one.
    internal void ToggleBar()
    {
        if (bar == null || IsRecording) return;
        if (bar.IsVisible) { dockWatch?.Stop(); bar.Hide(); }
        else ShowBar();
    }
    private void RestoreFromStrip()
    {
        if (bar == null || IsRecording) return;
        if (!BarDocked) { ShowBar(); return; }
        // Docked: slide down from behind the top edge.
        strip?.Hide();
        var area = WorkAreaOf(bar);
        bar.Top = area.Top - bar.ActualHeight; bar.Show();
        Slide(area.Top, () => dockWatch?.Start());
    }

    // Docking (0.14.0, as in David's video): drop the bar at the top edge of a screen and it
    // sticks there; when the pointer leaves it, it slides up out of sight and leaves the red tab.
    // Pointing at the tab slides it back down. Dragging it away from the edge undocks it.
    internal bool BarDocked { get; private set; }
    internal bool BarSliding { get; private set; }
    private DispatcherTimer? dockWatch, slideTimer;
    private DateTime pointerLeftAt = DateTime.MaxValue;
    private const double DockDistance = 12;
    internal static TimeSpan HideDelay { get; set; } = TimeSpan.FromMilliseconds(700);
    internal void BarMoved()
    {
        if (bar == null) return;
        var area = WorkAreaOf(bar);
        BarDocked = bar.Top <= area.Top + DockDistance;
        if (!BarDocked) { dockWatch?.Stop(); return; }
        bar.Top = area.Top; Settings.BarTop = bar.Top; Settings.BarLeft = bar.Left;
        pointerLeftAt = DateTime.MaxValue;
        if (dockWatch == null)
        {
            dockWatch = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(120) };
            dockWatch.Tick += (_, _) => WatchDockedBar();
        }
        dockWatch.Start();
    }
    // Hides the docked bar once the pointer has been away from it for a moment, unless a menu or
    // dialog of its own is open or TRT is busy.
    internal void WatchDockedBar(bool now = false)
    {
        if (bar == null || !BarDocked || BarSliding) return;
        if (!bar.IsVisible) return; // Hidden for a capture or in the tab: nothing to watch yet.
        var busyBar = bar.OutputMenu.IsOpen || bar.BarMenu.IsOpen || bar.OwnedWindows.Count > 0 || busy || IsRecording || !bar.IsEnabled;
        if (PointerOver(bar) || busyBar) { pointerLeftAt = DateTime.MaxValue; return; }
        if (pointerLeftAt == DateTime.MaxValue) pointerLeftAt = DateTime.UtcNow;
        if (!now && DateTime.UtcNow - pointerLeftAt < HideDelay) return;
        dockWatch?.Stop(); pointerLeftAt = DateTime.MaxValue;
        var area = WorkAreaOf(bar);
        Slide(area.Top - bar.ActualHeight, () => { bar.Hide(); bar.Top = area.Top; ShowStrip(area); });
    }
    private void Slide(double to, Action done)
    {
        if (bar == null) return;
        slideTimer?.Stop();
        var from = bar.Top; var started = DateTime.UtcNow; var length = TimeSpan.FromMilliseconds(140);
        BarSliding = true;
        slideTimer = new DispatcherTimer(DispatcherPriority.Render) { Interval = TimeSpan.FromMilliseconds(15) };
        slideTimer.Tick += (_, _) =>
        {
            var t = Math.Min(1, (DateTime.UtcNow - started) / length);
            bar.Top = from + (to - from) * t;
            if (t < 1) return;
            slideTimer!.Stop(); BarSliding = false; done();
        };
        slideTimer.Start();
    }
    private static bool PointerOver(Window window)
    {
        if (!GetCursorPos(out var p) || !GetWindowRect(new WindowInteropHelper(window).Handle, out var r)) return window.IsMouseOver;
        return p.X >= r.Left && p.X < r.Right && p.Y >= r.Top && p.Y < r.Bottom;
    }
    // The work area of the screen holding a window, in WPF units (TRT's windows use the system scaling).
    internal static Rect WorkAreaOf(Window window)
    {
        var handle = new WindowInteropHelper(window).Handle;
        if (handle == IntPtr.Zero) return SystemParameters.WorkArea;
        var area = Forms.Screen.FromHandle(handle).WorkingArea;
        var dpi = VisualTreeHelper.GetDpi(window);
        return new Rect(area.X / dpi.DpiScaleX, area.Y / dpi.DpiScaleY, area.Width / dpi.DpiScaleX, area.Height / dpi.DpiScaleY);
    }
    [StructLayout(LayoutKind.Sequential)] private struct NativePoint { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] private struct NativeRect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetCursorPos(out NativePoint point);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetWindowRect(IntPtr window, out NativeRect rect);
    private ScreenRuler? ruler;
    internal ScreenRuler? Ruler => ruler;
    // 0.14.0: a ruler with measuring tools (ScreenRuler.cs), opened on the screen with the pointer.
    internal void ShowRuler()
    {
        if (ruler is { Visible: true }) { ruler.Activate(); return; }
        using (new ScreenCapture.DpiScope())
        {
            ruler = new ScreenRuler();
            _ = ruler.Handle; // Created here, per-monitor aware, so it takes this monitor's scaling before it is placed.
            var monitor = ScreenCapture.MonitorAt(ScreenCapture.CursorPosition);
            ruler.Location = new(monitor.X + (monitor.Width - ruler.Width) / 2, monitor.Y + monitor.Height / 3);
        }
        ruler.MeasureRequested += Measure;
        ruler.FormClosed += (_, _) => { ruler?.Dispose(); ruler = null; };
        ruler.Show(); ruler.Activate();
    }
    // The ruler's Rectangle, Distance and Angle tools measure on a frozen picture of the screen.
    internal Func<MeasureOverlay, bool>? ShowMeasureOverlay { get; set; } // Checks look at the overlay instead of showing it.
    private void Measure(MeasureKind kind)
    {
        if (busy) return;
        busy = true;
        try
        {
            using var dpi = new ScreenCapture.DpiScope();
            var screen = ScreenCapture.VirtualScreen;
            using var desktop = ScreenCapture.Grab(screen, false);
            using var overlay = new MeasureOverlay(desktop, screen, kind);
            if (ShowMeasureOverlay != null) ShowMeasureOverlay(overlay); else overlay.ShowDialog();
        }
        catch (Exception ex) when (ex is InvalidOperationException or System.ComponentModel.Win32Exception or ExternalException) { ShowError("Screen Ruler", "Couldn't measure the screen: " + ex.Message); }
        finally { busy = false; }
        ruler?.Activate();
    }
    internal void HideToTray(bool fromClose)
    {
        bar?.Hide();
        if (tray != null && fromClose && !trayHintShown)
        {
            trayHintShown = true;
            tray.ShowBalloonTip(4000, "TRT is still running", "Shortcuts still work. Click the icon to show the bar; right-click it to quit.", Forms.ToolTipIcon.Info);
        }
    }
    private void Notify(string text)
    {
        LastNotice = text;
        tray?.ShowBalloonTip(2500, "TinyRedactionTool", text, Forms.ToolTipIcon.Info);
    }
    private Window? DialogOwner() => editor is { IsVisible: true } e ? e : bar is { IsVisible: true } b ? b : null;
    private void ShowError(string title, string text)
    {
        var owner = DialogOwner();
        if (owner != null) ThemedMessage.Show(owner, text, title, MessageBoxButton.OK, MessageBoxImage.Warning);
        else ThemedMessage.Show(text, title, MessageBoxButton.OK, MessageBoxImage.Warning);
    }

    // ---- Shortcuts (registered with Windows, so they work whichever program is in front) ----
    private void RegisterHotkeys()
    {
        UnregisterHotkeys();
        if (hotkeyWindow == null) return;
        ScreenshotShortcutWorks = Register(ScreenshotKey, Settings.ScreenshotShortcut);
        RecordingShortcutWorks = Register(RecordingKey, Settings.RecordingShortcut);
        BarShortcutWorks = Settings.BarShortcut.Length == 0 || Register(BarKey, Settings.BarShortcut);
        EditorShortcutWorks = Settings.EditorShortcut.Length == 0 || Register(EditorKey, Settings.EditorShortcut);
    }
    internal bool BarShortcutWorks { get; private set; } = true;
    internal bool EditorShortcutWorks { get; private set; } = true;
    private bool Register(int id, string shortcut)
    {
        if (AppSettings.ParseShortcut(shortcut) is not { } parsed) return false;
        uint modifiers = 0x4000; // MOD_NOREPEAT
        if (parsed.Modifiers.HasFlag(ModifierKeys.Alt)) modifiers |= 1;
        if (parsed.Modifiers.HasFlag(ModifierKeys.Control)) modifiers |= 2;
        if (parsed.Modifiers.HasFlag(ModifierKeys.Shift)) modifiers |= 4;
        return RegisterHotKey(hotkeyWindow!.Handle, id, modifiers, (uint)KeyInterop.VirtualKeyFromKey(parsed.Key));
    }
    private void UnregisterHotkeys()
    {
        if (hotkeyWindow == null) return;
        foreach (var id in new[] { ScreenshotKey, RecordingKey, BarKey, EditorKey }) UnregisterHotKey(hotkeyWindow.Handle, id);
    }
    private void ReportShortcutProblems()
    {
        var missing = new List<string>();
        if (!ScreenshotShortcutWorks) missing.Add(AppSettings.DisplayShortcut(Settings.ScreenshotShortcut) + " (screenshot)");
        if (!RecordingShortcutWorks) missing.Add(AppSettings.DisplayShortcut(Settings.RecordingShortcut) + " (recording)");
        if (!BarShortcutWorks) missing.Add(AppSettings.DisplayShortcut(Settings.BarShortcut) + " (show or hide the capture bar)");
        if (!EditorShortcutWorks) missing.Add(AppSettings.DisplayShortcut(Settings.EditorShortcut) + " (open the editor)");
        if (missing.Count == 0) return;
        // The installed TinyRedactionTool v2.5 uses the same default shortcuts.
        var installed = System.Diagnostics.Process.GetProcessesByName("TinyRedactionTool").Any(p => p.Id != Environment.ProcessId);
        ShowError("Shortcuts", "Another program already uses these shortcuts: " + string.Join(", ", missing) + "." +
            (installed ? "\n\nTinyRedactionTool v2.5 is running and uses them. Quit it (right-click its icon, Quit), then open Settings and click OK." : "") +
            "\n\nThe capture bar and its icon still work. You can choose other shortcuts in Settings.");
    }
    private IntPtr HotkeyHook(IntPtr window, int message, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (message != 0x0312) return IntPtr.Zero;
        handled = true;
        // Ignore the shortcut while TRT shows a dialog (or a capture is being chosen).
        if (System.Windows.Interop.ComponentDispatcher.IsThreadModal) return IntPtr.Zero;
        var id = wParam.ToInt32();
        bar?.Dispatcher.BeginInvoke(async () =>
        {
            if (id == ScreenshotKey) await CaptureAsync(CaptureMode.Rectangle);
            else if (id == RecordingKey) { if (recorder != null) StopRecording(false); else await StartRecordingAsync(RecordingArea.Region); }
            else if (id == BarKey) ToggleBar();
            else if (id == EditorKey) OpenEditor().Activate();
        });
        return IntPtr.Zero;
    }

    // ---- Screenshots ----
    internal async Task CaptureAsync(CaptureMode mode)
    {
        if (busy || quitting || disposed) return;
        if (recorder != null) { Notify("Stop recording first."); return; }
        if (Settings.Output == CaptureOutput.Editor && editor is { CanTakeCapture: false }) { Notify("The editor is busy. Try again in a moment."); return; }
        busy = true; bar?.SetBusy(true);
        var target = mode == CaptureMode.ActiveWindow ? foreground?.Current ?? (ScreenCapture.IsCapturable(ScreenCapture.ForegroundWindow) ? ScreenCapture.ForegroundWindow : IntPtr.Zero) : IntPtr.Zero;
        var hidden = HideOwnWindows();
        BitmapSource? image = null;
        try
        {
            await Task.Delay(hidden.Count > 0 ? 250 : 40);
            if (Settings.CaptureDelaySeconds > 0) await Task.Delay(Settings.CaptureDelaySeconds * 1000);
            using var picture = mode == CaptureMode.Scrolling ? await TakeScrollingPictureAsync() : TakePicture(mode, target);
            if (picture != null) image = ScreenCapture.ToBitmapSource(picture);
        }
        catch (Exception ex) when (ex is not OutOfMemoryException) { RestoreOwnWindows(hidden); hidden = []; ShowError("Screen Capture", ex.Message); }
        finally { RestoreOwnWindows(hidden); }
        try { if (image != null) await DeliverAsync(image); }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or InvalidOperationException or COMException) { ShowError("Screen Capture", ex.Message); }
        finally { busy = false; bar?.SetBusy(false); }
    }
    private Drawing.Bitmap? TakePicture(CaptureMode mode, IntPtr target)
    {
        using var dpi = new ScreenCapture.DpiScope();
        var cursor = Settings.CaptureMousePointer;
        var screen = ScreenCapture.VirtualScreen;
        switch (mode)
        {
            case CaptureMode.ActiveWindow:
                if (target == IntPtr.Zero || ScreenCapture.WindowBounds(target) is not { } bounds) throw new InvalidOperationException("No window to capture. Click the window you want, then try again.");
                bounds.Intersect(screen);
                if (bounds.Width < 2 || bounds.Height < 2) throw new InvalidOperationException("The active window is not on the screen.");
                return ScreenCapture.Grab(bounds, cursor);
            case CaptureMode.FullScreen:
                return ScreenCapture.Grab(Settings.FullScreenAllMonitors ? screen : ScreenCapture.MonitorAt(ScreenCapture.CursorPosition), cursor);
            default:
                // Freeze the screen first, so menus and tooltips that close when the selection screen
                // appears are still in the picture (inherited v2.5.1 behaviour).
                using (var desktop = ScreenCapture.Grab(screen, cursor))
                {
                    var kind = mode switch { CaptureMode.Freehand => SelectionKind.Freehand, CaptureMode.Object => SelectionKind.Object, _ => SelectionKind.Rectangle };
                    var hint = kind switch
                    {
                        SelectionKind.Freehand => "Draw round the area. Esc or right-click cancels.",
                        SelectionKind.Object => "Point at a window or a part of it, then click. Esc or right-click cancels.",
                        _ => "Drag round the area to capture. Esc or right-click cancels.",
                    };
                    using var overlay = new CaptureOverlay(desktop, screen, kind, kind == SelectionKind.Object ? ScreenCapture.VisibleWindows() : null, hint);
                    if (overlay.ShowDialog() != Forms.DialogResult.OK) return null;
                    if (kind == SelectionKind.Freehand) return ScreenCapture.CropFreehand(desktop, overlay.Outline.Select(p => new Drawing.Point(p.X - screen.X, p.Y - screen.Y)).ToList());
                    var area = overlay.SelectedRegion; area.Offset(-screen.X, -screen.Y);
                    return ScreenCapture.Crop(desktop, area);
                }
        }
    }
    // Scrolling window (0.13.0): pick the window or panel, then TRT scrolls it and joins the pictures.
    private async Task<Drawing.Bitmap?> TakeScrollingPictureAsync()
    {
        Drawing.Rectangle area; Drawing.Point clicked;
        using (new ScreenCapture.DpiScope())
        {
            var screen = ScreenCapture.VirtualScreen;
            using var desktop = ScreenCapture.Grab(screen, false);
            // 0.22.2 (David: no choice of pane): the click also says which part to scroll, such as one pane of a web page.
            using var overlay = new CaptureOverlay(desktop, screen, SelectionKind.Object, ScreenCapture.VisibleWindows(), "Click inside the part to scroll (a window, panel or page pane). Esc or right-click cancels.") { FindWebPanes = true };
            if (overlay.ShowDialog() != Forms.DialogResult.OK) return null;
            area = Drawing.Rectangle.Intersect(overlay.SelectedRegion, screen); clicked = overlay.ClickedPoint;
        }
        if (area.Width < 16 || area.Height < 32) throw new InvalidOperationException("That area is too small to scroll.");
        await Task.Delay(150);
        CaptureToast.Show("Scrolling… press Esc to stop", 60);
        try { return await ScrollingCapture.RunAsync(area, ScrollingCapture.EscapePressed, scrollAt: area.Contains(clicked) ? clicked : null); }
        finally { CaptureToast.Show("Scrolling Capture Finished", 0.8); }
    }
    // Hides TRT's own windows so they are not in the picture; RestoreOwnWindows shows them again.
    private List<Window> HideOwnWindows()
    {
        var hidden = new List<Window>();
        foreach (var window in new Window?[] { bar, strip }.Concat(AllEditors))
            if (window is { IsVisible: true } && window.WindowState != WindowState.Minimized) { window.Hide(); hidden.Add(window); }
        if (ruler is { Visible: true }) { ruler.Hide(); rulerHidden = true; }
        return hidden;
    }
    private bool rulerHidden;
    private void RestoreOwnWindows(List<Window> hidden)
    {
        foreach (var window in hidden) window.Show();
        hidden.Clear();
        if (rulerHidden) { rulerHidden = false; ruler?.Show(); }
    }

    internal async Task DeliverAsync(BitmapSource image)
    {
        // Every screenshot also goes to the clipboard, as captured (David, 0.13.0).
        LastNotice = CopyImage(image) ? "Copied to the clipboard" : "Not copied: the clipboard is busy";
        CaptureToast.Show(LastNotice);
        switch (Settings.Output)
        {
            case CaptureOutput.Clipboard:
                break;
            case CaptureOutput.File:
                SaveImageAs(image);
                break;
            default:
                var path = store.NewFile("CAPTURE", ".png");
                WritePng(image, path);
                await OpenInEditorAsync(path);
                break;
        }
    }
    // Another program (clipboard history, a remote-desktop client) can hold the clipboard for a moment:
    // try for about three seconds (0.15.0; was a third of a second), then report it instead of failing.
    internal static bool CopyImage(BitmapSource image)
    {
        for (var attempt = 0; ; attempt++)
        {
            try { Clipboard.SetDataObject(Transparency.ClipboardData(image), true); return true; }
            catch (COMException) when (attempt < 25) { Thread.Sleep(120); }
            catch (COMException) { return false; }
        }
    }
    internal const string ClipboardBusy = "The clipboard is busy, so nothing was copied. Try again.";
    internal static void WritePng(BitmapSource image, string path)
    {
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(image));
        using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None);
        encoder.Save(file);
    }
    private void SaveImageAs(BitmapSource image)
    {
        var folder = Settings.LastSaveFolder is { } last && Directory.Exists(last) ? last : Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);
        var dialog = new SaveFileDialog { Filter = "PNG image|*.png|JPG image|*.jpg", AddExtension = true, AddToRecent = false, InitialDirectory = folder, FileName = $"CAPTURE_{DateTime.Now:yyyyMMdd_HHmmss}.png" };
        if (dialog.ShowDialog(DialogOwner()) != true) return;
        if (!AllowDestination(dialog.FileName)) return;
        var jpg = Path.GetExtension(dialog.FileName).Equals(".jpg", StringComparison.OrdinalIgnoreCase);
        BitmapEncoder encoder = jpg ? new JpegBitmapEncoder { QualityLevel = 95 } : new PngBitmapEncoder();
        // A JPG has no transparency: a freehand capture goes on white (0.22.1).
        encoder.Frames.Add(BitmapFrame.Create(jpg && Transparency.HasTransparency(image) ? Transparency.Flatten(image, Colors.White) : image));
        var partial = dialog.FileName + ".partial-" + Guid.NewGuid().ToString("N");
        try
        {
            using (var file = new FileStream(partial, FileMode.CreateNew, FileAccess.Write, FileShare.None)) encoder.Save(file);
            File.Move(partial, dialog.FileName, true);
        }
        finally { if (File.Exists(partial)) File.Delete(partial); }
        Settings.LastSaveFolder = Path.GetDirectoryName(dialog.FileName); Settings.Save();
        Notify($"Screenshot saved as {Path.GetFileName(dialog.FileName)}, as captured (nothing redacted).");
    }
    private bool AllowDestination(string path)
    {
        if (!ManagedPolicy.IsNetwork(path)) return true;
        if (policy.BlockNetworkDestination) throw new IOException("Your organisation's policy blocks saving to network drives.");
        var owner = DialogOwner();
        const string text = "This folder is on a network or mapped drive. Save the capture there?";
        return (owner != null ? ThemedMessage.Show(owner, text, "Network Drive", MessageBoxButton.YesNo, MessageBoxImage.Warning) : ThemedMessage.Show(text, "Network Drive", MessageBoxButton.YesNo, MessageBoxImage.Warning)) == MessageBoxResult.Yes;
    }
    // Opens a capture in the editor. If the editor keeps its current capture instead (or cannot open
    // the new one), the new capture is offered for saving before it is wiped, so it is never lost silently.
    private async Task OpenInEditorAsync(string path)
    {
        var window = OpenEditor();
        // 0.26.1 (David): a screenshot taken while a New picture is open goes onto it, as an item.
        if (await window.AddCaptureOntoNewPictureAsync(path)) { Notify("Screenshot added to your New picture. Ctrl+Z takes it back."); return; }
        if (await window.OpenCaptureAsync(path)) return;
        var video = Path.GetExtension(path).Equals(".mp4", StringComparison.OrdinalIgnoreCase);
        var kind = video ? "recording" : "screenshot";
        if (Ask(window, $"The new {kind} didn't open. Save it before TRT wipes it?", "New " + kind))
        {
            var folder = Settings.LastSaveFolder is { } last && Directory.Exists(last) ? last : Environment.GetFolderPath(video ? Environment.SpecialFolder.MyVideos : Environment.SpecialFolder.MyPictures);
            var dialog = new SaveFileDialog { Filter = video ? "MP4 video|*.mp4" : "PNG image|*.png", AddExtension = true, AddToRecent = false, InitialDirectory = folder, FileName = Path.GetFileName(path) };
            if (dialog.ShowDialog(window) == true && AllowDestination(dialog.FileName)) { File.Copy(path, dialog.FileName, true); Settings.LastSaveFolder = Path.GetDirectoryName(dialog.FileName); Settings.Save(); }
        }
        try { store.Wipe(path); } catch (IOException) { }
    }

    // ---- Editor ----
    // Checks supply off-screen editor windows and answer questions without dialogs.
    internal Func<MainWindow>? EditorFactory { get; set; }
    internal Func<Window, string, string, bool> Ask { get; set; } =
        (owner, text, title) => ThemedMessage.Show(owner, text, title, MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes;
    internal MainWindow OpenEditor()
    {
        if (editor == null)
        {
            editor = CreateEditor();
            if (EditorFactory == null) RememberPlacement(editor); // Checks' off-screen editors stay where they are put.
        }
        editor.Show();
        if (editor.WindowState == WindowState.Minimized) editor.WindowState = WindowState.Maximized;
        editor.Activate();
        return editor;
    }
    // 0.21.0 (David): a captured video frame chosen for Edit opens in its own picture editor window, beside
    // the video. Captures, shortcuts and files from Explorer still go to the main editor; a picture editor
    // never becomes the main one.
    private readonly List<MainWindow> otherEditors = [];
    internal IReadOnlyList<MainWindow> OtherEditors => otherEditors;
    private IEnumerable<MainWindow> AllEditors => editor == null ? otherEditors : otherEditors.Prepend(editor);
    internal MainWindow OpenAnotherEditor()
    {
        var created = CreateEditor(); created.PicturesOnly = true; otherEditors.Add(created);
        created.Show(); created.Activate();
        return created;
    }
    // 3.0.0 (David): the main editor opens the way it was last closed (maximised or windowed, its size and place).
    internal void RememberPlacement(MainWindow window)
    {
        window.UsePlacement(Settings.EditorPlacement);
        window.Closing += (_, e) =>
        {
            if (e.Cancel || window.CurrentPlacement() is not { } now || now == Settings.EditorPlacement) return;
            Settings.EditorPlacement = now; Settings.Save();
        };
    }
    private MainWindow CreateEditor()
    {
        var created = EditorFactory?.Invoke() ?? new MainWindow(policy);
        created.Captures = this;
        created.Closed += (_, _) =>
        {
            otherEditors.Remove(created);
            if (editor == created) editor = null;
        };
        return created;
    }
    internal void OpenFileInEditor() => OpenEditor().ShowOpenDialog();
    // A file from "Open with TRT" or a later start of TRT (0.13.0).
    internal async Task OpenPathInEditorAsync(string path)
    {
        if (quitting || disposed) return;
        await OpenEditor().OpenPathAsync(path);
    }
    internal void EditSettings(Window? owner)
    {
        UnregisterHotkeys(); // Lets the Settings window receive the current shortcut keys.
        try
        {
            var dialog = new SettingsWindow(Settings) { Owner = owner };
            if (dialog.ShowDialog() != true) return;
            Apply(dialog.Result);
            if (dialog.ExplorerMenuChosen != ExplorerMenu.IsInstalled)
            {
                try { if (dialog.ExplorerMenuChosen) ExplorerMenu.Install(); else ExplorerMenu.Remove(); }
                catch (Exception ex) when (ex is UnauthorizedAccessException or System.Security.SecurityException or IOException) { ShowError("Open with TRT", "Windows wouldn't let TRT change the right-click menu: " + ex.Message); }
            }
            if (dialog.StartupChosen != StartupEntry.IsInstalled)
            {
                try { if (dialog.StartupChosen) StartupEntry.Install(); else StartupEntry.Remove(); }
                catch (Exception ex) when (ex is UnauthorizedAccessException or System.Security.SecurityException or IOException) { ShowError("Start with Windows", "Windows wouldn't let TRT change starting with Windows: " + ex.Message); }
            }
            // 0.25.0 (David): TRT as the default app for pictures. Windows itself asks for the last click.
            if (dialog.DefaultPictureAppChosen != PictureApp.IsRegistered)
            {
                try
                {
                    if (dialog.DefaultPictureAppChosen) PictureApp.Register(); else PictureApp.Remove();
                    PictureApp.Announce();
                    if (dialog.DefaultPictureAppChosen)
                        try { PictureApp.OpenDefaultApps(); }
                        catch (System.ComponentModel.Win32Exception) { ShowError("Default App for Pictures", "TRT is ready to open pictures, but Windows' Default apps page didn't open. Open Settings › Apps › Default apps, choose TinyRedactionTool and press Set default."); }
                }
                catch (Exception ex) when (ex is UnauthorizedAccessException or System.Security.SecurityException or IOException) { ShowError("Default App for Pictures", "Windows wouldn't let TRT register itself for pictures: " + ex.Message); }
            }
            if (editor != null) { editor.SetTheme(dialog.ThemeChosen); foreach (var other in otherEditors) other.SetTheme(dialog.ThemeChosen); }
            else MainWindow.SetThemeWithoutEditor(dialog.ThemeChosen);
            Notify(Settings.Save() ? "Settings saved." : "Settings applied, but not saved for next time.");
        }
        finally
        {
            RegisterHotkeys();
            if (interactive) ReportShortcutProblems();
        }
    }
    internal void Apply(AppSettings settings)
    {
        Settings = settings;
        bar?.ShowSettings(settings);
        foreach (var open in AllEditors) open.ApplySettings(settings);
        if (strip is { IsVisible: true } && bar != null) { var area = WorkAreaOf(bar); strip.Place(StripLeft(area), area, settings.StripWidth); }
        // The capture bar switched off or on in Settings (0.18.0).
        if (bar != null && !settings.ShowCaptureBar && (bar.IsVisible || strip?.IsVisible == true)) { strip?.Hide(); bar.Hide(); }
        else if (bar != null && settings.ShowCaptureBar && wasBarOff && !bar.IsVisible && strip?.IsVisible != true) ShowBar();
        wasBarOff = !settings.ShowCaptureBar;
    }
    internal void SetOutput(CaptureOutput output) { Settings.Output = output; Settings.Save(); bar?.ShowSettings(Settings); }
    internal void SetCaptureMousePointer(bool include) { Settings.CaptureMousePointer = include; Settings.Save(); bar?.ShowSettings(Settings); }
    internal void ShowAbout(Window? owner)
    {
        AboutWindow.Open(owner, System.Text.RegularExpressions.Regex.Match(MainWindow.AboutText, @"\d+\.\d+\.\d+").Value);
    }

    // ---- Screen recording ----
    internal void ShowRecorder(Window? owner)
    {
        if (recorder != null) { StopRecording(false); return; }
        if (busy || quitting) return;
        var dialog = new RecorderWindow(Settings) { Owner = owner is { IsVisible: true } ? owner : null };
        if (dialog.Owner == null) dialog.WindowStartupLocation = WindowStartupLocation.CenterScreen;
        if (dialog.ShowDialog() != true) return;
        Settings.RecordingArea = dialog.Area; Settings.RecordingFramesPerSecond = dialog.FramesPerSecond; Settings.RecordMousePointer = dialog.MousePointer; Settings.RecordMouseClicks = dialog.MouseClicks; Settings.Save();
        _ = StartRecordingAsync(dialog.Area);
    }
    internal async Task StartRecordingAsync(RecordingArea area)
    {
        if (busy || quitting || disposed || recorder != null) return;
        if (editor is { CanTakeCapture: false }) { Notify("The editor is busy. Try again in a moment."); return; }
        busy = true; bar?.SetBusy(true);
        var hidden = HideOwnWindows();
        string? path = null;
        try
        {
            await Task.Delay(hidden.Count > 0 ? 250 : 40);
            Drawing.Rectangle? chosen;
            using (new ScreenCapture.DpiScope())
            {
                var cursorAt = ScreenCapture.CursorPosition;
                chosen = area switch
                {
                    RecordingArea.FullScreen => ScreenCapture.MonitorAt(cursorAt),
                    RecordingArea.FullScreenWithoutTaskbar => ScreenCapture.MonitorAt(cursorAt, true),
                    RecordingArea.Window => Select(SelectionKind.Window, "Click the window to record. Esc or right-click cancels."),
                    _ => Select(SelectionKind.Rectangle, "Drag round the area to record. Esc or right-click cancels."),
                };
            }
            if (chosen is not { } picked) { RestoreOwnWindows(hidden); return; }
            var region = Drawing.Rectangle.Intersect(picked, ScreenCapture.VirtualScreen);
            region = ScreenCapture.EvenSize(region);
            if (region.Width < 16 || region.Height < 16) throw new InvalidOperationException("The area is too small to record.");
            path = store.NewFile("CAPTURE", ".mp4");
            using (new ScreenCapture.DpiScope())
            {
                recordingBorder = new RecordingBorder(region); recordingBorder.Show();
                var controls = new RecordingBar(region, Settings.RecordingShortcut);
                recordingBar = controls;
                controls.PauseToggled += (_, _) => TogglePause();
                controls.StopRequested += (_, _) => StopRecording(false);
                controls.DiscardRequested += (_, _) =>
                {
                    if (ThemedMessage.Show("Discard this recording? TRT wipes it.", "Discard Recording", MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes) StopRecording(true);
                };
                controls.Show();
            }
            if (!recordingBorder.CaptureExcluded || !recordingBar.CaptureExcluded)
                throw new InvalidOperationException("Windows could not keep the recording border and controls out of the video, so recording did not start.");
            discardRecording = false;
            recorder = new ScreenRecorder(FFmpeg, path, region, Settings.RecordingFramesPerSecond, Settings.RecordMousePointer) { ShowClicks = Settings.RecordMouseClicks };
            recorder.Start();
            hiddenForRecording = hidden;
            if (stopItem != null) stopItem.Visible = true;
            if (tray != null) tray.Text = "TinyRedactionTool: recording";
            recordingClock = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(250) };
            recordingClock.Tick += (_, _) => { if (recorder != null) { recordingBar?.SetElapsed(recorder.Elapsed); if (recorder.Completion.IsCompleted) FinishRecording(); } };
            recordingClock.Start();
        }
        catch (Exception ex) when (ex is not OutOfMemoryException)
        {
            CloseRecordingWindows();
            recorder?.Dispose(); recorder = null;
            if (path != null) try { store.Wipe(path); } catch (IOException) { }
            RestoreOwnWindows(hidden);
            ShowError("Screen Recording", ex.Message);
        }
        finally { busy = false; bar?.SetBusy(false); }
    }
    private Drawing.Rectangle? Select(SelectionKind kind, string hint)
    {
        var screen = ScreenCapture.VirtualScreen;
        using var desktop = ScreenCapture.Grab(screen, false);
        using var overlay = new CaptureOverlay(desktop, screen, kind, kind == SelectionKind.Window ? ScreenCapture.VisibleWindows() : null, hint);
        return overlay.ShowDialog() == Forms.DialogResult.OK ? overlay.SelectedRegion : null;
    }
    private void TogglePause()
    {
        if (recorder == null) return;
        if (recorder.IsPaused) recorder.Resume(); else recorder.Pause();
        recordingBar?.SetPaused(recorder.IsPaused); recordingBorder?.SetPaused(recorder.IsPaused);
    }
    internal void StopRecording(bool discard)
    {
        if (recorder == null) return;
        discardRecording |= discard;
        recordingBar?.Finishing();
        if (tray != null) tray.Text = "TinyRedactionTool: finishing the recording";
        recorder.RequestStop();
    }
    private void CloseRecordingWindows()
    {
        recordingClock?.Stop(); recordingClock = null;
        recordingBorder?.Close(); recordingBorder?.Dispose(); recordingBorder = null;
        recordingBar?.Close(); recordingBar?.Dispose(); recordingBar = null;
    }
    private async void FinishRecording()
    {
        if (recorder is not { } finished) return;
        recorder = null;
        CloseRecordingWindows();
        var error = finished.Error; var frames = finished.FrameCount; var path = finished.OutputPath;
        finished.Dispose();
        if (stopItem != null) stopItem.Visible = false;
        if (tray != null) tray.Text = "TinyRedactionTool";
        RestoreOwnWindows(hiddenForRecording);
        if (discardRecording || quitting || error.Length > 0 || frames == 0 || !File.Exists(path))
        {
            try { if (store.Owns(path)) store.Wipe(path); } catch (IOException) { }
            if (quitting) return;
            if (discardRecording) Notify("Recording discarded and wiped.");
            else ShowError("Screen Recording", "The recording failed. " + error);
            return;
        }
        try { await OpenInEditorAsync(path); }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { ShowError("Screen Recording", ex.Message); }
    }

    // ---- Leftovers from a session that did not close normally ----
    private void OfferAbandonedCleanup()
    {
        var folders = CaptureStore.AbandonedFolders(temporaryFolder);
        if (folders.Count == 0) return;
        var count = folders.Sum(f => { try { return Directory.GetFiles(f).Count(n => !n.EndsWith(".session.lock", StringComparison.Ordinal)); } catch (IOException) { return 0; } });
        if (ThemedMessage.Show(bar!, $"TRT found {count} unredacted capture file(s) left from a session that didn't close properly, in:\n{temporaryFolder}\n\nWipe them now? (No keeps them; TRT asks again next time.)",
            "Leftover Captures", MessageBoxButton.YesNo, MessageBoxImage.Question) != MessageBoxResult.Yes) return;
        var failed = 0;
        foreach (var folder in folders) { try { CaptureStore.WipeAbandoned(folder); } catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { failed++; } }
        if (failed > 0) ShowError("Leftover Captures", "Some leftover captures couldn't be wiped. TRT will ask again next time.");
    }

    // ---- Remove History (0.28.0, David: on demand, since TRT stays in the notification area) ----
    // Wipes every capture and working copy that no editor is showing (including the copies Undo could go back to, so
    // each editor's Undo list is cleared), leftovers from a session that didn't close properly and leftover export
    // scratch folders; forgets the last save folder and Windows' memory of the folders TRT's Open and Save boxes used.
    // What an editor still shows stays until it is closed, as before. Returns what was done, in plain words.
    private void TrayThemeChanged(bool dark) { if (trayMenu != null) WindowTheme.Apply(trayMenu, dark); }
    // From the capture bar's menu or the notification-area menu: ask, then say what was done.
    internal void AskRemoveHistory(Window? owner)
    {
        if (ThemedMessage.Show(owner, "Wipe TRT's old captures and working copies, clear Undo, and forget the folders TRT last used?\n\nWhat is open in the editor stays. Files you saved or exported are not touched.",
                "Remove History", MessageBoxButton.YesNo, MessageBoxImage.Question) != MessageBoxResult.Yes) return;
        var text = RemoveHistory();
        ThemedMessage.Show(owner, text, "Remove History", MessageBoxButton.OK, MessageBoxImage.Information);
    }
    internal string RemoveHistory()
    {
        if (busy || recorder != null || AllEditors.Any(e => !e.CanTakeCapture)) return "Finish the current work first, then try again.";
        foreach (var open in AllEditors) open.ForgetUndoHistory();
        var shown = AllEditors.Select(e => e.ShownMediaPath).Where(p => p != null).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var wiped = 0; var failed = 0;
        foreach (var file in store.Files.ToList())
        {
            if (shown.Contains(file)) continue;
            try { store.Wipe(file); wiped++; } catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { failed++; }
        }
        foreach (var folder in CaptureStore.AbandonedFolders(temporaryFolder))
            try { wiped += CaptureStore.WipeAbandoned(folder); } catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { failed++; }
        wiped += VideoExport.RemoveLeftoverScratch(temporaryFolder);
        Settings.LastSaveFolder = null; Settings.Save();
        var forgotten = 0;
        if (DialogMemory.OwnProgramName() is { } program) try { forgotten = DialogMemory.Forget(program); } catch (Exception ex) when (ex is UnauthorizedAccessException or IOException or System.Security.SecurityException) { }
        var text = wiped == 0 ? "There were no old captures or working copies to wipe." : $"Wiped {wiped} old capture or working file{(wiped == 1 ? "" : "s")}.";
        if (shown.Count > 0) text += " What is open in the editor stays until you close it.";
        text += forgotten > 0 ? " The last save folder and the folders the Open and Save boxes remembered are forgotten." : " The last save folder is forgotten.";
        if (failed > 0) text += $" {failed} file{(failed == 1 ? "" : "s")} could not be wiped yet (still in use); TRT wipes {(failed == 1 ? "it" : "them")} when it quits.";
        return text;
    }

    // ---- Quitting ----
    internal void Quit()
    {
        if (quitting || disposed) return;
        if (busy) { Notify("Finish the current capture first."); return; }
        if (recorder != null)
        {
            if (ThemedMessage.Show("You are recording. Discard it and quit?", "Quit TRT", MessageBoxButton.YesNo, MessageBoxImage.Warning) != MessageBoxResult.Yes) return;
            discardRecording = true; recorder.RequestStop(); recorder.Completion.Wait(TimeSpan.FromSeconds(65)); FinishRecording();
        }
        foreach (var other in otherEditors.ToList()) { other.Close(); if (otherEditors.Contains(other)) return; } // It asked and the user kept it open.
        while (editor is { } main) { main.Close(); if (editor == main) return; }
        quitting = true;
        var failed = store.WipeAll();
        if (failed.Count > 0) ShowError("Quit", "TRT could not wipe these captures. Please delete them yourself:\n" + string.Join("\n", failed));
        Settings.Save();
        Dispose();
        Application.Current?.Shutdown();
    }
    // Windows is signing out or shutting down: no questions, wipe what can be wiped.
    internal void EndSession()
    {
        quitting = true;
        try { recorder?.Dispose(); } catch (Exception ex) when (ex is InvalidOperationException or IOException) { }
        store.WipeAll();
    }
    public void Dispose()
    {
        if (disposed) return;
        disposed = true; quitting = true;
        UnregisterHotkeys(); hotkeyWindow?.RemoveHook(HotkeyHook);
        foreground?.Dispose();
        CloseRecordingWindows(); recorder?.Dispose(); recorder = null;
        if (tray != null) { tray.Visible = false; tray.Dispose(); }
        MainWindow.ThemeApplied -= TrayThemeChanged; trayMenu?.Dispose();
        dockWatch?.Stop(); slideTimer?.Stop();
        strip?.Close(); ruler?.Close();
        bar?.Close();
        store.Dispose(); tools.Dispose();
    }

    [DllImport("user32.dll", SetLastError = true)] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool RegisterHotKey(IntPtr window, int id, uint modifiers, uint key);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool UnregisterHotKey(IntPtr window, int id);
}
