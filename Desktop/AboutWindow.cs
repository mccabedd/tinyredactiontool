using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace TinyRedaction.Desktop;

// The About box (0.27.1, David: simple, like the original TRT's; 0.28.0: in this TRT's own style). It follows Light and
// Dark like the other windows: the app icon beside the name and version, David's description, then copyright, the
// privacy line, licence and the source address with a Copy button, and Close in the footer bar as in the message boxes.
internal sealed class AboutWindow : Window
{
    public const string Description =
        "A lightweight Windows tool for redacting and editing sensitive areas in videos and images using black box, blur or pixelation. " +
        "Supports multiple selection shapes, frame-range redactions, broad media input support and a stand-alone single-EXE build with an embedded custom FFmpeg.";
    public const string SourceAddress = "https://github.com/mccabedd/tinyredactiontool/";

    // The TRT icon inside the program (named by assembly, so it also loads when the checks run this window).
    internal static Uri AppIcon => new($"pack://application:,,,/{typeof(AboutWindow).Assembly.GetName().Name};component/Assets/icon.ico");
    public AboutWindow(string version)
    {
        Title = "About TinyRedactionTool";
        Width = 560; SizeToContent = SizeToContent.Height; ResizeMode = ResizeMode.NoResize; ShowInTaskbar = false;
        WindowStartupLocation = WindowStartupLocation.CenterOwner; FontFamily = new FontFamily("Segoe UI");
        SetResourceReference(BackgroundProperty, "Background"); SetResourceReference(ForegroundProperty, "Foreground");
        try { Icon = BitmapFrame.Create(AppIcon); } catch (Exception ex) when (ex is IOException or UriFormatException or NotSupportedException) { }

        var panel = new StackPanel { Margin = new Thickness(28, 22, 28, 18) };
        TextBlock Line(string text, double size, FontWeight weight, double top, string colour = "Foreground", double opacity = 1)
        {
            var block = new TextBlock { Text = text, FontSize = size, FontWeight = weight, Margin = new Thickness(0, top, 0, 0), Opacity = opacity, TextWrapping = TextWrapping.Wrap };
            block.SetResourceReference(TextBlock.ForegroundProperty, colour); return block;
        }
        // Heading: the icon, the name, and the version under it.
        var heading = new DockPanel();
        var icon = new Image { Width = 48, Height = 48, Margin = new Thickness(0, 0, 14, 0), VerticalAlignment = VerticalAlignment.Center };
        try { icon.Source = BitmapFrame.Create(AppIcon); } catch (Exception ex) when (ex is IOException or UriFormatException or NotSupportedException) { }
        DockPanel.SetDock(icon, Dock.Left); heading.Children.Add(icon);
        var names = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        names.Children.Add(Line($"TinyRedactionTool v{version}", 20, FontWeights.SemiBold, 0));
        names.Children.Add(Line("Copyright (C) 2026 David McCabe", 12, FontWeights.Normal, 2, opacity: 0.75));
        heading.Children.Add(names);
        panel.Children.Add(heading);

        // David's description, on a card in the theme's panel colour.
        var description = Line(Description, 13, FontWeights.Normal, 0); description.LineHeight = 20;
        var card = new Border { Child = description, Padding = new Thickness(14, 12, 14, 12), Margin = new Thickness(0, 18, 0, 0), CornerRadius = new CornerRadius(4), BorderThickness = new Thickness(1) };
        card.SetResourceReference(Border.BackgroundProperty, "Surface"); card.SetResourceReference(Border.BorderBrushProperty, "ChromeLine");
        panel.Children.Add(card);

        panel.Children.Add(Line("Local media processing. No telemetry or media uploads.", 12.5, FontWeights.SemiBold, 16));
        panel.Children.Add(Line("Licensed under GPL-2.0-or-later. Source available on GitHub.", 12, FontWeights.Normal, 4, opacity: 0.75));

        var address = new DockPanel { Margin = new Thickness(0, 10, 0, 0) };
        var copy = new Button { Name = "CopyAddressButton", Content = "Copy", ToolTip = "Copy the Address", Padding = new Thickness(10, 2, 10, 2), Margin = new Thickness(10, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center };
        copy.Click += (_, _) => { try { Clipboard.SetText(SourceAddress); copy.Content = "Copied"; } catch (System.Runtime.InteropServices.ExternalException) { } };
        DockPanel.SetDock(copy, Dock.Right); address.Children.Add(copy);
        var link = Line(SourceAddress, 12.5, FontWeights.Normal, 0, "ToolHoverBorder"); link.VerticalAlignment = VerticalAlignment.Center;
        address.Children.Add(link);
        panel.Children.Add(address);

        // Footer bar with Close, as in TRT's message boxes.
        var close = new Button { Name = "CloseButton", Content = "Close", MinWidth = 84, Padding = new Thickness(12, 5, 12, 5), IsDefault = true, IsCancel = true, HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(12, 10, 12, 12) };
        close.SetResourceReference(BackgroundProperty, "ToolSelected"); close.SetResourceReference(ForegroundProperty, "ToolSelectedText");
        close.Click += (_, _) => Close();
        var footer = new Border { Child = close, BorderThickness = new Thickness(0, 1, 0, 0) };
        footer.SetResourceReference(Border.BackgroundProperty, "Surface"); footer.SetResourceReference(Border.BorderBrushProperty, "ChromeLine");
        var layout = new DockPanel();
        DockPanel.SetDock(footer, Dock.Bottom); layout.Children.Add(footer); layout.Children.Add(panel);
        Content = layout;
    }

    public static void Open(Window? owner, string version)
    {
        var window = new AboutWindow(version);
        if (owner is { IsVisible: true }) window.Owner = owner; else window.WindowStartupLocation = WindowStartupLocation.CenterScreen;
        window.ShowDialog();
    }
}
