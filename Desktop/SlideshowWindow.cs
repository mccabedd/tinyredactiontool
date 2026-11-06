using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;

namespace TinyRedaction.Desktop;

// Slideshow (0.23.0, David, for his own use): a folder's pictures full screen, one after another. It only shows
// them: nothing is opened for editing, copied or written. Space pauses, Left/Right step, Home/End go to the first
// or last, Esc or a right-click ends it. The time per picture and starting again after the last are in Settings.
internal sealed class SlideshowWindow : Window
{
    private readonly IReadOnlyList<string> pictures;
    private readonly Func<string, CancellationToken, Task<BitmapSource?>> read;
    private readonly bool repeat;
    private readonly DispatcherTimer next = new(), noteTimer = new() { Interval = TimeSpan.FromSeconds(2.5) }, pointerTimer = new() { Interval = TimeSpan.FromSeconds(2) };
    private readonly Image picture = new() { Stretch = Stretch.Uniform, StretchDirection = StretchDirection.DownOnly };
    private readonly TextBlock note = new() { Foreground = Brushes.White, FontSize = 15, Margin = new(14, 8, 14, 8) };
    private readonly Border noteBox;
    private readonly CancellationTokenSource closing = new();
    private (int Index, Task<BitmapSource?> Picture)? ahead;
    private int version;
    internal int Index { get; private set; }
    internal bool Paused { get; private set; }
    internal string Note => note.Text;
    internal bool Manual { get; }
    // The previous and next keys chosen in Settings (0.24.0, David), besides the arrows and Page Up/Down.
    internal string PreviousKey { get; init; } = AppSettings.DefaultPreviousKey;
    internal string NextKey { get; init; } = AppSettings.DefaultNextKey;
    private bool Running => !Paused && !Manual;
    internal BitmapSource? Shown => picture.Source as BitmapSource;

    public SlideshowWindow(IReadOnlyList<string> pictures, int start, TimeSpan interval, bool repeat, Func<string, CancellationToken, Task<BitmapSource?>> read)
    {
        this.pictures = pictures; this.read = read; this.repeat = repeat; Index = Math.Clamp(start, 0, pictures.Count - 1);
        Title = "TinyRedactionTool Slideshow"; WindowStyle = WindowStyle.None; ResizeMode = ResizeMode.NoResize; WindowState = WindowState.Maximized; Topmost = true;
        Background = Brushes.Black; ShowInTaskbar = true;
        RenderOptions.SetBitmapScalingMode(picture, BitmapScalingMode.HighQuality);
        noteBox = new Border { Child = note, Background = new SolidColorBrush(Color.FromArgb(180, 20, 20, 20)), CornerRadius = new(4), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Bottom, Margin = new(0, 0, 0, 28), IsHitTestVisible = false };
        // 0.25.0 (David): the navigation bar in row 1 while pinned; unpinned it lies over the picture and slides away.
        layout.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        layout.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        layout.Children.Add(picture); layout.Children.Add(noteBox);
        Content = layout;
        // 0 seconds (0.24.0, David): no timer; each picture stays until a key moves on.
        Manual = interval <= TimeSpan.Zero;
        next.Interval = Manual ? TimeSpan.FromHours(1) : interval < TimeSpan.FromSeconds(1) ? TimeSpan.FromSeconds(1) : interval;
        next.Tick += async (_, _) => await Move(1, automatic: true);
        noteTimer.Tick += (_, _) => { noteTimer.Stop(); if (!Paused) noteBox.Visibility = Visibility.Collapsed; };
        pointerTimer.Tick += (_, _) => { pointerTimer.Stop(); if (Nav?.IsMouseOver != true) Cursor = Cursors.None; };
        hideTimer.Tick += (_, _) => { hideTimer.Stop(); if (Nav?.IsMouseOver != true) SlideNav(show: false); };
        Loaded += async (_, _) => await Begin();
        Closed += (_, _) => { closing.Cancel(); next.Stop(); noteTimer.Stop(); pointerTimer.Stop(); hideTimer.Stop(); };
        MouseMove += (_, _) => { Cursor = null; pointerTimer.Stop(); pointerTimer.Start(); };
        MouseRightButtonUp += (_, _) => Close();
        MouseLeftButtonUp += async (_, _) => await Move(1);
        MouseWheel += async (_, e) => await Move(e.Delta > 0 ? -1 : 1);
        KeyDown += async (_, e) => { e.Handled = true; await Key(e.Key == System.Windows.Input.Key.System ? e.SystemKey : e.Key, Keyboard.Modifiers); };
    }

    // The first picture, then the timer (when the window opens; checks call it without showing the window).
    internal async Task Begin()
    {
        if (NavShownAtStart) OpenNav(NavPinnedAtStart);
        await ShowAt(Index, "Space pauses · ← → step · Esc ends");
        if (Running) next.Start();
        pointerTimer.Start();
        if (Nav != null && !NavPinned) hideTimer.Start(); // Unpinned from the start: seen for a moment, then away.
    }

    // ---- The navigation bar (0.25.0, David) ----
    private readonly Grid layout = new();
    private readonly DispatcherTimer hideTimer = new() { Interval = TimeSpan.FromMilliseconds(700) };
    private Border? redTab;
    internal bool NavShownAtStart { get; init; }
    internal bool NavPinnedAtStart { get; init; } = true;
    internal double NavPictureSize { get; init; } = AppSettings.NavBarSizes[1];
    internal Action<double>? NavSizeChosen { get; init; }
    internal NavigationBar? Nav { get; private set; }
    internal bool NavPinned { get; private set; }
    internal bool NavHidden { get; private set; } // Unpinned and slid out of sight (the red tab shows).
    internal Border? RedTab => redTab;
    internal void OpenNav(bool pinned)
    {
        if (Nav == null)
        {
            Nav = new NavigationBar { ThumbnailSize = NavPictureSize };
            Nav.PreviousClicked += async () => await Move(-1);
            Nav.NextClicked += async () => await Move(1);
            Nav.PlayClicked += () => { if (Manual) ShowNote("0 seconds per picture: the keys move on (Settings › Slideshow)"); else TogglePause(); };
            Nav.PinClicked += () => SetNavPinned(!NavPinned);
            Nav.CloseClicked += CloseNav;
            Nav.SizeDragged += size => NavSizeChosen?.Invoke(size); // 0.26.0: kept for next time, as in the editor.
            Nav.PictureChosen += async path => { var at = pictures.ToList().FindIndex(p => string.Equals(p, path, StringComparison.OrdinalIgnoreCase)); if (at >= 0) await Jump(at); };
            Nav.MouseEnter += (_, _) => { hideTimer.Stop(); Cursor = null; };
            Nav.MouseLeave += (_, _) => { if (!NavPinned) { hideTimer.Stop(); hideTimer.Start(); } };
            Nav.RenderTransform = new TranslateTransform();
            Nav.Show(pictures, pictures[Index]);
            layout.Children.Add(Nav);
            // The red tab an unpinned bar leaves at the bottom edge, like the capture bar's at the top.
            redTab = new Border { Width = 160, Height = 14, Background = Brushes.Transparent, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Bottom, Visibility = Visibility.Collapsed, ToolTip = "Navigation Bar", Cursor = Cursors.Hand,
                Child = new Border { Height = 5, VerticalAlignment = VerticalAlignment.Bottom, Background = new SolidColorBrush(Color.FromRgb(0xD6, 0x30, 0x30)), CornerRadius = new(2, 2, 0, 0) } };
            Panel.SetZIndex(redTab, 6);
            redTab.MouseEnter += (_, _) => SlideNav(show: true);
            redTab.MouseLeftButtonUp += (_, e) => { e.Handled = true; SlideNav(show: true); };
            layout.Children.Add(redTab);
        }
        Nav.Visibility = Visibility.Visible;
        Nav.Playing = Running;
        SetNavPinned(pinned);
    }
    internal void SetNavPinned(bool pinned)
    {
        if (Nav == null) return;
        NavPinned = pinned; Nav.Pinned = pinned;
        hideTimer.Stop();
        // Pinned: its own row under the picture. Unpinned: over the bottom of the picture, ready to slide away.
        Grid.SetRow(Nav, pinned ? 1 : 0);
        Nav.VerticalAlignment = VerticalAlignment.Bottom; Panel.SetZIndex(Nav, 5);
        SlideNav(show: true, animate: false);
        if (!pinned && Nav.IsMouseOver != true) hideTimer.Start();
    }
    internal void SlideNav(bool show, bool animate = true)
    {
        if (Nav == null || Nav.Visibility != Visibility.Visible) return;
        if (!show && NavPinned) return;
        NavHidden = !show;
        var move = (TranslateTransform)Nav.RenderTransform;
        var to = show ? 0 : Math.Max(Nav.ActualHeight, 200) + 4;
        if (animate && IsVisible) move.BeginAnimation(TranslateTransform.YProperty, new System.Windows.Media.Animation.DoubleAnimation(to, TimeSpan.FromMilliseconds(140)));
        else { move.BeginAnimation(TranslateTransform.YProperty, null); move.Y = to; }
        Nav.IsHitTestVisible = show;
        if (redTab != null) redTab.Visibility = show ? Visibility.Collapsed : Visibility.Visible;
    }
    // Close: the bar goes completely (Tab brings it back).
    internal void CloseNav()
    {
        if (Nav == null) return;
        hideTimer.Stop(); NavHidden = false;
        Nav.Visibility = Visibility.Collapsed;
        if (redTab != null) redTab.Visibility = Visibility.Collapsed;
    }
    internal bool NavOpen => Nav is { Visibility: Visibility.Visible };

    internal async Task Key(Key key, ModifierKeys modifiers = ModifierKeys.None)
    {
        if (AppSettings.Matches(NextKey, modifiers, key)) { await Move(1); return; }
        if (AppSettings.Matches(PreviousKey, modifiers, key)) { await Move(-1); return; }
        switch (key)
        {
            case System.Windows.Input.Key.Tab: if (NavOpen) CloseNav(); else OpenNav(NavPinned || Nav == null && NavPinnedAtStart); break;
            case System.Windows.Input.Key.Escape: Close(); break;
            case System.Windows.Input.Key.Space: TogglePause(); break;
            case System.Windows.Input.Key.Right or System.Windows.Input.Key.PageDown or System.Windows.Input.Key.Down: await Move(1); break;
            case System.Windows.Input.Key.Left or System.Windows.Input.Key.PageUp or System.Windows.Input.Key.Up: await Move(-1); break;
            case System.Windows.Input.Key.Home: await Jump(0); break;
            case System.Windows.Input.Key.End: await Jump(pictures.Count - 1); break;
        }
    }
    internal void TogglePause()
    {
        Paused = !Paused;
        next.Stop(); if (Running) next.Start();
        if (Nav != null) Nav.Playing = Running;
        ShowNote(Paused ? "Paused · Space goes on" : "Playing");
    }
    private async Task Move(int step, bool automatic = false)
    {
        var target = Index + step;
        if (target >= pictures.Count) { if (!repeat) { if (automatic) { next.Stop(); Paused = true; if (Nav != null) Nav.Playing = false; ShowNote("The end · Esc ends"); } else ShowNote("The last picture"); return; } target = 0; }
        if (target < 0) target = repeat ? pictures.Count - 1 : 0;
        await Jump(target, Math.Sign(step));
    }
    private async Task Jump(int target, int direction = 1)
    {
        await ShowAt(target, null, direction);
        next.Stop(); if (Running) next.Start(); // Each picture gets its full time, also after a step by hand.
    }
    // Shows a picture (read ahead while the one before was on screen); one that can't be read is skipped.
    private async Task ShowAt(int index, string? extra, int direction = 1)
    {
        var mine = ++version;
        for (var tries = 0; tries < pictures.Count; tries++)
        {
            var reading = ahead is { } a && a.Index == index ? a.Picture : Read(index);
            var shown = await reading;
            if (mine != version || closing.IsCancellationRequested) return;
            if (shown != null)
            {
                Index = index; picture.Source = shown;
                Nav?.Select(pictures[index]);
                ShowNote($"{index + 1} / {pictures.Count} · {Path.GetFileName(pictures[index])}" + (extra != null ? "  ·  " + extra : ""));
                var following = (index + 1) % pictures.Count;
                ahead = (following, Read(following));
                return;
            }
            index = (index + (direction < 0 ? -1 : 1) + pictures.Count) % pictures.Count; // Not a picture TRT can read: on, the same way.
        }
        ShowNote("None of these pictures could be read · Esc ends");
    }
    private Task<BitmapSource?> Read(int index)
    {
        var path = pictures[index];
        return Task.Run(async () =>
        {
            // Windows reads most pictures itself, quickest; the others go to TRT's FFmpeg.
            try
            {
                var frame = BitmapDecoder.Create(new Uri(path), BitmapCreateOptions.IgnoreImageCache, BitmapCacheOption.OnLoad).Frames[0];
                BitmapSource shown = frame;
                // Phone photos say how they were held (EXIF orientation); show them upright, as File Explorer does.
                if (Upright(frame) is { } turn) shown = new TransformedBitmap(frame, turn);
                shown.Freeze(); return (BitmapSource?)shown;
            }
            catch (Exception ex) when (ex is NotSupportedException or IOException or FileFormatException or UnauthorizedAccessException or ArgumentException) { }
            return await read(path, closing.Token);
        });
    }
    internal static Transform? Upright(BitmapFrame frame)
    {
        object? value = null;
        try { if (frame.Metadata is BitmapMetadata metadata && metadata.ContainsQuery("/app1/ifd/{ushort=274}")) value = metadata.GetQuery("/app1/ifd/{ushort=274}"); }
        catch (Exception ex) when (ex is NotSupportedException or InvalidOperationException or ArgumentException) { }
        return Convert.ToInt32(value ?? 1) switch
        {
            2 => new ScaleTransform(-1, 1), 3 => new RotateTransform(180), 4 => new ScaleTransform(1, -1),
            5 => new TransformGroup { Children = { new RotateTransform(90), new ScaleTransform(-1, 1) } }, 6 => new RotateTransform(90),
            7 => new TransformGroup { Children = { new RotateTransform(270), new ScaleTransform(-1, 1) } }, 8 => new RotateTransform(270),
            _ => null,
        };
    }
    private void ShowNote(string text)
    {
        note.Text = text; noteBox.Visibility = Visibility.Visible;
        noteTimer.Stop(); noteTimer.Start();
    }
}
