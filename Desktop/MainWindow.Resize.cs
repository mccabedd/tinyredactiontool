using System.Globalization;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Resize (0.23.0, David): a new size for the picture. Redactions,
// annotations and the crop are scaled with it; like Rotate it makes a new working copy (the original is never
// changed) and Undo goes back. Pictures only.
public partial class MainWindow
{
    internal const int MaxResizeSide = 20000;
    private void ResizePicture(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Media is not { } media) { Status.Text = "Open a picture first."; return; }
        if (media.IsVideo) { Status.Text = "Resize works on pictures."; return; }
        var dialog = new ResizeWindow(media.Width, media.Height) { Owner = this };
        if (dialog.ShowDialog() == true) _ = ResizePictureAsync(dialog.NewWidth, dialog.NewHeight);
    }
    // Moves every redaction, annotation and the crop with the picture; line widths and text sizes scale too.
    internal static void ScaleProjectGeometry(RedactionProject project, int width, int height)
    {
        var m = project.Media!; double sx = width / (double)m.Width, sy = height / (double)m.Height, both = Math.Sqrt(sx * sy);
        MediaRect Scale(MediaRect r) => new MediaRect(r.X * sx, r.Y * sy, r.Width * sx, r.Height * sy).Clamp(width, height);
        MediaPoint Point(MediaPoint p) => new(Math.Clamp(p.X * sx, 0, width), Math.Clamp(p.Y * sy, 0, height));
        foreach (var r in project.Regions)
        {
            r.Keyframes = r.Keyframes.Select(k => k with { Bounds = Scale(k.Bounds) }).ToList();
            r.CoverageMargin *= both;
        }
        foreach (var a in project.Annotations)
        {
            a.Points = a.Points.Select(Point).ToList();
            a.Box = Scale(a.Box);
            a.Width = Math.Max(1, (int)Math.Round(a.Width * both));
            a.FontSize = Math.Max(4, a.FontSize * both);
        }
        if (project.Crop is { } crop) project.Crop = Scale(crop);
        project.Media = m with { Width = width, Height = height };
    }
    // The picture at its new size, smoothed (Fant) and keeping any transparency.
    internal static BitmapSource ScaleBitmap(BitmapSource source, int width, int height)
    {
        var visual = new DrawingVisual();
        RenderOptions.SetBitmapScalingMode(visual, BitmapScalingMode.HighQuality);
        using (var dc = visual.RenderOpen()) dc.DrawImage(source, new Rect(0, 0, width, height));
        var target = new RenderTargetBitmap(width, height, 96, 96, PixelFormats.Pbgra32);
        target.Render(visual);
        var result = new FormatConvertedBitmap(target, PixelFormats.Bgra32, null, 0); result.Freeze(); return result;
    }
    internal async Task<bool> ResizePictureAsync(int width, int height)
    {
        if (busy || closing || Project.Media is not { IsVideo: false } media) return false;
        if (captures == null) { Status.Text = "Resizing needs the capture part of TRT, which is not running."; return false; }
        if (width < 1 || height < 1 || width > MaxResizeSide || height > MaxResizeSide) { Status.Text = $"Choose a size from 1 to {MaxResizeSide} pixels."; return false; }
        if (width == media.Width && height == media.Height) { Status.Text = "That is the size it already is."; return false; }
        var done = false; string? made = null; var before = ProjectStore.Serialize(Project);
        await RunWork(async token =>
        {
            if (Preview.Image is not { } image) throw new InvalidOperationException("The picture is not loaded.");
            var project = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
            ScaleProjectGeometry(project, width, height);
            made = captures.Store.NewFile("CAPTURE", ".png");
            CaptureController.WritePng(ScaleBitmap(image, width, height), made);
            token.ThrowIfCancellationRequested();
            var hash = await ProjectStore.HashAsync(made, token);
            project.Media = media with { Path = made, Length = new FileInfo(made).Length, Sha256 = hash, Width = width, Height = height, Duration = 0 };
            await LoadMedia(made, project, token, keepHistory: true);
            done = true;
        }, "Resizing cancelled. Nothing was changed.", "Resizing the Picture");
        if (!done) { if (made != null && captures.Store.Owns(made) && Project.Media?.Path != made) ReleaseCapture(made); return false; }
        history.Checkpoint(before);
        savedSnapshot = null; // The resized working copy is new work.
        Status.Text = $"Picture resized to {width} × {height}. Redactions and annotations moved with it; the original file is unchanged.";
        return true;
    }
}

// The Resize window: width and height in pixels or as a percentage, keeping the proportions unless untick.
internal sealed class ResizeWindow : Window
{
    private readonly int width, height;
    private readonly TextBox widthBox = new() { Width = 80 }, heightBox = new() { Width = 80 };
    private readonly RadioButton pixels = new() { Content = "Pixels", IsChecked = true, Margin = new(0, 0, 16, 0) }, percent = new() { Content = "Percent" };
    private readonly CheckBox keep = new() { Content = "Keep Proportions", IsChecked = true, Margin = new(0, 10, 0, 0) };
    private readonly TextBlock result = new() { Margin = new(0, 10, 0, 0) };
    private readonly Button ok = new() { Content = "OK", IsDefault = true, MinWidth = 80, Margin = new(0, 0, 8, 0) };
    private bool updating;
    internal int NewWidth { get; private set; }
    internal int NewHeight { get; private set; }
    public ResizeWindow(int width, int height)
    {
        this.width = width; this.height = height; NewWidth = width; NewHeight = height;
        Title = "Resize"; SizeToContent = SizeToContent.WidthAndHeight; ResizeMode = ResizeMode.NoResize; WindowStartupLocation = WindowStartupLocation.CenterOwner; ShowInTaskbar = false;
        SetResourceReference(BackgroundProperty, "Background"); SetResourceReference(ForegroundProperty, "Foreground");
        foreach (var r in new[] { pixels, percent }) { r.GroupName = "ResizeUnit"; r.SetResourceReference(ForegroundProperty, "Foreground"); r.Checked += (_, _) => ShowValues(); }
        widthBox.TextChanged += (_, _) => Edited(widthBox); heightBox.TextChanged += (_, _) => Edited(heightBox);
        keep.Checked += (_, _) => Edited(widthBox);
        var cancel = new Button { Content = "Cancel", IsCancel = true, MinWidth = 80 };
        ok.Click += (_, _) => { DialogResult = true; };
        Grid Row(string label, TextBox box)
        {
            var row = new Grid { Margin = new(0, 4, 0, 0) };
            row.ColumnDefinitions.Add(new() { Width = new(70) }); row.ColumnDefinitions.Add(new() { Width = GridLength.Auto });
            var text = new TextBlock { Text = label, VerticalAlignment = VerticalAlignment.Center };
            Grid.SetColumn(box, 1); row.Children.Add(text); row.Children.Add(box); return row;
        }
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, Margin = new(0, 14, 0, 0), Children = { ok, cancel } };
        Content = new StackPanel
        {
            Margin = new(16), MinWidth = 280,
            Children =
            {
                new TextBlock { Text = $"Now {width} × {height} pixels", Margin = new(0, 0, 0, 8) },
                new StackPanel { Orientation = Orientation.Horizontal, Children = { pixels, percent } },
                Row("Width", widthBox), Row("Height", heightBox), keep, result, buttons,
            },
        };
        ShowValues();
        Loaded += (_, _) => { widthBox.Focus(); widthBox.SelectAll(); };
    }
    private bool Percent => percent.IsChecked == true;
    private void ShowValues()
    {
        updating = true;
        widthBox.Text = Percent ? F(NewWidth * 100.0 / width) : NewWidth.ToString(CultureInfo.CurrentCulture);
        heightBox.Text = Percent ? F(NewHeight * 100.0 / height) : NewHeight.ToString(CultureInfo.CurrentCulture);
        updating = false; ShowResult();
    }
    private static string F(double value) => Math.Round(value, 2).ToString("0.##", CultureInfo.CurrentCulture);
    // A value typed in one box sets the other when the proportions are kept.
    private void Edited(TextBox box)
    {
        if (updating) return;
        var other = box == widthBox ? heightBox : widthBox;
        if (!double.TryParse(box.Text, NumberStyles.Float, CultureInfo.CurrentCulture, out var value) || value <= 0) { ok.IsEnabled = false; result.Text = "Type a number above 0."; return; }
        var side = box == widthBox ? width : height;
        var pixelsNow = (int)Math.Round(Percent ? side * value / 100 : value);
        if (box == widthBox) NewWidth = pixelsNow; else NewHeight = pixelsNow;
        if (keep.IsChecked == true)
        {
            var ratio = pixelsNow / (double)side;
            if (box == widthBox) NewHeight = Math.Max(1, (int)Math.Round(height * ratio)); else NewWidth = Math.Max(1, (int)Math.Round(width * ratio));
            updating = true; other.Text = Percent ? F(ratio * 100) : (box == widthBox ? NewHeight : NewWidth).ToString(CultureInfo.CurrentCulture); updating = false;
        }
        ShowResult();
    }
    private void ShowResult()
    {
        var fits = NewWidth >= 1 && NewHeight >= 1 && NewWidth <= MainWindow.MaxResizeSide && NewHeight <= MainWindow.MaxResizeSide;
        ok.IsEnabled = fits;
        result.Text = fits ? $"New size: {NewWidth} × {NewHeight} pixels" : $"Choose a size from 1 to {MainWindow.MaxResizeSide} pixels.";
    }
    // For checks: type into a box as the user would.
    internal void Type(bool widthField, string text) => (widthField ? widthBox : heightBox).Text = text;
    internal void UsePercent(bool on) => (on ? percent : pixels).IsChecked = true;
    internal void KeepProportions(bool on) => keep.IsChecked = on;
}
