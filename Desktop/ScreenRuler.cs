using System.Globalization;
using System.Runtime.InteropServices;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace TinyRedaction.Desktop;

internal enum MeasureKind { Rectangle, Distance, Angle }
internal enum RulerPart { None, StartGrip, EndGrip, Turn, Rectangle, Distance, Angle, Options, Close, Middle, Scale }

// Screen ruler (0.14.0, after David's video): a grey ruler with pixel ticks
// and numbers along both edges and a row of tools in the middle. The middle shows where the pointer
// is along the ruler ("124 px"); dragging along either edge measures a span ("D=99 px"). Drag the
// middle to move it, drag the grips at either end to change its length, double-click (or the arrows
// button) to turn it. Its tools measure a rectangle, a distance or an angle on a frozen picture of
// the screen. It is a per-monitor DPI aware Windows Forms window (created in ScreenCapture.DpiScope),
// so one ruler pixel is one screen pixel on every monitor. TRT's own artwork; Esc closes.
internal sealed class ScreenRuler : Forms.Form
{
    private static readonly Drawing.Color Body = Drawing.Color.FromArgb(217, 217, 217), Ink = Drawing.Color.FromArgb(40, 40, 40),
        Edge = Drawing.Color.FromArgb(120, 120, 120), Marker = Drawing.Color.FromArgb(220, 30, 30), Span = Drawing.Color.FromArgb(225, 220, 0),
        Hover = Drawing.Color.FromArgb(190, 205, 225);
    private static readonly RulerPart[] Tools = [RulerPart.Turn, RulerPart.Rectangle, RulerPart.Distance, RulerPart.Angle, RulerPart.Options, RulerPart.Close];
    private readonly Forms.Timer follow = new() { Interval = 30 };
    private readonly Forms.ToolTip tip = new() { InitialDelay = 400, ShowAlways = true };
    private readonly Forms.ContextMenuStrip menu = new();
    private float scale = 1;
    private bool vertical;
    private int length, pointer = -1;
    private int? spanStart, spanEnd;
    private bool spanInFirstBand, spanning;
    private RulerPart hovered, resizing;
    private Drawing.Point resizeAnchor;
    private Drawing.Rectangle resizeBounds;
    private Drawing.Font? font, bold;
    public event Action<MeasureKind>? MeasureRequested;

    public ScreenRuler()
    {
        AutoScaleMode = Forms.AutoScaleMode.None; FormBorderStyle = Forms.FormBorderStyle.None; StartPosition = Forms.FormStartPosition.Manual;
        TopMost = true; ShowInTaskbar = false; KeyPreview = true; Text = "Screen Ruler"; BackColor = Body; DoubleBuffered = true;
        SetStyle(Forms.ControlStyles.AllPaintingInWmPaint | Forms.ControlStyles.OptimizedDoubleBuffer | Forms.ControlStyles.UserPaint, true);
        follow.Tick += (_, _) => FollowPointer();
        menu.Items.Add("Turn (Horizontal / Vertical)", null, (_, _) => Turn());
        foreach (var size in new[] { 400, 800, 1200, 1600 }) menu.Items.Add($"Length {size} Pixels", null, (_, _) => SetLength(size));
        menu.Items.Add("Length: The Width of This Screen", null, (_, _) => SetLength(ScreenLength()));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add("Close Ruler", null, (_, _) => Close());
        WindowTheme.Apply(menu, MainWindow.DarkTheme); // 0.28.0: follows Light and Dark.
    }
    internal bool IsVertical => vertical;
    internal int Length => length;
    internal int Thickness => S(76);
    private int Band => S(23);
    private int Grip => S(10);
    private int ButtonSize => S(24);
    private int S(double v) => (int)Math.Round(v * scale);

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        try { scale = Math.Max(1, GetDpiForWindow(Handle) / 96f); } catch (EntryPointNotFoundException) { }
        font = new Drawing.Font("Segoe UI", 11 * scale, Drawing.GraphicsUnit.Pixel);
        bold = new Drawing.Font("Segoe UI", 12.5f * scale, Drawing.FontStyle.Bold, Drawing.GraphicsUnit.Pixel);
        if (length == 0) length = S(560);
        Arrange();
        follow.Start();
    }
    // Keep screen pixels: never let Windows resize this window for a monitor's scaling.
    protected override void WndProc(ref Forms.Message m) { if (m.Msg == 0x02E0) { m.Result = IntPtr.Zero; return; } base.WndProc(ref m); }
    private void Arrange() { Size = vertical ? new(Thickness, length) : new(length, Thickness); Invalidate(); }
    internal void Turn() { vertical = !vertical; spanStart = spanEnd = null; Arrange(); }
    internal void SetLength(int pixels) { length = Math.Max(MinimumLength, pixels); Arrange(); }
    private int MinimumLength => Grip * 2 + S(8) + Tools.Length * (ButtonSize + S(2)) + S(80);
    private int ScreenLength()
    {
        var monitor = ScreenCapture.MonitorAt(new(Left + Width / 2, Top + Height / 2));
        return vertical ? monitor.Height : monitor.Width;
    }

    // ---- Where things are, in ruler terms: "along" from the start, "across" from the first edge. ----
    private Drawing.Point ToRuler(Drawing.Point client) => vertical ? new(client.Y, client.X) : client;
    private Drawing.Rectangle FromRuler(int along, int across, int alongSize, int acrossSize) =>
        vertical ? new(across, along, acrossSize, alongSize) : new(along, across, alongSize, acrossSize);
    private Drawing.Rectangle ToolArea(int index)
    {
        var size = ButtonSize; var start = Grip + S(6) + index * (size + S(2));
        return FromRuler(start, (Thickness - size) / 2, size, size);
    }
    internal RulerPart HitTest(Drawing.Point client)
    {
        var p = ToRuler(client);
        if (p.Y < Band || p.Y >= Thickness - Band) return RulerPart.Scale;
        if (p.X < Grip) return RulerPart.StartGrip;
        if (p.X >= length - Grip) return RulerPart.EndGrip;
        for (var i = 0; i < Tools.Length; i++) if (ToolArea(i).Contains(client)) return Tools[i];
        return RulerPart.Middle;
    }
    private static string ToolTipFor(RulerPart part) => part switch
    {
        RulerPart.Turn => "Turn the Ruler (Horizontal / Vertical)",
        RulerPart.Rectangle => "Measure a Rectangle: Drag Round It",
        RulerPart.Distance => "Measure the Distance Between Two Points",
        RulerPart.Angle => "Measure an Angle (Protractor)",
        RulerPart.Options => "Options: length, turn, close",
        RulerPart.Close => "Close the Ruler (Esc)",
        RulerPart.StartGrip or RulerPart.EndGrip => "Drag to Make the Ruler Longer or Shorter",
        RulerPart.Scale => "Drag Along the Edge to Measure a Length",
        RulerPart.Middle => "Drag to Move · Double-Click to Turn · Arrow Keys Move by One Pixel",
        _ => "",
    };

    // ---- The pointer's position along the ruler, shown in the middle ("124 px"). ----
    private void FollowPointer()
    {
        if (!IsHandleCreated || !Visible) return;
        Drawing.Point screen;
        using (new ScreenCapture.DpiScope()) screen = ScreenCapture.CursorPosition;
        var bounds = Bounds;
        SetPointer(vertical ? screen.Y - bounds.Top : screen.X - bounds.Left);
    }
    internal void SetPointer(int along)
    {
        if (along == pointer) return;
        pointer = along;
        if (spanning) spanEnd = Math.Clamp(along, 0, length);
        Invalidate();
    }
    internal string Readout => spanStart is { } a && spanEnd is { } b && a != b ? $"D={Math.Abs(b - a)} px" : $"{pointer} px";
    // Measuring a span along one edge (checks drive this directly).
    internal void MeasureSpan(int from, int to, bool firstBand = false) { spanStart = from; spanEnd = to; spanInFirstBand = firstBand; spanning = false; Invalidate(); }

    // ---- Mouse and keys ----
    protected override void OnMouseDown(Forms.MouseEventArgs e)
    {
        base.OnMouseDown(e);
        if (e.Button == Forms.MouseButtons.Right) { menu.Show(this, e.Location); return; }
        if (e.Button != Forms.MouseButtons.Left) return;
        var part = HitTest(e.Location);
        switch (part)
        {
            case RulerPart.Middle when e.Clicks == 2: Turn(); return;
            case RulerPart.Middle: ReleaseCapture(); SendMessage(Handle, 0xA1, 2, 0); return; // Move like a title bar.
            case RulerPart.Scale:
                var along = ToRuler(e.Location).X;
                spanStart = spanEnd = along; spanInFirstBand = ToRuler(e.Location).Y < Band; spanning = true; Capture = true; Invalidate(); return;
            case RulerPart.StartGrip or RulerPart.EndGrip:
                resizing = part; resizeAnchor = Forms.Cursor.Position; resizeBounds = Bounds; Capture = true; return;
            default: Press(part); return;
        }
    }
    internal void Press(RulerPart part)
    {
        switch (part)
        {
            case RulerPart.Turn: Turn(); break;
            case RulerPart.Rectangle: MeasureRequested?.Invoke(MeasureKind.Rectangle); break;
            case RulerPart.Distance: MeasureRequested?.Invoke(MeasureKind.Distance); break;
            case RulerPart.Angle: MeasureRequested?.Invoke(MeasureKind.Angle); break;
            case RulerPart.Options: var at = ToolArea(Array.IndexOf(Tools, RulerPart.Options)); menu.Show(this, new Drawing.Point(at.Left, at.Bottom)); break;
            case RulerPart.Close: Close(); break;
        }
    }
    protected override void OnMouseMove(Forms.MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (resizing != RulerPart.None)
        {
            var moved = vertical ? Forms.Cursor.Position.Y - resizeAnchor.Y : Forms.Cursor.Position.X - resizeAnchor.X;
            var original = vertical ? resizeBounds.Height : resizeBounds.Width;
            if (resizing == RulerPart.EndGrip) SetLength(original + moved);
            else
            {
                var size = Math.Max(MinimumLength, original - moved); var shift = original - size;
                length = size;
                Bounds = vertical ? new(resizeBounds.Left, resizeBounds.Top + shift, Thickness, size) : new(resizeBounds.Left + shift, resizeBounds.Top, size, Thickness);
                Invalidate();
            }
            return;
        }
        var part = HitTest(e.Location);
        Cursor = part switch
        {
            RulerPart.StartGrip or RulerPart.EndGrip => vertical ? Forms.Cursors.SizeNS : Forms.Cursors.SizeWE,
            RulerPart.Middle => Forms.Cursors.SizeAll,
            RulerPart.Scale => vertical ? Forms.Cursors.HSplit : Forms.Cursors.VSplit,
            _ => Forms.Cursors.Hand,
        };
        if (part != hovered) { hovered = part; tip.SetToolTip(this, ToolTipFor(part)); Invalidate(); }
    }
    protected override void OnMouseUp(Forms.MouseEventArgs e)
    {
        base.OnMouseUp(e);
        if (resizing != RulerPart.None) { resizing = RulerPart.None; Capture = false; return; }
        if (spanning) { spanning = false; Capture = false; if (spanStart == spanEnd) spanStart = spanEnd = null; Invalidate(); }
    }
    protected override void OnMouseLeave(EventArgs e) { base.OnMouseLeave(e); if (hovered != RulerPart.None) { hovered = RulerPart.None; Invalidate(); } }
    protected override void OnKeyDown(Forms.KeyEventArgs e)
    {
        base.OnKeyDown(e);
        var step = e.Shift ? 10 : 1;
        switch (e.KeyCode)
        {
            case Forms.Keys.Escape: Close(); break;
            case Forms.Keys.Left: Left -= step; break;
            case Forms.Keys.Right: Left += step; break;
            case Forms.Keys.Up: Top -= step; break;
            case Forms.Keys.Down: Top += step; break;
            default: return;
        }
        e.Handled = true;
    }

    // ---- Drawing ----
    protected override void OnPaint(Forms.PaintEventArgs e)
    {
        var g = e.Graphics;
        using var ink = new Drawing.Pen(Ink, 1);
        using (var edge = new Drawing.Pen(Edge, 1)) g.DrawRectangle(edge, 0, 0, Width - 1, Height - 1);
        if (spanStart is { } a && spanEnd is { } b && a != b)
        {
            using var yellow = new Drawing.SolidBrush(Span);
            g.FillRectangle(yellow, FromRuler(Math.Min(a, b), spanInFirstBand ? 0 : Thickness - Band, Math.Abs(b - a), Band));
        }
        // Ticks every 2 pixels, longer every 10, 50 and 100; numbers every 50, on both edges.
        for (var at = 0; at < length; at += 2)
        {
            var tick = at % 100 == 0 ? S(13) : at % 50 == 0 ? S(10) : at % 10 == 0 ? S(7) : S(3);
            Line(g, ink, at, 0, at, tick);
            Line(g, ink, at, Thickness - 1, at, Thickness - 1 - tick);
            if (at % 50 != 0 || at == 0) continue;
            var label = at.ToString(CultureInfo.InvariantCulture);
            var size = Forms.TextRenderer.MeasureText(g, label, font, Drawing.Size.Empty, Forms.TextFormatFlags.NoPadding);
            if (vertical)
            {
                Forms.TextRenderer.DrawText(g, label, font, new Drawing.Point(S(15), at - size.Height / 2), Ink, Forms.TextFormatFlags.NoPadding);
                Forms.TextRenderer.DrawText(g, label, font, new Drawing.Point(Thickness - S(15) - size.Width, at - size.Height / 2), Ink, Forms.TextFormatFlags.NoPadding);
            }
            else
            {
                Forms.TextRenderer.DrawText(g, label, font, new Drawing.Point(at - size.Width / 2, S(13)), Ink, Forms.TextFormatFlags.NoPadding);
                Forms.TextRenderer.DrawText(g, label, font, new Drawing.Point(at - size.Width / 2, Thickness - S(13) - size.Height), Ink, Forms.TextFormatFlags.NoPadding);
            }
        }
        if (pointer >= 0 && pointer < length)
        {
            using var red = new Drawing.Pen(Marker, Math.Max(1, scale));
            Line(g, red, pointer, 0, pointer, Band); Line(g, red, pointer, Thickness - Band, pointer, Thickness);
        }
        // Grips at both ends.
        foreach (var start in new[] { S(3), length - S(7) })
        {
            Line(g, ink, start, Thickness / 2 - S(5), start, Thickness / 2 + S(5));
            Line(g, ink, start + S(3), Thickness / 2 - S(5), start + S(3), Thickness / 2 + S(5));
        }
        for (var i = 0; i < Tools.Length; i++) DrawTool(g, Tools[i], ToolArea(i));
        // The readout, in the middle after the tools.
        var free = vertical
            ? new Drawing.Rectangle(0, ToolArea(Tools.Length - 1).Bottom + S(6), Thickness, Math.Max(0, length - Grip - ToolArea(Tools.Length - 1).Bottom - S(6)))
            : new Drawing.Rectangle(ToolArea(Tools.Length - 1).Right + S(6), Band, Math.Max(0, length - Grip - ToolArea(Tools.Length - 1).Right - S(6)), Thickness - 2 * Band);
        if (vertical) free = new(0, free.Top, Thickness, Math.Min(free.Height, S(40)));
        Forms.TextRenderer.DrawText(g, Readout, bold, free, Ink, Forms.TextFormatFlags.HorizontalCenter | Forms.TextFormatFlags.VerticalCenter | Forms.TextFormatFlags.NoPadding);
    }
    private void Line(Drawing.Graphics g, Drawing.Pen pen, int along1, int across1, int along2, int across2)
    {
        if (vertical) g.DrawLine(pen, across1, along1, across2, along2); else g.DrawLine(pen, along1, across1, along2, across2);
    }
    // TRT's own small tool pictures, drawn with lines.
    private void DrawTool(Drawing.Graphics g, RulerPart part, Drawing.Rectangle r)
    {
        if (part == hovered)
        {
            using var back = new Drawing.SolidBrush(Hover); g.FillRectangle(back, r);
            using var frame = new Drawing.Pen(Edge); g.DrawRectangle(frame, r.X, r.Y, r.Width - 1, r.Height - 1);
        }
        g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.AntiAlias;
        using var pen = new Drawing.Pen(Ink, Math.Max(1.4f, 1.6f * scale)) { StartCap = Drawing.Drawing2D.LineCap.Round, EndCap = Drawing.Drawing2D.LineCap.Round };
        using var fill = new Drawing.SolidBrush(Ink);
        float X(double v) => r.X + (float)(v * r.Width / 24); float Y(double v) => r.Y + (float)(v * r.Height / 24);
        Drawing.PointF P(double x, double y) => new(X(x), Y(y));
        switch (part)
        {
            case RulerPart.Turn:
                if (vertical) { g.FillPolygon(fill, [P(4, 12), P(10, 7), P(10, 17)]); g.FillPolygon(fill, [P(20, 12), P(14, 7), P(14, 17)]); }
                else { g.FillPolygon(fill, [P(12, 4), P(7, 10), P(17, 10)]); g.FillPolygon(fill, [P(12, 20), P(7, 14), P(17, 14)]); }
                break;
            case RulerPart.Rectangle:
                g.DrawRectangle(pen, X(6), Y(6), X(18) - X(6), Y(18) - Y(6));
                g.FillRectangle(fill, X(16), Y(16), X(20) - X(16), Y(20) - Y(16)); break;
            case RulerPart.Distance:
                g.DrawLine(pen, P(6, 6), P(18, 18)); g.FillEllipse(fill, X(3.5), Y(3.5), X(8.5) - X(3.5), Y(8.5) - Y(3.5)); g.FillEllipse(fill, X(15.5), Y(15.5), X(20.5) - X(15.5), Y(20.5) - Y(15.5)); break;
            case RulerPart.Angle:
                g.DrawLine(pen, P(4, 19), P(20, 19)); g.DrawLine(pen, P(4, 19), P(15, 6)); g.DrawArc(pen, X(-3), Y(12), X(11) - X(-3), Y(26) - Y(12), -50, 50);
                g.FillEllipse(fill, X(13), Y(4), X(17) - X(13), Y(8) - Y(4)); break;
            case RulerPart.Options:
                g.DrawRectangle(pen, X(5), Y(5), X(19) - X(5), Y(19) - Y(5));
                g.DrawLine(pen, P(9, 9.5), P(15, 9.5)); g.DrawLine(pen, P(9, 12), P(15, 12)); g.DrawLine(pen, P(9, 14.5), P(15, 14.5)); break;
            case RulerPart.Close:
                g.DrawLine(pen, P(7, 7), P(17, 17)); g.DrawLine(pen, P(17, 7), P(7, 17)); break;
        }
        g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.None;
    }
    protected override void Dispose(bool disposing)
    {
        if (disposing) { follow.Dispose(); tip.Dispose(); menu.Dispose(); font?.Dispose(); bold?.Dispose(); }
        base.Dispose(disposing);
    }
    [DllImport("user32.dll")] private static extern uint GetDpiForWindow(IntPtr handle);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool ReleaseCapture();
    [DllImport("user32.dll")] private static extern IntPtr SendMessage(IntPtr handle, int message, int wParam, int lParam);
}

// The ruler's measuring screen (0.14.0): the screen is frozen as it was, with a
// crosshair pointer and, in a bottom corner, a magnifier and a panel with the result and the steps.
// Rectangle: drag round something (W × H). Distance: drag between two points (D, Shift keeps the line
// straight). Angle: click the centre, then the ends of the two lines. Measure as often as you like;
// Esc or a right-click closes it. Per-monitor DPI aware, like the capture overlay, so it measures
// screen pixels.
internal sealed class MeasureOverlay : Forms.Form
{
    private const int Magnification = 5, MagnifierSource = 41;
    private static readonly Drawing.Color Line = Drawing.Color.FromArgb(0, 230, 255);
    private readonly Drawing.Bitmap desktop;
    private readonly Drawing.Rectangle screen;
    private readonly MeasureKind kind;
    private readonly List<Drawing.Rectangle> painted = [];
    private readonly List<Drawing.Point> points = [];
    private Drawing.Point pointer;
    private bool dragging, pointerKnown;
    private float scale = 1;
    private Drawing.Font? font, bold;

    public MeasureOverlay(Drawing.Bitmap frozen, Drawing.Rectangle virtualScreen, MeasureKind measure)
    {
        desktop = frozen; screen = virtualScreen; kind = measure;
        AutoScaleMode = Forms.AutoScaleMode.None; FormBorderStyle = Forms.FormBorderStyle.None; StartPosition = Forms.FormStartPosition.Manual;
        Bounds = screen; TopMost = true; ShowInTaskbar = false; KeyPreview = true; Text = "TinyRedactionTool ruler"; Cursor = Forms.Cursors.Cross;
        SetStyle(Forms.ControlStyles.AllPaintingInWmPaint | Forms.ControlStyles.OptimizedDoubleBuffer | Forms.ControlStyles.UserPaint | Forms.ControlStyles.Opaque, true);
    }
    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        try { scale = Math.Max(1, GetDpiForWindow(Handle) / 96f); } catch (EntryPointNotFoundException) { }
        font = new Drawing.Font("Segoe UI", 12.5f * scale, Drawing.GraphicsUnit.Pixel);
        bold = new Drawing.Font("Segoe UI", 13.5f * scale, Drawing.FontStyle.Bold, Drawing.GraphicsUnit.Pixel);
    }
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
        if (e.Button == Forms.MouseButtons.Left) Press(e.Location, Forms.Control.ModifierKeys.HasFlag(Forms.Keys.Shift));
    }
    protected override void OnMouseMove(Forms.MouseEventArgs e) { base.OnMouseMove(e); Track(e.Location, Forms.Control.ModifierKeys.HasFlag(Forms.Keys.Shift)); }
    protected override void OnMouseUp(Forms.MouseEventArgs e) { base.OnMouseUp(e); if (e.Button == Forms.MouseButtons.Left) Release(e.Location, Forms.Control.ModifierKeys.HasFlag(Forms.Keys.Shift)); }

    // ---- What the mouse does (client coordinates; the checks drive these directly) ----
    internal void Press(Drawing.Point p, bool straight = false)
    {
        p = Clamp(p);
        if (kind == MeasureKind.Angle)
        {
            // Click 1 fixes the centre, click 2 the first line's end, click 3 the second's; a 4th starts again.
            if (angleFixed || points.Count == 0) { angleFixed = false; points.Clear(); points.Add(p); points.Add(p); }
            else if (points.Count == 2) { points[1] = p; points.Add(p); }
            else { points[2] = p; angleFixed = true; }
        }
        else { points.Clear(); points.Add(p); points.Add(p); dragging = true; Capture = true; }
        Track(p, straight);
    }
    internal void Track(Drawing.Point p, bool straight = false)
    {
        p = Clamp(p); pointer = p; pointerKnown = true;
        if (points.Count >= 2 && (dragging || (kind == MeasureKind.Angle && !angleFixed)))
            points[^1] = straight && kind == MeasureKind.Distance ? Straight(points[0], p) : p;
        foreach (var area in painted) Invalidate(area);
        painted.Clear(); painted.AddRange(DirtyAreas());
        foreach (var area in painted) Invalidate(area);
    }
    internal void Release(Drawing.Point p, bool straight = false)
    {
        if (!dragging) return;
        Track(p, straight); dragging = false; Capture = false;
    }
    // Angle: done once the centre and both line ends are fixed (three clicks).
    private bool angleFixed;
    internal bool AngleFixed => angleFixed;
    private Drawing.Point Clamp(Drawing.Point p) => new(Math.Clamp(p.X, 0, screen.Width - 1), Math.Clamp(p.Y, 0, screen.Height - 1));
    internal static Drawing.Point Straight(Drawing.Point from, Drawing.Point to)
    {
        var dx = to.X - from.X; var dy = to.Y - from.Y;
        var angle = Math.Round(Math.Atan2(dy, dx) / (Math.PI / 4)) * (Math.PI / 4);
        var distance = Math.Sqrt(dx * dx + dy * dy);
        return new(from.X + (int)Math.Round(Math.Cos(angle) * distance), from.Y + (int)Math.Round(Math.Sin(angle) * distance));
    }
    internal static double Distance(Drawing.Point a, Drawing.Point b) => Math.Sqrt(Math.Pow(b.X - a.X, 2) + Math.Pow(b.Y - a.Y, 2));
    // The angle between the lines centre→a and centre→b, 0–180 degrees.
    internal static double Angle(Drawing.Point centre, Drawing.Point a, Drawing.Point b)
    {
        var first = Math.Atan2(a.Y - centre.Y, a.X - centre.X); var second = Math.Atan2(b.Y - centre.Y, b.X - centre.X);
        var degrees = Math.Abs(second - first) * 180 / Math.PI;
        return degrees > 180 ? 360 - degrees : degrees;
    }
    // The result, as shown in the panel.
    internal string Result
    {
        get
        {
            switch (kind)
            {
                case MeasureKind.Rectangle when points.Count == 2:
                    var r = ScreenCapture.Normalize(points[0], new(points[1].X + 1, points[1].Y + 1));
                    return $"W × H = {r.Width} × {r.Height} px";
                case MeasureKind.Distance when points.Count == 2:
                    return string.Create(CultureInfo.InvariantCulture, $"D={Distance(points[0], points[1]):0.#} px");
                case MeasureKind.Angle when points.Count == 3:
                    return string.Create(CultureInfo.InvariantCulture, $"Angle = {Angle(points[0], points[1], points[2]):0.#}°");
                default:
                    return kind == MeasureKind.Angle ? "Protractor" : $"{pointer.X + screen.X}, {pointer.Y + screen.Y}";
            }
        }
    }
    private string Steps => kind switch
    {
        MeasureKind.Rectangle => "Drag round something to measure its width and height.\nEsc or right-click closes.",
        MeasureKind.Distance => "Drag between two points. Shift keeps the line straight.\nEsc or right-click closes.",
        _ => (points.Count == 0 || angleFixed ? "▶ " : "   ") + "1. Click the centre point\n" + (points.Count == 2 ? "▶ " : "   ") + "2. Click the end of the first line\n" +
             (points.Count == 3 && !angleFixed ? "▶ " : "   ") + "3. Click the end of the second line\nEsc or right-click closes.",
    };

    // ---- Repainting only what changed (the frozen screen can be very large) ----
    private IEnumerable<Drawing.Rectangle> DirtyAreas()
    {
        if (points.Count > 0)
        {
            var b = ScreenCapture.Bounds(points); var margin = (int)(140 * scale);
            b.Inflate(margin, margin); yield return b;
        }
        if (pointerKnown) { var p = Panel(); p.Inflate(4, 4); yield return p; }
    }
    private Drawing.Rectangle Panel()
    {
        var width = (int)(300 * scale); var height = (int)(300 * scale);
        var monitor = ScreenCapture.MonitorAt(new(pointer.X + screen.X, pointer.Y + screen.Y));
        var left = monitor.X - screen.X; var top = monitor.Y - screen.Y; var gap = (int)(16 * scale);
        var panel = new Drawing.Rectangle(left + monitor.Width - width - gap, top + monitor.Height - height - gap, width, height);
        var near = Drawing.Rectangle.Inflate(panel, (int)(40 * scale), (int)(40 * scale));
        if (near.Contains(pointer)) panel.X = left + gap; // Out of the way of the pointer.
        return panel;
    }
    protected override void OnPaint(Forms.PaintEventArgs e)
    {
        var g = e.Graphics; var clip = e.ClipRectangle;
        g.DrawImage(desktop, clip, clip, Drawing.GraphicsUnit.Pixel);
        g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.AntiAlias;
        using var pen = new Drawing.Pen(Line, Math.Max(1, scale));
        using var dot = new Drawing.SolidBrush(Line);
        var r = 3 * scale;
        switch (kind)
        {
            case MeasureKind.Rectangle when points.Count == 2:
                var box = ScreenCapture.Normalize(points[0], new(points[1].X + 1, points[1].Y + 1));
                g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.None;
                g.DrawRectangle(pen, box.X, box.Y, Math.Max(1, box.Width - 1), Math.Max(1, box.Height - 1));
                Label(g, $"{box.Width} × {box.Height}", new(box.X, box.Bottom + (int)(4 * scale)));
                break;
            case MeasureKind.Distance when points.Count == 2:
                g.DrawLine(pen, points[0], points[1]);
                foreach (var p in points) g.FillEllipse(dot, p.X - r, p.Y - r, 2 * r, 2 * r);
                Label(g, string.Create(CultureInfo.InvariantCulture, $"D={Distance(points[0], points[1]):0.#} px  ({Math.Abs(points[1].X - points[0].X)} × {Math.Abs(points[1].Y - points[0].Y)})"), new(points[1].X + (int)(10 * scale), points[1].Y + (int)(10 * scale)));
                break;
            case MeasureKind.Angle when points.Count >= 1:
                foreach (var p in points.Skip(1)) g.DrawLine(pen, points[0], p);
                foreach (var p in points) g.FillEllipse(dot, p.X - r, p.Y - r, 2 * r, 2 * r);
                if (points.Count == 3 && points[1] != points[0] && points[2] != points[0])
                {
                    var radius = (float)Math.Min(40 * scale, Math.Min(Distance(points[0], points[1]), Distance(points[0], points[2])));
                    var start = (float)(Math.Atan2(points[1].Y - points[0].Y, points[1].X - points[0].X) * 180 / Math.PI);
                    var end = (float)(Math.Atan2(points[2].Y - points[0].Y, points[2].X - points[0].X) * 180 / Math.PI);
                    var sweep = end - start; if (sweep > 180) sweep -= 360; if (sweep < -180) sweep += 360;
                    if (radius > 2) g.DrawArc(pen, points[0].X - radius, points[0].Y - radius, 2 * radius, 2 * radius, start, sweep);
                    Label(g, Result, new(points[0].X + (int)(12 * scale), points[0].Y + (int)(12 * scale)));
                }
                break;
        }
        g.SmoothingMode = Drawing.Drawing2D.SmoothingMode.None;
        if (pointerKnown) DrawPanel(g);
    }
    private void DrawPanel(Drawing.Graphics g)
    {
        var panel = Panel();
        var lensSize = (int)(170 * scale);
        var lens = new Drawing.Rectangle(panel.X, panel.Y, panel.Width, lensSize);
        g.FillRectangle(Drawing.Brushes.Black, lens);
        var cell = lens.Width / (float)MagnifierSource;
        var rows = (int)Math.Ceiling(lens.Height / cell);
        var source = new Drawing.RectangleF(pointer.X - MagnifierSource / 2f, pointer.Y - rows / 2f, MagnifierSource, rows);
        g.InterpolationMode = Drawing.Drawing2D.InterpolationMode.NearestNeighbor; g.PixelOffsetMode = Drawing.Drawing2D.PixelOffsetMode.Half;
        g.SetClip(lens);
        g.DrawImage(desktop, new Drawing.RectangleF(lens.X, lens.Y, lens.Width, rows * cell), source, Drawing.GraphicsUnit.Pixel);
        g.ResetClip();
        g.InterpolationMode = Drawing.Drawing2D.InterpolationMode.Default; g.PixelOffsetMode = Drawing.Drawing2D.PixelOffsetMode.Default;
        using (var cross = new Drawing.Pen(Line, Math.Max(2, cell / 3)))
        {
            var cx = lens.X + lens.Width / 2f; var cy = lens.Y + lens.Height / 2f;
            g.DrawLine(cross, cx - cell * 2, cy, cx + cell * 2, cy); g.DrawLine(cross, cx, cy - cell * 2, cx, cy + cell * 2);
        }
        g.DrawRectangle(Drawing.Pens.White, lens.X, lens.Y, lens.Width - 1, lens.Height - 1);
        var title = new Drawing.Rectangle(panel.X, lens.Bottom, panel.Width, (int)(28 * scale));
        using (var grey = new Drawing.SolidBrush(Drawing.Color.FromArgb(200, 200, 200))) g.FillRectangle(grey, title);
        Forms.TextRenderer.DrawText(g, Result, bold, title, Drawing.Color.FromArgb(16, 32, 120), Forms.TextFormatFlags.HorizontalCenter | Forms.TextFormatFlags.VerticalCenter);
        var steps = new Drawing.Rectangle(panel.X, title.Bottom, panel.Width, panel.Bottom - title.Bottom);
        using (var blue = new Drawing.SolidBrush(Drawing.Color.FromArgb(50, 100, 160))) g.FillRectangle(blue, steps);
        var text = Drawing.Rectangle.Inflate(steps, -(int)(10 * scale), -(int)(8 * scale));
        Forms.TextRenderer.DrawText(g, Steps, font, text, Drawing.Color.White, Forms.TextFormatFlags.WordBreak | Forms.TextFormatFlags.Left | Forms.TextFormatFlags.Top);
    }
    private void Label(Drawing.Graphics g, string text, Drawing.Point at)
    {
        var size = Forms.TextRenderer.MeasureText(g, text, font);
        var box = new Drawing.Rectangle(Math.Min(at.X, screen.Width - size.Width - (int)(8 * scale)), Math.Min(at.Y, screen.Height - (int)(22 * scale)), size.Width + (int)(8 * scale), (int)(20 * scale));
        g.FillRectangle(Drawing.Brushes.Black, box);
        Forms.TextRenderer.DrawText(g, text, font, box, Drawing.Color.White, Forms.TextFormatFlags.HorizontalCenter | Forms.TextFormatFlags.VerticalCenter);
    }
    protected override void Dispose(bool disposing) { if (disposing) { font?.Dispose(); bold?.Dispose(); } base.Dispose(disposing); }
    [DllImport("user32.dll")] private static extern uint GetDpiForWindow(IntPtr handle);
}
