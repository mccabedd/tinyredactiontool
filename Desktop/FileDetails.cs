using System.Globalization;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// File info (0.23.0, David): what is written inside the opened file besides the picture, such as camera, place
// (GPS), dates and the program that made it. TRT's export leaves all of it out (and checks it did). Read with TRT's
// own FFmpeg: the file's tags, each stream's tags, and the first picture's tags (EXIF from JPG, WebP and TIFF,
// text from PNG).
internal static class FileDetails
{
    public const string Container = "File", Stream = "Stream", Picture = "Picture";
    public static async Task<List<(string Group, string Name, string Value)>> ReadAsync(MediaTools tools, string path, CancellationToken token) =>
        (await ReportAsync(tools, path, picture: false, token)).Details.ToList();

    // 0.25.0 (David): File info laid out as a plain text report: a General section, then one per stream
    // (Video, Audio, Text, or Image for a picture), each a list of "name : value" lines. One ffprobe run gives both
    // the report and the plain list of details (what Export leaves out, checked by Release023Checks).
    public static async Task<FileReport> ReportAsync(MediaTools tools, string path, bool picture, CancellationToken token)
    {
        var found = new List<(string, string, string)>();
        var sections = new List<(string Title, List<(string Name, string Value)> Lines)>();
        var json = await tools.RunAsync("ffprobe.exe",
            ["-v", "error", "-show_entries", "format:stream:frame_tags", "-show_frames", "-read_intervals", "%+#1", "-of", "json", path], path, token);
        var xmp = await Task.Run(() => HasXmp(path), token);
        using (var document = JsonDocument.Parse(json))
        {
            var root = document.RootElement;
            var format = root.TryGetProperty("format", out var f) && f.ValueKind == JsonValueKind.Object ? f : default;
            var streams = root.TryGetProperty("streams", out var s) && s.ValueKind == JsonValueKind.Array ? s.EnumerateArray().ToList() : [];
            JsonElement? frame = root.TryGetProperty("frames", out var fr) && fr.ValueKind == JsonValueKind.Array ? fr.EnumerateArray().Cast<JsonElement?>().FirstOrDefault() : null;
            if (format.ValueKind == JsonValueKind.Object) Tags(format, Container, found);
            foreach (var stream in streams) Tags(stream, Text(stream, "codec_type") switch { "video" => "Picture stream", "audio" => "Sound stream", _ => Stream }, found);
            if (frame is { } first) Tags(first, Picture, found);
            if (xmp) found.Add((Container, "XMP description", "present (not listed in detail)"));
            var place = Position(found);
            if (place != null) found.Insert(0, (Place, "GPS position", place));

            // General
            var general = new List<(string, string)> { ("Complete name", path) };
            var firstVideoIndex = streams.FindIndex(x => Text(x, "codec_type") == "video");
            var firstVideo = firstVideoIndex >= 0 ? streams[firstVideoIndex] : default;
            general.Add(("Format", ContainerName(Text(format, "format_name"), Text(format, "format_long_name"), Path.GetExtension(path), firstVideo)));
            long? bytes = null; try { bytes = new FileInfo(path).Length; } catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
            if (bytes is { } size) general.Add(("File size", Size(size)));
            if (!picture)
            {
                if (Number(format, "duration") is { } duration && duration > 0) general.Add(("Duration", Duration(duration)));
                if (Number(format, "bit_rate") is { } rate && rate > 0) general.Add(("Overall bit rate", BitRate(rate)));
                if (firstVideo.ValueKind == JsonValueKind.Object && FrameRate(Text(firstVideo, "avg_frame_rate") ?? Text(firstVideo, "r_frame_rate")) is { } fps) general.Add(("Frame rate", fps));
            }
            if (place != null) general.Add(("GPS position", place));
            // MP4 brands written as: "isom (isom/iso2/avc1/mp41)".
            if (Text(Tags(format), "major_brand") is { } brand)
            {
                var brands = Text(Tags(format), "compatible_brands") ?? "";
                var list = Enumerable.Range(0, brands.Length / 4).Select(i => brands.Substring(i * 4, 4).Trim()).Where(b => b.Length > 0).ToList();
                general.Add(("Codec ID", list.Count > 0 ? $"{brand.Trim()} ({string.Join("/", list)})" : brand.Trim()));
            }
            AddTags(general, format, "major_brand", "minor_version", "compatible_brands");
            if (xmp) general.Add(("XMP description", "present (not listed in detail)"));
            sections.Add(("General", general));

            // One section per stream, numbered when there are several of a kind (Audio #1, Audio #2).
            var kinds = streams.Select(x => Kind(x, picture)).ToList();
            var seen = new Dictionary<string, int>();
            for (var i = 0; i < streams.Count; i++)
            {
                var stream = streams[i]; var kind = kinds[i];
                seen[kind] = seen.GetValueOrDefault(kind) + 1;
                var title = kinds.Count(k => k == kind) > 1 ? $"{kind} #{seen[kind]}" : kind;
                var lines = StreamLines(stream, kind, picture);
                if (i == firstVideoIndex && frame is { } tagged) AddTags(lines, tagged, true);
                sections.Add((title, lines));
            }
        }
        return new FileReport(sections.Select(x => (x.Title, (IReadOnlyList<(string, string)>)x.Lines)).ToList(), found.Distinct().ToList());
    }
    private static string Kind(JsonElement stream, bool picture) => Text(stream, "codec_type") switch
    {
        "video" => picture || Text(stream, "disposition_attached_pic") == "1" ? "Image" : "Video",
        "audio" => "Audio", "subtitle" => "Text", "attachment" => "Attachment", _ => "Other",
    };
    private static List<(string, string)> StreamLines(JsonElement s, string kind, bool picture)
    {
        var lines = new List<(string, string)>();
        void Add(string name, string? value) { if (!string.IsNullOrWhiteSpace(value)) lines.Add((name, value.Trim())); }
        var codec = Text(s, "codec_name");
        var tags = s.TryGetProperty("tags", out var t) && t.ValueKind == JsonValueKind.Object ? t : default;
        string? Tag(string name) => tags.ValueKind == JsonValueKind.Object ? tags.EnumerateObject().FirstOrDefault(p => string.Equals(p.Name, name, StringComparison.OrdinalIgnoreCase)).Value is { ValueKind: JsonValueKind.String } v ? v.GetString() : null : null;
        if (!picture) Add("ID", (Number(s, "index") is { } index ? (int)index + 1 : 1).ToString(Inv));
        var (formatName, info) = CodecName(codec, Text(s, "codec_long_name"));
        Add("Format", formatName); Add("Format/Info", info);
        var profile = ProfileName(codec, Text(s, "profile"));
        if (profile != null && Number(s, "level") is { } level && level > 0 && codec is "h264" or "hevc")
            profile += "@L" + (codec == "hevc" ? level / 30 : level / 10).ToString("0.#", Inv);
        Add("Format profile", profile);
        var tag = Text(s, "codec_tag_string");
        if (tag != null && !tag.StartsWith('[')) Add("Codec ID", tag);
        if (!picture && kind is "Video" or "Audio")
        {
            var duration = Number(s, "duration") ?? Clock(Tag("DURATION"));
            if (duration is > 0) Add("Duration", Duration(duration.Value));
            var rate = Number(s, "bit_rate") ?? (double.TryParse(Tag("BPS"), NumberStyles.Float, Inv, out var bps) ? bps : null);
            if (rate is > 0) Add("Bit rate", BitRate(rate.Value));
        }
        if (kind is "Video" or "Image")
        {
            var w = Number(s, "width"); var h = Number(s, "height");
            if (w is > 0) Add("Width", Pixels(w.Value));
            if (h is > 0) Add("Height", Pixels(h.Value));
            var aspect = Text(s, "display_aspect_ratio");
            if (kind == "Video") Add("Display aspect ratio", aspect is { } a && a != "0:1" && a != "N/A" ? a : w is > 0 && h is > 0 ? Ratio(w.Value, h.Value) : null);
            if (kind == "Video")
            {
                Add("Frame rate", FrameRate(Text(s, "avg_frame_rate") ?? Text(s, "r_frame_rate")));
                Add("Frame count", Text(s, "nb_frames") ?? Tag("NUMBER_OF_FRAMES"));
            }
            var pixels = Text(s, "pix_fmt");
            if (pixels != null)
            {
                var p = pixels.ToLowerInvariant();
                Add("Colour space", p.StartsWith("yuv") || p.StartsWith("yuvj") || p.StartsWith("nv") ? "YUV" : p.Contains("rgb") || p.Contains("bgr") || p.StartsWith("gbr") ? "RGB" : p.StartsWith("gray") || p.StartsWith("ya") ? "Greyscale" : p.StartsWith("pal") ? "Palette" : pixels);
                Add("Chroma subsampling", p.Contains("420") || p.StartsWith("nv12") ? "4:2:0" : p.Contains("422") ? "4:2:2" : p.Contains("444") ? "4:4:4" : p.Contains("411") ? "4:1:1" : null);
                var depth = Number(s, "bits_per_raw_sample") is { } bits && bits > 0 ? (int)bits
                    : System.Text.RegularExpressions.Regex.Match(p, @"p(\d+)(le|be)$") is { Success: true } m ? int.Parse(m.Groups[1].Value, Inv) : p.Contains("64") || p.Contains("48") || p.EndsWith("16le") || p.EndsWith("16be") ? 16 : 8;
                Add("Bit depth", $"{depth} bits");
                Add("Transparency", p.StartsWith("rgba") || p.StartsWith("bgra") || p.StartsWith("argb") || p.StartsWith("abgr") || p.StartsWith("ya") || p.StartsWith("yuva") || p.StartsWith("gbrap") || p.StartsWith("pal") ? "Yes (alpha)" : null);
            }
            Add("Scan type", Text(s, "field_order") switch { "progressive" => "Progressive", "tt" or "bb" or "tb" or "bt" => "Interlaced", _ => null });
            Add("Colour primaries", Colour(Text(s, "color_primaries"))); Add("Transfer characteristics", Colour(Text(s, "color_transfer"))); Add("Matrix coefficients", Colour(Text(s, "color_space")));
        }
        if (kind == "Audio")
        {
            if (Number(s, "channels") is { } channels && channels > 0) Add("Channel(s)", channels == 1 ? "1 channel" : $"{channels.ToString(Inv)} channels");
            Add("Channel layout", Text(s, "channel_layout"));
            if (Number(s, "sample_rate") is { } hz && hz > 0) Add("Sampling rate", $"{(hz / 1000).ToString("0.0", Inv)} kHz");
            if (Number(s, "bits_per_raw_sample") is { } bits && bits > 0) Add("Bit depth", $"{bits.ToString(Inv)} bits");
        }
        if (!picture)
        {
            var language = Tag("language");
            Add("Language", language is null or "und" ? null : Language(language));
            if (s.TryGetProperty("disposition", out var d) && d.ValueKind == JsonValueKind.Object)
            {
                Add("Default", Number(d, "default") == 1 ? "Yes" : "No");
                if (Number(d, "forced") == 1) Add("Forced", "Yes");
            }
        }
        AddTags(lines, s, "language", "DURATION", "BPS", "NUMBER_OF_FRAMES", "NUMBER_OF_BYTES");
        return lines;
    }
    // A stream's or the file's own tags, with the usual names where they have one.
    private static void AddTags(List<(string, string)> lines, JsonElement element, params string[] skip) => AddTags(lines, element, false, skip);
    // exif: the picture's own tags (EXIF), whose numbers and codes are written out (ExifValue).
    private static void AddTags(List<(string, string)> lines, JsonElement element, bool exif, params string[] skip)
    {
        if (!element.TryGetProperty("tags", out var tags) || tags.ValueKind != JsonValueKind.Object) return;
        foreach (var tag in tags.EnumerateObject())
        {
            if (skip.Contains(tag.Name, StringComparer.OrdinalIgnoreCase) || tag.Name.StartsWith("_STATISTICS", StringComparison.OrdinalIgnoreCase)) continue;
            var value = tag.Value.ValueKind == JsonValueKind.String ? tag.Value.GetString() ?? "" : tag.Value.ToString();
            value = System.Text.RegularExpressions.Regex.Replace(value.Trim(), @"\s*,\s*", ", ");
            value = System.Text.RegularExpressions.Regex.Replace(value, @"\s+", " ");
            if (exif) value = ExifValue(Bare(tag.Name), value);
            if (value.Length > 300) value = value[..300] + "…";
            if (value.Length > 0) lines.Add((TagName(tag.Name), value));
        }
    }
    // "ExifIFD/ExposureTime" -> "ExposureTime" (0.26.0: the folder FFmpeg puts in front says nothing).
    private static string Bare(string name) => name.Contains('/') ? name[(name.LastIndexOf('/') + 1)..] : name;
    // EXIF values as a camera app shows them (0.26.0, David's iPhone photo): 1/297 s, f/1.78, 6.77 mm, 2026-10-21 09:08:53.
    internal static string ExifValue(string name, string value)
    {
        static double? Fraction(string text)
        {
            var parts = text.Trim().Split(':', '/');
            if (parts.Length != 2 || !double.TryParse(parts[0], NumberStyles.Float, Inv, out var top) || !double.TryParse(parts[1], NumberStyles.Float, Inv, out var bottom) || bottom == 0) return null;
            return top / bottom;
        }
        static string Number(double n, string format = "0.##") => n.ToString(format, Inv);
        var one = Fraction(value);
        byte[]? Bytes() { var parts = value.Split(','); var bytes = new byte[parts.Length]; for (var i = 0; i < parts.Length; i++) if (!byte.TryParse(parts[i].Trim(), NumberStyles.Integer, Inv, out bytes[i])) return null; return bytes; }
        int? Code() => int.TryParse(value.Trim(), NumberStyles.Integer, Inv, out var n) ? n : null;
        switch (name)
        {
            case "ExposureTime" when one is > 0: return one < 1 ? $"1/{Number(Math.Round(1 / one.Value))} s" : $"{Number(one.Value)} s";
            case "FNumber" when one is { } f: return $"f/{Number(f, "0.0#")}";
            case "FocalLength" when one is { } mm: return $"{Number(mm, "0.0##")} mm";
            case "FocalLengthIn35mmFilm": return $"{value.Trim()} mm";
            case "ExposureBiasValue" when one is { } ev: return $"{Number(ev)} EV";
            case "ExifVersion" or "FlashpixVersion" when Bytes() is { } version: return Encoding.ASCII.GetString(version);
            case "MakerNote" when Bytes() is { } note: return $"{note.Length} bytes (the camera maker's own data)";
            case "UserComment" when Bytes() is { Length: >= 8 } comment: return Encoding.ASCII.GetString(comment, 8, comment.Length - 8).TrimEnd('\0', ' ');
            case "ComponentsConfiguration" when Bytes() is { } parts: return parts.SequenceEqual(new byte[] { 1, 2, 3, 0 }) ? "YCbCr" : parts.SequenceEqual(new byte[] { 4, 5, 6, 0 }) ? "RGB" : value;
            case "DateTime" or "DateTimeOriginal" or "DateTimeDigitized" when System.Text.RegularExpressions.Regex.IsMatch(value, @"^\d{4}:\d\d:\d\d "): return value[..4] + "-" + value[5..7] + "-" + value[8..];
            case "ResolutionUnit": return Code() switch { 2 => "inches", 3 => "centimetres", 1 => "none", _ => value };
            case "ExposureProgram": return Code() switch { 1 => "Manual", 2 => "Normal program", 3 => "Aperture priority", 4 => "Shutter priority", 5 => "Creative", 6 => "Action", 7 => "Portrait", 8 => "Landscape", _ => value };
            case "MeteringMode": return Code() switch { 1 => "Average", 2 => "Centre-weighted average", 3 => "Spot", 4 => "Multi-spot", 5 => "Pattern", 6 => "Partial", _ => value };
            case "Flash": return Code() is { } flash ? (flash & 1) == 1 ? "Fired" : "Did not fire" : value;
            case "ColorSpace": return Code() switch { 1 => "sRGB", 65535 => "Uncalibrated", _ => value };
            case "WhiteBalance": return Code() switch { 0 => "Auto", 1 => "Manual", _ => value };
            case "ExposureMode": return Code() switch { 0 => "Auto", 1 => "Manual", 2 => "Auto bracket", _ => value };
            case "SceneCaptureType": return Code() switch { 0 => "Standard", 1 => "Landscape", 2 => "Portrait", 3 => "Night", _ => value };
            case "SensingMethod": return Code() switch { 2 => "One-chip colour area", 3 => "Two-chip colour area", 4 => "Three-chip colour area", _ => value };
            case "CustomRendered": return Code() switch { 0 => "Normal", 1 => "Custom", _ => value };
            case "YCbCrPositioning": return Code() switch { 1 => "Centred", 2 => "Co-sited", _ => value };
            case "SceneType": return Code() == 1 ? "Directly photographed" : value;
            case "Orientation": return Code() switch { 1 => "Normal", 3 => "Upside down", 6 => "Turned 90° clockwise", 8 => "Turned 90° anti-clockwise", 2 or 4 or 5 or 7 => "Mirrored", _ => value };
        }
        if (name.StartsWith("GPS", StringComparison.Ordinal)) return value; // The position is written out in General.
        // Any other single fraction or list of fractions: as numbers.
        if (one is { } plain) return Number(plain, "0.###");
        var fractions = value.Split(',').Select(Fraction).ToList();
        if (fractions.Count > 1 && fractions.All(x => x != null)) return string.Join(", ", fractions.Select(x => Number(x!.Value, "0.###")));
        return value;
    }
    private static readonly Dictionary<string, string> TagNames = new(StringComparer.OrdinalIgnoreCase)
    {
        ["encoder"] = "Writing application", ["creation_time"] = "Encoded date", ["title"] = "Title", ["comment"] = "Comment", ["artist"] = "Performer",
        ["date"] = "Recorded date", ["handler_name"] = "Handler", ["vendor_id"] = "Vendor", ["major_brand"] = "Codec ID", ["compatible_brands"] = "Compatible brands",
        ["minor_version"] = "Codec ID version", ["Make"] = "Camera make", ["Model"] = "Camera model", ["DateTime"] = "Date and time", ["DateTimeOriginal"] = "Date taken",
        ["DateTimeDigitized"] = "Date digitised", ["copyright"] = "Copyright", ["XResolution"] = "X resolution", ["YResolution"] = "Y resolution",
        ["FNumber"] = "F-number", ["ISOSpeedRatings"] = "ISO", ["ExposureBiasValue"] = "Exposure bias", ["FocalLengthIn35mmFilm"] = "Focal length (35 mm)",
        ["PixelXDimension"] = "Picture width", ["PixelYDimension"] = "Picture height", ["SubSecTimeOriginal"] = "Sub-second taken", ["SubSecTimeDigitized"] = "Sub-second digitised",
        ["YCbCrPositioning"] = "YCbCr positioning", ["ColorSpace"] = "Colour space (EXIF)", ["MakerNote"] = "Maker note", ["UserComment"] = "User comment", ["description"] = "Description", ["location"] = "Location",
    };
    // EXIF tags FFmpeg knows only by number.
    private static readonly Dictionary<string, string> NumberedTags = new(StringComparer.OrdinalIgnoreCase)
    {
        ["0x013C"] = "Host computer", ["0x9010"] = "Offset time", ["0x9011"] = "Offset time original", ["0x9012"] = "Offset time digitised",
        ["0xA430"] = "Camera owner", ["0xA431"] = "Camera serial number", ["0xA432"] = "Lens specification", ["0xA433"] = "Lens make", ["0xA434"] = "Lens model",
        ["0xA435"] = "Lens serial number", ["0x8830"] = "Sensitivity type", ["0xA460"] = "Composite image", ["0x9400"] = "Temperature",
    };
    internal static string TagName(string name)
    {
        name = name.StartsWith("com.", StringComparison.Ordinal) ? name : Bare(name);
        if (NumberedTags.TryGetValue(name, out var numbered)) return numbered;
        if (TagNames.TryGetValue(name, out var known)) return known;
        if (name.StartsWith("0x", StringComparison.OrdinalIgnoreCase)) return "Tag " + name;
        if (name.Contains('.') || name.Contains(':')) return name; // com.apple.quicktime…, exif:…: as written.
        var spaced = System.Text.RegularExpressions.Regex.Replace(name.Replace('_', ' '), "(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", " ").Trim();
        var words = spaced.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (words.Length == 0) return name;
        for (var i = 0; i < words.Length; i++)
        {
            var w = words[i];
            var acronym = w.Length <= 4 && w.All(c => char.IsUpper(c) || char.IsDigit(c)) && words.Length > 1;
            if (!acronym) w = w.ToLowerInvariant();
            words[i] = i == 0 ? char.ToUpperInvariant(w[0]) + w[1..] : w;
        }
        return string.Join(' ', words);
    }
    private static string ContainerName(string? format, string? longName, string extension, JsonElement video)
    {
        var ext = extension.ToLowerInvariant();
        var codec = video.ValueKind == JsonValueKind.Object ? Text(video, "codec_name") : null;
        return format switch
        {
            null => longName ?? "Unknown",
            "matroska,webm" => ext == ".webm" ? "WebM" : "Matroska",
            "mov,mp4,m4a,3gp,3g2,mj2" => ext == ".mov" ? "QuickTime" : ext is ".3gp" or ".3g2" ? "3GPP" : "MPEG-4",
            "avi" => "AVI", "asf" => "Windows Media", "flv" => "Flash Video", "mpegts" => "MPEG-TS", "mpeg" => "MPEG-PS", "gif" => "GIF",
            _ when format.StartsWith("image2") || format.EndsWith("_pipe") => CodecName(codec, longName).Format ?? longName ?? format,
            _ => longName ?? format,
        };
    }
    private static (string? Format, string? Info) CodecName(string? codec, string? longName) => codec switch
    {
        null => (longName, null),
        "h264" => ("AVC", "Advanced Video Codec"), "hevc" => ("HEVC", "High Efficiency Video Coding"), "av1" => ("AV1", "AOMedia Video 1"),
        "vp8" => ("VP8", null), "vp9" => ("VP9", null), "mpeg4" => ("MPEG-4 Visual", null), "mpeg2video" => ("MPEG Video", "Version 2"), "mpeg1video" => ("MPEG Video", "Version 1"),
        "msmpeg4v3" => ("MS-MPEG4 v3", null), "wmv3" => ("VC-1", "Windows Media Video 9"), "prores" => ("ProRes", null), "mjpeg" => ("JPEG", null),
        "aac" => ("AAC", "Advanced Audio Codec"), "mp3" => ("MPEG Audio", "Layer 3"), "mp2" => ("MPEG Audio", "Layer 2"), "ac3" => ("AC-3", "Audio Coding 3"), "eac3" => ("E-AC-3", "Enhanced AC-3"),
        "dts" => ("DTS", null), "opus" => ("Opus", null), "vorbis" => ("Vorbis", null), "flac" => ("FLAC", "Free Lossless Audio Codec"), "alac" => ("ALAC", "Apple Lossless"),
        "wmav2" => ("WMA", "Windows Media Audio"), "truehd" => ("TrueHD", null),
        "png" or "apng" => ("PNG", "Portable Network Graphics"), "webp" => ("WebP", null), "bmp" => ("BMP", null), "tiff" => ("TIFF", null), "gif" => ("GIF", null),
        "subrip" => ("UTF-8", "SubRip"), "ass" => ("ASS", "Advanced SubStation Alpha"), "mov_text" => ("Timed Text", null), "hdmv_pgs_subtitle" => ("PGS", null), "dvd_subtitle" => ("VobSub", null),
        _ when codec.StartsWith("pcm_") => ("PCM", null),
        _ => (codec.ToUpperInvariant(), longName),
    };
    private static JsonElement Tags(JsonElement e) => e.ValueKind == JsonValueKind.Object && e.TryGetProperty("tags", out var tags) ? tags : default;
    // TRT's FFmpeg is built small: it gives profiles as numbers, so they are named here (H.264, HEVC, AAC, VP9, AV1).
    private static string? ProfileName(string? codec, string? profile)
    {
        if (profile == null || !int.TryParse(profile, NumberStyles.Integer, Inv, out var n)) return profile;
        return (codec, n) switch
        {
            (_, < 0) => null,
            ("h264", 66) => "Baseline", ("h264", 578) => "Constrained Baseline", ("h264", 77) => "Main", ("h264", 88) => "Extended", ("h264", 100) => "High",
            ("h264", 110) => "High 10", ("h264", 122) => "High 4:2:2", ("h264", 244) => "High 4:4:4 Predictive", ("h264", 44) => "CAVLC 4:4:4",
            ("hevc", 1) => "Main", ("hevc", 2) => "Main 10", ("hevc", 3) => "Main Still Picture", ("hevc", 4) => "Format Range",
            ("aac", 0) => "Main", ("aac", 1) => "LC", ("aac", 2) => "SSR", ("aac", 3) => "LTP", ("aac", 4) => "HE-AAC", ("aac", 28) => "HE-AACv2", ("aac", 22) => "LD", ("aac", 38) => "ELD",
            ("vp9", _) => $"Profile {n}", ("av1", 0) => "Main", ("av1", 1) => "High", ("av1", 2) => "Professional",
            _ => null, // Other numbers (JPEG's 192) mean nothing to read.
        };
    }
    private static string? Colour(string? value) => value switch
    {
        null or "unknown" or "unspecified" or "reserved" => null,
        "bt709" => "BT.709", "bt470bg" => "BT.601 PAL", "smpte170m" => "BT.601 NTSC", "bt2020" or "bt2020nc" or "bt2020c" => "BT.2020", "bt2020-10" => "BT.2020 (10-bit)",
        "smpte2084" => "PQ", "arib-std-b67" => "HLG", "iec61966-2-1" => "sRGB", "gbr" => "Identity", _ => value,
    };
    private static string Language(string code)
    {
        try { var culture = CultureInfo.GetCultures(CultureTypes.NeutralCultures).FirstOrDefault(c => c.ThreeLetterISOLanguageName == code || c.TwoLetterISOLanguageName == code); return culture?.EnglishName ?? code; }
        catch (CultureNotFoundException) { return code; }
    }
    private static readonly CultureInfo Inv = CultureInfo.InvariantCulture;
    private static string? Text(JsonElement e, string name)
    {
        if (e.ValueKind != JsonValueKind.Object) return null;
        if (name.StartsWith("disposition_")) return e.TryGetProperty("disposition", out var d) && d.ValueKind == JsonValueKind.Object ? Text(d, name["disposition_".Length..]) : null;
        if (!e.TryGetProperty(name, out var v)) return null;
        return v.ValueKind switch { JsonValueKind.String => v.GetString(), JsonValueKind.Number => v.GetRawText(), _ => null };
    }
    private static double? Number(JsonElement e, string name) => double.TryParse(Text(e, name), NumberStyles.Float, Inv, out var n) && double.IsFinite(n) ? n : null;
    // "01:49:12.345000000" (Matroska stream durations) to seconds.
    private static double? Clock(string? text) => text != null && TimeSpan.TryParse(text.Length > 16 ? text[..16] : text, Inv, out var span) ? span.TotalSeconds : null;
    // The ways of writing sizes, times and rates: 7.85 GiB, 1 h 49 min, 10.2 Mb/s, 23.976 (24000/1001) FPS, 1 920 pixels.
    internal static string Size(long bytes)
    {
        if (bytes < 1024) return $"{bytes} Bytes";
        string[] units = ["KiB", "MiB", "GiB", "TiB"];
        double value = bytes; var unit = -1;
        while (value >= 1024 && unit < units.Length - 1) { value /= 1024; unit++; }
        return $"{Significant(value)} {units[unit]}";
    }
    internal static string Duration(double seconds)
    {
        var span = TimeSpan.FromSeconds(seconds);
        if (span.TotalHours >= 1) return $"{(int)span.TotalHours} h {span.Minutes} min";
        if (span.TotalMinutes >= 1) return $"{span.Minutes} min {span.Seconds} s";
        if (span.TotalSeconds >= 1) return $"{span.Seconds} s {span.Milliseconds} ms";
        return $"{span.Milliseconds} ms";
    }
    internal static string BitRate(double bitsPerSecond) =>
        bitsPerSecond >= 10_000_000 ? $"{Significant(bitsPerSecond / 1_000_000)} Mb/s" : $"{Thousands(Math.Round(bitsPerSecond / 1000))} kb/s";
    internal static string? FrameRate(string? rate)
    {
        if (rate == null) return null;
        var parts = rate.Split('/');
        if (!double.TryParse(parts[0], NumberStyles.Float, Inv, out var top) || top <= 0) return null;
        var bottom = parts.Length > 1 && double.TryParse(parts[1], NumberStyles.Float, Inv, out var b) && b > 0 ? b : 1;
        var fps = (top / bottom).ToString("0.000", Inv);
        return bottom == 1 ? $"{fps} FPS" : $"{fps} ({rate}) FPS";
    }
    private static string Pixels(double count) => $"{Thousands(count)} pixels";
    private static string Thousands(double value) => ((long)value).ToString("#,0", Inv).Replace(',', ' ');
    private static string Significant(double value) => value >= 100 ? value.ToString("0", Inv) : value >= 10 ? value.ToString("0.0", Inv) : value.ToString("0.00", Inv);
    private static string Ratio(double w, double h)
    {
        var r = w / h;
        foreach (var (name, value) in new[] { ("16:9", 16 / 9.0), ("4:3", 4 / 3.0), ("1:1", 1.0), ("3:2", 1.5), ("21:9", 64 / 27.0), ("9:16", 9 / 16.0), ("3:4", 0.75), ("2.39:1", 2.39), ("1.85:1", 1.85) })
            if (Math.Abs(r - value) < 0.01) return name;
        return r.ToString("0.000", Inv);
    }
    public const string Place = "Place";
    // The GPS position as decimal degrees (to paste into a map) and in degrees, minutes and seconds; null without one.
    // Photos: EXIF GPSLatitude/GPSLongitude ("64:1, 7:1, 3540:100") with their N/S and E/W; videos: ISO 6709
    // ("+64.1265-021.8174/", in "location" or Apple's "com.apple.quicktime.location.ISO6709").
    internal static string? Position(IEnumerable<(string Group, string Name, string Value)> details)
    {
        var tags = details.GroupBy(d => d.Name, StringComparer.OrdinalIgnoreCase).ToDictionary(g => g.Key, g => g.First().Value, StringComparer.OrdinalIgnoreCase);
        string? Tag(string end) => tags.FirstOrDefault(t => t.Key.EndsWith(end, StringComparison.OrdinalIgnoreCase)).Value;
        double? latitude = null, longitude = null;
        if (Degrees(Tag("GPSLatitude")) is { } lat && Degrees(Tag("GPSLongitude")) is { } lon)
        {
            latitude = Tag("GPSLatitudeRef")?.Trim().StartsWith('S') == true ? -lat : lat;
            longitude = Tag("GPSLongitudeRef")?.Trim().StartsWith('W') == true ? -lon : lon;
        }
        else if ((Tag("location.ISO6709") ?? Tag("location")) is { } iso)
        {
            var match = System.Text.RegularExpressions.Regex.Match(iso, @"^\s*([+-]\d+(?:\.\d+)?)([+-]\d+(?:\.\d+)?)");
            if (match.Success) { latitude = double.Parse(match.Groups[1].Value, System.Globalization.CultureInfo.InvariantCulture); longitude = double.Parse(match.Groups[2].Value, System.Globalization.CultureInfo.InvariantCulture); }
        }
        if (latitude is not { } la || longitude is not { } lo || Math.Abs(la) > 90 || Math.Abs(lo) > 180) return null;
        static string Dms(double value, char positive, char negative)
        {
            var a = Math.Abs(value); var d = (int)a; var m = (int)((a - d) * 60); var s = (a - d - m / 60.0) * 3600;
            return $"{d}° {m}′ {s.ToString("0.0", System.Globalization.CultureInfo.InvariantCulture)}″ {(value < 0 ? negative : positive)}";
        }
        var inv = System.Globalization.CultureInfo.InvariantCulture;
        return $"{la.ToString("0.00000", inv)}, {lo.ToString("0.00000", inv)} ({Dms(la, 'N', 'S')}, {Dms(lo, 'E', 'W')})";
    }
    // "64:1, 7:1, 3540:100" (degrees, minutes, seconds as fractions) to decimal degrees.
    private static double? Degrees(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return null;
        var parts = text.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        double total = 0, unit = 1;
        foreach (var part in parts.Take(3))
        {
            var fraction = part.Split(':', '/');
            if (!double.TryParse(fraction[0], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var top)) return null;
            var bottom = fraction.Length > 1 && double.TryParse(fraction[1], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var b) ? b : 1;
            if (bottom == 0) return null;
            total += top / bottom / unit; unit *= 60;
        }
        return total;
    }
    private static void Tags(JsonElement element, string group, List<(string, string, string)> found)
    {
        if (!element.TryGetProperty("tags", out var tags) || tags.ValueKind != JsonValueKind.Object) return;
        foreach (var tag in tags.EnumerateObject())
        {
            var value = tag.Value.ValueKind == JsonValueKind.String ? tag.Value.GetString() ?? "" : tag.Value.ToString();
            value = System.Text.RegularExpressions.Regex.Replace(value.Trim(), @"\s*,\s*", ", "); // FFmpeg pads EXIF numbers with spaces.
            value = System.Text.RegularExpressions.Regex.Replace(value, @"[ \t]{2,}", " ");
            if (value.Length > 300) value = value[..300] + "…";
            found.Add((group, tag.Name, value));
        }
    }
    private static bool HasXmp(string path)
    {
        try
        {
            using var stream = File.OpenRead(path);
            var buffer = new byte[Math.Min(stream.Length, 4 << 20)]; var read = stream.Read(buffer, 0, buffer.Length);
            var text = Encoding.ASCII.GetString(buffer, 0, read);
            return text.Contains("<x:xmpmeta", StringComparison.Ordinal) || text.Contains("http://ns.adobe.com/xap/1.0/", StringComparison.Ordinal);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { return false; }
    }
    // Details that can say who, where or when: shown first and marked.
    public static bool Personal(string name)
    {
        var n = name.ToLowerInvariant();
        return n.Contains("gps") || n.Contains("location") || n.Contains("xyz") || n.Contains("date") || n.Contains("time") || n.Contains("make") || n.Contains("model")
            || n.Contains("serial") || n.Contains("artist") || n.Contains("author") || n.Contains("owner") || n.Contains("copyright") || n.Contains("comment") || n.Contains("software")
            || n.Contains("encoder") || n.Contains("description") || n.Contains("title") || n.Contains("user") || n.Contains("xmp");
    }
}

// What File info shows: sections of "name : value" lines, and the plain list of details besides the picture.
internal sealed record FileReport(IReadOnlyList<(string Title, IReadOnlyList<(string Name, string Value)> Lines)> Sections, IReadOnlyList<(string Group, string Name, string Value)> Details)
{
    // As a plain text report: each section's title on its own line, the names padded so the colons line up.
    internal string Text
    {
        get
        {
            var width = Math.Max(32, Sections.SelectMany(s => s.Lines).Select(l => l.Name.Length).DefaultIfEmpty(0).Max() + 1);
            var text = new StringBuilder();
            foreach (var (title, lines) in Sections)
            {
                if (text.Length > 0) text.AppendLine();
                text.AppendLine(title);
                foreach (var (name, value) in lines) text.Append(name.PadRight(width)).Append(": ").AppendLine(value.Replace("\r", " ").Replace("\n", " "));
            }
            return text.ToString();
        }
    }
}

// The File info window (0.25.0, David): the report as plain text in a fixed-width font,
// to select and copy (Ctrl+C) or Copy all, then what Export and Save media as… do with the details.
internal sealed class FileInfoWindow : Window
{
    // Thin scroll bars (0.26.0, David): an 8-pixel rounded thumb in the theme's text colour, no arrows.
    internal static Style ThinScrollBar => thin ??= (Style)System.Windows.Markup.XamlReader.Parse("""
        <Style TargetType="ScrollBar" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
         <Setter Property="Background" Value="Transparent"/>
         <Setter Property="Width" Value="9"/><Setter Property="MinWidth" Value="9"/>
         <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
          <Border Background="{TemplateBinding Background}"><Track x:Name="PART_Track" IsDirectionReversed="True">
           <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageUpCommand" Focusable="False" Opacity="0"/></Track.DecreaseRepeatButton>
           <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageDownCommand" Focusable="False" Opacity="0"/></Track.IncreaseRepeatButton>
           <Track.Thumb><Thumb MinHeight="24"><Thumb.Template><ControlTemplate TargetType="Thumb">
            <Border x:Name="Bar" CornerRadius="3" Margin="2,1" Background="{DynamicResource Foreground}" Opacity="0.35"/>
            <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bar" Property="Opacity" Value="0.6"/></Trigger><Trigger Property="IsDragging" Value="True"><Setter TargetName="Bar" Property="Opacity" Value="0.75"/></Trigger></ControlTemplate.Triggers>
           </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
          </Track></Border>
         </ControlTemplate></Setter.Value></Setter>
         <Style.Triggers><Trigger Property="Orientation" Value="Horizontal">
          <Setter Property="Width" Value="Auto"/><Setter Property="MinWidth" Value="0"/><Setter Property="Height" Value="9"/><Setter Property="MinHeight" Value="9"/>
          <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
           <Border Background="{TemplateBinding Background}"><Track x:Name="PART_Track">
            <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageLeftCommand" Focusable="False" Opacity="0"/></Track.DecreaseRepeatButton>
            <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageRightCommand" Focusable="False" Opacity="0"/></Track.IncreaseRepeatButton>
            <Track.Thumb><Thumb MinWidth="24"><Thumb.Template><ControlTemplate TargetType="Thumb">
             <Border x:Name="Bar" CornerRadius="3" Margin="1,2" Background="{DynamicResource Foreground}" Opacity="0.35"/>
             <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bar" Property="Opacity" Value="0.6"/></Trigger><Trigger Property="IsDragging" Value="True"><Setter TargetName="Bar" Property="Opacity" Value="0.75"/></Trigger></ControlTemplate.Triggers>
            </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
           </Track></Border>
          </ControlTemplate></Setter.Value></Setter>
         </Trigger></Style.Triggers>
        </Style>
        """);
    private static Style? thin;
    internal FileReport Report { get; }
    internal IReadOnlyList<(string Group, string Name, string Value)> Details => Report.Details;
    internal string Summary { get; }
    internal TextBox Box { get; }
    public FileInfoWindow(string name, FileReport report)
    {
        Report = report;
        Title = $"File Info · {name}"; Width = 800; Height = 620; MinWidth = 460; MinHeight = 320; WindowStartupLocation = WindowStartupLocation.CenterOwner; ShowInTaskbar = false;
        SetResourceReference(BackgroundProperty, "Background"); SetResourceReference(ForegroundProperty, "Foreground");
        Box = new TextBox
        {
            Text = report.Text, IsReadOnly = true, IsReadOnlyCaretVisible = false, TextWrapping = TextWrapping.NoWrap, AcceptsReturn = true,
            FontFamily = new FontFamily("Consolas, Cascadia Mono, Courier New"), FontSize = 13, Padding = new(6, 4, 6, 4), BorderThickness = new(1),
            HorizontalScrollBarVisibility = ScrollBarVisibility.Auto, VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
        };
        Box.SetResourceReference(TextBox.BackgroundProperty, "Background"); Box.SetResourceReference(TextBox.ForegroundProperty, "Foreground");
        Box.SetResourceReference(TextBox.BorderBrushProperty, "ChromeLine");
        // 0.26.0 (David): a solid selection with white text (WPF's usual one is a pale wash over the
        // text; App turns on drawing the selection behind the text so it can be solid), and thin scroll bars.
        Box.SelectionBrush = new SolidColorBrush(Color.FromRgb(0x00, 0x78, 0xD7)); Box.SelectionTextBrush = Brushes.White; Box.SelectionOpacity = 1;
        Box.Resources.Add(typeof(System.Windows.Controls.Primitives.ScrollBar), ThinScrollBar);
        Box.Resources.Add(SystemColors.ControlBrushKey, Brushes.Transparent); // The square where the two scroll bars meet.
        var count = report.Details.Count;
        Summary = count == 0 ? "Nothing is written in this file besides the picture or video. Export writes only the picture or video." :
            $"{count} detail{(count == 1 ? " is" : "s are")} written in this file besides the picture or video. Export removes all of them (and checks it did). Save media as… keeps them: that is an exact copy.";
        var copy = new Button { Content = "Copy All", MinWidth = 80, Margin = new(0, 0, 8, 0), ToolTip = "Copy All the Text" };
        copy.Click += (_, _) => { try { Clipboard.SetText(report.Text); } catch (System.Runtime.InteropServices.ExternalException) { } };
        var close = new Button { Content = "Close", IsCancel = true, IsDefault = true, MinWidth = 80 };
        close.Click += (_, _) => Close();
        var panel = new DockPanel { Margin = new(10) };
        var foot = new StackPanel();
        foot.Children.Add(new TextBlock { Text = Summary, TextWrapping = TextWrapping.Wrap, Margin = new(2, 10, 2, 0) });
        foot.Children.Add(new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, Margin = new(0, 10, 0, 0), Children = { copy, close } });
        DockPanel.SetDock(foot, Dock.Bottom);
        panel.Children.Add(foot); panel.Children.Add(Box);
        Content = panel;
        Loaded += (_, _) => Box.Focus();
    }
}
