using System.Runtime.InteropServices;
using Drawing = System.Drawing;
using DrawingImaging = System.Drawing.Imaging;

namespace TinyRedaction.Desktop;

// Scrolling window capture (0.13.0): TRT scrolls the chosen window or panel down
// with the mouse wheel, grabbing a picture after each step, and joins the pictures where they
// overlap. Rows that stay put at the top and bottom (a fixed header or footer) appear once.
// It stops at the end of the content, at the size limit, or when Esc is pressed.
internal static class ScrollingCapture
{
    internal const int MaxHeight = 20000, MaxSteps = 120, ScrollbarMargin = 24;
    internal static readonly List<string> LastLog = [];
    internal static bool KeepFailedPair; internal static (Drawing.Bitmap, Drawing.Bitmap)? FailedPair, FirstPair; // Diagnostics only.
    internal static Action<string>? PaneTrace; internal static int DebugShift; // Diagnostics only: how MovingPane and FindShift judged.
    internal static int LastSteps { get; private set; } // Pictures joined by the last run (diagnostics).

    public static async Task<Drawing.Bitmap> RunAsync(Drawing.Rectangle area, Func<bool> stopRequested, int settleMilliseconds = 280, Drawing.Point? scrollAt = null)
    {
        var frames = new List<Drawing.Bitmap>(); Drawing.Bitmap? above = null; LastLog.Clear();
        var cursor = ScreenCapture.CursorPosition;
        var at = scrollAt ?? new(area.X + area.Width / 2, area.Y + area.Height / 2);
        var park = ParkingSpot(at);
        LastLog.Add($"scroll at {at}, pointer waits at {(park is { } spot ? spot.ToString() : "the scroll point")}");
        try
        {
            using (new ScreenCapture.DpiScope()) SetCursorPos((park ?? at).X, (park ?? at).Y);
            await Task.Delay(park == null ? 120 : 250);
            frames.Add(ScreenCapture.Grab(area, false));
            var height = area.Height;
            for (var step = 0; step < MaxSteps && height < MaxHeight && !stopRequested(); step++)
            {
                // 0.22.0 (David: web pages stopped after one picture): a browser can miss the first wheel
                // turn while it takes focus, and a heavy page starts moving late and glides. So wait until
                // the page has moved and come to rest, and turn the wheel once more before deciding the
                // end is reached. (Probed with a test page in a browser.)
                var next = await ScrollAndSettleAsync(area, at, park, frames[^1], settleMilliseconds, stopRequested)
                    ?? await ScrollAndSettleAsync(area, at, park, frames[^1], settleMilliseconds, stopRequested);
                if (next == null) break;
                // 0.22.1 (David): only the page content, not the browser's tabs, address and bookmark bars or
                // side bars. After the first scroll, keep just the part of the window that moved; everything
                // that stayed still is left out from then on. (A fixed side bar also stopped the joining: its
                // rows never lined up.) 0.22.2: just the pane that moved with the scroll point.
                if (frames.Count == 1 && KeepFailedPair) { FirstPair?.Item1.Dispose(); FirstPair?.Item2.Dispose(); FirstPair = ((Drawing.Bitmap)frames[0].Clone(), (Drawing.Bitmap)next.Clone()); }
                if (frames.Count == 1 && MovingPane(frames[0], next, new(at.X - area.X, at.Y - area.Y)) is { } moved && moved.Size != frames[0].Size)
                {
                    LastLog.Add($"content {moved}");
                    // The top of the page above the pane in the first picture (a code site's file bar covers it once
                    // scrolled) is kept, up to the browser's own bars: rows that look exactly the same after the scroll.
                    var lead = PageAbove(frames[0], next, moved);
                    if (lead > 0) { above?.Dispose(); above = ScreenCapture.Crop(frames[0], new(moved.X, moved.Y - lead, moved.Width, lead)); LastLog.Add($"page above the pane: {lead} rows"); }
                    var first = ScreenCapture.Crop(frames[0], moved); frames[0].Dispose(); frames[0] = first;
                    var cropped = ScreenCapture.Crop(next, moved); next.Dispose(); next = cropped;
                    area = new(area.X + moved.X, area.Y + moved.Y, moved.Width, moved.Height); height = area.Height;
                }
                var (header, footer) = Margins(frames[0], frames.Count > 1 ? frames[1] : next);
                var shift = FindShift(frames[^1], next, header, footer);
                LastLog.Add($"step {step}: header {header}, footer {footer}, shift {shift}");
                if (shift <= 0) { if (KeepFailedPair) { FailedPair?.Item1.Dispose(); FailedPair?.Item2.Dispose(); FailedPair = ((Drawing.Bitmap)frames[^1].Clone(), (Drawing.Bitmap)next.Clone()); } next.Dispose(); break; }
                frames.Add(next); height += shift;
            }
            LastSteps = frames.Count;
            var joined = Stitch(frames);
            if (above == null) return joined;
            using (joined) return Stack(above, joined);
        }
        finally
        {
            foreach (var frame in frames) frame.Dispose();
            above?.Dispose();
            using (new ScreenCapture.DpiScope()) SetCursorPos(cursor.X, cursor.Y);
        }
    }

    // The part of the picture that changed with the scroll: the columns that changed in at least a quarter of the
    // rows (so a scroll bar's moving thumb doesn't count) and the rows between the first and last that changed in
    // those columns. Null when too little moved to tell.
    internal const int MinContentSize = 48;
    internal static Drawing.Rectangle? MovingPart(Drawing.Bitmap before, Drawing.Bitmap after)
    {
        if (before.Size != after.Size) return null;
        var w = before.Width; var h = before.Height;
        var a = Pixels(before); var b = Pixels(after);
        var columnChanges = new int[w];
        for (var y = 0; y < h; y++) for (var x = 0; x < w; x++) if (((a[y * w + x] ^ b[y * w + x]) & 0xFFFFFF) != 0) columnChanges[x]++;
        int left = 0, right = w - 1;
        while (left < w && columnChanges[left] < h / 4) left++;
        while (right > left && columnChanges[right] < h / 4) right--;
        if (right - left + 1 < MinContentSize) return null;
        int top = 0, bottom = h - 1;
        bool RowChanged(int y) { for (var x = left; x <= right; x++) if (((a[y * w + x] ^ b[y * w + x]) & 0xFFFFFF) != 0) return true; return false; }
        while (top < h && !RowChanged(top)) top++;
        while (bottom > top && !RowChanged(bottom)) bottom--;
        if (bottom - top + 1 < MinContentSize) return null;
        // Widen over the page's own margins and the space beside short lines (longer lines may come further down)
        // up to the first bar: a line of pixels whose marks (anything but the page colour) mostly stay put.
        var counts = new Dictionary<int, int>();
        for (var y = top; y <= bottom; y += 2) for (var x = left; x <= right; x += 2) { var p = b[y * w + x] & 0xFFFFFF; counts[p] = counts.GetValueOrDefault(p) + 1; }
        var page = counts.MaxBy(pair => pair.Value).Key;
        bool Bar(int from, int to, Func<int, int> at)
        {
            int marks = 0, still = 0;
            for (var i = from; i <= to; i++)
            {
                var k = at(i); int p = a[k] & 0xFFFFFF, q = b[k] & 0xFFFFFF;
                if (p == page && q == page) continue;
                marks++; if (p == q) still++;
            }
            return still * 2 > marks;
        }
        while (left > 0 && !Bar(top, bottom, y => y * w + left - 1)) left--;
        while (right < w - 1 && !Bar(top, bottom, y => y * w + right + 1)) right++;
        while (top > 0 && !Bar(left, right, x => (top - 1) * w + x)) top--;
        while (bottom < h - 1 && !Bar(left, right, x => (bottom + 1) * w + x)) bottom++;
        return new(left, top, right - left + 1, bottom - top + 1);
    }
    // 0.22.2 (David: a choice of pane; a code site's file pane slides by a different amount than the page): the pane is
    // the block around the scroll point whose content moved by the same amount as at the point. Still bars, other
    // panes and anything that moved differently are left out. MovingPart when the point's movement can't be told.
    internal static Drawing.Rectangle? MovingPane(Drawing.Bitmap before, Drawing.Bitmap after, Drawing.Point at)
    {
        if (before.Size != after.Size) return null;
        var w = before.Width; var h = before.Height;
        at = new(Math.Clamp(at.X, 0, w - 1), Math.Clamp(at.Y, 0, h - 1));
        // How far it moved: on the whole picture (still parts don't count), or, when another pane slid by a different
        // amount, on a band of columns around the point.
        // Narrower bands when a wide one still takes in part of the other pane.
        int bandLeft = 0, bandRight = w - 1;
        var shift = FindShift(before, after, 0, 0);
        foreach (var half in (int[])[160, 60, 30])
        {
            if (shift > 0) break;
            bandLeft = Math.Max(0, at.X - half); bandRight = Math.Min(w - 1, at.X + half);
            using var bandBefore = ScreenCapture.Crop(before, new(bandLeft, 0, bandRight - bandLeft + 1, h));
            using var bandAfter = ScreenCapture.Crop(after, new(bandLeft, 0, bandRight - bandLeft + 1, h));
            shift = FindShift(bandBefore, bandAfter, 0, 0);
        }
        if (shift <= 0 || shift >= h - MinContentSize) return MovingPart(before, after);
        var a = Pixels(before); var b = Pixels(after);
        // Colours this close count as the same (a page moved by part of a pixel draws its text a little differently).
        static bool Same(int p, int q) => Math.Abs((p & 0xFF) - (q & 0xFF)) <= 24 && Math.Abs((p >> 8 & 0xFF) - (q >> 8 & 0xFF)) <= 24 && Math.Abs((p >> 16 & 0xFF) - (q >> 16 & 0xFF)) <= 24;
        // Only pixels at an edge (text, lines, icons) tell anything: a flat bar can look the same as a flat part of the
        // page further down (a code site's grey file bar and its grey table rows).
        var edge = new bool[w * h];
        for (var y = 0; y < h; y++) for (var x = 1; x < w; x++) if (!Same(b[y * w + x], b[y * w + x - 1])) edge[y * w + x] = edge[y * w + x - 1] = true;
        // +1: moved with the point; 0: too few pixels to tell (plain page, an even scroll track: the same moved or not);
        // -1: it didn't (a bar, another pane, a scroll bar's handle appearing).
        int Moved(int x0, int x1, int y0, int y1)
        {
            int marks = 0, hits = 0;
            for (var y = y0; y <= y1; y++)
                for (var x = x0; x <= x1; x++)
                {
                    if (!edge[y * w + x]) continue;
                    int q = b[y * w + x]; bool moved = Same(a[(y + shift) * w + x], q), still = Same(a[y * w + x], q);
                    if (moved && still) continue;
                    marks++; if (moved) hits++;
                }
            return marks < 6 ? 0 : hits * 10 >= marks * 7 ? 1 : -1;
        }
        // The picture in 16-pixel tiles, each judged on all its pixels (one line alone is easily fooled). Tiles of new
        // content, below what was on screen before, can't be compared with anything.
        const int T = 16;
        int tw = (w + T - 1) / T, th = (h + T - 1) / T, oldRows = h - shift;
        var tile = new int[tw * th];
        for (var ty = 0; ty < th; ty++)
            for (var tx = 0; tx < tw; tx++)
                tile[ty * tw + tx] = ty * T >= oldRows ? 0 : Moved(tx * T, Math.Min(w, tx * T + T) - 1, ty * T, Math.Min(oldRows, ty * T + T) - 1);
        if (PaneTrace is { } trace)
        {
            trace($"shift {shift}, band {bandLeft}-{bandRight}");
            for (var ty = 0; ty < th; ty++) trace(string.Concat(Enumerable.Range(0, tw).Select(tx => ty * T >= oldRows ? 'n' : tile[ty * tw + tx] switch { 1 => '+', 0 => '.', _ => 'x' })));
        }
        // The pane: the moved tiles that reach each other (up to 4 tiles apart, over gaps between paragraphs), starting
        // with the one nearest the point.
        const int Reach = 4;
        int cx = at.X / T, cy = Math.Min(at.Y, oldRows - 1) / T, seed = -1, seedDistance = int.MaxValue;
        for (var ty = Math.Max(0, cy - Reach); ty <= Math.Min(th - 1, cy + Reach); ty++)
            for (var tx = Math.Max(0, cx - Reach); tx <= Math.Min(tw - 1, cx + Reach); tx++)
                if (tile[ty * tw + tx] > 0 && Math.Max(Math.Abs(tx - cx), Math.Abs(ty - cy)) < seedDistance) { seed = ty * tw + tx; seedDistance = Math.Max(Math.Abs(tx - cx), Math.Abs(ty - cy)); }
        if (seed < 0) return MovingPart(before, after);
        var inPane = new bool[tile.Length]; var queue = new Queue<int>(); inPane[seed] = true; queue.Enqueue(seed);
        int minX = tw, maxX = -1, minY = th, maxY = -1;
        while (queue.TryDequeue(out var t))
        {
            int tx = t % tw, ty = t / tw;
            minX = Math.Min(minX, tx); maxX = Math.Max(maxX, tx); minY = Math.Min(minY, ty); maxY = Math.Max(maxY, ty);
            for (var ny = Math.Max(0, ty - Reach); ny <= Math.Min(th - 1, ty + Reach); ny++)
                for (var nx = Math.Max(0, tx - Reach); nx <= Math.Min(tw - 1, tx + Reach); nx++)
                {
                    var n = ny * tw + nx;
                    if (!inPane[n] && tile[n] > 0) { inPane[n] = true; queue.Enqueue(n); }
                }
        }
        // A tile at an edge can move by chance (a line that looks the same further down): drop edge columns and rows of
        // tiles with as many that stayed put as moved.
        PaneTrace?.Invoke($"tiles that moved together: {minX}-{maxX} x {minY}-{maxY}");
        int Votes(int x0, int x1, int y0, int y1) { var sum = 0; for (var ty = y0; ty <= y1; ty++) for (var tx = x0; tx <= x1; tx++) sum += Math.Sign(tile[ty * tw + tx]); return sum; }
        for (var changed = true; changed;)
        {
            changed = false;
            if (maxX > minX && Votes(minX, minX, minY, maxY) <= 0) { minX++; changed = true; }
            if (maxX > minX && Votes(maxX, maxX, minY, maxY) <= 0) { maxX--; changed = true; }
            if (maxY > minY && Votes(minX, maxX, minY, minY) <= 0) { minY++; changed = true; }
            if (maxY > minY && Votes(minX, maxX, maxY, maxY) <= 0) { maxY--; changed = true; }
        }
        // A line of tiles that moved by chance can sit just outside a bar: within 6 tiles of each edge, cut after the
        // innermost line where more stayed put than moved, up to a line that clearly moved.
        static int Peel(int from, int step, int limit, Func<int, int> votes)
        {
            var cut = from;
            for (var i = 0; i < 6; i++)
            {
                var line = from + i * step;
                if (step > 0 ? line >= limit : line <= limit) break;
                var v = votes(line); if (v >= 3) break; if (v < 0) cut = line + step;
            }
            return cut;
        }
        minY = Peel(minY, 1, maxY, ty => Votes(minX, maxX, ty, ty)); maxY = Peel(maxY, -1, minY, ty => Votes(minX, maxX, ty, ty));
        minX = Peel(minX, 1, maxX, tx => Votes(tx, tx, minY, maxY)); maxX = Peel(maxX, -1, minX, tx => Votes(tx, tx, minY, maxY));
        // Widen over plain margins and more of the page (tile columns and rows where nothing stayed put, or far more
        // moved than stayed) up to the first bar or other pane. New content below belongs to the pane when the pane
        // reaches down that far.
        PaneTrace?.Invoke($"after the vote: {minX}-{maxX} x {minY}-{maxY}");
        bool Clear(int x0, int x1, int y0, int y1)
        {
            int moved = 0, still = 0;
            for (var ty = y0; ty <= y1; ty++) for (var tx = x0; tx <= x1; tx++) { var m = tile[ty * tw + tx]; if (m > 0) moved++; else if (m < 0) still++; }
            return moved > still * 2 || still == 0 && (x0 != x1 || !Divider(x0));
        }
        // A plain tile column with a line down nearly all the pane's height is a divider between panes (a line down
        // the page looks the same moved or not, so only its shape tells).
        bool Divider(int tx)
        {
            int y0 = minY * T, y1 = Math.Min(oldRows, maxY * T + T) - 1;
            for (var x = tx * T; x < Math.Min(w, tx * T + T); x++)
            {
                var lined = 0;
                for (var y = y0; y <= y1; y++) if (edge[y * w + x]) lined++;
                if (lined * 10 >= (y1 - y0 + 1) * 9) return true;
            }
            return false;
        }
        bool ColumnClear(int tx) => Clear(tx, tx, minY, maxY);
        bool RowClear(int ty) => Clear(minX, maxX, ty, ty);
        while (minX > 0 && ColumnClear(minX - 1)) minX--;
        while (maxX < tw - 1 && ColumnClear(maxX + 1)) maxX++;
        while (minY > 0 && RowClear(minY - 1)) minY--;
        while (maxY < th - 1 && (maxY + 1) * T < oldRows && RowClear(maxY + 1)) maxY++;
        int left = minX * T, right = Math.Min(w, maxX * T + T) - 1, top = minY * T, bottom = Math.Min(h, maxY * T + T) - 1;
        var lastOld = Math.Min(bottom, oldRows - 1);
        if ((maxY + 1 + Reach) * T >= oldRows) bottom = h - 1;
        // To the pixel: leave out the lines at each edge that stayed put (a divider, a scroll bar), within the edge tile.
        int ColumnMoved(int x) => Moved(x, x, top, lastOld);
        int RowMoved(int y) => y < oldRows ? Moved(left, right - Math.Min(ScrollbarMargin, (right - left) / 4), y, y) : 0;
        static int Trim(int from, int step, int span, Func<int, int> moved)
        {
            var edge = from;
            for (var i = 0; i < span; i++) { var m = moved(from + i * step); if (m > 0) break; if (m < 0) edge = from + (i + 1) * step; }
            return edge;
        }
        PaneTrace?.Invoke($"before trimming {left}-{right} x {top}-{bottom}; left edge columns: " + string.Concat(Enumerable.Range(left, Math.Min(T * 2, right - left)).Select(x => ColumnMoved(x) switch { > 0 => '+', 0 => '.', _ => 'x' })));
        // A line down nearly the whole pane near a side edge, with something beyond it that didn't move (the next pane's
        // scroll bar), is the divider from the next pane: cut there too. (With only plain margin beyond, it is the
        // pane's own border.)
        bool Lined(int x) { var lined = 0; for (var y = top; y <= lastOld; y++) if (edge[y * w + x]) lined++; return lined * 10 >= (lastOld - top + 1) * 9; }
        int Divide(int from, int step, int cut)
        {
            for (var i = T * 2 - 1; i >= 0; i--)
            {
                var x = from + i * step;
                if (x < 0 || x >= w || !Lined(x)) continue;
                for (var beyond = from; beyond != x; beyond += step) if (ColumnMoved(beyond) < 0) return step > 0 ? Math.Max(cut, x + 1) : Math.Min(cut, x - 1);
            }
            return cut;
        }
        if (lastOld > top)
        {
            left = Divide(left, 1, Trim(left, 1, T * 2, ColumnMoved)); right = Divide(right, -1, Trim(right, -1, T * 2, ColumnMoved));
            top = Trim(top, 1, T * 2, RowMoved); if (bottom < oldRows) bottom = Trim(bottom, -1, T * 2, RowMoved);
        }
        if (right - left + 1 < MinContentSize || bottom - top + 1 < MinContentSize) return MovingPart(before, after);
        return new(left, top, right - left + 1, bottom - top + 1);
    }

    // Rows of the first picture just above the pane that are page, not the browser's bars: going up from the pane,
    // up to the first row that has something on it and looks exactly the same after the scroll.
    internal static int PageAbove(Drawing.Bitmap before, Drawing.Bitmap after, Drawing.Rectangle pane)
    {
        var w = before.Width; var a = Pixels(before); var b = Pixels(after);
        var rows = 0;
        for (var y = pane.Y - 1; y >= 0; y--)
        {
            bool still = true, plain = true; var first = a[y * w + pane.X] & 0xFFFFFF;
            for (var x = pane.X; x < pane.Right; x++)
            {
                int p = a[y * w + x] & 0xFFFFFF, q = b[y * w + x] & 0xFFFFFF;
                if (p != q) still = false; if (p != first) plain = false;
            }
            if (still && !plain) break;
            rows++;
        }
        // Plain rows right under the bars are the browser's edge, not page.
        while (rows > 0) { var y = pane.Y - rows; var first = a[y * w + pane.X] & 0xFFFFFF; var plain = true; for (var x = pane.X; x < pane.Right && plain; x++) if ((a[y * w + x] & 0xFFFFFF) != first || (b[y * w + x] & 0xFFFFFF) != (a[y * w + x] & 0xFFFFFF)) plain = false; if (!plain) break; rows--; }
        return rows;
    }
    internal static Drawing.Bitmap Stack(Drawing.Bitmap top, Drawing.Bitmap bottom)
    {
        var result = new Drawing.Bitmap(bottom.Width, Math.Min(MaxHeight, top.Height + bottom.Height), DrawingImaging.PixelFormat.Format32bppRgb);
        using var g = Drawing.Graphics.FromImage(result);
        g.DrawImage(top, new Drawing.Rectangle(0, 0, top.Width, top.Height), new Drawing.Rectangle(0, 0, top.Width, top.Height), Drawing.GraphicsUnit.Pixel);
        g.DrawImage(bottom, new Drawing.Rectangle(0, top.Height, bottom.Width, bottom.Height), new Drawing.Rectangle(0, 0, bottom.Width, bottom.Height), Drawing.GraphicsUnit.Pixel);
        return result;
    }

    // 0.22.2 (David: web pages still failed): while the pointer rests on a page, links light up and the browser
    // shows the link's address in a corner, so the pictures differ in more than the scroll. The pointer only visits
    // the scroll point to turn the wheel and waits just outside that window (null when there is nowhere outside).
    private static Drawing.Point? ParkingSpot(Drawing.Point at)
    {
        using var scope = new ScreenCapture.DpiScope();
        var root = GetAncestor(WindowFromPoint(at), 2);
        if (root == IntPtr.Zero || !GetWindowRect(root, out var r)) return null;
        Drawing.Point[] spots = [new(r.Left - 6, at.Y), new(r.Right + 5, at.Y), new(at.X, r.Top - 6), new(at.X, r.Bottom + 5)];
        foreach (var spot in spots)
            if (MonitorFromPoint(spot, 0) != IntPtr.Zero && GetAncestor(WindowFromPoint(spot), 2) != root) return spot;
        return null;
    }
    private static int[] Pixels(Drawing.Bitmap bitmap)
    {
        var data = bitmap.LockBits(new(0, 0, bitmap.Width, bitmap.Height), DrawingImaging.ImageLockMode.ReadOnly, DrawingImaging.PixelFormat.Format32bppRgb);
        try
        {
            var result = new int[bitmap.Width * bitmap.Height];
            for (var y = 0; y < bitmap.Height; y++) Marshal.Copy(data.Scan0 + y * data.Stride, result, y * bitmap.Width, bitmap.Width);
            return result;
        }
        finally { bitmap.UnlockBits(data); }
    }

    internal const int SettleLimitMilliseconds = 1500, SettlePollMilliseconds = 70;
    // One wheel turn, then pictures every 70 ms until the content has moved and two pictures in a row are
    // the same (at rest); null when nothing moved within the limit.
    private static async Task<Drawing.Bitmap?> ScrollAndSettleAsync(Drawing.Rectangle area, Drawing.Point at, Drawing.Point? park, Drawing.Bitmap previous, int firstWait, Func<bool> stopRequested)
    {
        using (new ScreenCapture.DpiScope()) SetCursorPos(at.X, at.Y);
        Wheel(-240);
        if (park is { } spot) { await Task.Delay(40); using (new ScreenCapture.DpiScope()) SetCursorPos(spot.X, spot.Y); }
        var before = Rows(previous); var clock = System.Diagnostics.Stopwatch.StartNew();
        await Task.Delay(Math.Min(firstWait, 120));
        Drawing.Bitmap? last = null; ulong[]? lastRows = null;
        while (true)
        {
            var shot = ScreenCapture.Grab(area, false); var rows = Rows(shot);
            var moved = !rows.AsSpan().SequenceEqual(before);
            if (moved && lastRows != null && rows.AsSpan().SequenceEqual(lastRows)) { last?.Dispose(); return shot; } // At rest.
            last?.Dispose(); last = shot; lastRows = rows;
            if (clock.ElapsedMilliseconds >= SettleLimitMilliseconds || stopRequested())
            {
                if (moved) return last; // Still moving (an animation): use the latest picture.
                last.Dispose(); return null;
            }
            await Task.Delay(SettlePollMilliseconds);
        }
    }

    // Joins frames taken while scrolling down. The header and footer are measured on the first two
    // frames and kept for the whole run, so the joins line up.
    public static Drawing.Bitmap Stitch(IReadOnlyList<Drawing.Bitmap> frames)
    {
        if (frames.Count == 0) throw new ArgumentException("Nothing was captured.");
        var first = frames[0]; var w = first.Width; var h = first.Height;
        if (frames.Count == 1) return ScreenCapture.Crop(first, new(0, 0, w, h));
        var (header, footer) = Margins(first, frames[1]);
        var pieces = new List<(Drawing.Bitmap Frame, int Top, int Height)> { (first, 0, h - footer) };
        for (var i = 1; i < frames.Count; i++)
        {
            var shift = FindShift(frames[i - 1], frames[i], header, footer);
            if (shift <= 0) break;
            pieces.Add((frames[i], h - footer - shift, shift));
        }
        pieces.Add((pieces[^1].Frame, h - footer, footer));
        var total = Math.Min(MaxHeight, pieces.Sum(p => p.Height));
        var result = new Drawing.Bitmap(w, total, DrawingImaging.PixelFormat.Format32bppRgb);
        using var g = Drawing.Graphics.FromImage(result);
        var y = 0;
        foreach (var (frame, top, rows) in pieces)
        {
            var take = Math.Min(rows, total - y); if (take <= 0) break;
            g.DrawImage(frame, new Drawing.Rectangle(0, y, w, take), new Drawing.Rectangle(0, top, w, take), Drawing.GraphicsUnit.Pixel);
            y += take;
        }
        return result;
    }

    // Rows that are identical at the same place in two frames, from the top and from the bottom,
    // each limited to a third of the height so moving content is never mistaken for a header.
    internal static (int Header, int Footer) Margins(Drawing.Bitmap a, Drawing.Bitmap b)
    {
        var ra = Rows(a); var rb = Rows(b); var h = ra.Length; var limit = h / 3;
        var header = 0; while (header < limit && ra[header] == rb[header]) header++;
        var footer = 0; while (footer < limit && ra[h - 1 - footer] == rb[h - 1 - footer]) footer++;
        if (header >= limit && footer >= limit) return (0, 0); // Nothing moved at all.
        return (header == limit ? 0 : header, footer == limit ? 0 : footer);
    }
    // How far the content moved up between two frames, in pixels; 0 when it did not move or no
    // overlap could be found. The smallest shift whose overlap matches (allowing for a blinking
    // caret or small animation) wins.
    internal static int FindShift(Drawing.Bitmap previous, Drawing.Bitmap next, int header, int footer)
    {
        var rp = Rows(previous); var rn = Rows(next); var h = rp.Length;
        var top = header; var bottom = h - footer; var content = bottom - top;
        if (content < 12) return 0;
        var unchanged = 0; for (var y = top; y < bottom; y++) if (rp[y] == rn[y]) unchanged++;
        if (unchanged == content) return 0;
        // 0.22.2 (David: web pages still failed): each row in 24 pieces, and pieces that stayed put are left out of
        // the comparison, so things that don't scroll (a bar that sticks to the top once scrolled, a chat button, the
        // link address a browser shows in a corner) no longer spoil every row they cross.
        // Rows that don't line up at the very top or bottom of the overlap are left out too (a code site's file bar sticks to
        // the top only after the first scroll), as long as at least half the overlap is left.
        var sp = Segments(previous); var sn = Segments(next);
        var best = 0; var bestScore = 0.0; var rowState = new int[h];
        for (var s = 1; s < content - 8; s++)
        {
            for (var y = top; y < bottom - s; y++)
            {
                int consideredHere = 0, matchesHere = 0;
                for (int k = y * SegmentCount, end = k + SegmentCount, o = (y + s) * SegmentCount; k < end; k++, o++)
                {
                    var n = sn[k]; if (n == sp[k]) continue;
                    consideredHere++; if (n == sp[o]) matchesHere++;
                }
                // Every changed piece must line up: rows that differ only in a number (a list of look-alike lines) don't.
                rowState[y] = consideredHere == 0 ? 0 : matchesHere == consideredHere ? 1 : -1;
            }
            // The run of rows where they line up best: a row that doesn't line up costs as much as 20 that do.
            int first = top, last = top - 1, runStart = top, sum = 0, bestSum = 0;
            for (var y = top; y < bottom - s; y++)
            {
                sum += rowState[y] > 0 ? 1 : rowState[y] < 0 ? -20 : 0;
                if (sum <= 0) { sum = 0; runStart = y + 1; }
                else if (sum > bestSum) { bestSum = sum; first = runStart; last = y; }
            }
            if (PaneTrace != null && s == DebugShift) PaneTrace($"at {s}: rows {first}-{last} of {top}-{bottom - s - 1}: " + string.Concat(Enumerable.Range(top, bottom - s - top).Select(y => rowState[y] switch { > 0 => '+', 0 => '.', _ => 'x' })));
            if ((last - first + 1) * 2 < bottom - s - top) continue;
            int considered = 0, matches = 0;
            for (var y = first; y <= last; y++) if (rowState[y] != 0) { considered++; if (rowState[y] > 0) matches++; }
            if (considered < 12) continue;
            var score = matches / (double)considered;
            if (score >= 0.97) return s;
            if (score > bestScore) { bestScore = score; best = s; }
        }
        PaneTrace?.Invoke($"pieces: best shift {best} at {bestScore:P0}");
        if (bestScore >= 0.9) return best;
        // 0.22.0: no exact match. On scaled screens a browser can move the page by part of a pixel, which
        // draws the text a little differently; compare rows by their brightness profile instead.
        var pp = Profiles(previous); var pn = Profiles(next);
        best = 0; bestScore = 0.0;
        for (var s = 1; s < content - 8; s++)
        {
            var overlap = content - s; var matches = 0;
            var still = 0;
            for (var y = top; y < bottom - s; y++) if (pn[y].AsSpan().SequenceEqual(pp[y])) still++; else if (Near(pn[y], pp[y + s])) matches++;
            if (overlap - still < 12) continue;
            var score = matches / (double)(overlap - still);
            if (score > bestScore) { bestScore = score; best = s; }
        }
        PaneTrace?.Invoke($"profiles: best shift {best} at {bestScore:P0}");
        return bestScore >= 0.95 ? best : 0;
    }
    private const int ProfileBins = 48, ProfileTolerance = 8;
    // Each row as the average brightness of 48 slices (the scroll bar edge left out, as in Rows).
    internal static byte[][] Profiles(Drawing.Bitmap bitmap)
    {
        var data = bitmap.LockBits(new(0, 0, bitmap.Width, bitmap.Height), DrawingImaging.ImageLockMode.ReadOnly, DrawingImaging.PixelFormat.Format32bppRgb);
        try
        {
            var width = Math.Max(ProfileBins, bitmap.Width - Math.Min(ScrollbarMargin, bitmap.Width / 4));
            var row = new byte[Math.Min(width, bitmap.Width) * 4]; var result = new byte[bitmap.Height][];
            for (var y = 0; y < bitmap.Height; y++)
            {
                Marshal.Copy(data.Scan0 + y * data.Stride, row, 0, row.Length);
                var sums = new int[ProfileBins]; var counts = new int[ProfileBins]; var pixels = row.Length / 4;
                for (var x = 0; x < pixels; x++) { var bin = x * ProfileBins / pixels; sums[bin] += (row[x * 4] * 11 + row[x * 4 + 1] * 59 + row[x * 4 + 2] * 30) / 100; counts[bin]++; }
                result[y] = new byte[ProfileBins];
                for (var b = 0; b < ProfileBins; b++) result[y][b] = (byte)(counts[b] == 0 ? 0 : sums[b] / counts[b]);
            }
            return result;
        }
        finally { bitmap.UnlockBits(data); }
    }
    private static bool Near(byte[] a, byte[] b)
    {
        for (var i = 0; i < a.Length; i++) if (Math.Abs(a[i] - b[i]) > ProfileTolerance) return false;
        return true;
    }
    private const int SegmentCount = 24;
    // A fingerprint for each of 24 pieces of every row (the scroll bar edge left out, as in Rows), row after row.
    internal static ulong[] Segments(Drawing.Bitmap bitmap)
    {
        var data = bitmap.LockBits(new(0, 0, bitmap.Width, bitmap.Height), DrawingImaging.ImageLockMode.ReadOnly, DrawingImaging.PixelFormat.Format32bppRgb);
        try
        {
            var width = Math.Max(SegmentCount, bitmap.Width - Math.Min(ScrollbarMargin, bitmap.Width / 4));
            var pixels = Math.Min(width, bitmap.Width); var row = new byte[pixels * 4]; var result = new ulong[bitmap.Height * SegmentCount];
            for (var y = 0; y < bitmap.Height; y++)
            {
                Marshal.Copy(data.Scan0 + y * data.Stride, row, 0, row.Length);
                for (var k = 0; k < SegmentCount; k++)
                {
                    var hash = 14695981039346656037UL;
                    for (int x = k * pixels / SegmentCount, end = (k + 1) * pixels / SegmentCount; x < end; x++)
                    { var i = x * 4; hash = (hash ^ row[i]) * 1099511628211UL; hash = (hash ^ row[i + 1]) * 1099511628211UL; hash = (hash ^ row[i + 2]) * 1099511628211UL; }
                    result[y * SegmentCount + k] = hash;
                }
            }
            return result;
        }
        finally { bitmap.UnlockBits(data); }
    }
    // One fingerprint per row, leaving out the right-hand edge where a scroll bar moves.
    internal static ulong[] Rows(Drawing.Bitmap bitmap)
    {
        var data = bitmap.LockBits(new(0, 0, bitmap.Width, bitmap.Height), DrawingImaging.ImageLockMode.ReadOnly, DrawingImaging.PixelFormat.Format32bppRgb);
        try
        {
            var width = Math.Max(1, bitmap.Width - Math.Min(ScrollbarMargin, bitmap.Width / 4));
            var row = new byte[width * 4]; var result = new ulong[bitmap.Height];
            for (var y = 0; y < bitmap.Height; y++)
            {
                Marshal.Copy(data.Scan0 + y * data.Stride, row, 0, row.Length);
                var hash = 14695981039346656037UL;
                for (var i = 0; i < row.Length; i += 4) { hash = (hash ^ row[i]) * 1099511628211UL; hash = (hash ^ row[i + 1]) * 1099511628211UL; hash = (hash ^ row[i + 2]) * 1099511628211UL; }
                result[y] = hash;
            }
            return result;
        }
        finally { bitmap.UnlockBits(data); }
    }

    internal static void Wheel(int delta)
    {
        var input = new INPUT { type = 0, mi = new MOUSEINPUT { mouseData = delta, dwFlags = 0x0800 } };
        SendInput(1, [input], Marshal.SizeOf<INPUT>());
    }
    internal static bool EscapePressed() => (GetAsyncKeyState(0x1B) & 0x8000) != 0;
    [StructLayout(LayoutKind.Sequential)] private struct MOUSEINPUT { public int dx, dy, mouseData, dwFlags, time; public IntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Sequential)] private struct INPUT { public int type; public MOUSEINPUT mi; } // MOUSEINPUT is the union's largest member.
    [DllImport("user32.dll")] private static extern uint SendInput(uint count, INPUT[] inputs, int size);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
    [StructLayout(LayoutKind.Sequential)] private struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] private static extern IntPtr WindowFromPoint(Drawing.Point point);
    [DllImport("user32.dll")] private static extern IntPtr GetAncestor(IntPtr window, uint flags);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool GetWindowRect(IntPtr window, out RECT rect);
    [DllImport("user32.dll")] private static extern IntPtr MonitorFromPoint(Drawing.Point point, uint flags);
}
