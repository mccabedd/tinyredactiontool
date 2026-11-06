using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace TinyRedaction.Desktop;

// Icon-over-caption toolbar buttons (TRT's own vector artwork).
// Icon is stroked in the button's foreground; Accent is filled with AccentBrush underneath it.
public static class Toolbar
{
    public static readonly DependencyProperty IconProperty = DependencyProperty.RegisterAttached("Icon", typeof(Geometry), typeof(Toolbar));
    public static readonly DependencyProperty AccentProperty = DependencyProperty.RegisterAttached("Accent", typeof(Geometry), typeof(Toolbar));
    public static readonly DependencyProperty AccentBrushProperty = DependencyProperty.RegisterAttached("AccentBrush", typeof(Brush), typeof(Toolbar));
    public static Geometry? GetIcon(DependencyObject o) => (Geometry?)o.GetValue(IconProperty);
    public static void SetIcon(DependencyObject o, Geometry? value) => o.SetValue(IconProperty, value);
    public static Geometry? GetAccent(DependencyObject o) => (Geometry?)o.GetValue(AccentProperty);
    public static void SetAccent(DependencyObject o, Geometry? value) => o.SetValue(AccentProperty, value);
    // IconFill (0.18.0): parts of the picture filled in the text colour, such as the solid eyedropper.
    public static readonly DependencyProperty IconFillProperty = DependencyProperty.RegisterAttached("IconFill", typeof(Geometry), typeof(Toolbar));
    public static Geometry? GetIconFill(DependencyObject o) => (Geometry?)o.GetValue(IconFillProperty);
    public static void SetIconFill(DependencyObject o, Geometry? value) => o.SetValue(IconFillProperty, value);
    public static Brush? GetAccentBrush(DependencyObject o) => (Brush?)o.GetValue(AccentBrushProperty);
    public static void SetAccentBrush(DependencyObject o, Brush? value) => o.SetValue(AccentBrushProperty, value);
    // Drawn size of an IconButton's picture (0.16.0: larger play and frame-step buttons); the artwork stays on its 20 × 20 grid.
    public static readonly DependencyProperty IconSizeProperty = DependencyProperty.RegisterAttached("IconSize", typeof(double), typeof(Toolbar), new FrameworkPropertyMetadata(20d));
    public static double GetIconSize(DependencyObject o) => (double)o.GetValue(IconSizeProperty);
    public static void SetIconSize(DependencyObject o, double value) => o.SetValue(IconSizeProperty, value);
    // Words only (0.16.2): the toolbar shows the two-line caption without the icon, so the button keeps the
    // usual height; Small icons still shows the icon (it has no captions).
    public static readonly DependencyProperty WordsOnlyProperty = DependencyProperty.RegisterAttached("WordsOnly", typeof(bool), typeof(Toolbar), new FrameworkPropertyMetadata(false));
    public static bool GetWordsOnly(DependencyObject o) => (bool)o.GetValue(WordsOnlyProperty);
    public static void SetWordsOnly(DependencyObject o, bool value) => o.SetValue(WordsOnlyProperty, value);
}

// Faster tooltips (0.18.0, David): every TRT window shows a tooltip a quarter of a second after the
// pointer stops, and keeps it up long enough to read.
internal static class ToolTipTiming
{
    private static bool applied;
    public static void Apply()
    {
        if (applied) return;
        applied = true;
        ToolTipService.InitialShowDelayProperty.OverrideMetadata(typeof(FrameworkElement), new FrameworkPropertyMetadata(250));
        ToolTipService.BetweenShowDelayProperty.OverrideMetadata(typeof(FrameworkElement), new FrameworkPropertyMetadata(50));
        ToolTipService.ShowDurationProperty.OverrideMetadata(typeof(FrameworkElement), new FrameworkPropertyMetadata(20000));
    }
}