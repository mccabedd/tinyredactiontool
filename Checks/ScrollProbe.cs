using System.IO;
using TinyRedaction.Desktop;
using Drawing = System.Drawing;

// Diagnostic, not a check (0.22.0): runs the real scrolling capture on a screen area (a browser window
// opened for the purpose) and saves the joined picture. Run with --scroll-probe <left> <top> <width> <height> <out.png> [<x> <y>].
internal static class ScrollProbe
{
    // One wheel step, then pictures every 50 ms: when does the page settle, how far did it move, and do rows match exactly?
    public static async Task Diagnose(string[] a)
    {
        int N(int i) => int.Parse(a[i], System.Globalization.CultureInfo.InvariantCulture);
        var area = new Drawing.Rectangle(N(0), N(1), N(2), N(3));
        using (new ScreenCapture.DpiScope()) ScrollingCapture.SetCursorPos(area.X + area.Width / 2, area.Y + area.Height / 2);
        await Task.Delay(300);
        using var before = ScreenCapture.Grab(area, false);
        var clock = System.Diagnostics.Stopwatch.StartNew(); ScrollingCapture.Wheel(-240);
        var shots = new List<(long Ms, Drawing.Bitmap Shot)>();
        while (clock.ElapsedMilliseconds < 1500) { await Task.Delay(50); shots.Add((clock.ElapsedMilliseconds, ScreenCapture.Grab(area, false))); }
        var rb = ScrollingCapture.Rows(before);
        foreach (var (ms, shot) in shots)
        {
            var rs = ScrollingCapture.Rows(shot); var same = rb.Zip(rs).Count(p => p.First == p.Second);
            // Best exact shift by row hashes.
            var best = 0; var bestScore = 0.0;
            for (var s = 1; s < rb.Length - 8; s++) { var m = 0; for (var y = 0; y < rb.Length - s; y++) if (rs[y] == rb[y + s]) m++; var score = m / (double)(rb.Length - s); if (score > bestScore) { bestScore = score; best = s; } }
            Console.WriteLine($"{ms,5} ms: rows unchanged {same}/{rb.Length}, best exact shift {best} px matching {bestScore:P0}");
        }
        before.Save(a[4] + "-before.png"); shots[^1].Shot.Save(a[4] + "-after.png");
        foreach (var (_, shot) in shots) shot.Dispose();
    }
    public static async Task Run(string[] a)
    {
        int N(int i) => int.Parse(a[i], System.Globalization.CultureInfo.InvariantCulture);
        var area = new Drawing.Rectangle(N(0), N(1), N(2), N(3));
        var timer = System.Diagnostics.Stopwatch.StartNew(); ScrollingCapture.KeepFailedPair = true;
        Drawing.Point? at = a.Length >= 7 ? new(N(5), N(6)) : null; // Optional scroll point (0.22.2: the pane to scroll).
        using var joined = await ScrollingCapture.RunAsync(area, ScrollingCapture.EscapePressed, scrollAt: at);
        joined.Save(a[4], Drawing.Imaging.ImageFormat.Png);
        Console.WriteLine($"scrolling capture: {joined.Width} x {joined.Height} (area {area.Height} high) in {timer.ElapsedMilliseconds} ms; steps {ScrollingCapture.LastSteps}"); foreach (var line in ScrollingCapture.LastLog) Console.WriteLine(line);
        if (ScrollingCapture.FailedPair is var (p, n)) { p.Save(a[4] + "-prev.png"); n.Save(a[4] + "-next.png"); }
        if (ScrollingCapture.FirstPair is var (f, s)) { f.Save(a[4] + "-first0.png"); s.Save(a[4] + "-first1.png"); }
    }
    // --web-panes <x> <y>: the panes TRT outlines in the browser window at a point (0.22.3), run twice (the first run
    // switches the browser's accessibility on).
    public static void WebPanesAt(string[] a)
    {
        int N(int i) => int.Parse(a[i], System.Globalization.CultureInfo.InvariantCulture);
        var point = new Drawing.Point(N(0), N(1));
        var window = ScreenCapture.VisibleWindows().FirstOrDefault(w => w.Bounds.Contains(point));
        if (window == null) { Console.WriteLine("no window there"); return; }
        Console.WriteLine($"window {window.Bounds}, browser {WebPanes.IsBrowser(window.Handle)}");
        for (var run = 1; run <= 2; run++)
        {
            var clock = System.Diagnostics.Stopwatch.StartNew();
            var panes = WebPanes.Scan(window.Handle, area => ScreenCapture.Grab(area, false));
            Console.WriteLine($"run {run}: {clock.ElapsedMilliseconds} ms, panes {string.Join(" ", panes)}; at the point {WebPanes.At(panes, point)}");
        }
    }
    // --overlay-panes <x> <y> ...: what the scrolling capture picker outlines at each point, without showing it (0.22.3).
    public static void OverlayPanes(string[] a)
    {
        int N(int i) => int.Parse(a[i], System.Globalization.CultureInfo.InvariantCulture);
        using var dpi = new ScreenCapture.DpiScope();
        var screen = ScreenCapture.VirtualScreen;
        using var desktop = ScreenCapture.Grab(screen, false);
        using var overlay = new CaptureOverlay(desktop, screen, SelectionKind.Object, ScreenCapture.VisibleWindows(), "probe") { FindWebPanes = true };
        _ = overlay.Handle;
        for (var i = 0; i + 1 < a.Length; i += 2)
        {
            var point = new Drawing.Point(N(i), N(i + 1));
            overlay.Track(new(point.X - screen.X, point.Y - screen.Y));
            var first = overlay.Highlighted; var clock = System.Diagnostics.Stopwatch.StartNew();
            while (clock.ElapsedMilliseconds < 3000) { System.Windows.Forms.Application.DoEvents(); Thread.Sleep(20); }
            Console.WriteLine($"{point}: at once {first}, after the scan {overlay.Highlighted}");
        }
    }
    // --pane-probe <before.png> <after.png> <x> <y>: how the pane around a point is judged (0.22.2).
    public static void Pane(string[] a)
    {
        int N(int i) => int.Parse(a[i], System.Globalization.CultureInfo.InvariantCulture);
        using var before = new Drawing.Bitmap(a[0]); using var after = new Drawing.Bitmap(a[1]);
        ScrollingCapture.PaneTrace = Console.WriteLine; if (a.Length > 4) ScrollingCapture.DebugShift = N(4);
        var pane = ScrollingCapture.MovingPane(before, after, new(N(2), N(3)));
        Console.WriteLine($"pane {pane}; whole picture shift {ScrollingCapture.FindShift(before, after, 0, 0)}");
        if (pane is not { } p) return;
        Console.WriteLine($"page above the pane: {ScrollingCapture.PageAbove(before, after, p)} rows");
        using var a2 = ScreenCapture.Crop(before, p); using var b2 = ScreenCapture.Crop(after, p);
        var (header, footer) = ScrollingCapture.Margins(a2, b2);
        Console.WriteLine($"in the pane: header {header}, footer {footer}, shift {ScrollingCapture.FindShift(a2, b2, header, footer)}, without margins {ScrollingCapture.FindShift(a2, b2, 0, 0)}");
    }
}
