# Changelog

All notable changes to TinyRedactionTool are documented in this file.

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

The approved custom FFmpeg/FFprobe binaries, CFR/VFR timing, Begin/End frame semantics, opaque redaction safety margins, export rendering and validation, metadata/extra-stream stripping and audio-off-by-default behaviour remain unchanged by the final final icon/packaging update.


## [2.2.0] - 2026-09-23

### Added

- Pre-redaction 90° clockwise and anticlockwise rotation for still images and video.
- Rotation is applied after normal source autorotation and before redaction geometry is created.
- Rotation controls lock once redaction work exists and reset when new media is opened.
- Rotated exports bake the selected orientation into the output pixels/dimensions rather than relying on new rotation metadata.
- Optional **Aggressive** Blur and Pixelate mode.
- Aggressive mode reduces the protected region to a deliberately low-detail structural representation before applying the final visual effect.
- Right-button drag panning while preserving existing simple right-click behaviour.
- Additional FFmpeg support required by v2.2.0 for:
  - `transpose`
  - `avgblur`
  - `lutyuv`

### Changed

- User-facing Blur/Pixelate terminology now uses **Default** and **Aggressive**.
- The validated Aggressive profile in v2.2.0 is fixed at strength 5.
- Blur/Pixelate warning text was expanded to explain reconstruction risk and the purpose of Aggressive mode.
- **Aggressive** is emphasised in the Blur/Pixelate warning.
- **Don't show again this session** is checked by default for the Blur/Pixelate warning only.
- Dark Mode main surface/background updated to approximately `#3C3F47`, with coordinated nearby control and border shades.
- Default Pixelate preview sampling was aligned more closely with export behaviour.

### Fixed

- Default Pixelate preview/export mismatch where the block layout could visibly change after export.
- Preview now mirrors the export minimum reduced-grid rule.
- GDI+ nearest-neighbour preview sampling now uses half-pixel-centred sampling to better match FFmpeg's neighbour-scaling behaviour.

### Preserved

- CFR/VFR timing and exact presentation timestamps.
- Previous/Next Frame behaviour.
- Existing ±2-frame temporal safety handling.
- Rectangle, Oval and Freeform redaction geometry.
- Zoom and pan behaviour.
- Source autorotation.
- Audio-off-by-default policy.
- Primary-audio-only handling when audio is enabled.
- Metadata/chapter/unintended-stream stripping.
- Transactional export validation.
- Source-file immutability.
- Runtime SHA-256 verification of FFmpeg and FFprobe.
- Network-disabled custom FFmpeg profile.
- Black Box and Coloured Box opaque replacement behaviour.

### Security

Blur and Pixelate remain visual-obscuration methods and are not equivalent to opaque replacement.

For maximum obscuration, use **Black Box** or **Coloured Box**.

## [2.1.0]

- Previous stable release and frozen baseline for v2.2.0 development.
