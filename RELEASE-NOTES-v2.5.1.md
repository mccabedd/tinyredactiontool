# TinyRedactionTool v2.5.1

TinyRedactionTool v2.5.1 is a focused maintenance release built on v2.5.0. It adds outline-only Rectangle/Oval/Freeform drawing annotations and improves screenshot, startup and dark-theme workflow.

This release is promoted from the user-tested `v2.5.0-r8` candidate. Company security/governance approval remains a separate deployment process; release status is not a claim of company certification or an independent security audit.

## Added

- **Rectangle Drawing**, **Oval Drawing** and **Freeform Drawing** annotation tools.
- Drawing tools are outline-only: adjustable border colour, thickness and line style, with applicable corner/join controls. They never create an opaque, Blur or Pixelate interior.
- Shift-constrained Rectangle/Oval drawing and the existing constrained Freeform segment behaviour.
- Compact floating editing controls for the new drawing annotations, including double-click reopening.
- Exact Begin/End annotation timing on video, using the existing annotation timeline lane and without the redaction safety buffer.
- Immediate **Copy** and **Export Image** for a screenshot captured by the current TRT session, even when no redaction, annotation or crop has been added.
- Plain screenshot exports default to `SCREENSHOT_yyyyMMdd_HHmmss.ext`.

## Improved and fixed

- Dark Mode is now the startup default.
- TRT opens maximized and makes a one-shot foreground activation request after the main form is shown. It is not permanently TopMost.
- Removed focus-on-mouse-enter behaviour that could pull TRT in front of another window merely when the pointer crossed its surface.
- Drawing annotations show their selected line colour/thickness/style live while being created, before Create Annotation.
- Drawing annotation handles and visible outlines now share the same exact media-space geometry instead of mixing annotation coordinates with redaction even-pixel normalisation.
- Floating editor title/close text follows Dark/Day theme colours.
- Copy and Export Image have independent enabled visual states for current-session screenshots.
- Text annotation Bold, Italic and Left/Centre/Right alignment controls remain clearly visible in Dark Mode.
- Still screenshots are cropped from the pre-selector desktop snapshot so transient UI such as dropdowns, menus and tooltips can be captured before focus changes close them.

- Dark-mode Text Bold, Italic and justification controls remain clearly visible.
- Still screenshots preserve transient UI such as dropdowns, menus and tooltips by using the pre-selector desktop snapshot.
- Completed still-image redaction and annotation drafts can be committed by clicking outside the object as well as with the green Create button.
- Floating redaction and annotation editors include direct trashcan delete/cancel controls.
- Floating editor layouts are compact and tailored to each tool to avoid clipped controls and unnecessary empty space.

## Preserved

The approved custom FFmpeg/FFprobe binaries are unchanged. Existing CFR/VFR timing, exact logical-frame navigation, redaction Begin/End handling, opaque redaction safety margins, Blur/Pixelate semantics, managed-policy restrictions, transactional export validation, metadata/extra-stream stripping, audio-off-by-default behaviour and runtime tool ownership/cleanup architecture remain in place.

## Build and hashes

The frozen v2.5.1 application source SHA-256 is:

`CA2CC6EBD3BDB48737B249A96F8953D2007DCB38780606AC2EEE74E5F40A2C3C`

The repository/source pack includes a Windows PowerShell 5.1 offline packaging builder pinned to that exact source plus the approved media resources/compiler inputs.

Current executable and archive hashes are published separately in `SHA256SUMS-v2.5.1.txt` with the release assets. Rebuilding or signing the executable can change its binary hash.

## Suggested final manual check

1. Launch from Explorer with another window frontmost; verify TRT opens maximized, Dark Mode, and requests foreground once without remaining TopMost.
2. Capture a disposable screenshot and immediately test Copy and Export Image with no edits.
3. Create Rectangle, Oval and Freeform Drawing annotations at several zoom levels; verify live preview, aligned handles, Shift constraints, Create Annotation and double-click editing.
4. Repeat drawing annotations on a short disposable video and verify Begin/End annotation timing and export.
5. Recheck one opaque redaction, one Blur/Pixelate export, one CFR/VFR video and managed-policy startup to confirm the maintenance changes did not disturb the established release architecture.
