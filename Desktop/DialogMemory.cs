using System.IO;
using Microsoft.Win32;

namespace TinyRedaction.Desktop;

// Windows' own memory of TRT's Open and Save boxes (0.28.0, David: File › Remove History). Windows keeps, per program,
// the last folder used in an Open/Save box (ComDlg32\LastVisitedPidlMRU), the box's size (CIDSizeMRU) and the first
// folder shown (FirstFolder). Each value starts with the program's file name; TRT removes only its own values and the
// matching numbers in the list of their order (MRUListEx), so other programs' entries stay as they were.
internal static class DialogMemory
{
    public const string DefaultRoot = @"Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32";
    private static readonly string[] Lists = ["LastVisitedPidlMRU", "LastVisitedPidlMRULegacy", "CIDSizeMRU", "FirstFolder"];

    // The program's own file name, or null when it is a shared host (the checks run under dotnet.exe).
    public static string? OwnProgramName()
    {
        var name = Path.GetFileName(Environment.ProcessPath);
        return string.IsNullOrEmpty(name) || name.Equals("dotnet.exe", StringComparison.OrdinalIgnoreCase) ? null : name;
    }

    // Removes this program's entries under root (HKCU). Returns how many were removed.
    public static int Forget(string programName, string root = DefaultRoot)
    {
        var removed = 0;
        foreach (var list in Lists)
        {
            using var key = Registry.CurrentUser.OpenSubKey(root + "\\" + list, writable: true);
            if (key == null) continue;
            var order = key.GetValue("MRUListEx") as byte[];
            var dropped = new List<uint>();
            foreach (var name in key.GetValueNames())
            {
                if (!uint.TryParse(name, out var index) || key.GetValue(name) is not byte[] data || !StartsWithProgram(data, programName)) continue;
                key.DeleteValue(name, false); dropped.Add(index); removed++;
            }
            if (order != null && dropped.Count > 0) key.SetValue("MRUListEx", WithoutIndexes(order, dropped), RegistryValueKind.Binary);
        }
        return removed;
    }

    internal static bool StartsWithProgram(byte[] data, string programName)
    {
        var bytes = System.Text.Encoding.Unicode.GetBytes(programName + "\0");
        if (data.Length < bytes.Length) return false;
        var start = System.Text.Encoding.Unicode.GetString(data, 0, bytes.Length);
        return string.Equals(start, programName + "\0", StringComparison.OrdinalIgnoreCase);
    }

    // MRUListEx: four-byte numbers in order of use, ending with FF FF FF FF.
    internal static byte[] WithoutIndexes(byte[] order, IReadOnlyCollection<uint> dropped)
    {
        var kept = new List<byte>();
        for (var i = 0; i + 4 <= order.Length; i += 4)
        {
            var value = BitConverter.ToUInt32(order, i);
            if (value == uint.MaxValue) break;
            if (!dropped.Contains(value)) kept.AddRange(BitConverter.GetBytes(value));
        }
        kept.AddRange(BitConverter.GetBytes(uint.MaxValue));
        return [.. kept];
    }
}
