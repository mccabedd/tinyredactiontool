# Verification: 3.1.0, 9 November 2026

Status: **`Build-Dev.ps1` (build and all checks) passed: 1394 checks, none failed.** Build: 0 errors, 0 warnings.

## New checks (Checks/Release300LayerChecks.cs; `--layers-only` runs these 52)
- Layers: redactions and annotations share one stack; the Regions and Annotations lists show it top layer first. Move Up and Move Down (redaction past redaction, annotation past annotation and any redactions between, or to the very top/bottom), numbering 1, 2, 3 … with no ties, saved in the project; older projects keep their drawing order.
- In the picture: an annotation under a black box is hidden there; moved above, it is drawn on the box; the same picture pixels are covered either way, and an annotation above a Blur doesn't undo the blur.
- In the editor (through the real buttons): arrows sit just right of each list, on and off as they should; Move Up keeps the selection and says what it moved above; Undo puts the order back; Duplicate makes a selected copy on top, 10 px right and down (back the other way at an edge), for redactions and annotations; Edit › Layers has Move Up, Move Down, Duplicate Layer, Delete Layer, Flatten Image.
- Flatten Image: the lists empty, the picture becomes a working copy (EDITED_….png in TRT's private folder) with the boxes, colours and lines in its pixels; the original is kept; Undo separates them again; off for videos and when there is nothing to flatten.
- Video annotations: the annotation's own window shows green Begin Here and red End Here; End Here and Begin Here set the frame shown; a text on a video gets the window too (timing and Delete only).
- Video crop: the Crop tool works on a video; the crop is whole pixels with an even size (51 × 41 becomes 50 × 40); the size shown is the cropped size; Undo removes it. Export to MP4 and WebM: the crop's size, every frame, each frame the crop of the redacted and annotated frame (within the codec's tolerance), yuv420p, sound kept when asked, original unchanged.
- Pictures for a look: test-output/layers-pane.png, test-output/layers-video-popup.png.

## Changed checks
- CropChecks: a video crop is accepted; one beyond the frame is refused. CropUiChecks: Crop is available for a video.
- Release300Checks: the version is 3.1.0.

## Not checked
- Ctrl+], Ctrl+[ and Ctrl+D on the real keyboard (the checks call the same commands; they cannot hold Ctrl).
- Cropping a real phone or screen recording video end to end in the running app (the checks use synthetic videos).

## Package
- standalone/3.1.0/TinyRedactionTool-3.1.0.exe, 117 MB, SHA-256 C1F0FB21249761A90EA95BDB76827CAEDDE874B720443EE3423B8DAE2D7D9E5E (product version 3.1.0).
