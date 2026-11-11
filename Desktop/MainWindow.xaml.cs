using System.Globalization;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;
public partial class MainWindow : Window
{
    private readonly ManagedPolicy policy;
    private readonly EditHistory history = new();
    private readonly MediaTools tools;
    private readonly ThumbnailService thumbnails;
    private readonly DispatcherTimer clock = new() { Interval = TimeSpan.FromMilliseconds(33) };
    private CancellationTokenSource? work;
    private CancellationTokenSource? seekWork;
    private FileStream? sourceLock;
    private bool playing, updating, busy, closing;
    private bool initializing = true;
    private bool hoverInside;
    private long hoverRequest;
    private double hoverX;
    private string? projectPath;
    private StillFormat lastStillFormat = StillFormat.Png;
    private string? savedSnapshot;
    private readonly string preferences = Path.Combine(AppSettings.ProgramFolder, "theme.preference");
    private RedactionProject Project
    {
        get => Preview.Project;
        set
        {
            // A replaced project (open, undo, redo, apply) ends any text editing; the selected
            // annotation is kept when the new project still contains it.
            CloseTextEditor(true);
            var kept = Preview.SelectedAnnotation?.Id;
            // Trim marks are frame numbers of one video; another video (trimmed, appended, opened) drops them.
            if (value.Media?.Path != Preview.Project?.Media?.Path) MarkerA = MarkerB = null;
            Preview.ClearMultiSelection(); Preview.Project = value; Preview.SelectedAnnotation = value.Annotations.FirstOrDefault(a => a.Id == kept); Refresh();
        }
    }
    private double Time => Preview.Time;
    public MainWindow(ManagedPolicy managedPolicy)
    {
        policy = managedPolicy;
        tools = new MediaTools(); thumbnails = new(tools, frameCache);
        InitializeComponent();
        InitializeAnnotations();
        InitializeLayout();
        initializing = false;
        Preview.AllowVisualObscuration = !policy.DisableVisualObscuration;
        UpdateToolButtons();
        Preview.BeforeEdit += () => { Pause(); history.Checkpoint(Project); };
        Preview.PausePlayback += Pause;
        Preview.SelectionChanged += _ => Refresh(); Preview.Edited += Refresh; Preview.MultiSelectionChanged += Refresh;
        Preview.ViewportChanged += () => ZoomText.Text = Preview.ZoomLabel;
        Preview.ColorSampled += colour => ApplyColor(colour, "Picked");
        Preview.EyedropperEnded += UpdateColorControls;
        Preview.CropDraftChanged += UpdateCropControls;
        Preview.CropConfirmRequested += ConfirmCropDraft;
        Preview.PictureClicked += ToggleAnimation; Closed += (_, _) => StopAnimation(); // 0.28.0: animated GIFs.
        SourceInitialized += (_, _) => RestorePlacement(); StateChanged += (_, _) => TrackShownState(); // 3.0.0: opens as last closed.
        // Keep the playhead with the presented image, even when rendering keeps
        // WPF's lower-priority timer from receiving a tick.
        Preview.PlaybackFramePresented += () => { if (playing) UpdateClock(); };
        Preview.CanEditFrame = () =>
        {
            if (!Preview.UsePlayer) { seekWork?.Cancel(); UpdateClock(); return true; }
            Pause(); if (seekWork == null) _ = SeekExact(Time); return false;
        };
        Preview.Player.MediaOpened += (_, _) => Dispatcher.BeginInvoke(() => Hint($"Live CPU preview {Preview.Player.FrameWidth}×{Preview.Player.FrameHeight} · Pause for exact source-frame inspection"));
        Preview.Player.MediaFailed += (_, _) => Dispatcher.BeginInvoke(() => { Pause(); Status.Text = Preview.Player.LastError ?? "Playback failed. Exact paused frame inspection remains available."; });
        Preview.Player.MediaEnded += (_, _) => Dispatcher.BeginInvoke(Pause);
        clock.Tick += (_, _) =>
        {
            if (!playing) return;
            UpdateClock();
        };
        clock.Start();
        // Light is the default (David, 0.8.1); a theme the user picks is still remembered.
        var selected = File.Exists(preferences) ? File.ReadAllText(preferences).Trim() : "Light";
        ThemeChoice.SelectedIndex = selected == "Dark" ? 1 : selected == "Light" ? 2 : 0;
        SystemEvents.UserPreferenceChanged += SystemThemeChanged;
        Closing += (_, e) =>
        {
            if (busy) { ThemedMessage.Show(this, "Cancel the current task and wait for it to stop, then close.", "Still Working"); e.Cancel = true; return; }
            if (!ConfirmDiscard()) { e.Cancel = true; return; }
            var shown = Project.Media?.Path;
            closing = true; Pause(); clock.Stop(); work?.Cancel(); seekWork?.Cancel(); prefetchWork?.Cancel(); thumbnails.Dispose(); Preview.Player.Dispose(); sourceLock?.Dispose(); tools.Dispose(); SystemEvents.UserPreferenceChanged -= SystemThemeChanged;
            Preview.Project = new(); ReleaseCapture(shown); foreach (var file in historyMedia) ReleaseCapture(file);
        };
        UpdateEditingState();
    }
    // 0.12.0: a screenshot or recording that was neither saved nor exported is wiped when it closes, so ask.
    private bool ConfirmDiscard()
    {
        var unsavedProject = Project.Media != null && savedSnapshot != ProjectStore.Serialize(Project);
        if (UnsavedCapture) return ConfirmKeepQuestion(this, ConfirmText(unsavedProject), "Unsaved " + CaptureKind);
        return !unsavedProject || ConfirmKeepQuestion(this, "Discard your unsaved changes?", "Unsaved Changes");
    }
    private static string F(double d) => d.ToString("0.######", CultureInfo.InvariantCulture);
    private static double Number(TextBox box) => double.Parse(box.Text, CultureInfo.InvariantCulture);
    private void Pause() { playing = false; Preview.Player.Pause(); ShowPlayButton(false); UpdateEditingState(); }
    private void ShowPlayButton(bool isPlaying)
    {
        PlayButton.Content = isPlaying ? "Pause" : "Play";
        Toolbar.SetIcon(PlayButton, (Geometry)FindResource(isPlaying ? "IconPause" : "IconPlay"));
        Toolbar.SetAccent(PlayButton, (Geometry)FindResource(isPlaying ? "IconPause" : "IconPlay"));
    }
    private void UpdateEditingState()
    {
        var locked = playing || busy || Preview.UsePlayer || seekWork != null;
        foreach (var field in new[] { GeometryX, GeometryY, GeometryW, GeometryH, RegionName, RegionColor, StartTime, EndTime, CoverageMargin }) field.IsReadOnly = locked;
        ApplyPropertiesButton.IsEnabled = !locked && Preview.Selected != null;
        EffectChoice.IsEnabled = !locked;
        ((ComboBoxItem)EffectChoice.Items[1]).IsEnabled = !policy.DisableVisualObscuration;
        ((ComboBoxItem)EffectChoice.Items[2]).IsEnabled = !policy.DisableVisualObscuration;
        EffectMode.IsEnabled = EffectChoice.IsEnabled && EffectChoice.SelectedIndex != 0 && !policy.DisableVisualObscuration;
        EffectStrength.IsEnabled = EffectMode.IsEnabled && EffectMode.SelectedIndex == 0;
        OpaqueTool.IsEnabled = !busy;
        BlurTool.IsEnabled = PixelateTool.IsEnabled = !busy && !policy.DisableVisualObscuration;
        ExportQuality.IsEnabled = !busy;
        KeepAudio.IsEnabled = !busy && Project.Media?.IsVideo == true && !policy.DisableAudioRetention;
        var video = Project.Media?.IsVideo == true && Preview.Selected != null && Preview.Timeline != null;
        var canFollow = video && RedactionWorkflow.FollowSeed(Preview.Selected!, Preview.Timeline!, Time) >= 0;
        // Playback controls only apply to video; still images grey them out.
        var hasVideo = Project.Media?.IsVideo == true && Preview.Timeline != null;
        foreach (var control in new Control[] { PreviousFrameButton, PlayButton, NextFrameButton, Speed, Timeline }) control.IsEnabled = hasVideo && !busy;
        // 0.17.0 (David): only videos show the timeline, the time and the playback controls; pictures get the room.
        var videoOnly = hasVideo ? Visibility.Visible : Visibility.Collapsed;
        RangeLane.Visibility = Timeline.Visibility = ClockText.Visibility = TransportControls.Visibility = PlaybackBar.Visibility = videoOnly;
        ClearScreenButton.IsEnabled = !busy;
        // 0.16.0: here (after any work ends), not in Refresh, which runs while loading is still busy.
        CopyButton.IsEnabled = !busy && Project.Media != null;
        CopyButton.ToolTip = Project.Media == null ? "Copy: Open an Image or Video First" : "Copy the Image with Its Redactions (Ctrl+C)";
        PasteButton.IsEnabled = !busy;
        ToolClearRedactions.IsEnabled = !busy && Project.Regions.Count > 0;
        SaveMediaMenuItem.IsEnabled = !busy && Project.Media != null;
        RotateMenu.IsEnabled = !busy && Project.Media != null && captures != null;
        // 0.24.0: the toolbar's turn and flip buttons, File info and Delete follow their menu items.
        RotateClockwiseButton.IsEnabled = RotateCounterClockwiseButton.IsEnabled = FlipHorizontalButton.IsEnabled = FlipVerticalButton.IsEnabled = RotateMenu.IsEnabled;
        FileInfoButton.IsEnabled = !busy && Project.Media != null;
        AppendVideoMenuItem.IsEnabled = AppendToolButton.IsEnabled = !busy && Project.Media?.IsVideo == true && Preview.Timeline != null && captures != null;
        // 0.21.0 (David): Trim and Append are on the toolbar only while a video is open; Trim shows or hides the trim row.
        TrimToolButton.Visibility = AppendToolButton.Visibility = videoOnly;
        TrimToolButton.IsEnabled = TrimMenuItem.IsEnabled = !busy && hasVideo;
        // 0.23.0: Resize is for pictures; Previous and Next for a picture opened from a folder (not a capture).
        ResizeButton.IsEnabled = !busy && Project.Media is { IsVideo: false } && captures != null;
        PreviousPictureButton.IsEnabled = NextPictureButton.IsEnabled = !busy && openedPath != null && Project.Media is { IsVideo: false };
        NavBarButton.IsEnabled = Project.Media?.IsVideo != true; // 0.26.0 (David): the navigation bar is for pictures.
        NewButton.IsEnabled = !busy && captures != null;
        AddImageButton.IsEnabled = !busy && Project.Media is { IsVideo: false }; // 0.27.0: images go onto an open image.
        if (!hasVideo) ShowTrimRow(false);
        MarkerAButton.IsEnabled = MarkerBButton.IsEnabled = ClearMarkersButton.IsEnabled = !busy && Project.Media?.IsVideo == true;
        if (Preview.Timeline is not { } trimMap || MarkerA >= trimMap.Frames.Count || MarkerB >= trimMap.Frames.Count) { MarkerA = MarkerB = null; }
        UpdateTrimUi();
        TransformMenu.IsEnabled = !busy && (Preview.Selected != null || SelectedAnnotation != null || Preview.HasMultiSelection);
        CaptureFrameMenuItem.IsEnabled = CaptureFrameButton.IsEnabled = !busy && Project.Media?.IsVideo == true && Preview.Timeline != null;
        ToolClearAnnotations.IsEnabled = !busy && Project.Annotations.Count > 0;
        FollowSubjectButton.IsEnabled = !busy && canFollow;
        StopRedactionButton.IsEnabled = !busy && video;
        WorkflowHint.Text = !video ? "Pause and draw over the subject to set the start." :
            $"Starts {TimeSpan.FromSeconds(Preview.Selected!.Start):hh\\:mm\\:ss\\.fff} · Ends {TimeSpan.FromSeconds(Preview.Selected.End):hh\\:mm\\:ss\\.fff}\n" +
            (busy ? "Working." : canFollow ? "Track, play to check, then stop where you want." : "No later frames to track. It still works as a redaction that stays in place.");
        UpdateCropControls();
        PositionRegionPopup();
    }
    private async Task RunWork(Func<CancellationToken, Task> operation, string cancellationMessage = "Operation cancelled. No completed export was produced.", string title = "Working")
    {
        if (busy) return;
        busy = true; Pause(); seekWork?.Cancel(); StopFrameWork(); HoverPopup.Visibility = Visibility.Collapsed; Preview.EyedropperActive = false; Preview.IsEnabled = false;
        work = new CancellationTokenSource();
        ShowWorkPopup(title);
        try { await operation(work.Token); }
        catch (OperationCanceledException) { Status.Text = cancellationMessage; }
        catch (Exception ex)
        {
            HideWorkPopup(); Status.Text = "Operation failed";
            if (WorkFailed != null) WorkFailed(ex); else ThemedMessage.Show(this, SafeError(ex), "TinyRedactionTool", MessageBoxButton.OK, MessageBoxImage.Warning);
        }
        finally { HideWorkPopup(); busy = false; Preview.IsEnabled = true; work.Dispose(); work = null; UpdateEditingState(); }
    }
    internal bool IsBusy => busy;
    // 0.21.0 (David): the window a captured video frame opens in is a picture editor only: the picture
    // tools, no video parts (timeline, Trim, Append, Capture frame), and it will not open a video.
    private bool picturesOnly;
    internal bool PicturesOnly
    {
        get => picturesOnly;
        set
        {
            picturesOnly = value;
            Title = value ? $"TinyRedactionTool {VersionText} · Image Editor" : $"TinyRedactionTool {VersionText}";
            AppendVideoMenuItem.Visibility = CaptureFrameMenuItem.Visibility = VideoMenu.Visibility = value ? Visibility.Collapsed : Visibility.Visible;
        }
    }
    private static string VersionText => System.Text.RegularExpressions.Regex.Match(AboutText, @"\d+\.\d+\.\d+").Value;
    internal Action<Exception>? WorkFailed { get; set; } // Checks see failures without a blocking message box.
    // A short delay keeps quick operations from flashing the popup.
    private readonly DispatcherTimer workPopupDelay = new() { Interval = TimeSpan.FromMilliseconds(250) };
    private void ShowWorkPopup(string title)
    {
        WorkTitle.Text = title + "…"; WorkProgress.IsIndeterminate = true; WorkProgress.Value = 0; WorkCancelButton.IsEnabled = true;
        workPopupDelay.Stop(); workPopupDelay.Tick -= RevealWorkPopup; workPopupDelay.Tick += RevealWorkPopup; workPopupDelay.Start();
    }
    private void RevealWorkPopup(object? sender, EventArgs e) { workPopupDelay.Stop(); if (busy) { WorkOverlay.Visibility = Visibility.Visible; WorkCancelButton.Focus(); } }
    private void HideWorkPopup() { workPopupDelay.Stop(); WorkOverlay.Visibility = Visibility.Collapsed; }
    // Determinate progress for operations that report a fraction.
    internal void ShowExportPhase(ExportPhase phase)
    {
        if (!busy) return;
        if (phase == ExportPhase.Exporting) { WorkTitle.Text = "Exporting Video…"; return; }
        WorkTitle.Text = "Checking the Exported Video…"; WorkProgress.IsIndeterminate = true;
        Hint("Checking the new video matches the original, frame by frame.");
    }
    private void ReportWork(double fraction, string text)
    {
        if (!busy) return;
        WorkProgress.IsIndeterminate = false; WorkProgress.Value = Math.Clamp(fraction, 0, 1); Hint(text);
    }
    private string SafeError(Exception ex)
    {
        var text = ex.Message;
        if (Project.Media is { } media) text = text.Replace(media.Path, "[source media]", StringComparison.OrdinalIgnoreCase);
        return text[..Math.Min(text.Length, 1800)];
    }
    private bool CheckPath(string path, bool destination)
    {
        if (!ManagedPolicy.IsNetwork(path)) return true;
        if (destination ? policy.BlockNetworkDestination : policy.BlockNetworkSource) throw new IOException("Your organisation's policy blocks network drives.");
        return ThemedMessage.Show(this, destination ? "This folder is on a network or mapped drive. Save there?" : "This source is on a network or mapped drive. Open unredacted media from it?", "Network Path", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes;
    }
    private async void OpenMedia(object sender, RoutedEventArgs e)
    {
        if (busy || !ConfirmDiscard()) return;
        var dialog = new OpenFileDialog { Title = PicturesOnly ? "Open an Image" : "Open an Image or Video", Filter = (PicturesOnly ? "Images|*.png;*.jpg;*.jpeg;*.jpe;*.bmp;*.tif;*.tiff;*.gif;*.webp;*.apng;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|" : "") + "Media Files|*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff;*.gif;*.webp;*.mp4;*.mov;*.m4v;*.avi;*.mkv;*.webm;*.wmv;*.asf;*.mpg;*.mpeg;*.mpe;*.vob;*.ts;*.mts;*.m2ts;*.m2t;*.flv;*.3gp;*.3g2;*.f4v;*.ogv;*.rm;*.rmvb;*.mxf;*.wtv;*.dv;*.mjpeg;*.mjpg;*.mlv;*.r3d;*.jpe;*.apng;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|All Files|*.*", AddToRecent = false };
        if (dialog.ShowDialog(this) != true) return;
        await RunWork(async token => { if (CheckPath(dialog.FileName, false)) await LoadMedia(dialog.FileName, null, token); }, "Loading cancelled. The previous workspace is unchanged.", "Opening");
    }
    // keepHistory (0.21.0): the new media replaces the old as an undoable step (Rotate, Trim, Append, or
    // Undo/Redo over one), so the history stays and the old file is kept for it.
    private async Task LoadMedia(string path, RedactionProject? existing, CancellationToken token, bool keepHistory = false)
    {
        Hint("Opening and Checking the File");
        var previous = Project.Media?.Path; // A capture shown before is wiped once the new media is in place (0.12.0).
        FileStream? candidateLock = new(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        try
        {
            var video = !PictureExtensions.Contains(Path.GetExtension(path).ToLowerInvariant());
            if (video && PicturesOnly) throw new InvalidDataException("This window opens pictures only. Open videos in the main editor.");
            // The fingerprint is taken while FFmpeg reads the frames (0.10.4); both read the whole file.
            using var stop = CancellationTokenSource.CreateLinkedTokenSource(token);
            var hashTask = Task.Run(() => ProjectStore.HashAsync(path, stop.Token), stop.Token);
            string hash; FrameTimeline? timeline; BitmapSource frame; GifAnimation? gif;
            try
            {
                timeline = video ? await Task.Run(() => tools.ProbeTimelineAsync(path, token), token) : null;
                frame = await Task.Run(() => tools.FrameAsync(path, timeline?.Frames[0], null, token), token);
                gif = video ? null : await ReadAnimationAsync(path, token); // 0.28.0: an animated GIF plays.
                if (gif != null && (gif.Width != frame.PixelWidth || gif.Height != frame.PixelHeight)) gif = null;
                hash = await hashTask;
            }
            catch { stop.Cancel(); try { await hashTask; } catch (Exception) { } throw; }
            if (existing != null && (!string.Equals(existing.Media!.Sha256, hash, StringComparison.OrdinalIgnoreCase) || existing.Media.Length != candidateLock.Length))
                throw new InvalidDataException("That is not the same file as the original. The project was not opened.");
            if (existing != null)
            {
                ProjectCoordinates.UpgradeLegacy(existing, frame.PixelWidth, frame.PixelHeight);
                if (existing.Media!.Width != frame.PixelWidth || existing.Media.Height != frame.PixelHeight) throw new InvalidDataException("The picture size differs from the saved project. The project was not opened.");
            }
            var duration = timeline == null ? 0 : timeline.Frames[^1].Time + timeline.Frames[^1].Duration;
            var reference = new MediaReference(Path.GetFullPath(path), candidateLock.Length, hash, frame.PixelWidth, frame.PixelHeight, duration, video);
            var project = existing ?? new RedactionProject(); project.Media = reference;
            ProjectStore.Validate(project); token.ThrowIfCancellationRequested();
            Preview.Player.Close(); sourceLock?.Dispose(); sourceLock = candidateLock; candidateLock = null;
            StopAnimation(); frameCache.Clear(); Preview.Image = frame; Preview.Time = 0; Preview.Timeline = timeline; Preview.UsePlayer = false; Preview.Selected = null; Preview.CropDraft = null;
            if (keepHistory) { Project = project; if (previous != null && captures?.Store.Owns(previous) == true) historyMedia.Add(previous); historyMedia.Remove(Path.GetFullPath(path)); }
            else { Project = project; ClearHistory(); ReleaseCapture(previous); }
            Preview.ResetViewport();
            Timeline.Maximum = Math.Max(duration, 0.001); UpdateClock();
            if (video)
            {
                Prefetch(reference, timeline!, 0, 1, whileLoading: true); // The first frame steps are ready at once (0.21.2).
                await Task.Run(() => Preview.Player.Open(reference.Path, reference.Width, reference.Height), token);
            }
            if (existing == null) projectPath = null;
            if (!keepHistory) { openedPath = captures?.Store.Owns(path) == true ? null : Path.GetFullPath(path); newPicture = false; }
            ShowAnimation(gif);
            RefreshNavBar(); // Also after a Rotate or Trim (a video hides it, a picture brings it back).
            savedSnapshot = ProjectStore.Serialize(Project);
            Status.Text = $"{frame.PixelWidth} × {frame.PixelHeight} · {(timeline == null ? gif != null ? $"Animated GIF, {gif.Frames.Count} frames (with Select, click the picture to pause or play)" : "Still image" : $"{timeline.Frames.Count} decoded frames")} · Source read-locked · {Path.GetFileName(path)}";
        }
        finally { candidateLock?.Dispose(); }
    }
    private async void OpenProject(object sender, RoutedEventArgs e)
    {
        if (busy || !ConfirmDiscard()) return;
        var dialog = new OpenFileDialog { Filter = "TRT Project|*.trtwpf.json", AddToRecent = false };
        if (dialog.ShowDialog(this) != true) return;
        await RunWork(async token =>
        {
            if (!CheckPath(dialog.FileName, false)) return;
            if (new FileInfo(dialog.FileName).Length > 32 * 1024 * 1024) throw new InvalidDataException("The project file is too large (over 32 MiB).");
            var project = ProjectStore.Deserialize(await File.ReadAllTextAsync(dialog.FileName, token));
            var path = project.Media!.Path;
            if (!File.Exists(path))
            {
                ThemedMessage.Show(this, "The original file can't be found. Choose it again: it must be exactly the same file.", "Find the Original");
                var relink = new OpenFileDialog { Title = "Find the Original File", AddToRecent = false };
                if (relink.ShowDialog(this) != true) return; path = relink.FileName;
            }
            if (!CheckPath(path, false)) return;
            await LoadMedia(path, project, token); projectPath = dialog.FileName;
        }, "Opening cancelled. The previous workspace is unchanged.", "Opening Project");
    }
    private async void SaveProject(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Media == null) return;
        var dialog = new SaveFileDialog { Filter = "TRT Project|*.trtwpf.json", FileName = projectPath ?? "Untitled.trtwpf.json", AddToRecent = false };
        if (dialog.ShowDialog(this) != true) return;
        await RunWork(async token =>
        {
            if (!CheckPath(dialog.FileName, true)) return;
            Hint("Saving Project");
            await ProjectStore.SaveAsync(dialog.FileName, Project, token); projectPath = dialog.FileName; savedSnapshot = ProjectStore.Serialize(Project); Status.Text = "Project saved. Media is referenced, not embedded.";
        }, "Saving cancelled. No project file was written.", "Saving Project");
    }
    private void Refresh()
    {
        var selected = Preview.Selected;
        updating = true; Regions.ItemsSource = null; Regions.ItemsSource = Layers.RegionsTopFirst(Project); Regions.SelectedItem = selected; updating = false;
        if (selected != null)
        {
            RegionName.Text = selected.Name; RegionColor.Text = selected.Color; Decorations.IsChecked = selected.ShowDecorations;
            updating = true; EffectChoice.SelectedIndex = (int)selected.Effect; EffectMode.SelectedIndex = selected.Aggressive ? 1 : 0; EffectStrength.Value = selected.Strength; updating = false;
            Preview.DrawingEffect = selected.Effect; Preview.DrawingAggressive = selected.Aggressive; Preview.DrawingStrength = selected.Strength; Preview.DrawingColor = selected.Color;
            var b = selected.GeometryAt(Time); GeometryX.Text = F(b.X); GeometryY.Text = F(b.Y); GeometryW.Text = F(b.Width); GeometryH.Text = F(b.Height);
            StartTime.Text = F(selected.Start); EndTime.Text = F(selected.End);
            CoverageMargin.Text = F(selected.CoverageMargin);
            TrackingRanges.ItemsSource = selected.Tracking.Select(s => $"{s.Start:0.000}–{s.End:0.000}s · {(s.State == ReviewState.Lost ? "tracking lost the subject" : "tracked")}").ToArray();
            Keyframes.ItemsSource = selected.Keyframes.Select(k => new KeyframeItem(k.Time, $"{k.Time:0.000000}s · {k.Origin} · {k.Bounds.X:0},{k.Bounds.Y:0} {k.Bounds.Width:0}×{k.Bounds.Height:0}")).ToArray();
        }
        else
        {
            Keyframes.ItemsSource = null; TrackingRanges.ItemsSource = null;
            updating = true; EffectChoice.SelectedIndex = (int)Preview.DrawingEffect; EffectMode.SelectedIndex = Preview.DrawingAggressive ? 1 : 0; EffectStrength.Value = Preview.DrawingStrength; updating = false;
        }
        SaveProjectMenuItem.IsEnabled = Project.Media != null; // 0.13.0: Save left the toolbar; File › Save Project… remains.
        RefreshAnnotations();
        var exportBlock = ExportBlockReason();
        ExportButton.IsEnabled = exportBlock == null;
        ExportButton.ToolTip = exportBlock == null ? "Export with Redactions (Checked After Saving)" : "Export is not available yet: " + exportBlock;
        UpdateCaptureUi();
        updating = true;
        ExportQuality.SelectedIndex = Project.Export.Quality == "High" ? 0 : Project.Export.Quality == "Smaller" ? 2 : 1;
        KeepAudio.IsChecked = Project.Export.KeepAudio;
        DeleteOriginalBox.IsChecked = Project.Export.DeleteOriginal && !policy.DisableSourceDeletion;
        DeleteOriginalBox.IsEnabled = Project.Media != null && !policy.DisableSourceDeletion;
        if (policy.DisableSourceDeletion) DeleteOriginalBox.ToolTip = "Your organisation's policy turns off deleting originals.";
        KeepAudio.IsEnabled = Project.Media?.IsVideo == true && !policy.DisableAudioRetention;
        updating = false;
        DrawRanges(); Preview.InvalidateVisual(); ZoomText.Text = Preview.ZoomLabel;
        SizeText.Text = Project.Media is not { } media ? "Size: –" : Project.Crop is { } crop ? $"Size: {crop.Width:0} × {crop.Height:0} (cropped)" : $"Size: {media.Width} × {media.Height}";
        UpdateEditingState();
        UpdateToolButtons();
        UpdateColorControls();
        UpdateCropControls();
        PositionRegionPopup();
    }
    // Crop (inherited Crop Image tool). 3.0.0 (David): videos too, every frame the same, with an even size.
    private bool updatingCrop;
    // The whole-pixel crop a draft gives (even-sized on a video), or null.
    private MediaRect? CropFor(MediaRect draft)
    {
        var rect = ImageCrop.PixelRect(draft, ImageCrop.Bounds(Project));
        return rect is { } r && Project.Media is { IsVideo: true } ? ImageCrop.EvenSize(r) : rect;
    }
    private void UpdateCropControls()
    {
        UpdateOptionsBar();
        if (CropTool == null || ConfirmCropButton == null || RemoveCropButton == null || updatingCrop) return;
        // Clearing the draft raises CropDraftChanged, which calls back here; never re-enter.
        updatingCrop = true;
        try { UpdateCropControlsCore(); } finally { updatingCrop = false; }
    }
    private void UpdateCropControlsCore()
    {
        var still = Project.Media != null; // 3.0.0: pictures and videos.
        CropTool.IsEnabled = !busy && still;
        if (!CropTool.IsEnabled && Preview.Tool == "Crop") { Preview.Tool = "Rectangle"; Preview.Cursor = null; Preview.CropDraft = null; }
        var cropping = Preview.Tool == "Crop";
        CropTool.SetResourceReference(BackgroundProperty, cropping ? "ToolSelected" : "Surface");
        CropTool.SetResourceReference(ForegroundProperty, cropping ? "ToolSelectedText" : "Foreground");
        ConfirmCropButton.Visibility = cropping ? Visibility.Visible : Visibility.Collapsed;
        ConfirmCropButton.IsEnabled = !busy && cropping && Preview.CropDraft is { } d && CropFor(d) != null;
        RemoveCropButton.Visibility = still && Project.Crop != null ? Visibility.Visible : Visibility.Collapsed;
        RemoveCropButton.IsEnabled = !busy;
        RemoveCropMenuItem.IsEnabled = !busy && still && Project.Crop != null;
        PositionCropPopup();
    }
    private void ConfirmCrop(object sender, RoutedEventArgs e) => ConfirmCropDraft();
    internal void ConfirmCropDraft()
    {
        if (busy || Preview.Tool != "Crop" || Project.Media is not { } media || Preview.CropDraft is not { } draft) return;
        if (CropFor(draft) is not { } rect) return;
        history.Checkpoint(Project);
        Project.Crop = rect;
        Preview.CropDraft = null; Preview.Tool = "Rectangle"; Preview.Cursor = null; Preview.ResetViewport();
        Refresh();
        Status.Text = media.IsVideo ? $"Video cropped to {rect.Width:0} × {rect.Height:0}, every frame. Export makes the cropped video; the original is unchanged. Undo or Remove Crop restores it."
            : $"Image cropped to {rect.Width:0} × {rect.Height:0}. Original unchanged. Undo or Remove crop restores it.";
    }
    private void RemoveCrop(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Crop == null) return;
        history.Checkpoint(Project);
        Project.Crop = null; Preview.CropDraft = null; Preview.ResetViewport(); Refresh();
        Status.Text = Project.Media is { IsVideo: true } ? "Crop removed. The whole video is shown and exported again." : "Crop removed. The whole image is shown and exported again.";
    }
    // The swatch shows the selected Coloured box's colour, otherwise the colour for new boxes.
    private string ActiveColor => Preview.Selected is { Effect: RedactionEffect.Opaque } r ? r.Color : Preview.DrawingColor;
    private bool ColorApplies => !busy && (Preview.Selected?.Effect ?? Preview.DrawingEffect) == RedactionEffect.Opaque;
    private void UpdateColorControls()
    {
        if (ColorSwatch == null || EyedropperButton == null) return;
        try { ColorSwatchFill.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString(ActiveColor)); } catch (FormatException) { }
        ColorSwatch.IsEnabled = ColorApplies;
        EyedropperButton.IsEnabled = ColorApplies && Project.Media != null;
        if (!EyedropperButton.IsEnabled && Preview.EyedropperActive) Preview.EyedropperActive = false;
        EyedropperButton.SetResourceReference(BackgroundProperty, Preview.EyedropperActive ? "ToolSelected" : "Surface");
        EyedropperButton.SetResourceReference(ForegroundProperty, Preview.EyedropperActive ? "ToolSelectedText" : "Foreground");
    }
    // Baseline semantics: a selected Coloured box is recoloured (undoable); with no such
    // selection the colour becomes the default for the next new box.
    internal void ApplyColor(string colour, string verb)
    {
        if (busy) return;
        colour = colour.ToUpperInvariant();
        if (Preview.Selected is { Effect: RedactionEffect.Opaque } region && Project.Regions.Contains(region))
        {
            if (region.Color != colour) { history.Checkpoint(Project); region.Color = colour; }
            Preview.DrawingColor = colour; Refresh();
            Status.Text = $"{verb} {colour} · applied to {region.Name}. Undo restores the previous colour.";
        }
        else
        {
            Preview.DrawingColor = colour; UpdateColorControls();
            Status.Text = $"{verb} {colour} · used for new coloured boxes.";
        }
    }
    private void ToggleEyedropper(object sender, RoutedEventArgs e)
    {
        if (!ColorApplies || Project.Media == null) return;
        Preview.EyedropperActive = !Preview.EyedropperActive;
        if (Preview.EyedropperActive) { Preview.Focus(); Hint("Eyedropper · Click a pixel in the frame to use its colour. Esc or right-click cancels."); }
        UpdateColorControls();
    }
    private void ChooseColor(object sender, RoutedEventArgs e)
    {
        if (!ColorApplies) return;
        Preview.EyedropperActive = false;
        var current = (Color)ColorConverter.ConvertFromString(ActiveColor);
        using var dialog = new System.Windows.Forms.ColorDialog { FullOpen = true, AnyColor = true, Color = System.Drawing.Color.FromArgb(current.R, current.G, current.B) };
        if (dialog.ShowDialog(new DialogOwner(new System.Windows.Interop.WindowInteropHelper(this).Handle)) != System.Windows.Forms.DialogResult.OK) return;
        ApplyColor($"#{dialog.Color.R:X2}{dialog.Color.G:X2}{dialog.Color.B:X2}", "Chose");
    }
    private sealed class DialogOwner(IntPtr handle) : System.Windows.Forms.IWin32Window { public IntPtr Handle { get; } = handle; }
    private sealed record KeyframeItem(double Time, string Description) { public override string ToString() => Description; }
    private void EffectStrengthChanged(object sender, RoutedPropertyChangedEventArgs<double> e) => ChangeEffect();
    private void EffectOptionsChanged(object sender, SelectionChangedEventArgs e) => ChangeEffect();
    private void ChangeEffect()
    {
        if (initializing || updating || busy || Preview == null || EffectChoice == null || EffectMode == null || EffectStrength == null) return;
        if (playing || Preview.UsePlayer || seekWork != null) { Refresh(); return; }
        var effect = (RedactionEffect)Math.Max(0, EffectChoice.SelectedIndex);
        if (policy.DisableVisualObscuration && effect != RedactionEffect.Opaque) { Refresh(); return; }
        Preview.DrawingEffect = effect; Preview.DrawingAggressive = EffectMode.SelectedIndex == 1; Preview.DrawingStrength = (int)Math.Round(EffectStrength.Value);
        if (Preview.Selected is { } region)
        { history.Checkpoint(Project); region.Effect = effect; region.Aggressive = Preview.DrawingAggressive; region.Strength = Preview.DrawingStrength; }
        Refresh();
    }
    private async void SelectEffectTool(object sender, RoutedEventArgs e)
    {
        if (busy) return;
        if (Preview.UsePlayer || seekWork != null)
        { Pause(); await SeekExact(Time); if (Preview.UsePlayer || seekWork != null) return; }
        var effect = Enum.Parse<RedactionEffect>((string)((Button)sender).Tag);
        if (policy.DisableVisualObscuration && effect != RedactionEffect.Opaque) return;
        updating = true; EffectChoice.SelectedIndex = (int)effect; updating = false;
        ChangeEffect();
        if (Preview.DrawingEffect != effect) return;
        if (Preview.Tool is "Select" or "Pan") Preview.Tool = "Rectangle";
        UpdateToolButtons();
        Hint($"{(effect == RedactionEffect.Opaque ? "Coloured box" : effect)} · Drag a {Preview.Tool.ToLowerInvariant()} over the area to redact");
    }
    private void UpdateToolButtons()
    {
        foreach (var button in new[] { OpaqueTool, BlurTool, PixelateTool, PopupOpaque, PopupBlur, PopupPixelate })
        {
            var selected = (string)button.Tag == Preview.DrawingEffect.ToString();
            button.SetResourceReference(BackgroundProperty, selected ? "ToolSelected" : "Surface");
            button.SetResourceReference(ForegroundProperty, selected ? "ToolSelectedText" : "Foreground");
        }
        // Drawing tools show the active one pressed. Crop has its own state.
        foreach (var button in new[] { SelectToolButton, RectangleTool, OvalTool, PolygonTool, PanTool, TextTool, LineTool, PolylineTool, DrawRectangleTool, DrawOvalTool, FreehandTool })
        {
            var selected = (string)button.Tag == Preview.Tool;
            button.SetResourceReference(BackgroundProperty, selected ? "ToolSelected" : "Surface");
            button.SetResourceReference(ForegroundProperty, selected ? "ToolSelectedText" : "Foreground");
        }
    }
    // Menu entries reuse the matching toolbar button, so enablement, policy and busy rules stay in one place.
    private void MenuTool(object sender, RoutedEventArgs e)
    {
        if (FindName((string)((MenuItem)sender).Tag) is Button { IsEnabled: true } button) button.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
    }
    private void MenuTheme(object sender, RoutedEventArgs e) => ThemeChoice.SelectedIndex = int.Parse((string)((MenuItem)sender).Tag, CultureInfo.InvariantCulture);
    private void ExitWindow(object sender, RoutedEventArgs e) => Close();
    private void RegionSelected(object sender, SelectionChangedEventArgs e) { if (!updating && !busy) { Preview.Selected = Regions.SelectedItem as Region; Refresh(); } }
    private void ApplyProperties(object sender, RoutedEventArgs e)
    {
        if (busy || Preview.Selected is not { } r || Project.Media is not { } m) return;
        Pause();
        try
        {
            var bounds = new MediaRect(Number(GeometryX), Number(GeometryY), Number(GeometryW), Number(GeometryH));
            var start = Number(StartTime); var end = Number(EndTime); var color = RegionColor.Text.Trim().ToUpperInvariant();
            var candidate = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
            var edit = candidate.Regions.Single(s => s.Id == r.Id); edit.Name = RegionName.Text; edit.Color = color; edit.Start = start; edit.End = end; edit.ShowDecorations = Decorations.IsChecked == true; edit.CoverageMargin = Number(CoverageMargin); edit.PutManual(Time, bounds);
            ProjectStore.Validate(candidate); history.Checkpoint(Project); Preview.Selected = edit; Project = candidate; Refresh();
        }
        catch (Exception ex) { ThemedMessage.Show(this, ex.Message, "Can't Use These Values"); }
    }
    private async void Undo(object sender, RoutedEventArgs e) => await StepHistoryAsync(true);
    private async void Redo(object sender, RoutedEventArgs e) => await StepHistoryAsync(false);
    // 0.21.0 (David): Undo and Redo also step back over Rotate, Trim and Append, which replace the media
    // itself with a working copy: the other file is loaded again (its fingerprint must still match).
    internal async Task<bool> StepHistoryAsync(bool back)
    {
        if (busy || Project.Media is not { } media) return false;
        Pause(); Preview.Selected = null; var crop = Project.Crop;
        var target = back ? history.Undo(Project) : history.Redo(Project);
        if (ReferenceEquals(target, Project)) return false;
        if (target.Media is { } other && !string.Equals(other.Path, media.Path, StringComparison.OrdinalIgnoreCase))
        {
            var saved = savedSnapshot; var done = false;
            await RunWork(async token => { await LoadMedia(other.Path, target, token, keepHistory: true); done = true; }, "Cancelled. Nothing was changed.", back ? "Undoing" : "Redoing");
            if (!done) { _ = back ? history.Redo(target) : history.Undo(target); return false; } // Put the step back where it was.
            savedSnapshot = saved; Status.Text = back ? "Undone: the previous picture or video is back." : "Redone.";
            return true;
        }
        Project = target; if (crop != Project.Crop) Preview.ResetViewport();
        return true;
    }
    // Working copies that Undo or Redo can still go back to; wiped once the history is cleared.
    private readonly HashSet<string> historyMedia = new(StringComparer.OrdinalIgnoreCase);
    // Remove History (0.28.0): the working copies Undo could return to are wiped, so the Undo list goes too.
    internal void ForgetUndoHistory() { ClearHistory(); UpdateEditingState(); }
    internal string? ShownMediaPath => Project.Media?.Path is { } p ? Path.GetFullPath(p) : null;
    private void RemoveHistory(object sender, RoutedEventArgs e)
    {
        if (captures is not { } c) { Status.Text = "Nothing to remove."; return; }
        if (!ConfirmKeepQuestion(this, "Wipe TRT's old captures and working copies, clear Undo, and forget the folders TRT last used?\n\nWhat is open in the editor stays. Files you saved or exported are not touched.", "Remove History")) return;
        var text = c.RemoveHistory();
        Status.Text = text;
        ThemedMessage.Show(this, text, "Remove History");
    }
    private void ClearHistory()
    {
        history.Clear();
        foreach (var file in historyMedia.ToList()) ReleaseCapture(file);
        historyMedia.Clear();
    }
    private void DeleteRegion(object sender, RoutedEventArgs e)
    {
        // A marching-ants group (0.19.0) is deleted as one Undo step.
        if (!busy && Preview.HasMultiSelection)
        {
            history.Checkpoint(Project);
            var count = Preview.MultiRegions.Count + Preview.MultiAnnotations.Count;
            Project.Regions.RemoveAll(Preview.MultiRegions.Contains); Project.Annotations.RemoveAll(Preview.MultiAnnotations.Contains);
            Preview.ClearMultiSelection(); Refresh(); Status.Text = $"{count} shapes deleted. Undo brings them back."; return;
        }
        DeleteSingle(sender, e);
    }
    private void DeleteSingle(object sender, RoutedEventArgs e) { if (SelectedAnnotation != null) { DeleteAnnotation(sender, e); return; } if (busy || Preview.Selected == null) return; history.Checkpoint(Project); Project.Regions.Remove(Preview.Selected); Preview.Selected = null; Refresh(); }
    private void ClearRegions(object sender, RoutedEventArgs e) { if (busy || Project.Regions.Count == 0) return; history.Checkpoint(Project); Project.Regions.Clear(); Preview.Selected = null; Refresh(); Status.Text = "All redactions cleared. Undo brings them back."; }
    private void RemoveKeyframe(object sender, RoutedEventArgs e)
    {
        if (busy || Preview.Selected is not { } r || r.Keyframes.Count <= 1 || Keyframes.SelectedItem is not KeyframeItem k) return;
        history.Checkpoint(Project); r.Keyframes.RemoveAll(f => f.Time == k.Time); Refresh();
    }
    private async void BeginHere(object sender, RoutedEventArgs e) { if (busy || seekWork != null || Preview.Selected is not { } r) return; Pause(); if (Preview.UsePlayer) await SeekExact(Time); if (Preview.UsePlayer || !Project.Regions.Contains(r)) return; history.Checkpoint(Project); r.Start = Time; r.End = Math.Max(r.End, Time); Refresh(); }
    private async void EndHere(object sender, RoutedEventArgs e) { if (busy || seekWork != null || Preview.Selected is not { } r) return; Pause(); if (Preview.UsePlayer) await SeekExact(Time); if (Preview.UsePlayer || !Project.Regions.Contains(r)) return; history.Checkpoint(Project); r.End = Time; r.Start = Math.Min(r.Start, Time); Refresh(); }
    private void Clear(object sender, RoutedEventArgs e)
    {
        if (busy || !ConfirmDiscard()) return;
        ClearWorkspace();
    }
    private void ClearWorkspace()
    {
        var shown = Project.Media?.Path;
        Pause(); seekWork?.Cancel(); StopFrameWork(); Preview.EyedropperActive = false; Preview.CropDraft = null; Preview.Player.Close(); sourceLock?.Dispose(); sourceLock = null; ShowAnimation(null); Preview.Image = null; Preview.Selected = null; Preview.Timeline = null; frameCache.Clear(); Preview.Time = 0; Project = new(); ClearHistory(); savedSnapshot = null; projectPath = null; Status.Text = "Workspace cleared.";
        ReleaseCapture(shown);
    }
    private void SelectTool(object sender, RoutedEventArgs e)
    {
        if (busy) return;
        var tool = (string)((Button)sender).Tag;
        if (tool == "Crop" && Project.Media == null) { Status.Text = "Open an image or video to crop it."; return; }
        if (tool == "Crop" && (playing || Preview.UsePlayer)) Pause(); // A video is cropped on a still frame.
        Preview.EyedropperActive = false; Preview.CropDraft = null; Preview.ClearMultiSelection(); Preview.Tool = tool; Preview.Cursor = tool == "Pan" ? CustomCursors.OpenHand : null;
        Hint(tool switch
        {
            "Crop" => "Crop · Drag a rectangle; adjust its eight handles or drag inside it. Confirm crop (Enter) applies; Esc cancels.",
            "Text" => "Text · Drag a box, then type. Ctrl+Enter or a click outside finishes. Double-click a text to edit it.",
            "Line" => "Line · Drag to draw; Shift snaps to 45°. Choose arrow ends in the options bar.",
            "Polyline" => "Polyline · Hold the button and drag; changing direction adds a right-angled corner. Release to finish.",
            "DrawRectangle" or "DrawOval" => "Outline drawing · Drag to draw; Shift keeps it square or round. It is an annotation, not a redaction.",
            "Freehand" => "Pen · Hold the button and draw.",
            _ => $"{Preview.Tool} tool · Edits create a manual keyframe at the current timestamp"
        });
        UpdateCropControls(); UpdateToolButtons(); RefreshAnnotations(); Preview.Focus();
    }
    private void Fit(object sender, RoutedEventArgs e) { Preview.Fit(); ZoomText.Text = Preview.ZoomLabel; }
    private void ActualPixels(object sender, RoutedEventArgs e) => Preview.ActualPixels();
    private void ZoomIn(object sender, RoutedEventArgs e) { Preview.Zoom(1.25, new(Preview.ActualWidth / 2, Preview.ActualHeight / 2)); ZoomText.Text = Preview.ZoomLabel; }
    private void ZoomOut(object sender, RoutedEventArgs e) { Preview.Zoom(0.8, new(Preview.ActualWidth / 2, Preview.ActualHeight / 2)); ZoomText.Text = Preview.ZoomLabel; }
    internal void ToggleProperties(object sender, RoutedEventArgs e) { var visible = PropertiesPanel.Visibility == Visibility.Visible; PropertiesPanel.Visibility = visible ? Visibility.Collapsed : Visibility.Visible; PropertiesColumn.Width = new(visible ? 0 : 300); }
    private void PlayPause(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Media is not { IsVideo: true } m) return;
        if (playing) { Pause(); _ = SeekExact(Time); return; }
        if (!Preview.Player.IsLoaded) { Status.Text = "Playback unavailable. Use exact frame inspection."; return; }
        Preview.UsePlayer = true; Preview.Player.Position = TimeSpan.FromSeconds(Time); Preview.Player.Play(); playing = true; ShowPlayButton(true); UpdateEditingState();
    }
    private void SpeedChanged(object sender, SelectionChangedEventArgs e) { if (Preview != null && Speed.SelectedItem is ComboBoxItem item) Preview.Player.SpeedRatio = double.Parse((string)item.Content, CultureInfo.InvariantCulture); }
    private void UpdateClock()
    {
        updating = true; Timeline.Value = Time; updating = false;
        var index = Preview.Timeline?.IndexAt(Time);
        ClockText.Text = TimeSpan.FromSeconds(Time).ToString(@"hh\:mm\:ss\.fff") + (index == null ? "" : $" · frame {index + 1}/{Preview.Timeline!.Frames.Count}");
        ZoomText.Text = Preview.ZoomLabel;
    }
    private async void PreviousFrame(object sender, RoutedEventArgs e) { await Step(-1); }
    private async void NextFrame(object sender, RoutedEventArgs e) { await Step(1); }
    private async void SeekKeyframe(object sender, MouseButtonEventArgs e) { if (!busy && Keyframes.SelectedItem is KeyframeItem k) { Pause(); await SeekExact(k.Time); } }
    private async void HoverTimeline(object sender, MouseEventArgs e)
    {
        if (busy || Project.Media is not { IsVideo: true } m || Preview.Timeline is not { } map || e.LeftButton == MouseButtonState.Pressed)
        { LeaveTimeline(sender, e); return; }
        hoverInside = true;
        var request = ++hoverRequest;
        var time = PrepareTimelineHover(e.GetPosition(Timeline).X);
        var frame = map.Frames[map.IndexAt(time)];
        try
        {
            var bitmap = await thumbnails.RequestAsync(m.Path, frame, m.Sha256);
            if (bitmap == null || request != hoverRequest || !hoverInside || busy || closing || Preview.Timeline != map) return;
            HoverImage.Source = bitmap; HoverTime.Text = TimeSpan.FromSeconds(frame.Time).ToString(@"hh\:mm\:ss\.fff");
            HoverPopup.Visibility = Visibility.Visible; PositionHoverOverlay();
        }
        catch (Exception) { if (request == hoverRequest) HoverPopup.Visibility = Visibility.Collapsed; }
    }
    internal double PrepareTimelineHover(double x)
    {
        hoverX = Math.Clamp(x, 0, Timeline.ActualWidth);
        PositionHoverOverlay();
        var track = Timeline.Template?.FindName("PART_Track", Timeline) as Track;
        var value = track?.ValueFromPoint(Timeline.TranslatePoint(new Point(hoverX, 0), track));
        return value.HasValue && double.IsFinite(value.Value) ? Math.Clamp(value.Value, Timeline.Minimum, Timeline.Maximum) :
            Timeline.Minimum + hoverX / Math.Max(1, Timeline.ActualWidth) * (Timeline.Maximum - Timeline.Minimum);
    }
    private void PositionHoverOverlay()
    {
        if (initializing || Timeline == null || HoverLayer == null || HoverPopup == null) return;
        HoverPopup.Measure(new Size(double.PositiveInfinity, double.PositiveInfinity));
        var anchor = Timeline.TranslatePoint(new Point(hoverX, 0), HoverLayer);
        var width = HoverPopup.Width; var height = Math.Max(158, HoverPopup.DesiredSize.Height);
        Canvas.SetLeft(HoverPopup, Math.Clamp(anchor.X - width / 2, 0, Math.Max(0, HoverLayer.ActualWidth - width)));
        Canvas.SetTop(HoverPopup, Math.Max(0, anchor.Y - height - 8));
    }
    private void HoverLayerSizeChanged(object sender, SizeChangedEventArgs e) => PositionHoverOverlay();
    private void LeaveTimeline(object sender, MouseEventArgs e) { hoverRequest++; hoverInside = false; HoverPopup.Visibility = Visibility.Collapsed; StopFrameWork(); }
    private void DrawRanges()
    {
        RangeLane.Children.Clear();
        if (Project.Media is not { IsVideo: true } m || m.Duration <= 0) return;
        // Tooltips that say what each line means (0.22.1, wording approved by David); times to the millisecond.
        foreach (var r in Project.Regions)
        {
            var rect = new System.Windows.Shapes.Rectangle { Width = Math.Max(2, (r.End - r.Start) / m.Duration * RangeLane.ActualWidth), Height = 4, Fill = Brushes.IndianRed, ToolTip = $"Redaction \"{r.Name}\": {r.Start:0.000}–{r.End:0.000} s" };
            Canvas.SetLeft(rect, r.Start / m.Duration * RangeLane.ActualWidth); Canvas.SetTop(rect, 2); RangeLane.Children.Add(rect);
            foreach (var k in r.Keyframes)
            { var mark = new System.Windows.Shapes.Rectangle { Width = 3, Height = 5, Fill = Brushes.DeepSkyBlue, ToolTip = $"Box placed by {(k.Origin == KeyframeOrigin.Manual ? "you" : "tracking")} at {k.Time:0.000} s" }; Canvas.SetLeft(mark, k.Time / m.Duration * RangeLane.ActualWidth); Canvas.SetTop(mark, 10); RangeLane.Children.Add(mark); }
            foreach (var segment in r.Tracking)
            {
                var mark = new System.Windows.Shapes.Rectangle { Width = Math.Max(3, (segment.End - segment.Start) / m.Duration * RangeLane.ActualWidth), Height = 4,
                    Fill = segment.State == ReviewState.Lost ? Brushes.OrangeRed : Brushes.MediumSeaGreen,
                    ToolTip = segment.State == ReviewState.Lost ? $"Tracking lost the subject: {segment.Start:0.000}–{segment.End:0.000} s (check this part)" : $"Tracking followed the subject: {segment.Start:0.000}–{segment.End:0.000} s" };
                Canvas.SetLeft(mark, segment.Start / m.Duration * RangeLane.ActualWidth); Canvas.SetTop(mark, 18); RangeLane.Children.Add(mark);
            }
        }
        DrawAnnotationLane(m);
        // Trim marks (0.20.0): A and B flags, and the part between them shaded (red to delete, green to keep).
        if (Preview.Timeline is { } marks && TrimRowShown) // Only while the trim row is shown (0.21.0).
        {
            double X(int frame) => marks.Frames[frame].Time / m.Duration * RangeLane.ActualWidth;
            if (MarkedFrames is { } span && span.Last < marks.Frames.Count)
            {
                // 0.22.0 (David): what will be deleted is red with X's, what stays is green; Invert swaps them.
                var end = RangeLane.ActualWidth; var a = X(span.First); var b = span.Last + 1 < marks.Frames.Count ? X(span.Last + 1) : end;
                var deleteBetween = DeletesBetween;
                void Band(double left, double right, bool deleted)
                {
                    if (right - left < 0.5) return;
                    var band = new System.Windows.Shapes.Rectangle { Width = Math.Max(2, right - left), Height = RangeLane.Height, IsHitTestVisible = false,
                        Fill = deleted ? TrimDeleteBrush : TrimKeepBrush, Tag = deleted ? "TrimDelete" : "TrimKeep" };
                    Canvas.SetLeft(band, left); Canvas.SetTop(band, 0); RangeLane.Children.Add(band);
                }
                Band(0, a, !deleteBetween); Band(a, b, deleteBetween); Band(b, end, !deleteBetween);
            }
            foreach (var (frame, label) in new[] { (MarkerA, "A"), (MarkerB, "B") })
            {
                if (frame is not { } f || f >= marks.Frames.Count) continue;
                var flag = new Border { Background = Brushes.DarkOrange, Padding = new Thickness(3, 0, 3, 0), IsHitTestVisible = false,
                    Child = new TextBlock { Text = label, Foreground = Brushes.White, FontSize = 10, FontWeight = FontWeights.Bold } };
                Canvas.SetLeft(flag, X(f) - 1); Canvas.SetTop(flag, 0); RangeLane.Children.Add(flag);
                var line = new System.Windows.Shapes.Rectangle { Width = 2, Height = RangeLane.Height, Fill = Brushes.DarkOrange, IsHitTestVisible = false };
                Canvas.SetLeft(line, X(f) - 1); Canvas.SetTop(line, 0); RangeLane.Children.Add(line);
            }
        }
    }
    private void RangeLaneSizeChanged(object sender, SizeChangedEventArgs e) { if (Preview != null) DrawRanges(); }
    // Trim bands: red with X's for frames that will be deleted, translucent green for frames that stay.
    internal static readonly Brush TrimKeepBrush = Frozen(new SolidColorBrush(Color.FromArgb(70, 46, 160, 67)));
    internal static readonly Brush TrimDeleteBrush = Frozen(new DrawingBrush
    {
        TileMode = TileMode.Tile, Viewport = new Rect(0, 0, 9, 9), ViewportUnits = BrushMappingMode.Absolute, Stretch = Stretch.None,
        Drawing = new DrawingGroup
        {
            Children =
            {
                new GeometryDrawing(new SolidColorBrush(Color.FromArgb(60, 220, 40, 40)), null, new RectangleGeometry(new Rect(0, 0, 9, 9))),
                new GeometryDrawing(null, new Pen(new SolidColorBrush(Color.FromRgb(210, 30, 30)), 1.2), Geometry.Parse("M1,1 L8,8 M8,1 L1,8")),
            },
        },
    });
    private static T Frozen<T>(T freezable) where T : Freezable { freezable.Freeze(); return freezable; }
    private async void ExportImage(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Media == null) return;
        var video = Project.Media.IsVideo; var exported = false;
        if (video && Project.Export.KeepAudio && ThemedMessage.Show(this, "Audio is not inspected or redacted. Retain the primary audio track only after reviewing it separately?", "Unredacted Audio", MessageBoxButton.YesNo, MessageBoxImage.Warning) != MessageBoxResult.Yes) return;
        var imageFormat = lastStillFormat;
        var dialog = new SaveFileDialog
        {
            Filter = video ? "MP4 video|*.mp4|MOV video|*.mov|M4V video|*.m4v|AVI video|*.avi|MKV video|*.mkv|WebM video|*.webm" : "PNG image|*.png|JPG image|*.jpg;*.jpeg|GIF image|*.gif|WebP image|*.webp",
            FilterIndex = video ? 1 : (int)imageFormat + 1, AddExtension = true,
            FileName = (Project.Crop != null && Project.Regions.Count == 0 ? "CROPPED_" : "REDACTED_") + $"{DateTime.Now:yyyyMMdd_HHmmss}" + (video ? ".mp4" : StillImageFormats.Extension(imageFormat)), AddToRecent = false
        };
        if (dialog.ShowDialog(this) != true) return;
        if (!video && StillImageFormats.FromPath(dialog.FileName) == null) { ThemedMessage.Show(this, "Choose a .png, .jpg, .gif or .webp file name.", "Image Format"); return; }
        await RunWork(async token =>
        {
            if (!CheckPath(dialog.FileName, true)) return;
            if (File.Exists(dialog.FileName)) throw new IOException("That file already exists. Choose a new name.");
            // The policy still sees the request (ExportGate refuses it under a no-deletion policy); the exporters
            // themselves never delete: TRT deletes the original only after a validated export (0.18.0).
            ExportGate.Check(Project, policy);
            var snapshot = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
            snapshot.Export.DeleteOriginal = false;
            if (video)
            {
                // Two steps in the popup: "Exporting video" with a percentage, then "Validating".
                var validating = false;
                await new VideoExport(tools).ExportAsync(dialog.FileName, snapshot, Preview.Timeline!, policy,
                    new Progress<double>(fraction => { if (!validating) ReportWork(fraction, $"Exporting · {fraction:P0}"); }), token,
                    new Progress<ExportPhase>(phase => { validating = phase == ExportPhase.Validating; ShowExportPhase(phase); }));
                Status.Text = "Video export passed stream, metadata, frame timeline and decode validation. Original source retained.";
                captures?.Store.MarkKept(Project.Media!.Path);
                exported = true;
            }
            else
            {
                snapshot.Export.KeepAudio = false;
                var format = StillImageFormats.FromPath(dialog.FileName)!.Value;
                Status.Text = $"Exporting {StillImageFormats.DisplayName(format)}, then validating it";
                await ImageExport.ExportAsync(dialog.FileName, snapshot, policy, Preview.Image!, token, tools, animation);
                lastStillFormat = format; // Session convenience only; does not mark the project as changed.
                captures?.Store.MarkKept(Project.Media!.Path);
                exported = true;
                Status.Text = format == StillFormat.Png ? "PNG export validated pixel-for-pixel and saved. Original source retained." :
                    $"{StillImageFormats.DisplayName(format)} export passed stream, metadata, decode and coverage checks. Source metadata is not copied. Original source retained.";
            }
        }, title: video ? "Exporting Video" : "Exporting Picture");
        if (exported && Project.Export.DeleteOriginal && !policy.DisableSourceDeletion) await SecurelyDeleteOriginalAsync(dialog.FileName);
    }
    // Secure deletion of the original (0.18.0, David), only after a validated export and one more question:
    // the editor closes the file, then TRT overwrites it with zeros, checks that, and deletes it.
    internal async Task<bool> SecurelyDeleteOriginalAsync(string exportedTo)
    {
        if (Project.Media is not { } media) return false;
        var original = media.Path;
        if (!ConfirmKeepQuestion(this, $"Export saved as {Path.GetFileName(exportedTo)}.\n\nSecurely delete the original, {Path.GetFileName(original)}, now? TRT overwrites it with zeros and deletes it. This can't be undone.", "Delete the Original")) 
        { Status.Text = "Export saved. The original was kept."; return false; }
        var capture = captures?.Store.Owns(original) == true;
        ClearWorkspace(); // Releases TRT's hold on the file (and wipes it if it was TRT's own capture).
        if (!capture)
        {
            try
            {
                await Task.Run(() =>
                {
                    for (var attempt = 0; ; attempt++)
                    {
                        try { CaptureStore.OverwriteAndDelete(original, Path.GetDirectoryName(original)!); return; }
                        catch (IOException ex) when (ex is not CaptureStore.CaptureCleanupRefused && attempt < 10 && File.Exists(original)) { Thread.Sleep(150); }
                    }
                });
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
            { Status.Text = $"Export saved, but the original could not be deleted: {ex.Message}"; return false; }
        }
        Status.Text = $"Export saved as {Path.GetFileName(exportedTo)}. The original was overwritten and deleted.";
        return !File.Exists(original);
    }
    private void ExportOptionsChanged(object sender, RoutedEventArgs e)
    {
        if (Preview == null || KeepAudio == null || ExportQuality == null || updating || busy) return;
        Project.Export.Quality = ExportQuality.SelectedItem is ComboBoxItem item ? (string)item.Content : "Normal";
        Project.Export.KeepAudio = KeepAudio.IsChecked == true && !policy.DisableAudioRetention;
        Project.Export.DeleteOriginal = DeleteOriginalBox.IsChecked == true && !policy.DisableSourceDeletion;
    }
    private void CancelWork(object sender, RoutedEventArgs e) { work?.Cancel(); seekWork?.Cancel(); StopFrameWork(); }
    private async void FollowSubject(object sender, RoutedEventArgs e) => await FollowSelectedSubject();
    internal async Task FollowSelectedSubject()
    {
        if (busy || Project.Media is not { IsVideo: true } media || Preview.Selected is not { } region || Preview.Timeline is not { } map) return;
        var seed = RedactionWorkflow.FollowSeed(region, map, Time); var target = map.IndexAt(region.End);
        if (seed < 0) { Status.Text = "Draw earlier in the video to track a subject. This redaction has no later frame to track."; return; }
        TrackingLoss? loss = null;
        System.Windows.Media.Imaging.BitmapSource? matchedImage = null, unmatchedImage = null;
        await RunWork(async token =>
        {
            var snapshot = ProjectStore.Deserialize(ProjectStore.Serialize(Project)); var reference = snapshot.Regions.Single(r => r.Id == region.Id);
            // Capture WPF's context before starting analysis on a worker thread.
            var reporting = true;
            var progress = new Progress<double>(fraction => { if (reporting && busy && !token.IsCancellationRequested) ReportWork(fraction, $"Tracking · {fraction:P0}"); });
            TrackingResult result;
            try { result = await Task.Run(() => new TrackingAnalysis(tools).AnalyseAsync(media, map, reference, seed, target, progress, token), token); }
            finally { reporting = false; }
            var image = await Task.Run(() => tools.FrameAsync(media.Path, map.Frames[seed], null, token), token);
            if (result.Loss is { } found)
            {
                unmatchedImage = await Task.Run(() => tools.FrameAsync(media.Path, map.Frames[found.FirstUnmatchedIndex], null, token), token);
                if (found.LastMatchedIndex is { } last)
                    matchedImage = await Task.Run(() => tools.FrameAsync(media.Path, map.Frames[last], null, token), token);
            }
            token.ThrowIfCancellationRequested(); history.Checkpoint(Project); result.Apply(region, map);
            loss = result.Loss;
            Preview.UsePlayer = false; Preview.Image = image; Preview.Time = map.Frames[seed].Time; Preview.Player.Position = TimeSpan.FromSeconds(Time);
            UpdateClock(); Refresh();
            Status.Text = result.Segments.Any(s => s.State == ReviewState.Lost) ?
                "Tracking lost the subject. Play to check; adjust the box and track again, or stop before that point." :
                "Ready to check · Press Play, then Stop redaction here at the end of the section.";
        }, "Tracking cancelled. Your redaction and earlier tracking were kept.", "Tracking");
        if (loss is not { } stopped || unmatchedImage == null || closing || !Project.Regions.Contains(region)) return;
        var lostAt = stopped.FirstUnmatchedIndex;
        var review = new FollowLossReview(matchedImage, stopped.LastMatchedIndex is { } matched ? map.Frames[matched].Time : null,
            unmatchedImage, map.Frames[lostAt].Time,
            stopped.LastMatchedIndex is { } lastMatch ? region.GeometryAt(map.Frames[lastMatch].Time) : null,
            region.GeometryAt(map.Frames[lostAt].Time), lostAt < map.IndexAt(region.End)) { Owner = this };
        review.ShowDialog();
        if (review.Decision == FollowLossReview.Choice.Continue && lostAt < map.IndexAt(region.End))
        {
            // Continue redaction (0.15.0, David): keep the box as it is on the lost frame and track on from
            // there. A further loss stops tracking and shows this dialog again.
            history.Checkpoint(Project); region.PutManual(map.Frames[lostAt].Time, region.GeometryAt(map.Frames[lostAt].Time));
            Preview.UsePlayer = false; Preview.Image = unmatchedImage; Preview.Time = map.Frames[lostAt].Time; Preview.Player.Position = TimeSpan.FromSeconds(Time);
            UpdateClock(); Refresh();
            await FollowSelectedSubject();
            return;
        }
        if (review.Decision == FollowLossReview.Choice.End && stopped.LastMatchedIndex is { } end)
        {
            history.Checkpoint(Project); RedactionWorkflow.StopAt(region, map, end);
            Preview.Image = matchedImage; Preview.Time = map.Frames[end].Time;
            Status.Text = "Redaction ended at the last matched frame. Check the retained range before exporting. Undo restores the full range.";
        }
        else if (review.Decision == FollowLossReview.Choice.Correct)
        {
            Preview.Image = unmatchedImage; Preview.Time = map.Frames[stopped.FirstUnmatchedIndex].Time;
            Preview.Tool = "Select";
            Status.Text = "Move or resize the box over the subject, then choose Track again to carry on from this frame.";
        }
        else { Status.Text = "Nothing changed. Tracking lost the subject in the orange part of the timeline; check it before exporting."; return; }
        Preview.UsePlayer = false; Preview.Player.Position = TimeSpan.FromSeconds(Time); UpdateClock(); Refresh();
    }
    private async void StopRedactionHere(object sender, RoutedEventArgs e) => await StopSelectedRedaction();
    internal async Task StopSelectedRedaction()
    {
        if (busy || Project.Media?.IsVideo != true || Preview.Selected is not { } region || Preview.Timeline is not { } map) return;
        var requested = seekWork != null ? Timeline.Value : Time;
        Pause();
        if (Preview.UsePlayer || seekWork != null)
        {
            if (!await SeekExact(requested)) return;
            if (Math.Abs(Time - map.Frames[map.IndexAt(requested)].Time) > .0000001) { Status.Text = "The stop frame could not be confirmed. Pause on an exact frame and try again."; return; }
        }
        if (Preview.UsePlayer || seekWork != null || !Project.Regions.Contains(region)) return;
        var frame = map.IndexAt(Time);
        if (map.Frames[frame].Time < region.Start) { Status.Text = "Move to or after this redaction's start, then Stop redaction here."; return; }
        if (Math.Abs(region.End - map.Frames[frame].Time) < .0000001) { Status.Text = "This redaction already stops here."; return; }
        history.Checkpoint(Project); RedactionWorkflow.StopAt(region, map, frame); Refresh();
        Status.Text = "Redaction stops here. Tracking after this point was removed; Undo can bring it back.";
    }
    private async void TrackForward(object sender, RoutedEventArgs e) => await Track(true);
    private async void TrackBackward(object sender, RoutedEventArgs e) => await Track(false);
    private async Task Track(bool forward)
    {
        if (busy || Project.Media is not { IsVideo: true } media || Preview.Selected is not { } region || Preview.Timeline is not { } map) return;
        var seed = map.IndexAt(Time); var target = map.IndexAt(forward ? region.End : region.Start);
        var issue = TrackingRangeIssue(map, region, Time, forward);
        if (issue != null) { ThemedMessage.Show(this, issue, "Can't Track Yet", MessageBoxButton.OK, MessageBoxImage.Information); return; }
        await RunWork(async token =>
        {
            var snapshot = ProjectStore.Deserialize(ProjectStore.Serialize(Project)); var referenceRegion = snapshot.Regions.Single(r => r.Id == region.Id);
            var result = await Task.Run(() => new TrackingAnalysis(tools).AnalyseAsync(media, map, referenceRegion, seed, target,
                new Progress<double>(fraction => Dispatcher.BeginInvoke(() => ReportWork(fraction, $"Tracking · {fraction:P0}"))), token), token);
            token.ThrowIfCancellationRequested(); history.Checkpoint(Project); result.Apply(region, map); Refresh();
            Status.Text = result.Segments.Any(s => s.State == ReviewState.Lost) ? "Tracking stopped on loss or ambiguity. Play the marked range and correct the box where needed." : "Tracking keyframes added. Play them through to check the box stays on the subject.";
        }, title: "Tracking");
    }
    internal static string? TrackingRangeIssue(FrameTimeline map, Region region, double time, bool forward)
    {
        var seed = map.IndexAt(time); var target = map.IndexAt(forward ? region.End : region.Start);
        if (map.Frames[seed].Time < region.Start || map.Frames[seed].Time > region.End)
            return "Move the playhead between the redaction's Begin and End first.";
        if (seed != target) return null;
        if (map.IndexAt(region.Start) == map.IndexAt(region.End))
            return "This redaction is one frame long. Set Begin and End on different frames, then track.";
        return forward ? "This is the redaction's end. Go back to its beginning, then click Track forward." :
            "This is the redaction's beginning. Go to its end, then click Track backward.";
    }
    // 3.0.0 (David): with a shape selected, the arrow keys nudge it 1 pixel (Shift: 10). With nothing selected
    // they do what they did: Left/Right step pictures in the folder, or a video's frames. A list or menu with the
    // keyboard keeps its arrow keys.
    internal bool NudgeKey(KeyEventArgs e)
    {
        if (e.Key is not (Key.Left or Key.Right or Key.Up or Key.Down) || Keyboard.Modifiers is not (ModifierKeys.None or ModifierKeys.Shift)) return false;
        static DependencyObject? Up(DependencyObject at) => (at is Visual ? VisualTreeHelper.GetParent(at) : null) ?? LogicalTreeHelper.GetParent(at);
        for (var at = e.OriginalSource as DependencyObject; at != null; at = Up(at))
            if (at is ComboBox or ListBox or Slider or MenuItem or DataGrid or TreeView or NumberSpinner) return false;
        var step = Keyboard.Modifiers == ModifierKeys.Shift ? 10 : 1;
        var dx = e.Key == Key.Left ? -step : e.Key == Key.Right ? step : 0;
        var dy = e.Key == Key.Up ? -step : e.Key == Key.Down ? step : 0;
        return Preview.Nudge(dx, dy, !e.IsRepeat);
    }
    private async void WindowKeyDown(object sender, KeyEventArgs e)
    {
        if (e.OriginalSource is TextBox || busy) return;
        if (NudgeKey(e)) { e.Handled = true; return; }
        if (BrowseKey(e)) { e.Handled = true; return; }
        if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.C) { CopyPicture(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.V) { PastePicture(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers == (ModifierKeys.Control | ModifierKeys.Shift) && e.Key == Key.V) { PasteOntoPicture(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.N) { NewPicture(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers == ModifierKeys.None && e.Key == Key.F1) { HelpManual.Open(this); e.Handled = true; }
        else if (Keyboard.Modifiers == (ModifierKeys.Control | ModifierKeys.Shift) && e.Key == Key.O) { AddPictureFiles(sender, e); e.Handled = true; }
        // 3.1.2 (David): Ctrl+O open, Ctrl+E export, Ctrl+Shift+S save media as; only when the menu item is on.
        else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.O) { OpenMedia(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.E) { if (ExportButton.IsEnabled) ExportImage(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers == (ModifierKeys.Control | ModifierKeys.Shift) && e.Key == Key.S) { if (SaveMediaMenuItem.IsEnabled) SaveMediaAs(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers.HasFlag(ModifierKeys.Control) && e.Key == Key.Z) { Undo(sender, e); e.Handled = true; }
        else if (Keyboard.Modifiers.HasFlag(ModifierKeys.Control) && e.Key == Key.Y) { Redo(sender, e); e.Handled = true; }
        // 3.0.0 (David): layers, as in image editors: Ctrl+] up, Ctrl+[ down, Ctrl+D duplicate.
        else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key is Key.OemCloseBrackets or Key.OemOpenBrackets) { MoveSelectedLayer(e.Key == Key.OemCloseBrackets, null); e.Handled = true; }
        else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.D) { DuplicateSelectedLayer(null); e.Handled = true; }
        else if (e.Key is Key.Left or Key.Right) { await Step(e.Key == Key.Left ? -1 : 1); e.Handled = true; }
        else if (e.Key == Key.Delete) DeleteRegion(sender, e);
        else if (e.Key == Key.Escape && Preview.EyedropperActive) { Preview.EyedropperActive = false; Status.Text = "Eyedropper cancelled."; e.Handled = true; }
    }
    private void ThemeChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ThemeChoice.SelectedItem is not ComboBoxItem item) return;
        var choice = (string)item.Content; ApplyTheme(choice);
        try { File.WriteAllText(preferences, choice); } catch (IOException) { Status.Text = "Theme changed; preference could not be saved."; }
    }
    private void SystemThemeChanged(object sender, UserPreferenceChangedEventArgs e) => Dispatcher.BeginInvoke(() => { if (ThemeChoice.SelectedIndex == 0) ApplyTheme("System"); });
    private void ApplyTheme(string choice)
    {
        ApplyThemeResources(choice); Preview?.InvalidateVisual();

    }
    internal static bool DarkTheme { get; private set; }
    // The theme choice (0.18.0: chosen in Settings) is kept in theme.preference beside the program.
    internal static string ThemeFile => Path.Combine(AppSettings.ProgramFolder, "theme.preference");
    internal static string SavedTheme()
    {
        try { var saved = File.Exists(ThemeFile) ? File.ReadAllText(ThemeFile).Trim() : "Light"; return saved is "Dark" or "System" ? saved : "Light"; }
        catch (IOException) { return "Light"; }
    }
    internal void SetTheme(string choice) => ThemeChoice.SelectedIndex = choice == "Dark" ? 1 : choice == "System" ? 0 : 2;
    // Without an editor open: apply and remember the theme directly.
    internal static void SetThemeWithoutEditor(string choice)
    {
        ApplyThemeResources(choice);
        try { File.WriteAllText(ThemeFile, choice); } catch (IOException) { }
    }
    // The capture bar opens before any editor (0.12.0), so it applies the remembered theme itself.
    internal static void ApplySavedTheme()
    {
        var file = Path.Combine(AppSettings.ProgramFolder, "theme.preference");
        string selected;
        try { selected = File.Exists(file) ? File.ReadAllText(file).Trim() : "Light"; } catch (IOException) { selected = "Light"; }
        ApplyThemeResources(selected is "Dark" or "Light" ? selected : "System");
    }
    internal static void ApplyThemeResources(string choice)
    {
        var light = choice == "Light";
        if (choice == "System") light = Registry.GetValue(@"HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 0) is int value && value != 0;
        DarkTheme = !light;
        // Light uses a classic grey chrome and workspace; Dark is neutral grey
        // built on David's #535353, with darker fields and workspace.
        void Set(string key, string lightColour, string darkColour) => Application.Current.Resources[key] = new SolidColorBrush((Color)ColorConverter.ConvertFromString(light ? lightColour : darkColour));
        Set("Background", "#FFFFFF", "#3E3E3E");
        Set("Surface", "#F0F0F0", "#535353");
        Set("Foreground", "#1E1E1E", "#F0F0F0");
        Set("Warning", "#875000", "#F2C27A");
        Set("ChromeLine", "#C8C8C8", "#6E6E6E");
        Set("FieldBorder", "#8E949E", "#7A7A7A");
        Set("CanvasBackdrop", "#C4C4C4", "#3A3A3A");
        Set("CanvasText", "#3C3C3C", "#D3D3D3");
        Set("ToolSelected", "#CCE4F7", "#2F6EA8");
        Set("ToolSelectedText", "#1E1E1E", "#FFFFFF");
        Set("ToolHover", "#E5F1FB", "#616161");
        Set("ToolHoverBorder", "#7EB4EA", "#8FB8E6");
        Set("MenuBackground", "#FBFBFB", "#333333"); // 0.28.0: menus, right-click menus and message boxes follow the theme.
        WindowTheme.ApplyToAll();
        ThemeApplied?.Invoke(DarkTheme);
    }
    // 0.28.0: the notification-area menu and the ruler's menu (Windows Forms) follow the theme too.
    internal static event Action<bool>? ThemeApplied;
    private void About(object sender, RoutedEventArgs e) => AboutWindow.Open(this, VersionText);
    private void OpenHelp(object sender, RoutedEventArgs e) => HelpManual.Open(this); // 3.0.0 (David)
    // 0.27.1 (David): the About box is the simple one (AboutWindow); this text is its version and description.
    internal static string AboutText => "TinyRedactionTool 3.1.2\n" + AboutWindow.Description;
}
