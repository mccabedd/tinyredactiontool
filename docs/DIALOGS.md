# TRT dialogue box text (for review, 0.21.4 / 0.22.0 sources)

**Applied in 0.22.4:** David's marked-up copy (3 Nov), "go with the suggestions": every row whose Suggested column
gives a wording (111 rows) now shows it; rows marked "—" or "keep: safety" are unchanged. The Now column below is the
text before 0.22.4. Row 6: the extra sentence about unsaved changes is gone ("Any changes will be lost" covers it).
Row 77 changes the quit box's title only, not the notification-area menu item.

Every piece of text TRT shows in a dialogue box, grouped by where it appears. **Now** is the current text.
**Suggested** is a shorter, plainer wording to consider ("—" means keep it as it is; "— (keep: safety)"
means the wording carries a safety, policy or privacy meaning and should not be weakened).

Nothing has been changed yet: mark the ones you want (or write your own wording in Suggested), and they
will be applied by find-and-replace, as was done for the tooltips. Tooltips are not listed here; they are
in TOOLTIPS.md.

How to read the Now column:

- `{…}` stands for a value filled in at the time, for example `{file}` (a file name) or `{CaptureKind}`
  (the word "screenshot" or "recording").
- ` / ` marks a line break in the box (`\n` in the source); ` / / ` is a blank line between paragraphs.
  Where a real slash is part of the text, the row says so.
- `(+ when …: …)` is a sentence added only in that situation.
- Yes / No / OK / Cancel on Windows message boxes are drawn by Windows and cannot be reworded.
- Text that comes from Windows or .NET itself (for example "Access to the path … is denied") is not listed:
  it cannot be changed by find-and-replace.

## Start-up

| #   | Where                                                                                       | Now                                                      | Suggested                                |
| --- | ------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ---------------------------------------- |
| 1   | App.xaml.cs:46 · TRT cannot start (box title)                                               | Startup blocked                                          | Application could not start              |
| 2   | App.xaml.cs:46 · TRT cannot start (message; the error comes from the Start-up errors below) | The development application could not start. / / {error} | Application could not start. / / {error} |

## Editor: closing and unsaved work

| #   | Where                                                                                                                                          | Now                                                                                                                                                                                              | Suggested                                                                                                                |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| 3   | MainWindow.xaml.cs:89 · closing the editor while a task is running (title)                                                                     | Work in progress                                                                                                                                                                                 | Still working                                                                                                            |
| 4   | MainWindow.xaml.cs:89 · same box (message)                                                                                                     | Cancel the current operation and wait for it to finish before closing.                                                                                                                           | Cancel the current task and wait for it to stop, then close.                                                             |
| 5   | MainWindow.xaml.cs:101 and MainWindow.Capture.cs:50 · title of the unsaved-capture questions (source is `"Unsaved " + CaptureKind`)            | Unsaved {CaptureKind}                                                                                                                                                                            | —                                                                                                                        |
| 6   | MainWindow.Capture.cs:68 · closing the editor, or opening other media, while a capture is neither saved nor exported                           | This {CaptureKind} hasn't been saved or exported. TRT will wipe its copy. (+ when project changes are unsaved: " Your unsaved changes will be lost too.") / / Continue?                          | This {CaptureKind} has not been saved or exported. Any changes will be lost.") / / Continue?                             |
| 7   | MainWindow.Capture.cs:50 · a new screenshot or recording arrives while the open capture is unsaved ({incoming} is "screenshot" or "recording") | Open the new {incoming} instead? / / The {CaptureKind} you have open hasn't been saved or exported, so TRT will wipe its copy. (+ when changed: " Your unsaved changes to it will be lost too.") | Open the new {incoming} instead? / / The current {CaptureKind} has not been saved or exported. Any changes will be lost. |
| 8   | MainWindow.xaml.cs:102 · closing or opening other media with unsaved project changes (title)                                                   | Unsaved changes                                                                                                                                                                                  | —                                                                                                                        |
| 9   | MainWindow.xaml.cs:102 · same box (message)                                                                                                    | Discard unsaved project changes?                                                                                                                                                                 | Discard your unsaved changes?                                                                                            |

## Editor: opening, saving and exporting

| #   | Where                                                                                                                                                                         | Now                                                                                                                                               | Suggested                                                                                                                                        |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 10  | MainWindow.xaml.cs:230 · File › Open in a picture editor window (file dialog title)                                                                                           | Open a picture                                                                                                                                    | —                                                                                                                                                |
| 11  | MainWindow.xaml.cs:230 · File › Open in the main editor (file dialog title)                                                                                                   | Open media for local editing                                                                                                                      | Open a picture or video                                                                                                                          |
| 12  | MainWindow.xaml.cs:173 · the "Operation failed" box: any editor task that fails (title)                                                                                       | TinyRedactionTool development                                                                                                                     | TinyRedactionTool                                                                                                                                |
| 13  | MainWindow.xaml.cs:173 · same box (message: one of the Errors below; the open file's path is shown as [source media])                                                         | {error}                                                                                                                                           | —                                                                                                                                                |
| 14  | MainWindow.xaml.cs:225 · opening from or saving to a network drive (title)                                                                                                    | Network path                                                                                                                                      | Network path                                                                                                                                     |
| 15  | MainWindow.xaml.cs:225 · saving a project, export or copy to a network drive                                                                                                  | This destination is on a network or mapped drive. Save the exported media there?                                                                  | This folder is on a network or mapped drive. Save there?                                                                                         |
| 16  | MainWindow.xaml.cs:225 · opening media or a project from a network drive                                                                                                      | This source is on a network or mapped drive. Open unredacted media from it?                                                                       | — (keep: safety)                                                                                                                                 |
| 17  | MainWindow.xaml.cs:298 · opening a project whose original file has moved (title)                                                                                              | Relink source                                                                                                                                     | Find the original                                                                                                                                |
| 18  | MainWindow.xaml.cs:298 · same box (message)                                                                                                                                   | The source is missing. Select the original media to relink. Its full SHA-256 fingerprint must match.                                              | The original file can't be found. Choose it again: it must be exactly the same file.                                                             |
| 19  | MainWindow.xaml.cs:299 · the file dialog that follows (title)                                                                                                                 | Find original source                                                                                                                              | Find the original file                                                                                                                           |
| 20  | MainWindow.xaml.cs:516 · Apply in the redaction properties with a wrong value (title)                                                                                         | Invalid properties                                                                                                                                | Can't use these values                                                                                                                           |
| 21  | MainWindow.xaml.cs:516 · same box (message: a .NET number message such as "The input string … was not in a correct format.", or a project check from Errors › Project checks) | {error}                                                                                                                                           | —                                                                                                                                                |
| 22  | MainWindow.xaml.cs:725 · Export of a video with Keep audio ticked (title)                                                                                                     | Unredacted audio                                                                                                                                  | — (keep: safety)                                                                                                                                 |
| 23  | MainWindow.xaml.cs:725 · same box (message)                                                                                                                                   | Audio is not inspected or redacted. Retain the primary audio track only after reviewing it separately?                                            | — (keep: safety). Plainer, same meaning: "TRT does not check or redact sound. Keep the sound only if you have listened to it yourself. Keep it?" |
| 24  | MainWindow.xaml.cs:734 · picture export to a name without a supported ending (title)                                                                                          | Image format                                                                                                                                      | —                                                                                                                                                |
| 25  | MainWindow.xaml.cs:734 · same box (message)                                                                                                                                   | Choose a .png, .jpg, .gif or .webp file name.                                                                                                     | —                                                                                                                                                |
| 26  | MainWindow.xaml.cs:776 · after a checked export, when Delete original is ticked (title)                                                                                       | Delete the original                                                                                                                               | — (keep: safety)                                                                                                                                 |
| 27  | MainWindow.xaml.cs:776 · same box (message)                                                                                                                                   | Export saved as {exported}. / / Securely delete the original, {original}, now? TRT overwrites it with zeros and deletes it. This can't be undone. | — (keep: safety)                                                                                                                                 |
| 28  | MainWindow.Capture.cs:87 and :165 · Original or Save media as… onto a file that exists (title)                                                                                | Replace file                                                                                                                                      | —                                                                                                                                                |
| 29  | MainWindow.Capture.cs:87 and :165 · same box (message)                                                                                                                        | {file} already exists. Replace it?                                                                                                                | —                                                                                                                                                |
| 30  | MainWindow.Capture.cs:86 · Original with only "Delete TRT's capture file" ticked (title)                                                                                      | Wipe capture                                                                                                                                      | —                                                                                                                                                |
| 31  | MainWindow.Capture.cs:86 · same box (message)                                                                                                                                 | Wipe this {CaptureKind} without saving a copy? It closes in the editor. (+ when changed: " Your unsaved changes will be lost too.")               | — (keep: safety)                                                                                                                                 |

## About box

Help › About in the editor (MainWindow.xaml.cs:984) and About on the capture bar menu (CaptureController.cs:623-624).
The message is built from the pieces below (MainWindow.xaml.cs:986-996); each paragraph is followed by a blank line.

| # | Where | Now | Suggested |
|---|---|---|---|
| 32 | MainWindow.xaml.cs:984, CaptureController.cs:623-624 · title | About this development build | About TinyRedactionTool |
| 33 | MainWindow.xaml.cs:986 | TinyRedactionTool 0.22.0 (development build) / C# rewrite of mccabedd/TinyRedactionTool · GPL-2.0-or-later | — |
| 34 | MainWindow.xaml.cs:987 | Redact and annotate pictures and videos on this computer. Nothing is uploaded and there is no telemetry. | — |
| 35 | MainWindow.xaml.cs:988 | Capture: active window, window or object, rectangular and freehand region, full screen, scrolling window and screen recording (picture only, no sound); a measuring screen ruler; the capture bar can hide in a red tab or in the notification area; start with Windows; shortcuts. | Capture: windows, regions, full screen, scrolling windows and screen recordings (picture only, no sound); a screen ruler; shortcuts. |
| 36 | MainWindow.xaml.cs:989 | Redact: coloured box, Blur and Pixelate (Default or Aggressive) in rectangles, ovals and polygons; tracking that moves a box with its subject; Clear all redactions. | — |
| 37 | MainWindow.xaml.cs:990 | Annotate: text, outline, ellipse, line and polyline (arrow and dot ends, dashes), pen; turn any shape with its rotate handle or Edit › Transform; select several with a dashed box; turn or flip the whole picture or video (Edit › Rotate); crop; Copy and Paste; Save media as… (the file as it is); Capture frame from a video. | Annotate: text, shapes, lines, arrows and pen; turn, flip and crop; Copy and Paste; Save media as…; Capture frame from a video. |
| 38 | MainWindow.xaml.cs:991 | Video: Trim with A and B marks (delete A–B, or keep only A–B) and Append another video at the beginning or end; the sound stays in step and redactions and annotations stay on their frames. | Video: Trim between A and B marks and Append another video; sound, redactions and annotations stay in step. |
| 39 | MainWindow.xaml.cs:992 | Export: PNG, JPG, GIF and WebP pictures and MP4, MOV, M4V, AVI, MKV and WebM videos, each checked after it is written. The original is never changed; it can be securely deleted after export if you choose. | — (keep: safety) |
| 40 | MainWindow.xaml.cs:993 | Captures opened in the editor live in a private temporary folder and are wiped when closed or when TRT quits. | — (keep: safety) |
| 41 | MainWindow.xaml.cs:994 | Live playback is a preview capped at 1280 pixels; edit on exact paused frames. | Playback is a preview (up to 1280 pixels); edit on paused frames. |
| 42 | MainWindow.xaml.cs:995 | Tracking can drift: play each tracked range through yourself. Blur and Pixelate hide appearance but are not guaranteed removal; use a coloured box when nothing may show. | — (keep: safety) |
| 43 | MainWindow.xaml.cs:996 | Development build, not yet a release: see docs/FEATURE-PARITY.md. | — |

## Tracking range box

Track forward or Track backward when tracking cannot start (MainWindow.xaml.cs:896, texts from :906-916).

| # | Where | Now | Suggested |
|---|---|---|---|
| 44 | MainWindow.xaml.cs:896 · title | Tracking range | Can't track yet |
| 45 | MainWindow.xaml.cs:910 · the playhead is outside the redaction's time (the " / " here is a real slash in the text) | Move the playhead inside the selected region's Begin / End range first. | Move the playhead between the redaction's Begin and End first. |
| 46 | MainWindow.xaml.cs:913 · the redaction lasts one frame | This region covers only one video frame. Set Begin here on an earlier frame and End here on a later frame, then track. | This redaction is one frame long. Set Begin and End on different frames, then track. |
| 47 | MainWindow.xaml.cs:914 · Track forward from the redaction's end | The playhead is already at this region's end. Move back to the region's beginning, then click Track forward. Tracking needs at least two different frames. | This is the redaction's end. Go back to its beginning, then click Track forward. |
| 48 | MainWindow.xaml.cs:915 · Track backward from the redaction's beginning | The playhead is already at this region's beginning. Move to the region's end, then click Track backward. Tracking needs at least two different frames. | This is the redaction's beginning. Go to its end, then click Track backward. |

## Capture bar, screenshots and recordings (CaptureController.cs)

| # | Where | Now | Suggested |
|---|---|---|---|
| 49 | CaptureController.cs:282 · the ruler's Rectangle, Distance or Angle fails (title) | Screen ruler | — |
| 50 | CaptureController.cs:282 · same box (message) | The screen could not be measured: {error} | Couldn't measure the screen: {error} |
| 51 | CaptureController.cs:344 · a shortcut is taken by another program, at start or after Settings (title) | Capture shortcuts | Shortcuts |
| 52 | CaptureController.cs:344 · same box (first sentence; {list} is built from rows 53-56) | Windows would not give TRT these shortcuts because another program already uses them: {list}. | Another program already uses these shortcuts: {list}. |
| 53 | CaptureController.cs:337 · list item after the shortcut | (screenshot) | — |
| 54 | CaptureController.cs:338 · list item | (recording) | — |
| 55 | CaptureController.cs:339 · list item | (show or hide the capture bar) | — |
| 56 | CaptureController.cs:340 · list item | (open the editor) | — |
| 57 | CaptureController.cs:345 · added when TinyRedactionTool v2.5 is running | / / The installed TinyRedactionTool (v2.5) is running and uses the same shortcuts. Quit it (right-click its notification-area icon, Quit), then open Settings here and click OK to take the shortcuts over. | / / TinyRedactionTool v2.5 is running and uses them. Quit it (right-click its icon, Quit), then open Settings and click OK. |
| 58 | CaptureController.cs:346 · last paragraph | / / The capture bar and its notification-area icon still work. You can also choose other shortcuts in Settings. | / / The capture bar and its icon still work. You can choose other shortcuts in Settings. |
| 59 | CaptureController.cs:382, :385 · a screenshot fails (title) | Screen capture | — |
| 60 | CaptureController.cs:382, :385 · same box (message: see Errors › Capture and recording) | {error} | — |
| 61 | CaptureController.cs:518 · saving a screenshot to a network drive (title) | Network path | Network drive |
| 62 | CaptureController.cs:517 · same box (message) | This destination is on a network or mapped drive. Save the capture there? | This folder is on a network or mapped drive. Save the capture there? |
| 63 | CaptureController.cs:528 · the editor did not open a new capture (title; source is `"New " + kind`, {kind} is "screenshot" or "recording") | New {kind} | — |
| 64 | CaptureController.cs:528 · same box (message) | The new {kind} was not opened. Save it to a file before TRT wipes it? | The new {kind} didn't open. Save it before TRT wipes it? |
| 65 | CaptureController.cs:591 · Settings could not add or remove "Open with TRT" (title) | Open with TRT | — |
| 66 | CaptureController.cs:591 · same box (message) | Windows did not allow the right-click menu to be changed: {error} | Windows wouldn't let TRT change the right-click menu: {error} |
| 67 | CaptureController.cs:596 · Settings could not add or remove the startup entry (title) | Start with Windows | — |
| 68 | CaptureController.cs:596 · same box (message) | Windows did not allow the startup entry to be changed: {error} | Windows wouldn't let TRT change starting with Windows: {error} |
| 69 | CaptureController.cs:674 · Discard on the yellow recording bar (title) | Discard recording | — |
| 70 | CaptureController.cs:674 · same box (message) | Discard this recording? TRT wipes it. | — |
| 71 | CaptureController.cs:696, :742, :746 · a recording fails to start, finish or open (title) | Screen recording | — |
| 72 | CaptureController.cs:742 · the recording failed while recording or finishing ({error} may be empty, or one of rows 293-297) | The recording could not be completed. {error} | The recording failed. {error} |
| 73 | CaptureController.cs:696, :746 · the recording could not start or open (message: see Errors › Capture and recording) | {error} | — |
| 74 | CaptureController.cs:756 · at start, captures left over from a TRT that did not close normally (title) | Leftover captures | — |
| 75 | CaptureController.cs:755 · same box (message) | TRT found {count} screenshot or recording file(s) left from an earlier TRT session that did not close normally. They are unredacted copies in: / {temporaryFolder} / / Wipe them now? (No keeps them; TRT asks again next time.) | TRT found {count} unredacted capture file(s) left from a session that didn't close properly, in: / {temporaryFolder} / / Wipe them now? (No keeps them; TRT asks again next time.) |
| 76 | CaptureController.cs:759 · some leftovers could not be wiped (title is row 74) | Some leftover captures could not be wiped. TRT will offer again next time. | Some leftover captures couldn't be wiped. TRT will ask again next time. |
| 77 | CaptureController.cs:769 · Quit while recording (title) | Quit TinyRedactionTool | Quit TRT |
| 78 | CaptureController.cs:769 · same box (message) | A recording is in progress. Discard it and quit? | You are recording. Discard it and quit? |
| 79 | CaptureController.cs:776 · Quit could not wipe some captures (title) | Quit | — |
| 80 | CaptureController.cs:776 · same box (message; one file per line) | TRT could not wipe these captures. Please delete them yourself: / {files} | — (keep: safety) |

## Capture frame window

File › Capture frame (or the toolbar button) on a video; built in code in MainWindow.Capture.cs AskFrameUse.

| # | Where | Now | Suggested |
|---|---|---|---|
| 81 | MainWindow.Capture.cs:239 · window title | Capture frame | — |
| 82 | MainWindow.Capture.cs:251 · heading ({time} as hh:mm:ss.fff) | Frame {n} at {time} | — |
| 83 | MainWindow.Capture.cs:236 · tick box | Include redactions and annotations | — |
| 84 | MainWindow.Capture.cs:243 · button | Save as… | — |
| 85 | MainWindow.Capture.cs:243 · button | Copy | — |
| 86 | MainWindow.Capture.cs:243 · button | Edit | — |
| 87 | MainWindow.Capture.cs:249 · button | Cancel | — |

## Keep the original capture window (Original button)

KeepCaptureWindow.xaml / .xaml.cs, opened from the Original button on a screenshot or recording.

| # | Where | Now | Suggested |
|---|---|---|---|
| 88 | KeepCaptureWindow.xaml:2 · window title | Keep the original capture | Original capture |
| 89 | KeepCaptureWindow.xaml:8 · heading (placeholder; replaced by row 90 when the window opens) | Save or copy the screenshot exactly as captured | — |
| 90 | KeepCaptureWindow.xaml.cs:17 · heading ({kind} is "recording" or "screenshot") | Save or copy the {kind} exactly as captured | Save or copy the {kind} as captured |
| 91 | KeepCaptureWindow.xaml:10 · warning under the heading | Nothing you have added is included: no redactions, annotations or crop. To share a redacted copy, use Export instead. | — (keep: safety) |
| 92 | KeepCaptureWindow.xaml:11 · tick box | Save a copy as | — |
| 93 | KeepCaptureWindow.xaml:15 · button | Browse… | — |
| 94 | KeepCaptureWindow.xaml:17 · tick box | Copy to the clipboard | — |
| 95 | KeepCaptureWindow.xaml:19 · note, recordings only | A recording is copied as the saved file, ready to paste into a folder, a chat or an email. | A recording is copied as the saved file, ready to paste. |
| 96 | KeepCaptureWindow.xaml:20 · tick box | Delete TRT's capture file afterwards | — |
| 97 | KeepCaptureWindow.xaml:22 · note under it | TRT keeps each capture in a private temporary folder and wipes it when you close it or quit TRT. Tick this to wipe it now. If you saved a copy, the editor carries on with that copy. | TRT wipes its capture when you close it or quit. Tick to wipe it now; if you saved a copy, the editor uses that. |
| 98 | MainWindow.Capture.cs:75 · replaces row 97 (and is the tick box's tooltip) when policy turns deleting off | Your organisation's policy turns off deleting originals. TRT still wipes its own copy when you close the capture or quit. | — (keep: policy) |
| 99 | KeepCaptureWindow.xaml.cs:38 · message: Copy ticked for a recording without Save | To copy a recording, also save a copy: the clipboard holds the saved file. | To copy a recording, also save it. |
| 100 | KeepCaptureWindow.xaml.cs:39 · message: Delete ticked without Save | Without a saved copy, deleting wipes the capture and closes it in the editor. | — (keep: safety) |
| 101 | KeepCaptureWindow.xaml.cs:40 · message: nothing ticked | Choose at least one thing to do. | — |
| 102 | KeepCaptureWindow.xaml.cs:46 · message: no folder chosen | Choose where to save the copy. | — |
| 103 | KeepCaptureWindow.xaml.cs:47 · message: wrong file ending (recording) | Save the recording as an .mp4 file. | — |
| 104 | KeepCaptureWindow.xaml.cs:47 · message: wrong file ending (screenshot) | Save the screenshot as a .png file. | — |
| 105 | KeepCaptureWindow.xaml:25 · button | OK | — |
| 106 | KeepCaptureWindow.xaml:26 · button | Cancel | — |

## Screen Recorder window

RecorderWindow.xaml, from the capture bar's Screen recorder button.

| # | Where | Now | Suggested |
|---|---|---|---|
| 107 | RecorderWindow.xaml:2 · window title | Screen Recorder | — |
| 108 | RecorderWindow.xaml:6 · heading | What to record | — |
| 109 | RecorderWindow.xaml:7 · choice | Rectangular region: drag round the area | Rectangle: drag round the area |
| 110 | RecorderWindow.xaml:8 · choice | Window: click the window to record | — |
| 111 | RecorderWindow.xaml:9 · choice | Full screen: the screen with the mouse pointer | Full screen: the screen with the cursor |
| 112 | RecorderWindow.xaml:10 · choice | Full screen without the taskbar | — |
| 113 | RecorderWindow.xaml:12 · label | Frames per second | — |
| 114 | RecorderWindow.xaml:15 · tick box | Record the mouse pointer | — |
| 115 | RecorderWindow.xaml:16 · tick box | Show mouse clicks (a yellow ring while a button is pressed) | Show mouse clicks (yellow ring) |
| 116 | RecorderWindow.xaml:18 · note | Screen only: no sound is recorded. A yellow bar lets you pause, stop or discard. When you stop, the recording opens in the editor so you can redact it. | No sound is recorded. Use the yellow bar to pause, stop or discard; the recording then opens in the editor. |
| 117 | RecorderWindow.xaml:20 · button | Record | — |
| 118 | RecorderWindow.xaml:21 · button | Cancel | — |

## Video editing

| # | Where | Now | Suggested |
|---|---|---|---|
| 119 | MainWindow.Video.cs:101 · Append: choose the video to add (file dialog title) | Append which video? | Choose a video to add |
| 120 | MainWindow.Video.cs:103 · Append: where to add it (title) | Append video | — |
| 121 | MainWindow.Video.cs:103 · same box (message; three spaces before "No:") | Add {file} at the end of this video? / / Yes: at the end.   No: at the beginning. | — |

## Tracking stopped window

FollowLossReview.xaml / .xaml.cs, shown when Track loses the subject.

| # | Where | Now | Suggested |
|---|---|---|---|
| 122 | FollowLossReview.xaml:2 · window title | Tracking stopped | — |
| 123 | FollowLossReview.xaml:6 · heading | Tracking lost the subject | — |
| 124 | FollowLossReview.xaml:7 · text under the heading | TRT could not find the subject in the frame on the right. Something may be in the way, the picture may have changed, or the subject may have left the frame. Nothing has been changed yet. | TRT lost the subject in the right-hand frame: something may be in the way, or it moved or left the frame. Nothing has changed yet. |
| 125 | FollowLossReview.xaml.cs:18 · label over the left picture ({time} in seconds); also the large viewer's title | Last frame tracked · {time} s | — |
| 126 | FollowLossReview.xaml.cs:18 · left label when nothing was tracked | The subject was not found after the first frame | — |
| 127 | FollowLossReview.xaml.cs:19 · label over the right picture; also the large viewer's title | Where tracking stopped · {time} s | — |
| 128 | FollowLossReview.xaml.cs:25 · explanation, first part (ends with a space) | The blue outline shows where the box is; click a picture to see it larger. | The blue outline is the box; click a picture to enlarge it. |
| 129 | FollowLossReview.xaml.cs:26 · explanation, added when there is a tracked frame (ends with a space) | End redaction here ends it on the left frame. | — |
| 130 | FollowLossReview.xaml.cs:27 · explanation, last part | Adjust the box lets you move or resize it on the right frame, then track again. Continue redaction keeps the box and carries on tracking. | — |
| 131 | FollowLossReview.xaml:14 · button | End redaction here | — |
| 132 | FollowLossReview.xaml:15 · button | Adjust the box | — |
| 133 | FollowLossReview.xaml:16 · button | Continue redaction | — |
| 134 | FollowLossReview.xaml.cs:64 · large viewer (click a picture): button | Close | — |
| 135 | FollowLossReview.xaml.cs:70 · large viewer: button while showing the close-up | Show whole frame | — |
| 136 | FollowLossReview.xaml.cs:70 · large viewer: button while showing the whole frame | Close-up of the box | — |

## Settings window

SettingsWindow.xaml / .xaml.cs. In the XAML, the quotation marks in rows 147-148 are written `&quot;`.

| # | Where | Now | Suggested |
|---|---|---|---|
| 137 | SettingsWindow.xaml:2 · window title | Settings | — |
| 138 | SettingsWindow.xaml:9 · tab | General | — |
| 139 | SettingsWindow.xaml:11 · heading | Starting TRT | — |
| 140 | SettingsWindow.xaml:12 · tick box | Start TRT when Windows starts | — |
| 141 | SettingsWindow.xaml:13 · note | It starts quietly in the notification area; its shortcuts work straight away. For your Windows user only; clear the tick to remove it. | It starts quietly in the notification area. For your Windows user only. |
| 142 | SettingsWindow.xaml:14 · heading | Theme | — |
| 143 | SettingsWindow.xaml:16 · choice | Light | — |
| 144 | SettingsWindow.xaml:17 · choice | Dark | — |
| 145 | SettingsWindow.xaml:18 · choice | Same as Windows | — |
| 146 | SettingsWindow.xaml:20 · heading | File Explorer | — |
| 147 | SettingsWindow.xaml:21 · tick box | Add "Open with TRT" to the right-click menu of pictures and videos | Add "Open with TRT" to the right-click menu |
| 148 | SettingsWindow.xaml:22 · note | For your Windows user only. On Windows 11 it is under "Show more options". Clear the tick to remove it. | For your Windows user only. On Windows 11 it is under "Show more options". |
| 149 | SettingsWindow.xaml:24 · heading | Settings file | — |
| 150 | SettingsWindow.xaml:26 · button | Export settings… | — |
| 151 | SettingsWindow.xaml:27 · button | Import settings… | — |
| 152 | SettingsWindow.xaml:29 · note | Imported settings fill in this window; press OK to use them. | — |
| 153 | SettingsWindow.xaml:32 · tab | Shortcuts | — |
| 154 | SettingsWindow.xaml:34 · note | Click a box, then press the keys you want. They work while TRT runs, even with the capture bar hidden. Screenshot captures a rectangular region; Recording starts or stops recording a region. | Click a box, then press the keys. Screenshot captures a rectangle; Recording starts or stops recording one. |
| 155 | SettingsWindow.xaml:38 · label | Screenshot | — |
| 156 | SettingsWindow.xaml:40 · label | Recording | — |
| 157 | SettingsWindow.xaml:42 · label | Show or hide the capture bar | — |
| 158 | SettingsWindow.xaml:45 · label | Open the editor | — |
| 159 | SettingsWindow.xaml:44, :47 · button; also SettingsWindow.xaml.cs:106 · shown in a box with no shortcut | None | — |
| 160 | SettingsWindow.xaml:50 · button | Reset shortcuts to defaults | — |
| 161 | SettingsWindow.xaml.cs:129 · message: a key without Ctrl or Alt | Use Ctrl or Alt with the key (Print Screen and F1–F24 also work on their own). | — |
| 162 | SettingsWindow.xaml.cs:137 · message: the keys are already used ({what} is one of rows 163-166) | {shortcut} is already used for {what}. | — |
| 163 | SettingsWindow.xaml.cs:12 · {what} | the screenshot | — |
| 164 | SettingsWindow.xaml.cs:12 · {what} | recording | — |
| 165 | SettingsWindow.xaml.cs:12 · {what} | showing or hiding the capture bar | — |
| 166 | SettingsWindow.xaml.cs:12 · {what} | opening the editor | — |
| 167 | SettingsWindow.xaml:53 · tab | Capture | — |
| 168 | SettingsWindow.xaml:56 · label | Delay before capture | — |
| 169 | SettingsWindow.xaml:58 · label after the number | seconds | — |
| 170 | SettingsWindow.xaml:60 · tick box | Include the mouse pointer in screenshots | — |
| 171 | SettingsWindow.xaml:62 · label | Full screen with several monitors | — |
| 172 | SettingsWindow.xaml:63 · choice | The screen with the mouse pointer | The screen with the cursor |
| 173 | SettingsWindow.xaml:63 · choice | All screens | — |
| 174 | SettingsWindow.xaml:65 · heading | Screen recording | — |
| 175 | SettingsWindow.xaml:67 · label | Frames per second | — |
| 176 | SettingsWindow.xaml:70 · tick box | Record the mouse pointer | — |
| 177 | SettingsWindow.xaml:73 · tab | Capture bar | — |
| 178 | SettingsWindow.xaml:75 · tick box | Show the capture bar | — |
| 179 | SettingsWindow.xaml:76 · note | Without it, TRT works from its notification-area icon and the shortcuts. | — |
| 180 | SettingsWindow.xaml:77 · note | Buttons: tick the ones to show; select one and use Up or Down to change the order. The Menu button is always shown, at the end. | Tick the buttons to show; use Up and Down to change the order. Menu is always last. |
| 181 | SettingsWindow.xaml.cs:67 · button list item | Capture active window | — |
| 182 | SettingsWindow.xaml.cs:68 · button list item | Capture window or object | — |
| 183 | SettingsWindow.xaml.cs:69 · button list item | Capture rectangular region | — |
| 184 | SettingsWindow.xaml.cs:70 · button list item | Capture freehand region | — |
| 185 | SettingsWindow.xaml.cs:71 · button list item | Capture full screen | — |
| 186 | SettingsWindow.xaml.cs:72 · button list item | Capture scrolling window | — |
| 187 | SettingsWindow.xaml.cs:73 · button list item | Screen recorder | — |
| 188 | SettingsWindow.xaml.cs:74 · button list item | Screen ruler | — |
| 189 | SettingsWindow.xaml.cs:75 · button list item | Open the editor | — |
| 190 | SettingsWindow.xaml.cs:76 · button list item | Output (where screenshots go) | — |
| 191 | SettingsWindow.xaml:82 · button | Up | — |
| 192 | SettingsWindow.xaml:83 · button | Down | — |
| 193 | SettingsWindow.xaml:84 · button | Reset | — |
| 194 | SettingsWindow.xaml:87 · heading | Red tab at the top of the screen | — |
| 195 | SettingsWindow.xaml:89 · label | Width | — |
| 196 | SettingsWindow.xaml:91 · value after the slider (source `{0:0} pixels`) | {width} pixels | — |
| 197 | SettingsWindow.xaml:94 · label | Place | — |
| 198 | SettingsWindow.xaml:95 · choice | Under the bar | — |
| 199 | SettingsWindow.xaml:96 · choice | Here: | — |
| 200 | SettingsWindow.xaml:103 · heading | The capture bar's ✕ button | — |
| 201 | SettingsWindow.xaml:105 · choice | Hides TRT in the notification area | — |
| 202 | SettingsWindow.xaml:106 · choice | Quits TRT | — |
| 203 | SettingsWindow.xaml:110 · tab | Editor | — |
| 204 | SettingsWindow.xaml:112 · heading | Toolbar | — |
| 205 | SettingsWindow.xaml:113 · tick box | Small icons (hide the captions under the toolbar icons) | Small icons (no captions) |
| 206 | SettingsWindow.xaml:114 · label | Position | — |
| 207 | SettingsWindow.xaml:116 · choice | Horizontal, across the top | — |
| 208 | SettingsWindow.xaml:117 · choice | Vertical, on the left | — |
| 209 | SettingsWindow.xaml:119 · heading | Options bar | — |
| 210 | SettingsWindow.xaml:120 · tick box | Hide the options bar under the toolbar (colour, width, font…) | — |
| 211 | SettingsWindow.xaml:121 · note | The floating windows beside a selected redaction, line or text have the same choices. The bar still appears while cropping, for Confirm crop. | The floating windows beside a selection have the same choices. The bar still shows while cropping. |
| 212 | SettingsWindow.xaml:126 · button | OK | — |
| 213 | SettingsWindow.xaml:127 · button | Cancel | — |
| 214 | SettingsWindow.xaml.cs:183 · Export settings… (file dialog title) | Export settings | — |
| 215 | SettingsWindow.xaml.cs:183 · Import settings… (file dialog title) | Import settings | — |
| 216 | SettingsWindow.xaml.cs:211 · box after Export or Import settings (title) | Settings file | — |
| 217 | SettingsWindow.xaml.cs:190 · settings exported | Settings exported to {file}. | — |
| 218 | SettingsWindow.xaml.cs:191 · export failed | The settings could not be saved there: {error} | Couldn't save the settings there: {error} |
| 219 | SettingsWindow.xaml.cs:205 · settings imported | Settings imported from {file}. Press OK to use them. | — |
| 220 | SettingsWindow.xaml.cs:208 · import failed | That file does not hold TRT settings. Nothing was changed. | That isn't a TRT settings file. Nothing was changed. |

## Progress box (in the editor)

The box with a progress bar and Cancel that covers the editor while a task runs (MainWindow.xaml:413-419).
Its title is the task name below with "…" added (MainWindow.xaml.cs:197); the line under the bar is the
progress text.

| # | Where | Now | Suggested |
|---|---|---|---|
| 221 | MainWindow.xaml:416 and MainWindow.xaml.cs:162 · default title | Working | — |
| 222 | MainWindow.xaml.cs:232, MainWindow.Capture.cs:39 · title: opening a file | Loading media | Opening |
| 223 | MainWindow.Capture.cs:54 · title: opening a capture | Opening capture | — |
| 224 | MainWindow.xaml.cs:304 · title | Opening project | — |
| 225 | MainWindow.xaml.cs:316 · title | Saving project | — |
| 226 | MainWindow.xaml.cs:767 · title | Exporting video | — |
| 227 | MainWindow.xaml.cs:767 · title | Exporting image | Exporting picture |
| 228 | MainWindow.xaml.cs:838, :904 · title | Tracking | — |
| 229 | MainWindow.Capture.cs:111 · title: Original | Keeping the original | Saving the original |
| 230 | MainWindow.Capture.cs:173 · title: Save media as… | Saving the media | Saving a copy |
| 231 | MainWindow.Capture.cs:199 · title: Capture frame with edits | Capturing the frame | — |
| 232 | MainWindow.Capture.cs:296 · title: Copy | Copying | — |
| 233 | MainWindow.Rotate.cs:134 · title | Rotating the video | Turning the video |
| 234 | MainWindow.Rotate.cs:134 · title | Rotating the picture | Turning the picture |
| 235 | MainWindow.Video.cs:84 · title | Trimming the video | — |
| 236 | MainWindow.Video.cs:134 · title | Appending a video | Adding a video |
| 237 | MainWindow.xaml.cs:531 · title: Undo over Rotate, Trim or Append | Undoing | — |
| 238 | MainWindow.xaml.cs:531 · title: Redo over Rotate, Trim or Append | Redoing | — |
| 239 | MainWindow.xaml.cs:206 · title while a video export is written | Exporting video… | — |
| 240 | MainWindow.xaml.cs:207 · title while the export is checked | Validating the exported video… | Checking the exported video… |
| 241 | MainWindow.xaml.cs:238 · progress text | Loading and validating media | Opening and checking the file |
| 242 | MainWindow.xaml.cs:314 · progress text | Saving project | — |
| 243 | MainWindow.Capture.cs:94 · progress text | Saving the original capture | — |
| 244 | MainWindow.xaml.cs:208 · progress text while the export is checked | Checking the new file: its streams, size, codecs and metadata, and that it has the same frames at the same times as the original. | Checking the new video matches the original, frame by frame. |
| 245 | MainWindow.xaml.cs:749 · progress text ({percent} such as 42 %) | Exporting · {percent} | — |
| 246 | MainWindow.xaml.cs:820 · progress text (Track) | Tracking · {percent} | — |
| 247 | MainWindow.xaml.cs:901 · progress text (Track forward or backward) | Analysing selected appearance · {percent} | Tracking · {percent} |
| 248 | MainWindow.Rotate.cs:114 · progress text | Turning the video (lossless copy; this can take a while) | Turning the video (this can take a while) |
| 249 | MainWindow.Video.cs:76 · progress text (Trim) | Cutting piece {n} of {count} | — |
| 250 | MainWindow.Video.cs:125 · progress text (Append) | Preparing the open video | — |
| 251 | MainWindow.Video.cs:127 · progress text (Append) | Preparing the added video | — |
| 252 | MainWindow.Video.cs:154 · progress text (Trim, Append) | Joining the pieces | — |
| 253 | MainWindow.xaml:419 · button | Cancel | — |

## Notification-area balloons and short notices (not boxes)

These are not dialogue boxes, but they are short messages TRT shows on its own, so they are listed for completeness.

| # | Where | Now | Suggested |
|---|---|---|---|
| 254 | CaptureController.cs:298 · title of every balloon from Notify | TinyRedactionTool | — |
| 255 | CaptureController.cs:369 · a screenshot while recording | Stop the recording before taking a screenshot. | Stop recording first. |
| 256 | CaptureController.cs:370, :641 · a capture while the editor is busy | The editor is busy. Try again when it has finished. | The editor is busy. Try again in a moment. |
| 257 | CaptureController.cs:510 · screenshot saved to a file (Output: file) | Screenshot saved as {file}, as captured (nothing redacted). | — (keep: safety) |
| 258 | CaptureController.cs:600 · Settings OK | Settings saved. | — |
| 259 | CaptureController.cs:600 · Settings OK, but the file could not be written | Settings applied, but they could not be saved for next time. | Settings applied, but not saved for next time. |
| 260 | CaptureController.cs:741 · recording discarded | Recording discarded and wiped. | — |
| 261 | CaptureController.cs:766 · Quit during a capture | Finish the current capture first. | — |
| 262 | CaptureController.cs:292 · first time the bar's ✕ hides TRT (balloon title) | TinyRedactionTool is still running | TRT is still running |
| 263 | CaptureController.cs:292 · same balloon (text) | Its capture shortcuts still work. Click its icon here to show the capture bar; right-click it to quit. | Shortcuts still work. Click the icon to show the bar; right-click it to quit. |
| 264 | CaptureController.cs:460 · notice after every screenshot | Saved to Clipboard | Copied to the clipboard |
| 265 | CaptureController.cs:460 · same, when the clipboard is busy | Not copied: the clipboard is busy | — |
| 266 | CaptureController.cs:436 · scrolling capture running | Scrolling… press Esc to stop | — |
| 267 | CaptureController.cs:438 · scrolling capture done | Scrolling capture finished | — |

## Selection screens (full-screen, not boxes)

The hint shown at the top of the frozen screen while you choose an area (CaptureOverlay) or measure (ruler).

| # | Where | Now | Suggested |
|---|---|---|---|
| 268 | CaptureController.cs:410 · Capture freehand region | Hold the mouse button and draw round the area. Esc or right-click cancels. | Draw round the area. Esc or right-click cancels. |
| 269 | CaptureController.cs:411 · Capture window / object | Point at a window or a part of it, then click. Esc or right-click cancels. | — |
| 270 | CaptureController.cs:412 · Capture rectangular region | Drag round the area to capture. Esc or right-click cancels. | — |
| 271 | CaptureController.cs:431 · Capture scrolling window | Click inside the part to scroll (a window, panel or page pane). Esc or right-click cancels. (0.22.2; was "Click the window or panel to scroll and capture.") | — |
| 272 | CaptureController.cs:656 · record a window | Click the window to record. Esc or right-click cancels. | — |
| 273 | CaptureController.cs:657 · record a region | Drag round the area to record. Esc or right-click cancels. | — |
| 274 | ScreenRuler.cs:434 · ruler Rectangle | Drag round something to measure its width and height. / Esc or right-click closes. | — |
| 275 | ScreenRuler.cs:435 · ruler Distance | Drag from one point to another to get the distance between them. Shift keeps the line straight. / Esc or right-click closes. | Drag between two points. Shift keeps the line straight. / Esc or right-click closes. |
| 276 | ScreenRuler.cs:436 · ruler Angle, step 1 (the current step has ▶ in front) | 1. Click the centre point | — |
| 277 | ScreenRuler.cs:436 · ruler Angle, step 2 | 2. Click the end of the first line | — |
| 278 | ScreenRuler.cs:437 · ruler Angle, step 3 | 3. Click the end of the second line | — |
| 279 | ScreenRuler.cs:437 · ruler Angle, last line | Esc or right-click closes. | — |

## Errors

The texts below are shown inside the boxes above: the editor's "Operation failed" box (row 12-13), the
"Invalid properties" box (rows 20-21), the "Screen capture" and "Screen recording" boxes (rows 59-60,
71-73) or the "Startup blocked" box (rows 1-2). Many are technical checks that should almost never be
seen; those are marked "technical" and kept unless you want them plainer.

### Opening files and projects (Operation failed box)

| #   | Where                                                                      | Now                                                                                                                            | Suggested                                                                    |
| --- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| 280 | MainWindow.xaml.cs:224 · network drive blocked by policy                   | Managed policy blocks this network path.                                                                                       | Your organisation's policy blocks network drives.                            |
| 281 | MainWindow.xaml.cs:245 · opening a video in a picture editor window        | This picture editor opens pictures only. Open videos in the main editor (the TRT icon in the notification area › Open editor). | This window opens pictures only. Open videos in the main editor.             |
| 282 | MainWindow.xaml.cs:258 · relinked file is not the original                 | Relinked source differs from the saved source fingerprint or dimensions. Project loading was blocked.                          | That is not the same file as the original. The project was not opened.       |
| 283 | MainWindow.xaml.cs:262 · picture size differs from the project             | Source display dimensions differ from the saved project. Loading was blocked.                                                  | The picture size differs from the saved project. The project was not opened. |
| 284 | MainWindow.xaml.cs:293 · project file too large                            | Project exceeds the development 32 MiB limit.                                                                                  | The project file is too large (over 32 MiB).                                 |
| 285 | MediaTools.cs:131 · a video whose last frame has no time                   | The video's last frame has no timestamp and its place can't be worked out.                                                     | —                                                                            |
| 286 | MediaTools.cs:134 · a video frame without a time ({n} is the frame number) | Frame {n} of the video has no timestamp, so TRT can't place it exactly.                                                        | —                                                                            |
| 287 | MediaTools.cs:110 · technical                                              | Decoded frame count does not match the timing map.                                                                             | —                                                                            |
| 288 | MediaTools.cs:156 · technical                                              | The exact requested frame was not decoded.                                                                                     | —                                                                            |
| 289 | Core/Timeline.cs:10 · technical                                            | Invalid source timestamp origin.                                                                                               | —                                                                            |
| 290 | Core/Timeline.cs:13 · a file with no video frames                          | No decoded frames.                                                                                                             | The file has no frames that this application can read.                       |
| 291 | Core/Timeline.cs:17 · technical                                            | Frame identity is ambiguous.                                                                                                   | —                                                                            |
| 292 | Core/ProjectCoordinates.cs:13 · old project with an out-of-range margin    | Coverage margin exceeds the supported range after coordinate upgrade; loading was blocked.                                     | —                                                                            |

### Capture and recording (Screen capture / Screen recording boxes)

| # | Where | Now | Suggested |
|---|---|---|---|
| 293 | ScreenRecorder.cs:85 · recording too slow (after "The recording could not be completed.") | Screen recording could not keep up. Try a smaller area or fewer frames per second. | — |
| 294 | ScreenRecorder.cs:100 · recording did not finish (same) | The recording could not be finished in time. | — |
| 295 | ScreenRecorder.cs:101 · recording file not written (same) | The recording could not be written. | — |
| 296 | ScreenRecorder.cs:78 · technical (same) | The recorded picture changed size. | — |
| 297 | ScreenRecorder.cs:67, MediaTools.cs:38 · FFmpeg would not start (same, or Operation failed box) | Could not start the approved media tool. | — |
| 298 | CaptureController.cs:396 · Capture active window with no window | There is no window to capture. Click the window you want, then use Capture active window (or its shortcut). | No window to capture. Click the window you want, then try again. |
| 299 | CaptureController.cs:398 · active window off screen | The active window is not on the screen. | — |
| 300 | CaptureController.cs:434 · scrolling capture area too small | That area is too small to scroll. | — |
| 301 | CaptureController.cs:515 · saving a screenshot to a network drive, blocked by policy | Managed policy blocks saving to a network path. | Your organisation's policy blocks saving to network drives. |
| 302 | CaptureController.cs:663 · recording area too small | The area is too small to record. | — |
| 303 | CaptureController.cs:679 · Windows cannot hide the recording frame from the video | Windows could not keep the recording border and controls out of the video, so recording did not start. | — (keep: safety) |
| 304 | ScreenCapture.cs:43 · technical | The capture area is empty. | — |
| 305 | ScreenCapture.cs:80 · freehand outline too short | A freehand region needs at least three points. | Draw a bigger freehand area. |
| 306 | ScreenCapture.cs:82 · freehand outline off the picture | The freehand region is outside the picture. | — |
| 307 | ScrollingCapture.cs:82 · scrolling capture got nothing | Nothing was captured. | — |
| 308 | ScreenRecorder.cs:43 · technical | The recording area needs an even width and height of at least 2 pixels. | — |
| 309 | ScreenRecorder.cs:44 · technical | Recording paths must be absolute. | — |
| 310 | ScreenRecorder.cs:49 · technical | A recorder records once. | — |

### Saving, copying, Original (Operation failed box)

| # | Where | Now | Suggested |
|---|---|---|---|
| 311 | CaptureController.cs:487 (thrown at MainWindow.Capture.cs:102; also shown in the status bar) · clipboard busy | The clipboard is in use by another program, so the picture was not copied. Try again. | The clipboard is busy, so nothing was copied. Try again. |
| 312 | MainWindow.Capture.cs:140 · Original or Save media as… copy failed its check | The saved copy did not match the capture. Nothing was replaced. | — |
| 313 | Core/Project.cs:194 · Save project over the media file | A project cannot replace its source media. | Choose another name: a project can't replace the picture or video. |

### Export (Operation failed box)

| # | Where | Now | Suggested |
|---|---|---|---|
| 314 | MainWindow.xaml.cs:738 · export to a file that exists | This development exporter requires a new destination. Choose another filename. | That file already exists. Choose a new name. |
| 315 | Core/Timeline.cs:39 · Export or Copy with nothing added | Create a redaction, annotation or crop first. | Add a redaction, annotation or crop first. |
| 316 | Core/Timeline.cs:41 · policy | Managed policy prohibits Blur and Pixelate. | Your organisation's policy does not allow Blur or Pixelate. |
| 317 | Core/Timeline.cs:42 · policy | Managed policy prohibits retaining audio. | Your organisation's policy does not allow keeping the sound. |
| 318 | Core/Timeline.cs:43 · policy | Managed policy prohibits source deletion. | Your organisation's policy does not allow deleting originals. |
| 319 | ImageExport.cs:23 · picture export onto the original | Export cannot replace the source. | Export can't replace the original. |
| 320 | ImageExport.cs:24 · picture export to a file that exists | Choose a new destination. Existing files are never replaced. | — |
| 321 | ImageExport.cs:25, VideoExport.cs:26 · policy | Managed policy blocks network export. | Your organisation's policy blocks exporting to network drives. |
| 322 | ImageExport.cs:26, VideoExport.cs:28 · the original changed while open | The source changed. Export was blocked. | The original file has changed since it was opened. Nothing was exported. |
| 323 | VideoExport.cs:25 · video export onto the original or a file that exists | Choose a new destination separate from the original. | Choose a new file name (not the original). |
| 324 | VideoExport.cs:134 · exported sound runs longer than the video | Output duration differs from the displayed video timeline. Audio may extend beyond the reviewed video; export without audio or review it separately. | — (keep: safety) |
| 325 | ImageExport.cs:97 · this FFmpeg cannot write that format ({parts}, {format}) | The approved FFmpeg build lacks {parts} required for {format} export. PNG export remains available. | TRT's FFmpeg can't write {format} here. PNG still works. |
| 326 | ImageExport.cs:21 · technical | Choose a PNG, JPG, GIF or WebP destination. | — |
| 327 | ImageExport.cs:22 · technical | The approved media tools are required for {format} export. | — |
| 328 | ImageExport.cs:19 · technical | Choose the video exporter for video media. | — |
| 329 | ImageExport.cs:20 · technical (TRT never asks this export for it) | Source deletion and audio retention are not implemented in this build. | — |
| 330 | VideoExport.cs:21 · technical | Choose the image exporter for still images. | — |
| 331 | VideoExport.cs:22 · technical (TRT never asks this export for it) | Original-source deletion is not implemented and cannot be requested. | — |
| 332 | VideoExport.cs:24 · technical | Unsupported video destination format. | — |
| 333 | ImageExport.cs:38 · technical check | Source dimensions differ. | — |
| 334 | ImageExport.cs:68 · technical check | The encoder did not produce an image. | — |
| 335 | Core/StillImage.cs:100 (via ImageExport.cs:82) · technical check | Decoded output dimensions differ from the prepared redaction. | — |
| 336 | Core/StillImage.cs:106 (via ImageExport.cs:82) · technical check | The encoded image contains transparency that was not in the prepared redaction. | — |
| 337 | Core/StillImage.cs:111 (via ImageExport.cs:82) · technical check ({x},{y} is the pixel) | Encoded output differs inside an opaque redaction (pixel {x},{y}). | — (keep: safety) |
| 338 | ImageExport.cs:109, :114 · technical check | Output structure mismatch. | — |
| 339 | ImageExport.cs:182 · technical check | Output stream, codec or dimension validation failed. | — |
| 340 | ImageExport.cs:185 · technical check | The output must contain exactly one image frame. | — |
| 341 | ImageExport.cs:186 · technical check | Output contains chapters. | — |
| 342 | ImageExport.cs:192, VideoExport.cs:151 · technical check ({key} is the metadata name) | Unexpected output metadata key: {key} | — |
| 343 | VideoExport.cs:66 · technical check | Invalid owned mask directory. | — |
| 344 | VideoExport.cs:77 · technical check | Source frame intervals are too short for safe mask timestamp mapping. | — |
| 345 | VideoExport.cs:131 · technical check | Output duration could not be validated. | — |
| 346 | VideoExport.cs:139 · technical check | Output stream, chapter or geometry validation failed. | — |
| 347 | VideoExport.cs:143 · technical check | Audio retention state does not match output. | — |
| 348 | VideoExport.cs:147 · technical check | Unexpected output codec. | — |
| 349 | VideoExport.cs:153 · technical check | Output frame count differs from source. | — |
| 350 | VideoExport.cs:157 · technical check | Output frame presentation time differs from source. | — |
| 351 | EffectVideoEncoder.cs:19 · technical check (Blur/Pixelate video export) | Frame timestamps are too close for effect export. | — |
| 352 | EffectVideoEncoder.cs:48 · technical check | Decoded effect frame dimensions changed. | — |
| 353 | EffectVideoEncoder.cs:55 · technical check | Unexpected extra decoded effect frame. | — |
| 354 | EffectVideoEncoder.cs:67 · Blur/Pixelate video export failed ({details} is FFmpeg's own text) | Effect video processing failed. {details} | — |
| 355 | EffectVideoEncoder.cs:80 · technical | Could not start approved effect processing. | — |
| 356 | AnnotationRenderer.cs:155 · annotations failed to draw | Annotations could not be drawn. | — |
| 357 | EffectRenderer.cs:22 · technical | Missing media. | — |
| 358 | Core/ImageCrop.cs:29 · technical (also Core/Project.cs:164) | Invalid image crop. | — |

### Tracking (Operation failed box)

| # | Where | Now | Suggested |
|---|---|---|---|
| 359 | TrackingAnalysis.cs:38 · range too short | Choose a range containing at least two frames. | Tracking needs at least two frames. |
| 360 | TrackingAnalysis.cs:40 · the original changed while open | Source fingerprint changed; analysis blocked. | The original file has changed since it was opened. Tracking stopped. |
| 361 | TrackingAnalysis.cs:74 · Track backward over too long a range | Backward analysis is limited to a 128 MiB memory buffer. Choose a shorter range. | That is too long to track backward. Choose a shorter part. |
| 362 | TrackingAnalysis.cs:91 · technical | Could not start analysis decoder. | — |
| 363 | TrackingAnalysis.cs:101 · technical | Analysis dimensions changed. | — |
| 364 | TrackingAnalysis.cs:105 · technical | Unexpected extra analysis frame. | — |
| 365 | TrackingAnalysis.cs:125 · technical | Invalid analysis PNG stream. | — |
| 366 | TrackingAnalysis.cs:130 · technical | Decoded frame exceeds its memory limit. | — |
| 367 | TimestampedPngStream.cs:20 · technical | Transport element is too large. | — |
| 368 | Core/AppearanceTracker.cs:58 · technical | Invalid analysis frame. | — |
| 369 | Core/RedactionWorkflow.cs:21 · Stop redaction here before the start (TRT normally checks this first) | Move to or after this redaction's start before stopping it. | — |

### Rotate, Trim and Append (Operation failed box)

| # | Where | Now | Suggested |
|---|---|---|---|
| 370 | MainWindow.Rotate.cs:107 · technical | The picture is not loaded. | — |
| 371 | MainWindow.Rotate.cs:125 · turned video lost or gained frames | The turned video has a different number of frames. Nothing was changed. | — |
| 372 | MainWindow.Video.cs:122 · Append with a different-shaped video | The videos are different shapes ({width} × {height} and {otherWidth} × {otherHeight}). Append needs the same shape. Nothing was changed. | — |
| 373 | MainWindow.Video.cs:159 · Trim or Append result has the wrong frame count | The new video has {count} frames instead of {expected}. Nothing was changed. | — |

### Project checks (Operation failed box when opening a project; Invalid properties box on Apply)

| # | Where | Now | Suggested |
|---|---|---|---|
| 374 | Core/Project.cs:149 · empty project file | Empty project. | The project file is empty. |
| 375 | Core/Project.cs:157 · project from another program or version | Unsupported project version. | This project was made by a different TRT version. |
| 376 | Core/Project.cs:158 · technical | Unsupported coordinate space. | — |
| 377 | Core/Project.cs:160 · technical | Invalid source reference. | — |
| 378 | Core/Project.cs:161 · technical | Duplicate region identity. | — |
| 379 | Core/Project.cs:171 · Apply with an out-of-range time, margin, colour or strength | Invalid redaction parameters. | Check the times, colour and margin: one is out of range. |
| 380 | Core/Project.cs:179 · Apply with a box outside the picture | Invalid region keyframe. | The box must be inside the picture. |
| 381 | Core/Project.cs:183 · technical | Polygon vertices must use normalized region coordinates. | — |
| 382 | Core/Project.cs:185 · technical | Invalid tracking review range. | — |
| 383 | Core/Project.cs:186 · technical | Invalid region order. | — |
| 384 | Core/Project.cs:187 · technical | Invalid region rotation. | — |
| 385 | Core/Project.cs:56 · technical | Region has no geometry. | — |
| 386 | Core/ProjectCoordinates.cs:7 · technical | Source reference missing. | — |
| 387 | Core/Annotation.cs:84 · technical | Duplicate annotation identity. | — |
| 388 | Core/Annotation.cs:92 · technical | Invalid annotation parameters. | — |
| 389 | Core/Annotation.cs:99 · technical | Invalid text annotation. | — |
| 390 | Core/Annotation.cs:105 · technical | Invalid drawing annotation. | — |
| 391 | Core/Annotation.cs:108 · technical | Invalid line annotation. | — |

### Start-up (Startup blocked box)

| # | Where | Now | Suggested |
|---|---|---|---|
| 392 | App.xaml.cs:35 · a TRT is already running but does not answer | TinyRedactionTool is already running but did not answer. Close it from its notification-area icon and try again. | TRT is already running but not answering. Quit it from its notification-area icon and try again. |
| 393 | App.xaml.cs:23 · wrong start-up arguments (technical) | `Use --managed-policy <local policy.json>.` | — |
| 394 | App.xaml.cs:28 · wrong start-up arguments (technical) | `Use [--managed-policy <local policy.json>] [--startup] [file to open].` | — |
| 395 | CaptureStore.cs:29 · the temporary folder is on a network drive | Screen capture needs a local temporary folder. | — (keep: safety) |
| 396 | MediaTools.cs:29 · TRT's FFmpeg files are not the approved ones | Approved media-tool hash mismatch. | TRT's FFmpeg files have been changed. TRT will not use them. |
| 397 | Core/ManagedPolicy.cs:15 · policy file | Managed policy must be local. | — (keep: policy) |
| 398 | Core/ManagedPolicy.cs:16 · policy file | Managed policy cannot be a reparse point. | — (keep: policy) |
| 399 | Core/ManagedPolicy.cs:18 · policy file | Managed policy must be 1 byte to 64 KiB. | — (keep: policy) |
| 400 | Core/ManagedPolicy.cs:27 · policy file | Unsupported managed policy schema. | — (keep: policy) |
| 401 | Core/ManagedPolicy.cs:29 · policy file | Invalid managed policy identity. | — (keep: policy) |
| 402 | Core/ManagedPolicy.cs:32 · policy file | Policy controls must be an object. | — (keep: policy) |
| 403 | Core/ManagedPolicy.cs:36 · policy file | Unsupported, duplicate or non-Boolean managed control. | — (keep: policy) |
| 404 | Core/ManagedPolicy.cs:42 · policy file | Policy must be an object. | — (keep: policy) |
| 405 | Core/ManagedPolicy.cs:44 · policy file | Unknown or missing policy properties. | — (keep: policy) |

### Video player checks (Operation failed box, first time a video opens)

| # | Where | Now | Suggested |
|---|---|---|---|
| 406 | LocalPlayback.cs:113 · technical | Playback requires an existing local filesystem source. | — |
| 407 | LocalPlayback.cs:267 · technical | Native playback manifest missing. | — |
| 408 | LocalPlayback.cs:268 · technical | Native playback manifest invalid. | — |
| 409 | LocalPlayback.cs:270 · the video player's files are not the approved ones | Unexpected or missing playback native modules. Startup blocked. | — (keep: safety) |
| 410 | LocalPlayback.cs:276 · technical | Invalid native manifest path. | — |
| 411 | LocalPlayback.cs:278 · the video player's files have been changed | Playback native hash mismatch. Startup blocked. | — (keep: safety) |

### Texts passed on from FFmpeg

MediaTools.cs:58, TrackingAnalysis.cs:110 and EffectVideoEncoder.cs:59 show FFmpeg's own error text (up to 1,500
characters, with the open file's path replaced by [source media]). That text comes from FFmpeg and cannot be reworded here.
