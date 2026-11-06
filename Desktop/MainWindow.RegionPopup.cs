using System.Windows;
using System.Windows.Controls;

namespace TinyRedaction.Desktop;

// Redaction popup (0.9.1, David's mockup): a small panel just below the new or selected
// redaction with Box/Blur/Pixelate, the effect's option, Delete and Redact (Review left in 0.14.0).
// On videos (0.13.0, David's design) it offers Start Redaction with an "Enable Manual Redaction" tick box (0.22.0; tracking unless ticked):
// ticked, the box follows the subject from this frame (the existing Follow process); not ticked,
// the box stays in place and Stop Redaction, shown on a later frame, ends it there.
// It hides while a drag is in progress, while playing or busy, and while editing text.
public partial class MainWindow
{
    private bool regionGestureActive;
    private Guid? trackingChoiceRegion;
    private void InitializeRegionPopup()
    {
        Preview.GestureStarted += () => { regionGestureActive = true; PositionRegionPopup(); };
        Preview.GestureEnded += () => { regionGestureActive = false; PositionRegionPopup(); };
        Preview.ViewportChanged += PositionRegionPopup;
        Preview.SizeChanged += (_, _) => PositionRegionPopup();
    }
    internal void PositionRegionPopup()
    {
        if (RegionPopup == null) return;
        PositionLinePopup(); PositionCropPopup();
        var region = Preview.Selected;
        if (region == null || !Project.Regions.Contains(region) || busy || playing || Preview.UsePlayer || regionGestureActive ||
            TextEditorPanel.Visibility == Visibility.Visible || !Preview.IsShown(region) || Project.Media == null)
        { RegionPopup.Visibility = Visibility.Collapsed; return; }
        var opaque = region.Effect == Core.RedactionEffect.Opaque;
        PopupColorOption.Visibility = opaque ? Visibility.Visible : Visibility.Collapsed;
        PopupStrengthOption.Visibility = opaque ? Visibility.Collapsed : Visibility.Visible;
        var video = Project.Media.IsVideo; var followed = region.Tracking.Count > 0;
        // The tick box starts clear for each redaction the popup shows.
        if (trackingChoiceRegion != region.Id) { trackingChoiceRegion = region.Id; PopupTrack.IsChecked = false; }
        var map = Preview.Timeline;
        var frame = map?.IndexAt(Time) ?? 0;
        var atStart = map == null || frame <= map.IndexAt(region.Start);
        var canFollow = FollowSubjectButton.IsEnabled;
        PopupTrack.Visibility = video && !followed && atStart ? Visibility.Visible : Visibility.Collapsed;
        PopupTrack.IsEnabled = canFollow;
        // 0.22.0 (David): tracking is the default; the tick box is "Enable Manual Redaction" (a box that stays put).
        PopupTrack.ToolTip = canFollow
            ? "Keep the Box in One Place Instead of Tracking"
            : "Nothing to track: this is the last frame of the redaction.";
        var tracking = TrackingChosen;
        PopupRedact.Content = !video ? "Redact" : followed || !atStart ? "Done" : "Start Redaction";
        PopupRedact.ToolTip = !video ? "Accept This Redaction" :
            followed || !atStart ? "Accept This Redaction" :
            tracking ? "Start Here and Track the Subject" :
            "Start Here; the Box Stays Until Stop Redaction";
        // Stop Redaction: on a frame after the start and before the current end.
        PopupStop.Visibility = video && map != null && !atStart && map.Frames[frame].Time < region.End - .0000001 ? Visibility.Visible : Visibility.Collapsed;
        PopupFollow.Visibility = video && followed ? Visibility.Visible : Visibility.Collapsed;
        PopupFollow.ToolTip = PopupFollow.IsEnabled ? "Track Again from This Frame" : "Nothing to track: this is the redaction's last frame.";
        RegionPopup.Visibility = Visibility.Visible;
        RegionPopup.UpdateLayout();
        var bounds = Preview.RegionScreenBounds(region);
        var width = RegionPopup.ActualWidth; var height = RegionPopup.ActualHeight;
        var layerWidth = TextEditorLayer.ActualWidth; var layerHeight = TextEditorLayer.ActualHeight;
        // Below the shape; above it when there is no room; otherwise inside the bottom edge.
        var x = Math.Clamp(bounds.X + bounds.Width / 2 - width / 2, 4, Math.Max(4, layerWidth - width - 4));
        var y = bounds.Bottom + 10;
        if (y + height > layerHeight - 4) y = bounds.Top - 10 - height;
        if (y < 4) y = Math.Max(4, layerHeight - height - 4);
        Canvas.SetLeft(RegionPopup, x); Canvas.SetTop(RegionPopup, y);
    }
    private void TrackingChoiceChanged(object sender, RoutedEventArgs e) { if (!updating && RegionPopup?.Visibility == Visibility.Visible) PositionRegionPopup(); }
    // Start Redaction tracks unless Enable Manual Redaction is ticked (or there is nothing left to track).
    private bool TrackingChosen => PopupTrack.Visibility == Visibility.Visible && PopupTrack.IsEnabled && PopupTrack.IsChecked != true;
    // "Redact" / "Start Redaction" / "Done": accept the redaction, exactly like clicking outside it;
    // Start Redaction runs the tracking unless Enable Manual Redaction is ticked.
    private async void AcceptRegion(object sender, RoutedEventArgs e)
    {
        if (busy || Preview.Selected == null) return;
        if (TrackingChosen) { await FollowSelectedSubject(); return; }
        var started = (string)PopupRedact.Content == "Start Redaction";
        Preview.Selected = null; Refresh();
        Status.Text = started ? "Redaction started. It stays in place to the end of the video. To end it sooner, play or step to that frame, click the redaction and choose Stop Redaction." :
            "Redaction accepted. Click it again to change it.";
    }
    private async void StopRedactionFromPopup(object sender, RoutedEventArgs e)
    {
        if (busy || Preview.Selected is not { } region) return;
        await StopSelectedRedaction();
        if (Project.Regions.Contains(region) && Preview.Selected == region) { Preview.Selected = null; Refresh(); }
    }
}
