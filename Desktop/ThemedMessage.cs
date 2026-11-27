using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace TinyRedaction.Desktop;

// TRT's message box (0.28.0, David: dialogue boxes follow Light and Dark). Windows' own MessageBox is always light, so
// TRT draws its own with the theme's colours: an icon, the message, and the usual buttons (Enter is the first, Esc the
// last). It answers as MessageBox does, so callers keep their MessageBoxResult checks.
internal sealed class ThemedMessage : Window
{
    // Checks answer instead of a person (a modal box on an off-screen window would wait forever).
    internal static Func<string, string, MessageBoxButton, MessageBoxResult>? Answer { get; set; }
    public MessageBoxResult Result { get; private set; }

    public static MessageBoxResult Show(string text, string caption = "TinyRedactionTool", MessageBoxButton buttons = MessageBoxButton.OK, MessageBoxImage image = MessageBoxImage.None) =>
        Show(null, text, caption, buttons, image);
    public static MessageBoxResult Show(Window? owner, string text, string caption = "TinyRedactionTool", MessageBoxButton buttons = MessageBoxButton.OK, MessageBoxImage image = MessageBoxImage.None)
    {
        if (Answer is { } answer) return answer(text, caption, buttons);
        var box = new ThemedMessage(text, caption, buttons, image);
        if (owner is { IsVisible: true } && owner.IsLoaded) { box.Owner = owner; box.WindowStartupLocation = WindowStartupLocation.CenterOwner; }
        else { box.WindowStartupLocation = WindowStartupLocation.CenterScreen; box.Topmost = true; }
        box.ShowDialog();
        return box.Result;
    }

    // 3.5.0 (David): the unsaved screenshot questions. One sentence per line, [Cancel] on its own at the left, [No] [Yes]
    // at the right, Yes the default (Enter); Esc is Cancel. The box is only as wide as its lines.
    internal static MessageBoxResult ShowUnsaved(Window? owner, string text, string caption)
    {
        if (Answer is { } answer) return answer(text, caption, MessageBoxButton.YesNoCancel);
        var box = new ThemedMessage(text, caption, MessageBoxButton.YesNoCancel, MessageBoxImage.Warning, split: true);
        if (owner is { IsVisible: true } && owner.IsLoaded) { box.Owner = owner; box.WindowStartupLocation = WindowStartupLocation.CenterOwner; }
        else { box.WindowStartupLocation = WindowStartupLocation.CenterScreen; box.Topmost = true; }
        box.ShowDialog();
        return box.Result;
    }

    internal ThemedMessage(string text, string caption, MessageBoxButton buttons, MessageBoxImage image, bool split = false)
    {
        Title = caption; SizeToContent = SizeToContent.WidthAndHeight; ResizeMode = ResizeMode.NoResize; ShowInTaskbar = false;
        MinWidth = split ? 0 : 320; MaxWidth = 560; FontFamily = new FontFamily("Segoe UI"); FontSize = 13;
        SetResourceReference(BackgroundProperty, "Background"); SetResourceReference(ForegroundProperty, "Foreground");
        if (split) { Content = SplitLayout(text, caption, image); return; }
        var choices = buttons switch
        {
            MessageBoxButton.OKCancel => new[] { MessageBoxResult.OK, MessageBoxResult.Cancel },
            MessageBoxButton.YesNo => [MessageBoxResult.Yes, MessageBoxResult.No],
            MessageBoxButton.YesNoCancel => [MessageBoxResult.Yes, MessageBoxResult.No, MessageBoxResult.Cancel],
            _ => [MessageBoxResult.OK],
        };
        Result = choices[^1] == MessageBoxResult.OK ? MessageBoxResult.OK : choices[^1];

        var message = new DockPanel { Margin = new Thickness(20, 18, 24, 18) };
        if (Glyph(image) is { } glyph) { DockPanel.SetDock(glyph, Dock.Left); message.Children.Add(glyph); }
        message.Children.Add(new TextBlock { Name = "MessageText", Text = text, TextWrapping = TextWrapping.Wrap, VerticalAlignment = VerticalAlignment.Center, LineHeight = 19, MaxWidth = 460 });

        var row = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(12, 10, 12, 12) };
        foreach (var choice in choices)
        {
            var button = new Button { Content = choice.ToString(), MinWidth = 84, Margin = new Thickness(6, 0, 0, 0), Padding = new Thickness(12, 5, 12, 5), IsDefault = choice == choices[0], IsCancel = choice == choices[^1], Tag = choice };
            if (choice == choices[0]) { button.SetResourceReference(BackgroundProperty, "ToolSelected"); button.SetResourceReference(ForegroundProperty, "ToolSelectedText"); }
            button.Click += (_, _) => { Result = (MessageBoxResult)button.Tag; DialogResult = true; };
            row.Children.Add(button);
        }
        var footer = new Border { Child = row, BorderThickness = new Thickness(0, 1, 0, 0) };
        footer.SetResourceReference(Border.BackgroundProperty, "Surface"); footer.SetResourceReference(Border.BorderBrushProperty, "ChromeLine");
        var layout = new DockPanel();
        DockPanel.SetDock(footer, Dock.Bottom); layout.Children.Add(footer); layout.Children.Add(message);
        Content = layout;
        // Ctrl+C copies the message, as Windows' box does.
        KeyDown += (_, e) => { if (e.Key == Key.C && Keyboard.Modifiers == ModifierKeys.Control) try { Clipboard.SetText(caption + "\n\n" + text); } catch (System.Runtime.InteropServices.ExternalException) { } };
    }

    private DockPanel SplitLayout(string text, string caption, MessageBoxImage image)
    {
        Result = MessageBoxResult.Cancel; // Closing the box keeps everything as it is.
        var message = new DockPanel { Margin = new Thickness(20, 18, 24, 18) };
        if (Glyph(image) is { } glyph) { DockPanel.SetDock(glyph, Dock.Left); message.Children.Add(glyph); }
        message.Children.Add(new TextBlock { Name = "MessageText", Text = text, VerticalAlignment = VerticalAlignment.Center, LineHeight = 19 });
        Button Make(MessageBoxResult choice)
        {
            var button = new Button { Content = choice.ToString(), MinWidth = 76, Padding = new Thickness(12, 5, 12, 5), Tag = choice, IsDefault = choice == MessageBoxResult.Yes, IsCancel = choice == MessageBoxResult.Cancel };
            if (choice == MessageBoxResult.Yes) { button.SetResourceReference(BackgroundProperty, "ToolSelected"); button.SetResourceReference(ForegroundProperty, "ToolSelectedText"); }
            button.Click += (_, _) => { Result = choice; DialogResult = true; };
            return button;
        }
        var row = new DockPanel { Margin = new Thickness(12, 10, 12, 12), LastChildFill = false };
        var cancel = Make(MessageBoxResult.Cancel); DockPanel.SetDock(cancel, Dock.Left); row.Children.Add(cancel);
        var yes = Make(MessageBoxResult.Yes); yes.Margin = new Thickness(6, 0, 0, 0); DockPanel.SetDock(yes, Dock.Right); row.Children.Add(yes);
        var no = Make(MessageBoxResult.No); no.Margin = new Thickness(24, 0, 0, 0); DockPanel.SetDock(no, Dock.Right); row.Children.Add(no);
        var footer = new Border { Child = row, BorderThickness = new Thickness(0, 1, 0, 0) };
        footer.SetResourceReference(Border.BackgroundProperty, "Surface"); footer.SetResourceReference(Border.BorderBrushProperty, "ChromeLine");
        var layout = new DockPanel();
        DockPanel.SetDock(footer, Dock.Bottom); layout.Children.Add(footer); layout.Children.Add(message);
        KeyDown += (_, e) => { if (e.Key == Key.C && Keyboard.Modifiers == ModifierKeys.Control) try { Clipboard.SetText(caption + "\n\n" + text); } catch (System.Runtime.InteropServices.ExternalException) { } };
        Loaded += (_, _) => yes.Focus();
        return layout;
    }

    // A round badge with !, ? or i, in TRT's own drawing.
    private static FrameworkElement? Glyph(MessageBoxImage image)
    {
        var (colour, mark) = image switch
        {
            MessageBoxImage.Error => (Color.FromRgb(0xD3, 0x2F, 0x2F), "✕"),
            MessageBoxImage.Warning => (Color.FromRgb(0xE0, 0x9A, 0x10), "!"),
            MessageBoxImage.Question => (Color.FromRgb(0x1A, 0x73, 0xE8), "?"),
            MessageBoxImage.Information => (Color.FromRgb(0x1A, 0x73, 0xE8), "i"),
            _ => (Colors.Transparent, ""),
        };
        if (mark.Length == 0) return null;
        var badge = new Grid { Width = 32, Height = 32, Margin = new Thickness(0, 0, 16, 0), VerticalAlignment = VerticalAlignment.Top };
        badge.Children.Add(new System.Windows.Shapes.Ellipse { Fill = new SolidColorBrush(colour) });
        badge.Children.Add(new TextBlock { Text = mark, Foreground = Brushes.White, FontWeight = FontWeights.Bold, FontSize = 18, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center });
        return badge;
    }
}
