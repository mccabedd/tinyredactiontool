namespace TinyRedaction.Core;

public static class RedactionWorkflow
{
    // Reviewing elsewhere must not accidentally change the initial tracking seed.
    // An explicit manual correction at the playhead is the exception.
    public static int FollowSeed(Region region, FrameTimeline map, double playhead)
    {
        var first = map.IndexAt(region.Start); var last = map.IndexAt(region.End);
        if (map.Frames[first].Time < region.Start) first++;
        if (first >= last) return -1;
        var current = map.IndexAt(playhead);
        if (current >= first && current < last && region.Keyframes.Any(k =>
            k.Origin == KeyframeOrigin.Manual && Math.Abs(k.Time - map.Frames[current].Time) < .0000001)) return current;
        return first;
    }

    public static bool StopAt(Region region, FrameTimeline map, int frameIndex)
    {
        var time = map.Frames[frameIndex].Time;
        if (time < region.Start) throw new InvalidOperationException("Move to or after this redaction's start before stopping it.");
        if (Math.Abs(time - region.End) < .0000001) return false;
        var oldEnd = region.End; var hadTracking = region.Tracking.Count > 0;
        // Capture the interpolated boundary before removing future anchors.
        var boundary = region.GeometryAt(Math.Min(time, oldEnd));
        var manualBoundary = region.Keyframes.Any(k => Math.Abs(k.Time - time) < .0000001 && k.Origin == KeyframeOrigin.Manual);
        if (manualBoundary) region.PutManual(time, boundary);
        else
        {
            // Stopping is not a geometric correction. Keep this boundary
            // replaceable by a later Follow pass, rather than pinning the subject.
            region.Keyframes.RemoveAll(k => Math.Abs(k.Time - time) < .0000001);
            region.Keyframes.Add(new(time, boundary, KeyframeOrigin.Tracking));
            region.Keyframes.Sort((a, b) => a.Time.CompareTo(b.Time));
        }
        region.Keyframes.RemoveAll(k => k.Time > time);
        region.End = time;
        region.Tracking = region.Tracking.Where(s => s.Start <= time && s.End >= region.Start)
            .Select(s => s with { Start = Math.Max(s.Start, region.Start), End = Math.Min(s.End, time) }).ToList();
        if (hadTracking && map.IndexAt(time) > map.IndexAt(oldEnd))
        {
            var next = map.Frames[map.IndexAt(oldEnd) + 1].Time;
            region.Tracking.Add(new(next, time, ReviewState.Unreviewed, "End extended; follow or inspect the added range before reviewing."));
        }
        return true;
    }
}
