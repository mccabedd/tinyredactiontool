using System.IO;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class WorkflowChecks
{
    public static async Task Run(MediaTools tools, string output, Action<bool, string> check)
    {
        var path = Path.Combine(output, "tracking-pan.mp4"); var map = await tools.ProbeTimelineAsync(path, CancellationToken.None);
        var media = new MediaReference(path, new FileInfo(path).Length, await ProjectStore.HashAsync(path), 128, 96, map.Frames[^1].Time + map.Frames[^1].Duration, true);
        var region = new Region { Start = map.Frames[1].Time, End = media.Duration };
        region.PutManual(region.Start, new(27, 21, 16, 16));
        var project = new RedactionProject { Media = media, Regions = [region] };
        check(RedactionWorkflow.FollowSeed(region, map, map.Frames[^1].Time) == 1, "Follow returns to drawn start even after scrubbing to video end");
        check(RedactionWorkflow.FollowSeed(region, map, 0) == 1, "Follow returns to drawn start from before active range");
        var result = await new TrackingAnalysis(tools).AnalyseAsync(media, map, region,
            RedactionWorkflow.FollowSeed(region, map, media.Duration), map.IndexAt(region.End), null, CancellationToken.None);
        result.Apply(region, map);
        check(result.Samples.Count == 5 && region.End == media.Duration, "natural Follow analyses to video end without manually setting an end");
        check(RedactionWorkflow.FollowSeed(region, map, map.Frames[4].Time) == 1, "reviewing an automatic frame does not silently change Follow seed");
        region.PutManual(map.Frames[3].Time, new(33, 23, 16, 16));
        check(RedactionWorkflow.FollowSeed(region, map, map.Frames[3].Time) == 3, "Follow restarts from an explicit correction at the playhead");
        var correction = region.Keyframes.Single(k => k.Time == map.Frames[3].Time);
        var corrected = await new TrackingAnalysis(tools).AnalyseAsync(media, map, region, RedactionWorkflow.FollowSeed(region, map, correction.Time), map.IndexAt(region.End), null, CancellationToken.None);
        corrected.Apply(region, map);
        check(region.Keyframes.Single(k => k.Time == correction.Time) == correction, "natural Follow retains the corrected manual anchor");
        var before = region.GeometryAt(map.Frames[4].Time); var earlier = region.GeometryAt(map.Frames[2].Time);
        region.Tracking.Add(new(map.Frames[5].Time, map.Frames[6].Time, ReviewState.Lost, "Synthetic future loss"));
        var history = new EditHistory(); history.Checkpoint(project);
        check(RedactionWorkflow.StopAt(region, map, 4), "Stop redaction here shortens the active range");
        check(region.Start == map.Frames[1].Time && region.End == map.Frames[4].Time, "Stop preserves automatic start and chooses the exact displayed frame");
        check(region.GeometryAt(region.End) == before && region.GeometryAt(map.Frames[2].Time) == earlier, "Stop preserves boundary geometry and earlier interpolation");
        check(region.Keyframes.Single(k => k.Time == region.End).Origin == KeyframeOrigin.Tracking, "Stop does not invent a manual correction that could pin a later Follow pass");
        check(region.Keyframes.All(k => k.Time <= region.End) && region.Tracking.All(s => s.End <= region.End), "Stop removes future keys and clips review ranges");
        check(region.Tracking.All(s => s.State != ReviewState.Lost), "Stop before subject loss removes the out-of-range loss warning");
        check(region.Tracking.All(s => s.State != ReviewState.Reviewed), "Stop does not mark the remaining followed range as checked");
        var undone = history.Undo(project);
        check(undone.Regions[0].End == media.Duration && undone.Regions[0].Tracking.Any(s => s.State == ReviewState.Lost), "Undo restores stopped tail and its review/loss data");
        project = history.Redo(undone); region = project.Regions[0];
        check(region.End == map.Frames[4].Time, "Redo restores the chosen stop");
        var restored = ProjectStore.Deserialize(ProjectStore.Serialize(project));
        check(restored.Regions[0].End == region.End && restored.Regions[0].Keyframes.SequenceEqual(region.Keyframes), "natural workflow persists using the existing project schema");
        region.Tracking = region.Tracking.Select(s => s with { State = ReviewState.Reviewed }).ToList();
        ExportGate.Check(project, new()); check(true, "a shortened followed range passes the export gate");
        var destination = Path.Combine(output, "natural-workflow-stopped.mp4"); if (File.Exists(destination)) File.Delete(destination);
        await new VideoExport(tools).ExportAsync(destination, project, map, new(), null, CancellationToken.None);
        check((await tools.ProbeTimelineAsync(destination, CancellationToken.None)).Frames.Count == map.Frames.Count, "reviewed natural workflow exports with complete video and validation");
        RedactionWorkflow.StopAt(region, map, 6);
        check(region.Tracking.Any(s => s.State == ReviewState.Unreviewed && s.Start > map.Frames[4].Time), "extending a previously stopped followed range requires new review");
        var snapshot = ProjectStore.Serialize(project);
        try { RedactionWorkflow.StopAt(region, map, 0); throw new Exception("Stopped before start"); }
        catch (InvalidOperationException) { check(ProjectStore.Serialize(project) == snapshot, "Stop before the drawn start leaves the region unchanged"); }
        var single = new Region { Start = map.Frames[3].Time, End = map.Frames[3].Time }; single.PutManual(single.Start, new(33, 23, 16, 16));
        check(RedactionWorkflow.FollowSeed(single, map, 0) == -1, "one-frame redaction remains static instead of starting invalid Follow analysis");
        var stopFirst = new Region { Start = map.Frames[1].Time, End = media.Duration }; stopFirst.PutManual(stopFirst.Start, new(27, 21, 16, 16));
        RedactionWorkflow.StopAt(stopFirst, map, 4);
        var shortFollow = await new TrackingAnalysis(tools).AnalyseAsync(media, map, stopFirst, RedactionWorkflow.FollowSeed(stopFirst, map, stopFirst.End), map.IndexAt(stopFirst.End), null, CancellationToken.None);
        shortFollow.Apply(stopFirst, map);
        check(Math.Abs(stopFirst.GeometryAt(stopFirst.End).X - 36) < 2, "setting Stop before Follow does not pin the final box to its original position");
        check(await ProjectStore.HashAsync(path) == media.Sha256, "natural workflow leaves source media unchanged");
    }
}
