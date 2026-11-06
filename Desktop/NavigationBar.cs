using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using Path = System.Windows.Shapes.Path;

namespace TinyRedaction.Desktop;

// The navigation bar (0.25.0, David): the folder's pictures as small pictures along the bottom,
// under a tab with Close, Previous, Play/Pause, Next and Pin. The editor and the slideshow each have one and decide
// what the buttons do. Small pictures are read only for the part of the row in view (and a little either side), so a
// folder of thousands of photos stays quick and small.
internal sealed class NavigationBar : Grid
{
    internal sealed class Item(string path) : INotifyPropertyChanged
    {
        public string Path { get; } = path;
        public string Name { get; } = System.IO.Path.GetFileName(path);
        public string Kind { get; } = System.IO.Path.GetExtension(path).TrimStart('.').ToUpperInvariant();
        private BitmapSource? picture;
        public BitmapSource? Picture { get => picture; set { picture = value; PropertyChanged?.Invoke(this, new(nameof(Picture))); } }
        public event PropertyChangedEventHandler? PropertyChanged;
    }

    public event Action? CloseClicked, PreviousClicked, NextClicked, PlayClicked, PinClicked;
    public event Action<string>? PictureChosen;
    internal Border Tab { get; }
    internal Border Shelf { get; }
    internal ListBox Strip { get; }
    internal Button CloseButton { get; }
    internal Button PreviousButton { get; }
    internal Button PlayButton { get; }
    internal Button NextButton { get; }
    internal Button PinButton { get; }
    internal ObservableCollection<Item> Items { get; } = [];
    private readonly Path pinIcon, playIcon;
    private readonly TextBlock emptyNote = new() { Text = "Open a picture from a folder to see the folder's pictures here.", FontSize = 11, Margin = new(12, 10, 12, 10), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
    private string[] paths = [];
    private CancellationTokenSource? reading;
    private readonly object wantLock = new();
    private (int From, int To, int Centre) wanted = (0, -1, 0);
    private readonly SemaphoreSlim wake = new(0);
    private readonly HashSet<int> started = [];

    public NavigationBar()
    {
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        // The tab on top, as in David's drawing: Close on the left, the three in the middle, Pin on the right.
        (CloseButton, _) = TabButton("IconNavClose", "Close the Navigation Bar", false);
        (PreviousButton, _) = TabButton("IconPrevious", "Previous Picture", false);
        (PlayButton, playIcon) = TabButton("IconPlay", "Play or Pause the Slideshow", true);
        (NextButton, _) = TabButton("IconNext", "Next Picture", false);
        (PinButton, pinIcon) = TabButton("IconPin", "Pin the Navigation Bar", false);
        CloseButton.Click += (_, _) => CloseClicked?.Invoke();
        PreviousButton.Click += (_, _) => PreviousClicked?.Invoke();
        PlayButton.Click += (_, _) => PlayClicked?.Invoke();
        NextButton.Click += (_, _) => NextClicked?.Invoke();
        PinButton.Click += (_, _) => PinClicked?.Invoke();
        var row = new Grid { MinWidth = 260 };
        foreach (var width in new[] { GridLength.Auto, new GridLength(1, GridUnitType.Star), GridLength.Auto, GridLength.Auto, GridLength.Auto, new GridLength(1, GridUnitType.Star), GridLength.Auto })
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = width });
        void Put(UIElement element, int column) { SetColumn(element, column); row.Children.Add(element); }
        Put(CloseButton, 0); Put(PreviousButton, 2); Put(PlayButton, 3); Put(NextButton, 4); Put(PinButton, 6);
        Tab = new Border { Child = row, HorizontalAlignment = HorizontalAlignment.Center, BorderThickness = new(1, 1, 1, 0), CornerRadius = new(4, 4, 0, 0), Padding = new(4, 1, 4, 1) };
        Tab.SetResourceReference(Border.BackgroundProperty, "Surface"); Tab.SetResourceReference(Border.BorderBrushProperty, "ChromeLine");
        Children.Add(Tab);

        Strip = new ListBox
        {
            ItemsSource = Items, BorderThickness = new(0), Background = Brushes.Transparent, Focusable = false,
            HorizontalContentAlignment = HorizontalAlignment.Center, SelectionMode = SelectionMode.Single,
        };
        Strip.SetResourceReference(Control.ForegroundProperty, "Foreground");
        ScrollViewer.SetHorizontalScrollBarVisibility(Strip, ScrollBarVisibility.Auto);
        ScrollViewer.SetVerticalScrollBarVisibility(Strip, ScrollBarVisibility.Disabled);
        ScrollViewer.SetCanContentScroll(Strip, true); // Offsets then count pictures, which is what WantView needs.
        VirtualizingPanel.SetIsVirtualizing(Strip, true);
        VirtualizingPanel.SetVirtualizationMode(Strip, VirtualizationMode.Recycling);
        var panel = new FrameworkElementFactory(typeof(VirtualizingStackPanel));
        panel.SetValue(VirtualizingStackPanel.OrientationProperty, Orientation.Horizontal);
        Strip.ItemsPanel = new ItemsPanelTemplate(panel);
        // Each picture in a box: the open one filled with the selection colour, a frame under the pointer.
        var chrome = new FrameworkElementFactory(typeof(Border), "Chrome");
        chrome.SetValue(Border.BorderThicknessProperty, new Thickness(1)); chrome.SetValue(Border.CornerRadiusProperty, new CornerRadius(3));
        chrome.SetValue(Border.BackgroundProperty, Brushes.Transparent); chrome.SetValue(Border.BorderBrushProperty, Brushes.Transparent);
        chrome.SetValue(Border.PaddingProperty, new TemplateBindingExtension(Control.PaddingProperty));
        chrome.AppendChild(new FrameworkElementFactory(typeof(ContentPresenter)));
        var template = new ControlTemplate(typeof(ListBoxItem)) { VisualTree = chrome };
        var hover = new Trigger { Property = IsMouseOverProperty, Value = true };
        hover.Setters.Add(new Setter(Border.BorderBrushProperty, new DynamicResourceExtension("ToolHoverBorder"), "Chrome"));
        var selected = new Trigger { Property = ListBoxItem.IsSelectedProperty, Value = true };
        selected.Setters.Add(new Setter(Border.BackgroundProperty, new DynamicResourceExtension("ToolSelected"), "Chrome"));
        selected.Setters.Add(new Setter(Border.BorderBrushProperty, new DynamicResourceExtension("ToolHoverBorder"), "Chrome"));
        template.Triggers.Add(hover); template.Triggers.Add(selected);
        var item = new Style(typeof(ListBoxItem));
        item.Setters.Add(new Setter(Control.TemplateProperty, template));
        item.Setters.Add(new Setter(Control.PaddingProperty, new Thickness(4)));
        item.Setters.Add(new Setter(MarginProperty, new Thickness(2, 4, 2, 2)));
        item.Setters.Add(new Setter(FocusableProperty, false));
        item.Setters.Add(new Setter(CursorProperty, Cursors.Hand));
        item.Setters.Add(new Setter(ToolTipProperty, new Binding(nameof(Item.Name))));
        // A click opens the picture; the selection only ever shows the picture that is open.
        item.Setters.Add(new EventSetter(PreviewMouseLeftButtonDownEvent, new MouseButtonEventHandler((sender, e) =>
        {
            e.Handled = true;
            if (sender is ListBoxItem { DataContext: Item chosen }) PictureChosen?.Invoke(chosen.Path);
        })));
        Strip.ItemContainerStyle = item;
        Strip.PreviewMouseWheel += (_, e) =>
        {
            if (FindScroller() is not { } scroller) return;
            scroller.ScrollToHorizontalOffset(scroller.HorizontalOffset - Math.Sign(e.Delta) * 3);
            e.Handled = true;
        };
        Strip.AddHandler(ScrollViewer.ScrollChangedEvent, new ScrollChangedEventHandler((_, _) => WantView()));
        ThumbnailSize = AppSettings.NavBarSizes[1];
        // The top edge of the pictures' row: drag it up or down to make the bar (and its pictures) taller or shorter.
        SizeEdge = new Thumb { Height = 6, VerticalAlignment = VerticalAlignment.Top, Cursor = Cursors.SizeNS, Margin = new(0, -3, 0, 0), ToolTip = "Drag to Resize" };
        var edge = new FrameworkElementFactory(typeof(Border)); edge.SetValue(Border.BackgroundProperty, Brushes.Transparent);
        SizeEdge.Template = new ControlTemplate(typeof(Thumb)) { VisualTree = edge };
        SizeEdge.DragStarted += (_, _) => dragging = true;
        SizeEdge.DragDelta += (_, e) => ThumbnailSize = thumbnailSize - e.VerticalChange;
        SizeEdge.DragCompleted += (_, _) => { dragging = false; ReadAgainIfLarger(); SizeDragged?.Invoke(thumbnailSize); };
        var shelf = new Grid { Children = { Strip, emptyNote, SizeEdge } };
        Shelf = new Border { Child = shelf, BorderThickness = new(0, 1, 0, 0) };
        Shelf.SetResourceReference(Border.BackgroundProperty, "Surface"); Shelf.SetResourceReference(Border.BorderBrushProperty, "ChromeLine");
        SetRow(Shelf, 1); Children.Add(Shelf);
        Pinned = true;
        Unloaded += (_, _) => reading?.Cancel();
        // Clicks, right-clicks and the wheel on the bar stay on the bar (in the slideshow they would step or end it).
        MouseLeftButtonUp += (_, e) => e.Handled = true;
        MouseRightButtonUp += (_, e) => e.Handled = true;
        MouseWheel += (_, e) => e.Handled = true;
    }
    private (Button, Path) TabButton(string icon, string tip, bool filled)
    {
        var path = new Path { Data = (Geometry)Application.Current.FindResource(icon), Width = 20, Height = 20, Stretch = Stretch.None, StrokeThickness = 1.5, StrokeLineJoin = PenLineJoin.Round, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round };
        path.SetResourceReference(filled ? Shape.FillProperty : Shape.StrokeProperty, "Foreground");
        // Not focusable: Space and the arrows stay with the slideshow or the editor after a click.
        var button = new Button { Content = path, ToolTip = tip, Padding = new(6, 2, 6, 2), Margin = new(2, 1, 2, 1), Focusable = false };
        button.SetResourceReference(StyleProperty, "EditorFlatButton");
        ToolTipService.SetShowOnDisabled(button, true);
        AutomationPropertiesName(button, tip);
        return (button, path);
    }
    private static void AutomationPropertiesName(DependencyObject element, string name) => System.Windows.Automation.AutomationProperties.SetName(element, name);

    // The height of the small pictures (Settings › Slideshow › Picture size, or dragged, 0.26.0). The template is bound
    // to these two, so dragging resizes the pictures as it goes; they are read again larger only when the drag ends.
    public static readonly DependencyProperty PictureHeightProperty = DependencyProperty.Register(nameof(PictureHeight), typeof(double), typeof(NavigationBar), new(72.0));
    public static readonly DependencyProperty PictureWidthProperty = DependencyProperty.Register(nameof(PictureWidth), typeof(double), typeof(NavigationBar), new(101.0));
    public double PictureHeight => (double)GetValue(PictureHeightProperty);
    public double PictureWidth => (double)GetValue(PictureWidthProperty);
    public const double MinPictureSize = AppSettings.MinNavBarSize, MaxPictureSize = AppSettings.MaxNavBarSize;
    // Dragging the bar's top edge (0.26.0, David's video): up for larger pictures, down for smaller; the size when let go.
    public event Action<double>? SizeDragged;
    internal Thumb SizeEdge { get; private set; } = null!;
    private double thumbnailSize, readSize;
    internal double ThumbnailSize
    {
        get => thumbnailSize;
        set
        {
            value = Math.Clamp(Math.Round(value), MinPictureSize, MaxPictureSize);
            if (value == thumbnailSize) return;
            thumbnailSize = value;
            SetValue(PictureHeightProperty, value); SetValue(PictureWidthProperty, Math.Round(value * 1.4));
            if (Strip.ItemTemplate == null) Strip.ItemTemplate = PictureTemplate();
            if (!dragging) ReadAgainIfLarger();
        }
    }
    private bool dragging;
    // Pictures read smaller than now shown are read again at the new size (smaller ones simply scale down).
    private void ReadAgainIfLarger()
    {
        if (thumbnailSize <= readSize) return;
        readSize = thumbnailSize;
        lock (wantLock) started.Clear();
        foreach (var each in Items) each.Picture = null;
        WantView();
    }
    private DataTemplate PictureTemplate()
    {
        {
            var stack = new FrameworkElementFactory(typeof(StackPanel)); stack.SetBinding(WidthProperty, new Binding(nameof(PictureWidth)) { Source = this });
            var frame = new FrameworkElementFactory(typeof(Grid)); frame.SetBinding(HeightProperty, new Binding(nameof(PictureHeight)) { Source = this });
            var kind = new FrameworkElementFactory(typeof(TextBlock)); kind.SetBinding(TextBlock.TextProperty, new Binding(nameof(Item.Kind)));
            kind.SetValue(HorizontalAlignmentProperty, HorizontalAlignment.Center); kind.SetValue(VerticalAlignmentProperty, VerticalAlignment.Center); kind.SetValue(OpacityProperty, 0.5); kind.SetValue(TextBlock.FontSizeProperty, 11.0);
            var image = new FrameworkElementFactory(typeof(Image)); image.SetBinding(Image.SourceProperty, new Binding(nameof(Item.Picture)));
            image.SetValue(Image.StretchProperty, Stretch.Uniform); image.SetValue(RenderOptions.BitmapScalingModeProperty, BitmapScalingMode.HighQuality);
            frame.AppendChild(kind); frame.AppendChild(image);
            var name = new FrameworkElementFactory(typeof(TextBlock)); name.SetBinding(TextBlock.TextProperty, new Binding(nameof(Item.Name)));
            name.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis); name.SetValue(TextBlock.TextAlignmentProperty, TextAlignment.Center);
            name.SetValue(TextBlock.FontSizeProperty, 11.0); name.SetValue(MarginProperty, new Thickness(0, 3, 0, 0));
            stack.AppendChild(frame); stack.AppendChild(name);
            return new DataTemplate { VisualTree = stack };
        }
    }
    // Pinned shows a pin standing up; unpinned (only the slideshow allows it) a pin lying over.
    private bool pinned;
    internal bool Pinned
    {
        get => pinned;
        set
        {
            pinned = value;
            pinIcon.RenderTransform = value ? Transform.Identity : new RotateTransform(45, 10, 10);
            pinIcon.SetResourceReference(Shape.FillProperty, value ? "Foreground" : "Surface");
            UpdatePinTip();
        }
    }
    private bool canUnpin = true;
    internal bool CanUnpin { get => canUnpin; set { canUnpin = value; PinButton.IsEnabled = value; UpdatePinTip(); } }
    private void UpdatePinTip() => PinButton.ToolTip = !canUnpin ? "Always Pinned in the Editor" : pinned ? "Unpin: Slide Out of Sight" : "Pin the Navigation Bar";
    internal bool Playing
    {
        set { playIcon.Data = (Geometry)Application.Current.FindResource(value ? "IconPause" : "IconPlay"); PlayButton.ToolTip = value ? "Pause the Slideshow" : "Play the Slideshow"; }
    }

    // The folder's pictures, with the open one chosen (kept as they are when the folder is the same).
    internal void Show(IReadOnlyList<string> pictures, string? current)
    {
        if (!pictures.SequenceEqual(paths, StringComparer.OrdinalIgnoreCase))
        {
            reading?.Cancel(); reading = new CancellationTokenSource();
            paths = [.. pictures];
            Items.Clear(); foreach (var path in paths) Items.Add(new Item(path));
            lock (wantLock) started.Clear();
            var token = reading.Token; var mine = paths;
            _ = Task.Run(() => ReadPictures(mine, token), token);
        }
        emptyNote.Visibility = paths.Length == 0 ? Visibility.Visible : Visibility.Collapsed;
        Select(current);
    }
    internal int SelectedIndex => Strip.SelectedIndex;
    internal void Select(string? current)
    {
        var index = current == null ? -1 : Array.FindIndex(paths, p => string.Equals(p, current, StringComparison.OrdinalIgnoreCase));
        Strip.SelectedIndex = index;
        if (index >= 0) Strip.ScrollIntoView(Items[index]);
        WantView(index);
    }
    private ScrollViewer? FindScroller()
    {
        if (VisualTreeHelper.GetChildrenCount(Strip) == 0) return null;
        return VisualTreeHelper.GetChild(Strip, 0) is Border { Child: ScrollViewer scroller } ? scroller : null;
    }
    // The pictures in view, and a few either side (offsets count pictures); pictures far away are let go again.
    private void WantView(int around = -1)
    {
        if (paths.Length == 0) return;
        int from, to;
        if (FindScroller() is { ViewportWidth: > 0 } scroller) { from = (int)scroller.HorizontalOffset; to = from + (int)Math.Ceiling(scroller.ViewportWidth); }
        else { var centre = Math.Max(0, around); from = centre - 10; to = centre + 10; }
        from = Math.Max(0, from - 8); to = Math.Min(paths.Length - 1, to + 8);
        lock (wantLock)
        {
            wanted = (from, to, around >= from && around <= to ? around : (from + to) / 2);
            for (var i = 0; i < Items.Count; i++)
                if ((i < from - 150 || i > to + 150) && Items[i].Picture != null) { Items[i].Picture = null; started.Remove(i); }
        }
        if (wake.CurrentCount == 0) wake.Release();
    }
    private async Task ReadPictures(string[] mine, CancellationToken token)
    {
        try
        {
            while (!token.IsCancellationRequested)
            {
                await wake.WaitAsync(token);
                while (!token.IsCancellationRequested)
                {
                    int next = -1; double size;
                    lock (wantLock)
                    {
                        size = thumbnailSize;
                        var (from, to, centre) = wanted;
                        for (var step = 0; step <= to - from && next < 0; step++)
                            foreach (var i in new[] { centre + step, centre - step })
                                if (i >= from && i <= to && i < mine.Length && started.Add(i)) { next = i; break; }
                    }
                    if (next < 0) break;
                    var picture = ReadSmall(mine[next], (int)Math.Round(size * 2));
                    if (picture == null || token.IsCancellationRequested) continue;
                    var index = next;
                    _ = Dispatcher.BeginInvoke(() => { if (!token.IsCancellationRequested && index < Items.Count && ReferenceEquals(mine, paths)) Items[index].Picture = picture; });
                }
            }
        }
        catch (OperationCanceledException) { }
    }
    // A small copy of a picture, upright (EXIF orientation); null if Windows can't read it (its type shows instead).
    internal static BitmapSource? ReadSmall(string path, int height)
    {
        try
        {
            Transform? turn = null;
            using (var stream = File.OpenRead(path))
            {
                var frame = BitmapDecoder.Create(stream, BitmapCreateOptions.DelayCreation | BitmapCreateOptions.IgnoreColorProfile, BitmapCacheOption.None).Frames[0];
                turn = SlideshowWindow.Upright(frame);
            }
            var small = new BitmapImage();
            small.BeginInit();
            small.UriSource = new Uri(path); small.CacheOption = BitmapCacheOption.OnLoad; small.CreateOptions = BitmapCreateOptions.IgnoreImageCache | BitmapCreateOptions.IgnoreColorProfile;
            small.DecodePixelHeight = Math.Max(16, height);
            small.EndInit();
            BitmapSource shown = turn == null ? small : new TransformedBitmap(small, turn);
            shown.Freeze();
            return shown;
        }
        catch (Exception ex) when (ex is NotSupportedException or IOException or FileFormatException or UnauthorizedAccessException or ArgumentException or InvalidOperationException or System.Runtime.InteropServices.COMException) { return null; }
    }
}
