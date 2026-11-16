# Verification: 3.2.0, 16 November 2026

Status: **`Build-Dev.ps1` (build and all checks) passed: 1438 checks, none failed.** Build: 0 errors, 0 warnings. (The first full run stopped where an older check found the Draw menu by its position; the menu order changed, so it now finds menus by name.)

## What changed
- Auto redaction colour: Region.AutoColor; AutoColour.Sample takes the most common colour along a band 1.5 to 3 pixels either side of the shape's edge (turned shapes, ovals and polygons included) on the frame shown, after every draw, move, size or turn. The Auto tick box sits between Redaction Colour and the Eyedropper (redaction window and options bar). Choosing a colour turns it off. Settings › Editor › Auto Redaction Colour (off by default).
- Pictures read by Windows (StillDecoder): PNG, BMP and JPEG, with JPEG EXIF orientation applied and colour profiles ignored, as FFmpeg does; anything else, a PNG with its own EXIF block, or a file Windows can't read goes through FFmpeg. Measured on the development laptop: FFmpeg took 1.2 to 3.6 s for a picture, Windows 0.04 to 0.25 s, the fingerprint 8 to 25 ms.
- New Image with the current picture: the picture is drawn into the new picture's pixels (NewPictureWindow.Compose) instead of a Picture item covering the canvas.
- Menus: File, Edit, View, Redact, Draw, Video, Capture, Help. Solid Fill / Blur Fill / Pixelate Fill; Redaction Colour…; Eyedropper; Solid in the redaction window. Paint-bucket icon; filled Rectangle, Oval and Polygon icons; larger Clear icons.
- Settings › Editor: line width for new shapes (default 4, was 6); the tray click (default: click opens the editor, double-click shows the capture bar).

## New checks (Release320Checks; `--release-320-only` runs these 29)
- Auto colour finds the light blue around black text (not a dark average), the pink around a turned oval, the colour along a polygon's edge, and nothing on see-through pixels.
- In the editor, through the real mouse path: with Auto on, a Solid Fill drawn over black text on light blue is light blue; moved onto pink it turns pink; choosing a colour turns Auto off; ticking Auto again matches at once; with Auto off a new box uses the chosen colour.
- A PNG read by Windows has exactly FFmpeg's pixels (transparency included); a JPEG held sideways comes out upright and the same size as FFmpeg's, within decoder rounding; GIF, WebP and TGA still use FFmpeg.
- Settings defaults and round trip (line width, Auto, tray click); a line width outside 1 to 20 goes back to 4; the line width setting is what new lines start with.
- Redact menu, toolbar, redaction-window names and tooltips; Auto's place in the redaction window; the paint-bucket and filled icons; Clear icons as tall as File Info.
- Tray: a double-click shows the capture bar, a click opens the editor, and swapping them in Settings works.

## Changed checks
- Release026: New Image puts the screenshot into the new picture's own pixels (not an item); later counts of picture items one fewer.
- Release015 and AnnotationChecks: new lines start 4 pixels wide.
- FrameSpeedChecks: Solid Fill, Blur Fill, Pixelate Fill captions. Program.cs: menu order, and the Draw and Redact menus found by name.

## Not checked
- The real mouse on David's notification-area icon (the checks call the same click handler).
- Auto colour on video frames while playing (it samples the frame shown when the redaction is drawn or moved).

## Package
- TinyRedactionTool-3.2.0.exe, 117 MB, SHA-256 E4FAD4EA14EF2AAAFE99108B262C143EA4AEF0C2D566E359FB01275F5A6862B2 (product version 3.2.0).
