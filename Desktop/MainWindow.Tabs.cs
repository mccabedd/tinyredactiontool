using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Tabs (3.5.0, David): every screenshot, recording and opened file gets its own tab in the editor, so a part of one
// can be copied (Select an area, Copy) and pasted into another. Each tab is a whole editor of its own (its picture or
// video, Undo, zoom and side panel); the capture side keeps the list and shows one tab at a time in the same place
// (CaptureController.Tabs.cs). This file is one tab's part: its name, the tab bar and closing it.
public partial class MainWindow
{
    private bool closingOneTab;      // Closed as a tab (its own ✕, Close All Tabs): the other tabs stay.
    private bool skipCloseQuestion;  // The unsaved question was already asked (and answered Yes).

    // What the tab says: the file's name, or what the work is (a screenshot and the time it was taken).
    internal string TabTitle
    {
        get
        {
            if (Project.Media is not { } media) return "New Tab";
            if (saveTarget != null) return Path.GetFileName(saveTarget);
            if (projectPath != null) return Path.GetFileName(projectPath);
            if (openedPath != null) return Path.GetFileName(openedPath);
            var at = origin.Time.ToString("HH:mm:ss");
            return origin.Kind switch
            {
                MediaOriginKind.Screenshot => "Screenshot " + at,
                MediaOriginKind.Recording => "Recording " + at,
                MediaOriginKind.Frame => "Frame " + at,
                MediaOriginKind.Pasted => "Pasted Image " + at,
                MediaOriginKind.NewImage => "New Image " + at,
                _ => Path.GetFileName(media.Path),
            };
        }
    }
    private string TabTip => saveTarget ?? projectPath ?? openedPath ?? TabTitle;
    // Unsaved: a screenshot or recording not saved yet, or changes since it was opened or saved.
    internal bool HasUnsavedWork => Project.Media != null && (UnsavedCapture || savedSnapshot != ProjectStore.Serialize(Project));
    // Something Save All Tabs should save: unsaved captures, and changes since the file was opened or last saved.
    internal bool NeedsSave => Project.Media != null && (UnsavedCapture || savedRender != ProjectStore.Serialize(Project));
    internal bool IsEmptyTab => Project.Media == null;

    // Closes this tab only; the question was asked (or not needed). False when it is still open (busy).
    internal bool CloseAsTab()
    {
        closingOneTab = true; skipCloseQuestion = true;
        Close();
        if (!closing) { closingOneTab = skipCloseQuestion = false; return false; } // Kept open (still working).
        return true;
    }
    // Close All Tabs keeps the editor open with one empty tab: the last tab is emptied instead of closed.
    internal void ResetTab()
    {
        ClearWorkspace(); openedPath = null; newPicture = false; lastSavedCopy = null; origin = new(MediaOriginKind.Imported, DateTime.Now);
        UpdateCaptureUi(); Refresh(); UpdateEditingState(); UpdateTitle();
        Status.Text = "All tabs closed.";
    }

    // ---- The tab bar (the same in every tab; only the shown tab's is seen) ----
    internal void ShowTabs(IReadOnlyList<MainWindow> tabs, MainWindow? active)
    {
        if (TabBar == null) return;
        if (captures == null) { TabBar.Visibility = Visibility.Collapsed; return; }
        TabBar.Visibility = IsFullScreen ? Visibility.Collapsed : Visibility.Visible;
        TabHeaders.Children.Clear();
        foreach (var tab in tabs) TabHeaders.Children.Add(TabHeader(tab, tab == active));
        var add = new Button { Content = "+", ToolTip = "New Tab (Ctrl+T)", Focusable = false, Padding = new Thickness(9, 0, 9, 1), Margin = new Thickness(2, 0, 0, 2), FontSize = 15, VerticalAlignment = VerticalAlignment.Bottom, Background = Brushes.Transparent, BorderThickness = new Thickness(0) };
        add.Click += (_, _) => captures?.NewEmptyTab(this);
        TabHeaders.Children.Add(add);
    }
    private FrameworkElement TabHeader(MainWindow tab, bool active)
    {
        var name = new TextBlock { Text = tab.TabTitle, MaxWidth = 220, TextTrimming = TextTrimming.CharacterEllipsis, VerticalAlignment = VerticalAlignment.Center, FontWeight = active ? FontWeights.SemiBold : FontWeights.Normal };
        var close = new Button { Content = "✕", ToolTip = "Close Tab (Ctrl+W)", Focusable = false, FontSize = 10, Padding = new Thickness(5, 1, 5, 1), Margin = new Thickness(6, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center, Background = Brushes.Transparent, BorderThickness = new Thickness(0) };
        close.Click += (_, e) => { e.Handled = true; captures?.CloseTab(tab); };
        var row = new StackPanel { Orientation = Orientation.Horizontal };
        row.Children.Add(name); row.Children.Add(close);
        var header = new Border { Child = row, Padding = new Thickness(10, 3, 3, 3), Margin = new Thickness(0, 0, 2, 0), BorderThickness = new Thickness(1, 1, 1, 0), CornerRadius = new CornerRadius(4, 4, 0, 0), ToolTip = tab.TabTip, Tag = tab, Cursor = Cursors.Hand };
        header.SetResourceReference(Border.BorderBrushProperty, "ChromeLine");
        if (active) header.SetResourceReference(Border.BackgroundProperty, "Background");
        else { header.Background = Brushes.Transparent; name.Opacity = 0.8; }
        header.MouseLeftButtonUp += (_, _) => captures?.SelectTab(tab);
        header.MouseUp += (_, e) => { if (e.ChangedButton == MouseButton.Middle) captures?.CloseTab(tab); }; // As in web browsers.
        return header;
    }
    // Ctrl+T new tab, Ctrl+W close this tab, Ctrl+Tab / Ctrl+Shift+Tab (and Ctrl+PageDown / PageUp) next and previous.
    private bool TabKey(KeyEventArgs e)
    {
        if (captures == null || Keyboard.Modifiers is not (ModifierKeys.Control or (ModifierKeys.Control | ModifierKeys.Shift))) return false;
        var shift = Keyboard.Modifiers.HasFlag(ModifierKeys.Shift);
        switch (e.Key)
        {
            case Key.T when !shift: captures.NewEmptyTab(this); return true;
            case Key.W when !shift: captures.CloseTab(this); return true;
            case Key.Tab: captures.StepTab(this, shift ? -1 : 1); return true;
            case Key.PageDown when !shift: captures.StepTab(this, 1); return true;
            case Key.PageUp when !shift: captures.StepTab(this, -1); return true;
            default: return false;
        }
    }
    internal void Notice(string text) => Status.Text = text;
    private async void SaveAllTabs(object sender, RoutedEventArgs e) { if (captures != null) await captures.SaveAllTabsAsync(); }
    private void CloseAllTabs(object sender, RoutedEventArgs e) => captures?.CloseAllTabs(keepEditorOpen: true);

    // Opens a file from the File menu, File Explorer or a drop: in its own tab when this one already shows something.
    internal async Task<bool> OpenFileInTabAsync(string path) =>
        UsesTabs ? await captures!.OpenInNewTabAsync(this, tab => tab.OpenPathAsync(path)) : await OpenPathAsync(path);
    // Something new opens in a tab of its own (not in place of what this tab shows).
    private bool UsesTabs => captures is { ReplaceInShownTab: false } && !IsEmptyTab;
}
