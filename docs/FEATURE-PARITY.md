# Baseline feature parity acceptance register

Every feature below is required. Pending items are not removed from scope. This development build is NOT a replacement for v2.5.1. Status here is deliberately conservative; implemented subsets are described in README.md and TEST-RESULTS.md.

The user's explicit C#/WPF rewrite supersedes implementation-specific references to a PowerShell/WinForms GUI or PS2EXE builder. Their functional guarantees (local processing, trusted tooling, reproducible packaging and standalone delivery) remain required in the new architecture. This register has 138 inherited/additional acceptance entries; the development code does not yet satisfy all of them.

Read-only local README SHA-256: A46CEBE09213FC3BC392172FCB57A1CA1F99BA15B6557C8C84BCD12B6CC3B0D2
Read-only v2.5.1 source SHA-256: 5F2B4E58A9FA2D86EA8B8CB84F880364F2D4446CCDE4FDCC9A4ABABF0E0F35C5

## Complete inherited README checklist

### Selection and redaction

- [ ] BASE-001: Rectangle selection.
- [ ] BASE-002: Oval selection.
- [ ] BASE-003: Freeform/polygon selection.
- [ ] BASE-004: Move an uncommitted Rectangle, Oval or closed Freeform selection before committing it.
- [ ] BASE-005: Resize an uncommitted Rectangle/Square with **8 handles**: four corners plus North/East/South/West edge handles.
- [ ] BASE-006: Resize an uncommitted Oval/Circle with **4 cardinal handles**: North/East/South/West.
- [ ] BASE-007: Edit a closed uncommitted Freeform by dragging any existing vertex handle; whole-polygon movement remains available.
- [ ] BASE-008: Hold **Shift while resizing** a Rectangle/Oval to constrain the result to a square/circle.
- [ ] BASE-009: Clicking outside a closed Freeform dismisses that draft; a second click begins a new Freeform.
- [ ] BASE-010: Hold **Shift** while drawing a Rectangle/Oval to constrain it to a square/circle.
- [ ] BASE-011: Hold **Shift** while adding Freeform points to snap the next segment to horizontal, vertical or 45-degree angles.
- [ ] BASE-012: Opaque **Black/Coloured Box** redaction for permanent pixel replacement.
- [x] BASE-013: User-selectable box colour. *(Accepted in 0.6.0: integrated checks plus David's manual check, 28 Oct 2026.)*
- [x] BASE-014: Eyedropper tool to sample a colour directly from the loaded frame/image. *(Accepted in 0.6.0: integrated checks plus David's manual check, 28 Oct 2026.)*
- [ ] BASE-015: **Blur** visual obscuration with adjustable strength.
- [ ] BASE-016: **Pixelate** visual obscuration with adjustable strength.
- [ ] BASE-017: Optional **Aggressive** Blur/Pixelate mode that first reduces the selected area to a deliberately low-detail structural representation before applying the final visual effect.
- [ ] BASE-018: Aggressive mode uses the validated fixed strength-5 profile in v2.2.0; Default remains the normal unchecked mode.
- [ ] BASE-019: Session-only warning suppression for Blur/Pixelate security warnings; the Blur/Pixelate suppression checkbox starts checked by default.
- [ ] BASE-020: Video redactions use explicit **Begin Redaction** and **End Redaction** frame markers.
- [ ] BASE-021: Automatic **2-frame temporal safety buffer** before and after each marked video range.
- [ ] BASE-022: Automatic **1-pixel outward spatial safety margin** for secure opaque exports where media bounds allow it.
- [ ] BASE-023: Redaction list showing shape, mode and marked range.
- [ ] BASE-024: Remove selected redactions or clear all redactions.
- [ ] BASE-025: Timeline markers show committed video redaction ranges.
- [ ] BASE-026: Draft and committed redaction geometry is stored in canonical displayed-media coordinates rather than screen/control coordinates.
### Zoom, pan and preview navigation

- [ ] BASE-027: Dedicated Zoom tool in the left toolbar.
- [ ] BASE-028: Pointer-centred **left-click zoom in**.
- [ ] BASE-029: Pointer-centred **right-click zoom out**.
- [ ] BASE-030: Pointer-centred **mouse-wheel zoom is always available while the pointer is over the preview**, regardless of the selected drawing tool.
- [ ] BASE-031: Visible `−  Fit  +` zoom controls in the preview.
- [ ] BASE-032: Live zoom indicator such as `Fit (43%)` or `200%`.
- [ ] BASE-033: **100% = one displayed-media pixel per screen pixel**.
- [ ] BASE-034: Manual zoom up to **800%**.
- [ ] BASE-035: Drag with the Zoom tool to pan.
- [ ] BASE-036: **Middle-button drag** pans the preview at any time without changing the selected drawing tool.
- [ ] BASE-037: **Right-button drag** also pans the preview while preserving the existing simple right-click Zoom/Freeform actions.
- [ ] BASE-038: Hold **Space + drag** while Rectangle/Oval/Freeform is selected for temporary pan without changing drawing tools.
- [ ] BASE-039: Fit mode preserves aspect ratio and permits letterboxing rather than stretching media.
- [ ] BASE-040: Manual zoom/pan survives frame stepping, seeking, playback, pause, panel collapse/restore and window resize/maximise/restore.
- [ ] BASE-041: Opening new media resets the viewport to Fit.
- [ ] BASE-042: Redactions remain attached to the same media pixels at every zoom level and pan position.
- [ ] BASE-043: Preview selection outlines remain approximately constant in screen-pixel thickness instead of scaling into oversized borders.
### Video timing and playback

- [ ] BASE-044: CFR video support.
- [ ] BASE-045: Native **VFR (variable-frame-rate)** support without converting the source to a temporary CFR file.
- [ ] BASE-046: FFprobe-backed per-frame timing map using real presentation timestamps.
- [ ] BASE-047: Exact logical-frame Previous/Next navigation.
- [ ] BASE-048: Left/Right arrow keyboard shortcuts for previous/next frame.
- [ ] BASE-049: Click-and-drag timeline seeking mapped to presentation time.
- [ ] BASE-050: Play/Pause preview playback.
- [ ] BASE-051: Playback cadence follows actual per-frame presentation durations for VFR sources.
- [ ] BASE-052: Current preview time and logical frame number display.
- [ ] BASE-053: Redaction activation uses logical frame indexes rather than `frame / fps` arithmetic.
- [ ] BASE-054: Exact-PTS preview extraction fails closed instead of silently substituting a neighbouring frame.
- [ ] BASE-055: Existing source autorotation/orientation handling remains intact.
- [ ] BASE-056: Pre-redaction **90° clockwise / anticlockwise user rotation** is available before any redaction geometry exists; 180° and 270° are reached by repeated quarter-turns.
- [ ] BASE-057: User rotation is baked into exported pixels/dimensions and does not alter logical frame identity or timing.
### Image and video export

- [ ] BASE-058: Video export: **MP4, MOV, M4V, AVI, MKV, WebM**.
- [x] BASE-059: Image export: **PNG, JPG, GIF, WebP**. *(Accepted in 0.6.0: integrated checks plus David's manual export of all formats, 28 Oct 2026. See TEST-RESULTS.md.)*
- [ ] BASE-060: H.264 output for MP4/MOV/M4V/AVI/MKV.
- [ ] BASE-061: VP9 output for WebM.
- [ ] BASE-062: High quality, Normal quality and Smaller file size presets.
- [ ] BASE-063: Audio retention is **off by default**.
- [ ] BASE-064: Optional primary-audio retention only (`0:a:0`).
- [ ] BASE-065: AAC audio for non-WebM video output and Opus for WebM.
- [ ] BASE-066: Separate warning before retaining audio because TinyRedactionTool does not inspect or redact spoken content.
- [ ] BASE-067: Source metadata, stream metadata and chapters stripped from exports.
- [ ] BASE-068: Subtitle, data, attachment and unintended extra audio streams excluded.
- [ ] BASE-069: Neutral default output name: `REDACTED_yyyyMMdd_HHmmss.ext`.
- [ ] BASE-070: Export is written separately; optional original-source deletion is off by default and requires the existing eligibility checks, warnings and explicit user choice.
### Export validation and fail-closed behaviour

- [ ] BASE-071: Export is first written to a same-directory `.partial.<GUID>` file.
- [ ] BASE-072: The partial output is structurally inspected with the bundled FFprobe before finalisation.
- [ ] BASE-073: Stream counts/types, chapters, metadata keys, dimensions and expected audio state are checked.
- [ ] BASE-074: Video exports rebuild and compare the complete output frame timeline against the source timing map.
- [ ] BASE-075: Exact decoded frame-count equality is required for video.
- [ ] BASE-076: Per-frame presentation timestamps must remain within a tight muxer-quantisation tolerance.
- [ ] BASE-077: Generated video is decode-checked before promotion to the requested destination.
- [ ] BASE-078: Existing destination files are not replaced until validation succeeds.
- [ ] BASE-079: Failed encoding/validation/finalisation removes the partial output where possible and leaves the existing destination untouched.
### Local-processing, privacy and media-tool trust

- [ ] BASE-080: Local media processing; no TinyRedactionTool media-upload service.
- [ ] BASE-081: No application telemetry.
- [ ] BASE-082: No background update checker.
- [ ] BASE-083: No FFmpeg/FFprobe `PATH` fallback in the packaged application.
- [ ] BASE-084: Single-file EXE embeds a private custom FFmpeg and FFprobe build.
- [ ] BASE-085: Embedded media tools are extracted to a unique random runtime directory.
- [ ] BASE-086: Exact FFmpeg/FFprobe SHA-256 values are injected during the release build and verified at startup.
- [ ] BASE-087: Verified runtime tool files are held open with read-only sharing locks for the GUI session to prevent ordinary post-verification replacement/modification.
- [ ] BASE-088: Custom FFmpeg build has networking disabled while retaining required local file/pipe protocols.
- [ ] BASE-089: Unredacted preview frames are piped through memory instead of intentionally being written as temporary image files.
- [ ] BASE-090: Non-rectangular temporary mask PNGs contain generated geometry/colour coverage, not copied source imagery.
- [ ] BASE-091: Network/mapped-drive source warning before opening unredacted media.
- [ ] BASE-092: Separate network/mapped-drive destination warning before saving exported media.
- [ ] BASE-093: Network warning suppression is session-only and source/destination suppression states are separate.
- [ ] BASE-094: Best-effort Windows Recent Items suppression using `OFN_DONTADDTORECENT`.
- [ ] BASE-095: Captured FFmpeg/FFprobe error text replaces the current source path with `[source media]` where practical and truncates oversized diagnostics.
### User interface and workflow

- [ ] BASE-096: Compact Windows PowerShell/WinForms desktop UI.
- [ ] BASE-097: Day and Dark modes with themed toolbar icons; the Dark Mode base uses the lighter `#3C3F47` family.
- [ ] BASE-098: Compact left toolbar for Rectangle, Oval, Freeform, Zoom, Coloured Box, Blur and Pixelate.
- [ ] BASE-099: Collapsible **Redaction Area** side panel; preview expands when the panel is collapsed.
- [ ] BASE-100: Selection X/Y/Width/Height readout.
- [ ] BASE-101: Security-mode guidance distinguishing opaque redaction from visual obscuration.
- [ ] BASE-102: Status/progress feedback during media analysis and export.
- [ ] BASE-103: Compact warning dialogs for Blur/Pixelate, audio and network/cloud paths.
- [ ] BASE-104: About dialog identifies **TinyRedactionTool v2.5.0**, GPL-2.0-or-later licensing and local-processing/no-telemetry posture.
- [ ] BASE-105: GitHub repository URL in About is non-clickable and has a dedicated copy-to-clipboard icon.
- [ ] BASE-106: Custom application/taskbar icon in the packaged EXE.
### Standalone build

- [ ] BASE-107: Runs as a single **64-bit Windows EXE** after packaging.
- [ ] BASE-108: No separate FFmpeg installation or PATH configuration required for the standalone build.
- [ ] BASE-109: Release builder targets Windows PowerShell 5.1 and uses pinned PS2EXE 1.0.18.
- [ ] BASE-110: The v2.5.0 packaging builder checks accepted media-tool hashes; the matching historic FFmpeg toolchain and its functional regression record remain separate inputs.
- [ ] BASE-111: The release builder is expected to refuse to package a source file or approved media-tool binary whose SHA-256 does not match the frozen release values.

## Additional v2.5.x source and release requirements

- [ ] Selected-region screenshots with Ctrl+Print Screen
- [ ] Selected-region recording with Ctrl+Shift+Print Screen; yellow Stop Recording, blinking border and selection guidance
- [ ] Mutually exclusive minimize/exit-to-tray settings; exit-to-tray default; tray restore and Quit
- [ ] Single-instance restore without reloading policy or extracting redundant payloads
- [x] Still-image crop with eight handles, explicit Confirm Crop, no video crop *(Accepted in 0.7.0: 582 integrated checks plus David's manual check, 28 Oct 2026.)*
- [ ] Text, Line and Polyline annotations on images and video; styling, appearance controls and creation-order layering
- [ ] Floating multiline text editor; double-click reopen; Ctrl+Enter; Escape rollback; outside-click editor confirmation
- [ ] Standalone video annotation Begin/End/Cancel timing, exact inclusive frames without redaction buffer and separate timeline lane
- [ ] Double-click committed redactions to reopen shape/effect editors; Day/Dark colours and viewport anchoring
- [ ] Completed still-image drafts commit on outside-click, consuming that click; explicit Create retained; video Begin/End remains explicit
- [ ] Clear Screen releases workspace; asynchronous video loading with Cancel; responsive window during loading/export
- [ ] Copy redacted/cropped image only from validated output; explicit clipboard disclosure and confirmation
- [ ] Native icon in title/taskbar/tray/header; maximized startup; v2.5.1 DPI behaviour
- [ ] Optional source deletion OFF by default: eligibility, file identity and hardlink checks; warnings, countdown, overwrite/flush/verify/delete; no unsupported erasure guarantees
- [ ] Strict managed v1 policy discovery at ProgramData and explicit override; malformed/unknown/network/reparse policies fail closed
- [ ] blockNetworkSource and blockNetworkDestination enforced at open/export boundary
- [ ] disableSourceDeletion, disableAudioRetention and disableVisualObscuration independently enforced in UI and processing paths
- [ ] Leased private runtime directories, instance ownership, normal cleanup and scoped abandoned-session recovery
- [ ] C# WPF theme preference: Light/Dark/System, persistent explicit choice and scaling/keyboard/window behaviour
- [ ] Real-time playback with audio/speed/seek; exact paused inspection; full broad-codec and rotated/SAR/VFR validation
- [ ] Editable timestamp geometry animation; interpolation; manual corrections protected from retracking
- [ ] Forward/backward assisted subject tracking, size change, coverage margin, progress/cancel; explicit loss and review; no invented confidence
- [ ] Tracking review gating, project persistence and source-fingerprint relink
  - 0.14.0: David removed the separate Review step and its export gate ("an extra step which serves to confuse the end user"; 29 Oct). Loss handling, timeline marking, persistence and relink stay.
- [ ] Hover thumbnails with debounce, obsolete-work cancellation, bounded memory cache and no implicit seeks
- [ ] Versioned local projects, missing-source handling, export settings and all existing region/annotation/crop data
- [ ] All input/output formats, Default/Aggressive profiles and warnings must pass the same behavioural baseline
- [ ] Standalone x64 development packaging with pinned tools, licensing and dependency provenance; distinct version/output; no old publisher
