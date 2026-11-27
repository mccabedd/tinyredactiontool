using System.IO;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Win32;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Saving (3.3.0, David): three commands.
//   Save (Ctrl+S): the rendered result to the established save destination: the file that was opened, or the last
//     file Save As wrote. Without one (a capture, a new image, a project), or in a format TRT can't write, Save As opens.
//     Nothing changed since it was last opened or saved: Ctrl+S does nothing. Replacing the file being edited asks once
//     (the edits become permanent; Save Project keeps them editable; a video's sound that would go is named), then
//     the file is opened again as saved.
//   Save As (Ctrl+Shift+S): the same checked writing and replacing, to a new name; the new file becomes the destination.
//   Save Project: the editable work. Media in TRT's temporary folder gets a checked copy beside the project first.
// Secure deletion of the original is its own command (File › Securely Delete Original…), never part of saving.
public partial class MainWindow
{
    private string? saveTarget;     // Where Save writes; named in the title.
    private string? savedRender;    // The work as last opened or saved: unchanged, Ctrl+S has nothing to do.
    private string? lastSavedCopy;  // A copy Save As wrote in this session (Securely Delete Original needs one).
    private MediaOrigin origin = new(MediaOriginKind.Imported, DateTime.Now);
    private readonly HashSet<string> replaceConfirmed = new(StringComparer.OrdinalIgnoreCase);
    internal string? SaveTarget => saveTarget;
    internal MediaOrigin Origin => origin;
    // Checks answer the file dialogs: (folder, suggested name) → the chosen full path, or null for Cancel.
    internal Func<string?, string, string?>? AnswerSaveAs { get; set; }
    internal Func<string?, string, string?>? AnswerSaveProject { get; set; }
    private const string SaveTip = "Save (Ctrl+S)", SaveAsTip = "Save As a New File (Ctrl+Shift+S)";
    private static readonly string[] VideoFormats = [".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm"];

    // A new picture or video (not an undoable replacement): where it came from, and where Save writes.
    private void MediaLoaded(string path, RedactionProject? existing)
    {
        origin = captures?.Store.OriginOf(path) ?? new MediaOrigin(MediaOriginKind.Imported, DateTime.Now);
        // An opened file is the destination. A project's media (or a capture) has none until Save As: replacing the
        // file a project depends on would stop the project opening.
        saveTarget = existing == null ? openedPath : null;
        lastSavedCopy = null;
    }
    private void UpdateTitle()
    {
        Title = $"TinyRedactionTool {VersionText}" + (picturesOnly ? " · Image Editor" : "") + (saveTarget != null && Project.Media != null ? " - " + Path.GetFileName(saveTarget) : "");
        captures?.RefreshTabs(); // 3.5.0: the tab's name follows.
    }
    private void UpdateSaveUi()
    {
        if (SecureDeleteMenuItem == null) return;
        SecureDeleteMenuItem.IsEnabled = !busy && SecureDeleteTarget() != null;
        SecureDeleteMenuItem.ToolTip = policy.DisableSourceDeletion ? "Your Organisation's Policy Turns Off Deleting Originals" : "Overwrite and Delete the Opened File, After Save As Wrote a Copy";
    }
    private static bool CanWrite(string path, bool video) =>
        video ? VideoFormats.Contains(Path.GetExtension(path).ToLowerInvariant()) : StillImageFormats.FromPath(path) != null;
    private string? SaveFolder()
    {
        foreach (var candidate in new[] { saveTarget, openedPath })
            if (candidate != null && Path.GetDirectoryName(candidate) is { } dir && Directory.Exists(dir)) return dir;
        if (Settings.LastSaveFolder is { } last && Directory.Exists(last)) return last;
        if (captures?.Settings.LastSaveFolder is { } shared && Directory.Exists(shared)) return shared;
        return Environment.GetFolderPath(Project.Media?.IsVideo == true ? Environment.SpecialFolder.MyVideos : Environment.SpecialFolder.MyPictures);
    }
    internal string SuggestedName(string extension, string? folder)
    {
        var suffix = SaveNaming.Suffix(Project, origin.Kind);
        return SaveNaming.Suggest(folder, suffix, SaveNaming.TimeFor(suffix, origin, DateTime.Now), extension);
    }
    private bool ConfirmAudio() => !Project.Export.KeepAudio ||
        ThemedMessage.Show(this, "Audio is not inspected or redacted. Retain the primary audio track only after reviewing it separately?", "Unredacted Audio", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes;

    // ---- Save ----
    private async void SaveFile(object sender, RoutedEventArgs e) => await SaveAsync();
    internal async Task<bool> SaveAsync()
    {
        if (busy || Project.Media is not { } media) return false;
        if (ExportBlockReason() is { } block) { Status.Text = "Save is not available yet: " + block; return false; }
        if (saveTarget == null || !CanWrite(saveTarget, media.IsVideo)) return await SaveAsAsync();
        if (savedRender == ProjectStore.Serialize(Project) && File.Exists(saveTarget)) { Status.Text = $"Nothing has changed since {Path.GetFileName(saveTarget)} was opened or saved."; return false; }
        if (media.IsVideo && !ConfirmAudio()) return false;
        return await WriteAsync(saveTarget);
    }

    // ---- Save As ----
    private async void SaveAs(object sender, RoutedEventArgs e) => await SaveAsAsync();
    // chosen: a path given directly (checks); otherwise the dialog (or AnswerSaveAs) picks one.
    internal async Task<bool> SaveAsAsync(string? chosen = null)
    {
        if (busy || Project.Media is not { } media) return false;
        if (ExportBlockReason() is { } block) { Status.Text = "Save As is not available yet: " + block; return false; }
        var video = media.IsVideo;
        if (chosen == null && video && !ConfirmAudio()) return false;
        // A picture keeps the format of the file it will replace or of the last save; a video starts as MP4.
        var format = saveTarget != null && StillImageFormats.FromPath(saveTarget) is { } targetFormat ? targetFormat : lastStillFormat;
        var folder = SaveFolder();
        var suggested = SuggestedName(video ? ".mp4" : StillImageFormats.Extension(format), folder);
        var destination = chosen;
        if (destination == null && AnswerSaveAs != null) destination = AnswerSaveAs(folder, suggested);
        else if (destination == null)
        {
            var dialog = new SaveFileDialog
            {
                Title = "Save As",
                Filter = video ? "MP4 video|*.mp4|MOV video|*.mov|M4V video|*.m4v|AVI video|*.avi|MKV video|*.mkv|WebM video|*.webm" : "PNG image|*.png|JPG image|*.jpg;*.jpeg|GIF image|*.gif|WebP image|*.webp",
                FilterIndex = video ? 1 : (int)format + 1, AddExtension = true, AddToRecent = false,
                InitialDirectory = folder, FileName = suggested,
            };
            if (dialog.ShowDialog(this) == true) destination = dialog.FileName;
        }
        if (destination == null) { Status.Text = "Save As cancelled. Nothing was saved."; return false; }
        if (!CanWrite(destination, video)) { ThemedMessage.Show(this, video ? "Choose a .mp4, .mov, .m4v, .avi, .mkv or .webm file name." : "Choose a .png, .jpg, .gif or .webp file name.", "Save As"); return false; }
        return await WriteAsync(Path.GetFullPath(destination));
    }

    // Writes the rendered result to destination with the checked export pipeline. Replacing the file being edited
    // (in place) asks once and opens it again afterwards; any other file becomes the new destination. Cancelled or
    // failed: the destination, the editing and any existing file stay as they were.
    private async Task<bool> WriteAsync(string destination)
    {
        var media = Project.Media!;
        var name = Path.GetFileName(destination);
        var exists = File.Exists(destination);
        var inPlace = exists && (ProjectStore.SamePath(destination, media.Path) || openedPath != null && ProjectStore.SamePath(destination, openedPath));
        // What the saved file will hold, so a reopened file still counts as redacted or edited.
        var suffix = SaveNaming.Suffix(Project, origin.Kind);
        var edits = Project.BakedEdit || Project.Crop != null || Project.Annotations.Count > 0;
        var soundGoes = media.IsVideo && !Project.Export.KeepAudio && exists && await HasSoundAsync(destination);
        var soundNote = soundGoes ? $"\n\n{name} has sound. The saved video won't (Keep Primary Audio is off in Save Options)." : "";
        if (inPlace && !replaceConfirmed.Contains(destination))
        {
            var kind = media.IsVideo ? "video" : "picture";
            if (!ConfirmKeepQuestion(this, $"Replace {name} with this version?\n\nYour redactions and other edits become a permanent part of the {kind}; the unedited {kind} will be gone. Use Save Project as well to keep them editable." + soundNote, "Save"))
            { Status.Text = $"Not saved. {name} is unchanged."; return false; }
            replaceConfirmed.Add(destination);
        }
        else if (!inPlace && soundGoes && !ConfirmKeepQuestion(this, $"Replace {name}?" + soundNote, "Save"))
        { Status.Text = $"Not saved. {name} is unchanged."; return false; }

        if (!inPlace)
        {
            if (!await ExportToAsync(destination, exists ? ExportReplace.Existing : null)) return false;
            saveTarget = destination; savedRender = ProjectStore.Serialize(Project); lastSavedCopy = destination;
            RememberFolder(destination); UpdateTitle(); UpdateSaveUi();
            Status.Text = $"Saved {name} (checked after writing). Ctrl+S now saves to it.";
            return true;
        }
        var released = false;
        // Just before the swap: let go of TRT's own hold on the file (the lock, the player, background frame reading).
        var replace = ExportReplace.Original(() => Dispatcher.Invoke(() =>
        {
            Pause(); StopFrameWork(); Preview.Player.Close(); sourceLock?.Dispose(); sourceLock = null; released = true;
        }));
        if (!await ExportToAsync(destination, replace))
        {
            // The swap failed after letting go: the file is untouched; hold it again with the work as it was.
            if (released) await RunWork(async token => await LoadMedia(Project.Media!.Path, Project, token, keepHistory: true), "Reopening cancelled.", "Opening");
            return false;
        }
        var reopened = false;
        await RunWork(async token => { await LoadMedia(destination, null, token); reopened = true; }, "Reopening cancelled. The file was saved.", "Opening");
        if (reopened)
        {
            Project.BakedRedaction = suffix == SaveNaming.Redacted;
            Project.BakedEdit = suffix == SaveNaming.Edited || suffix == SaveNaming.Redacted && edits;
            savedSnapshot = savedRender = ProjectStore.Serialize(Project);
            saveTarget = destination; UpdateTitle();
        }
        RememberFolder(destination); UpdateSaveUi();
        Status.Text = $"Saved {name}: the edits are now part of it (checked before it replaced the file).";
        return true;
    }
    private async Task<bool> HasSoundAsync(string path)
    {
        try { return await HasAudioAsync(path, CancellationToken.None); }
        catch (Exception ex) when (ex is IOException or InvalidDataException or InvalidOperationException) { return false; }
    }
    private void RememberFolder(string path)
    {
        if (Path.GetDirectoryName(path) is not { } folder) return;
        if (captures != null) { captures.Settings.LastSaveFolder = folder; captures.Settings.Save(); }
    }
    internal bool IsOpenFile(string path) =>
        openedPath != null && ProjectStore.SamePath(path, openedPath) || Project.Media != null && ProjectStore.SamePath(path, Project.Media.Path);

    // The checked writing (Export before 3.3.0): written beside the destination, checked, then moved into place.
    // replace null: an existing file is refused; Existing: replacing it was confirmed; Original: the file being edited.
    internal async Task<bool> ExportToAsync(string destination, ExportReplace? replace)
    {
        var video = Project.Media!.IsVideo; var exported = false;
        await RunWork(async token =>
        {
            if (!CheckPath(destination, true)) return;
            ExportGate.Check(Project, policy);
            var snapshot = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
            snapshot.Export.DeleteOriginal = false;
            var kept = replace?.ReleaseOriginal != null ? "It replaced the file." : "The original is unchanged.";
            if (video)
            {
                // Two steps in the popup: "Saving" with a percentage, then "Validating".
                var validating = false;
                await new VideoExport(tools).ExportAsync(destination, snapshot, Preview.Timeline!, policy,
                    new Progress<double>(fraction => { if (!validating) ReportWork(fraction, $"Saving · {fraction:P0}"); }), token,
                    new Progress<ExportPhase>(phase => { validating = phase == ExportPhase.Validating; ShowExportPhase(phase); }), replace);
                Status.Text = $"The video passed stream, metadata, frame timeline and decode checks. {kept}";
            }
            else
            {
                snapshot.Export.KeepAudio = false;
                var format = StillImageFormats.FromPath(destination)!.Value;
                Status.Text = $"Saving {StillImageFormats.DisplayName(format)}, then checking it";
                await ImageExport.ExportAsync(destination, snapshot, policy, Preview.Image!, token, tools, animation, replace);
                lastStillFormat = format; // Session convenience only; does not mark the project as changed.
                Status.Text = format == StillFormat.Png ? $"The PNG was checked pixel for pixel. {kept}" :
                    $"The {StillImageFormats.DisplayName(format)} passed stream, metadata, decode and coverage checks; source metadata is not copied. {kept}";
            }
            captures?.Store.MarkKept(Project.Media!.Path);
            exported = true;
        }, "Cancelled. Nothing was saved.", replace?.ReleaseOriginal != null || video ? "Saving" : "Saving the Picture");
        return exported;
    }

    // ---- Save Project ----
    private async void SaveProject(object sender, RoutedEventArgs e) => await SaveProjectAsync();
    internal async Task<bool> SaveProjectAsync(string? chosen = null)
    {
        if (busy || Project.Media is not { } media) return false;
        var folder = projectPath != null && Path.GetDirectoryName(projectPath) is { } projectFolder && Directory.Exists(projectFolder) ? projectFolder : SaveFolder();
        var suggested = projectPath != null ? Path.GetFileName(projectPath) : SaveNaming.SuggestProject(folder, DateTime.Now);
        var path = chosen;
        if (path == null && AnswerSaveProject != null) path = AnswerSaveProject(folder, suggested);
        else if (path == null)
        {
            var dialog = new SaveFileDialog { Title = "Save Project", Filter = "TRT Project|*" + SaveNaming.ProjectExtension, FileName = suggested, InitialDirectory = folder, AddToRecent = false };
            if (dialog.ShowDialog(this) == true) path = dialog.FileName;
        }
        if (path == null) { Status.Text = "Save Project cancelled. No project file was written."; return false; }
        path = Path.GetFullPath(path);
        if (!path.EndsWith(SaveNaming.ProjectExtension, StringComparison.OrdinalIgnoreCase)) path = Path.ChangeExtension(path, null) + SaveNaming.ProjectExtension;
        var saved = false; string? backing = null;
        await RunWork(async token =>
        {
            if (!CheckPath(path, true)) return;
            Hint("Saving Project");
            var copy = ProjectStore.Deserialize(ProjectStore.Serialize(Project));
            // Media in TRT's temporary folder is wiped when TRT quits: keep a checked copy beside the project and
            // point the project at it, before saying it is saved.
            if (captures?.Store.Owns(media.Path) == true)
            {
                backing = await BackingPathAsync(path, media, token);
                if (!File.Exists(backing)) await CopyVerifiedAsync(media.Path, backing, media.Sha256, token);
                if (!await ProjectStore.MatchesAsync(media with { Path = backing }, backing, token)) throw new IOException("The copy of the media beside the project could not be checked. The project was not saved.");
                copy.Media = media with { Path = backing };
            }
            await ProjectStore.SaveAsync(path, copy, token);
            ProjectStore.Deserialize(await File.ReadAllTextAsync(path, token)); // Reads back before reporting success.
            projectPath = path; savedSnapshot = ProjectStore.Serialize(Project); saved = true;
            if (backing != null) captures!.Store.MarkKept(media.Path);
        }, "Saving cancelled. No project file was written.", "Saving Project");
        if (!saved) return false;
        captures?.RefreshTabs(); // 3.5.0: the tab is named after the project.
        Status.Text = backing != null
            ? $"Project saved, with a copy of the {(media.IsVideo ? "video" : "picture")} beside it ({Path.GetFileName(backing)}), so it opens again after TRT clears its temporary files."
            : "Project saved. Media is referenced, not embedded.";
        return true;
    }
    // Beside the project: <project name>_MEDIA.<ext>; an existing file with other content is never replaced (_2, _3...).
    private static async Task<string> BackingPathAsync(string projectPath, MediaReference media, CancellationToken token)
    {
        var folder = Path.GetDirectoryName(projectPath)!;
        var stem = Path.GetFileName(projectPath)[..^SaveNaming.ProjectExtension.Length] + "_MEDIA";
        var extension = Path.GetExtension(media.Path);
        for (var i = 1; ; i++)
        {
            var candidate = Path.Combine(folder, (i == 1 ? stem : $"{stem}_{i}") + extension);
            if (!File.Exists(candidate)) return candidate;
            if (new FileInfo(candidate).Length == media.Length && string.Equals(await ProjectStore.HashAsync(candidate, token), media.Sha256, StringComparison.OrdinalIgnoreCase)) return candidate;
        }
    }

    // ---- Securely Delete Original (0.18.0; 3.3.0: its own command) ----
    // The opened file, once Save As has written a checked copy elsewhere in this session; never a capture, never
    // while the editor shows a working copy (Rotate, Trim...), never under a no-deletion policy.
    internal string? SecureDeleteTarget()
    {
        if (policy.DisableSourceDeletion || Project.Media is not { } media || openedPath is not { } original) return null;
        if (!ProjectStore.SamePath(media.Path, original) || captures?.Store.Owns(original) == true || !File.Exists(original)) return null;
        if (lastSavedCopy == null || !File.Exists(lastSavedCopy) || ProjectStore.SamePath(lastSavedCopy, original)) return null;
        return original;
    }
    private async void SecurelyDeleteOriginal(object sender, RoutedEventArgs e) => await SecurelyDeleteOriginalAsync();
    internal async Task<bool> SecurelyDeleteOriginalAsync()
    {
        if (busy || SecureDeleteTarget() is not { } original || lastSavedCopy is not { } copy) return false;
        if (!ConfirmKeepQuestion(this, $"Securely delete this file?\n\n{original}\n\nYour saved copy, {Path.GetFileName(copy)}, is kept. TRT overwrites the file with zeros and deletes it. This can't be undone.", "Securely Delete Original"))
        { Status.Text = "The original was kept."; return false; }
        ClearWorkspace(); // Releases TRT's hold on the file.
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
        { Status.Text = $"The original could not be deleted: {ex.Message}"; return false; }
        Status.Text = $"{Path.GetFileName(original)} was overwritten and deleted. Your copy, {Path.GetFileName(copy)}, is kept.";
        return !File.Exists(original);
    }

    // A picture made from other work (a frame with its redactions, a new image carrying the old one) starts out
    // already redacted or edited: its suggested name says so.
    internal void CarryProvenance(bool redaction, bool edit)
    {
        if (Project.Media == null || !redaction && !edit) return;
        var unchanged = savedSnapshot == ProjectStore.Serialize(Project);
        Project.BakedRedaction |= redaction; Project.BakedEdit |= edit;
        savedRender = ProjectStore.Serialize(Project);
        if (unchanged) savedSnapshot = savedRender;
    }
}
