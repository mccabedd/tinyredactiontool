# Changelog

All notable changes to TinyRedactionTool are documented in this file.

## [2.5.1] - 2026-10-05

Focused maintenance release promoted from the user-tested v2.5.0-r8 candidate.

### Added

- **Outline Drawing tools:** Rectangle, Oval and Freeform annotation tools with adjustable border colour, thickness, line style and applicable corner/join settings. These are annotation-only shapes with no filled, Blur or Pixelate interior.
- Drawing Rectangle/Oval keep Shift-constrain behaviour; Freeform retains constrained segment snapping.
- Double-click reopening/editing for the new Drawing annotations using the same compact floating editor used by the other annotation tools.
- Video Drawing annotations use the existing exact Begin/End annotation timing and annotation timeline lane.
- A freshly captured TRT screenshot can be **copied or exported immediately** without first creating a redaction, annotation or crop.
- Plain screenshot export uses a neutral `SCREENSHOT_yyyyMMdd_HHmmss` default filename.

### Improved and fixed

- Dark Mode is now the application startup default; Day mode remains available.
- Floating annotation editor titles and close controls correctly follow Dark/Day theme colours.
- Drawing annotation live previews now display the selected line colour/thickness/style before Create Annotation is pressed.
- Drawing annotation geometry no longer passes through redaction/export even-pixel normalisation, fixing visibly offset resize/vertex handles at some zoom levels.
- Copy and Export Image buttons now have independent enabled visual states for current-session screenshots.
- Startup reasserts maximized state after the form is shown and performs a one-shot foreground activation request so TRT opens in front of the launching Explorer window where Windows permits it.
- Removed preview focus-on-mouse-enter behaviour that could cause windows above TRT to drop behind it merely when the pointer crossed the TRT surface.
- Dark-mode Text formatting controls (Bold, Italic and Left/Centre/Right alignment) now use explicit themed foreground/background/border colours.
- Still screenshot capture now crops from the desktop snapshot taken before the region selector appears, preserving transient UI such as open dropdowns, menus and tooltips.

- Dark-mode Text formatting controls use explicit theme colours.
- Still screenshots preserve transient UI such as dropdowns, menus and tooltips by cropping from the pre-selector desktop snapshot.
- Completed still-image redaction/annotation drafts can also be committed by clicking outside the object; the green Create buttons remain available.
- Floating redaction and annotation editors include direct trashcan delete/cancel controls.
- Floating editor layouts were tightened per tool so controls are not clipped and unused space is reduced.

### Preserved

- Approved custom FFmpeg/FFprobe binaries and decompressed hashes.
- CFR/VFR timing, exact logical-frame navigation and Begin/End semantics.
- Opaque redaction spatial/temporal safety handling.
- Blur/Pixelate visual-obscuration model and managed-policy restrictions.
- Transactional export validation, metadata/extra-stream stripping, audio-off-by-default behaviour and runtime media-tool ownership/cleanup architecture.

## [2.5.0] - 2026-10-04

Final release; application version 2.5.0. Includes changes developed after the published v2.2.0 release.

### Added

- **Region screenshot capture:** Ctrl+Print Screen while TRT is running.
- **Region video capture:** Ctrl+Shift+Print Screen, with a yellow Stop Recording control and blinking red recording-area border. Capture is available while TRT is in the tray.
- **Tray settings:** mutually exclusive Minimize to tray and Exit to tray options in About; Exit to tray is the default. Click the tray icon to restore, or right-click > Quit to exit.
- **Single-instance operation:** opening TRT again restores the existing session.
- **Image crop:** Crop Image Tool below Zoom, an adjustable rectangular selection with eight handles and an explicit Confirm Crop action. Video crop is not supported.
- **Text, Line and Polyline annotations:** floating editing controls, double-click reopening and an explicit Create Annotation commit action. Clicking outside the editor closes/confirms the edit without committing the annotation.
- **Redaction editing:** double-click Rectangle, Oval or Freeform redactions to reopen editing on images and video.
- **Clear Screen** to release the current media/editing workspace.
- **Copy redacted image** beside image export, using the validated redacted/cropped output, followed by an Image Copied to Clipboard confirmation.
- **Managed-policy restrictions** for network opening, network saving, optional original-file deletion, audio retention and Blur/Pixelate.
- **Optional original-file deletion** after validated successful export, off by default and subject to eligibility checks, warnings and managed policy.

### Improved and fixed

- Video loading runs asynchronously with a Loading Video notice and Cancel button.
- Minimize, restore and maximize remain responsive during video loading and export.
- Tray closing/restoring behaviour and the main Create Annotation action were corrected.
- The expanded editing pane was simplified; Appearance controls moved to floating annotation editors, reducing clipping and unwanted scrolling.
- Loading, cancellation, clipboard confirmation, Clear Screen and editing controls follow the light/dark theme.
- TRT starts maximized and uses the supplied icon in the title bar, taskbar, tray and header.
- Compressed media tools remain embedded resources until the owning instance expands them; second launches do not stage extra payloads in TEMP.
- App-owned temporary captures/tools have scoped cleanup and abandoned-session recovery. Forced termination can leave files until the next successful launch; tray residency is still an active session.

### Preserved

The approved custom FFmpeg/FFprobe binaries, CFR/VFR timing, Begin/End frame semantics, opaque redaction safety margins, export rendering and validation, metadata/extra-stream stripping and audio-off-by-default behaviour remain unchanged by the final icon/packaging update.

## [2.2.0] - 2026-09-23

### Added

- Pre-redaction 90° clockwise and anticlockwise rotation for still images and video.
- Rotation is applied after normal source autorotation and before redaction geometry is created.
- Rotation controls lock once redaction work exists and reset when new media is opened.
- Rotated exports bake the selected orientation into the output pixels/dimensions rather than relying on new rotation metadata.
- Optional **Aggressive** Blur and Pixelate mode.
- Aggressive mode reduces the protected region to a deliberately low-detail structural representation before applying the final visual effect.
- Right-button drag panning while preserving existing simple right-click behaviour.
- Additional FFmpeg support required by v2.2.0 for `transpose`, `avgblur` and `lutyuv`.

### Changed

- User-facing Blur/Pixelate terminology uses **Default** and **Aggressive**.
- The validated Aggressive profile is fixed at strength 5.
- Blur/Pixelate warning text explains reconstruction risk and the purpose of Aggressive mode.
- Dark Mode main surface/background updated to approximately `#3C3F47`.
- Default Pixelate preview sampling was aligned more closely with export behaviour.

### Security

Blur and Pixelate remain visual-obscuration methods and are not equivalent to opaque replacement. For maximum obscuration, use **Black Box** or **Coloured Box**.

## [2.1.0]

- Previous stable release and frozen baseline for v2.2.0 development.
