using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// File › New (0.26.0, David: "like any popular image creation tool"): a blank picture of a chosen size, shape and
// background (a colour, or transparent) to draw on with the annotation tools and paste pictures onto. Pictures only.
internal sealed class NewPictureWindow : Window
{
    internal sealed record Preset(string Name, int Width, int Height) { public override string ToString() => Width > 0 ? $"{Name} ({Width} × {Height})" : Name; }
    internal const int MaxSide = 10_000;
    internal NumberSpinner WidthBox { get; } = new() { Minimum = 1, Maximum = MaxSide, Value = 1920 };
    internal NumberSpinner HeightBox { get; } = new() { Minimum = 1, Maximum = MaxSide, Value = 1080 };
    internal ComboBox Presets { get; } = new() { Width = 300 };
    internal RadioButton Landscape { get; } = new() { Content = "Landscape", GroupName = "Orientation", Margin = new(0, 2, 16, 2), IsChecked = true };
    internal RadioButton Portrait { get; } = new() { Content = "Portrait", GroupName = "Orientation", Margin = new(0, 2, 0, 2) };
    internal RadioButton White { get; } = new() { Content = "White", GroupName = "Background", Margin = new(0, 2, 16, 2), IsChecked = true };
    internal RadioButton Black { get; } = new() { Content = "Black", GroupName = "Background", Margin = new(0, 2, 16, 2) };
    internal RadioButton Clear { get; } = new() { Content = "Transparent", GroupName = "Background", Margin = new(0, 2, 16, 2) };
    internal RadioButton Coloured { get; } = new() { Content = "Colour:", GroupName = "Background", Margin = new(0, 2, 6, 2), VerticalAlignment = VerticalAlignment.Center };
    private readonly Border swatch = new() { Width = 26, Height = 14, BorderThickness = new(1), BorderBrush = new SolidColorBrush(Color.FromRgb(0x9A, 0xA3, 0xB2)) };
    internal Color Chosen { get; set; } = Color.FromRgb(0x1E, 0x5A, 0xA8);
    private bool updating;
    public (int Width, int Height, Color? Background, bool Carry)? Result { get; private set; }

    // 0.26.1 (David: a screenshot was lost to a larger New canvas): the picture that is open goes onto the new one.
    internal CheckBox Carry { get; } = new() { Content = "Put the Current Image on It (With Its Redactions and Annotations)", Margin = new(0, 2, 0, 2) };
    public NewPictureWindow(BitmapSource? clipboard, BitmapSource? current = null)
    {
        Title = "New Image"; SizeToContent = SizeToContent.WidthAndHeight; ResizeMode = ResizeMode.NoResize; WindowStartupLocation = WindowStartupLocation.CenterOwner; ShowInTaskbar = false;
        SetResourceReference(BackgroundProperty, "Background"); SetResourceReference(ForegroundProperty, "Foreground");
        foreach (var radio in new[] { Landscape, Portrait, White, Black, Clear, Coloured }) radio.SetResourceReference(ForegroundProperty, "Foreground");
        WidthBox.Box.Width = HeightBox.Box.Width = 64;
        var presets = new List<Preset>();
        if (current != null) presets.Add(new("The Current Image", current.PixelWidth, current.PixelHeight));
        if (clipboard != null) presets.Add(new("The Image on the Clipboard", clipboard.PixelWidth, clipboard.PixelHeight));
        presets.AddRange([new("Full HD", 1920, 1080), new("HD", 1280, 720), new("4K", 3840, 2160), new("Square", 1080, 1080), new("Portrait Post", 1080, 1350),
            new("Phone Story", 1080, 1920), new("A4 at 150 dpi", 1754, 1240), new("Letter at 150 dpi", 1650, 1275), new("Custom", 0, 0)]);
        Presets.ItemsSource = presets;
        Presets.SelectionChanged += (_, _) => { if (Presets.SelectedItem is Preset { Width: > 0 } p && !updating) Show(p.Width, p.Height); };
        WidthBox.ValueChanged += (_, _) => Typed(); HeightBox.ValueChanged += (_, _) => Typed();
        Landscape.Checked += (_, _) => Turn(); Portrait.Checked += (_, _) => Turn();
        swatch.Background = new SolidColorBrush(Chosen);
        var pick = new Button { Content = swatch, Padding = new(4), ToolTip = "Background Colour" };
        pick.Click += (_, _) => { if (PickColour()) Coloured.IsChecked = true; };

        var grid = new Grid { Margin = new(16, 14, 16, 8) };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto }); grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        void Row(string label, UIElement content)
        {
            var row = grid.RowDefinitions.Count; grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            var text = new TextBlock { Text = label, VerticalAlignment = VerticalAlignment.Center, Margin = new(0, 6, 14, 6) };
            Grid.SetRow(text, row); Grid.SetRow(content, row); Grid.SetColumn(content, 1);
            if (content is FrameworkElement element) element.Margin = new(0, 6, 0, 6);
            grid.Children.Add(text); grid.Children.Add(content);
        }
        Row("Size", Presets);
        Row("Width", new StackPanel { Orientation = Orientation.Horizontal, Children = { WidthBox, new TextBlock { Text = "Pixels", VerticalAlignment = VerticalAlignment.Center, Margin = new(8, 0, 0, 0) } } });
        Row("Height", new StackPanel { Orientation = Orientation.Horizontal, Children = { HeightBox, new TextBlock { Text = "Pixels", VerticalAlignment = VerticalAlignment.Center, Margin = new(8, 0, 0, 0) } } });
        Row("Orientation", new StackPanel { Orientation = Orientation.Horizontal, Children = { Landscape, Portrait } });
        Row("Background", new StackPanel { Orientation = Orientation.Horizontal, Children = { White, Black, Clear, Coloured, pick } });
        Carry.SetResourceReference(ForegroundProperty, "Foreground"); Carry.IsChecked = current != null;
        if (current != null) Row("Keep", Carry);
        var create = new Button { Content = "Create", IsDefault = true, MinWidth = 80, Margin = new(0, 0, 8, 0), Padding = new(8, 3, 8, 3) };
        create.Click += (_, _) => Accept();
        var cancel = new Button { Content = "Cancel", IsCancel = true, MinWidth = 80, Padding = new(8, 3, 8, 3) };
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, Margin = new(16, 6, 16, 14), Children = { create, cancel } };
        Content = new StackPanel { Children = { grid, buttons } };
        Presets.SelectedItem = presets.First(p => p.Name == "Full HD"); // The current and clipboard sizes are in the list too.
    }
    private void Show(int width, int height)
    {
        updating = true;
        try
        {
            WidthBox.Value = width; HeightBox.Value = height;
            (width >= height ? Landscape : Portrait).IsChecked = true;
        }
        finally { updating = false; }
    }
    // A typed size that isn't a preset's is Custom.
    private void Typed()
    {
        if (updating) return;
        updating = true;
        try
        {
            var list = (List<Preset>)Presets.ItemsSource;
            Presets.SelectedItem = list.FirstOrDefault(p => p.Width == (int)WidthBox.Value && p.Height == (int)HeightBox.Value) ?? list[^1];
            (WidthBox.Value >= HeightBox.Value ? Landscape : Portrait).IsChecked = true;
        }
        finally { updating = false; }
    }
    // Landscape: the longer side across; Portrait: the longer side up and down.
    private void Turn()
    {
        if (updating) return;
        var w = WidthBox.Value; var h = HeightBox.Value;
        if (Landscape.IsChecked == true && h > w || Portrait.IsChecked == true && w > h) { updating = true; try { WidthBox.Value = h; HeightBox.Value = w; } finally { updating = false; } Typed(); }
    }
    private bool PickColour()
    {
        using var dialog = new System.Windows.Forms.ColorDialog { FullOpen = true, AnyColor = true, Color = System.Drawing.Color.FromArgb(Chosen.R, Chosen.G, Chosen.B) };
        if (dialog.ShowDialog() != System.Windows.Forms.DialogResult.OK) return false;
        Chosen = Color.FromRgb(dialog.Color.R, dialog.Color.G, dialog.Color.B); swatch.Background = new SolidColorBrush(Chosen);
        return true;
    }
    internal void Accept()
    {
        var background = White.IsChecked == true ? Colors.White : Black.IsChecked == true ? Colors.Black : Clear.IsChecked == true ? (Color?)null : Chosen;
        Result = ((int)Math.Clamp(WidthBox.Value, 1, MaxSide), (int)Math.Clamp(HeightBox.Value, 1, MaxSide), background, Carry.IsChecked == true && Carry.Parent != null);
        if (IsLoaded) DialogResult = true;
    }
    // The blank picture itself (transparent: every pixel clear).
    internal static BitmapSource Blank(int width, int height, Color? background)
    {
        var colour = background ?? Colors.Transparent;
        var pixels = new byte[checked(width * height * 4)];
        for (var i = 0; i < pixels.Length; i += 4) { pixels[i] = colour.B; pixels[i + 1] = colour.G; pixels[i + 2] = colour.R; pixels[i + 3] = colour.A; }
        var picture = BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4);
        picture.Freeze(); return picture;
    }
}

public partial class MainWindow
{
    // A picture made with New (until another one is opened): Paste puts pictures onto it.
    private bool newPicture;
    internal bool IsNewPicture => newPicture && Project.Media is { IsVideo: false };
    // Checks answer the New window themselves.
    internal Func<NewPictureWindow, bool>? AnswerNewPicture { get; set; }
    private async void NewPicture(object sender, RoutedEventArgs e) => await NewPictureAsync();
    internal async Task<bool> NewPictureAsync()
    {
        if (busy || closing) return false;
        if (captures == null) { Status.Text = "New needs the capture part of TRT, which is not running."; return false; }
        BitmapSource? clipboard = null;
        try { clipboard = Transparency.ClipboardPng() ?? (Clipboard.ContainsImage() ? Clipboard.GetImage() : null); } catch (System.Runtime.InteropServices.COMException) { }
        // The open picture as it looks now (redactions, annotations, crop), to carry onto the new one.
        BitmapSource? current = null;
        if (Project.Media is { IsVideo: false } && Preview.Image is { } shown)
            try { current = RenderForCopy(shown, Project, 0, null, CancellationToken.None); } catch (Exception ex) when (ex is InvalidOperationException or IOException or ArgumentException) { }
        var dialog = new NewPictureWindow(clipboard, current) { Owner = IsLoaded ? this : null };
        var answered = AnswerNewPicture != null ? AnswerNewPicture(dialog) : dialog.ShowDialog() == true;
        if (!answered || dialog.Result is not { } chosen) return false;
        var path = captures.Store.NewFile("NEW", ".png");
        CaptureController.WritePng(NewPictureWindow.Blank(chosen.Width, chosen.Height, chosen.Background), path);
        // Carried over, nothing is lost, so the "unsaved screenshot" question isn't asked.
        var carried = chosen.Carry && current != null;
        var opened = await OpenCaptureAsync(path, ask: !carried, incoming: "new picture");
        if (!opened) { ReleaseCapture(path); return false; }
        newPicture = true; UpdateCaptureUi();
        if (carried) Preview.AddPicture(current!);
        Preview.Fit(); ZoomText.Text = Preview.ZoomLabel; Refresh(); UpdateEditingState();
        Status.Text = $"New picture, {chosen.Width} × {chosen.Height}{(carried ? ", with the picture you had on it" : "")}. Screenshots, Paste (Ctrl+V) and File › Add picture go onto it; Export or Copy when done.";
        return true;
    }

    // A picture file at its full size, upright (EXIF orientation); null if Windows can't read it.
    private static BitmapSource? ReadWhole(string path)
    {
        try
        {
            var frame = BitmapDecoder.Create(new Uri(path), BitmapCreateOptions.IgnoreImageCache, BitmapCacheOption.OnLoad).Frames[0];
            BitmapSource shown = SlideshowWindow.Upright(frame) is { } turn ? new TransformedBitmap(frame, turn) : frame;
            // Plain pixels, free of the decoder (read on another thread, it would belong to that thread).
            var bgra = new FormatConvertedBitmap(shown, PixelFormats.Bgra32, null, 0);
            var pixels = new byte[checked(bgra.PixelWidth * bgra.PixelHeight * 4)]; bgra.CopyPixels(pixels, bgra.PixelWidth * 4, 0);
            var plain = BitmapSource.Create(bgra.PixelWidth, bgra.PixelHeight, 96, 96, PixelFormats.Bgra32, null, pixels, bgra.PixelWidth * 4);
            plain.Freeze(); return plain;
        }
        catch (Exception ex) when (ex is NotSupportedException or IOException or FileFormatException or UnauthorizedAccessException or ArgumentException or System.Runtime.InteropServices.COMException) { return null; }
    }
    // Paste onto picture (0.26.0): the clipboard picture, or picture files copied in File Explorer, as items on the open
    // picture (Edit › Paste onto picture, Ctrl+Shift+V; Paste does this too on a New picture).
    private async void PasteOntoPicture(object sender, RoutedEventArgs e) => await PasteOntoPictureAsync();
    internal async Task<int> PasteOntoPictureAsync()
    {
        if (busy || closing) return 0;
        if (Project.Media is not { IsVideo: false } media) { Status.Text = "Open a picture (or make a New one) to paste onto."; return 0; }
        var found = new List<BitmapSource>();
        try
        {
            if (Clipboard.ContainsFileDropList())
                foreach (var file in Clipboard.GetFileDropList().Cast<string>().Where(f => File.Exists(f) && PictureExtensions.Contains(Path.GetExtension(f).ToLowerInvariant())))
                    if (await Task.Run(() => ReadWhole(file)) is { } read) found.Add(read);
            if (found.Count == 0 && (Transparency.ClipboardPng() ?? (Clipboard.ContainsImage() ? Clipboard.GetImage() : null)) is { } image) found.Add(image);
        }
        catch (System.Runtime.InteropServices.COMException) { Status.Text = "The clipboard is busy. Try Paste again."; return 0; }
        if (found.Count == 0) { Status.Text = "There is no picture on the clipboard to paste."; return 0; }
        return AddPictures(found, "pasted");
    }
    // Pictures as items on the open picture; several at once step down and across a little, so each can be seen and picked.
    private int AddPictures(IReadOnlyList<BitmapSource> found, string done)
    {
        if (Project.Media is not { IsVideo: false } media) return 0;
        var added = 0;
        foreach (var (picture, i) in found.Select((p, i) => (p, i)))
        {
            // Several at once step down and across a little, so each can be seen and picked.
            var step = Math.Min(media.Width, media.Height) * 0.04 * i;
            if (Preview.AddPicture(picture, new MediaPoint(media.Width / 2.0 + step, media.Height / 2.0 + step)) != null) added++;
        }
        Refresh(); UpdateEditingState();
        Status.Text = added == 0 ? "That picture is too large to put onto this one." :
            $"{(added == 1 ? "Picture" : $"{added} pictures")} {done}. Drag to move; drag a corner to size (Shift stretches); Del removes; Ctrl+Z takes it back.";
        return added;
    }
    // File › Add picture… (0.26.1, David: open a picture without losing what is in the editor): picture files as items.
    private async void AddPictureFiles(object sender, RoutedEventArgs e)
    {
        if (busy || closing) return;
        if (Project.Media is not { IsVideo: false }) { Status.Text = "Open a picture (or make a New one) to add pictures to."; return; }
        var dialog = new Microsoft.Win32.OpenFileDialog { Title = "Add Images onto This One", Multiselect = true, AddToRecent = false, Filter = "Images|" + string.Join(";", PictureExtensions.Select(x => "*" + x)) };
        if (dialog.ShowDialog(this) != true) return;
        await AddPictureFilesAsync(dialog.FileNames);
    }
    internal async Task<int> AddPictureFilesAsync(IEnumerable<string> files)
    {
        var found = new List<BitmapSource>();
        foreach (var file in files.Where(f => File.Exists(f) && PictureExtensions.Contains(Path.GetExtension(f).ToLowerInvariant())))
            if (await Task.Run(() => ReadWhole(file)) is { } read) found.Add(read);
        if (found.Count == 0) { Status.Text = "Those files aren't pictures TRT can read."; return 0; }
        return AddPictures(found, "added");
    }
    // A new screenshot while a New picture is open (0.26.1, David): it goes onto the picture as an item instead of
    // replacing it (the capture file is then wiped; its pixels are in the picture). False when it should open as usual.
    internal async Task<bool> AddCaptureOntoNewPictureAsync(string path)
    {
        if (!IsNewPicture || busy || closing || !PictureExtensions.Contains(Path.GetExtension(path).ToLowerInvariant())) return false;
        if (await Task.Run(() => ReadWhole(path)) is not { } shot) return false;
        if (IsLoaded) Activate();
        var added = AddPictures([shot], "added: the screenshot is on your picture") > 0;
        if (added && captures is { } c && c.Store.Owns(path)) try { c.Store.Wipe(path); } catch (IOException) { }
        return added;
    }
}
