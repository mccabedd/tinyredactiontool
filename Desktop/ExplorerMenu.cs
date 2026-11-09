using System.IO;
using System.IO.Pipes;
using System.Text;
using Microsoft.Win32;

namespace TinyRedaction.Desktop;

// "Open with TRT" in File Explorer's right-click menu (0.13.0). Added or removed only when the user
// ticks or clears it in Settings, for the current Windows user only (no administrator rights):
// one entry per supported format under HKCU\Software\Classes\SystemFileAssociations.
// On Windows 11 it appears under "Show more options".
internal static class ExplorerMenu
{
    internal const string VerbName = "TinyRedactionTool.Open", Label = "Open with TRT";
    internal static readonly string[] Extensions =
    [
        ".png", ".jpg", ".jpeg", ".jpe", ".bmp", ".tif", ".tiff", ".gif", ".webp", ".apng", ".tga", ".dds", ".exr", ".hdr", ".dpx", ".jp2", ".j2k", ".j2c", ".jpc", ".jls", ".psd", ".pcx", ".qoi", ".avif", ".heic", ".heif",
        ".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm", ".wmv", ".asf", ".mpg", ".mpeg", ".mpe", ".vob", ".ts", ".mts", ".m2ts", ".m2t", ".flv", ".3gp", ".3g2", ".f4v", ".ogv", ".rm", ".rmvb", ".mxf", ".wtv", ".dv", ".mjpeg", ".mjpg", ".mlv", ".r3d",
    ];
    // Checks point this at a throw-away key.
    internal static string ClassesRoot { get; set; } = @"Software\Classes";
    private static string VerbKey(string extension) => $@"{ClassesRoot}\SystemFileAssociations\{extension}\shell\{VerbName}";

    // How Explorer starts this build: the standalone .exe directly, or dotnet with the development .dll.
    internal static string Command
    {
        get
        {
            var process = Environment.ProcessPath ?? "";
            var library = typeof(ExplorerMenu).Assembly.Location;
            return Path.GetFileName(process).Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase) && library.Length > 0
                ? $"\"{process}\" \"{library}\" \"%1\"" : $"\"{process}\" \"%1\"";
        }
    }
    public static bool IsInstalled => Registry.CurrentUser.OpenSubKey(VerbKey(".png")) is { } key && Dispose(key);
    private static bool Dispose(RegistryKey key) { key.Dispose(); return true; }
    public static void Install()
    {
        var icon = Environment.ProcessPath ?? "";
        foreach (var extension in Extensions)
        {
            using var verb = Registry.CurrentUser.CreateSubKey(VerbKey(extension));
            verb.SetValue("", Label); verb.SetValue("Icon", icon);
            using var command = verb.CreateSubKey("command");
            command.SetValue("", Command);
        }
    }
    public static void Remove()
    {
        foreach (var extension in Extensions) Registry.CurrentUser.DeleteSubKeyTree(VerbKey(extension), false);
    }
    // 3.1.1 (David: right-click gave "Application not found" after the 0.13.0 .exe was deleted): when the entry is
    // there and this TRT runs from somewhere else, point every format at this .exe. True if changed.
    public static bool Refresh()
    {
        if (Path.GetFileName(Environment.ProcessPath)?.Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase) == true) return false; // A development run.
        if (!IsStale) return false;
        Install(); return true;
    }
    // The entry is there, but some format starts another program (an older or deleted TRT).
    internal static bool IsStale
    {
        get
        {
            if (!IsInstalled) return false;
            var command = Command;
            foreach (var extension in Extensions)
            {
                using var key = Registry.CurrentUser.OpenSubKey(VerbKey(extension) + @"\command");
                if (key?.GetValue("") as string != command) return true;
            }
            return false;
        }
    }
}

// The default app for pictures (0.25.0, David; pictures only, not videos). Ticking it in Settings registers TRT for
// this Windows user as a program that opens pictures, the way picture viewers do (HKCU\Software\Classes and
// RegisteredApplications, no administrator rights), then opens Windows' Default apps page at TRT. Windows 10 and 11
// don't let a program make itself the default: one click on "Set default" there does it. Clearing it removes
// TRT's registration again (Windows then asks which app to use).
internal static class PictureApp
{
    internal const string ProgId = "TinyRedactionTool.Picture", RegisteredName = "TinyRedactionToolWPF", AppName = "TinyRedactionTool";
    // Checks point this at a throw-away key.
    internal static string SoftwareRoot { get; set; } = "Software";
    private static string Classes => $@"{SoftwareRoot}\Classes";
    internal static string CapabilitiesKey => $@"{SoftwareRoot}\{RegisteredName}\Capabilities";
    internal static string CommandKey => $@"{Classes}\{ProgId}\shell\open\command";
    internal static IReadOnlyList<string> Extensions => MainWindow.PictureExtensions;
    public static bool IsRegistered { get { using var key = Registry.CurrentUser.OpenSubKey(CommandKey); return key?.GetValue("") is string; } }
    public static void Register()
    {
        var icon = Environment.ProcessPath ?? "";
        using (var type = Registry.CurrentUser.CreateSubKey($@"{Classes}\{ProgId}"))
        {
            type.SetValue("", "Picture"); type.SetValue("FriendlyTypeName", "Picture (TinyRedactionTool)");
            using (var defaultIcon = type.CreateSubKey("DefaultIcon")) defaultIcon.SetValue("", $"\"{icon}\",0");
            using var command = type.CreateSubKey(@"shell\open\command");
            command.SetValue("", ExplorerMenu.Command);
            // 3.0.0 (David: "Open with" showed the old internal name): the name and icon Windows shows for TRT.
            using var application = type.CreateSubKey("Application");
            application.SetValue("ApplicationName", AppName); application.SetValue("ApplicationIcon", $"\"{icon}\",0");
        }
        if (Path.GetFileName(icon) is { Length: > 0 } exe && !exe.Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase))
        {
            using (var app = Registry.CurrentUser.CreateSubKey($@"{Classes}\Applications\{exe}")) app.SetValue("FriendlyAppName", AppName);
            // Windows remembers the name it last read from this .exe; an older TRT at the same place told it the old one.
            using var names = Registry.CurrentUser.OpenSubKey($@"{Classes}\Local Settings\Software\Microsoft\Windows\Shell\MuiCache", true);
            if (names?.GetValue(icon + ".FriendlyAppName") is string old && old != AppName) names.SetValue(icon + ".FriendlyAppName", AppName);
        }
        using (var capabilities = Registry.CurrentUser.CreateSubKey(CapabilitiesKey))
        {
            capabilities.SetValue("ApplicationName", "TinyRedactionTool");
            capabilities.SetValue("ApplicationDescription", "Open pictures, redact and annotate them, and export them without hidden details.");
            capabilities.SetValue("ApplicationIcon", $"\"{icon}\",0");
            using var associations = capabilities.CreateSubKey("FileAssociations");
            foreach (var extension in Extensions) associations.SetValue(extension, ProgId);
        }
        foreach (var extension in Extensions)
        {
            using var openWith = Registry.CurrentUser.CreateSubKey($@"{Classes}\{extension}\OpenWithProgids");
            openWith.SetValue(ProgId, "");
        }
        using (var registered = Registry.CurrentUser.CreateSubKey($@"{SoftwareRoot}\RegisteredApplications")) registered.SetValue(RegisteredName, CapabilitiesKey);
    }
    public static void Remove()
    {
        Registry.CurrentUser.DeleteSubKeyTree($@"{Classes}\{ProgId}", false);
        Registry.CurrentUser.DeleteSubKeyTree($@"{SoftwareRoot}\{RegisteredName}", false);
        if (Path.GetFileName(Environment.ProcessPath) is { Length: > 0 } exe && !exe.Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase))
            Registry.CurrentUser.DeleteSubKeyTree($@"{Classes}\Applications\{exe}", false);
        foreach (var extension in Extensions) { using var openWith = Registry.CurrentUser.OpenSubKey($@"{Classes}\{extension}\OpenWithProgids", true); openWith?.DeleteValue(ProgId, false); }
        using var registered = Registry.CurrentUser.OpenSubKey($@"{SoftwareRoot}\RegisteredApplications", true);
        registered?.DeleteValue(RegisteredName, false);
    }
    // A newer TRT started from another place (a new standalone .exe): point the registration at it. True if changed.
    public static bool Refresh()
    {
        if (!IsRegistered) return false;
        using (var key = Registry.CurrentUser.OpenSubKey(CommandKey))
        using (var named = Registry.CurrentUser.OpenSubKey($@"{Classes}\{ProgId}\Application")) // 3.0.0: older registrations had no name.
            if (key?.GetValue("") as string == ExplorerMenu.Command && named?.GetValue("ApplicationName") as string == AppName) return false;
        Register(); return true;
    }
    // Tells File Explorer the file types changed, then opens Windows' Default apps page at TRT.
    public static void Announce() => SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero);
    public static void OpenDefaultApps() =>
        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo($"ms-settings:defaultapps?registeredAppUser={RegisteredName}") { UseShellExecute = true });
    [System.Runtime.InteropServices.DllImport("shell32.dll")] private static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);
}

// Start TRT with Windows (0.18.0, David): a value under HKCU\...\Run, added or removed only when the user ticks
// or clears it in Settings (this Windows user only). TRT then starts with "--startup": quietly, in the
// notification area, without showing the capture bar.
internal static class StartupEntry
{
    internal const string ValueName = "TinyRedactionTool", Argument = "--startup";
    // Checks point this at a throw-away key.
    internal static string RunKey { get; set; } = @"Software\Microsoft\Windows\CurrentVersion\Run";
    internal static string Command
    {
        get
        {
            var process = Environment.ProcessPath ?? "";
            var library = typeof(StartupEntry).Assembly.Location;
            return Path.GetFileName(process).Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase) && library.Length > 0
                ? $"\"{process}\" \"{library}\" {Argument}" : $"\"{process}\" {Argument}";
        }
    }
    public static bool IsInstalled { get { using var key = Registry.CurrentUser.OpenSubKey(RunKey); return key?.GetValue(ValueName) is string; } }
    public static void Install() { using var key = Registry.CurrentUser.CreateSubKey(RunKey); key.SetValue(ValueName, Command); }
    public static void Remove() { using var key = Registry.CurrentUser.OpenSubKey(RunKey, true); key?.DeleteValue(ValueName, false); }
    // 3.0.0 clean-up: when "Start TRT When Windows Starts" is ticked and this TRT runs from somewhere else (a newer .exe,
    // or the old one was deleted), point the entry here, so Windows doesn't try to start a missing program. True if changed.
    public static bool Refresh()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKey);
        if (key?.GetValue(ValueName) is not string current || current == Command) return false;
        if (Path.GetFileName(Environment.ProcessPath)?.Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase) == true) return false; // A development run.
        Install(); return true;
    }
}

// One TRT at a time (0.13.0; inherited single-instance behaviour). A second start, for example from
// "Open with TRT", hands its file to the running TRT over a pipe only this Windows user can open,
// then exits.
internal sealed class SingleInstance : IDisposable
{
    private static readonly string Name = $"TinyRedactionTool3.{Environment.UserName}"; // Not the original TRT's name: they are different programs.
    private readonly Mutex mutex;
    private readonly CancellationTokenSource stop = new();
    public bool IsFirst { get; }
    public SingleInstance()
    {
        mutex = new Mutex(true, @"Local\" + Name, out var created);
        IsFirst = created;
    }
    // In the first TRT: receive "open <path>" or "show" from later starts.
    public void Listen(Action<string?> received)
    {
        _ = Task.Run(async () =>
        {
            while (!stop.IsCancellationRequested)
            {
                try
                {
                    await using var server = new NamedPipeServerStream(Name, PipeDirection.In, 1, PipeTransmissionMode.Byte, PipeOptions.Asynchronous | PipeOptions.CurrentUserOnly);
                    await server.WaitForConnectionAsync(stop.Token);
                    using var reader = new StreamReader(server, Encoding.UTF8);
                    var line = await reader.ReadLineAsync(stop.Token);
                    if (line == "show") received(null);
                    else if (line?.StartsWith("open ", StringComparison.Ordinal) == true) received(line[5..]);
                }
                catch (OperationCanceledException) { break; }
                catch (IOException) { }
            }
        });
    }
    // In a later start: pass the file (or just "show") to the running TRT.
    public static bool Send(string? path)
    {
        try
        {
            using var client = new NamedPipeClientStream(".", Name, PipeDirection.Out, PipeOptions.CurrentUserOnly);
            client.Connect(3000);
            AllowSetForegroundWindow(-1); // Lets the running TRT bring its editor to the front.
            using var writer = new StreamWriter(client, new UTF8Encoding(false));
            writer.WriteLine(path == null ? "show" : "open " + path);
            return true;
        }
        catch (Exception ex) when (ex is IOException or TimeoutException or UnauthorizedAccessException) { return false; }
    }
    public void Dispose() { stop.Cancel(); if (IsFirst) mutex.ReleaseMutex(); mutex.Dispose(); }
    [System.Runtime.InteropServices.DllImport("user32.dll")] [return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)] private static extern bool AllowSetForegroundWindow(int process);
}
