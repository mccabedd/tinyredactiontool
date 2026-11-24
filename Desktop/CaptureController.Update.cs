using System.Diagnostics;
using System.IO;
using System.Windows;

namespace TinyRedaction.Desktop;

// Check for Updates (3.4.0, David), from the About box only. See Updater for what is checked.
internal sealed partial class CaptureController
{
    private Action? afterQuit;
    internal bool IsQuitting => quitting;
    // Checks replace these: the network (a fake GitHub), the questions, and the program path.
    internal Func<Updater> NewUpdater { get; set; } = () => new Updater(Updater.CurrentVersion);
    internal Func<Window?, string, string, bool> AskUpdate { get; set; } =
        (owner, text, title) => (owner != null ? ThemedMessage.Show(owner, text, title, MessageBoxButton.YesNo, MessageBoxImage.Question) : ThemedMessage.Show(text, title, MessageBoxButton.YesNo, MessageBoxImage.Question)) == MessageBoxResult.Yes;
    internal Action<Window?, string, string> TellUpdate { get; set; } =
        (owner, text, title) => { if (owner != null) ThemedMessage.Show(owner, text, title); else ThemedMessage.Show(text, title); };
    internal string? ProgramPath { get; set; } = Updater.CanReplaceItself ? Environment.ProcessPath : null;
    internal Func<string, Process?> StartProgram { get; set; } =
        exe =>
        {
            var start = new ProcessStartInfo(exe) { UseShellExecute = false };
            if (App.PolicyPath != null) { start.ArgumentList.Add("--managed-policy"); start.ArgumentList.Add(App.PolicyPath); }
            start.ArgumentList.Add(App.AfterUpdateArgument); start.ArgumentList.Add(Environment.ProcessId.ToString());
            return Process.Start(start);
        };

    // The first start after an update: say so, and where the previous version was kept.
    internal void ShowUpdated() =>
        Notify($"Updated to TinyRedactionTool {Updater.CurrentVersion.ToString(3)}. The previous version is kept as {Path.GetFileName(UpdateSwap.OldPath(Environment.ProcessPath ?? "TinyRedactionTool.exe"))}.");
    // status: a line in the About box ("Checking…", "Downloading… 40 %"). Returns what happened, for the About box.
    internal async Task<string> CheckForUpdatesAsync(Window? owner, Action<string> status)
    {
        var updater = NewUpdater();
        Updater.Release? release;
        try
        {
            status("Checking GitHub for a newer version…");
            release = await updater.LatestAsync(CancellationToken.None);
        }
        catch (Exception ex) when (ex is IOException or System.Net.Http.HttpRequestException or TaskCanceledException or System.Text.Json.JsonException or UriFormatException)
        { return Failed(owner, ex); }
        if (release == null) return $"You have the latest version ({Updater.CurrentVersion.ToString(3)}).";

        var notes = release.Notes.Trim();
        if (notes.Length > 1200) notes = notes[..1200].TrimEnd() + "…";
        var replace = ProgramPath != null;
        var question = $"TinyRedactionTool {release.Version.ToString(3)} is available (you have {Updater.CurrentVersion.ToString(3)}).\n\n{notes}\n\n" +
            (replace ? "Download and install it? TRT checks the download, then closes (asking about unsaved work first) and starts again." : "Download it? TRT checks the download and tells you where it is.");
        if (!AskUpdate(owner, question, "Update Available")) return "Not updated.";

        var (target, beside) = UpdateSwap.DownloadTarget(ProgramPath, release.AssetName);
        try
        {
            await updater.DownloadAsync(release, target, new Progress<double>(p => status($"Downloading {release.AssetName}… {p:P0}")), CancellationToken.None);
        }
        catch (Exception ex) when (ex is IOException or System.Net.Http.HttpRequestException or TaskCanceledException or UnauthorizedAccessException)
        { return Failed(owner, ex); }
        if (!replace || !beside)
        {
            var where = replace ? "TRT can't write to the folder it runs from, so it can't replace itself." : "This copy of TRT can't replace itself (it isn't the single .exe).";
            TellUpdate(owner, $"{release.AssetName} is downloaded and checked:\n\n{target}\n\n{where} Close TRT and run the new file instead.", "Update Downloaded");
            return "Downloaded and checked: " + target;
        }
        return InstallUpdate(owner, ProgramPath!, target, release);
    }
    private string Failed(Window? owner, Exception ex)
    {
        var text = ex is System.Net.Http.HttpRequestException or TaskCanceledException ? "TRT couldn't reach GitHub. Check the internet connection and try again." : ex.Message;
        TellUpdate(owner, text, "Check for Updates");
        return "Not updated: " + text;
    }
    // Swap the checked download in, then quit (asking about unsaved work as Quit always does); the new TRT starts once
    // this one has ended. If TRT doesn't quit (work kept open), the swap is undone and nothing changes.
    private string InstallUpdate(Window? owner, string exe, string download, Updater.Release release)
    {
        try { UpdateSwap.Swap(exe, download); }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            TellUpdate(owner, $"TRT couldn't put the new version in place ({ex.Message}). Nothing was changed; the checked download is here:\n\n{download}", "Check for Updates");
            return "Not updated.";
        }
        afterQuit = () => StartProgram(exe);
        foreach (var about in Application.Current?.Windows.OfType<AboutWindow>().ToList() ?? []) about.Close(); // Before the editors close.
        Quit();
        if (IsQuitting) return $"Updating to {release.Version.ToString(3)}…";
        afterQuit = null;
        try { UpdateSwap.Undo(exe, download); } catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        return "Not updated: TRT stayed open, so the update wasn't installed. The download is kept; Check for Updates again to install it.";
    }
}
