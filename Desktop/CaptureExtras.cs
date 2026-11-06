using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;

namespace TinyRedaction.Desktop;

// A short message near the bottom of the main screen ("Saved to Clipboard", 0.13.0). It never takes
// focus, ignores the mouse and is kept out of screenshots and recordings.
internal sealed class CaptureToast : Window
{
    private static CaptureToast? current;
    private readonly DispatcherTimer timer;
    private CaptureToast(string text, TimeSpan duration)
    {
        WindowStyle = WindowStyle.None; AllowsTransparency = true; Background = Brushes.Transparent; Topmost = true; ShowInTaskbar = false;
        ShowActivated = false; Focusable = false; IsHitTestVisible = false; SizeToContent = SizeToContent.WidthAndHeight; Title = "TinyRedactionTool Notice";
        Content = new Border
        {
            Background = new SolidColorBrush(Color.FromArgb(235, 32, 32, 32)), CornerRadius = new CornerRadius(6), Padding = new Thickness(18, 10, 18, 10),
            Child = new TextBlock { Text = text, Foreground = Brushes.White, FontFamily = new FontFamily("Segoe UI"), FontSize = 14, FontWeight = FontWeights.SemiBold },
        };
        timer = new DispatcherTimer { Interval = duration };
        timer.Tick += (_, _) => { timer.Stop(); Close(); };
        SourceInitialized += (_, _) => ScreenCapture.ExcludeFromCapture(new WindowInteropHelper(this).Handle);
        Loaded += (_, _) =>
        {
            var area = SystemParameters.WorkArea;
            Left = area.Left + (area.Width - ActualWidth) / 2; Top = area.Bottom - ActualHeight - 48;
        };
        Closed += (_, _) => { if (current == this) current = null; };
    }
    internal static string? LastText { get; private set; }
    public static void Show(string text, double seconds = 2)
    {
        LastText = text;
        current?.Close();
        current = new CaptureToast(text, TimeSpan.FromSeconds(seconds)) { Left = -20000, Top = -20000 };
        current.Show(); current.timer.Start();
    }
}

// The capture bar's hidden form (0.13.0): a short red tab on the top edge of the
// screen, under the bar's left end. Pointing at it (or clicking it) brings the capture bar back.
// 0.14.0: its width is set in Settings (David).
internal sealed class MinimizedStrip : Window
{
    public event EventHandler? Restore;
    internal const double StripThickness = 3;
    public MinimizedStrip()
    {
        WindowStyle = WindowStyle.None; ResizeMode = ResizeMode.NoResize; Topmost = true; ShowInTaskbar = false; ShowActivated = false;
        // 0.22.0 (David): half as thick as before (6 → 3).
        Background = new SolidColorBrush(Color.FromRgb(214, 48, 48)); Height = StripThickness; Width = AppSettings.DefaultStripWidth; Title = "TinyRedactionTool";
        ToolTip = "Point Here to Show the Capture Bar";
        Cursor = Cursors.Hand;
        MouseEnter += (_, _) => Restore?.Invoke(this, EventArgs.Empty);
        MouseLeftButtonDown += (_, _) => Restore?.Invoke(this, EventArgs.Empty);
    }
    // At the top of the work area that holds the bar, starting under the bar's left end.
    public void Place(double barLeft, Rect area, int width)
    {
        Width = Math.Clamp(width, AppSettings.MinStripWidth, AppSettings.MaxStripWidth);
        Left = Math.Clamp(barLeft, area.Left, Math.Max(area.Left, area.Right - Width));
        Top = area.Top;
    }
}
