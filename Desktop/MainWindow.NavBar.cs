using System.IO;
using System.Windows;

namespace TinyRedaction.Desktop;

// The navigation bar in the editor (0.25.0, David): the open picture's folder along the bottom. The Nav Bar button
// (or View › Navigation bar) shows it, Close hides it; in the editor it is always pinned. Play starts the slideshow
// from the picture that is open. 0.26.0 (David): not while a video is open; its top edge drags to resize it.
public partial class MainWindow
{
    private NavigationBar? navBar;
    internal NavigationBar? NavBar => navBar;
    // Wanted: Settings › Slideshow › Show it in the editor (and the Nav Bar button). Shown: wanted, and no video open.
    internal bool NavBarWanted => Settings.NavBarInEditor;
    internal bool NavBarShown => navBar is { Visibility: Visibility.Visible };
    private void ToggleNavBar(object sender, RoutedEventArgs e)
    {
        if (Project.Media?.IsVideo == true) { Status.Text = "The navigation bar is for pictures; it shows again when a picture is open."; return; }
        SetNavBar(!NavBarWanted, remember: true);
    }
    // Shows or hides the bar; remember keeps the choice for next time.
    internal void SetNavBar(bool show, bool remember)
    {
        if (remember && Settings.NavBarInEditor != show) { Settings.NavBarInEditor = show; Settings.Save(); }
        show &= Project.Media?.IsVideo != true;
        if (show && navBar == null)
        {
            navBar = new NavigationBar { CanUnpin = false, Pinned = true };
            navBar.PreviousClicked += () => _ = StepPictureAsync(-1);
            navBar.NextClicked += () => _ = StepPictureAsync(1);
            navBar.PlayClicked += () => StartSlideshow();
            navBar.CloseClicked += () => SetNavBar(false, remember: true);
            navBar.PictureChosen += path => { if (!busy && !string.Equals(path, openedPath, StringComparison.OrdinalIgnoreCase)) _ = OpenPathAsync(path); };
            navBar.SizeDragged += size => { Settings.NavBarThumbnailSize = (int)size; Settings.Save(); };
            NavBarHost.Child = navBar;
        }
        if (navBar != null) navBar.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
        if (show) RefreshNavBar();
    }
    // The folder of the picture that is open; hidden while a video is open (and back with the next picture).
    internal void RefreshNavBar()
    {
        var should = NavBarWanted && Project.Media?.IsVideo != true;
        if (should != NavBarShown && (navBar != null || should)) { SetNavBar(NavBarWanted, remember: false); return; }
        if (navBar == null || !NavBarShown) return;
        navBar.ThumbnailSize = Settings.NavBarThumbnailSize;
        var folder = openedPath != null ? Path.GetDirectoryName(openedPath) : null;
        navBar.Show(folder != null ? FolderPictures(folder) : [], openedPath);
    }
}
