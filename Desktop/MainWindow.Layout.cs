using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Shapes;
using System.Windows.Threading;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// 0.10.0 (David's 0.9.2 feedback): Settings window and toolbar layout, short notices in place
// of the status line, the reason Export is unavailable, and the floating Line/Polyline window.
public partial class MainWindow
{
    internal AppSettings Settings { get; private set; } = new();
    private bool quietStatus;
    private readonly DispatcherTimer noticeTimer = new() { Interval = TimeSpan.FromSeconds(5) };
    private EventHandler? statusWatcher;
    private void InitializeLayout()
    {
        statusWatcher = (_, _) => StatusChanged();
        var text = DependencyPropertyDescriptor.FromProperty(TextBlock.TextProperty, typeof(TextBlock));
        text.AddValueChanged(Status, statusWatcher);
        Closed += (_, _) => { text.RemoveValueChanged(Status, statusWatcher); noticeTimer.Stop(); };
        noticeTimer.Tick += (_, _) => { noticeTimer.Stop(); NoticeBar.Visibility = Visibility.Collapsed; };
        ApplySettings(AppSettings.Load());
    }

    // ---- Notices: results and warnings show briefly over the picture; tool tips stay quiet. ----
    private void Hint(string text) { quietStatus = true; try { Status.Text = text; } finally { quietStatus = false; } }
    private void StatusChanged()
    {
        if (quietStatus || string.IsNullOrWhiteSpace(Status.Text)) return;
        NoticeText.Text = Status.Text; NoticeBar.Visibility = Visibility.Visible;
        noticeTimer.Stop(); noticeTimer.Start();
    }

    // ---- Settings ----
    private void OpenSettings(object sender, RoutedEventArgs e)
    {
        if (busy) return;
        if (captures != null) { captures.EditSettings(this); return; } // Shared with the capture bar (0.12.0).
        var dialog = new SettingsWindow(Settings) { Owner = this };
        if (dialog.ShowDialog() != true) return;
        ApplySettings(dialog.Result);
        SetTheme(dialog.ThemeChosen);
        Status.Text = dialog.Result.Save() ? "Settings saved." : "Settings applied, but they could not be saved for next time.";
    }
    internal void ApplySettings(AppSettings settings)
    {
        Settings = settings;
        var vertical = settings.VerticalToolbar; var small = settings.SmallIcons;
        var style = (Style)FindResource(small ? "SmallToolButton" : "ToolButton");
        ArrangeToolbar(settings); // 0.24.0: the buttons, order and sides chosen in Settings.
        // Panel (0.16.1) sits outside the wrapping buttons: far right across the top, at the bottom when vertical.
        // The Clear buttons and Panel (0.18.0) sit apart: far right across the top, at the bottom when vertical.
        foreach (var child in ToolButtons.Children.Cast<UIElement>().Concat(RightTools.Children.Cast<UIElement>()))
        {
            if (child is Button button) button.Style = style;
            else if (child is Rectangle separator)
            {
                separator.Width = vertical ? small ? 20 : 52 : 1;
                separator.Height = vertical ? 1 : small ? 22 : 36;
                separator.Margin = vertical ? new Thickness(2, 4, 2, 4) : new Thickness(4, 0, 4, 0);
            }
        }
        RightTools.Orientation = vertical ? Orientation.Vertical : Orientation.Horizontal;
        DockPanel.SetDock(RightTools, vertical ? Dock.Bottom : Dock.Right);
        RightTools.VerticalAlignment = vertical ? VerticalAlignment.Bottom : VerticalAlignment.Top;
        UpdateOptionsBar();
        ToolButtons.Orientation = vertical ? Orientation.Vertical : Orientation.Horizontal;
        ToolButtons.ItemWidth = vertical && !small ? 60 : double.NaN;
        DockPanel.SetDock(ToolStrip, vertical ? Dock.Left : Dock.Top);
        ToolStrip.BorderThickness = vertical ? new Thickness(0, 0, 1, 0) : new Thickness(0, 1, 0, 1);
        RefreshNavBar(); // 0.25.0: the navigation bar as Settings say (hidden while a video is open, 0.26.0).
    }

    // The options bar can be hidden in Settings (0.18.0). Cropping has its own window now (0.21.4), so a
    // hidden options bar stays hidden while cropping.
    internal void UpdateOptionsBar()
    {
        if (OptionsBar == null) return;
        OptionsBar.Visibility = !Settings.HideOptionsBar ? Visibility.Visible : Visibility.Collapsed;
    }
    // ---- Crop window under the crop rectangle (0.21.4, David), like the redaction and line windows. ----
    // Shown while the Crop tool has a rectangle drawn, or when a crop can be removed.
    private void PositionCropPopup()
    {
        if (CropPopup == null) return;
        var draft = Preview.Tool == "Crop" ? Preview.CropDraft : null;
        if (Preview.Tool != "Crop" || busy || Project.Media is not { IsVideo: false } || draft == null && Project.Crop == null)
        { CropPopup.Visibility = Visibility.Collapsed; return; }
        CropPopup.Visibility = Visibility.Visible;
        CropPopup.UpdateLayout();
        var width = CropPopup.ActualWidth; var height = CropPopup.ActualHeight;
        double x, y;
        if (draft is { } d)
        {
            var bounds = Preview.ScreenRect(d);
            x = bounds.X + bounds.Width / 2 - width / 2; y = bounds.Bottom + 12;
            if (y + height > TextEditorLayer.ActualHeight - 4) y = bounds.Top - 12 - height;
            if (y < 4) y = Math.Max(4, TextEditorLayer.ActualHeight - height - 4);
        }
        else { x = TextEditorLayer.ActualWidth / 2 - width / 2; y = 12; } // No rectangle yet: at the top, for Remove crop.
        Canvas.SetLeft(CropPopup, Math.Clamp(x, 4, Math.Max(4, TextEditorLayer.ActualWidth - width - 4))); Canvas.SetTop(CropPopup, y);
    }
    private void CancelCrop(object sender, RoutedEventArgs e) => CancelCropDraft();
    // Cancel crop: drop the rectangle and leave the Crop tool; any crop already applied stays.
    internal void CancelCropDraft()
    {
        if (busy || Preview.Tool != "Crop") return;
        Preview.CropDraft = null; Preview.Tool = "Rectangle"; Preview.Cursor = null;
        Refresh(); Preview.Focus();
        Status.Text = "Cropping cancelled.";
    }

    // ---- Export: say why it is unavailable (shown as the Export button's tooltip). ----
    internal string? ExportBlockReason()
    {
        if (Project.Media == null) return "open an image or video first.";
        if (Project.Regions.Count == 0 && Project.Annotations.Count == 0 && Project.Crop == null) return "draw a redaction, annotation or crop first.";
        // 0.14.0 (David): no separate Review step any more; followed ranges no longer hold up export.
        if (policy.DisableVisualObscuration && Project.Regions.Any(r => r.Effect != RedactionEffect.Opaque)) return "your organisation's policy allows only coloured boxes; change Blur or Pixelate redactions to Box.";
        return null;
    }

    // ---- Line / Polyline window under the selected line, like the text window. ----
    private void PositionLinePopup()
    {
        if (LinePopup == null) return;
        var a = SelectedAnnotation;
        if (a is null || a.Kind == AnnotationKind.Text || busy || playing || Preview.UsePlayer || regionGestureActive ||
            TextEditorPanel.Visibility == Visibility.Visible || !Preview.IsShown(a))
        { LinePopup.Visibility = Visibility.Collapsed; return; }
        LinePopupTitle.Text = KindName(a.Kind);
        LinePopup.Visibility = Visibility.Visible;
        LinePopup.UpdateLayout();
        var bounds = Preview.ScreenRect(a.Bounds());
        var width = LinePopup.ActualWidth; var height = LinePopup.ActualHeight;
        var x = Math.Clamp(bounds.X + bounds.Width / 2 - width / 2, 4, Math.Max(4, TextEditorLayer.ActualWidth - width - 4));
        var y = bounds.Bottom + 12;
        if (y + height > TextEditorLayer.ActualHeight - 4) y = bounds.Top - 12 - height;
        if (y < 4) y = Math.Max(4, TextEditorLayer.ActualHeight - height - 4);
        Canvas.SetLeft(LinePopup, x); Canvas.SetTop(LinePopup, y);
    }
    private void LinePopupDone(object sender, RoutedEventArgs e)
    {
        Preview.SelectAnnotation(null); Refresh(); Preview.Focus();
    }
}
