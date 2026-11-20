using System.IO;

namespace TinyRedaction.Desktop;

// 3.2.2 (David): exports never replace a file unless asked. Existing: the user confirmed Windows' "replace?" question
// for a file that is not the one open in TRT. Original: File › Save puts the redacted picture or video in place of the
// opened file; ReleaseOriginal lets go of TRT's own hold on it just before the swap. Either way the new file is written
// and checked beside it first, and only then moved over the old one in one step (nothing half-written is ever left).
public sealed class ExportReplace
{
    public static readonly ExportReplace Existing = new(null);
    public static ExportReplace Original(Action releaseOriginal) => new(releaseOriginal ?? throw new ArgumentNullException(nameof(releaseOriginal)));
    private ExportReplace(Action? releaseOriginal) => ReleaseOriginal = releaseOriginal;
    public Action? ReleaseOriginal { get; }

    internal static void Finish(string temporary, string destination, ExportReplace? replace)
    {
        if (replace == null) { File.Move(temporary, destination, false); return; } // Never overwrite unless asked.
        replace.ReleaseOriginal?.Invoke();
        // MoveFileEx with REPLACE_EXISTING: the old file goes as the new one arrives. A picture or video reader that is
        // just stopping can hold the file for a moment, so a refused swap is tried again for up to two seconds.
        for (var attempt = 0; ; attempt++)
        {
            try { File.Move(temporary, destination, true); return; }
            catch (Exception error) when (attempt < 20 && error is IOException or UnauthorizedAccessException && File.Exists(temporary)) { Thread.Sleep(100); }
            catch (Exception error) when (error is IOException or UnauthorizedAccessException)
            { throw new IOException($"{Path.GetFileName(destination)} can't be replaced (it may be read-only or open in another program). It was left as it was.", error); }
        }
    }
}
