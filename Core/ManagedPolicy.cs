using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace TinyRedaction.Core;

public sealed record ManagedPolicy(bool BlockNetworkSource = false, bool BlockNetworkDestination = false,
    bool DisableSourceDeletion = false, bool DisableAudioRetention = false, bool DisableVisualObscuration = false)
{
    public static ManagedPolicy Load(string? explicitPath = null)
    {
        var path = explicitPath ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "TinyRedactionTool", "policy.json");
        if (explicitPath == null && !File.Exists(path)) return new();
        path = Path.GetFullPath(path);
        if (IsNetwork(path)) throw new InvalidDataException("Managed policy must be local.");
        if ((File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0) throw new InvalidDataException("Managed policy cannot be a reparse point.");
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        if (stream.Length is < 1 or > 65536) throw new InvalidDataException("Managed policy must be 1 byte to 64 KiB.");
        var bytes = new byte[(int)stream.Length]; stream.ReadExactly(bytes);
        return Parse(new UTF8Encoding(false, true).GetString(bytes).TrimStart('\uFEFF'));
    }
    public static ManagedPolicy Parse(string json)
    {
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        RequireProperties(root, ["schemaVersion", "policyId", "policyVersion", "controls"]);
        if (root.GetProperty("schemaVersion").GetInt32() != 1) throw new InvalidDataException("Unsupported managed policy schema.");
        if (!Regex.IsMatch(root.GetProperty("policyId").GetString() ?? "", @"\A[A-Za-z0-9][A-Za-z0-9._-]{0,63}\z") ||
            !Regex.IsMatch(root.GetProperty("policyVersion").GetString() ?? "", @"\A[A-Za-z0-9][A-Za-z0-9._-]{0,31}\z")) throw new InvalidDataException("Invalid managed policy identity.");
        var controls = root.GetProperty("controls");
        string[] allowed = ["blockNetworkSource", "blockNetworkDestination", "disableSourceDeletion", "disableAudioRetention", "disableVisualObscuration"];
        if (controls.ValueKind != JsonValueKind.Object) throw new InvalidDataException("Policy controls must be an object.");
        var seen = new HashSet<string>();
        foreach (var property in controls.EnumerateObject())
            if (!allowed.Contains(property.Name) || !seen.Add(property.Name) || property.Value.ValueKind is not (JsonValueKind.True or JsonValueKind.False))
                throw new InvalidDataException("Unsupported, duplicate or non-Boolean managed control.");
        bool Get(string name) => controls.TryGetProperty(name, out var value) && value.GetBoolean();
        return new(Get(allowed[0]), Get(allowed[1]), Get(allowed[2]), Get(allowed[3]), Get(allowed[4]));
    }
    private static void RequireProperties(JsonElement root, string[] expected)
    {
        if (root.ValueKind != JsonValueKind.Object) throw new InvalidDataException("Policy must be an object.");
        var names = root.EnumerateObject().Select(p => p.Name).ToArray();
        if (names.Length != expected.Length || names.Distinct().Count() != names.Length || names.Except(expected).Any()) throw new InvalidDataException("Unknown or missing policy properties.");
    }
    public static bool IsNetwork(string path)
    {
        var full = Path.GetFullPath(path);
        if (full.StartsWith(@"\\", StringComparison.Ordinal)) return true;
        var root = Path.GetPathRoot(full);
        return !string.IsNullOrEmpty(root) && new DriveInfo(root).DriveType == DriveType.Network;
    }
}
