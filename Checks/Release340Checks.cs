using System.IO;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 3.4.0 (David): Check for Updates in the About box (only when clicked; GitHub over HTTPS only, every redirect checked;
// only a newer version; the download checked for size, SHA-256 and being TRT of that version; swapped in safely, undone
// if TRT doesn't quit) and the File menu order (Release027Checks). A fake GitHub answers: no real network is used.
// `--release-340-only` runs these.
internal static class Release340Checks
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(3);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("3.4.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    // A pretend GitHub: answers by full address; anything else is a 404. Records every address asked for.
    private sealed class FakeGitHub : HttpMessageHandler
    {
        public readonly Dictionary<string, Func<HttpResponseMessage>> Routes = new();
        public readonly List<string> Asked = [];
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken token)
        {
            var address = request.RequestUri!.ToString(); Asked.Add(address);
            return Task.FromResult(Routes.TryGetValue(address, out var answer) ? answer() : new HttpResponseMessage(HttpStatusCode.NotFound));
        }
        public void Bytes(string address, byte[] content) => Routes[address] = () => new HttpResponseMessage(HttpStatusCode.OK) { Content = new ByteArrayContent(content) };
        public void Redirect(string address, string to) => Routes[address] = () => { var r = new HttpResponseMessage(HttpStatusCode.Found); r.Headers.Location = new Uri(to); return r; };
    }
    private const string Api = "https://api.github.com/repos/mccabedd/tinyredactiontool/releases/latest";
    private static string ReleaseJson(string tag, string asset, long size, string? digest, string download, bool prerelease = false, string? sumsUrl = null) =>
        "{\"tag_name\":\"" + tag + "\",\"draft\":false,\"prerelease\":" + (prerelease ? "true" : "false") + ",\"body\":\"Better saving.\",\"assets\":[" +
        "{\"name\":\"" + asset + "\",\"size\":" + size + (digest != null ? ",\"digest\":\"sha256:" + digest + "\"" : "") + ",\"browser_download_url\":\"" + download + "\"}" +
        (sumsUrl != null ? ",{\"name\":\"SHA256SUMS-" + tag + ".txt\",\"size\":200,\"browser_download_url\":\"" + sumsUrl + "\"}" : "") + "]}";

    public static void Run(string output, Action<bool, string> check)
    {
        // ---- Addresses ----
        bool Refused(string address) { try { Updater.CheckAddress(new Uri(address)); return false; } catch (Updater.UpdateRefused) { return true; } }
        check(!Refused(Api) && !Refused("https://github.com/mccabedd/tinyredactiontool/releases/download/v3.4.0/x.exe") && !Refused("https://objects.githubusercontent.com/x")
              && !Refused("https://release-assets.githubusercontent.com/x"), "GitHub's own addresses over HTTPS are allowed");
        check(Refused("http://api.github.com/x") && Refused("https://example.com/x") && Refused("https://github.com.example.com/x") && Refused("https://api.github.com:8443/x"),
            "plain HTTP, other sites, look-alike names and other ports are refused");

        // ---- The test program: this build's own TinyRedactionTool.exe (a real x64 TRT program, version 3.4.0) ----
        var program = new[] { Path.Combine(AppContext.BaseDirectory, "TinyRedactionTool.exe"), Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "TinyRedaction.Desktop", "debug", "TinyRedactionTool.exe")) }.FirstOrDefault(File.Exists);
        check(program != null, "the test program (this build's TinyRedactionTool.exe) is there: " + program);
        if (program == null) return;
        var bytes = File.ReadAllBytes(program); var sha = Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
        var version = Version.Parse(System.Text.RegularExpressions.Regex.Match(MainWindow.AboutText, @"\d+\.\d+\.\d+").Value);
        var tag = "v" + version.ToString(3); var asset = $"TinyRedactionTool-{version.ToString(3)}.exe";
        var download = $"https://github.com/mccabedd/tinyredactiontool/releases/download/{tag}/{asset}";
        var cdn = "https://release-assets.githubusercontent.com/github-production-release-asset/1/x?sig=1";
        var folder = Path.Combine(output, "release340"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        Updater Make(FakeGitHub fake, Version? current = null) => new(current ?? new Version(3, 3, 0), fake) { MinimumSize = 1024 };
        T Expect<T>(Func<Task<T>> work, out Exception? error) { error = null; try { return Wait(work); } catch (Exception ex) { error = ex; return default!; } }

        var github = new FakeGitHub();
        github.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, sha, download)));
        github.Redirect(download, cdn); github.Bytes(cdn, bytes);
        var release = Wait(() => Make(github).LatestAsync(CancellationToken.None));
        check(release != null && release.Version == version && release.Sha256 == sha && release.Size == bytes.Length && release.Notes == "Better saving.",
            $"a newer release is found with its notes, size and GitHub's SHA-256 ({release?.Version})");
        var target = Path.Combine(folder, "TRT.exe.download");
        Wait(async () => { await Make(github).DownloadAsync(release!, target, null, CancellationToken.None); return true; });
        check(File.Exists(target) && File.ReadAllBytes(target).AsSpan().SequenceEqual(bytes) && github.Asked.Contains(cdn), "it downloads through GitHub's redirect to its download server, and the file is exactly the release's");
        check(Wait(() => Make(github, version).LatestAsync(CancellationToken.None)) == null && Wait(() => Make(github, new Version(9, 0, 0)).LatestAsync(CancellationToken.None)) == null,
            "the same version, or an older one than the running TRT, is never offered");
        var pre = new FakeGitHub(); pre.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, sha, download, prerelease: true)));
        check(Wait(() => Make(pre).LatestAsync(CancellationToken.None)) == null, "a pre-release isn't offered");

        // ---- Refusals: nothing is kept ----
        void Refuses(string name, FakeGitHub fake, string why)
        {
            var file = Path.Combine(folder, name);
            var found = Expect(() => Make(fake).LatestAsync(CancellationToken.None), out var error);
            if (error == null && found != null) Expect(async () => { await Make(fake).DownloadAsync(found, file, null, CancellationToken.None); return true; }, out error);
            check(error is Updater.UpdateRefused && !File.Exists(file) && !File.Exists(file + ".partial"), $"{why} ({error?.Message})");
        }
        var away = new FakeGitHub(); away.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, sha, download))); away.Redirect(download, "https://downloads.example.com/trt.exe"); away.Bytes("https://downloads.example.com/trt.exe", bytes);
        Refuses("away.exe", away, "a redirect away from GitHub is refused and nothing is downloaded from there");
        check(!away.Asked.Contains("https://downloads.example.com/trt.exe"), "TRT never even asks the other site");
        var plain = new FakeGitHub(); plain.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, sha, download))); plain.Redirect(download, "http://objects.githubusercontent.com/x");
        Refuses("plain.exe", plain, "a redirect to plain HTTP is refused");
        var wrongHash = new FakeGitHub(); wrongHash.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, new string('0', 64), download))); wrongHash.Bytes(download, bytes);
        Refuses("hash.exe", wrongHash, "a download that doesn't match GitHub's SHA-256 is deleted");
        var tampered = (byte[])bytes.Clone(); tampered[^10] ^= 0xFF;
        var changed = new FakeGitHub(); changed.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, sha, download))); changed.Bytes(download, tampered);
        Refuses("changed.exe", changed, "a file changed on the way (same size) is deleted");
        var shortFile = new FakeGitHub(); shortFile.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, sha, download))); shortFile.Bytes(download, bytes[..(bytes.Length / 2)]);
        Refuses("short.exe", shortFile, "a download that is shorter than GitHub lists is deleted");
        var noHash = new FakeGitHub(); noHash.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, null, download))); noHash.Bytes(download, bytes);
        Refuses("nohash.exe", noHash, "a release with no SHA-256 for the program isn't downloaded");
        var other = typeof(Release340Checks).Assembly.Location; // A real program file, but not TRT x64 of that version.
        var otherBytes = File.ReadAllBytes(other); var otherSha = Convert.ToHexString(SHA256.HashData(otherBytes)).ToLowerInvariant();
        var notTrt = new FakeGitHub(); notTrt.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, otherBytes.Length, otherSha, download))); notTrt.Bytes(download, otherBytes);
        Refuses("nottrt.exe", notTrt, "a download that matches its SHA-256 but isn't a 64-bit TRT of that version is deleted");
        // Older releases without GitHub's SHA-256 field: the SHA256SUMS file attached to the same release.
        var sums = "https://github.com/mccabedd/tinyredactiontool/releases/download/" + tag + "/SHA256SUMS-" + tag + ".txt";
        var listed = new FakeGitHub(); listed.Bytes(Api, Encoding.UTF8.GetBytes(ReleaseJson(tag, asset, bytes.Length, null, download, sumsUrl: sums)));
        listed.Bytes(sums, Encoding.UTF8.GetBytes($"{sha}  {asset}\n0000000000000000000000000000000000000000000000000000000000000000  TinyRedactionTool-{version.ToString(3)}-SOURCE.zip\n"));
        check(Wait(() => Make(listed).LatestAsync(CancellationToken.None))?.Sha256 == sha, "without GitHub's SHA-256 field, the SHA256SUMS file of the same release is used");

        // ---- Swapping the program ----
        var exe = Path.Combine(folder, "TinyRedactionTool-3.3.0.exe"); File.WriteAllText(exe, "old"); File.WriteAllText(UpdateSwap.DownloadPath(exe), "new");
        UpdateSwap.Swap(exe, UpdateSwap.DownloadPath(exe));
        check(File.ReadAllText(exe) == "new" && File.ReadAllText(UpdateSwap.OldPath(exe)) == "old" && !File.Exists(UpdateSwap.DownloadPath(exe)),
            "the new program takes the old one's name (shortcuts keep working); the old one is kept as .old");
        UpdateSwap.Undo(exe, UpdateSwap.DownloadPath(exe));
        check(File.ReadAllText(exe) == "old" && !File.Exists(UpdateSwap.OldPath(exe)) && File.ReadAllText(UpdateSwap.DownloadPath(exe)) == "new", "undoing puts the old program back and keeps the download");
        File.Delete(UpdateSwap.DownloadPath(exe));
        var failed = false; try { UpdateSwap.Swap(exe, UpdateSwap.DownloadPath(exe)); } catch (IOException) { failed = true; }
        check(failed && File.ReadAllText(exe) == "old" && !File.Exists(UpdateSwap.OldPath(exe)), "a swap that fails half-way puts the old program straight back");
        var (besideTarget, beside) = UpdateSwap.DownloadTarget(exe, asset);
        check(beside && besideTarget == UpdateSwap.DownloadPath(exe), "the download goes beside the program when that folder can be written");

        // ---- The whole flow, with the About box ----
        var temp = Path.Combine(output, "release340-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release340-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ShowActivated = false, ConfirmKeepQuestion = (_, _, _) => false };
        var told = new List<string>(); var asked = new List<string>(); var answer = true; var started = 0;
        controller.AskUpdate = (_, text, _) => { asked.Add(text); return answer; };
        controller.TellUpdate = (_, text, _) => told.Add(text);
        controller.StartProgram = _ => { started++; return null; };
        controller.NewUpdater = () => Make(github);
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var about = new AboutWindow("3.4.0", controller.CheckForUpdatesAsync) { Left = -20000, Top = 0, ShowActivated = false, WindowStartupLocation = WindowStartupLocation.Manual };
            about.Show(); about.UpdateLayout();
            var button = (Button)LogicalTreeHelper.FindLogicalNode(about, "CheckUpdatesButton");
            check(button is { IsEnabled: true, Content: "Check for Updates" }, "the About box has Check for Updates");
            var bare = new AboutWindow("3.4.0") { Left = -20000, ShowActivated = false }; bare.Show();
            check(((Button)LogicalTreeHelper.FindLogicalNode(bare, "CheckUpdatesButton")).IsEnabled == false, "without the capture side of TRT the button is off");
            bare.Close();
            var askedBefore = github.Asked.Count;
            var newAbout = new AboutWindow("3.4.0", controller.CheckForUpdatesAsync); // Opening the About box asks nothing.
            check(github.Asked.Count == askedBefore, "opening the About box makes no network request: only the button does");

            // A development build (no single .exe to replace): downloaded, checked and left in TRT's temporary update folder.
            answer = true; told.Clear(); asked.Clear();
            var result = Wait(() => controller.CheckForUpdatesAsync(about, text => about.UpdateStatus.Text = text));
            var kept = Path.Combine(Path.GetTempPath(), "TinyRedactionTool-Update", asset);
            check(asked.Count == 1 && asked[0].Contains("Better saving.") && told.Count == 1 && told[0].Contains(kept) && File.ReadAllBytes(kept).AsSpan().SequenceEqual(bytes) && started == 0,
                $"it asks first (showing the release notes), then downloads and checks; a copy that can't replace itself says where the file is ({result})");
            File.Delete(kept);
            answer = false; asked.Clear();
            check(Wait(() => controller.CheckForUpdatesAsync(about, _ => { })) == "Not updated." && asked.Count == 1, "answering No downloads nothing");
            controller.NewUpdater = () => Make(github, version);
            check(Wait(() => controller.CheckForUpdatesAsync(about, _ => { })).StartsWith("You have the latest version"), "with nothing newer it says so");

            // The single .exe: swapped in, then TRT quits; here the user keeps unsaved work, so TRT stays and the swap is undone.
            controller.NewUpdater = () => Make(github);
            var program2 = Path.Combine(folder, "app", "TinyRedactionTool.exe"); Directory.CreateDirectory(Path.GetDirectoryName(program2)!); File.WriteAllText(program2, "running");
            controller.ProgramPath = program2; answer = true;
            var picture = Path.Combine(folder, "work.png"); { var e = new System.Windows.Media.Imaging.PngBitmapEncoder(); e.Frames.Add(System.Windows.Media.Imaging.BitmapFrame.Create(Release320Checks.TextPicture())); using var s = File.Create(picture); e.Save(s); }
            var editor = controller.OpenEditor();
            Wait(() => editor.OpenPathAsync(picture));
            var preview = (PreviewSurface)editor.FindName("Preview");
            var region = new Region { Name = "R", Start = 0, End = 0 }; region.PutManual(0, new(10, 10, 20, 20)); preview.Project.Regions.Add(region); // Unsaved work.
            result = Wait(() => controller.CheckForUpdatesAsync(null, _ => { }));
            check(!controller.IsQuitting && started == 0 && File.ReadAllText(program2) == "running" && !File.Exists(UpdateSwap.OldPath(program2))
                  && File.ReadAllBytes(UpdateSwap.DownloadPath(program2)).AsSpan().SequenceEqual(bytes) && editor.IsVisible,
                $"when TRT is kept open for unsaved work, the update is undone: the program is as it was and the checked download is kept ({result})");
            editor.ConfirmKeepQuestion = (_, _, _) => true;
            about.Close();
        }
        finally { AppSettings.Path = savedPath; foreach (var w in Application.Current.Windows.OfType<MainWindow>().ToList()) { w.ConfirmKeepQuestion = (_, _, _) => true; w.Close(); } controller.Store.WipeAll(); controller.Dispose(); }
    }
}
