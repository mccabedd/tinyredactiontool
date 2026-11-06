using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;

namespace TinyRedaction.Desktop;

// The capture bar (0.12.0). It only passes clicks to the CaptureController and shows the current
// choices; the controller does the capturing.
public partial class CaptureBar : Window
{
    private readonly CaptureController owner;
    internal CaptureBar(CaptureController controller)
    {
        owner = controller;
        InitializeComponent();
        ShowSettings(owner.Settings);
        LocationChanged += (_, _) => { if (IsVisible && !owner.BarSliding) { owner.Settings.BarLeft = Left; owner.Settings.BarTop = Top; } };
    }
    // The buttons chosen in Settings, in their order (0.14.0). A thin line separates the capture
    // buttons, the recorder and ruler, and the editor and Output; Menu is always last.
    internal Button BarButton(string id) => (Button)FindName(id + "Button");
    private static int Group(string id) => id switch { "Recorder" or "Ruler" => 1, "Editor" or "Output" => 2, _ => 0 };
    internal void ArrangeButtons(IReadOnlyList<string> shown)
    {
        CaptureButtons.Children.Clear();
        int? previous = null;
        foreach (var id in shown.Where(AppSettings.BarButtonIds.Contains))
        {
            if (previous is { } group && group != Group(id))
                CaptureButtons.Children.Add(new System.Windows.Shapes.Rectangle { Width = 1, Height = 20, Margin = new Thickness(3, 0, 3, 0), Fill = (Brush)FindResource("ChromeLine") });
            CaptureButtons.Children.Add(BarButton(id)); previous = Group(id);
        }
        CaptureButtons.Children.Add(MenuButton);
    }
    // Tooltips name the shortcuts; the Output button shows where captures go.
    internal void ShowSettings(AppSettings settings)
    {
        ArrangeButtons(settings.BarButtons);
        // Tooltip wording chosen by David (0.21.3, docs/TOOLTIPS.md).
        RegionButton.ToolTip = "Capture a Rectangle: Drag Round the Area";
        FullScreenButton.ToolTip = settings.FullScreenAllMonitors ? "Capture All Screens" : "Capture the Screen with the Cursor";
        RecorderButton.ToolTip = "Record the Screen as a Video";
        CloseButton.ToolTip = settings.CloseButtonQuits ? "Quit TinyRedactionTool" : "Hide the Bar (TRT Keeps Running in the Notification Area)";
        ToEditorItem.IsChecked = settings.Output == CaptureOutput.Editor;
        ToClipboardItem.IsChecked = settings.Output == CaptureOutput.Clipboard;
        ToFileItem.IsChecked = settings.Output == CaptureOutput.File;
        MousePointerItem.IsChecked = settings.CaptureMousePointer;
        var (icon, accent, brush, text) = settings.Output switch
        {
            CaptureOutput.Clipboard => ("IconToClipboard", "AccentToClipboard", "AccentFolder", "Captures Go to the Clipboard"),
            CaptureOutput.File => ("IconSave", "AccentSave", "AccentBlue", "Captures Are Saved to a File"),
            _ => ("IconEditor", "AccentPencil", "AccentRed", "Captures Go to the Editor"),
        };
        Toolbar.SetIcon(OutputButton, (Geometry)FindResource(icon)); Toolbar.SetAccent(OutputButton, (Geometry)FindResource(accent)); Toolbar.SetAccentBrush(OutputButton, (Brush)FindResource(brush));
        OutputButton.ToolTip = text + ". Click to change.";
    }
    internal void SetBusy(bool busy) { foreach (var child in CaptureButtons.Children.OfType<Button>()) child.IsEnabled = !busy || child == MenuButton; }
    // After a drag, the controller docks the bar if it was dropped at the top edge of a screen.
    private void DragBar(object sender, MouseButtonEventArgs e) { if (e.ButtonState != MouseButtonState.Pressed) return; DragMove(); owner.BarMoved(); }
    private void Minimise(object sender, RoutedEventArgs e) => owner.MinimizeToStrip();
    private void HideClick(object sender, RoutedEventArgs e) => owner.HideToTray(true);
    private void RulerClick(object sender, RoutedEventArgs e) => owner.ShowRuler();
    private void CloseBar(object sender, RoutedEventArgs e) { if (owner.Settings.CloseButtonQuits) owner.Quit(); else owner.HideToTray(true); }
    private async void CaptureClick(object sender, RoutedEventArgs e) => await owner.CaptureAsync(Enum.Parse<CaptureMode>((string)((Button)sender).Tag));
    private void RecorderClick(object sender, RoutedEventArgs e) => owner.ShowRecorder(this);
    private void EditorClick(object sender, RoutedEventArgs e) => owner.OpenEditor();
    private void OpenFileClick(object sender, RoutedEventArgs e) => owner.OpenFileInEditor();
    private void SettingsClick(object sender, RoutedEventArgs e) => owner.EditSettings(this);
    private void AboutClick(object sender, RoutedEventArgs e) => owner.ShowAbout(this);
    private void HelpClick(object sender, RoutedEventArgs e) => HelpManual.Open(this); // 3.0.0 (David)
    private void RemoveHistoryClick(object sender, RoutedEventArgs e) => owner.AskRemoveHistory(this); // 0.28.0 (David)
    private void QuitClick(object sender, RoutedEventArgs e) => owner.Quit();
    private void OutputClick(object sender, RoutedEventArgs e) => OpenMenu(OutputButton);
    private void MenuClick(object sender, RoutedEventArgs e) => OpenMenu(MenuButton);
    private static void OpenMenu(Button button)
    {
        var menu = button.ContextMenu; menu.PlacementTarget = button; menu.Placement = PlacementMode.Bottom; menu.IsOpen = true;
    }
    private void OutputChosen(object sender, RoutedEventArgs e) => owner.SetOutput(Enum.Parse<CaptureOutput>((string)((MenuItem)sender).Tag));
    private void MousePointerChosen(object sender, RoutedEventArgs e) => owner.SetCaptureMousePointer(MousePointerItem.IsChecked);
}
