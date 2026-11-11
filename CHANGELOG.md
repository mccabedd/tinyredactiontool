# Changelog

## 3.1.2 (November 2026)
- File menu in a new order: New Image, Open Media (Ctrl+O), Export (Ctrl+E), Save Media As (Ctrl+Shift+S), Add Image, Open Project, Save Project, File Info.

## 3.1.1 (November 2026)
- "Open with TRT" in the right-click menu follows TRT to a new .exe: an entry left by an older or deleted TRT ("Application not found") is fixed when TRT starts.

## 3.1.0 (November 2026)

### Layers
- The side panel lists redactions and annotations top layer first, with Move Up and Move Down arrows beside each list (Ctrl+] and Ctrl+[).
- Duplicate Layer (Ctrl+D) makes a copy on top, a little to the right; Delete Layer as before.
- Flatten Image (pictures) makes the redactions and annotations part of the picture; Undo separates them again.
- All of these are also in Edit › Layers. A redaction always hides the picture under it, whatever the order.

### Video
- Crop a video: every frame is cut to the same area at export (an even width and height). Trim, crop, redact, annotate and export in one pass.
- Annotations start and end on chosen frames: green Begin Here and red End Here in the annotation's own window (and in the side panel). A text on a video gets this window too.

## 3.0.0 (November 2026)

A complete rewrite of TinyRedactionTool in C# and WPF (.NET 10). It keeps v2.5.1's local-only, fail-closed approach to redaction and export, and adds a full editor, screen capture tools and a Help manual. The v2.5.1 source and changelog are in `history/v2.5.1`.

### Editor
- Rectangle, oval and polygon redactions with Box (any colour, or picked from the picture), Blur and Pixelate (Default or Aggressive, strength 1-10). Select, move, resize and freely turn shapes; select several with a dashed box; nudge the selection with the arrow keys (1 pixel, or 10 with Shift); Undo and Redo.
- Annotations: text, rectangle and ellipse outlines, lines and arrows, polylines and a pen. Add Image, Paste onto Image and New Image.
- Crop, Resize, Rotate and Flip (the picture or just the selected shapes). Zoom, Fit, Fit Width, Actual Size, Pan, full screen, slideshow, previous and next picture in the folder, and a navigation bar of the folder's pictures.
- Animated GIFs play (with Select, click to pause or play) and export animated, with the redactions on every frame.
- File Info shows what a file carries besides the picture (camera, GPS position and more), all of which export leaves out.
- The editor opens the way it was last closed (maximised, or windowed at the same size and place; back onto a connected screen if that monitor is gone).
- Light and Dark themes across menus, dialogue boxes, title bars and the tray menu. A configurable toolbar (which buttons, their order, left and right), small icons or a vertical toolbar, and an optional options bar.

### Video
- Frame-accurate timeline with play, frame steps, speed and hover previews. Coloured lanes show redactions, box positions, tracked and lost ranges, and annotations.
- Tracking: Start Redaction follows the subject. Where tracking is lost, TRT stops and asks: continue, end the redaction there, or adjust the box. Enable Manual Redaction keeps a box in place until Stop Redaction.
- Trim (keep or delete between A and B), Append another video at the start or end, and Capture Frame. Undo covers these too.
### Capture
- A compact capture bar and a notification-area icon: rectangular region, freehand, active window, window or object, full screen, scrolling window (including long web pages), a screen recorder (area, window or screen) and a screen ruler. Global shortcuts.
- Output to the editor, the clipboard or a file. Captures stay in a private temporary folder until saved or exported, and are overwritten and deleted afterwards.

### Saving and privacy
- Export PNG, JPG, GIF and WebP pictures and MP4, MOV, M4V, AVI, MKV and WebM videos. Each export is written to a temporary file, then checked (streams, metadata, frame count and timing, decoded pixels, opaque coverage) before it is kept. The original is never changed.
- Optional secure deletion of the original after a checked export (overwrite with zeros, verify, delete).
- Projects save and reopen work in progress, tied to the original file's fingerprint.
- File › Remove History wipes old captures and working copies, clears Undo, and makes TRT and Windows forget the folders last used.
- No telemetry, uploads or update checks. The FFmpeg tools are hash-checked and read-locked, with no PATH fallback. Network drives are confirmed before use, and an organisation policy file can block them.

### Help
- An illustrated Help manual (Help › Help, or F1) in TRT's own Help window, with a contents list, in the app's theme. No web browser is needed.

### Requirements
- Windows x64 with the .NET 10 Desktop Runtime. v2.5.1 remains available for computers without it.