using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;

namespace TinyRedaction.Desktop;

// A number box with ▲▼ buttons (0.15.0, David's screenshot): the one width / size adjuster
// used by every drawing tool, in the options bar and the floating Line window. Type a number and
// press Enter (or click away), click ▲▼, use the Up/Down keys or the mouse wheel. Out-of-range
// numbers are pulled back between Minimum and Maximum.
public sealed class NumberSpinner : UserControl
{
    public static readonly DependencyProperty ValueProperty = DependencyProperty.Register(nameof(Value), typeof(double), typeof(NumberSpinner),
        new FrameworkPropertyMetadata(1d, FrameworkPropertyMetadataOptions.BindsTwoWayByDefault, (d, e) => ((NumberSpinner)d).OnValueChanged((double)e.OldValue, (double)e.NewValue), (d, v) => ((NumberSpinner)d).Clamp((double)v)));
    public static readonly RoutedEvent ValueChangedEvent = EventManager.RegisterRoutedEvent(nameof(ValueChanged), RoutingStrategy.Bubble, typeof(RoutedPropertyChangedEventHandler<double>), typeof(NumberSpinner));
    private readonly TextBox box = new() { Width = 38, Margin = new Thickness(0), Padding = new Thickness(3, 2, 3, 2), VerticalContentAlignment = VerticalAlignment.Center };
    private readonly RepeatButton up = new() { Content = "▲", Tag = 1, Focusable = false }, down = new() { Content = "▼", Tag = -1, Focusable = false };
    public NumberSpinner()
    {
        foreach (var button in new[] { up, down })
        {
            button.SetResourceReference(StyleProperty, "EditorFlatRepeat");
            button.Padding = new Thickness(3, 0, 3, 0); button.FontSize = 7; button.Delay = 400; button.Interval = 80;
            button.Click += (_, _) => Step((int)button.Tag);
        }
        up.ToolTip = "Larger"; down.ToolTip = "Smaller";
        var arrows = new StackPanel { Margin = new Thickness(1, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center };
        arrows.Children.Add(up); arrows.Children.Add(down);
        var row = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center };
        row.Children.Add(box); row.Children.Add(arrows);
        Content = row;
        box.Text = Format(Value);
        box.LostKeyboardFocus += (_, _) => Commit();
        box.PreviewKeyDown += (_, e) =>
        {
            if (e.Key == Key.Enter) { Commit(); e.Handled = true; }
            else if (e.Key == Key.Up) { Step(1); e.Handled = true; }
            else if (e.Key == Key.Down) { Step(-1); e.Handled = true; }
        };
        PreviewMouseWheel += (_, e) => { if (IsEnabled) { Step(e.Delta > 0 ? 1 : -1); e.Handled = true; } };
    }
    public double Value { get => (double)GetValue(ValueProperty); set => SetValue(ValueProperty, value); }
    public double Minimum { get; set; } = 1;
    public double Maximum { get; set; } = 100;
    public double Increment { get; set; } = 1;
    public int Decimals { get; set; }
    public event RoutedPropertyChangedEventHandler<double> ValueChanged { add => AddHandler(ValueChangedEvent, value); remove => RemoveHandler(ValueChangedEvent, value); }
    internal TextBox Box => box;
    internal void Step(int direction) { Commit(); Value = Math.Round(Value + direction * Increment, Decimals); }
    // Reads what was typed; anything that is not a number leaves the value as it was.
    internal void Commit()
    {
        if (double.TryParse(box.Text, NumberStyles.Float, CultureInfo.InvariantCulture, out var typed) && double.IsFinite(typed)) Value = Math.Round(typed, Decimals);
        box.Text = Format(Value);
    }
    private double Clamp(double v) => double.IsFinite(v) ? Math.Clamp(v, Minimum, Maximum) : Minimum;
    private string Format(double v) => v.ToString(Decimals == 0 ? "0" : "0.#", CultureInfo.InvariantCulture);
    private void OnValueChanged(double before, double after)
    {
        box.Text = Format(after);
        up.IsEnabled = after < Maximum; down.IsEnabled = after > Minimum;
        RaiseEvent(new RoutedPropertyChangedEventArgs<double>(before, after, ValueChangedEvent));
    }
}
