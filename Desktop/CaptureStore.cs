using System.IO;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Where screenshots and recordings opened in the editor live (0.12.0; inherited v2.5.0 design):
// a private folder in the local temporary folder, owned by this TRT session through a lock file.
// A capture is overwritten with zeros and deleted when the editor lets go of it, or when TRT
// quits; the user keeps a capture by saving it (Original) or exporting it. Only files this store
// created, directly inside its own folder, are ever wiped; redirected files are refused.
internal sealed class CaptureStore : IDisposable
{
    internal const string FolderPrefix = "TinyRedactionTool-Capture-";
    private const string LeaseName = ".session.lock";
    private readonly string tempBase;
    private readonly List<string> files = [];
    private readonly HashSet<string> kept = new(StringComparer.OrdinalIgnoreCase);
    private FileStream? lease;
    public string? Root { get; private set; }
    public IReadOnlyList<string> Files => files;

    public CaptureStore(string? temporaryFolder = null) => tempBase = Path.GetFullPath(temporaryFolder ?? Path.GetTempPath());

    // A new, unused file name such as SCREENSHOT_20261029_143005.png.
    public string NewFile(string stem, string extension)
    {
        if (Root == null)
        {
            if (ManagedPolicy.IsNetwork(tempBase)) throw new IOException("Screen capture needs a local temporary folder.");
            var root = Path.Combine(tempBase, FolderPrefix + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            lease = new FileStream(Path.Combine(root, LeaseName), FileMode.CreateNew, FileAccess.ReadWrite, FileShare.None);
            Root = root;
        }
        var name = $"{stem}_{DateTime.Now:yyyyMMdd_HHmmss}";
        var path = Path.Combine(Root, name + extension);
        for (var i = 2; File.Exists(path) || files.Contains(path, StringComparer.OrdinalIgnoreCase); i++) path = Path.Combine(Root, $"{name}_{i}{extension}");
        files.Add(path);
        return path;
    }
    public bool Owns(string? path) => path != null && Root != null && files.Contains(Path.GetFullPath(path), StringComparer.OrdinalIgnoreCase);
    // Saved or exported: the user has what they wanted from it.
    public void MarkKept(string path) { if (Owns(path)) kept.Add(Path.GetFullPath(path)); }
    public bool IsKept(string path) => kept.Contains(Path.GetFullPath(path));
    public IReadOnlyList<string> Unkept => files.Where(f => !kept.Contains(f) && File.Exists(f)).ToList();

    // Overwrites the capture with zeros, checks the overwrite, then deletes it. A file still open
    // elsewhere (for example a frame being read) is retried briefly before giving up.
    public void Wipe(string path)
    {
        var full = Path.GetFullPath(path);
        if (!Owns(full)) throw new IOException("TRT only wipes captures it made in this session.");
        for (var attempt = 0; ; attempt++)
        {
            try { OverwriteAndDelete(full, Root!); break; }
            catch (IOException ex) when (ex is not CaptureCleanupRefused && attempt < 10 && File.Exists(full)) { Thread.Sleep(150); }
        }
        files.RemoveAll(f => string.Equals(f, full, StringComparison.OrdinalIgnoreCase)); kept.Remove(full);
    }
    // Wipes every capture and removes the folder. Returns the files that could not be wiped.
    public IReadOnlyList<string> WipeAll()
    {
        var failed = new List<string>();
        foreach (var file in files.ToList())
        {
            try { Wipe(file); } catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { failed.Add(file); }
        }
        if (failed.Count == 0 && Root != null)
        {
            lease?.Dispose(); lease = null;
            try { File.Delete(Path.Combine(Root, LeaseName)); Directory.Delete(Root, false); Root = null; }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        }
        return failed;
    }
    public void Dispose() => lease?.Dispose();

    internal static void OverwriteAndDelete(string path, string root)
    {
        var full = Path.GetFullPath(path);
        if (!File.Exists(full)) return;
        ZeroFill(full, root);
        File.Delete(full);
    }
    // Overwrites a capture with zeros and reads it back. Refuses anything outside the capture folder,
    // redirected files and files with a second name (hard link), whose contents belong elsewhere too.
    internal static void ZeroFill(string path, string root)
    {
        var full = Path.GetFullPath(path); var folder = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar);
        if (!string.Equals(Path.GetDirectoryName(full), folder, StringComparison.OrdinalIgnoreCase)) throw new CaptureCleanupRefused("Capture cleanup path rejected.");
        if ((File.GetAttributes(full) & FileAttributes.ReparsePoint) != 0 || (File.GetAttributes(folder) & FileAttributes.ReparsePoint) != 0) throw new CaptureCleanupRefused("Capture cleanup refuses redirected files.");
        using var file = new FileStream(full, FileMode.Open, FileAccess.ReadWrite, FileShare.None, 65536, FileOptions.WriteThrough);
        if (!GetFileInformationByHandle(file.SafeFileHandle, out var info) || info.NumberOfLinks != 1) throw new CaptureCleanupRefused("Capture cleanup refuses a file that has another name (hard link).");
        var length = file.Length; var zero = new byte[65536];
        while (file.Position < length) file.Write(zero, 0, (int)Math.Min(zero.Length, length - file.Position));
        file.Flush(true); file.Position = 0;
        var check = new byte[65536]; int count;
        while ((count = file.Read(check, 0, check.Length)) > 0) if (check.AsSpan(0, count).ContainsAnyExcept((byte)0)) throw new IOException("Capture overwrite could not be verified.");
    }
    internal sealed class CaptureCleanupRefused(string message) : IOException(message);
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct FileInformation { public uint Attributes, CreatedLow, CreatedHigh, AccessedLow, AccessedHigh, WrittenLow, WrittenHigh, VolumeSerial, SizeHigh, SizeLow, NumberOfLinks, IndexHigh, IndexLow; }
    [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
    [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
    private static extern bool GetFileInformationByHandle(Microsoft.Win32.SafeHandles.SafeFileHandle file, out FileInformation information);

    // Capture folders left by a TRT session that ended without cleaning up (its lock file is free).
    public static IReadOnlyList<string> AbandonedFolders(string? temporaryFolder = null)
    {
        var folder = Path.GetFullPath(temporaryFolder ?? Path.GetTempPath());
        var result = new List<string>();
        try
        {
            foreach (var dir in Directory.GetDirectories(folder, FolderPrefix + "*"))
            {
                if ((File.GetAttributes(dir) & FileAttributes.ReparsePoint) != 0) continue;
                var leasePath = Path.Combine(dir, LeaseName);
                try { if (File.Exists(leasePath)) using (new FileStream(leasePath, FileMode.Open, FileAccess.ReadWrite, FileShare.None)) { } result.Add(dir); }
                catch (IOException) { } // In use by a running TRT.
            }
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        return result;
    }
    // 0.28.0: also NEW_ (New pictures, 0.26.0), which leftover cleanup had missed.
    // 3.1.3 (David): everything TRT makes is CAPTURE_; the older names stay so Remove History still clears them.
    internal static readonly string[] OwnPrefixes = ["CAPTURE_", "SCREENSHOT_", "RECORDING_", "PASTED_", "FRAME_", "EDITED_", "NEW_"];
    // Wipes the captures TRT made in an abandoned folder (only its own file names) and removes it.
    public static int WipeAbandoned(string dir)
    {
        var count = 0;
        foreach (var file in Directory.GetFiles(dir))
        {
            var name = Path.GetFileName(file);
            // 0.18.0: also pasted pictures (0.14.0) and captured video frames; 0.19.0: turned working copies.
            if (name == LeaseName || !OwnPrefixes.Any(prefix => name.StartsWith(prefix, StringComparison.Ordinal))) continue;
            OverwriteAndDelete(file, dir); count++;
        }
        var leasePath = Path.Combine(dir, LeaseName); if (File.Exists(leasePath)) File.Delete(leasePath);
        if (Directory.GetFileSystemEntries(dir).Length == 0) Directory.Delete(dir, false);
        return count;
    }
}
