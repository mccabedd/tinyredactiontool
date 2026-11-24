using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text.Json;

namespace TinyRedaction.Desktop;

// Check for Updates (3.4.0, David). Runs only when the user clicks it in the About box: TRT makes no network connection
// otherwise. It talks only to GitHub's own addresses over HTTPS (every redirect is checked; anything else is refused),
// asks for the latest release of this repository, offers it only when it is newer than the running version, and keeps
// the download only when it is the expected program: the size and SHA-256 GitHub publishes for it, a Windows x64
// program named TinyRedactionTool with that version. Swapping it in is UpdateSwap's job.
// (Not yet: a signature from a key kept off GitHub, and a policy switch to turn this off. David, 24 Nov: later.)
internal sealed class Updater(Version current, HttpMessageHandler? handler = null)
{
    public const string Repository = "mccabedd/tinyredactiontool";
    internal static readonly string[] AllowedHosts = ["api.github.com", "github.com", "objects.githubusercontent.com", "release-assets.githubusercontent.com"];
    internal const long MaxProgramSize = 1L << 30;
    internal long MinimumSize { get; init; } = 1L << 20; // Checks serve a smaller test program.
    private const int MaxRedirects = 5;

    public sealed record Release(Version Version, string Tag, string Notes, string AssetName, Uri Download, long Size, string Sha256);
    internal sealed class UpdateRefused(string message) : IOException(message);

    public static Version CurrentVersion => Version.Parse(System.Text.RegularExpressions.Regex.Match(MainWindow.AboutText, @"\d+\.\d+\.\d+").Value);
    // The standalone single-file .exe can replace itself; a development build (TinyRedactionTool.dll beside it) can't.
    public static bool CanReplaceItself => string.IsNullOrEmpty(typeof(Updater).Assembly.Location) && Environment.ProcessPath is { Length: > 0 };

    private HttpClient Client()
    {
        var client = new HttpClient(handler ?? new SocketsHttpHandler { AllowAutoRedirect = false, AutomaticDecompression = DecompressionMethods.None }, disposeHandler: handler == null)
        { Timeout = TimeSpan.FromMinutes(10) };
        client.DefaultRequestHeaders.UserAgent.ParseAdd("TinyRedactionTool-Updater");
        return client;
    }
    // HTTPS to GitHub only, before every request and every redirect.
    internal static void CheckAddress(Uri address)
    {
        if (address.Scheme != Uri.UriSchemeHttps) throw new UpdateRefused($"TRT only downloads updates over HTTPS. It was sent to {address.Scheme}://{address.Host}, so nothing was downloaded.");
        if (!AllowedHosts.Contains(address.IdnHost.ToLowerInvariant())) throw new UpdateRefused($"TRT only downloads updates from GitHub. It was sent to {address.Host}, so nothing was downloaded.");
        if (!address.IsDefaultPort) throw new UpdateRefused("TRT only downloads updates from GitHub's usual address, so nothing was downloaded.");
    }
    private static async Task<HttpResponseMessage> GetAsync(HttpClient client, Uri address, string accept, CancellationToken token)
    {
        for (var hop = 0; ; hop++)
        {
            CheckAddress(address);
            var request = new HttpRequestMessage(HttpMethod.Get, address);
            request.Headers.Accept.ParseAdd(accept);
            var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, token);
            if ((int)response.StatusCode is >= 300 and < 400 && response.Headers.Location is { } next)
            {
                response.Dispose();
                if (hop >= MaxRedirects) throw new UpdateRefused("GitHub sent TRT round too many addresses, so nothing was downloaded.");
                address = next.IsAbsoluteUri ? next : new Uri(address, next);
                continue;
            }
            if (!response.IsSuccessStatusCode)
            {
                var code = (int)response.StatusCode; response.Dispose();
                throw new IOException(code == 404 ? "GitHub has no release of TRT to offer yet." : $"GitHub answered {code}. Try again later.");
            }
            return response;
        }
    }

    // The latest release, or null when it isn't newer than the running TRT.
    public async Task<Release?> LatestAsync(CancellationToken token)
    {
        using var client = Client();
        using var response = await GetAsync(client, new Uri($"https://api.github.com/repos/{Repository}/releases/latest"), "application/vnd.github+json", token);
        if (response.Content.Headers.ContentLength > 4 << 20) throw new UpdateRefused("GitHub's answer was unexpectedly large, so TRT stopped.");
        using var json = JsonDocument.Parse(await ReadLimitedAsync(response, 4 << 20, token));
        var root = json.RootElement;
        if (Flag(root, "draft") || Flag(root, "prerelease")) return null;
        var tag = Text(root, "tag_name");
        if (!TryVersion(tag, out var version)) throw new UpdateRefused($"The latest release ({tag}) has no version number TRT understands.");
        if (version <= current) return null; // Never an older (or the same) version.
        var name = $"TinyRedactionTool-{version.ToString(3)}.exe";
        if (!root.TryGetProperty("assets", out var assets) || assets.ValueKind != JsonValueKind.Array) throw new UpdateRefused("The latest release has no files attached.");
        JsonElement? exe = null, sums = null;
        foreach (var asset in assets.EnumerateArray())
        {
            var assetName = Text(asset, "name");
            if (assetName == name) exe = asset;
            else if (assetName == $"SHA256SUMS-v{version.ToString(3)}.txt") sums = asset;
        }
        if (exe is not { } program) throw new UpdateRefused($"The latest release ({tag}) has no {name}.");
        var size = program.TryGetProperty("size", out var s) && s.TryGetInt64(out var bytes) ? bytes : 0;
        if (size < MinimumSize || size > MaxProgramSize) throw new UpdateRefused($"{name} on GitHub isn't the size of a TRT program, so it wasn't downloaded.");
        var download = new Uri(Text(program, "browser_download_url"));
        CheckAddress(download);
        // GitHub's own SHA-256 of the file; for older releases without it, the SHA256SUMS file attached to the same release.
        var digest = Text(program, "digest");
        var sha = digest.StartsWith("sha256:", StringComparison.OrdinalIgnoreCase) ? digest[7..] : sums is { } list ? await HashFromListAsync(client, list, name, token) : "";
        if (sha.Length != 64 || !sha.All(Uri.IsHexDigit)) throw new UpdateRefused($"GitHub gives no SHA-256 for {name}, so TRT can't check it and didn't download it.");
        return new Release(version, tag, Text(root, "body"), name, download, size, sha.ToLowerInvariant());
    }
    private static async Task<string> HashFromListAsync(HttpClient client, JsonElement list, string name, CancellationToken token)
    {
        var address = new Uri(Text(list, "browser_download_url"));
        using var response = await GetAsync(client, address, "application/octet-stream", token);
        foreach (var line in (await ReadLimitedAsync(response, 64 << 10, token)).Split('\n'))
        {
            var parts = line.Trim().Split((char[]?)null, 2, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 2 && parts[1].TrimStart('*') == name) return parts[0];
        }
        return "";
    }

    // Downloads the release into destination (a partial file is never kept), checking the size and SHA-256 as it goes,
    // then that it is a TRT program of that version. Anything wrong: the file is deleted and the reason thrown.
    public async Task DownloadAsync(Release release, string destination, IProgress<double>? progress, CancellationToken token)
    {
        var partial = destination + ".partial";
        try
        {
            using var client = Client();
            using (var response = await GetAsync(client, release.Download, "application/octet-stream", token))
            {
                if (response.Content.Headers.ContentLength is { } announced && announced != release.Size) throw new UpdateRefused("The download isn't the size GitHub lists for it, so it was deleted.");
                await using var input = await response.Content.ReadAsStreamAsync(token);
                await using var output = new FileStream(partial, FileMode.Create, FileAccess.Write, FileShare.None, 1 << 16, true);
                using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
                var buffer = new byte[1 << 16]; long total = 0; int read;
                while ((read = await input.ReadAsync(buffer, token)) > 0)
                {
                    total += read;
                    if (total > release.Size) throw new UpdateRefused("The download is larger than GitHub lists, so it was deleted.");
                    hash.AppendData(buffer, 0, read); await output.WriteAsync(buffer.AsMemory(0, read), token);
                    progress?.Report(total / (double)release.Size);
                }
                if (total != release.Size) throw new UpdateRefused("The download stopped early, so it was deleted. Try again.");
                if (!string.Equals(Convert.ToHexString(hash.GetHashAndReset()), release.Sha256, StringComparison.OrdinalIgnoreCase))
                    throw new UpdateRefused("The download doesn't match the SHA-256 GitHub publishes for it, so it was deleted.");
            }
            CheckProgram(partial, release.Version);
            if (File.Exists(destination)) File.Delete(destination);
            File.Move(partial, destination);
        }
        finally { if (File.Exists(partial)) File.Delete(partial); }
    }
    // A Windows x64 program (MZ, PE, AMD64) whose version details say TinyRedactionTool and the release's version.
    internal static void CheckProgram(string path, Version version)
    {
        using (var file = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
        using (var reader = new BinaryReader(file))
        {
            if (file.Length < 1024 || reader.ReadUInt16() != 0x5A4D) throw new UpdateRefused("The download isn't a Windows program, so it was deleted.");
            file.Position = 0x3C; var pe = reader.ReadInt32();
            if (pe <= 0 || pe > file.Length - 6) throw new UpdateRefused("The download isn't a Windows program, so it was deleted.");
            file.Position = pe;
            if (reader.ReadUInt32() != 0x00004550 || reader.ReadUInt16() != 0x8664) throw new UpdateRefused("The download isn't a 64-bit Windows program, so it was deleted.");
        }
        var details = FileVersionInfo.GetVersionInfo(path);
        if (details.ProductName != "TinyRedactionTool" || !TryVersion(details.ProductVersion, out var inside) || inside != version)
            throw new UpdateRefused($"The download isn't TinyRedactionTool {version.ToString(3)} (it says {details.ProductName} {details.ProductVersion}), so it was deleted.");
    }

    internal static bool TryVersion(string? text, out Version version)
    {
        var match = System.Text.RegularExpressions.Regex.Match(text ?? "", @"^v?(\d+)\.(\d+)\.(\d+)");
        version = match.Success ? new Version(int.Parse(match.Groups[1].Value), int.Parse(match.Groups[2].Value), int.Parse(match.Groups[3].Value)) : new Version();
        return match.Success;
    }
    private static string Text(JsonElement element, string name) => element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() ?? "" : "";
    private static bool Flag(JsonElement element, string name) => element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.True;
    private static async Task<string> ReadLimitedAsync(HttpResponseMessage response, int limit, CancellationToken token)
    {
        await using var stream = await response.Content.ReadAsStreamAsync(token);
        using var memory = new MemoryStream(); var buffer = new byte[8192]; int read;
        while ((read = await stream.ReadAsync(buffer, token)) > 0) { if (memory.Length + read > limit) throw new UpdateRefused("GitHub's answer was unexpectedly large, so TRT stopped."); memory.Write(buffer, 0, read); }
        return System.Text.Encoding.UTF8.GetString(memory.ToArray());
    }
}

// Putting the checked download in place of the running .exe (3.4.0): Windows lets a running program
// be renamed, so the old .exe becomes <name>.old (kept, to go back), the new one takes its name (shortcuts, the startup
// entry and "Open with" keep working), and if anything fails the old one is put back. Undo is for when TRT then can't
// close (the user kept unsaved work open).
internal static class UpdateSwap
{
    public static string OldPath(string exe) => exe + ".old";
    public static string DownloadPath(string exe) => exe + ".download";
    public static void Swap(string exe, string download)
    {
        var old = OldPath(exe);
        if (File.Exists(old)) File.Delete(old);
        File.Move(exe, old);
        try { File.Move(download, exe); }
        catch { File.Move(old, exe); throw; }
    }
    public static void Undo(string exe, string download)
    {
        var old = OldPath(exe);
        if (!File.Exists(old)) return;
        if (File.Exists(exe)) File.Move(exe, download, true);
        File.Move(old, exe);
    }
    // Where to put the download: beside the .exe when that folder can be written, else TRT's own temporary folder.
    public static (string Path, bool BesideProgram) DownloadTarget(string? exe, string name)
    {
        if (exe != null && CanReplaceIn(exe)) return (DownloadPath(exe), true);
        var folder = Path.Combine(Path.GetTempPath(), "TinyRedactionTool-Update"); Directory.CreateDirectory(folder);
        return (Path.Combine(folder, name), false);
    }
    private static bool CanReplaceIn(string exe)
    {
        try
        {
            var probe = Path.Combine(Path.GetDirectoryName(exe)!, ".trt-update-" + Guid.NewGuid().ToString("N"));
            using (new FileStream(probe, FileMode.CreateNew, FileAccess.Write, FileShare.None, 1, FileOptions.DeleteOnClose)) { }
            return true;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { return false; }
    }
}
