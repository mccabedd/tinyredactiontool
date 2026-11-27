# Changelog

## 3.5.0 (November 2026)
- **Tabs.** Every screenshot, recording and opened file (File › Open Media, Open Project, File Explorer, drag and drop) gets its own tab along the top of the picture; an empty tab takes the next one. Each tab keeps its own redactions, notes, Undo and zoom. **+** (Ctrl+T) adds an empty tab; a tab's **✕** (Ctrl+W, or a middle click) closes it, asking first when it is unsaved; Ctrl+Tab and Ctrl+Shift+Tab (or Ctrl+Page Down / Page Up) go to the next and previous tab. A frame chosen for Edit in Capture Frame opens in a new tab.
- **Copy part of one tab into another.** With Select, the dashed box you drag round an area stays marked; Copy (Ctrl+C) then copies just that area, as it would be saved (redactions and notes included). Paste (Ctrl+V) puts it into another tab: in an empty tab it becomes the picture, on a picture it goes on top as an item to move and size (as Paste onto Image), and with a video open it goes to a new tab.
- **File › Save All Tabs** saves each tab with unsaved work in turn (stopping at, and showing, a tab whose Save As is cancelled). **File › Close All Tabs** closes them all, asking about each unsaved one; the editor stays open with one empty tab. Closing the editor window closes every tab the same way.
- **The unsaved screenshot questions** put one sentence on each line, with [Cancel] at the left and [No] [Yes] at the right (Yes is the default), in a narrower box: "This screenshot has not been saved. / Any changes will be lost. / Continue?" and "Discard and open the new screenshot instead? / The current screenshot has not been saved. / Any changes will be lost." No keeps it (when closing several tabs, it goes on to the next; for a new screenshot, the new one opens in a tab of its own); Cancel stops.

## 3.4.0 (November 2026)
- **Check for Updates** in Help › About. TRT goes online only when you click it. It asks GitHub for the latest release, offers it only when it is newer, shows what's new and asks first. The download must be the size GitHub lists, match the SHA-256 GitHub publishes for it, and be a 64-bit TinyRedactionTool of that version; anything else is deleted. TRT talks only to GitHub over HTTPS and stops if it is sent anywhere else. It then closes (asking about unsaved work first) and starts again as the new version, keeping the old one beside it as `.old`. If TRT is kept open, or can't write to its own folder, nothing is replaced.
- File menu order: New Image, Open Media, Save, Save As, Open Project, Save Project, Add Image, File Info.

## 3.3.0 (November 2026)
Saving is simpler: three commands in the File menu and on the toolbar, each with its own icon and a place in Settings › Toolbar.
- **Save (Ctrl+S)** saves to the same file again: the file you opened, or the last file Save As wrote (named in the title bar). With nothing changed it does nothing. A screenshot, a new image or a project has no file yet, so Save opens Save As; so does a format TRT can't write. Saving over the file being edited explains first, once, that the edits become permanent and that Save Project keeps them editable (and, for a video, that its sound will go when Keep Primary Audio is off); the saved file then opens again.
- **Save As (Ctrl+Shift+S)** replaces Export: the same checked writing and replacing, to a new file, which then becomes the file Save writes to. Cancelled or failed, nothing changes (the previous file, the editing and any file it would have replaced). Untouched screenshots, recordings, new images and work that is only turned, resized, flipped or trimmed can now be saved too.
- **Save Project** keeps the work editable. A project whose picture or video is in TRT's temporary folder (a screenshot, say) gets a checked copy beside it (`<project>_MEDIA.png`), so it opens again after TRT has wiped its temporary files.
- **Suggested names**: `yyyyMMdd_HHmmss_SUFFIX.ext`. REDACTED when the file has a Solid, Blur or Pixelate redaction (including one made part of the picture by Flatten Image or a Save); EDITED for notes or other edits without a redaction; otherwise SCREENGRAB, RECORDING, FRAME, COPY (an opened file or pasted picture) or IMAGE (a new image). Untouched screenshots, recordings and frames carry the time they were taken. A name already in the folder gets _2, _3 and so on. Projects: `yyyyMMdd_HHmmss.trtwpf.json`. The Original command (raw screenshots and recordings) suggests SCREENGRAB or RECORDING even after edits.
- **Save Media As** is gone (Original still saves a screenshot or recording exactly as captured). Ctrl+E is gone with Export.
- **Securely Delete Original** is its own command in the File menu, no longer an option of saving. It becomes available after Save As has written a copy, shows the exact file before asking, and keeps the organisation policy that can turn it off.
- The side panel's Export Options are now Save Options.

## 3.2.2 (November 2026)
- **File › Save (Ctrl+S)**: the redacted picture or video replaces the file you opened, under the same name. TRT writes the new file beside it and checks it first; only then does it replace the old one. The first Save of each file asks once ("Replace 01.png with the redacted version? The unredacted picture will be gone."). The saved file opens again with the redactions now part of it. Screenshots and New Image have no file yet, so Save works like Export there; formats TRT can't write (such as BMP or TIFF) still go through Export.
- **Export can replace an existing file**: when Windows asks whether to replace a file and you answer Yes, Export replaces it (after its checks). It never replaces the file open in TRT; that goes through Save.
- The window title shows the open file's name, for example "TinyRedactionTool 3.2.2 - 01.png".

## 3.2.1 (November 2026)
- Scrolling capture of a short scrolling area (between a fixed header and a large fixed box) captured only the first screen: each wheel turn moved the area almost its whole height, leaving too little to join. The first turn is now one notch, and each later turn is sized to move about 45 % of the area (tall web pages keep their usual speed).
- When a web page pane is picked, its own top (such as a title) is kept above the joined picture, with no side columns.
- Floating buttons that stay in one place while the page scrolls under them are no longer joined in on every screen; the page under them is taken from the next screen (a button that fades or shifts a shade counts too).
- A scroll of part of a notch that moves nothing is followed by a whole notch before TRT decides the end is reached.
- A join that doesn't line up no longer ends the capture: TRT waits for late-loading pictures and takes the screen again, then steps back and takes a smaller step, before stopping.
- Scrolling starts once Shift, Ctrl and Alt are let go (Shift + wheel scrolls sideways in a browser, Ctrl + wheel zooms).
- A last step that ends on part of a pixel still joins when one step size clearly wins, and a click in an empty part of a pane uses the rows that changed.
- A picked web pane keeps its full width (margins included) and the whole part that scrolls, including blank rows at its bottom, so the end of a short scrolling area is no longer cut off.

## 3.2.0 (November 2026)
- **Auto redaction colour**: an **Auto** tick box between Redaction Colour and the Eyedropper (redaction window and options bar). A Solid Fill redaction then takes the most common colour along its edge (black text on light blue is covered with light blue), again whenever it is moved, sized or turned. Choosing a colour turns it off. Settings › Editor decides whether it starts ticked (off to start).
- **Pictures open faster**: PNG, BMP and JPEG are read by Windows' own decoder instead of starting FFmpeg (phone photos still come out upright). Other formats still use FFmpeg.
- **New Image fix**: with "Put the Current Image on It", or when a picture pasted (or added) onto an empty New Image fills it, the picture becomes part of the new image, so it can be redacted and annotated, nothing stays stuck selected, and Save Media As saves what you see. Pasted pictures that aren't selected no longer catch the drawing tools (draw over them; Select moves them; Esc lets go of a selection).
- Menus in the order File, Edit, View, Redact, Draw, Video, Capture, Help. The drawing tools read Outline, Ellipse, Text, Line, Polyline, Pen on the toolbar and in the Draw menu.
- **Solid Fill, Blur Fill, Pixelate Fill** (toolbar, tooltips and Redact menu); Redact › Redaction Colour… and Eyedropper; the redaction window says Solid. Solid Fill has a paint-bucket icon; the Rectangle, Oval and Polygon redaction icons are filled in.
- Settings › Editor: the line width new outlines, ellipses, lines and arrows, polylines and pen strokes start with (now 4, was 6).
- The notification-area icon: a click opens the editor, a double-click shows the capture bar (Settings › Editor can swap them).
- Clear Redactions and Clear Annotations icons are as large as the others.
- TRT starts with the capture bar hidden in the red tab at the top of the screen (point at the tab to bring it out). Settings › Capture Bar can start it open instead.

## 3.1.3 (November 2026)
- Toolbar spacer: Settings › Toolbar › Add Spacer puts a blank, button-sized gap anywhere on the editor's toolbar.
- New first-start defaults from David's settings file: Save Media before Save Project, Copy and Paste in their own group; Save Media, Delete, Fit Width, Slideshow and Nav Bar shown, New, Add Image and Rotate hidden; the navigation bar shows in the editor at 48 pixels; the red tab is 30 pixels wide.
- The Save Copy button is now Save Media, with the tooltip "Save Media As… (No Redactions)".
- The red tab the capture bar hides in has no tooltip.
- Edit menu: Copy Image, Paste Image and Paste onto Image come before Transform, Rotate and Resize.
- File names: every export is REDACTED_ (no more CROPPED_); everything TRT makes before export (screenshots, recordings, frames, pasted and new images, edited working copies) is CAPTURE_. Save Media As adds _COPY once, never _COPY_COPY.

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