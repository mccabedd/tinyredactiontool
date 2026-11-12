using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace TinyRedaction.Desktop;

public partial class SettingsWindow : Window
{
    // The four shortcuts by what they do (0.18.0 adds the capture bar and editor ones; those may be empty = none).
    private readonly Dictionary<string, string> shortcuts = [];
    private static readonly string[] ShortcutOrder = ["Screenshot", "Recording", "Bar", "Editor"];
    private static string ShortcutName(string what) => what switch { "Screenshot" => "the screenshot", "Recording" => "recording", "Bar" => "showing or hiding the capture bar", _ => "opening the editor" };
    public AppSettings Result { get; private set; }
    // Not settings.json values: the right-click menu entry (0.13.0) and the Windows startup entry (0.18.0)
    // themselves are the settings; the theme lives in theme.preference.
    public bool ExplorerMenuChosen { get; private set; }
    public bool StartupChosen { get; private set; }
    public bool DefaultPictureAppChosen { get; private set; } // 0.25.0: TRT registered as the default app for pictures.
    public string ThemeChosen { get; private set; } = "Light";
    public SettingsWindow(AppSettings current)
    {
        InitializeComponent();
        // 0.24.1 (David: settings cut off out of reach): a tab taller than the window scrolls instead (the Toolbar tab's
        // list scrolls itself).
        foreach (var tab in Tabs.Items.OfType<TabItem>())
            if (tab.Content is StackPanel page) { tab.Content = null; tab.Content = new ScrollViewer { Content = page, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled, Padding = new Thickness(0, 0, 4, 0) }; }
        Result = current.Copy();
        StartupBox.IsChecked = StartupChosen = StartupEntry.IsInstalled;
        ThemeChosen = MainWindow.SavedTheme();
        (ThemeChosen == "Dark" ? ThemeDarkBox : ThemeChosen == "System" ? ThemeSystemBox : ThemeLightBox).IsChecked = true;
        ExplorerMenuBox.IsChecked = ExplorerMenuChosen = ExplorerMenu.IsInstalled;
        DefaultPictureAppBox.IsChecked = DefaultPictureAppChosen = PictureApp.IsRegistered;
        StripWidthSlider.ValueChanged += (_, _) => ShowStripPreview(); StripPositionSlider.ValueChanged += (_, _) => ShowStripPreview();
        StripUnderBarBox.Checked += (_, _) => ShowStripPreview(); StripSetPlaceBox.Checked += (_, _) => ShowStripPreview();
        DelayChoice.ItemsSource = AppSettings.Delays; FrameRateChoice.ItemsSource = AppSettings.FrameRates; SlideshowTimeChoice.ItemsSource = AppSettings.SlideshowTimes;
        ShowValues(current);
    }
    // Fills the window from settings: on opening, and after Import settings (0.22.0).
    private void ShowValues(AppSettings current)
    {
        SmallIconsBox.IsChecked = current.SmallIcons;
        (current.VerticalToolbar ? VerticalBox : HorizontalBox).IsChecked = true;
        shortcuts["Screenshot"] = current.ScreenshotShortcut; shortcuts["Recording"] = current.RecordingShortcut;
        shortcuts["Bar"] = current.BarShortcut; shortcuts["Editor"] = current.EditorShortcut;
        ShowShortcuts();
        ShowBarBox.IsChecked = current.ShowCaptureBar;
        (current.StripAtSetPlace ? StripSetPlaceBox : StripUnderBarBox).IsChecked = true;
        StripPositionSlider.Value = current.StripPositionPercent;
        HideOptionsBarBox.IsChecked = current.HideOptionsBar;
        DelayChoice.SelectedItem = current.CaptureDelaySeconds;
        CapturePointerBox.IsChecked = current.CaptureMousePointer;
        FullScreenChoice.SelectedIndex = current.FullScreenAllMonitors ? 1 : 0;
        FrameRateChoice.SelectedItem = current.RecordingFramesPerSecond;
        SlideshowTimeChoice.SelectedItem = current.SlideshowSeconds; SlideshowRepeatBox.IsChecked = current.SlideshowRepeat;
        NavBarEditorBox.IsChecked = current.NavBarInEditor; NavBarSlideshowBox.IsChecked = current.NavBarInSlideshow; NavBarPinnedBox.IsChecked = current.NavBarPinnedInSlideshow;
        // 0.28.0 (David): the height in pixels (a dragged height shows here as it is).
        NavBarHeightBox.Value = current.NavBarThumbnailSize;
        RecordPointerBox.IsChecked = current.RecordMousePointer;
        (current.CloseButtonQuits ? CloseQuitsBox : CloseHidesBox).IsChecked = true;
        ShowBarButtons(current.BarButtons);
        ShowToolbar(current.EditorToolbar, current.EditorHiddenButtons);
        previousKey = current.PreviousPictureKey; nextKey = current.NextPictureKey; ShowPictureKeys();
        StripWidthSlider.Value = current.StripWidth;
        UpdateMoveButtons(); ShowStripPreview();
    }
    // The little screen-edge picture: where the tab will be (under the bar = about a third of the way across).
    private void ShowStripPreview()
    {
        if (StripPreview == null || StripPositionSlider == null) return;
        var screen = StripPreviewScreen.Width - 2; var width = Math.Max(4, StripWidthSlider.Value / 1920 * screen);
        StripPreview.Width = width;
        var percent = StripSetPlaceBox.IsChecked == true ? StripPositionSlider.Value : 33;
        Canvas.SetLeft(StripPreview, (screen - width) * percent / 100);
    }

    // ---- Capture bar buttons (0.14.0): shown ones first in their order, then the hidden ones. ----
    internal static string BarButtonLabel(string id) => id switch
    {
        "ActiveWindow" => "Capture Active Window",
        "WindowObject" => "Capture Window or Object",
        "Region" => "Capture Rectangular Region",
        "Freehand" => "Capture Freehand Region",
        "FullScreen" => "Capture Full Screen",
        "Scrolling" => "Capture Scrolling Window",
        "Recorder" => "Screen Recorder",
        "Ruler" => "Screen Ruler",
        "Editor" => "Open the Editor",
        "Output" => "Output (Where Screenshots Go)",
        _ => id,
    };
    private void ShowBarButtons(IReadOnlyList<string> shown)
    {
        BarButtonList.Items.Clear();
        foreach (var id in shown.Concat(AppSettings.BarButtonIds.Except(shown)))
            BarButtonList.Items.Add(new CheckBox { Content = BarButtonLabel(id), Tag = id, IsChecked = shown.Contains(id), Margin = new Thickness(2) });
    }
    internal IEnumerable<CheckBox> BarButtonChoices => BarButtonList.Items.Cast<CheckBox>();
    private void BarButtonSelected(object sender, SelectionChangedEventArgs e) => UpdateMoveButtons();
    private void UpdateMoveButtons()
    {
        var index = BarButtonList.SelectedIndex;
        BarButtonUp.IsEnabled = index > 0;
        BarButtonDown.IsEnabled = index >= 0 && index < BarButtonList.Items.Count - 1;
    }
    internal void MoveBarButton(object sender, RoutedEventArgs e)
    {
        var index = BarButtonList.SelectedIndex; var to = index + int.Parse((string)((Button)sender).Tag);
        if (index < 0 || to < 0 || to >= BarButtonList.Items.Count) return;
        var item = BarButtonList.Items[index];
        BarButtonList.Items.RemoveAt(index); BarButtonList.Items.Insert(to, item);
        BarButtonList.SelectedIndex = to; BarButtonList.ScrollIntoView(item);
    }
    private void ResetBarButtons(object sender, RoutedEventArgs e) { ShowBarButtons(AppSettings.BarButtonIds); UpdateMoveButtons(); }

    // ---- Keys for the previous and next picture (0.24.0, David): any key, with or without Ctrl, Shift or Alt ----
    private string previousKey = AppSettings.DefaultPreviousKey, nextKey = AppSettings.DefaultNextKey;
    private void ShowPictureKeys() { PreviousKeyBox.Text = previousKey; NextKeyBox.Text = nextKey; }
    private void PictureKeyDown(object sender, KeyEventArgs e)
    {
        var key = e.Key == Key.System ? e.SystemKey : e.Key;
        if (key is Key.Tab or Key.Escape) return; // These keep their usual jobs.
        e.Handled = true;
        if (key is Key.LeftCtrl or Key.RightCtrl or Key.LeftShift or Key.RightShift or Key.LeftAlt or Key.RightAlt or Key.LWin or Key.RWin) return;
        SetPictureKey(sender == PreviousKeyBox, AppSettings.KeyText(Keyboard.Modifiers, key));
    }
    internal void SetPictureKey(bool previous, string text)
    {
        if (AppSettings.ParseKey(text) == null) return;
        if (previous) previousKey = text; else nextKey = text;
        ShowPictureKeys();
    }
    internal static string ToolbarLabel(string id) => id switch
    {
        "OpenButton" => "Open", "AddImageButton" => "Add Image", "OpenProjectButton" => "Open Project", "PreviousPictureButton" => "Previous Image", "NextPictureButton" => "Next Image",
        "ExportButton" => "Export", "SaveProjectButton" => "Save Project", "SaveMediaButton" => "Save Media", "OriginalButton" => "Original (Captures Only)",
        "CopyButton" => "Copy", "PasteButton" => "Paste", "UndoButton" => "Undo", "RedoButton" => "Redo", "DeleteButton" => "Delete the Selected Shape",
        "SelectToolButton" => "Select", "RectangleTool" => "Rectangle", "OvalTool" => "Oval", "PolygonTool" => "Polygon", "PanTool" => "Pan", "CropTool" => "Crop", "ResizeButton" => "Resize",
        "RotateClockwiseButton" => "Rotate Right (Clockwise)", "RotateCounterClockwiseButton" => "Rotate Left (Anti-Clockwise)",
        "FlipHorizontalButton" => "Flip Canvas Horizontally", "FlipVerticalButton" => "Flip Canvas Vertically",
        "TrimToolButton" => "Trim (Videos Only)", "AppendToolButton" => "Append (Videos Only)",
        "OpaqueTool" => "Box", "BlurTool" => "Blur", "PixelateTool" => "Pixelate",
        "TextTool" => "Text", "DrawRectangleTool" => "Outline", "DrawOvalTool" => "Ellipse", "LineTool" => "Line", "PolylineTool" => "Polyline", "FreehandTool" => "Pen",
        "ZoomInButton" => "Zoom In", "ZoomOutButton" => "Zoom Out", "FitButton" => "Fit", "FitWidthButton" => "Fit Width", "ActualSizeButton" => "Actual Size",
        "FullScreenButton" => "Full Screen", "SlideshowButton" => "Slideshow", "NavBarButton" => "Nav Bar", "NewButton" => "New", "FileInfoButton" => "File Info",
        "ToolClearRedactions" => "Clear Redactions", "ToolClearAnnotations" => "Clear Annotations", "ClearScreenButton" => "Clear Editor",
        "SettingsButton" => "Settings", "PanelButton" => "Panel",
        _ => id,
    };
    private const string SeparatorLabel = "──────  Separator  ──────", RightSideLabel = "▶  Right Side Starts Here", SpacerLabel = "(Spacer)";
    private static ListBoxItem SpacerItem() => new() { Content = SpacerLabel, Tag = AppSettings.ToolbarSpacer, Opacity = 0.75, FontStyle = FontStyles.Italic, Padding = new Thickness(6, 1, 2, 1) };
    private void ShowToolbar(IEnumerable<string> layout, ICollection<string> hidden)
    {
        ToolbarList.Items.Clear();
        foreach (var id in AppSettings.CleanToolbar(layout))
            ToolbarList.Items.Add(id switch
            {
                AppSettings.ToolbarSeparator => new ListBoxItem { Content = SeparatorLabel, Tag = id, Opacity = 0.75, Padding = new Thickness(6, 1, 2, 1) },
                AppSettings.ToolbarSpacer => SpacerItem(),
                AppSettings.ToolbarRightSide => new ListBoxItem { Content = RightSideLabel, Tag = id, FontWeight = FontWeights.SemiBold, Padding = new Thickness(4, 3, 2, 3) },
                _ => new CheckBox { Content = ToolbarLabel(id), Tag = id, IsChecked = !hidden.Contains(id), Margin = new Thickness(2) },
            });
        UpdateToolbarButtons();
    }
    internal IEnumerable<FrameworkElement> ToolbarChoices => ToolbarList.Items.Cast<FrameworkElement>();
    private void ToolbarSelected(object sender, SelectionChangedEventArgs e) => UpdateToolbarButtons();
    private void UpdateToolbarButtons()
    {
        var index = ToolbarList.SelectedIndex;
        ToolbarUp.IsEnabled = index > 0; ToolbarDown.IsEnabled = index >= 0 && index < ToolbarList.Items.Count - 1;
        ToolbarRemoveSeparator.IsEnabled = index >= 0 && (string?)((FrameworkElement)ToolbarList.Items[index]).Tag is AppSettings.ToolbarSeparator or AppSettings.ToolbarSpacer;
    }
    internal void MoveToolbarItem(object sender, RoutedEventArgs e) => MoveToolbarItem(int.Parse((string)((Button)sender).Tag));
    internal void MoveToolbarItem(int step)
    {
        var index = ToolbarList.SelectedIndex; var to = index + step;
        if (index < 0 || to < 0 || to >= ToolbarList.Items.Count) return;
        var item = ToolbarList.Items[index];
        ToolbarList.Items.RemoveAt(index); ToolbarList.Items.Insert(to, item);
        ToolbarList.SelectedIndex = to; ToolbarList.ScrollIntoView(item);
    }
    internal void AddToolbarSeparator(object sender, RoutedEventArgs e)
    {
        var at = ToolbarList.SelectedIndex < 0 ? ToolbarList.Items.Count : ToolbarList.SelectedIndex + 1;
        var item = new ListBoxItem { Content = SeparatorLabel, Tag = AppSettings.ToolbarSeparator, Opacity = 0.75, Padding = new Thickness(6, 1, 2, 1) };
        ToolbarList.Items.Insert(at, item); ToolbarList.SelectedIndex = at; ToolbarList.ScrollIntoView(item);
    }
    // 3.1.3 (David): a blank space the size of a button.
    internal void AddToolbarSpacer(object sender, RoutedEventArgs e)
    {
        var at = ToolbarList.SelectedIndex < 0 ? ToolbarList.Items.Count : ToolbarList.SelectedIndex + 1;
        var item = SpacerItem();
        ToolbarList.Items.Insert(at, item); ToolbarList.SelectedIndex = at; ToolbarList.ScrollIntoView(item);
    }
    internal void RemoveToolbarSeparator(object sender, RoutedEventArgs e)
    {
        var index = ToolbarList.SelectedIndex;
        if (index >= 0 && (string?)((FrameworkElement)ToolbarList.Items[index]).Tag is AppSettings.ToolbarSeparator or AppSettings.ToolbarSpacer) ToolbarList.Items.RemoveAt(index);
        UpdateToolbarButtons();
    }
    private void ResetToolbar(object sender, RoutedEventArgs e) => ShowToolbar(AppSettings.DefaultEditorToolbar, AppSettings.DefaultHiddenEditorButtons);
    private (List<string> Layout, List<string> Hidden) ToolbarChosen()
    {
        var items = ToolbarList.Items.Cast<FrameworkElement>().ToList();
        return (items.Select(i => (string)i.Tag).ToList(), items.OfType<CheckBox>().Where(c => c.IsChecked != true).Select(c => (string)c.Tag).ToList());
    }
    private TextBox BoxFor(string what) => what switch { "Screenshot" => ScreenshotBox, "Recording" => RecordingBox, "Bar" => BarShortcutBox, _ => EditorShortcutBox };
    private string WhatFor(TextBox box) => ShortcutOrder.First(w => BoxFor(w) == box);
    private void ShowShortcuts()
    {
        foreach (var what in ShortcutOrder) BoxFor(what).Text = shortcuts[what].Length == 0 ? "None" : AppSettings.DisplayShortcut(shortcuts[what]);
    }
    private void ClearShortcut(object sender, RoutedEventArgs e) { shortcuts[(string)((Button)sender).Tag] = ""; ShortcutMessage.Text = ""; ShowShortcuts(); }
    // Tab and Esc keep their usual jobs (move on, cancel); every other key press is a shortcut attempt.
    private void ShortcutKeyDown(object sender, KeyEventArgs e)
    {
        var key = e.Key == Key.System ? e.SystemKey : e.Key;
        if (key is Key.Tab or Key.Escape) return;
        e.Handled = true;
        // Windows sends Print Screen only as a key release, so it is taken in ShortcutKeyUp.
        if (key != Key.Snapshot) TryShortcut((TextBox)sender, Keyboard.Modifiers, key);
    }
    private void ShortcutKeyUp(object sender, KeyEventArgs e)
    {
        var key = e.Key == Key.System ? e.SystemKey : e.Key;
        if (key != Key.Snapshot) return;
        e.Handled = true; TryShortcut((TextBox)sender, Keyboard.Modifiers, key);
    }
    internal bool TryShortcut(TextBox box, ModifierKeys modifiers, Key key)
    {
        if (key is Key.LeftCtrl or Key.RightCtrl or Key.LeftShift or Key.RightShift or Key.LeftAlt or Key.RightAlt) return false;
        if (!AppSettings.IsAllowed(modifiers, key))
        {
            ShortcutMessage.Text = "Use Ctrl or Alt with the key (Print Screen and F1–F24 also work on their own).";
            return false;
        }
        var text = AppSettings.FormatShortcut(modifiers, key);
        var what = WhatFor(box);
        var clash = ShortcutOrder.FirstOrDefault(w => w != what && string.Equals(shortcuts[w], text, StringComparison.OrdinalIgnoreCase));
        if (clash != null)
        {
            ShortcutMessage.Text = $"{AppSettings.DisplayShortcut(text)} is already used for {ShortcutName(clash)}.";
            return false;
        }
        shortcuts[what] = text;
        ShortcutMessage.Text = ""; ShowShortcuts(); return true;
    }
    private void ResetShortcuts(object sender, RoutedEventArgs e)
    {
        shortcuts["Screenshot"] = AppSettings.DefaultScreenshotShortcut; shortcuts["Recording"] = AppSettings.DefaultRecordingShortcut;
        shortcuts["Bar"] = AppSettings.DefaultBarShortcut; shortcuts["Editor"] = AppSettings.DefaultEditorShortcut;
        ShortcutMessage.Text = ""; ShowShortcuts();
        previousKey = AppSettings.DefaultPreviousKey; nextKey = AppSettings.DefaultNextKey; ShowPictureKeys();
    }
    internal AppSettings Collect()
    {
        Result.SmallIcons = SmallIconsBox.IsChecked == true;
        Result.VerticalToolbar = VerticalBox.IsChecked == true;
        Result.ScreenshotShortcut = shortcuts["Screenshot"]; Result.RecordingShortcut = shortcuts["Recording"];
        Result.BarShortcut = shortcuts["Bar"]; Result.EditorShortcut = shortcuts["Editor"];
        Result.ShowCaptureBar = ShowBarBox.IsChecked == true;
        Result.StripAtSetPlace = StripSetPlaceBox.IsChecked == true; Result.StripPositionPercent = (int)Math.Round(StripPositionSlider.Value);
        Result.HideOptionsBar = HideOptionsBarBox.IsChecked == true;
        StartupChosen = StartupBox.IsChecked == true;
        ThemeChosen = ThemeShown;
        Result.CaptureDelaySeconds = DelayChoice.SelectedItem is int delay ? delay : 0;
        Result.CaptureMousePointer = CapturePointerBox.IsChecked == true;
        Result.FullScreenAllMonitors = FullScreenChoice.SelectedIndex == 1;
        Result.RecordingFramesPerSecond = FrameRateChoice.SelectedItem is int fps ? fps : 15;
        (Result.EditorToolbar, Result.EditorHiddenButtons) = ToolbarChosen();
        Result.PreviousPictureKey = previousKey; Result.NextPictureKey = nextKey;
        Result.SlideshowSeconds = SlideshowTimeChoice.SelectedItem is int seconds ? seconds : 5; Result.SlideshowRepeat = SlideshowRepeatBox.IsChecked == true;
        Result.RecordMousePointer = RecordPointerBox.IsChecked == true;
        Result.CloseButtonQuits = CloseQuitsBox.IsChecked == true;
        ExplorerMenuChosen = ExplorerMenuBox.IsChecked == true;
        DefaultPictureAppChosen = DefaultPictureAppBox.IsChecked == true;
        Result.NavBarInEditor = NavBarEditorBox.IsChecked == true; Result.NavBarInSlideshow = NavBarSlideshowBox.IsChecked == true;
        Result.NavBarPinnedInSlideshow = NavBarPinnedBox.IsChecked == true;
        Result.NavBarThumbnailSize = (int)Math.Clamp(Math.Round(NavBarHeightBox.Value), AppSettings.MinNavBarSize, AppSettings.MaxNavBarSize);
        Result.BarButtons = BarButtonChoices.Where(c => c.IsChecked == true).Select(c => (string)c.Tag).ToList();
        Result.StripWidth = (int)Math.Round(StripWidthSlider.Value);
        return Result;
    }
    private void Accept(object sender, RoutedEventArgs e) { Collect(); DialogResult = true; }

    // ---- Export / import (0.22.0, David): the settings as a .json file. The Windows startup entry, the
    // right-click menu and the theme are not in it (they belong to this PC's Windows user). ----
    internal Func<bool, string?>? ChooseSettingsFile { get; set; } // Checks answer without the file dialogs (true = export).
    internal string? SettingsFileMessage { get; private set; }
    private string? AskSettingsFile(bool export)
    {
        if (ChooseSettingsFile != null) return ChooseSettingsFile(export);
        Microsoft.Win32.FileDialog dialog = export
            ? new Microsoft.Win32.SaveFileDialog { FileName = "TRT settings.json", AddExtension = true, DefaultExt = ".json" }
            : new Microsoft.Win32.OpenFileDialog();
        dialog.Filter = "TRT Settings|*.json"; dialog.AddToRecent = false; dialog.Title = export ? "Export Settings" : "Import Settings";
        return dialog.ShowDialog(this) == true ? dialog.FileName : null;
    }
    private void ExportSettings(object sender, RoutedEventArgs e) => ExportSettingsTo(AskSettingsFile(true));
    internal bool ExportSettingsTo(string? path)
    {
        if (path == null) return false;
        try { var exported = Collect().Copy(); exported.Theme = ThemeShown; exported.EditorPlacement = null; System.IO.File.WriteAllText(path, exported.ToJson()); SettingsFileMessage = $"Settings exported to {System.IO.Path.GetFileName(path)}."; }
        catch (Exception ex) when (ex is System.IO.IOException or UnauthorizedAccessException) { SettingsFileMessage = "Couldn't save the settings there: " + ex.Message; Report(); return false; }
        Report(); return true;
    }
    private string ThemeShown => ThemeDarkBox.IsChecked == true ? "Dark" : ThemeSystemBox.IsChecked == true ? "System" : "Light";
    private void ImportSettings(object sender, RoutedEventArgs e) => ImportSettingsFrom(AskSettingsFile(false));
    internal bool ImportSettingsFrom(string? path)
    {
        if (path == null) return false;
        try
        {
            var text = System.IO.File.ReadAllText(path);
            if (text.Length > 1_000_000) throw new System.Text.Json.JsonException("too large");
            var imported = AppSettings.Parse(text);
            imported.LastSaveFolder = Result.LastSaveFolder; // A folder on another PC means nothing here.
            imported.EditorPlacement = Result.EditorPlacement; // Nor does another PC's window place (3.0.0).
            if (imported.Theme is "Dark" or "System" or "Light") (imported.Theme == "Dark" ? ThemeDarkBox : imported.Theme == "System" ? ThemeSystemBox : ThemeLightBox).IsChecked = true;
            imported.Theme = null; // Kept in theme.preference once OK is pressed, not in the settings.
            Result = imported.Copy(); ShowValues(imported);
            SettingsFileMessage = $"Settings imported from {System.IO.Path.GetFileName(path)}. Press OK to use them.";
        }
        catch (Exception ex) when (ex is System.IO.IOException or UnauthorizedAccessException or System.Text.Json.JsonException or NotSupportedException)
        { SettingsFileMessage = "That isn't a TRT settings file. Nothing was changed."; Report(); return false; }
        Report(); return true;
    }
    private void Report() { if (ChooseSettingsFile == null) ThemedMessage.Show(this, SettingsFileMessage ?? "", "Settings File"); }
}
