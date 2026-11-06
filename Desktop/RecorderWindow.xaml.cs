using System.Windows;

namespace TinyRedaction.Desktop;

public partial class RecorderWindow : Window
{
    public RecordingArea Area { get; private set; }
    public int FramesPerSecond { get; private set; }
    public bool MousePointer { get; private set; }
    public bool MouseClicks { get; private set; }
    public RecorderWindow(AppSettings settings)
    {
        InitializeComponent();
        (settings.RecordingArea switch { RecordingArea.Window => WindowChoice, RecordingArea.FullScreen => FullScreenChoice, RecordingArea.FullScreenWithoutTaskbar => WorkAreaChoice, _ => RegionChoice }).IsChecked = true;
        FrameRateChoice.ItemsSource = AppSettings.FrameRates; FrameRateChoice.SelectedItem = settings.RecordingFramesPerSecond;
        PointerChoice.IsChecked = settings.RecordMousePointer;
        ClicksChoice.IsChecked = settings.RecordMouseClicks;
        Collect();
    }
    internal void Collect()
    {
        Area = WindowChoice.IsChecked == true ? RecordingArea.Window : FullScreenChoice.IsChecked == true ? RecordingArea.FullScreen : WorkAreaChoice.IsChecked == true ? RecordingArea.FullScreenWithoutTaskbar : RecordingArea.Region;
        FramesPerSecond = FrameRateChoice.SelectedItem is int fps ? fps : 15;
        MousePointer = PointerChoice.IsChecked == true;
        MouseClicks = ClicksChoice.IsChecked == true;
    }
    private void Record(object sender, RoutedEventArgs e) { Collect(); DialogResult = true; }
}
