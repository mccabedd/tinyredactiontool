# TRT tooltips (applied in 0.21.3)

**0.27.0 (David): every tooltip, menu item, button and label is now in Title Case** ("Capture Active Window",
"Show or Hide the Side Panel"). Small joining words stay small (a, an, the, and, or, of, to, in, on, at, by, for,
with, from, as, onto, into, via, per) unless they start the phrase or come after a colon or bracket. Full sentences keep
sentence capitals. The tables below keep the wording in its 0.21.3 sentence case; read each as Title Case. New in 0.27.0:
Add Image toolbar button "Add Images onto This One"; File › Add Image "Put Images onto This One, to Move and Size";
New "New Image". The DEVELOPMENT BUILD label (#22) is gone.

**3.1.3 (David):** the red tab (#18) has no tooltip; the Save Copy button is now Save Media, tooltip "Save Media As… (No Redactions)" (#158); Settings › Toolbar has Add Spacer, tooltip "Add a Blank Space the Size of a Button", and Remove says "Remove the Separator or Spacer".

Every tooltip in the app, grouped by where it appears. **Now** is the current text. **Suggested** is a
wording David chose ("—" means kept as it was). All Suggested wordings were applied in 0.21.3.

Some tooltips change with the situation; those show each variant. `{…}` stands for a value filled in at the time.

## Capture bar

| #   | Button                    | Now                                                                                                                                                      | Suggested                                                                      |
| --- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| 1   | Minimise                  | Minimise to a red tab at the top of the screen (point at the tab to bring the bar back). Tip: drag the bar to the top edge and it hides there by itself. | Hide in a red tab at the top of the screen (point at the tab to bring it back) |
| 2   | Active window             | Capture active window: the window you were using last                                                                                                    | Capture the active window                                                      |
| 3   | Window / object           | Capture window / object: point at a window or a part of it, then click                                                                                   | Capture a window or part of one: point, then click                             |
| 4   | Rectangular region        | Capture rectangular region: drag round the area ({shortcut})                                                                                             | Capture a rectangle: drag round the area                                       |
| 5   | Freehand region           | Capture freehand region: hold the mouse button and draw round the area                                                                                   | Capture a freehand area: draw round it                                         |
| 6   | Full screen (one screen)  | Capture full screen: the screen with the mouse pointer                                                                                                   | Capture the screen with the cursor                                             |
| 7   | Full screen (all screens) | Capture full screen: all screens                                                                                                                         | Capture all screens                                                            |
| 8   | Scrolling window          | Capture scrolling window: click a window or panel; TRT scrolls it down and joins the pictures (Esc stops)                                                | Capture a scrolling window (Esc stops)                                         |
| 9   | Screen recorder           | Screen recorder: record an area, a window or the screen as a video, then redact it ({shortcut} records a region straight away)                           | Record the screen as a video                                                   |
| 10  | Ruler                     | Screen ruler: measure lengths, rectangles, distances and angles on screen in pixels                                                                      | Screen ruler: measure on screen in pixels                                      |
| 11  | Editor                    | Open the editor (open, redact and export images and videos)                                                                                              | Open the editor                                                                |
| 12  | Output (editor)           | Output: to the editor, for redacting and annotating. Click to change.                                                                                    | Captures go to the editor. Click to change.                                    |
| 13  | Output (clipboard)        | Output: to the clipboard (the picture as it is, ready to paste). Click to change.                                                                        | Captures go to the clipboard. Click to change.                                 |
| 14  | Output (file)             | Output: to a file (the picture as it is; you choose the name). Click to change.                                                                          | Captures are saved to a file. Click to change.                                 |
| 15  | Menu                      | Settings, editor and quit                                                                                                                                | —                                                                              |
| 16  | Close (quits)             | Quit TinyRedactionTool                                                                                                                                   | —                                                                              |
| 17  | Close (hides)             | Close the capture bar (TRT keeps running in the notification area; right-click its icon to quit)                                                         | Hide the bar (TRT keeps running in the notification area)                      |
| 18  | Red tab                   | (none since 3.1.3, David)                                                                                                                                | (none: tooltip removed)                                                        |

## Editor menus

| # | Item | Now | Suggested |
|---|---|---|---|
| 19 | File › Save media as… | Save a copy of the open picture or video exactly as it is: no redactions or edits | Save a copy as it is, without redactions or edits |
| 20 | File › Capture frame | Save, copy or edit the video frame on screen as a picture | — |
| 21 | File › Append video | Add another video at the beginning or end of this one (sound kept in step) | Add another video at the beginning or end |
| 22 | DEVELOPMENT BUILD label | Development build: check tracked boxes and exact paused frames before exporting | — |

## Editor toolbar

| #   | Button              | Now                                                                                                                                       | Suggested                                                                |
| --- | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| 23  | Open                | Open an image or video                                                                                                                    | Open an image or video                                                   |
| 24  | Export              | Validated image/video export                                                                                                              | Export with redactions (checked after saving)                            |
| 25  | Export (not ready)  | Export is not available yet: {reason}                                                                                                     | —                                                                        |
| 26  | Original (captures) | Original: save or copy the {screenshot/recording} exactly as captured (no redactions, annotations or crop). You can also wipe TRT's copy. | Save or copy the {screenshot} as captured, without edits                 |
| 27  | Copy (nothing open) | Copy: open an image or video first                                                                                                        | Copy: open a picture or video first                                      |
| 28  | Copy                | Copy (Ctrl+C): put the {picture / frame you are looking at} on the clipboard with its redactions, annotations{ and crop}                  | Copy the image with its redactions (Ctrl+C)                              |
| 29  | Paste               | Paste: open the picture on the clipboard in the editor (a copied picture file opens too)                                                  | Paste the image from the clipboard                                       |
| 30  | Undo                | Undo (Ctrl+Z)                                                                                                                             | —                                                                        |
| 31  | Redo                | Redo (Ctrl+Y)                                                                                                                             | —                                                                        |
| 32  | Select              | Select, move and resize regions                                                                                                           | Select, move, resize and turn shapes (drag round several to select them) |
| 33  | Rectangle           | Draw a rectangular region                                                                                                                 | Draw a rectangle redaction                                               |
| 34  | Oval                | Draw an oval region                                                                                                                       | Draw an oval redaction                                                   |
| 35  | Polygon             | Draw a polygon region                                                                                                                     | Draw a polygon redaction                                                 |
| 36  | Pan                 | Move the view                                                                                                                             | —                                                                        |
| 37  | Crop (picture)      | Crop image: drag a rectangle, adjust its eight handles or drag inside it, then Confirm crop. Still images only.                           | Crop                                                                     |
| 38  | Crop (video)        | Video crop is not supported                                                                                                               | Crop works on pictures only                                              |
| 39  | Trim                | Trim: show or hide the trim row above the timeline (Set A, Set B, then Delete A–B or keep only A–B)                                       | Show or hide Trim                                                        |
| 40  | Append              | Append: add another video at the beginning or the end                                                                                     | Add another video at the beginning or end                                |
| 41  | Box                 | Coloured box: choose opaque replacement, then draw a region; also changes the selected region                                             | Redaction box                                                            |
| 42  | Blur                | Choose Blur, then draw a region; also changes the selected region                                                                         | Blur                                                                     |
| 43  | Pixelate            | Choose Pixelate, then draw a region; also changes the selected region                                                                     | Pixelate                                                                 |
| 44  | Text                | Text annotation: drag a box, then type. Ctrl+Enter or a click outside finishes; Esc cancels. Double-click a text to edit it.              | Text: drag a box, then type (double-click a text to edit it)             |
| 45  | Outline             | Rectangle outline (drawing, not a redaction): drag. Shift draws a square.                                                                 | Rectangle outline                                                        |
| 46  | Ellipse             | Ellipse outline (drawing, not a redaction): drag. Shift draws a circle.                                                                   | Ellipse outline                                                          |
| 47  | Line                | Line or arrow annotation: drag. Shift snaps to 45°.                                                                                       | Line or arrow                                                            |
| 48  | Polyline            | Polyline annotation: hold the button and drag; changing direction adds a right-angled corner. Release to finish.                          | Polyline: drag; turning adds a right-angled corner                       |
| 49  | Pen                 | Pen: hold the button and draw freehand.                                                                                                   | Pen: draw freehand                                                       |
| 50  | Zoom In             | Zoom in                                                                                                                                   | —                                                                        |
| 51  | Zoom Out            | Zoom out                                                                                                                                  | —                                                                        |
| 52  | Fit                 | Fit to window                                                                                                                             | —                                                                        |
| 53  | Actual Size         | Actual size (100%): one picture pixel per screen pixel                                                                                    | Actual size (100%)                                                       |
| 54  | Clear Redactions    | Clear all redactions: the picture and annotations stay; Undo brings them back                                                             | Remove all redactions (Undo brings them back)                            |
| 55  | Clear Annotations   | Clear all annotations (text, lines and drawings): the picture and redactions stay; Undo brings them back                                  | Remove all annotations (Undo brings them back)                           |
| 56  | Clear Editor        | Clear Editor: close the media and start again (asks first if there are unsaved changes)                                                   | Clear the editor (0.22.0)                                               |
| 57  | Panel               | Show or hide the Regions / Tracking panel                                                                                                 | Show or hide the side panel                                              |

## Options bar (under the toolbar)

| #   | Control           | Now                                                                                                        | Suggested                      |
| --- | ----------------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------ |
| 58  | Effect mode       | Effect mode                                                                                                | Default or Aggressive          |
| 59  | Strength          | Default strength, 1–10                                                                                     | Strength (1–10)                |
| 60  | Box colour        | Coloured box colour: changes the selected Coloured box, otherwise the colour for new boxes                 | Box colour                     |
| 61  | Eyedropper        | Pick colour (eyedropper): click a pixel in the loaded frame to use its colour. Esc or right-click cancels. | Pick a colour from the picture |
| 62  | Annotation colour | Annotation colour                                                                                          | Colour                         |
| 63  | Width             | Line width (media pixels, 1–20)                                                                            | Line width                     |
| 64  | Dashes            | Line style: solid, dashes or dots                                                                          | Line style                     |
| 65  | Ends              | Arrowheads                                                                                                 | Line ends                      |
| 66  | Font              | Font                                                                                                       | —                              |
| 67  | Font size         | Font size in media pixels, 6–200                                                                           | Font size                      |
| 68  | Number boxes (▲)  | Larger                                                                                                     | —                              |
| 69  | Number boxes (▼)  | Smaller                                                                                                    | —                              |
| 70  | Confirm crop      | Apply the crop (Enter). The original file is never changed.                                                | Apply the crop (Enter)         |
| 71  | Remove crop       | Show and export the whole image again                                                                      | Undo the crop                  |

## Text editing box

| # | Control | Now | Suggested |
|---|---|---|---|
| 72 | ✕ | Close and keep the text (Ctrl+Enter) | Done (Ctrl+Enter) |
| 73 | Colour | Text colour | — |
| 74 | Font | Font | — |
| 75 | Size | Size in media pixels, 6–200 | Font size |
| 76 | A▲ | Larger | — |
| 77 | A▼ | Smaller | — |
| 78 | B | Bold | — |
| 79 | I | Italic | — |
| 80 | Align left | Align left | — |
| 81 | Centre | Centre | — |
| 82 | Align right | Align right | — |

## Redaction popup (next to a selected redaction)

| #   | Control                       | Now                                                                                                                                                                                                                                                                                                           | Suggested                                        |
| --- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| 83  | Box                           | Coloured box (opaque replacement)                                                                                                                                                                                                                                                                             | Coloured box                                     |
| 84  | Blur                          | Blur (visual obscuration)                                                                                                                                                                                                                                                                                     | Blur                                             |
| 85  | Pixelate                      | Pixelate (visual obscuration)                                                                                                                                                                                                                                                                                 | Pixelate                                         |
| 86  | Colour                        | Box colour                                                                                                                                                                                                                                                                                                    | —                                                |
| 87  | Eyedropper                    | Pick colour (eyedropper): click a pixel in the picture to use its colour for this box. Esc or right-click cancels.                                                                                                                                                                                            | Pick a colour from the picture                   |
| 88  | Default / Aggressive          | Default or Aggressive (reduces detail further; still not a guarantee)                                                                                                                                                                                                                                         | Aggressive hides more detail                     |
| 89  | Strength                      | Strength 1–10 (Default mode)                                                                                                                                                                                                                                                                                  | Strength (1–10)                                  |
| 90  | Enable Tracking               | Tracking: TRT tracks the subject as it moves, from this frame on, and moves the box with it. Play it through afterwards to check the box stays on the subject. (blank line) Leave it unticked for a box that stays in one place: play on, click the redaction where it should end, and choose Stop Redaction. | Move the box with the subject from this frame on |
| 91  | Enable Tracking (last frame)  | Nothing to track: this is the last frame of the redaction.                                                                                                                                                                                                                                                    | —                                                |
| 92  | Redact (picture)              | Accept this redaction (same as clicking outside it)                                                                                                                                                                                                                                                           | Accept this redaction                            |
| 93  | Done                          | Accept this redaction as it is                                                                                                                                                                                                                                                                                | Accept this redaction                            |
| 94  | Start Redaction (tracking)    | Start the redaction here and track the subject from this frame                                                                                                                                                                                                                                                | Start here and track the subject                 |
| 95  | Start Redaction (no tracking) | Start the redaction here. The box stays in this place until you choose Stop Redaction on a later frame (or to the end of the video).                                                                                                                                                                          | Start here; the box stays until Stop Redaction   |
| 96  | Stop Redaction                | End this redaction on the frame you are looking at. Undo brings the rest back.                                                                                                                                                                                                                                | End the redaction on this frame                  |
| 97  | Track again                   | Track the subject again from this frame (after adjusting the box)                                                                                                                                                                                                                                             | Track again from this frame                      |
| 98  | Track again (last frame)      | Nothing to track: this is the redaction's last frame.                                                                                                                                                                                                                                                         | —                                                |
| 99  | Delete                        | Delete this redaction (Del)                                                                                                                                                                                                                                                                                   | —                                                |

## Line / Polyline popup

| # | Control | Now | Suggested |
|---|---|---|---|
| 100 | ✕ | Close and keep the line | Done |
| 101 | Colour | Line colour | — |
| 102 | Width | Line width (media pixels, 1–20) | Line width |
| 103 | Dashes | Line style: solid, dashes or dots | Line style |
| 104 | Ends | Arrowheads | Line ends |
| 105 | Joins | Corner joins | Corners |
| 106 | Delete | Delete this annotation (Del) | — |

## Trim row and playback

| # | Control | Now | Suggested |
|---|---|---|---|
| 107 | Set A | Set A: mark the frame on screen as A (one end of the part to trim) | Set A: mark this frame |
| 108 | Set B | Set B: mark the frame on screen as B (the other end) | Set B: mark this frame |
| 109 | Clear | Clear: remove the A and B marks | Clear the marks |
| 110 | Invert | Delete everything outside A and B instead of between them | Keep A–B and delete the rest |
| 111 | Delete A–B | Delete the frames from A to B (including A and B). Redactions and annotations follow their frames. | Delete the frames from A to B |
| 112 | Keep only A–B | Delete everything outside A and B (the frames at A and B stay). Redactions and annotations follow their frames. | Delete everything outside A–B |
| 113 | Capture frame | Capture frame: save, copy or edit the frame on screen as a picture | Save, copy or edit this frame as a picture |
| 114 | Previous frame | Previous frame (Left arrow) | — |
| 115 | Play | Play / pause | — |
| 116 | Next frame | Next frame (Right arrow) | — |
| 117 | Playback Speed | Playback speed | — |
| 118 | Timeline: redaction bar | {name}: {start}–{end}s (+2-frame export buffer required) | {name}: {start}–{end} s |
| 119 | Timeline: keyframe mark | {time}s {Manual/Tracked} | — |
| 120 | Timeline: tracked span | Tracked: {start}–{end}s | — |
| 121 | Timeline: lost span | Tracking lost the subject: {start}–{end}s | — |
| 122 | Timeline: annotation bar | {annotation}: {start}–{end}s (exact frames, no buffer) | {annotation}: {start}–{end} s |

## Side panel

| # | Control | Now | Suggested |
|---|---|---|---|
| 123 | Region name | Region name (Apply details to save changes) | Name (press Apply details to save) |
| 124 | Annotation Begin here | Show this annotation from the current frame (exact, no buffer) | Show it from this frame |
| 125 | Annotation End here | Show this annotation up to and including the current frame | Show it up to this frame |
| 126 | Delete original after export | After the export has been written and checked, TRT asks once more, then overwrites the original file with zeros, checks that, and deletes it. It can't be undone. (On solid-state drives a copy may survive in the drive's spare area.) | — (the safety detail matters; keep) |
| 127 | Delete original (blocked) | Your organisation's policy turns off deleting originals. | — |

## Settings

| # | Control | Now | Suggested |
|---|---|---|---|
| 128 | Screenshot shortcut | Click, then press the shortcut (for example Ctrl+Print Screen) | — |
| 129 | Recording shortcut | Click, then press the shortcut (for example Ctrl+Shift+Print Screen) | — |
| 130 | Capture bar shortcut | Click, then press the shortcut (for example Ctrl+Alt+B) | — |
| 131 | Editor shortcut | Click, then press the shortcut (for example Ctrl+Alt+E) | — |
| 132 | None (×2) | No shortcut for this | No shortcut |
| 133 | Delay | Time to open a menu or move the pointer before the screenshot is taken | Wait before taking the screenshot |
| 134 | Move left | Move the selected button to the left on the bar | Move left |
| 135 | Move right | Move the selected button to the right on the bar | Move right |
| 136 | Reset | Show every button in the usual order | — |
| 137 | Red tab width | Width of the red tab, in pixels | — |
| 138 | Red tab position | Left edge of the screen to right edge | Where the red tab sits along the top edge |

## Dialogs

| # | Control | Now | Suggested |
|---|---|---|---|
| 139 | Tracking stopped: pictures | Click to see it larger | — |
| 140 | Tracking stopped: Correct | Show the frame on the right so you can move or resize the box, then track again | Fix the box on the right frame, then track again |
| 141 | Tracking stopped: End | End the redaction on the last frame tracked (on the left) | End on the last tracked frame (left) |
| 142 | Tracking stopped: End (none) | There is no tracked frame to end on | — |
| 143 | Tracking stopped: Continue | Keep the box where it is on the right and carry on tracking from that frame. If tracking loses the subject again, it stops and asks again. | Keep the box on the right and track on from there |
| 144 | Tracking stopped: Continue (last frame) | This is the redaction's last frame: there is nothing left to track | — |
| 145 | Keep capture: Delete (blocked) | {policy reason} | — |

The shape popup also lists each item's name as its tooltip, and there is a generic `{Binding Name}`
tooltip in list items, so neither is listed separately.


## Added in 0.23.0

| # | Where | Tooltip | Suggested |
| --- | --- | --- | --- |
| 146 | Editor toolbar: Previous | Previous picture in the folder | — |
| 147 | Editor toolbar: Next | Next picture in the folder | — |
| 148 | Editor toolbar: Resize | Resize the picture | — |

## Added in 0.24.0

| # | Where | Tooltip | Suggested |
| --- | --- | --- | --- |
| 149 | Editor toolbar: Rotate Right | Rotate 90° clockwise | — |
| 150 | Editor toolbar: Rotate Left | Rotate 90° anti-clockwise | — |
| 151 | Editor toolbar: Flip H | Flip canvas horizontally | — |
| 152 | Editor toolbar: Flip V | Flip canvas vertically | — |
| 153 | Editor toolbar: Full Screen | Full screen (F11) | — |
| 154 | Editor toolbar: Slideshow | Slideshow (F5) | — |
| 155 | Editor toolbar: File Info | File info (Ctrl+I) | — |
| 156 | Editor toolbar: Open Project | Open a project | — |
| 157 | Editor toolbar: Save Project | Save the project | — |
| 158 | Editor toolbar: Save Media (was Save Copy, 3.1.3) | Save Media As… (No Redactions) | — |
| 159 | Editor toolbar: Fit Width | Fit width | — |
| 160 | Editor toolbar: Delete | Delete the selected shape (Del) | — |
| 161 | Editor toolbar: Settings | Settings | — |
| 162 | File info: Copy all | Copy all the text (0.25.0; was "Copy the table…") | — |
| 163 | Editor toolbar: Nav Bar (0.25.0) | Show or hide the navigation bar | — |
| 164 | Navigation bar: ✕ | Close the navigation bar | — |
| 165 | Navigation bar: ← | Previous picture | — |
| 166 | Navigation bar: ▶ | Play the slideshow / Pause the slideshow | — |
| 167 | Navigation bar: → | Next picture | — |
| 168 | Navigation bar: pin | Unpin: slide out of sight / Pin the navigation bar / Always pinned in the editor | — |
| 169 | Navigation bar: a small picture | its file name | — |
| 170 | Slideshow: red tab at the bottom | Navigation bar | — |
| 171 | Navigation bar: top edge (0.26.0) | Drag to resize | — |
| 172 | Editor toolbar: New (0.26.0) | New picture | — |
| 173 | Edit menu: Paste onto picture (0.26.0) | Paste onto this picture, to move and size | — |
| 174 | New picture: colour swatch (0.26.0) | Background colour | — |

## Added in 3.0.0 (layers, 9 November 2026)

| Control | Tooltip |
|---|---|
| Regions / Annotations lists | Top Layer First |
| Up arrow beside a list | Move Up |
| Down arrow beside a list | Move Down |
| Duplicate (side panel) | Duplicate Layer |
| Flatten Image (side panel) | Make the Layers Part of the Image |
| Begin Here (annotation window, videos) | Show It from This Frame |
| End Here (annotation window, videos) | Show It Up to This Frame |
