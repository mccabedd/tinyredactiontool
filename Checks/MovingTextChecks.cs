using System.IO;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class MovingTextChecks
{
    public static async Task Playback(string path, Action<bool, string> check)
    {
        using var player = new LocalPlayback(silentTestOutput: true);
        await Task.Run(() => player.Open(path, 640, 360)); player.Play();
        for (var i = 0; i < 8; i++)
        {
            await Task.Delay(1000);
            Console.WriteLine($"Playback position {player.Position.TotalSeconds:0.000}, presented {player.PresentedTime:0.000}, frames {player.DisplayedFrames}");
        }
        check(player.PresentedTime > 7 && player.PresentedTime < 8.5, "presented playback timestamp follows the video clock");
    }
    public static async Task Run(string path, Action<bool, string> check, bool expectSceneChange = false)
    {
        using var tools = new MediaTools();
        var map = await tools.ProbeTimelineAsync(path, CancellationToken.None);
        var duration = map.Frames[^1].Time + map.Frames[^1].Duration;
        var media = new MediaReference(path, new FileInfo(path).Length, await ProjectStore.HashAsync(path), 640, 360, duration, true);
        var region = new Region { Start = 0, End = duration }; region.PutManual(0, new(60, 140, 200, 40));
        var result = await new TrackingAnalysis(tools).AnalyseAsync(media, map, region, 0, map.Frames.Count - 1, null, CancellationToken.None);
        Console.WriteLine($"Moving text samples: {result.Samples.Count}; ranges: {string.Join("; ", result.Segments)}");
        result.Apply(region, map);
        if (expectSceneChange)
        {
            check(result.Loss is { LastMatchedIndex: 95, FirstUnmatchedIndex: 96 } && result.Samples.Count == 95, "scene-change sample detects loss on the first frame of the new scene at 4s");
            var lossFrame = await tools.FrameAsync(path, map.Frames[96], null, CancellationToken.None);
            check(lossFrame.PixelWidth == 640 && lossFrame.PixelHeight == 360, "scene-change review frame decodes through TRT imaging");
            RedactionWorkflow.StopAt(region, map, 95);
            check(region.End == map.Frames[95].Time && region.Tracking.All(s => s.State == ReviewState.Unreviewed), "scene-change suggested end removes lost tail but retains review requirement");
            check(await ProjectStore.HashAsync(path) == media.Sha256, "scene-change sample remains unchanged");
            return;
        }
        check(result.Samples.Count == 287 && result.Segments.All(s => s.State == ReviewState.Unreviewed), "moving text follows all 288 frames without losing subject");
        var worst = 0d;
        foreach (var frame in map.Frames)
        {
            var u = Math.Clamp((frame.Time - 1) / 10, 0, 1);
            var x = 60 + 150 * (1 - Math.Cos(2 * Math.PI * u)); var y = 140 + 55 * Math.Sin(2 * Math.PI * u);
            var b = region.GeometryAt(frame.Time);
            worst = Math.Max(worst, Math.Max(Math.Abs(b.X - x), Math.Abs(b.Y - y)));
        }
        Console.WriteLine($"Worst moving text position error: {worst:0.00}px");
        check(worst < 5, "moving text box stays within five pixels of known path");
    }
}
