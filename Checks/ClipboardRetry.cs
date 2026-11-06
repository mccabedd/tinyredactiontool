using System.Runtime.InteropServices;
using System.Windows;

// Another program (clipboard history, a remote-desktop client) can hold the clipboard open for a
// moment; reading it then fails. The checks only save and restore it, so they wait and try again.
internal static class ClipboardRetry
{
    public static string? Text()
    {
        for (var attempt = 0; ; attempt++)
        {
            try { return Clipboard.ContainsText() ? Clipboard.GetText() : null; }
            catch (COMException) when (attempt < 20) { Thread.Sleep(100); }
            catch (COMException) { return null; }
        }
    }
}