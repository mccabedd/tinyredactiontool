using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Windows.Input;

namespace TinyRedaction.Desktop;

// Where a screenshot goes (0.12.0), set by the Output button: the editor, the clipboard or a file.
public enum CaptureOutput { Editor, Clipboard, File }
// What the Screen Recorder records (0.12.0).
public enum RecordingArea { Region, Window, FullScreen, FullScreenWithoutTaskbar }

// Settings window values (0.10.0). Stored next to the program like theme.preference; a missing or
// unreadable file gives the defaults. 0.12.0 adds the capture bar's choices.
public sealed class AppSettings
{
    public const string DefaultScreenshotShortcut = "Ctrl+PrintScreen", DefaultRecordingShortcut = "Ctrl+Shift+PrintScreen";
    public static readonly int[] Delays = [0, 1, 2, 3, 5, 10];
    public static readonly int[] FrameRates = [10, 15, 20, 25, 30];
    // 0 (0.24.0, David): no timer; the picture stays until a key moves on.
    public static readonly int[] SlideshowTimes = [0, 2, 3, 5, 8, 10, 15, 30, 60];
    // The editor's toolbar (0.24.0, David): every button in order, with "|" for a separator and ">" where the right
    // side starts (the bottom when the toolbar is vertical). Buttons in EditorHiddenButtons keep their place but
    // aren't shown. The names are the buttons' names in MainWindow.xaml.
    public const string ToolbarSeparator = "|", ToolbarRightSide = ">";
    // 0.27.0 (David's "TRT settings.json"): his order and hidden buttons are the defaults, with Add Image after Open.
    public static readonly string[] DefaultEditorToolbar =
    [
        "NewButton", "OpenButton", "AddImageButton", "OpenProjectButton", "PreviousPictureButton", "NextPictureButton", "ExportButton", "SaveProjectButton", "SaveMediaButton", "OriginalButton", "CopyButton", "PasteButton", "|",
        "UndoButton", "RedoButton", "DeleteButton", "|",
        "SelectToolButton", "RectangleTool", "OvalTool", "PolygonTool", "|",
        "TrimToolButton", "AppendToolButton", "|",
        "OpaqueTool", "BlurTool", "PixelateTool", "|",
        "TextTool", "DrawRectangleTool", "DrawOvalTool", "LineTool", "PolylineTool", "FreehandTool", "|",
        "CropTool", "ResizeButton", "RotateClockwiseButton", "RotateCounterClockwiseButton", "FlipHorizontalButton", "FlipVerticalButton", "|",
        "ZoomInButton", "ZoomOutButton", "FitButton", "FitWidthButton", "ActualSizeButton", "FullScreenButton", "PanTool", "SlideshowButton", "NavBarButton", "|",
        ">", "FileInfoButton", "|", "ToolClearRedactions", "ToolClearAnnotations", "ClearScreenButton", "|", "SettingsButton", "PanelButton",
    ];
    public static readonly string[] DefaultHiddenEditorButtons =
        ["OpenProjectButton", "PreviousPictureButton", "NextPictureButton", "SaveProjectButton", "SaveMediaButton", "OriginalButton", "DeleteButton",
         "FlipHorizontalButton", "FlipVerticalButton", "ZoomInButton", "ZoomOutButton", "FitWidthButton", "SlideshowButton", "NavBarButton", "SettingsButton"];
    public static IEnumerable<string> EditorButtonIds => DefaultEditorToolbar.Where(id => id is not (ToolbarSeparator or ToolbarRightSide));
    public List<string> EditorToolbar { get; set; } = [.. DefaultEditorToolbar];
    public List<string> EditorHiddenButtons { get; set; } = [.. DefaultHiddenEditorButtons];
    // Keys for the previous and next picture (0.24.0, David), in the editor and the slideshow; Left and Right work too.
    public const string DefaultPreviousKey = "PageUp", DefaultNextKey = "PageDown";
    public string PreviousPictureKey { get; set; } = DefaultPreviousKey;
    public string NextPictureKey { get; set; } = DefaultNextKey;
    // "Ctrl+Shift+N", "Right", "PageDown": a key with any modifiers; null when it isn't a key.
    public static (ModifierKeys Modifiers, Key Key)? ParseKey(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return null;
        var parts = text.Split('+', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        var modifiers = ModifierKeys.None;
        foreach (var part in parts[..^1])
        {
            if (part.Equals("Ctrl", StringComparison.OrdinalIgnoreCase)) modifiers |= ModifierKeys.Control;
            else if (part.Equals("Shift", StringComparison.OrdinalIgnoreCase)) modifiers |= ModifierKeys.Shift;
            else if (part.Equals("Alt", StringComparison.OrdinalIgnoreCase)) modifiers |= ModifierKeys.Alt;
            else return null;
        }
        if (!Enum.TryParse<Key>(parts[^1], true, out var key) || key is Key.None or Key.LeftCtrl or Key.RightCtrl or Key.LeftShift or Key.RightShift or Key.LeftAlt or Key.RightAlt or Key.System) return null;
        return (modifiers, key);
    }
    public static string KeyText(ModifierKeys modifiers, Key key) =>
        (modifiers.HasFlag(ModifierKeys.Control) ? "Ctrl+" : "") + (modifiers.HasFlag(ModifierKeys.Shift) ? "Shift+" : "") + (modifiers.HasFlag(ModifierKeys.Alt) ? "Alt+" : "") + key;
    public static bool Matches(string setting, ModifierKeys modifiers, Key key) => ParseKey(setting) is { } k && k.Key == key && k.Modifiers == modifiers;
    // The saved toolbar, put right: unknown names dropped, every button once (new ones in their default place), one ">".
    public static List<string> CleanToolbar(IEnumerable<string>? saved)
    {
        var known = EditorButtonIds.ToHashSet();
        var result = new List<string>(); var seen = new HashSet<string>();
        foreach (var id in saved ?? DefaultEditorToolbar)
        {
            if (id == ToolbarSeparator) { result.Add(id); continue; }
            if (id == ToolbarRightSide ? seen.Add(id) : known.Contains(id) && seen.Add(id)) result.Add(id);
        }
        if (!seen.Contains(ToolbarRightSide)) result.Add(ToolbarRightSide);
        // Buttons the saved list doesn't have (added in a later version) go after the one before them by default.
        foreach (var (id, index) in DefaultEditorToolbar.Select((id, i) => (id, i)))
        {
            if (!known.Contains(id) || seen.Contains(id)) continue;
            var before = DefaultEditorToolbar.Take(index).LastOrDefault(b => known.Contains(b) && result.Contains(b));
            result.Insert(before == null ? 0 : result.IndexOf(before) + 1, id); seen.Add(id);
        }
        return result;
    }
    // Slideshow (0.23.0): seconds per picture, and starting again after the last.
    public int SlideshowSeconds { get; set; } = 5;
    public bool SlideshowRepeat { get; set; } = true;
    // The navigation bar (0.25.0, David): the folder's pictures along the bottom of the editor or the
    // slideshow. Always pinned in the editor; in the slideshow it can be unpinned (it then hides like the capture bar).
    public static readonly int[] NavBarSizes = [48, 72, 96];
    public const int MinNavBarSize = 32, MaxNavBarSize = 256;
    public bool NavBarInEditor { get; set; }
    public bool NavBarInSlideshow { get; set; } = true;
    public bool NavBarPinnedInSlideshow { get; set; } = true;
    public int NavBarThumbnailSize { get; set; } = 72;
    public bool SmallIcons { get; set; }
    public bool VerticalToolbar { get; set; }
    public string ScreenshotShortcut { get; set; } = DefaultScreenshotShortcut;
    public string RecordingShortcut { get; set; } = DefaultRecordingShortcut;
    [JsonConverter(typeof(JsonStringEnumConverter))] public CaptureOutput Output { get; set; } = CaptureOutput.Editor;
    public bool CaptureMousePointer { get; set; }
    public int CaptureDelaySeconds { get; set; }
    public bool FullScreenAllMonitors { get; set; }
    [JsonConverter(typeof(JsonStringEnumConverter))] public RecordingArea RecordingArea { get; set; } = RecordingArea.Region;
    public int RecordingFramesPerSecond { get; set; } = 15;
    public bool RecordMousePointer { get; set; } = true;
    // 0.22.4 (David: dark mode was lost on import): the theme is kept in theme.preference, and travels only in an
    // exported settings file (Light, Dark or System).
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? Theme { get; set; }
    // 0.13.0: a yellow ring round the pointer while a mouse button is pressed, so clicks show in the video.
    public bool RecordMouseClicks { get; set; } = true;
    // The capture bar's ✕: false hides TRT in the notification area (the inherited default), true quits.
    public bool CloseButtonQuits { get; set; }
    // 3.0.0 (David): how the editor was last closed (MainWindow.PlacementText); none opens it maximised.
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] public string? EditorPlacement { get; set; }
    public double? BarLeft { get; set; }
    public double? BarTop { get; set; }
    // 0.14.0: which capture bar buttons show, in their order (the Menu button always shows, last), and
    // the width of the red tab the bar hides into at the top of the screen.
    public static readonly string[] BarButtonIds = ["ActiveWindow", "WindowObject", "Region", "Freehand", "FullScreen", "Scrolling", "Recorder", "Ruler", "Editor", "Output"];
    public const int MinStripWidth = 30, MaxStripWidth = 600, DefaultStripWidth = 60;
    // 0.27.0 (David's settings file): his order, without the Ruler (Settings › Capture bar shows it again).
    public static readonly string[] DefaultBarButtons = ["Region", "Freehand", "ActiveWindow", "WindowObject", "FullScreen", "Scrolling", "Recorder", "Editor", "Output"];
    public List<string> BarButtons { get; set; } = [.. DefaultBarButtons];
    public int StripWidth { get; set; } = DefaultStripWidth;
    public string? LastSaveFolder { get; set; }
    // 0.18.0 (David): the capture bar can be switched off (TRT then lives in the notification area), and
    // two more shortcuts show/hide the bar and open the editor. An empty shortcut means none.
    public const string DefaultBarShortcut = "Ctrl+Alt+B", DefaultEditorShortcut = "Ctrl+Alt+E";
    public bool ShowCaptureBar { get; set; } = true;
    public string BarShortcut { get; set; } = DefaultBarShortcut;
    public string EditorShortcut { get; set; } = DefaultEditorShortcut;
    // Where the red tab sits along the top edge: under the bar's left end, or at a set place (0-100 % across).
    public bool StripAtSetPlace { get; set; }
    public int StripPositionPercent { get; set; } = 50;
    // The editor's options bar (colour, width, font...) can be hidden: the floating style windows have the same choices.
    public bool HideOptionsBar { get; set; } = true; // 0.27.0: David's default.

    internal static string Path { get; set; } = System.IO.Path.Combine(ProgramFolder, "settings.json");
    // The folder people see the program in. A standalone .exe unpacks itself to a temporary folder
    // (AppContext.BaseDirectory), so its settings live beside the .exe instead (0.13.0).
    internal static string ProgramFolder =>
        string.IsNullOrEmpty(typeof(AppSettings).Assembly.Location) && System.IO.Path.GetDirectoryName(Environment.ProcessPath) is { } exe ? exe : AppContext.BaseDirectory;
    public static AppSettings Load()
    {
        try
        {
            if (!File.Exists(Path)) return new();
            return Parse(File.ReadAllText(Path));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException or NotSupportedException) { return new(); }
    }
    // Settings from JSON (settings.json, or a file imported in Settings, 0.22.0): anything out of range is put
    // back to its default. Throws JsonException when the text is not TRT settings at all.
    public static AppSettings Parse(string json)
    {
        {
            var loaded = JsonSerializer.Deserialize<AppSettings>(json) ?? throw new JsonException("The file holds no settings.");
            if (ParseShortcut(loaded.ScreenshotShortcut) == null) loaded.ScreenshotShortcut = DefaultScreenshotShortcut;
            if (ParseShortcut(loaded.RecordingShortcut) == null) loaded.RecordingShortcut = DefaultRecordingShortcut;
            if (!Delays.Contains(loaded.CaptureDelaySeconds)) loaded.CaptureDelaySeconds = 0;
            if (!FrameRates.Contains(loaded.RecordingFramesPerSecond)) loaded.RecordingFramesPerSecond = 15;
            if (!SlideshowTimes.Contains(loaded.SlideshowSeconds)) loaded.SlideshowSeconds = 5;
            // 0.26.0: any height the bar was dragged to, within NavigationBar's limits.
            if (loaded.NavBarThumbnailSize is < MinNavBarSize or > MaxNavBarSize) loaded.NavBarThumbnailSize = 72;
            loaded.EditorToolbar = CleanToolbar(loaded.EditorToolbar);
            loaded.EditorHiddenButtons = (loaded.EditorHiddenButtons ?? [.. DefaultHiddenEditorButtons]).Where(EditorButtonIds.Contains).Distinct().ToList();
            if (ParseKey(loaded.PreviousPictureKey) == null) loaded.PreviousPictureKey = DefaultPreviousKey;
            if (ParseKey(loaded.NextPictureKey) == null) loaded.NextPictureKey = DefaultNextKey;
            if (!Enum.IsDefined(loaded.Output)) loaded.Output = CaptureOutput.Editor;
            if (!Enum.IsDefined(loaded.RecordingArea)) loaded.RecordingArea = RecordingArea.Region;
            loaded.BarButtons = (loaded.BarButtons ?? [.. DefaultBarButtons]).Where(BarButtonIds.Contains).Distinct().ToList();
            loaded.StripWidth = Math.Clamp(loaded.StripWidth, MinStripWidth, MaxStripWidth);
            loaded.StripPositionPercent = Math.Clamp(loaded.StripPositionPercent, 0, 100);
            if (loaded.BarShortcut is not "" && ParseShortcut(loaded.BarShortcut) == null) loaded.BarShortcut = DefaultBarShortcut;
            if (loaded.EditorShortcut is not "" && ParseShortcut(loaded.EditorShortcut) == null) loaded.EditorShortcut = DefaultEditorShortcut;
            return loaded;
        }
    }
    public string ToJson() => JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
    public bool Save()
    {
        try { File.WriteAllText(Path, ToJson()); return true; }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { return false; }
    }
    public AppSettings Copy() { var copy = (AppSettings)MemberwiseClone(); copy.BarButtons = [.. BarButtons]; copy.EditorToolbar = [.. EditorToolbar]; copy.EditorHiddenButtons = [.. EditorHiddenButtons]; return copy; }

    // "Ctrl+Shift+PrintScreen" <-> modifiers and key. A shortcut needs Ctrl or Alt, except
    // Print Screen and F1-F24 on their own; Windows-key combinations are reserved by Windows.
    public static (ModifierKeys Modifiers, Key Key)? ParseShortcut(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return null;
        var modifiers = ModifierKeys.None; Key? key = null;
        foreach (var part in text.Split('+', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries))
        {
            switch (part.ToLowerInvariant())
            {
                case "ctrl": modifiers |= ModifierKeys.Control; break;
                case "shift": modifiers |= ModifierKeys.Shift; break;
                case "alt": modifiers |= ModifierKeys.Alt; break;
                default:
                    if (key != null || !Enum.TryParse<Key>(part == "PrintScreen" ? "Snapshot" : part, out var k)) return null;
                    key = k; break;
            }
        }
        return key is { } found && IsAllowed(modifiers, found) ? (modifiers, found) : null;
    }
    public static bool IsAllowed(ModifierKeys modifiers, Key key)
    {
        if (key is Key.None or Key.LeftCtrl or Key.RightCtrl or Key.LeftShift or Key.RightShift or Key.LeftAlt or Key.RightAlt or Key.LWin or Key.RWin or Key.System) return false;
        if (modifiers.HasFlag(ModifierKeys.Windows)) return false;
        return key == Key.Snapshot || key is >= Key.F1 and <= Key.F24 || modifiers.HasFlag(ModifierKeys.Control) || modifiers.HasFlag(ModifierKeys.Alt);
    }
    public static string FormatShortcut(ModifierKeys modifiers, Key key) =>
        string.Join("+", new[] { modifiers.HasFlag(ModifierKeys.Control) ? "Ctrl" : null, modifiers.HasFlag(ModifierKeys.Shift) ? "Shift" : null, modifiers.HasFlag(ModifierKeys.Alt) ? "Alt" : null, key == Key.Snapshot ? "PrintScreen" : key.ToString() }.Where(p => p != null));
    // How a shortcut reads to people: "Ctrl+Shift+Print Screen".
    public static string DisplayShortcut(string shortcut) => shortcut.Replace("PrintScreen", "Print Screen");
}
