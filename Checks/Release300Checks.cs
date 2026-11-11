using System.IO;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using TinyRedaction.Desktop;

// 3.0.0: the Help manual (David approved it) travels with TRT and opens from Help › Help (F1), the capture bar's menu and
// the notification-area menu, in its own window; the menu reads Help > Help, Settings, About. `--release-300-only`.
internal static class Release300Checks
{
    public static void Run(Action<bool, string> check)
    {
        var manual = HelpManual.ManualPath;
        check(File.Exists(manual), $"the Help manual is beside the program ({manual})");
        var html = File.Exists(manual) ? File.ReadAllText(manual) : "";
        var folder = Path.GetDirectoryName(manual)!;
        var pictures = Regex.Matches(html, "src=\"([^\"]+)\"").Select(m => m.Groups[1].Value).Distinct().ToList();
        var missing = pictures.Where(p => !File.Exists(Path.Combine(folder, p.Replace('/', Path.DirectorySeparatorChar)))).ToList();
        check(pictures.Count > 40 && missing.Count == 0, $"every picture and icon the manual shows is there ({pictures.Count} pictures; missing {string.Join(", ", missing)})");
        var anchors = Regex.Matches(html, "href=\"#([^\"]+)\"").Select(m => m.Groups[1].Value).Distinct().ToList();
        var broken = anchors.Where(a => !html.Contains($"id=\"{a}\"")).ToList();
        check(anchors.Count > 20 && broken.Count == 0, $"every link in the manual's contents goes to a section ({string.Join(", ", broken)})");
        check(!Regex.IsMatch(html, "(src|href)=\"https?:"), "the manual needs nothing from the internet (no outside pictures, styles or scripts)");
        check(!File.Exists(Path.Combine(folder, "images", "places.json")), "the picture-making notes are not shipped");

        // The manual is shown in TRT's own Help window (Release300EditChecks.HelpWindow); no browser is started.
        check(html.Contains("data-theme=\"dark\"") || html.Contains("[data-theme=\"dark\"]"), "the manual can show itself dark or light, as TRT asks");

        var iconLinks = Regex.Matches(html, "<link rel=\"icon\"[^>]*href=\"([^\"]+)\"").Select(m => m.Groups[1].Value).ToList();
        check(iconLinks.Count >= 2 && iconLinks.All(i => File.Exists(Path.Combine(folder, i.Replace('/', Path.DirectorySeparatorChar)))),
            "the Help window has its own icon (TRT with a yellow question mark), in several sizes (David, 3.0.0)");
        check(Regex.Matches(html, "color-scheme: dark;").Count >= 2 && html.Contains("scrollbar-color"), "in Dark, the manual's scroll bars are dark too");
        // The name Windows shows ("Open with", Task Manager, file properties): TinyRedactionTool, not the internal name.
        var details = System.Diagnostics.FileVersionInfo.GetVersionInfo(typeof(MainWindow).Assembly.Location);
        check(details.FileDescription == "TinyRedactionTool" && details.ProductName == "TinyRedactionTool" && details.CompanyName == "David McCabe" && details.ProductVersion?.StartsWith("3.1.2") == true,
            $"Windows calls the program TinyRedactionTool (description {details.FileDescription}, product {details.ProductName})");
        var savedRoot = PictureApp.SoftwareRoot; PictureApp.SoftwareRoot = @"Software\TRT-Checks-300";
        try
        {
            PictureApp.Register();
            using var named = Microsoft.Win32.Registry.CurrentUser.OpenSubKey($@"Software\TRT-Checks-300\Classes\{PictureApp.ProgId}\Application");
            check(named?.GetValue("ApplicationName") as string == "TinyRedactionTool", "TRT's picture-app registration names it TinyRedactionTool for Open With (on a throw-away key)");
            using (var app = Microsoft.Win32.Registry.CurrentUser.OpenSubKey($@"Software\TRT-Checks-300\Classes\{PictureApp.ProgId}\Application", true)) app!.DeleteValue("ApplicationName");
            check(PictureApp.Refresh(), "a registration made by an older TRT (without the name) is brought up to date when TRT starts");
        }
        finally { PictureApp.Remove(); Microsoft.Win32.Registry.CurrentUser.DeleteSubKeyTree(@"Software\TRT-Checks-300", false); PictureApp.SoftwareRoot = savedRoot; }
        // Clean-up (3.0.0): the internal name is plain TinyRedactionTool; projects saved under the old name still open.
        check(typeof(MainWindow).Assembly.GetName().Name == "TinyRedactionTool", "the program's internal name is TinyRedactionTool (was TinyRedactionTool.Wpf.Dev)");
        var fresh = new TinyRedaction.Core.RedactionProject { Media = new(Path.Combine(Path.GetTempPath(), "release300.png"), 1, new string('0', 64), 40, 30, 0, false) };
        var older = TinyRedaction.Core.ProjectStore.Serialize(fresh).Replace("\"TinyRedactionTool\"", "\"TinyRedactionTool.Wpf.Dev\"");
        check(fresh.Application == "TinyRedactionTool" && TinyRedaction.Core.ProjectStore.Deserialize(older) != null, "new projects say TinyRedactionTool, and projects saved by older builds still open");
        var stranger = TinyRedaction.Core.ProjectStore.Serialize(fresh).Replace("\"TinyRedactionTool\"", "\"SomethingElse\"");
        var refused = false; try { TinyRedaction.Core.ProjectStore.Deserialize(stranger); } catch (InvalidDataException) { refused = true; }
        check(refused, "a project made by another program is still refused");
        var savedRun = StartupEntry.RunKey; StartupEntry.RunKey = @"Software\TRT-Checks-300\Run";
        try
        {
            using (var run = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(StartupEntry.RunKey)) run.SetValue(StartupEntry.ValueName, "\"C:\\Gone\\TinyRedactionTool-0.22.0.exe\" --startup");
            check(!StartupEntry.Refresh() && StartupEntry.IsInstalled, "a development run never rewrites the Windows startup entry (a copied .exe does, on a throw-away key here)");
        }
        finally { Microsoft.Win32.Registry.CurrentUser.DeleteSubKeyTree(@"Software\TRT-Checks-300", false); StartupEntry.RunKey = savedRun; }
        // 3.1.1: "Open with TRT" left by an older (deleted) TRT is pointed at this one when TRT starts.
        var savedClasses = ExplorerMenu.ClassesRoot; ExplorerMenu.ClassesRoot = @"Software\TRT-Checks-311\Classes";
        try
        {
            ExplorerMenu.Install();
            check(!ExplorerMenu.IsStale, "a fresh right-click entry starts this TRT");
            using (var old = Microsoft.Win32.Registry.CurrentUser.CreateSubKey($@"{ExplorerMenu.ClassesRoot}\SystemFileAssociations\.mp4\shell\{ExplorerMenu.VerbName}\command"))
                old.SetValue("", "\"C:\\Gone\\TinyRedactionTool-0.13.0.exe\" \"%1\"");
            check(ExplorerMenu.IsStale, "a right-click entry that starts a deleted TRT is noticed (on a throw-away key)");
            check(!ExplorerMenu.Refresh() && ExplorerMenu.IsStale, "a development run never rewrites the right-click entry (a copied .exe does)");
            ExplorerMenu.Install();
            check(!ExplorerMenu.IsStale, "rewriting the entry points every format at this TRT again");
            ExplorerMenu.Remove();
            check(!ExplorerMenu.IsStale && !ExplorerMenu.Refresh(), "with the setting cleared, starting TRT adds nothing to the right-click menu");
        }
        finally { ExplorerMenu.ClassesRoot = savedClasses; Microsoft.Win32.Registry.CurrentUser.DeleteSubKeyTree(@"Software\TRT-Checks-311", false); }
        // 3.1.2: the File menu's order is checked in Release027Checks (with the other menu wording).
        check(MainWindow.AboutText.StartsWith("TinyRedactionTool 3.1.2\n", StringComparison.Ordinal), "the version is 3.1.2 (3.1.1 is published; the File menu order came after)");
    }
}
