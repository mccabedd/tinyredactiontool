using System.Diagnostics;
using System.IO;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Desktop;

internal static class PlaybackChecks
{
    public static async Task Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var clip = Path.Combine(output, "playback-four-seconds.mp4");
        await tools.RunAsync("ffmpeg.exe", ["-v", "error", "-y", "-stream_loop", "3", "-i", Path.Combine(output, "synthetic-with-audio.mp4"), "-c", "copy", clip], clip, CancellationToken.None);
        using var player = new LocalPlayback(silentTestOutput: true);
        var available = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        player.FrameAvailable += (_, _) => available.TrySetResult();
        player.Open(clip, 96, 64);
        player.Play();
        await available.Task.WaitAsync(TimeSpan.FromSeconds(12));
        check(player.DisplayedFrames > 0 && player.FrameWidth == 96 && player.FrameHeight == 64, "private decoder renders actual video frames from file callbacks");
        await Task.Delay(350);
        check(player.HasAudioTrack, "private decoder recognises primary audio track (dummy test audio output)");
        var start = player.Position.TotalSeconds; var wall = Stopwatch.StartNew(); await Task.Delay(1000);
        var elapsed = player.Position.TotalSeconds - start;
        check(elapsed > 0.65 && elapsed < wall.Elapsed.TotalSeconds + 0.4, $"real-time decoder clock advances at 1x ({elapsed:0.000}s)");
        check(player.DecodedAudioBlocks > 0, "primary audio is actually decoded by the playback engine");
        var snapshot = player.SnapshotPixels();
        check(snapshot.Length == 96 * 64 * 4 && snapshot.Where((_, i) => i % 4 != 3).Any(v => v < 40), "decoded callback buffer contains moving synthetic subject");
        player.Pause(); await Task.Delay(200); var pausedTime = player.Position.TotalSeconds; var pausedPixels = player.SnapshotPixels();
        await Task.Delay(300);
        check(Math.Abs(player.Position.TotalSeconds - pausedTime) < 0.12 && pausedPixels.SequenceEqual(player.SnapshotPixels()), "pause holds native timestamp and decoded pixels (repeat redraw callbacks permitted)");
        player.Close(); player.Open(clip, 96, 64); player.SpeedRatio = 0.5; player.Play();
        await WaitUntil(() => player.Position.TotalSeconds > 0.25);
        start = player.Position.TotalSeconds; await Task.Delay(1000); elapsed = player.Position.TotalSeconds - start;
        check(elapsed > 0.2 && elapsed < 0.85, $"half-speed native playback ({elapsed:0.000}s per wall second)");
        player.Close(); player.Open(clip, 96, 64); player.SpeedRatio = 2; player.Play();
        await WaitUntil(() => player.Position.TotalSeconds > 0.5);
        start = player.Position.TotalSeconds; await Task.Delay(1000); elapsed = player.Position.TotalSeconds - start;
        check(elapsed > 1.45 && elapsed < 2.55, $"double-speed native playback ({elapsed:0.000}s per wall second, after native startup settled)");
        player.Pause(); player.Position = TimeSpan.FromSeconds(3.1); player.SpeedRatio = 1; player.Play(); await Task.Delay(350);
        check(player.Position.TotalSeconds > 2.8, "native seek resumes near requested timestamp");
        // 0.21.2: a place chosen while paused is only remembered; Play goes there once. Playing at 0.5x after the
        // jump starts the clock from the place asked for when the first picture arrives (no jump), then runs at 0.5x.
        player.Pause(); await Task.Delay(150); player.Position = TimeSpan.FromSeconds(1.0); player.SpeedRatio = 0.5;
        check(Math.Abs(player.Position.TotalSeconds - 1.0) < 0.001 && Math.Abs(player.PresentedTime - 1.0) < 0.001, "a place chosen while paused is remembered for Play");
        var before = player.DisplayedFrames; player.Play();
        await WaitUntil(() => player.DisplayedFrames > before);
        check(player.PresentedTime is >= 0.99 and < 1.15, $"after the jump the first picture shows the place asked for, not a later time ({player.PresentedTime:0.000}s)");
        await Task.Delay(700); start = player.PresentedTime; await Task.Delay(1000); elapsed = player.PresentedTime - start;
        check(elapsed is > 0.3 and < 0.75, $"then it plays at the chosen half speed ({elapsed:0.000}s per wall second)");
        player.Close(); check(!player.IsLoaded, "playback close releases source and native player");
        var formats = new[] { ("synthetic-vfr.mp4", 96, 64), ("synthetic-rotated.mp4", 64, 96), ("synthetic-sar.mp4", 192, 64) };
        foreach (var (name, width, height) in formats)
        {
            var rendered = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
            void Ready(object? sender, EventArgs args) => rendered.TrySetResult();
            player.FrameAvailable += Ready;
            player.Open(Path.Combine(output, name), width, height); player.Play();
            await rendered.Task.WaitAsync(TimeSpan.FromSeconds(12));
            var nativePixels = player.SnapshotPixels();
            check(player.FrameWidth == width && player.FrameHeight == height, "private decoder presents " + name);
            player.Close(); player.FrameAvailable -= Ready;
            var map = await tools.ProbeTimelineAsync(Path.Combine(output, name), CancellationToken.None);
            var exact = await tools.FrameAsync(Path.Combine(output, name), map.Frames[0], null, CancellationToken.None);
            var converted = new FormatConvertedBitmap(exact, PixelFormats.Bgra32, null, 0);
            var expected = new byte[width * height * 4]; converted.CopyPixels(expected, width * 4, 0);
            var actualCentre = DarkCentre(nativePixels, width, height); var expectedCentre = DarkCentre(expected, width, height);
            check(Math.Abs(actualCentre.X - expectedCentre.X) < 8 && Math.Abs(actualCentre.Y - expectedCentre.Y) < 8,
                "native decoded orientation/content agrees with canonical inspection: " + name);
        }
    }
    private static async Task WaitUntil(Func<bool> ready)
    {
        var timeout = Stopwatch.StartNew();
        while (!ready()) { if (timeout.Elapsed > TimeSpan.FromSeconds(8)) throw new TimeoutException("Playback clock did not settle."); await Task.Delay(30); }
    }
    private static (double X, double Y) DarkCentre(byte[] pixels, int width, int height)
    {
        double sx = 0, sy = 0, count = 0;
        for (var y = 0; y < height; y++) for (var x = 0; x < width; x++)
        { var i = (y * width + x) * 4; if (pixels[i] < 50 && pixels[i + 1] < 50 && pixels[i + 2] < 50) { sx += x; sy += y; count++; } }
        if (count == 0) throw new InvalidDataException("Synthetic subject missing from decoded buffer.");
        return (sx / count, sy / count);
    }
}
