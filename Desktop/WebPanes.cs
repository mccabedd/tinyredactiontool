using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Automation;
using Drawing = System.Drawing;

namespace TinyRedaction.Desktop;

// The panes of a web page (0.22.3, David: highlight each pane in red before clicking).
// A browser draws its whole page in one window, so its panes are not windows TRT can list. Instead TRT asks the browser
// (UI Automation) for the page area and the page's tall columns, such as a code site's file list and text. When a page
// names no columns, long lines down the page in the frozen screenshot divide it (a two-pane viewer).
internal static class WebPanes
{
    // The two window classes that web browsers draw their pages in.
    public static bool IsBrowser(IntPtr window)
    {
        var name = new StringBuilder(64); GetClassName(window, name, name.Capacity);
        return name.ToString() is "Chrome_WidgetWin_1" or "MozillaWindowClass";
    }

    // The panes of the page in this window, in screen pixels; empty when the page can't be found. Takes up to a
    // second the first time (the browser switches its accessibility on), so run it off the UI thread.
    public static List<Drawing.Rectangle> Scan(IntPtr window, Func<Drawing.Rectangle, Drawing.Bitmap?>? picture = null)
    {
        using var dpi = new ScreenCapture.DpiScope();
        var panes = new List<Drawing.Rectangle>();
        try
        {
            if (Page(window) is not { } page) return panes;
            var area = Box(page);
            if (area.Width < 64 || area.Height < 64) return panes;
            var columns = new List<Drawing.Rectangle>();
            Columns(page, area, columns, depth: 0);
            panes.Add(area); panes.AddRange(SideBySide(columns));
            if (panes.Count == 1 && picture?.Invoke(area) is { } shot) using (shot) panes.AddRange(Dividers(shot, area));
        }
        catch (Exception exception) when (exception is ElementNotAvailableException or COMException or InvalidOperationException or TimeoutException) { }
        return panes;
    }

    // The page itself: the Document element in the window (the browser's own bars are outside it). The browser may
    // build its accessibility tree on the first request, so look twice.
    private static AutomationElement? Page(IntPtr window)
    {
        var root = AutomationElement.FromHandle(window);
        var document = new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Document);
        for (var attempt = 0; attempt < 2; attempt++)
        {
            if (root.FindFirst(TreeScope.Descendants, document) is { } found && found.Current.BoundingRectangle is { IsEmpty: false, Width: > 64 }) return found;
            Thread.Sleep(250);
        }
        return null;
    }
    private static Drawing.Rectangle Box(AutomationElement element)
    {
        var r = element.Current.BoundingRectangle;
        return r.IsEmpty ? Drawing.Rectangle.Empty : Drawing.Rectangle.FromLTRB((int)Math.Round(r.Left), (int)Math.Round(r.Top), (int)Math.Round(r.Right), (int)Math.Round(r.Bottom));
    }

    // Tall parts of the page narrower than the page (a column), searched from the page down; within a column, its own
    // columns too (a text pane beside an outline). A column reaches the page's full height on screen: it scrolls
    // through all of it.
    private const int MaxDepth = 10;
    private static void Columns(AutomationElement parent, Drawing.Rectangle page, List<Drawing.Rectangle> panes, int depth)
    {
        if (depth > MaxDepth || panes.Count > 24) return;
        var walker = TreeWalker.ControlViewWalker;
        var parentBox = Drawing.Rectangle.Intersect(Box(parent), page);
        for (var child = walker.GetFirstChild(parent); child != null; child = walker.GetNextSibling(child))
        {
            var box = Drawing.Rectangle.Intersect(Box(child), page);
            if (box.Height < page.Height * 3 / 10 || box.Width < 120) continue;  // Too short or thin to be a pane: skip it and what is in it.
            if (box.Width <= parentBox.Width * 9 / 10)
            {
                var pane = new Drawing.Rectangle(box.X, page.Y, box.Width, page.Height);
                if (!panes.Contains(pane)) panes.Add(pane);
            }
            Columns(child, page, panes, depth + 1);
        }
    }

    // Panes come side by side: a column alone (a page's main column beside short boxes) scrolls with the whole page,
    // so it isn't one. A column inside a pane is its own pane only when much narrower (an outline beside the text, not
    // the file list's tree inside the file pane).
    internal static List<Drawing.Rectangle> SideBySide(List<Drawing.Rectangle> columns)
    {
        var paired = columns.Where(c => columns.Any(o => o != c && (Math.Abs(o.Left - c.Right) <= 24 || Math.Abs(c.Left - o.Right) <= 24))).ToList();
        return paired.Where(c => !paired.Any(o => o != c && o.Contains(c) && c.Width * 10 > o.Width * 6)).ToList();
    }

    // Long lines down the page divide it into panes when the page names none: a line of pixels that differ from their
    // neighbour on the left through at least three quarters of the page's height.
    internal static IEnumerable<Drawing.Rectangle> Dividers(Drawing.Bitmap shot, Drawing.Rectangle page)
    {
        var w = shot.Width; var h = shot.Height;
        var data = shot.LockBits(new(0, 0, w, h), Drawing.Imaging.ImageLockMode.ReadOnly, Drawing.Imaging.PixelFormat.Format32bppRgb);
        var pixels = new int[w * h];
        try { for (var y = 0; y < h; y++) Marshal.Copy(data.Scan0 + y * data.Stride, pixels, y * w, w); }
        finally { shot.UnlockBits(data); }
        static bool Differ(int p, int q) => Math.Abs((p & 0xFF) - (q & 0xFF)) + Math.Abs((p >> 8 & 0xFF) - (q >> 8 & 0xFF)) + Math.Abs((p >> 16 & 0xFF) - (q >> 16 & 0xFF)) > 24;
        var lines = new List<int>();
        for (var x = 1; x < w; x++)
        {
            int run = 0, best = 0;
            for (var y = 0; y < h; y++) { if (Differ(pixels[y * w + x], pixels[y * w + x - 1])) { if (++run > best) best = run; } else run = 0; }
            if (best * 4 >= h * 3) lines.Add(x);
        }
        // A thick divider has a line on each side; panes narrower than 120 pixels (a scroll bar) are not panes.
        var edges = new List<int> { 0 };
        foreach (var x in lines) if (x - edges[^1] >= 120 && w - x >= 120) edges.Add(x);
        edges.Add(w);
        if (edges.Count < 3) yield break;
        for (var i = 0; i + 1 < edges.Count; i++) yield return new(page.X + edges[i], page.Y, edges[i + 1] - edges[i], page.Height);
    }

    // The pane under the point: the narrowest one holding it (the page itself when no column does).
    public static Drawing.Rectangle? At(IReadOnlyList<Drawing.Rectangle> panes, Drawing.Point point)
    {
        Drawing.Rectangle? best = null;
        foreach (var pane in panes) if (pane.Contains(point) && (best == null || (long)pane.Width * pane.Height < (long)best.Value.Width * best.Value.Height)) best = pane;
        return best;
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern int GetClassName(IntPtr window, StringBuilder name, int capacity);
}
