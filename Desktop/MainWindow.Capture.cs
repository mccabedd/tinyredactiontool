using System.IO;
using System.Security.Cryptography;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// The editor's side of capture (0.12.0): opening screenshots and recordings from the capture bar,
// the Original button (save/copy exactly as captured, optionally wiping TRT's copy) and wiping a
// capture once the editor no longer shows it.
public partial class MainWindow
{
    private CaptureController? captures;
    internal CaptureController? Captures
    {
        get => captures;
        set { captures = value; CaptureMenu.Visibility = QuitMenuItem.Visibility = value == null ? Visibility.Collapsed : Visibility.Visible; UpdateCaptureUi(); }
    }
    internal bool CanTakeCapture => !busy && !closing;
    private bool IsCapture => Project.Media is { } media && captures?.Store.Owns(media.Path) == true;
    private bool UnsavedCapture => IsCapture && !captures!.Store.IsKept(Project.Media!.Path);
    private string CaptureKind => Project.Media?.IsVideo == true ? "recording" : "screenshot";
    private void UpdateCaptureUi()
    {
        if (OriginalButton == null) return;
        OriginalButton.Visibility = IsCapture && !IsNewPicture ? Visibility.Visible : Visibility.Collapsed; // A New picture has no original to keep.
        OriginalMenuItem.IsEnabled = IsCapture && !IsNewPicture; // 0.27.0: also when David's toolbar hides the Original button.
        OriginalButton.ToolTip = $"Save or Copy the {(Project.Media?.IsVideo == true ? "Recording" : "Screenshot")} as Captured, Without Edits";
    }

    internal void ShowOpenDialog() => OpenMedia(this, new RoutedEventArgs());
    // Opens a file named from outside (File Explorer's "Open with TRT"), with the usual checks.
    internal async Task<bool> OpenPathAsync(string path)
    {
        if (busy || closing || !ConfirmDiscard()) return false;
        if (!File.Exists(path)) { Status.Text = "That file no longer exists."; return false; }
        var loaded = false;
        await RunWork(async token => { if (CheckPath(path, false)) { await LoadMedia(path, null, token); loaded = true; } }, "Loading cancelled. The previous workspace is unchanged.", "Opening");
        return loaded;
    }
    // Opens a new capture. False when the user keeps the current work, or it could not be opened.
    // ask: false when nothing is lost (0.26.1: New carries the current picture onto the new one).
    internal async Task<bool> OpenCaptureAsync(string path, bool ask = true, string? incoming = null)
    {
        if (busy || closing) return false;
        if (ask && UnsavedCapture)
        {
            incoming ??= Path.GetExtension(path).Equals(".mp4", StringComparison.OrdinalIgnoreCase) ? "new recording" : "new screenshot";
            var dirty = savedSnapshot != ProjectStore.Serialize(Project);
            if (!ConfirmKeepQuestion(this, $"Open the {incoming} instead?\n\nThe current {CaptureKind} has not been saved or exported. Any changes will be lost.", "Unsaved " + CaptureKind)) return false;
        }
        else if (ask && !ConfirmDiscard()) return false;
        var loaded = false;
        await RunWork(async token => { await LoadMedia(path, null, token); loaded = true; }, "Opening cancelled. The capture was not opened.", "Opening Capture");
        // Captures open at actual size (100%) (0.13.0); scroll or Fit to see more.
        if (loaded) { UpdateLayout(); Preview.ActualPixels(); ZoomText.Text = Preview.ZoomLabel; }
        if (loaded) Status.Text =$"{(Project.Media?.IsVideo == true ? "Recording" : "Screenshot")} ready. Redact or annotate it, then Export. Original saves or copies it exactly as captured.";
        return loaded;
    }
    // Wipes a capture the editor no longer shows (closed, cleared or replaced).
    private void ReleaseCapture(string? previous)
    {
        if (previous == null || captures is not { } c || !c.Store.Owns(previous) || string.Equals(previous, Project.Media?.Path, StringComparison.OrdinalIgnoreCase)) return;
        try { c.Store.Wipe(previous); }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { Status.Text = "TRT could not wipe the previous capture yet. It will be wiped when TRT quits."; }
    }
    private string ConfirmText(bool unsavedProject) =>
        $"This {CaptureKind} has not been saved or exported. Any changes will be lost.\n\nContinue?";

    private async void KeepOriginal(object sender, RoutedEventArgs e)
    {
        if (busy || !IsCapture || captures is not { } c || Project.Media is not { } media) return;
        var video = media.IsVideo;
        var folder = c.Settings.LastSaveFolder is { } last && Directory.Exists(last) ? last : Environment.GetFolderPath(video ? Environment.SpecialFolder.MyVideos : Environment.SpecialFolder.MyPictures);
        var blocked = policy.DisableSourceDeletion ? "Your organisation's policy turns off deleting originals. TRT still wipes its own copy when you close the capture or quit." : null;
        var dialog = new KeepCaptureWindow(video, Path.Combine(folder, Path.GetFileName(media.Path)), blocked) { Owner = this };
        if (dialog.ShowDialog() != true) return;
        await KeepOriginalAsync(dialog.SavePath, dialog.CopyToClipboard, dialog.DeleteCapture);
    }
    // The Original actions in order: save a verified copy, copy, then wipe TRT's capture.
    internal async Task<bool> KeepOriginalAsync(string? destination, bool copy, bool delete)
    {
        if (busy || !IsCapture || captures is not { } c || Project.Media is not { } media) return false;
        if (delete && policy.DisableSourceDeletion) delete = false;
        var dirty = savedSnapshot != ProjectStore.Serialize(Project);
        if (delete && destination == null && !ConfirmKeepQuestion(this, $"Wipe this {CaptureKind} without saving a copy? It closes in the editor." + (dirty ? " Your unsaved changes will be lost too." : ""), "Wipe Capture")) return false;
        if (destination != null && File.Exists(destination) && !ConfirmKeepQuestion(this, $"{Path.GetFileName(destination)} already exists. Replace it?", "Replace File")) return false;
        var done = false;
        await RunWork(async token =>
        {
            if (destination != null)
            {
                if (!CheckPath(destination, true)) return;
                Hint("Saving the Original Capture");
                await CopyVerifiedAsync(media.Path, destination, media.Sha256, token);
                c.Store.MarkKept(media.Path);
                c.Settings.LastSaveFolder = Path.GetDirectoryName(destination); c.Settings.Save();
            }
            if (copy)
            {
                if (media.IsVideo) Clipboard.SetFileDropList(new System.Collections.Specialized.StringCollection { destination! });
                else if (!CaptureController.CopyImage(DecodeOriginal(media.Path))) throw new IOException(CaptureController.ClipboardBusy);
            }
            if (delete && destination != null)
            {
                // Carry on with the saved copy (same fingerprint), so redactions and annotations stay.
                await LoadMedia(destination, Project, token);
                if (dirty) savedSnapshot = null;
            }
            done = true;
        }, "Cancelled. The capture was not changed.", "Saving the Original");
        if (!done) return false;
        if (delete && destination == null) ClearWorkspace();
        Status.Text = (destination != null ? $"Saved {Path.GetFileName(destination)} exactly as captured. " : "") + (copy ? "Copied to the clipboard as captured. " : "") +
            (delete ? destination != null ? "TRT's capture was wiped; the editor now uses the saved copy." : "TRT's capture was wiped." : "");
        UpdateCaptureUi();
        return true;
    }
    // Question asker for the Original actions; checks replace it to answer without a dialog.
    internal Func<Window, string, string, bool> ConfirmKeepQuestion { get; set; } =
        (owner, text, title) => ThemedMessage.Show(owner, text, title, MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes;
    private static BitmapSource DecodeOriginal(string path)
    {
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        var frame = BitmapDecoder.Create(stream, BitmapCreateOptions.PreservePixelFormat | BitmapCreateOptions.IgnoreColorProfile, BitmapCacheOption.OnLoad).Frames[0];
        frame.Freeze(); return frame;
    }
    // Writes a partial file beside the destination, checks it has the capture's exact fingerprint,
    // and only then puts it in place. A failed copy leaves any existing destination untouched.
    internal static async Task CopyVerifiedAsync(string source, string destination, string sha256, CancellationToken token)
    {
        var partial = destination + ".partial-" + Guid.NewGuid().ToString("N");
        try
        {
            await using (var input = new FileStream(source, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 16, true))
            await using (var output = new FileStream(partial, FileMode.CreateNew, FileAccess.Write, FileShare.None, 1 << 16, true))
                await input.CopyToAsync(output, token);
            string hash;
            await using (var check = new FileStream(partial, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 16, true)) hash = Convert.ToHexString(await SHA256.HashDataAsync(check, token));
            if (!string.Equals(hash, sha256, StringComparison.OrdinalIgnoreCase)) throw new IOException("The saved copy did not match the capture. Nothing was replaced.");
            File.Move(partial, destination, true);
        }
        finally { if (File.Exists(partial)) File.Delete(partial); }
    }

    // ---- Save media as… (0.18.0, David): the open picture or video exactly as it is on disk, without any
    // redactions or edits. The copy is checked against the file's fingerprint before it replaces anything.
    private async void SaveMediaAs(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Media is not { } media) return;
        var extension = Path.GetExtension(media.Path);
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = $"Same format as the original (*{extension})|*{extension}", AddExtension = true, AddToRecent = false,
            FileName = Path.GetFileNameWithoutExtension(media.Path) + "_COPY" + extension,
            InitialDirectory = captures?.Settings.LastSaveFolder is { } last && Directory.Exists(last) ? last : Path.GetDirectoryName(media.Path),
        };
        if (dialog.ShowDialog(this) != true) return;
        await SaveMediaAsAsync(dialog.FileName);
    }
    internal async Task<bool> SaveMediaAsAsync(string destination)
    {
        if (busy || Project.Media is not { } media) return false;
        if (ProjectStore.SamePath(destination, media.Path)) { Status.Text = "Choose another name: the original is not replaced."; return false; }
        if (File.Exists(destination) && !ConfirmKeepQuestion(this, $"{Path.GetFileName(destination)} already exists. Replace it?", "Replace File")) return false;
        var saved = false;
        await RunWork(async token =>
        {
            if (!CheckPath(destination, true)) return;
            await CopyVerifiedAsync(media.Path, destination, media.Sha256, token);
            captures?.Store.MarkKept(media.Path);
            saved = true;
        }, "Cancelled. Nothing was saved.", "Saving a Copy");
        if (saved) Status.Text = $"Saved {Path.GetFileName(destination)}: the {(media.IsVideo ? "video" : "picture")} as it is, without redactions or edits.";
        return saved;
    }

    // ---- Capture frame (0.18.0, David): the video frame on screen as a picture, to save, copy or edit. ----
    internal enum FrameUse { Save, Copy, Edit }
    // Checks answer the question without the dialog.
    internal Func<(FrameUse Use, bool WithEdits)?>? FrameQuestion { get; set; }
    private async void CaptureFrame(object sender, RoutedEventArgs e) => await CaptureFrameAsync();
    internal async Task<bool> CaptureFrameAsync(string? saveTo = null)
    {
        if (busy || closing || Project.Media is not { IsVideo: true } media || Preview.Timeline is not { } map) return false;
        if (Preview.UsePlayer || seekWork != null) { Pause(); if (!await SeekExact(Time)) return false; }
        if (Preview.Image is not { } frame) return false;
        var choice = FrameQuestion != null ? FrameQuestion() : AskFrameUse();
        if (choice is not { } chosen) return false;
        BitmapSource? picture = frame;
        if (chosen.WithEdits)
        {
            var snapshot = ProjectStore.Deserialize(ProjectStore.Serialize(Project)); snapshot.Export.KeepAudio = false; snapshot.Export.DeleteOriginal = false;
            var time = Time; picture = null;
            await RunWork(async token =>
            {
                if (snapshot.Regions.Count > 0 || snapshot.Annotations.Count > 0) ExportGate.Check(snapshot, policy);
                picture = await Task.Run(() => RenderForCopy(frame, snapshot, time, map, token), token);
            }, "Cancelled.", "Capturing the Frame");
            if (picture == null) return false;
        }
        var frameNumber = map.IndexAt(Time) + 1;
        switch (chosen.Use)
        {
            case FrameUse.Copy:
                if (!CaptureController.CopyImage(picture)) { Status.Text = CaptureController.ClipboardBusy; return false; }
                Status.Text = $"Frame {frameNumber} copied to the clipboard."; return true;
            case FrameUse.Save:
                var path = saveTo;
                if (path == null)
                {
                    var dialog = new Microsoft.Win32.SaveFileDialog { Filter = "PNG image|*.png|JPG image|*.jpg", AddExtension = true, AddToRecent = false, FileName = $"FRAME_{frameNumber}_{DateTime.Now:yyyyMMdd_HHmmss}.png" };
                    if (dialog.ShowDialog(this) != true) return false;
                    path = dialog.FileName;
                }
                if (!CheckPath(path, true)) return false;
                BitmapEncoder encoder = Path.GetExtension(path).Equals(".jpg", StringComparison.OrdinalIgnoreCase) ? new JpegBitmapEncoder { QualityLevel = 95 } : new PngBitmapEncoder();
                encoder.Frames.Add(BitmapFrame.Create(picture));
                using (var file = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None)) encoder.Save(file);
                Status.Text = $"Frame {frameNumber} saved as {Path.GetFileName(path)}."; return true;
            default:
                if (captures == null) { Status.Text = "Editing a frame needs the capture part of TRT, which is not running."; return false; }
                // 0.21.0 (David): in another editor window; the video stays open in this one.
                var capture = captures.Store.NewFile("FRAME", ".png");
                CaptureController.WritePng(picture, capture);
                var other = captures.OpenAnotherEditor();
                var opened = await other.OpenCaptureAsync(capture);
                if (!opened) { other.Close(); ReleaseCapture(capture); }
                else Status.Text = $"Frame {frameNumber} opened in another editor window.";
                return opened;
        }
    }
    private (FrameUse Use, bool WithEdits)? AskFrameUse()
    {
        (FrameUse Use, bool WithEdits)? answer = null;
        var withEdits = new CheckBox { Content = "Include Redactions and Annotations", IsChecked = true, Margin = new Thickness(0, 0, 0, 12) };
        var window = new Window
        {
            Title = "Capture Frame", Owner = this, SizeToContent = SizeToContent.WidthAndHeight, ResizeMode = ResizeMode.NoResize, ShowInTaskbar = false,
            WindowStartupLocation = WindowStartupLocation.CenterOwner, Background = (System.Windows.Media.Brush)FindResource("Surface"), Foreground = (System.Windows.Media.Brush)FindResource("Foreground"),
        };
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right };
        foreach (var (label, use, tip) in new[] { ("Save As…", FrameUse.Save, "Save the Frame as a PNG or JPG Picture"), ("Copy", FrameUse.Copy, "Copy the Frame to the Clipboard"), ("Edit", FrameUse.Edit, "Open the Frame as a New Picture in Another Editor Window (The Video Stays Open Here)") })
        {
            var button = new Button { Content = label, MinWidth = 80, ToolTip = tip };
            button.Click += (_, _) => { answer = (use, withEdits.IsChecked == true); window.Close(); };
            buttons.Children.Add(button);
        }
        var cancel = new Button { Content = "Cancel", MinWidth = 80, IsCancel = true }; cancel.Click += (_, _) => window.Close(); buttons.Children.Add(cancel);
        var layout = new StackPanel { Margin = new Thickness(16, 12, 16, 12) };
        layout.Children.Add(new TextBlock { Text = $"Frame {Preview.Timeline!.IndexAt(Time) + 1} at {TimeSpan.FromSeconds(Time):hh\\:mm\\:ss\\.fff}", FontWeight = FontWeights.SemiBold, Margin = new Thickness(0, 0, 0, 10) });
        layout.Children.Add(withEdits); layout.Children.Add(buttons);
        window.Content = layout; window.ShowDialog();
        return answer;
    }

    // ---- Drag and drop (0.18.0, David): one supported picture or video dropped on the editor opens it,
    // with the same checks and questions as File › Open. ----
    internal static string? DroppedMedia(IDataObject data)
    {
        if (!data.GetDataPresent(DataFormats.FileDrop) || data.GetData(DataFormats.FileDrop) is not string[] { Length: 1 } files) return null;
        var file = files[0];
        return File.Exists(file) && ExplorerMenu.Extensions.Contains(Path.GetExtension(file).ToLowerInvariant()) ? file : null;
    }
    private void MediaDragOver(object sender, DragEventArgs e)
    {
        e.Effects = !busy && DroppedMedia(e.Data) != null ? DragDropEffects.Copy : DragDropEffects.None;
        e.Handled = true;
    }
    private async void MediaDropped(object sender, DragEventArgs e)
    {
        e.Handled = true;
        if (busy) return;
        // 0.26.1: picture files dropped on a New picture go onto it, one or several.
        if (IsNewPicture && e.Data.GetData(DataFormats.FileDrop) is string[] dropped && dropped.Any(f => PictureExtensions.Contains(Path.GetExtension(f).ToLowerInvariant())))
        { Activate(); await AddPictureFilesAsync(dropped); return; }
        if (DroppedMedia(e.Data) is not { } file) { Status.Text = "Drop one picture or video file that TRT can open."; return; }
        Activate();
        await OpenPathAsync(file);
    }

    // ---- Copy and Paste (0.14.0, David) ----
    // Copy: the picture as Export would make it (redactions, annotations, crop), for a video the exact
    // paused frame. The same export gate and policy checks apply; nothing is written to disk.
    private async void CopyPicture(object sender, RoutedEventArgs e) => await CopyPictureAsync();
    internal async Task<bool> CopyPictureAsync()
    {
        if (busy || closing || Project.Media is not { } media) return false;
        if (media.IsVideo && (Preview.UsePlayer || seekWork != null)) { Pause(); if (!await SeekExact(Time)) return false; }
        if (Preview.Image is not { } frame || Preview.UsePlayer) { Status.Text = "Pause on a frame, then Copy."; return false; }
        var snapshot = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
        snapshot.Export.KeepAudio = false;
        var time = Time; var map = Preview.Timeline;
        BitmapSource? picture = null;
        await RunWork(async token =>
        {
            if (snapshot.Regions.Count > 0 || snapshot.Annotations.Count > 0 || snapshot.Crop != null) ExportGate.Check(snapshot, policy);
            picture = await Task.Run(() => RenderForCopy(frame, snapshot, media.IsVideo ? time : 0, media.IsVideo ? map : null, token), token);
        }, "Copy cancelled.", "Copying");
        if (picture == null) return false;
        if (!CaptureController.CopyImage(picture)) { Status.Text = CaptureController.ClipboardBusy; return false; }
        Status.Text = media.IsVideo ? "Copied this frame, with its redactions and annotations, to the clipboard." : "Copied the picture, with its redactions and annotations, to the clipboard.";
        return true;
    }
    internal static BitmapSource RenderForCopy(BitmapSource frame, RedactionProject project, double time, FrameTimeline? map, CancellationToken token)
    {
        var media = project.Media!;
        var annotations = AnnotationRaster.Create(project, media.Width, media.Height);
        var prepared = EffectRenderer.Render(frame, project, time, map, token, annotations);
        var converted = new System.Windows.Media.Imaging.FormatConvertedBitmap(prepared, System.Windows.Media.PixelFormats.Bgra32, null, 0);
        var width = converted.PixelWidth; var height = converted.PixelHeight;
        var pixels = new byte[checked(width * height * 4)];
        converted.CopyPixels(pixels, width * 4, 0);
        if (!media.IsVideo && project.Crop is { } crop)
        {
            pixels = ImageCrop.CropBgra(pixels, width, height, crop);
            width = (int)crop.Width; height = (int)crop.Height;
        }
        var result = BitmapSource.Create(width, height, 96, 96, System.Windows.Media.PixelFormats.Bgra32, null, pixels, width * 4);
        result.Freeze(); return result;
    }
    // Paste: a picture on the clipboard opens as a new capture (so Original and wiping work as for a
    // screenshot); a copied picture or video file opens like File › Open.
    private async void PastePicture(object sender, RoutedEventArgs e) => await PastePictureAsync();
    internal async Task<bool> PastePictureAsync()
    {
        if (busy || closing) return false;
        if (IsNewPicture) return await PasteOntoPictureAsync() > 0; // 0.26.0: onto a New picture, as items.
        try
        {
            if (Clipboard.ContainsFileDropList() && Clipboard.GetFileDropList() is { Count: 1 } files && files[0] is { } file && File.Exists(file))
                return await OpenPathAsync(file);
            // A PNG on the clipboard keeps its transparency (0.22.1); otherwise the ordinary picture.
            if ((Transparency.ClipboardPng() ?? (Clipboard.ContainsImage() ? Clipboard.GetImage() : null)) is not { } image) { Status.Text = "There is no picture on the clipboard to paste."; return false; }
            if (captures == null) { Status.Text = "Paste needs the capture part of TRT, which is not running."; return false; }
            var path = captures.Store.NewFile("PASTED", ".png");
            CaptureController.WritePng(image, path);
            var opened = await OpenCaptureAsync(path);
            if (!opened) ReleaseCapture(path);
            else Status.Text = "Pasted picture ready. Redact or annotate it, then Export or Copy.";
            return opened;
        }
        catch (System.Runtime.InteropServices.COMException) { Status.Text = "The clipboard is busy. Try Paste again."; return false; }
    }

    private async void MenuCapture(object sender, RoutedEventArgs e)
    {
        if (captures == null) return;
        await captures.CaptureAsync(Enum.Parse<CaptureMode>((string)((MenuItem)sender).Tag));
    }
    private void MenuRecorder(object sender, RoutedEventArgs e) => captures?.ShowRecorder(this);
    private void MenuRuler(object sender, RoutedEventArgs e) => captures?.ShowRuler(); // 0.27.0: the capture bar's Ruler button.
    private void MenuShowBar(object sender, RoutedEventArgs e) => captures?.ShowBar();
    private void QuitApp(object sender, RoutedEventArgs e) { if (captures != null) captures.Quit(); else Close(); }
}
