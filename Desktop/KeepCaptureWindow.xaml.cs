using System.IO;
using System.Windows;
using Microsoft.Win32;

namespace TinyRedaction.Desktop;

public partial class KeepCaptureWindow : Window
{
    private readonly bool video;
    public string? SavePath { get; private set; }
    public bool CopyToClipboard { get; private set; }
    public bool DeleteCapture { get; private set; }
    public KeepCaptureWindow(bool isVideo, string suggestedPath, string? deletionBlocked)
    {
        video = isVideo;
        InitializeComponent();
        Heading.Text = $"Save or copy the {(video ? "recording" : "screenshot")} as captured";
        DestinationBox.Text = suggestedPath;
        CopyNote.Visibility = video ? Visibility.Visible : Visibility.Collapsed;
        if (deletionBlocked != null) { DeleteBox.IsEnabled = false; DeleteBox.ToolTip = deletionBlocked; DeleteNote.Text = deletionBlocked; }
        ChoicesChanged(this, new RoutedEventArgs());
    }
    private void Browse(object sender, RoutedEventArgs e)
    {
        var current = DestinationBox.Text;
        var dialog = new SaveFileDialog
        {
            Filter = video ? "MP4 video|*.mp4" : "PNG image|*.png", AddExtension = true, AddToRecent = false,
            FileName = Path.GetFileName(current), InitialDirectory = Path.GetDirectoryName(current) ?? ""
        };
        if (dialog.ShowDialog(this) == true) DestinationBox.Text = dialog.FileName;
    }
    internal void ChoicesChanged(object sender, RoutedEventArgs e)
    {
        if (OkButton == null) return;
        var save = SaveBox.IsChecked == true;
        DestinationBox.IsEnabled = BrowseButton.IsEnabled = save;
        Message.Text = video && CopyBox.IsChecked == true && !save ? "To copy a recording, also save it." :
            DeleteBox.IsChecked == true && !save ? "Without a saved copy, deleting wipes the capture and closes it in the editor." :
            SaveBox.IsChecked != true && CopyBox.IsChecked != true && DeleteBox.IsChecked != true ? "Choose at least one thing to do." : "";
        OkButton.IsEnabled = !(video && CopyBox.IsChecked == true && !save) && (save || CopyBox.IsChecked == true || DeleteBox.IsChecked == true);
    }
    internal bool Collect()
    {
        SavePath = SaveBox.IsChecked == true ? DestinationBox.Text.Trim() : null;
        if (SavePath != null && (SavePath.Length == 0 || !Path.IsPathRooted(SavePath))) { Message.Text = "Choose where to save the copy."; return false; }
        if (SavePath != null && !Path.GetExtension(SavePath).Equals(video ? ".mp4" : ".png", StringComparison.OrdinalIgnoreCase)) { Message.Text = video ? "Save the recording as an .mp4 file." : "Save the screenshot as a .png file."; return false; }
        CopyToClipboard = CopyBox.IsChecked == true; DeleteCapture = DeleteBox.IsEnabled && DeleteBox.IsChecked == true;
        return true;
    }
    private void Accept(object sender, RoutedEventArgs e) { if (Collect()) DialogResult = true; }
}
