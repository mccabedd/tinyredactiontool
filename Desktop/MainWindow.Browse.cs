using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace TinyRedaction.Desktop;

// 0.23.0 (David): the previous and next picture in the folder, full screen,
// Fit width, File info (what the export removes) and a slideshow of a folder's pictures.
public partial class MainWindow
{
    internal static readonly string[] PictureExtensions =
        [".png", ".jpg", ".jpeg", ".jpe", ".bmp", ".tif", ".tiff", ".gif", ".webp", ".apng", ".tga", ".dds", ".exr", ".hdr", ".dpx", ".jp2", ".j2k", ".j2c", ".jpc", ".jls", ".psd", ".pcx", ".qoi", ".avif", ".heic", ".heif"];
    // The file the user opened (not a capture, and not the working copy a Rotate or Resize made), for the folder's
    // other pictures and File info.
    private string? openedPath;
    internal string? OpenedPath => openedPath;

    // ---- Previous and next picture in the folder ----
    // The folder's pictures in File Explorer's order (numbers in names count as numbers: 2 before 10).
    internal static List<string> FolderPictures(string folder)
    {
        try
        {
            var files = Directory.EnumerateFiles(folder).Where(f => PictureExtensions.Contains(Path.GetExtension(f).ToLowerInvariant())
                && (File.GetAttributes(f) & (FileAttributes.Hidden | FileAttributes.System)) == 0).ToList();
            files.Sort((a, b) => StrCmpLogicalW(Path.GetFileName(a), Path.GetFileName(b)));
            return files;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { return []; }
    }
    // The picture `step` places from `current` in its folder; null at either end. A file no longer there still has
    // its place in the order.
    internal static string? Neighbour(string current, int step)
    {
        var pictures = FolderPictures(Path.GetDirectoryName(current)!);
        var index = pictures.FindIndex(p => string.Equals(p, current, StringComparison.OrdinalIgnoreCase));
        if (index < 0)
        {
            var place = pictures.FindIndex(p => StrCmpLogicalW(Path.GetFileName(p), Path.GetFileName(current)) > 0);
            index = place < 0 ? pictures.Count : place;
            if (step > 0) index--;
        }
        var target = index + step;
        return target >= 0 && target < pictures.Count ? pictures[target] : null;
    }
    private async void PreviousPicture(object sender, RoutedEventArgs e) => await StepPictureAsync(-1);
    private async void NextPicture(object sender, RoutedEventArgs e) => await StepPictureAsync(1);
    internal async Task<bool> StepPictureAsync(int step)
    {
        if (busy || closing) return false;
        if (openedPath == null || Project.Media?.IsVideo == true) { Status.Text = "Open a picture from a folder first."; return false; }
        if (Neighbour(openedPath, step) is not { } target) { Status.Text = step > 0 ? "This is the last picture in the folder." : "This is the first picture in the folder."; return false; }
        return await OpenPathAsync(target);
    }

    // ---- Full screen (F11) ----
    private (WindowStyle Style, WindowState State, ResizeMode Resize, Visibility Menu, Visibility Tools, Visibility Options, Visibility Panel, GridLength Column)? beforeFullScreen;
    internal bool IsFullScreen => beforeFullScreen != null;
    private void ToggleFullScreen(object sender, RoutedEventArgs e) => SetFullScreen(!IsFullScreen);
    internal void SetFullScreen(bool on)
    {
        if (on == IsFullScreen) return;
        if (on)
        {
            beforeFullScreen = (WindowStyle, WindowState, ResizeMode, MenuRow.Visibility, ToolStrip.Visibility, OptionsBar.Visibility, PropertiesPanel.Visibility, PropertiesColumn.Width);
            MenuRow.Visibility = ToolStrip.Visibility = OptionsBar.Visibility = PropertiesPanel.Visibility = Visibility.Collapsed;
            PropertiesColumn.Width = new GridLength(0);
            // A window without a frame covers the taskbar only when it is maximised after losing the frame.
            WindowState = WindowState.Normal; WindowStyle = WindowStyle.None; ResizeMode = ResizeMode.NoResize; WindowState = WindowState.Maximized;
            Status.Text = "Full screen. Esc or F11 returns.";
        }
        else if (beforeFullScreen is { } was)
        {
            beforeFullScreen = null;
            WindowState = WindowState.Normal; WindowStyle = was.Style; ResizeMode = was.Resize; WindowState = was.State;
            MenuRow.Visibility = was.Menu; ToolStrip.Visibility = was.Tools; OptionsBar.Visibility = was.Options; PropertiesPanel.Visibility = was.Panel; PropertiesColumn.Width = was.Column;
            UpdateOptionsBar();
        }
        Preview.Focus();
    }

    // ---- Fit width ----
    private void FitWidth(object sender, RoutedEventArgs e) { Preview.FitWidth(); Status.Text = "Fit width: the mouse wheel scrolls; Ctrl+wheel zooms."; }

    // ---- File info ----
    private async void ShowFileInfo(object sender, RoutedEventArgs e) => await ShowFileInfoAsync();
    internal async Task<FileInfoWindow?> ShowFileInfoAsync(bool show = true)
    {
        if (busy || Project.Media is not { } media) { Status.Text = "Open a picture or video first."; return null; }
        var path = openedPath != null && File.Exists(openedPath) ? openedPath : media.Path;
        FileReport? found = null;
        await RunWork(async token => { found = await FileDetails.ReportAsync(tools, path, !media.IsVideo, token); }, "Reading the file info cancelled.", "Reading the File Info");
        if (found == null) return null;
        var window = new FileInfoWindow(Path.GetFileName(path), found) { Owner = this };
        if (show) window.ShowDialog();
        return window;
    }

    // ---- Slideshow (F5) ----
    private void StartSlideshow(object sender, RoutedEventArgs e) => StartSlideshow();
    internal SlideshowWindow? StartSlideshow(string? folder = null, bool show = true)
    {
        if (busy) return null;
        string? start = null;
        if (folder == null && openedPath != null && Project.Media?.IsVideo != true) { folder = Path.GetDirectoryName(openedPath); start = openedPath; }
        if (folder == null)
        {
            var dialog = new Microsoft.Win32.OpenFolderDialog { Title = "Choose a Folder of Pictures", Multiselect = false };
            if (dialog.ShowDialog(this) != true) return null;
            folder = dialog.FolderName;
        }
        var pictures = FolderPictures(folder);
        if (pictures.Count == 0) { Status.Text = "That folder has no pictures."; return null; }
        var first = start == null ? 0 : Math.Max(0, pictures.FindIndex(p => string.Equals(p, start, StringComparison.OrdinalIgnoreCase)));
        var slideshow = new SlideshowWindow(pictures, first, TimeSpan.FromSeconds(Settings.SlideshowSeconds), Settings.SlideshowRepeat, SlideshowPicture)
        {
            PreviousKey = Settings.PreviousPictureKey, NextKey = Settings.NextPictureKey,
            NavShownAtStart = Settings.NavBarInSlideshow, NavPinnedAtStart = Settings.NavBarPinnedInSlideshow, NavPictureSize = Settings.NavBarThumbnailSize,
            NavSizeChosen = size => { Settings.NavBarThumbnailSize = (int)size; Settings.Save(); RefreshNavBar(); },
        };
        if (show) slideshow.Show();
        return slideshow;
    }
    // Pictures Windows can't read itself (for example TGA, DDS, EXR, PSD) are read with TRT's FFmpeg.
    private async Task<System.Windows.Media.Imaging.BitmapSource?> SlideshowPicture(string path, CancellationToken token)
    {
        try { return await tools.FrameAsync(path, null, null, token); }
        catch (Exception ex) when (ex is IOException or InvalidDataException or InvalidOperationException) { return null; }
    }

    // Keys for these (from WindowKeyDown): Left/Right or Page Up/Down step pictures, F11 full screen, F5 slideshow.
    // Decided at once (the key is handled before anything is awaited); the work then runs on.
    private bool BrowseKey(KeyEventArgs e)
    {
        if (e.Key == Key.F11) { SetFullScreen(!IsFullScreen); return true; }
        if (e.Key == Key.Escape && IsFullScreen && !Preview.EyedropperActive) { SetFullScreen(false); return true; }
        if (e.Key == Key.F5 && Keyboard.Modifiers == ModifierKeys.None) { StartSlideshow(); return true; }
        if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.I) { _ = ShowFileInfoAsync(); return true; }
        // 0.24.0 (David): the keys chosen in Settings (Page Up and Page Down unless changed); Left and Right too, for pictures.
        var picture = Project.Media is { IsVideo: false };
        var key = e.Key == Key.System ? e.SystemKey : e.Key;
        if (!picture && key is Key.Left or Key.Right) return false; // A video's frame steps.
        var back = AppSettings.Matches(Settings.PreviousPictureKey, Keyboard.Modifiers, key) || picture && Keyboard.Modifiers == ModifierKeys.None && key == Key.Left;
        var on = AppSettings.Matches(Settings.NextPictureKey, Keyboard.Modifiers, key) || picture && Keyboard.Modifiers == ModifierKeys.None && key == Key.Right;
        if (back || on) { _ = StepPictureAsync(back ? -1 : 1); return true; }
        return false;
    }

    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode)] private static extern int StrCmpLogicalW(string a, string b);
}
