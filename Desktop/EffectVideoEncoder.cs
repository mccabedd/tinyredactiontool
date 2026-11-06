using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Text;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// The exact compositor runs on sequential decoded frames held only in memory.
// A forward-only timestamped PNG transport keeps decoded source imagery off disk.
internal static class EffectVideoEncoder
{
    internal static async Task EncodeAsync(string destination, RedactionProject project,
        FrameTimeline map, IProgress<double>? progress, CancellationToken cancellation)
    {
        var source = project.Media!;
        var stamps = map.Frames.Select(f => checked((long)Math.Round(f.Time * 1_000_000))).ToArray();
        if (stamps.Zip(stamps.Skip(1)).Any(p => p.Second <= p.First)) throw new InvalidDataException("Frame timestamps are too close for effect export.");
        var webm = Path.GetExtension(destination).Equals(".webm", StringComparison.OrdinalIgnoreCase);
        var encoding = new List<string> { "-v", "error", "-xerror", "-copyts", "-f", "matroska", "-i", "pipe:0" };
        if (project.Export.KeepAudio) encoding.AddRange(["-itsoffset", (-map.OriginTime).ToString("0.000000", CultureInfo.InvariantCulture), "-i", source.Path]);
        encoding.AddRange(["-map", "0:v:0", "-map_metadata", "-1", "-map_chapters", "-1", "-map_metadata:s:v", "-1", "-sn", "-dn"]);
        if (project.Export.KeepAudio) encoding.AddRange(["-map", "1:a:0?", "-map_metadata:s:a", "-1", "-c:a", webm ? "libopus" : "aac"]); else encoding.Add("-an");
        encoding.AddRange(["-c:v", webm ? "libvpx-vp9" : "libx264", "-pix_fmt", source.Width % 2 == 0 && source.Height % 2 == 0 ? "yuv420p" : "yuv444p", "-crf", project.Export.Quality == "High" ? "16" : project.Export.Quality == "Smaller" ? "28" : "21"]);
        if (webm) encoding.AddRange(["-b:v", "0"]); else encoding.AddRange(["-preset", "medium"]);
        if (Path.GetExtension(destination).Equals(".avi", StringComparison.OrdinalIgnoreCase)) encoding.AddRange(["-bf", "0", "-avoid_negative_ts", "disabled"]);
        encoding.AddRange(["-fps_mode", "passthrough", "-enc_time_base:v:0", "demux", "-metadata", "title=", "-metadata", "comment=", "-metadata", "description=", destination]);
        var decoding = new[] { "-v", "error", "-xerror", "-i", source.Path, "-map", "0:v:0", "-vf", MediaTools.CanonicalScale, "-fps_mode", "passthrough", "-f", "image2pipe", "-vcodec", "png", "pipe:1" };
        using var encoder = Start(encoding, true);
        Process decoderInstance;
        try { decoderInstance = Start(decoding, false); }
        catch { Stop(encoder); await encoder.WaitForExitAsync(); throw; }
        using var decoder = decoderInstance;
        using var registration = cancellation.Register(() => { Stop(encoder); Stop(decoder); });
        var encodeErrors = encoder.StandardError.ReadToEndAsync(); var decodeErrors = decoder.StandardError.ReadToEndAsync();
        var drain = encoder.StandardOutput.BaseStream.CopyToAsync(Stream.Null);
        try
        {
            var annotations = AnnotationRaster.Create(project, source.Width, source.Height);
            var transport = new TimestampedPngStream(encoder.StandardInput.BaseStream);
            await transport.BeginAsync(source.Width, source.Height, source.Duration, map.Frames[^1].Duration, cancellation);
            for (var i = 0; i < map.Frames.Count; i++)
            {
                cancellation.ThrowIfCancellationRequested();
                using var png = await TrackingAnalysis.ReadPngAsync(decoder.StandardOutput.BaseStream, cancellation, Math.Min(256L * 1024 * 1024, (long)source.Width * source.Height * 5 + 1024 * 1024));
                var image = new BitmapImage(); image.BeginInit(); image.CacheOption = BitmapCacheOption.OnLoad; image.StreamSource = png; image.EndInit(); image.Freeze();
                if (image.PixelWidth != source.Width || image.PixelHeight != source.Height) throw new InvalidDataException("Decoded effect frame dimensions changed.");
                var result = EffectRenderer.Render(image, project, map.Frames[i].Time, map, cancellation, annotations);
                var output = new PngBitmapEncoder(); output.Frames.Add(BitmapFrame.Create(result));
                using var encoded = new MemoryStream(); output.Save(encoded); encoded.Position = 0;
                await transport.FrameAsync(encoded.GetBuffer().AsMemory(0, checked((int)encoded.Length)), stamps[i], Math.Max(1, (long)Math.Round(map.Frames[i].Duration * 1_000_000)), cancellation);
                progress?.Report((i + 1d) / map.Frames.Count * .85);
            }
            var extra = new byte[1]; if (await decoder.StandardOutput.BaseStream.ReadAsync(extra, cancellation) != 0) throw new InvalidDataException("Unexpected extra decoded effect frame.");
            encoder.StandardInput.Close();
            await Task.WhenAll(decoder.WaitForExitAsync(cancellation), encoder.WaitForExitAsync(cancellation), drain);
            cancellation.ThrowIfCancellationRequested();
            if (decoder.ExitCode != 0 || encoder.ExitCode != 0) throw new IOException(Safe(await decodeErrors + "\n" + await encodeErrors, source.Path));
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            Stop(encoder); Stop(decoder);
            await Task.WhenAll(encoder.WaitForExitAsync(), decoder.WaitForExitAsync());
            cancellation.ThrowIfCancellationRequested();
            var message = Safe(await decodeErrors + "\n" + await encodeErrors, source.Path);
            throw new IOException("Effect video processing failed. " + (string.IsNullOrWhiteSpace(message) ? ex.Message : message), ex);
        }
        finally
        {
            Stop(encoder); Stop(decoder);
            await Task.WhenAll(encoder.WaitForExitAsync(), decoder.WaitForExitAsync(), drain, encodeErrors, decodeErrors);
        }
    }
    private static Process Start(IEnumerable<string> args, bool input)
    {
        var info = new ProcessStartInfo(Path.Combine(AppContext.BaseDirectory, "tools", "ffmpeg.exe"))
        { UseShellExecute = false, CreateNoWindow = true, RedirectStandardInput = input, RedirectStandardOutput = true, RedirectStandardError = true };
        foreach (var arg in args) info.ArgumentList.Add(arg);
        return Process.Start(info) ?? throw new IOException("Could not start approved effect processing.");
    }
    private static void Stop(Process process) { try { if (!process.HasExited) process.Kill(true); } catch (InvalidOperationException) { } }
    private static string Safe(string text, string path) { text = text.Replace(path, "[source media]", StringComparison.OrdinalIgnoreCase).Trim(); return text[..Math.Min(1500, text.Length)]; }
}
