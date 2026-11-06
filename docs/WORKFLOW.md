# Draw, follow, check, stop — development 0.5.0

Pause where the redaction should start, choose an effect and draw a region.
Drawing sets Start to the displayed exact frame and End to the video end.

**Follow subject** follows forward from that start without needing a manual
Begin/End setup or direction choice. Scrubbing elsewhere before clicking Follow
does not accidentally change the seed. A genuine manual correction at the
current frame is used instead, so pause/adjust/Follow is the correction workflow.
Following respects an existing shortened end in saved/edited projects.

Following is an analysis pass, not simultaneous live tracking during playback.
Progress and Cancel work remain available. The prepared result is committed
only after analysis and exact seed-image extraction succeed; cancellation keeps
the existing region/tracking. The playhead returns to that seed, paused and ready
for Play. Low texture, ambiguity and loss still stop the underlying experimental
appearance tracker. It is not a face detector or a guarantee of coverage.

**When Following loses the subject**, a comparison window shows the exact last
matched and first unmatched frames, with cyan box outlines. This is a loss of
appearance matching, not proof that the subject has left or a dedicated scene
classifier. Choose End redaction here to set the end to the last matched frame;
the normal two-frame export buffer still applies. Undo restores the original
tail. Earlier retained tracking remains unreviewed.

Choose Correct box and continue to open the exact first unmatched frame with
the Select tool. Move/resize the box over the subject (or scrub to its return
and correct it there), then press Follow. A manual correction provides the new
seed; earlier unresolved loss ranges remain for explicit inspection. Nothing
is automatically reacquired or marked reviewed. Keep range for later, Escape
or closing the window preserves the range and the unresolved loss. If the
initial selection cannot establish a match, no end suggestion is enabled.

Both comparison frames are extracted before the analysis result is committed;
cancellation or failed extraction retains the earlier region/tracking. Follow
is the same starting workflow for static and moving appearances.

**Stop redaction here** pauses live playback and obtains an exact frame before
changing the end. It shortens the selected redaction, not the video itself. It
preserves the interpolated boundary geometry and earlier animation, removes
future keys, clips retained review ranges and removes losses beyond the stop.
It does not invent a manual geometric correction at the stop: a later Follow
pass may replace that computed boundary. Existing manual corrections are kept.
Undo/Redo restores the corresponding whole project state. The inherited export
coverage margin and two-frame temporal buffer still apply.

Stopping before the start is rejected without changing data. Extending a
previously followed range makes the added tail Unreviewed. A one-frame range can
remain a fixed redaction; Follow is disabled because no later frame exists.

**I've checked the whole range** retains the existing explicit review prompt.
Stopping never marks automatic data reviewed. Unresolved tracking still blocks
export. Review only the retained active range, correcting any drift or loss.

The main panel shows Follow and Stop. Backward tracking, explicit forward
tracking, manual Begin/End, numerical properties and keyframes remain under
Region details and keyframes. Projects use the existing schema; no migration
or source-media modification is needed. Full inherited feature parity remains
unfinished and all entries in FEATURE-PARITY.md remain required.

## Build isolation

This milestone is built in artifacts/0.4.0 because an earlier app was open.
Build-Dev writes version-specific outputs and updates current-build.txt only
after successful build/checks. Run-Dev opens that relative, in-folder path using
the private SDK/runtime. Existing open windows and their unsaved work are left
alone; save a project there if you want to reopen it in the new version.
