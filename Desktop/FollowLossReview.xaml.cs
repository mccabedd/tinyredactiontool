using System.Windows;
using System.Windows.Media.Imaging;
using System.Windows.Media;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;
public partial class FollowLossReview : Window
{
    // Keep: the window was closed without a choice; nothing changes (0.15.0: no button for it any more).
    internal enum Choice { Keep, End, Correct, Continue }
    internal Choice Decision { get; private set; }
    public FollowLossReview(BitmapSource? matched, double? matchedTime, BitmapSource unmatched, double unmatchedTime,
        MediaRect? matchedBounds = null, MediaRect? unmatchedBounds = null, bool canContinue = true)
    {
        InitializeComponent();
        this.matched = matched; this.matchedBounds = matchedBounds; this.unmatched = unmatched; this.unmatchedBounds = unmatchedBounds;
        MatchedImage.Source = matched == null ? null : Outline(matched, matchedBounds); UnmatchedImage.Source = Outline(unmatched, unmatchedBounds);
        MatchedLabel.Text = matchedTime is { } time ? $"Last frame tracked · {time:0.000} s" : "The subject was not found after the first frame";
        UnmatchedLabel.Text = $"Where tracking stopped · {unmatchedTime:0.000} s";
        EndButton.IsEnabled = matchedTime != null;
        EndButton.ToolTip = matchedTime != null ? "End on the Last Tracked Frame (Left)" : "There Is No Tracked Frame to End On";
        ContinueButton.IsEnabled = canContinue;
        ContinueButton.ToolTip = canContinue ? "Keep the Box on the Right and Track on from There" :
            "This Is the Redaction's Last Frame: There Is Nothing Left to Track";
        Explanation.Text = "The blue outline is the box; click a picture to enlarge it. " +
            (matchedTime != null ? "End redaction here ends it on the left frame. " : "") +
            "Adjust the box lets you move or resize it on the right frame, then track again. Continue redaction keeps the box and carries on tracking.";
    }
    private readonly BitmapSource? matched, unmatched;
    private readonly MediaRect? matchedBounds, unmatchedBounds;
    // crop: show only this part of the frame (the close-up around the box).
    internal static ImageSource Outline(BitmapSource image, MediaRect? bounds, Rect? crop = null)
    {
        var drawing = new DrawingGroup();
        using (var dc = drawing.Open())
        {
            dc.DrawImage(image, new Rect(0, 0, image.PixelWidth, image.PixelHeight));
            var thickness = crop is { } c ? Math.Max(1, c.Width / 320d) : Math.Max(1, image.PixelWidth / 320d);
            if (bounds is { } b) dc.DrawRectangle(null, new Pen(Brushes.DeepSkyBlue, thickness), new Rect(b.X, b.Y, b.Width, b.Height));
        }
        if (crop is { } area) drawing.ClipGeometry = new RectangleGeometry(area);
        drawing.Freeze(); return new DrawingImage(drawing);
    }
    // The area around the box: three times its size, at least a quarter of the frame, inside the frame.
    internal static Rect CloseUp(BitmapSource image, MediaRect b)
    {
        var width = Math.Min(image.PixelWidth, Math.Max(b.Width * 3, image.PixelWidth / 4d));
        var height = Math.Min(image.PixelHeight, Math.Max(b.Height * 3, image.PixelHeight / 4d));
        // Keep the frame's shape so the close-up fills the viewer evenly.
        var aspect = (double)image.PixelWidth / image.PixelHeight;
        if (width / height < aspect) width = Math.Min(image.PixelWidth, height * aspect); else height = Math.Min(image.PixelHeight, width / aspect);
        var x = Math.Clamp(b.X + b.Width / 2 - width / 2, 0, image.PixelWidth - width);
        var y = Math.Clamp(b.Y + b.Height / 2 - height / 2, 0, image.PixelHeight - height);
        return new Rect(x, y, width, height);
    }
    private void EnlargeMatched(object sender, System.Windows.Input.MouseButtonEventArgs e) { if (matched != null) Enlarge(MatchedLabel.Text, matched, matchedBounds); }
    private void EnlargeUnmatched(object sender, System.Windows.Input.MouseButtonEventArgs e) { if (unmatched != null) Enlarge(UnmatchedLabel.Text, unmatched, unmatchedBounds); }
    private void Enlarge(string title, BitmapSource image, MediaRect? bounds) => CreateViewer(title, image, bounds).ShowDialog();
    // A large viewer: opens on the close-up around the box, with a button for the whole frame.
    internal Window CreateViewer(string title, BitmapSource image, MediaRect? bounds)
    {
        var picture = new System.Windows.Controls.Image { Stretch = Stretch.Uniform };
        var toggle = new System.Windows.Controls.Button { Padding = new Thickness(12, 4, 12, 4), Margin = new Thickness(0, 8, 8, 0) };
        var close = new System.Windows.Controls.Button { Content = "Close", Padding = new Thickness(12, 4, 12, 4), Margin = new Thickness(0, 8, 0, 0), IsCancel = true, IsDefault = true };
        var closeUp = bounds is { } b ? CloseUp(image, b) : (Rect?)null;
        var showingCloseUp = closeUp != null;
        void Show()
        {
            picture.Source = Outline(image, bounds, showingCloseUp ? closeUp : null);
            toggle.Content = showingCloseUp ? "Show Whole Frame" : "Close-Up of the Box";
        }
        toggle.Click += (_, _) => { showingCloseUp = !showingCloseUp; Show(); };
        toggle.Visibility = closeUp == null ? Visibility.Collapsed : Visibility.Visible;
        Show();
        var buttons = new System.Windows.Controls.StackPanel { Orientation = System.Windows.Controls.Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right };
        buttons.Children.Add(toggle); buttons.Children.Add(close);
        var layout = new System.Windows.Controls.DockPanel { Margin = new Thickness(12) };
        System.Windows.Controls.DockPanel.SetDock(buttons, System.Windows.Controls.Dock.Bottom);
        layout.Children.Add(buttons);
        layout.Children.Add(new System.Windows.Controls.Border { Background = new SolidColorBrush(Color.FromRgb(0x10, 0x12, 0x16)), Child = picture });
        var area = SystemParameters.WorkArea;
        return new Window
        {
            Title = title, Owner = this, Content = layout, WindowStartupLocation = WindowStartupLocation.CenterOwner, ShowInTaskbar = false,
            Width = area.Width * .85, Height = area.Height * .85, Background = Background, Foreground = Foreground
        };
    }
    private void EndRedaction(object sender, RoutedEventArgs e) { Decision = Choice.End; DialogResult = true; }
    private void CorrectBox(object sender, RoutedEventArgs e) { Decision = Choice.Correct; DialogResult = true; }
    private void ContinueRedaction(object sender, RoutedEventArgs e) { Decision = Choice.Continue; DialogResult = true; }
}
