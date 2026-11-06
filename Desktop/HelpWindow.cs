using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace TinyRedaction.Desktop;

// 3.0.0 (David): Help › Help (F1) opens the manual in TRT's own window, on any PC, whatever browser it has (or none):
// the contents on the left, the manual on the right, in TRT's Light or Dark theme. One Help window at a time.
internal sealed class HelpWindow : Window
{
    internal static HelpWindow? Current { get; private set; }
    internal HelpDocument Manual { get; private set; }
    internal ListBox Contents { get; } = new() { BorderThickness = new Thickness(0), Width = 250, Padding = new Thickness(10, 10, 6, 30) };
    internal FlowDocumentScrollViewer Viewer { get; } = new() { IsToolBarVisible = false, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled, Focusable = true };
    private readonly Border header = new() { BorderThickness = new Thickness(0, 0, 0, 1), Padding = new Thickness(24, 14, 24, 14) };
    private readonly Border side = new() { BorderThickness = new Thickness(0, 0, 1, 0) };
    private readonly TextBlock titleText = new() { FontSize = 22, FontWeight = FontWeights.SemiBold };
    private readonly TextBlock subtitleText = new() { FontSize = 13, Margin = new Thickness(0, 2, 0, 0), TextWrapping = TextWrapping.Wrap };
    private bool dark;

    public HelpWindow()
    {
        Title = "TinyRedactionTool Help"; FontFamily = new FontFamily("Segoe UI");
        var work = SystemParameters.WorkArea;
        Width = Math.Min(1180, work.Width * 0.9); Height = Math.Min(880, work.Height * 0.9); MinWidth = 620; MinHeight = 400;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        var iconPath = Path.Combine(Path.GetDirectoryName(HelpManual.ManualPath)!, "images", "help-icon-48.png");
        try { if (File.Exists(iconPath)) Icon = BitmapFrame.Create(new Uri(iconPath), BitmapCreateOptions.None, BitmapCacheOption.OnLoad); }
        catch (Exception ex) when (ex is IOException or NotSupportedException or UriFormatException) { }
        Resources.Add(typeof(System.Windows.Controls.Primitives.ScrollBar), FileInfoWindow.ThinScrollBar);
        Resources.Add(SystemColors.ControlBrushKey, Brushes.Transparent);

        var heading = new DockPanel();
        var icon = new Image { Width = 44, Height = 44, Margin = new Thickness(0, 0, 14, 0), VerticalAlignment = VerticalAlignment.Center, Source = Icon };
        DockPanel.SetDock(icon, Dock.Left); heading.Children.Add(icon);
        var names = new StackPanel { VerticalAlignment = VerticalAlignment.Center }; names.Children.Add(titleText); names.Children.Add(subtitleText);
        heading.Children.Add(names); header.Child = heading;

        side.Child = Contents;
        Contents.SelectionChanged += (_, _) => { if (Contents.SelectedItem is ListBoxItem { Tag: string id }) ShowTopic(id); };
        ScrollViewer.SetHorizontalScrollBarVisibility(Contents, ScrollBarVisibility.Disabled);

        var layout = new DockPanel();
        DockPanel.SetDock(header, Dock.Top); layout.Children.Add(header);
        DockPanel.SetDock(side, Dock.Left); layout.Children.Add(side);
        layout.Children.Add(Viewer);
        Content = layout;

        Manual = Build(MainWindow.DarkTheme);
        MainWindow.ThemeApplied += ThemeChanged;
        Closed += (_, _) => { MainWindow.ThemeApplied -= ThemeChanged; if (Current == this) Current = null; };
        KeyDown += (_, e) => { if (e.Key == Key.Escape) Close(); };
        Loaded += (_, _) => Viewer.Focus();
    }

    private void ThemeChanged(bool nowDark) => Dispatcher.BeginInvoke(() => { if (nowDark != dark) { var at = Scroller()?.VerticalOffset ?? 0; Manual = Build(nowDark); UpdateLayout(); Scroller()?.ScrollToVerticalOffset(at); } });

    private HelpDocument Build(bool useDark)
    {
        dark = useDark;
        var manual = new HelpDocument(HelpManual.ManualPath, useDark);
        var pal = HelpPalette.For(useDark);
        Background = pal.Brush(pal.Back); Foreground = pal.Brush(pal.Text);
        header.Background = pal.Brush(pal.Panel); header.BorderBrush = side.BorderBrush = pal.Brush(pal.Line);
        Contents.Background = pal.Brush(pal.Back); Contents.Foreground = pal.Brush(pal.Text);
        Viewer.Background = pal.Brush(pal.Back);
        Resources["Foreground"] = pal.Brush(pal.Text); // The thin scroll bars' thumb.
        titleText.Text = manual.Title; titleText.Foreground = pal.Brush(pal.Text);
        subtitleText.Text = manual.Subtitle; subtitleText.Foreground = pal.Brush(pal.Soft);

        var selected = (Contents.SelectedItem as ListBoxItem)?.Tag as string;
        Contents.Items.Clear();
        var group = "";
        foreach (var topic in manual.Topics)
        {
            if (topic.Group != group)
            {
                group = topic.Group;
                Contents.Items.Add(new ListBoxItem
                {
                    Content = new TextBlock { Text = group.ToUpperInvariant(), FontSize = 11.5, FontWeight = FontWeights.SemiBold, Foreground = pal.Brush(pal.Soft) },
                    IsHitTestVisible = false, Focusable = false, Margin = new Thickness(0, Contents.Items.Count == 0 ? 4 : 14, 0, 2),
                });
            }
            var item = new ListBoxItem { Content = new TextBlock { Text = topic.Title, TextWrapping = TextWrapping.Wrap, Foreground = pal.Brush(pal.Text), FontSize = 13.5 }, Tag = topic.Id, Padding = new Thickness(8, 4, 8, 4), Cursor = Cursors.Hand };
            item.Resources.Add(SystemColors.HighlightBrushKey, pal.Brush(pal.AccentSoft));
            item.Resources.Add(SystemColors.InactiveSelectionHighlightBrushKey, pal.Brush(pal.AccentSoft));
            item.Resources.Add(SystemColors.HighlightTextBrushKey, pal.Brush(pal.Text));
            Contents.Items.Add(item);
            if (topic.Id == selected) item.IsSelected = true;
        }
        manual.LinkClicked += id => { var target = Contents.Items.OfType<ListBoxItem>().FirstOrDefault(i => i.Tag as string == id); if (target != null && !target.IsSelected) target.IsSelected = true; else ShowTopic(id); };
        Viewer.Document = manual.Document;
        return manual;
    }

    // The scroll area inside the document viewer.
    internal ScrollViewer? Scroller()
    {
        DependencyObject? Find(DependencyObject at)
        {
            if (at is ScrollViewer) return at;
            for (var i = 0; i < VisualTreeHelper.GetChildrenCount(at); i++) if (Find(VisualTreeHelper.GetChild(at, i)) is { } found) return found;
            return null;
        }
        return Find(Viewer) as ScrollViewer;
    }

    // Puts a section's heading at the top of the page.
    internal void ShowTopic(string id)
    {
        if (!Manual.Targets.TryGetValue(id, out var block)) return;
        // From the end, bringing the heading into view scrolls up just far enough to put it at the top.
        UpdateLayout();
        Scroller()?.ScrollToEnd(); UpdateLayout();
        block.BringIntoView(); UpdateLayout();
    }

    public static HelpWindow Open(Window? owner, bool show = true)
    {
        if (Current is { } open)
        {
            if (show) { if (open.WindowState == WindowState.Minimized) open.WindowState = WindowState.Normal; open.Activate(); }
            return open;
        }
        var window = new HelpWindow();
        // On the same screen as the window it was opened from, but not tied to it (it can go behind the editor, and stays
        // open when the editor closes).
        if (owner is { IsVisible: true } && owner != window) { window.Owner = owner; window.WindowStartupLocation = WindowStartupLocation.CenterOwner; window.Loaded += (_, _) => window.Owner = null; }
        Current = window;
        if (show) window.Show();
        return window;
    }
}
