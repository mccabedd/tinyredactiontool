using System.IO;
using System.Windows;

namespace TinyRedaction.Desktop;

// The Help manual (3.0.0, David: Help › Help opens it in a separate window). The manual is a web page that travels with
// TRT (help/TRT-Help.html and its pictures) and is readable on GitHub too. TRT shows it in its own Help window
// (HelpWindow, HelpDocument): no browser is needed or started (David: a PC with only Floorp; a browser tab instead of a
// window). Nothing is fetched from the internet.
internal static class HelpManual
{
    public static string ManualPath => Path.Combine(AppContext.BaseDirectory, "help", "TRT-Help.html");

    public static void Open(Window? owner)
    {
        if (!File.Exists(ManualPath)) { ThemedMessage.Show(owner, "The Help manual is missing from this copy of TRT.", "Help", MessageBoxButton.OK, MessageBoxImage.Warning); return; }
        try { HelpWindow.Open(owner); }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or InvalidOperationException or NotSupportedException)
        { ThemedMessage.Show(owner, "TRT couldn't show the Help manual: " + ex.Message + "\n\nYou can open it with any web browser. It is here:\n" + ManualPath, "Help", MessageBoxButton.OK, MessageBoxImage.Warning); }
    }
}
