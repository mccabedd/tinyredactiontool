using System.Runtime.InteropServices;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace TinyRedaction.Desktop;

// While recording (0.12.0; inherited v2.5.0 behaviour): a blinking red border just outside the
// recorded area and a yellow control bar. Windows is asked to keep both out of every screen capture,
// so neither appears in the recording; recording does not start if Windows refuses.
// Both are per-monitor DPI aware Windows Forms windows sized in screen pixels.
internal abstract class RecordingWindow : Forms.Form
{
    protected float DpiScale { get; private set; } = 1;
    public bool CaptureExcluded { get; private set; }
    protected RecordingWindow()
    {
        AutoScaleMode = Forms.AutoScaleMode.None; FormBorderStyle = Forms.FormBorderStyle.None; StartPosition = Forms.FormStartPosition.Manual;
        TopMost = true; ShowInTaskbar = false;
    }
    protected override bool ShowWithoutActivation => true;
    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        try { DpiScale = Math.Max(1, GetDpiForWindow(Handle) / 96f); } catch (EntryPointNotFoundException) { }
        CaptureExcluded = ScreenCapture.ExcludeFromCapture(Handle);
        Arrange();
    }
    protected abstract void Arrange();
    protected override void WndProc(ref Forms.Message m) { if (m.Msg == 0x02E0) { m.Result = IntPtr.Zero; return; } base.WndProc(ref m); }
    [DllImport("user32.dll")] private static extern uint GetDpiForWindow(IntPtr handle);
}

internal sealed class RecordingBorder : RecordingWindow
{
    private readonly Drawing.Rectangle region;
    private readonly Forms.Timer blink = new() { Interval = 500 };
    private bool lit = true, paused;
    private int thickness = 3;
    public RecordingBorder(Drawing.Rectangle recorded)
    {
        region = recorded; BackColor = Drawing.Color.Magenta; TransparencyKey = Drawing.Color.Magenta;
        Bounds = Drawing.Rectangle.Inflate(region, thickness, thickness);
        blink.Tick += (_, _) => { lit = !lit; Invalidate(); }; blink.Start();
    }
    // Click-through, never activated, not in Alt+Tab.
    protected override Forms.CreateParams CreateParams { get { var p = base.CreateParams; p.ExStyle |= 0x080000A8; return p; } }
    protected override void Arrange() { thickness = (int)Math.Ceiling(3 * DpiScale); Bounds = Drawing.Rectangle.Inflate(region, thickness, thickness); }
    public void SetPaused(bool value) { paused = value; lit = true; if (paused) blink.Stop(); else blink.Start(); Invalidate(); }
    protected override void OnPaint(Forms.PaintEventArgs e)
    {
        base.OnPaint(e);
        if (!lit) return;
        using var brush = new Drawing.SolidBrush(paused ? Drawing.Color.FromArgb(255, 200, 40) : Drawing.Color.FromArgb(230, 30, 30));
        e.Graphics.FillRectangle(brush, 0, 0, Width, thickness); e.Graphics.FillRectangle(brush, 0, Height - thickness, Width, thickness);
        e.Graphics.FillRectangle(brush, 0, 0, thickness, Height); e.Graphics.FillRectangle(brush, Width - thickness, 0, thickness, Height);
    }
    protected override void Dispose(bool disposing) { if (disposing) blink.Dispose(); base.Dispose(disposing); }
}

// The yellow control bar: blinking dot, recorded time, Pause/Resume, Stop and save, Discard.
// It sits at the top of the screen that holds the recorded area and can be dragged aside.
internal sealed class RecordingBar : RecordingWindow
{
    private readonly Drawing.Rectangle region;
    private readonly Forms.Timer blink = new() { Interval = 500 };
    private readonly Forms.Button pause = new(), stop = new(), discard = new();
    private readonly Forms.Label time = new();
    private readonly Forms.ToolTip tip = new();
    private Drawing.Font? font, bold;
    private bool lit = true, paused, finishing;
    public event EventHandler? PauseToggled, StopRequested, DiscardRequested;
    public RecordingBar(Drawing.Rectangle recorded, string stopShortcut)
    {
        region = recorded; BackColor = Drawing.Color.FromArgb(255, 220, 65); Text = "TinyRedactionTool recording";
        foreach (var button in new[] { pause, stop, discard })
        {
            button.FlatStyle = Forms.FlatStyle.Flat; button.FlatAppearance.BorderColor = Drawing.Color.FromArgb(150, 120, 20);
            button.BackColor = Drawing.Color.FromArgb(255, 236, 150); button.ForeColor = Drawing.Color.Black; button.TabStop = false; Controls.Add(button);
        }
        pause.Text = "Pause"; stop.Text = "Stop and Save"; discard.Text = "Discard";
        time.Text = "00:00:00"; time.ForeColor = Drawing.Color.Black; time.TextAlign = Drawing.ContentAlignment.MiddleLeft; Controls.Add(time);
        tip.SetToolTip(stop, $"Stop recording and open it in the editor ({AppSettings.DisplayShortcut(stopShortcut)})");
        pause.Click += (_, _) => PauseToggled?.Invoke(this, EventArgs.Empty);
        stop.Click += (_, _) => StopRequested?.Invoke(this, EventArgs.Empty);
        discard.Click += (_, _) => DiscardRequested?.Invoke(this, EventArgs.Empty);
        blink.Tick += (_, _) => { lit = !lit; Invalidate(new Drawing.Rectangle(0, 0, (int)(34 * DpiScale), Height)); }; blink.Start();
        MouseDown += (_, e) => { if (e.Button == Forms.MouseButtons.Left) { ReleaseCapture(); SendMessage(Handle, 0xA1, 2, 0); } };
    }
    protected override Forms.CreateParams CreateParams { get { var p = base.CreateParams; p.ExStyle |= 0x08000088; return p; } }
    protected override void Arrange()
    {
        int S(double v) => (int)Math.Round(v * DpiScale);
        font = new Drawing.Font("Segoe UI", 13 * DpiScale, Drawing.GraphicsUnit.Pixel); bold = new Drawing.Font("Segoe UI", 13 * DpiScale, Drawing.FontStyle.Bold, Drawing.GraphicsUnit.Pixel);
        ClientSize = new(S(400), S(40));
        time.Font = bold; time.SetBounds(S(34), 0, S(84), ClientSize.Height);
        var x = S(122);
        foreach (var (button, width) in new[] { (pause, 74), (stop, 116), (discard, 74) }) { button.Font = font; button.SetBounds(x, S(6), S(width), S(28)); x += S(width) + S(6); }
        var monitor = ScreenCapture.MonitorAt(new(region.X + region.Width / 2, region.Y + region.Height / 2));
        Location = new(monitor.X + (monitor.Width - Width) / 2, monitor.Y + S(8));
    }
    public void SetElapsed(TimeSpan elapsed) => time.Text = elapsed.ToString(@"hh\:mm\:ss");
    public void SetPaused(bool value)
    {
        paused = value; pause.Text = paused ? "Resume" : "Pause"; lit = true;
        if (paused) blink.Stop(); else blink.Start(); Invalidate();
    }
    public void Finishing()
    {
        finishing = true; blink.Stop(); lit = false; stop.Text = "Finishing…";
        pause.Enabled = stop.Enabled = discard.Enabled = false; Invalidate();
    }
    protected override void OnPaint(Forms.PaintEventArgs e)
    {
        base.OnPaint(e);
        if (!lit || finishing) return;
        e.Graphics.SmoothingMode = Drawing.Drawing2D.SmoothingMode.AntiAlias;
        var size = 14 * DpiScale;
        using var brush = new Drawing.SolidBrush(paused ? Drawing.Color.FromArgb(120, 100, 20) : Drawing.Color.FromArgb(220, 30, 30));
        if (paused) { e.Graphics.FillRectangle(brush, 12 * DpiScale, (Height - size) / 2, 4 * DpiScale, size); e.Graphics.FillRectangle(brush, 20 * DpiScale, (Height - size) / 2, 4 * DpiScale, size); }
        else e.Graphics.FillEllipse(brush, 11 * DpiScale, (Height - size) / 2, size, size);
    }
    protected override void Dispose(bool disposing) { if (disposing) { blink.Dispose(); tip.Dispose(); font?.Dispose(); bold?.Dispose(); } base.Dispose(disposing); }
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] private static extern bool ReleaseCapture();
    [DllImport("user32.dll")] private static extern IntPtr SendMessage(IntPtr handle, int message, int wParam, int lParam);
}
