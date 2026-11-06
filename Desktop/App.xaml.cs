using System.IO;
using System.Windows;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;
public partial class App : Application
{
    static App()
    {
        ToolTipTiming.Apply();
        WindowTheme.Register(); // 0.28.0: dark title bars in Dark.
        // 0.26.0: text selections drawn behind the text, so File info's can be solid blue with white text.
        AppContext.SetSwitch("Switch.System.Windows.Controls.Text.UseAdornerForTextboxSelectionRendering", false);
    }
    internal bool StartDesktopWindow { get; init; } = true;
    private CaptureController? captures;
    private SingleInstance? instance;
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        if (!StartDesktopWindow) return; // Integration checks host their own windows.
        try
        {
            // Arguments: [--managed-policy <local policy.json>] [file to open] (0.13.0: "Open with TRT").
            string? policyPath = null, file = null;
            var args = e.Args.ToList();
            if (args.Count >= 1 && args[0] == "--managed-policy")
            {
                if (args.Count < 2) throw new ArgumentException("Use --managed-policy <local policy.json>.");
                policyPath = args[1]; args.RemoveRange(0, 2);
            }
            // 0.18.0: "--startup" (from the Windows startup entry) starts quietly in the notification area.
            var quiet = args.Remove(StartupEntry.Argument);
            if (args.Count > 1 || args.Any(a => a.StartsWith("--", StringComparison.Ordinal))) throw new ArgumentException("Use [--managed-policy <local policy.json>] [--startup] [file to open].");
            if (args.Count == 1) file = Path.GetFullPath(args[0]);
            // A TRT that is already running opens the file (or shows its capture bar) instead.
            instance = new SingleInstance();
            if (!instance.IsFirst)
            {
                if (quiet || SingleInstance.Send(file)) { Shutdown(0); return; }
                throw new IOException("TRT is already running but not answering. Quit it from its notification-area icon and try again.");
            }
            var policy = ManagedPolicy.Load(policyPath);
            // 0.25.0: TRT is the default app for pictures and this copy runs from a new place: point Windows at it.
            try { if (PictureApp.Refresh()) PictureApp.Announce(); StartupEntry.Refresh(); }
            catch (Exception ex) when (ex is UnauthorizedAccessException or System.Security.SecurityException or IOException) { }
            // 0.12.0: TRT opens as the capture bar and keeps running in the notification area until
            // Quit, so closing the editor or hiding the bar does not end it.
            ShutdownMode = ShutdownMode.OnExplicitShutdown;
            captures = new CaptureController(policy);
            captures.Start(showBar: !quiet);
            instance.Listen(path => Dispatcher.BeginInvoke(async () => { if (path == null) captures.ShowBar(); else await captures.OpenPathInEditorAsync(path); }));
            if (file != null) _ = captures.OpenPathInEditorAsync(file);
        }
        catch (Exception ex) { ThemedMessage.Show("Application could not start.\n\n" + ex.Message, "Application Could Not Start"); Shutdown(1); }
    }
    protected override void OnSessionEnding(SessionEndingCancelEventArgs e) { captures?.EndSession(); base.OnSessionEnding(e); }
    protected override void OnExit(ExitEventArgs e) { instance?.Dispose(); base.OnExit(e); }
}
