using System.Runtime.InteropServices;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace TinyRedaction.Desktop;

internal enum SelectionKind { Rectangle, Freehand, Window, Object }

// The capture selection screen (0.12.0): the screen is frozen at the
// moment of capture and dimmed; the part being chosen shows at full brightness. Rectangle shows a
// crosshair and a magnifier, Freehand draws the outline, Window/Object highlights what is under the
// pointer. Esc or a right-click cancels. It is a per-monitor DPI aware Windows Forms window so its
// pixels are the screen's pixels on every monitor (created inside ScreenCapture.DpiScope).
internal sealed class CaptureOverlay : Forms.Form
{
    private const int Magnification = 4, MagnifierSource = 31;
    private readonly Drawing.Bitmap desktop, dimmed;
    private readonly Drawing.Rectangle screen, hintArea;
    private readonly SelectionKind kind;
    private readonly IReadOnlyList<ScreenCapture.WindowTarget> windows;
    private readonly string hint;
    private readonly List<Drawing.Point> outline = [];
    private readonly List<Drawing.Rectangle> painted = [];
    private Drawing.Point anchor, pointer;
    private bool dragging, pointerKnown;
    private Drawing.Rectangle selection;
    private Drawing.Rectangle? hover;
    private float scale = 1;
    private Drawing.Font? font;
    public Drawing.Rectangle SelectedRegion { get; private set; }
    public Drawing.Point ClickedPoint { get; private set; } // Screen pixels; scrolling capture scrolls the pane under it.
    // 0.22.3 (David): the panes of web pages are highlighted too, as an application's panes are (scrolling capture).
    [System.ComponentModel.DesignerSerializationVisibility(System.ComponentModel.DesignerSerializationVisibility.Hidden)]
    public bool FindWebPanes { get; init; }
    private readonly Dictionary<IntPtr, List<Drawing.Rectangle>> webPanes = [];
    private readonly HashSet<IntPtr> scanning = [];
    internal Drawing.Rectangle? Highlighted => hover is { } h ? new(h.X + screen.X, h.Y + screen.Y, h.Width, h.Height) : null; // Screen pixels (checks).
    public IReadOnlyList<Drawing.Point> Outline => outline.Select(p => new Drawing.Point(p.X + screen.X, p.Y + screen.Y)).ToList();

    public CaptureOverlay(Drawing.Bitmap frozen, Drawing.Rectangle virtualScreen, SelectionKind selectionKind, IReadOnlyList<ScreenCapture.WindowTarget>? targets, string instructions)
    {
        desktop = frozen; screen = virtualScreen; kind = selectionKind; windows = targets ?? []; hint = instructions;
        dimmed = new Drawing.Bitmap(desktop);
        using (var g = Drawing.Graphics.FromImage(dimmed)) using (var shade = new Drawing.SolidBrush(Drawing.Color.FromArgb(105, 0, 0, 0))) g.FillRectangle(shade, 0, 0, dimmed.Width, dimmed.Height);
        var monitor = ScreenCapture.MonitorAt(ScreenCapture.CursorPosition);
        hintArea = new(monitor.X - screen.X, monitor.Y - screen.Y, monitor.Width, monitor.Height);
        AutoScaleMode = Forms.AutoScaleMode.None; FormBorderStyle = Forms.FormBorderStyle.None; StartPosition = Forms.FormStartPosition.Manual;
        Bounds = screen; TopMost = true; ShowInTaskbar = false; KeyPreview = true; Text = "TinyRedactionTool capture";
        Cursor = kind is SelectionKind.Window or SelectionKind.Object ? Forms.Cursors.Hand : Forms.Cursors.Cross;
        SetStyle(Forms.ControlStyles.AllPaintingInWmPaint | Forms.ControlStyles.OptimizedDoubleBuffer | Forms.ControlStyles.UserPaint | Forms.ControlStyles.Opaque, true);
    }
    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        try { scale = Math.Max(1, GetDpiForWindow(Handle) / 96f); } catch (EntryPointNotFoundException) { }
        font = new Drawing.Font("Segoe UI", 12.5f * scale, Drawing.GraphicsUnit.Pixel);
    }
    // Keep screen pixels: never let Windows resize this window for a monitor's scaling.
    protected override void WndProc(ref Forms.Message m) { if (m.Msg == 0x02E0) { m.Result = IntPtr.Zero; return; } base.WndProc(ref m); }
    protected override void OnShown(EventArgs e)
    {
        base.OnShown(e); Activate(); Focus();
        var p = ScreenCapture.CursorPosition; Track(new(p.X - screen.X, p.Y - screen.Y));
    }
    protected override void OnKeyDown(Forms.KeyEventArgs e)
    {
        if (e.KeyCode == Forms.Keys.Escape) { DialogResult = Forms.DialogResult.Cancel; e.Handled = true; }
        base.OnKeyDown(e);
    }
    protected override void OnMouseDown(Forms.MouseEventArgs e)
    {
        base.OnMouseDown(e);
        if (e.Button == Forms.MouseButtons.Right) { DialogResult = Forms.DialogResult.Cancel; return; }
        if (e.Button != Forms.MouseButtons.Left || kind is SelectionKind.Window or SelectionKind.Object) return;
        anchor = Clamp(e.Location); dragging = true; Capture = true;
        selection = Drawing.Rectangle.Empty; outline.Clear(); outline.Add(anchor);
        Track(anchor);
    }
    protected override void OnMouseMove(Forms.MouseEventArgs e) { base.OnMouseMove(e); Track(Clamp(e.Location)); }
    protected override void OnMouseUp(Forms.MouseEventArgs e)
    {
        base.OnMouseUp(e);
        if (e.Button != Forms.MouseButtons.Left) return;
        if (kind is SelectionKind.Window or SelectionKind.Object)
        {
            var at = Clamp(e.Location); Track(at);
            ClickedPoint = new(at.X + screen.X, at.Y + screen.Y);
            if (hover is { } picked) Finish(picked);
            return;
        }
        if (!dragging) return;
        dragging = false; Capture = false; Track(Clamp(e.Location));
        if (kind == SelectionKind.Freehand)
        {
            var bounds = outline.Count >= 3 ? ScreenCapture.Bounds(outline) : Drawing.Rectangle.Empty;
            if (bounds.Width < 3 || bounds.Height < 3) { outline.Clear(); Invalidate(); return; }
            Finish(bounds);
        }
        else if (selection.Width < 2 || selection.Height < 2) { selection = Drawing.Rectangle.Empty; Invalidate(); }
        else Finish(selection);
    }
    private void Finish(Drawing.Rectangle client)
    {
        SelectedRegion = new(client.X + screen.X, client.Y + screen.Y, client.Width, client.Height);
        DialogResult = Forms.DialogResult.OK;
    }
    private Drawing.Point Clamp(Drawing.Point p) => new(Math.Clamp(p.X, 0, screen.Width - 1), Math.Clamp(p.Y, 0, screen.Height - 1));

    // Moves the pointer state and repaints only what changed (the frozen screen can be very large).
    internal void Track(Drawing.Point p)
    {
        pointer = p; pointerKnown = true;
        if (dragging && kind == SelectionKind.Rectangle) selection = ScreenCapture.Normalize(anchor, new(p.X + 1, p.Y + 1));
        if (dragging && kind == SelectionKind.Freehand && (outline.Count == 0 || Math.Abs(outline[^1].X - p.X) + Math.Abs(outline[^1].Y - p.Y) >= 2)) outline.Add(p);
        if (kind is SelectionKind.Window or SelectionKind.Object)
        {
            var at = new Drawing.Point(p.X + screen.X, p.Y + screen.Y);
            var picked = ScreenCapture.Pick(windows, at, kind == SelectionKind.Object);
            if (FindWebPanes && windows.FirstOrDefault(w => w.Bounds.Contains(at)) is { } window && WebPanes.IsBrowser(window.Handle))
            {
                if (webPanes.TryGetValue(window.Handle, out var panes)) picked = WebPanes.At(panes, at) is { } pane ? Drawing.Rectangle.Intersect(pane, window.Bounds) : picked;
                else ScanWebPanes(window.Handle);
            }
            hover = picked is { } r ? new Drawing.Rectangle(r.X - screen.X, r.Y - screen.Y, r.Width, r.Height) : null;
        }
        foreach (var area in painted) Invalidate(area);
        painted.Clear(); painted.AddRange(DirtyAreas());
        foreach (var area in painted) Invalidate(area);
    }
    // Asks the browser for its page's panes in the background (up to a second the first time); the window stays
    // highlighted until they are known. The frozen screen is only read on this thread.
    private void ScanWebPanes(IntPtr handle)
    {
        if (!scanning.Add(handle)) return;
        Drawing.Bitmap? Picture(Drawing.Rectangle area)
        {
            try { return (Drawing.Bitmap?)Invoke(() => IsDisposed ? null : ScreenCapture.Crop(desktop, new(area.X - screen.X, area.Y - screen.Y, area.Width, area.Height))); }
            catch (Exception exception) when (exception is ObjectDisposedException or InvalidOperationException) { return null; }
        }
        Task.Run(() => WebPanes.Scan(handle, Picture)).ContinueWith(task =>
        {
            if (IsDisposed || !IsHandleCreated) return;
            try { BeginInvoke(() => { if (IsDisposed) return; webPanes[handle] = task.IsCompletedSuccessfully ? task.Result : []; if (pointerKnown) Track(pointer); }); }
            catch (InvalidOperationException) { }
        });
    }
    private IEnumerable<Drawing.Rectangle> DirtyAreas()
    {
        var margin = (int)(40 * scale);
        if (!selection.IsEmpty) yield return Inflate(selection, margin);
        if (hover is { } h) yield return Inflate(h, margin);
        if (outline.Count > 0) yield return Inflate(ScreenCapture.Bounds(outline), margin);
        if (!pointerKnown) yield break;
        if (kind is SelectionKind.Rectangle && !dragging)
        { yield return new(0, pointer.Y - 2, screen.Width, 5); yield return new(pointer.X - 2, 0, 5, screen.Height); }
        if (kind is SelectionKind.Rectangle or SelectionKind.Freehand) yield return Inflate(MagnifierArea(), 4);
        yield return Inflate(HintBox(), 4);
    }
    private static Drawing.Rectangle Inflate(Drawing.Rectangle r, int by) { r.Inflate(by, by); return r; }
    private Drawing.Rectangle HintBox()
    {
        var width = (int)(520 * scale); var height = (int)(30 * scale);
        return new(hintArea.X + (hintArea.Width - width) / 2, hintArea.Y + (int)(14 * scale), width, height);
    }
    private Drawing.Rectangle MagnifierArea()
    {
        var size = (int)(MagnifierSource * Magnification * Math.Min(scale, 1.5f)); var label = (int)(22 * scale); var gap = (int)(22 * scale);
        var monitor = ScreenCapture.MonitorAt(new(pointer.X + screen.X, pointer.Y + screen.Y));
        var left = monitor.X - screen.X; var top = monitor.Y - screen.Y;
        var x = pointer.X + gap; var y = pointer.Y + gap;
        if (x + size > left + monitor.Width) x = pointer.X - gap - size;
        if (y + size + label > top + monitor.Height) y = pointer.Y - gap - size - label;
        return new(x, y, size, size + label);
    }

    protected override void OnPaint(Forms.PaintEventArgs e)
    {
        var g = e.Graphics; var clip = e.ClipRectangle;
        g.DrawImage(dimmed, clip, clip, Drawing.GraphicsUnit.Pixel);
        Drawing.Rectangle? bright = !selection.IsEmpty ? selection : hover;
        if (bright is { } area)
        {
            var visible = Drawing.Rectangle.Intersect(area, clip);
            if (!visible.IsEmpty) g.DrawImage(desktop, visible, visible, Drawing.GraphicsUnit.Pixel);
            using var pen = new Drawing.Pen(kind is SelectionKind.Window or SelectionKind.Object ? Drawing.Color.FromArgb(224, 72, 72) : Drawing.Color.FromArgb(30, 144, 255), Math.Max(2, 2 * scale));
            g.DrawRectangle(pen, area.X, area.Y, Math.Max(1, area.Width - 1), Math.Max(1, area.Height - 1));
            Label(g, $"{area.Width} × {area.Height}", new(area.X, area.Y - (int)(24 * scale) < 0 ? area.Bottom + (int)(4 * scale) : area.Y - (int)(24 * scale)));
        }
        if (outline.Count > 1)
        {
            using var pen = new Drawing.Pen(Drawing.Color.FromArgb(224, 72, 72), Math.Max(2, 2 * scale));
            g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.AntiAlias;
            g.DrawLines(pen, outline.ToArray());
            if (!dragging) g.DrawLine(pen, outline[^1], outline[0]);
            g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.None;
        }
        if (pointerKnown && kind == SelectionKind.Rectangle && !dragging)
        {
            using var pen = new Drawing.Pen(Drawing.Color.FromArgb(220, 255, 255, 255), 1) { DashStyle = Drawing.Drawing2D.DashStyle.Dash };
            g.DrawLine(pen, 0, pointer.Y, screen.Width, pointer.Y); g.DrawLine(pen, pointer.X, 0, pointer.X, screen.Height);
        }
        if (pointerKnown && kind is SelectionKind.Rectangle or SelectionKind.Freehand) Magnifier(g);
        var box = HintBox();
        using (var back = new Drawing.SolidBrush(Drawing.Color.FromArgb(255, 220, 65))) g.FillRectangle(back, box);
        Forms.TextRenderer.DrawText(g, hint, font, box, Drawing.Color.Black, Forms.TextFormatFlags.HorizontalCenter | Forms.TextFormatFlags.VerticalCenter | Forms.TextFormatFlags.EndEllipsis);
    }
    private void Magnifier(Drawing.Graphics g)
    {
        var area = MagnifierArea(); var size = area.Width;
        var lens = new Drawing.Rectangle(area.X, area.Y, size, size);
        var source = new Drawing.Rectangle(pointer.X - MagnifierSource / 2, pointer.Y - MagnifierSource / 2, MagnifierSource, MagnifierSource);
        g.FillRectangle(Drawing.Brushes.Black, lens);
        g.InterpolationMode = Drawing.Drawing2D.InterpolationMode.NearestNeighbor; g.PixelOffsetMode = Drawing.Drawing2D.PixelOffsetMode.Half;
        g.DrawImage(desktop, lens, source, Drawing.GraphicsUnit.Pixel);
        g.InterpolationMode = Drawing.Drawing2D.InterpolationMode.Default; g.PixelOffsetMode = Drawing.Drawing2D.PixelOffsetMode.Default;
        var cell = size / (float)MagnifierSource; var centre = lens.X + size / 2f;
        using (var cross = new Drawing.Pen(Drawing.Color.FromArgb(200, 30, 144, 255), Math.Max(1, cell / 3)))
        { g.DrawLine(cross, centre, lens.Y, centre, lens.Bottom); g.DrawLine(cross, lens.X, lens.Y + size / 2f, lens.Right, lens.Y + size / 2f); }
        g.DrawRectangle(Drawing.Pens.White, lens.X, lens.Y, size - 1, size - 1);
        var text = dragging && kind == SelectionKind.Rectangle ? $"{selection.Width} × {selection.Height}" : $"{pointer.X + screen.X}, {pointer.Y + screen.Y}";
        var label = new Drawing.Rectangle(lens.X, lens.Bottom, size, area.Height - size);
        g.FillRectangle(Drawing.Brushes.Black, label);
        Forms.TextRenderer.DrawText(g, text, font, label, Drawing.Color.White, Forms.TextFormatFlags.HorizontalCenter | Forms.TextFormatFlags.VerticalCenter);
    }
    private void Label(Drawing.Graphics g, string text, Drawing.Point at)
    {
        var size = Forms.TextRenderer.MeasureText(g, text, font);
        var box = new Drawing.Rectangle(at.X, at.Y, size.Width + (int)(8 * scale), (int)(20 * scale));
        g.FillRectangle(Drawing.Brushes.Black, box);
        Forms.TextRenderer.DrawText(g, text, font, box, Drawing.Color.White, Forms.TextFormatFlags.HorizontalCenter | Forms.TextFormatFlags.VerticalCenter);
    }
    protected override void Dispose(bool disposing) { if (disposing) { dimmed.Dispose(); font?.Dispose(); } base.Dispose(disposing); }
    [DllImport("user32.dll")] private static extern uint GetDpiForWindow(IntPtr handle);
}
