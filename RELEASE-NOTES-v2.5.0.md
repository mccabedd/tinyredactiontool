# TinyRedactionTool v2.5.0

TinyRedactionTool v2.5.0 adds native screen capture, tray operation, image cropping, editable annotations/redactions and image clipboard copying, with responsive video loading and export.

This is the user-approved v2.5.0 final release. Organisation security governance review is a separate deployment process; final release status does not claim company certification.

## Added

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

## Improved and fixed

- Video loading runs asynchronously with a Loading Video notice and Cancel button.
- Minimize, restore and maximize remain responsive during video loading and export.
- Tray closing/restoring behaviour and the main Create Annotation action were corrected.
- The expanded editing pane was simplified; Appearance controls moved to floating annotation editors, reducing clipping and unwanted scrolling.
- Loading, cancellation, clipboard confirmation, Clear Screen and editing controls follow the light/dark theme.
- TRT starts maximized and uses the supplied icon in the title bar, taskbar, tray and header.
- Compressed media tools remain embedded resources until the owning instance expands them; second launches do not stage extra payloads in TEMP.
- App-owned temporary captures/tools have scoped cleanup and abandoned-session recovery. Forced termination can leave files until the next successful launch; tray residency is still an active session.

## Preserved

The approved custom FFmpeg/FFprobe binaries, CFR/VFR timing, Begin/End frame semantics, opaque redaction safety margins, export rendering and validation, metadata/extra-stream stripping and audio-off-by-default behaviour remain unchanged by the final final icon/packaging update.

## Downloads

- `TinyRedactionTool.exe` — standalone Windows x64 application.
- `TinyRedactionTool-v2.5.0-WINDOWS.zip` — application, source, documentation and policy samples.
- `TinyRedactionTool-v2.5.0-SOURCE-BUILD.zip` — pinned source/icon/compiler and approved embedded media resources for an offline packaging rebuild.
- `SHA256SUMS-v2.5.0.txt` — source, EXE and ZIP checksums.

Quit any older TRT session from its tray menu before testing this release. No AutoHotkey installation or separate media-tool download is required to run the EXE. Windows PowerShell 5.1/.NET Framework are required by the compiled host. The EXE is unsigned.

## Security and deployment notes

Use opaque Coloured Box redaction for sensitive content. Blur/Pixelate are visual obscuration, not irreversible redaction. Retained audio is not redacted.

The policy defaults to `%ProgramData%\TinyRedactionTool\policy.json`. A true control applies a restriction; false/absent preserves normal user choices. The accepted loader permits an explicit policy-path override, uses the process environment for discovery and starts normally if no policy is found. It is not tamper-proof mandatory enforcement. Read `MANAGED-POLICY-DEPLOYMENT.md` before company deployment.

Cleanup is limited to recognised app-owned files. It does not erase arbitrary TEMP contents or guarantee erasure from backups, SSD remapping, Windows clipboard history, pagefiles or crash dumps. Optional original-file deletion does not disable temporary-file cleanup.

Automated checks passed for Windows PowerShell parsing, protected-code preservation, exact embedded tools/icons, compiled startup, single-instance handling, runtime-tool recovery/cleanup and synthetic themed clipboard workflows. Live capture shortcuts, actual clipboard paste, company network paths and representative long CFR/VFR media remain final acceptance tests. This record is not a claim of an independent security audit.
