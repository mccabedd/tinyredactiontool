# TinyRedactionTool Security Audit

**Application:** TinyRedactionTool  
**Audited version:** v2.1.0 final packaged release  
**Audit/update date:** 2026-09-18  
**Platform:** 64-bit Windows / Windows PowerShell 5.1 builder  
**Primary use case:** Local redaction of still images and video that may contain PII/PHI or other sensitive information  
**License:** GPL-2.0-or-later

> **Version scope:** This document records the final **TinyRedactionTool v2.1.0** source, secure-builder and packaged-release identity. The frozen source, consolidated application regression, Windows secure-builder gates, independent EXE hash verification and final packaged-runtime smoke test were completed on 2026-09-18.

## 1. Executive summary

TinyRedactionTool v2.1.0 is a local Windows redaction application with a security model built around four core principles:

1. **Fail closed when media identity, frame timing, export validation, or trusted-tool integrity is ambiguous.**
2. **Use opaque pixel replacement, not reversible-looking visual effects, for security-sensitive redaction.**
3. **Do not trust arbitrary FFmpeg/FFprobe binaries from the host environment.**
4. **Do not promote an export to the requested final destination until the generated output has passed post-export inspection.**

The established hardened security architecture remains in v2.1.0: native CFR/VFR frame identity, exact logical-frame activation, metadata/chapter/extra-stream stripping, audio-off-by-default behaviour, transactional `.partial.<GUID>` export, structured post-export inspection, application-local pinned media tools, and runtime protection of the verified FFmpeg/FFprobe files.

v2.0.0 established the preview zoom/pan and canonical coordinate architecture. v2.1.0 extends only the draft-editing and viewport interaction layers: uncommitted Rectangle/Square selections gain eight resize handles, Oval/Circle selections gain four cardinal resize handles, and closed Freeform selections gain draggable per-vertex handles. The v2.1.0 viewport also makes pointer-centred mouse-wheel zoom always available over the preview and adds always-available middle-button drag pan. Existing Space+drag and the dedicated Zoom tool remain available.

The security/correctness boundary remains explicit: redaction geometry is stored in canonical displayed-media coordinates, while zoom, pan, handle hit areas, cursor state, window size and panel state exist only in viewport/UI coordinates. Handles are draft-only decoration and are never export geometry.

The consolidated v2.1.0 RC1 completed the full application regression on 2026-09-18, including still images, CFR/VFR video, Rectangle/Oval/Freeform editing, Black/Coloured Box, conventional Blur/Pixelate, exact Begin/End ranges, playback/seeking/frame stepping, zoom/pan, wheel zoom, middle-button pan, Space+drag, rotation, audio/metadata, WebM, panel/window changes and mixed-state interaction testing. Release preparation changed only the About-dialog label from `v2.1.0 RC1` to `v2.1.0`. Final packaged-build evidence was completed on 2026-09-18: the secure builder passed its source/media-tool integrity gates and functional smoke tests, the packaged EXE was independently verified as `1770318460DA5FCE5E7E5957F9937674D2ABF57C409189DAF915268D4A55BCB2`, and the final packaged-runtime smoke test was reported green.

Some dedicated historical fault-injection tests pre-date v2.1.0 and were not deliberately repeated against the final v2 build. Where a security control was unchanged, this audit labels that evidence as historical rather than implying a fresh v2.1.0 fault-injection occurred. Those references are consolidated in Section 23.

No claim is made that TinyRedactionTool eliminates all operating-system forensic artefacts, protects against a compromised Windows kernel/administrator, or makes Blur/Pixelate irreversible.

## 2. Tested release identity

The frozen v2.1.0 release source is:

| Artifact | SHA-256 / status |
|---|---|
| frozen v2.1.0 release source | `2BC392FD52587343AB4CEA95B19C295286E44E4D3543634D9D3D1E383567BDC7` |
| consolidated v2.1.0 RC1 source | `05445FE17E1E1EC58BF084B749B97C8B8BAAF6869FBAFCCA9D2A3AEB96B94C0D` |
| approved embedded `ffmpeg.exe` | `28612C0A94D50A29AABD0555C91E086D1CCDF13260757B83B4BBD53A0C2CDCE0` |
| approved embedded `ffprobe.exe` | `BB8CBA76F9D4F05DD608F319477A0604D8A8C289FB6A885B03919F07C4DC9855` |
| final `TinyRedactionTool.exe` | `1770318460DA5FCE5E7E5957F9937674D2ABF57C409189DAF915268D4A55BCB2` |
| `TinyRedactionTool-Secure-Builder-v2.1.0-r1.zip` | `6DF3F0A51D37B42E649CD4A5DD2E0B4289F3B2B499BCF2D9B096B9038D974C7F` |

The frozen release source differs from the fully regression-tested consolidated RC1 source only by changing the About-dialog text from `TinyRedactionTool v2.1.0 RC1` to `TinyRedactionTool v2.1.0`. No media, redaction, viewport-transform, timing, export, audio, metadata or security logic changed in that final version-label edit.

The approved FFmpeg and FFprobe binaries are intentionally unchanged from v2.0.0. The v2.1.0 Windows secure builder verified this frozen source and both approved media-tool hashes, completed its functional smoke-test gate, produced the final EXE, and the resulting EXE was independently hash-checked as `1770318460DA5FCE5E7E5957F9937674D2ABF57C409189DAF915268D4A55BCB2`.

Any later source/build change invalidates the direct applicability of this source-regression record. The complete toolchain is not claimed to be bit-for-bit reproducible.

## 3. Audit scope and evidence model

This audit evaluates the frozen **v2.1.0 release source**. The v2.1 work deliberately avoided broad refactoring of CFR/VFR timing, export validation, metadata/audio controls and embedded-tool trust while adding draft-shape resizing/vertex editing and always-available wheel/middle-button viewport navigation.

Evidence in this audit comes from three categories:

1. **v2.1.0 static/source integrity review**, including byte-equivalent checks for protected export/frame functions and isolation of resize/viewport UI state from export geometry.
2. **v2.1.0 functional regression**, including Rectangle/Oval/Freeform draft editing and the viewport interaction matrix. The consolidated RC1 full regression completed successfully before the release-preparation version-label-only edit.
3. **v2.1.0 packaged-runtime/build evidence**, including frozen-source/media-tool hash gates, functional FFmpeg/FFprobe smoke tests, timestamp-preserving VFR round trips, single-file packaging, independent EXE hash verification and a final packaged-runtime smoke test.
4. **Clearly labelled historical fault-injection evidence** for unchanged security controls. This evidence is kept only to document how those controls were originally challenged and is consolidated in Section 23.

Historical evidence is still labelled as historical; fresh v2.1.0 builder/package evidence is identified separately and is not conflated with earlier fault-injection results.

## 4. Security objectives

For PII/PHI-oriented or other sensitive-media use, TinyRedactionTool aims to:

- process source media locally unless the user deliberately selects a network-backed path;
- avoid application telemetry and background upload services;
- leave the source file unchanged;
- avoid intentionally writing unredacted decoded preview frames to disk;
- provide a clearly identified opaque redaction method with hard security edges;
- distinguish opaque redaction from visual obscuration;
- keep all redaction geometry canonical in displayed-media pixels, independent of viewport zoom/pan;
- keep redaction activation aligned to exact logical frames on CFR and VFR sources;
- strip source metadata, chapters and unintended streams;
- disable audio by default and retain only the primary audio stream when explicitly enabled;
- validate a temporary export before replacing/creating the user's final destination;
- avoid arbitrary FFmpeg/FFprobe discovery through `PATH`;
- verify the exact bundled media tools before use and protect the verified runtime copies against ordinary post-verification modification;
- sanitise sensitive source paths from captured media-tool error text where practical;
- warn when source/destination paths are detected as network backed; and
- reduce Windows Recent Items exposure using native dialog flags where practical.

## 5. Threat model

### 5.1 In scope

The application attempts to mitigate or detect:

- accidental export of the wrong frame range because of CFR/VFR timing assumptions;
- one-frame redaction leaks at range boundaries;
- viewport-induced redaction displacement while zooming, panning, resizing or collapsing/restoring panels;
- incorrect export geometry caused by storing screen/control coordinates rather than media coordinates;
- semi-transparent anti-aliased edges on opaque oval/freeform masks;
- accidental use of an untrusted `ffmpeg.exe` or `ffprobe.exe` from `PATH`;
- modification/replacement of the verified extracted media tools through ordinary Windows file opens during the application session;
- source metadata, chapters, subtitle/data/attachment streams and secondary audio tracks leaking into output;
- unredacted preview frame files being intentionally left in `%TEMP%`;
- invalid/incomplete exports replacing an existing destination;
- unexpected network-backed source/destination use;
- direct disclosure of a sensitive source path in captured FFmpeg/FFprobe error text;
- source-file modification by the application; and
- silent frame duplication/drop or CFR conversion during VFR video export.

### 5.2 Out of scope / residual platform risk

TinyRedactionTool cannot guarantee protection from:

- a compromised Windows kernel, administrator or sufficiently privileged attacker;
- process-memory inspection;
- Windows pagefile contents;
- crash dumps;
- EDR/Sysmon/antivirus/process-monitoring telemetry;
- screen capture or photography of the display;
- clipboard capture by other software;
- filesystem snapshots, backup clients or cloud sync controlled by other software;
- shell/process-history mechanisms outside the application's control;
- physical access to the host;
- malware that already controls the user's session;
- sensitive information present in audio when the user enables audio retention; or
- vulnerabilities in the broad set of enabled input decoders/demuxers required for media compatibility.

## 6. Local-processing and network model

The application contains no telemetry service, media upload service or background update checker. Runtime media processing uses the bundled custom FFmpeg/FFprobe build.

The custom FFmpeg configuration is compiled with networking disabled. Local file and pipe protocols remain enabled because the application requires them.

The v2.1.0 About dialog displays the GitHub repository URL as **non-clickable text** with a copy-to-clipboard icon. TinyRedactionTool does not itself launch that URL. Copying it and later opening it in another application is an explicit user action outside TinyRedactionTool's media-processing path.

UNC paths and mapped network drives are permitted but produce separate Source and Destination warnings. Each warning has its own session-only suppression state. This is an informed-consent control, not a prohibition.

Universal cloud-sync detection is not attempted. A path that appears local may still be synchronised by OneDrive, Dropbox, backup software or another service outside TinyRedactionTool's control.

## 7. Trusted FFmpeg/FFprobe supply chain

### 7.1 Pinned major inputs

The v2.1.0 release is intended to retain the same hardened major builder inputs used by v2.0.0:

- **FFmpeg source commit:** `fd7c73d01e976d2e332e85862ab63ab608710834`
- **MSYS2 base release asset ID:** `560868716`
- **MSYS2 expected archive size:** `42915960` bytes
- **MSYS2 expected SHA-256:** `F6BBDE384F3331FB293C5051D5B9DBEC01C772BCCDCEEE83B78213801264D0BD`
- **PS2EXE:** `1.0.18`

The builder verifies the FFmpeg `FETCH_HEAD` against the full pinned commit when it performs a source build.

For v2.1.0, the already-approved media binaries are deliberately retained rather than rebuilding FFmpeg for draft-editing/viewport-only changes. The updated v2.1 builder must continue to refuse packaging unless the media-binary SHA-256 values match the approved hashes in Section 2.

The v2 builder also refuses to package an application source file unless it matches the frozen RC3 source hash.

### 7.2 Reproducibility limitation

MSYS2 packages installed by `pacman` are obtained from signed rolling MSYS2 repositories. The builder therefore improves supply-chain pinning but does **not** make the complete compiler/library environment immutable. Bit-for-bit reproducibility is not claimed.

### 7.3 Restricted output profile

The custom media build disables network functionality and restricts the output-side feature set to TinyRedactionTool requirements. Required explicit encoders include:

- `libx264`
- `libvpx-vp9`
- `aac`
- `libopus`
- `png`
- `mjpeg`
- `gif`
- `libwebp`
- `wrapped_avframe`

The builder performs functional tests rather than trusting capability-name listings alone.

Broad native input decoding/demuxing remains enabled for compatibility. That is an explicit attack-surface trade-off and remains documented as residual risk.

## 8. Runtime embedded-tool trust model

The packaged application embeds GZip-compressed FFmpeg and FFprobe payloads.

At startup it:

1. creates `%TEMP%\TinyRedactionTool\run-<random GUID>\`;
2. expands `ffmpeg.exe` and `ffprobe.exe` into that unique directory;
3. verifies each binary against the SHA-256 value injected by the builder;
4. hashes through an already-open read handle;
5. retains that handle for the full GUI session with `FileShare.Read` only;
6. allows execution/read access but prevents ordinary later write/delete opens; and
7. releases the locks and removes the runtime directory on normal exit.

TinyRedactionTool never searches `PATH` for media tools in the packaged release.

### 8.1 Inherited tamper-resistance control

The current v2.1.0 source retains verified FFmpeg/FFprobe file handles open with read-only sharing for the GUI session, preventing ordinary later write/delete replacement through normal Windows file-opening semantics.

The dedicated append-byte tamper experiment that originally demonstrated the need for this control is **historical evidence**. It was not freshly repeated for v2.1.0. The control remains present in the source; the final v2.1 packaged build and runtime smoke test completed successfully, but this specific tamper fault-injection was not repeated.

For the historical fault-injection provenance, see Section 23.

## 9. Frame preview and temporary-data model

### 9.1 Memory-only decoded preview

Preview frames are emitted by FFmpeg through `image2pipe`/stdout and loaded into a process memory stream. TinyRedactionTool does not intentionally write decoded unredacted preview PNG/JPG files to disk.

v2.0.0 changed who draws the preview on screen; v2.1.0 retains that renderer. The application renders the in-memory preview bitmap through its own viewport transform rather than relying on `PictureBox.SizeMode=Zoom`. This does not introduce a new decoded-frame disk cache.

### 9.2 Geometry mask files

Non-rectangular redactions can use temporary PNG masks. These contain generated geometry/colour coverage information, not copied source/patient imagery.

## 10. Viewport, zoom/pan and redaction-coordinate architecture

This coordinate separation was the primary v2.0.0 architectural change and remains the foundation for the v2.1.0 editing/viewport work.

### 10.1 Canonical coordinate boundary

Redactions live in **displayed-media coordinates**. Zoom/pan/window/panel state lives in **viewport coordinates**.

Conceptually:

```text
MEDIA coordinates
    -> viewport scale
    -> viewport pan/origin
    -> screen/view coordinates
```

Mouse input uses the inverse mapping:

```text
screen/view coordinates
    -> inverse pan/origin
    -> inverse scale
    -> MEDIA coordinates
```

Export consumes canonical media-space geometry and has no reason to know the current zoom factor, pan offset, window size or panel state.

### 10.2 Draft geometry

The v1.4-era UI kept unfinished Rectangle/Oval/Freeform geometry in PictureBox coordinates until commit. During v2 development this exposed a pre-existing defect: collapsing/restoring the side panel could move the media under an unfinished selection because the draft remained fixed to screen pixels.

v2.0.0 fixed that architecture, and v2.1.0 retains it. Draft Rectangle/Oval/Freeform geometry is converted to media coordinates immediately. It therefore remains attached to the same source pixels through:

- zoom changes;
- pan;
- panel collapse/restore;
- window resize;
- maximise/restore; and
- frame navigation/playback.

v2.1.0 extends this existing draft-only editing layer without changing committed/export geometry:

- Rectangle/Square drafts expose eight screen-sized handles: four corners plus North/East/South/West;
- Oval/Circle drafts expose four North/East/South/West handles;
- closed Freeform drafts expose one screen-sized handle per existing vertex;
- Shift-resizing constrains Rectangle/Oval drafts to square/circle proportions;
- handles and their larger invisible hit targets are viewport decoration only;
- Freeform vertex editing changes only the selected media-space vertex; and
- committed redactions remain immutable and have no resize handles.

A first click outside a closed Freeform dismisses the draft and is consumed; a subsequent click begins a new Freeform.

### 10.3 View rendering

The application owns preview rendering and applies one viewport transform consistently to the media and redaction overlays.

Fit mode derives its scale from the current viewport and preserves aspect ratio. Manual zoom stores an absolute scale where `1.0 = 100%`. Manual zoom is capped at 800%.

The coordinate transform uses floating-point geometry internally so pointer-centred zoom and inverse mapping do not accumulate avoidable integer rounding error. Stored/exported redaction geometry is normalised to the existing media-pixel representation at the commit/export boundary.

Selection outlines and other UI decoration remain screen-pixel oriented rather than growing proportionally with 800% zoom.

### 10.4 Pointer-centred zoom and pan

The Zoom tool supports:

- left-click zoom in around the pointer;
- right-click zoom out around the pointer;
- mouse-wheel zoom around the pointer;
- left-drag pan after a small drag threshold; and
- visible `- / Fit / +` controls.

Holding Space while a Rectangle/Oval/Freeform tool is selected temporarily borrows the pan gesture without changing the drawing tool or redaction state.

The v2 regression verified that zoom/pan state persists across Previous/Next Frame, seek-bar navigation, playback and pause; opening new media resets the viewport to Fit.

#### v2.1 always-available viewport gestures

v2.1.0 reuses the same pointer-centred zoom and pan state rather than introducing a second transform:

- mouse-wheel zoom is available whenever the pointer is over loaded media, regardless of the selected drawing tool;
- middle-button drag pans without changing the selected drawing tool;
- Space+left-drag temporary pan remains available; and
- the dedicated Zoom tool retains its left/right-click zoom and drag-pan behaviour.

Wheel-scale changes are ignored during an active draw/move/resize/vertex-edit/pan gesture so the viewport transform cannot change underneath an in-progress geometry operation.

### 10.5 Resize/panel behaviour

When in Fit mode, viewport size changes recalculate Fit for the new available area.

When manually zoomed, viewport resizing and right-panel collapse/restore preserve the zoom level and keep the same media region near the viewport centre as far as media bounds permit.

A stale-paint bug found during Slice 3 testing caused old preview pixels to remain visible during maximise/restore and drag-resize. The final renderer forces the required full repaint on viewport-size changes; regression testing confirmed the double-image/trailing-artifact defect was removed.

### 10.6 Export isolation

The v2 static audit specifically checked that zoom/pan state is not consumed by export-generation functions. A redaction created while zoomed/panned is exported using the same canonical media coordinates as one created at Fit.

This separation is a correctness and security requirement: a user must not be able to change the exported redaction location merely by resizing the window, collapsing a panel or altering zoom after the redaction was placed.

## 11. CFR/VFR timing architecture

### 11.1 Timing map

The trusted FFprobe enumerates every video frame using structured per-frame data including:

- `best_effort_timestamp`
- `best_effort_timestamp_time`
- `duration_time` when available
- `key_frame`

The application streams compact records and stores typed arrays rather than materialising a large per-frame JSON object.

A frame map is rejected if, among other conditions:

- required timing fields are absent;
- timestamps/times are unusable;
- presentation timestamps are not strictly increasing;
- frame identity cannot be represented exactly enough for the FFmpeg selector;
- the frame count exceeds the deliberate two-million-frame safety bound; or
- the independent FFmpeg full-decode frame count does not exactly equal the FFprobe map count.

No fallback to average-FPS arithmetic is used when safe timing cannot be established.

### 11.2 UI frame model

Logical frame indexes are the canonical identity used by the UI and redaction state.

- Previous/Next increments/decrements the logical frame index.
- Left/Right arrow keys provide the same exact-frame stepping behaviour.
- Seek-bar position is based on presentation time rather than frame-number percentage.
- Seek-bar clicks/drags find the source frame corresponding to real presentation time.
- Playback timer intervals use actual mapped frame durations.

An average FPS value may exist for display/informational purposes, but it is not the timing authority.

### 11.3 Exact preview identity

For video preview, TinyRedactionTool performs a coarse time seek only as a decode accelerator. It then uses `-copyts` and FFmpeg `select='eq(pts,targetPts)'` to identify the exact mapped source frame.

If the requested mapped frame is not decoded, preview extraction fails rather than returning a neighbouring frame.

The builder contains a functional seek+PTS smoke test that compares exact selection behaviour against a controlled baseline.

### 11.4 Redaction timing

Committed video redactions store:

- `StartFrame`
- `EndFrame`
- `BufferedStartFrame`
- `BufferedEndFrame`

The security buffer is two logical frames on each side, clamped to source bounds.

Export activation uses FFmpeg's sequential input frame variable `n`:

```text
between(n,startFrame,endFrame)
```

This avoids floating-point timestamp boundaries and avoids dependency on `frame / fps` conversion.

### 11.5 Timestamp-preserving export

Video export explicitly uses timestamp-preserving frame-sync settings including:

```text
-fps_mode:v:0 passthrough
-enc_time_base:v:0 filter
```

The intent is to preserve the filtergraph/source presentation cadence rather than allowing an automatic CFR decision that could duplicate/drop frames.

### 11.6 Post-export timeline reconciliation

Before finalisation, the output timeline is rebuilt with the trusted FFprobe.

Validation requires:

- exact source/output decoded frame-count equality; and
- every normalised output presentation timestamp to match its source counterpart within a small muxer-quantisation tolerance.

The tolerance is deliberately much smaller than one frame and varies with nominal frame interval.

This catches silent CFR conversion, frame duplication/drop and meaningful presentation-timing distortion before the `.partial` file can be promoted.

## 12. Rotation architecture

FFmpeg autorotation is used consistently for:

- first-frame geometry/preflight;
- exact preview extraction; and
- export.

Displayed dimensions are obtained from the decoded/autorotated image rather than trusting only raw encoded width/height metadata.

v2.1.0 continues to use this already-displayed coordinate convention for zoom/pan and redaction geometry. The consolidated regression covered 90°, 180° and 270° orientation cases and confirmed preview/redaction/export placement alignment.

## 13. Secure mask semantics

### 13.1 Rectangle

Opaque rectangular replacement uses `drawbox` with `t=fill`.

### 13.2 Oval and Freeform

Opaque non-rectangular masks deliberately disable anti-aliasing so the security edge has binary coverage rather than partially transparent pixels.

Freeform opaque masks also draw a hard edge stroke to dilate the polygon boundary by approximately one pixel within the export mask.

### 13.3 Spatial safety margin

An export-only copy of every Black/Coloured Box redaction expands the bounding geometry by one pixel on every available side, clamped to the media boundary. The on-screen user selection itself is not altered.

### 13.4 Blur/Pixelate distinction

Blur and Pixelate intentionally retain smoother visual edges and are not represented as irreversible redaction. The application displays a warning and recommends Black/Coloured Box for information that must not be recoverable.

The v2 regression exercised Blur and Pixelate at Fit and while zoomed/panned to confirm viewport state did not displace the selected media region or exported effect.

## 14. Metadata, chapters and extra streams

Exports use explicit metadata/chapter stripping:

```text
-map_metadata -1
-map_metadata:s -1
-map_chapters -1
```

The export graph maps the intended video stream and, only when requested, the primary audio stream.

Structured FFprobe inspection checks:

- exactly one video/image stream;
- expected audio state;
- zero subtitle streams;
- zero data streams;
- zero attachment streams;
- zero chapters;
- expected dimensions; and
- only a narrow allow-list of muxer/encoder housekeeping metadata keys.

The consolidated v2.1.0 regression rechecked metadata/chapter stripping. The earlier hardened security test had additionally used controlled fake global, stream and chapter metadata plus a chapter-related data stream and confirmed those values/streams did not survive export.

## 15. Audio handling

Audio is disabled by default.

Enabling **Keep original audio** displays a warning that TinyRedactionTool does not inspect or redact audio. The warning can be suppressed only for the current session.

When enabled, the export maps only:

```text
0:a:0?
```

The source's additional audio tracks are therefore not silently copied.

The v2 regression verified audio-off and audio-on behaviour and retained the same primary-audio-only model. Audio itself remains a residual disclosure channel when the user elects to retain it.

## 16. Partial-file and commit workflow

TinyRedactionTool writes to a same-directory temporary path:

```text
<stem>.partial.<GUID>.<ext>
```

The final destination is not created/replaced until the temporary export has passed post-export security validation.

For an existing destination, the application attempts an atomic `File.Replace`; otherwise it moves the validated partial into place.

The protected-destination failure path remains unchanged in the v2.1.0 source: if finalisation cannot replace an existing destination, the validated partial is not promoted over it. The dedicated exclusive-lock fault-injection evidence for this control is historical and was not separately repeated for v2.0.0; its provenance is recorded in Section 23.

## 17. Post-export validation

For video, the validation gate verifies:

- non-empty temporary file;
- structured FFprobe readability;
- expected stream counts/types;
- no chapters;
- metadata-key allow-list;
- expected dimensions;
- plausible duration;
- complete output frame timing map;
- exact frame-count equality with source;
- per-frame normalised presentation timing within tight muxer tolerance; and
- successful decode of the generated video stream.

Only after validation succeeds can finalisation occur.

### 17.1 Validation-failure fault-injection limitation

A post-export validator failure was not separately induced during the v2.1.0 feature regression. The explicit failure branches remain present/source-reviewed; fresh packaged validation-failure evidence is not claimed for v2.1.0.

## 18. Network/cloud warning model

UNC and mapped-network source paths trigger an opening warning explaining that unredacted content will traverse the network.

Detected network destinations trigger a separate warning explaining that the exported file will traverse the network and may be cloud-synchronised.

Source and destination warning suppression states are separate and session-only.

The v2 regression rechecked network warning behaviour. The control is not described as universal cloud-sync detection.

## 19. Windows Recent Items / MRU

TinyRedactionTool uses native Windows Open/Save dialogs with `OFN_DONTADDTORECENT`.

The dedicated historical security test observed no new current-session source/export Recent Items entries, while older development entries already existed. v2.1.0 retains the same implementation.

Result: **best-effort control**, not a guarantee of zero operating-system/EDR traces.

## 20. Error and path hygiene

Captured FFmpeg/FFprobe error text replaces the current sensitive source path with:

```text
[source media]
```

Captured text is also truncated to limit oversized diagnostics.

A deliberate fake-sensitive-filename test during the hardened security work confirmed that the application error dialog used the sanitised placeholder rather than exposing that source filename/path. The same error-sanitisation functions remain in v2.1.0.

No claim is made that every Windows, EDR or third-party diagnostic path is sanitised.

## 21. Source immutability

TinyRedactionTool reads source media and creates a separate export. It does not intentionally modify the source media file.

Source immutability was previously runtime-tested by comparing SHA-256 before and after repeated processing and remains part of the v2 design. The v2 regression did not reveal any source-write behaviour.

## 22. v2.1.0 functional regression record

The resize/edit feature was developed in isolated slices, with static harness results of 32/32 for Rectangle r2, 36/36 for Oval, and 60/60 for Freeform r2. The integrated Resize Slice 4 static harness then passed 51/51. The viewport-usability slice and consolidated RC1 were subsequently tested, and the user confirmed the complete consolidated full-regression checklist was green on 2026-09-18.

The frozen release source differs from consolidated RC1 only by the About-dialog version label. Therefore the source-level functional regression applies directly to this frozen source. The final secure-builder and packaged-runtime checks were subsequently completed successfully on 2026-09-18.

| Test area | Result | Evidence / notes |
|---|---|---|
| Frozen v2.0.0 baseline integrity | PASS | Development started from source hash `11698B006A1FF8759D7FF222246475FE9B0A091C5A4F61023AC4649ACBF2B4FB`. |
| Protected export filter builder | PASS | Kept byte-equivalent to frozen v2.0.0 throughout resize integration. |
| Exact video frame extraction | PASS | Kept byte-equivalent to frozen v2.0.0 throughout resize integration. |
| Export redaction-list preparation | PASS | Kept byte-equivalent to frozen v2.0.0 throughout resize integration. |
| Rectangle/Square draft resizing | PASS | Eight handles, cursor mapping, bounds, Shift-square, move/resize precedence. |
| Oval/Circle draft resizing | PASS | Four cardinal handles, bounds and Shift-circle. |
| Freeform vertex editing | PASS | Per-vertex handles, isolated point edits, whole-shape move retained. |
| Freeform outside-click dismissal | PASS | First outside click clears/consumes; second click starts a new polygon. |
| Resize handles under zoom/pan | PASS | Screen-sized UI decoration aligned to canonical draft geometry. |
| Create/Begin commit geometry | PASS | Final edited media-space geometry is committed; handles remain draft-only. |
| Always-on mouse-wheel zoom | PASS | Pointer-centred zoom over preview regardless of selected drawing tool. |
| Always-on middle-button pan | PASS | Reuses existing viewport pan state/clamping. |
| Space+drag temporary pan | PASS | Retained. |
| Dedicated Zoom tool | PASS | Existing left/right click zoom and drag-pan retained. |
| Still-image redaction | PASS | Consolidated full regression green. |
| CFR video | PASS | Consolidated full regression green. |
| VFR video | PASS | Consolidated full regression green. |
| Exact Begin/End frame activation | PASS | Consolidated full regression green. |
| Rotation 90°/180°/270° | PASS | Consolidated full regression green. |
| Black/Coloured Box | PASS | Consolidated full regression green. |
| Conventional Blur / Pixelate | PASS | v2.1 does not include the parked replacement-first experiment. |
| Audio OFF / audio ON warning | PASS | Consolidated full regression green. |
| Metadata/chapter stripping | PASS | Consolidated full regression green. |
| WebM/VP9 | PASS | Consolidated full regression green. |
| Panel collapse/restore and window resize | PASS | Consolidated full regression green. |
| Mixed-state torture sequence | PASS | Consolidated full regression green. |
| Final Windows builder source-hash gate | PASS | Verified frozen source `2BC392FD52587343AB4CEA95B19C295286E44E4D3543634D9D3D1E383567BDC7`. |
| Final FFmpeg/FFprobe hash gates | PASS | Verified approved binaries `28612C0A94D50A29AABD0555C91E086D1CCDF13260757B83B4BBD53A0C2CDCE0` / `BB8CBA76F9D4F05DD608F319477A0604D8A8C289FB6A885B03919F07C4DC9855`. |
| Builder functional media-tool smoke tests | PASS | Required features, exact-preview/frame-index tests, network-disable checks, structured FFprobe timing and MP4/H.264 + WebM/VP9 VFR timestamp round trips all passed. |
| Final packaged EXE launch | PASS | Final EXE opened normally; About/version and v2.1 interaction smoke tests were reported green. |
| Independent final EXE SHA-256 | PASS | `1770318460DA5FCE5E7E5957F9937674D2ABF57C409189DAF915268D4A55BCB2` matched the builder-reported hash exactly. |

## 23. Historical security evidence inherited by v2.1.0

**Historical provenance only:** the fault-injection evidence in this section originates from the **v1.3.8 hardening/security test campaign**. It is retained because the corresponding controls remain present and materially unchanged through v2.1.0. These items are **not** represented as freshly repeated v2.1.0 fault-injection tests.

The following historical tests remain relevant to the current control design:

- post-verification runtime FFmpeg/FFprobe write/replace attempt blocked by retained read-only file handles;
- exclusive-lock final-destination commit failure leaving the prior destination untouched;
- deliberate fake-sensitive source path sanitisation test;
- controlled source-file before/after hash immutability test;
- direct `%TEMP%` observation for absence of decoded preview image files; and
- dedicated Recent Items observation.

The v2.1 draft-editing/viewport work did not intentionally alter these controls, and the protected export/timing/trust code paths were kept outside the feature changes.

## 24. Build-time smoke tests

The v2.1.0 secure builder reused the established functional gates for the approved custom media tools after pinning the frozen application-source hash `2BC392FD52587343AB4CEA95B19C295286E44E4D3543634D9D3D1E383567BDC7`. No FFmpeg/FFprobe rebuild was required for the v2.1 UI/geometry changes.

The existing gate includes:

- exact approved media-tool SHA-256 verification;
- frozen application-source SHA-256 verification;
- required encoder/muxer/filter/protocol checks;
- explicit network-protocol absence checks;
- `null` + `wrapped_avframe` functional decode/discard;
- `image2pipe` + PNG functional output;
- exact logical-frame `select` behaviour;
- exact PTS-based preview selection;
- FFprobe `-show_frames`, `-show_entries`, `-select_streams` and structured output;
- controlled unequal-frame-timing enumeration; and
- timestamp-preserving VFR round trips through MP4/H.264 and WebM/VP9.

**v2.1.0 build status: PASS.** The Windows builder verified the frozen source and approved media tools, all listed smoke tests passed, packaging produced a single `TinyRedactionTool.exe` with no `.config` sidecar, the independent EXE hash matched `1770318460DA5FCE5E7E5957F9937674D2ABF57C409189DAF915268D4A55BCB2`, and the packaged-runtime smoke test was reported green. Builder package identity: `6DF3F0A51D37B42E649CD4A5DD2E0B4289F3B2B499BCF2D9B096B9038D974C7F`.

## 25. Known residual risks and explicit non-guarantees

The following limitations are intentional and must remain visible in release documentation:

- Windows pagefile may contain process memory outside TinyRedactionTool's control.
- Crash dumps may contain process memory outside application control.
- EDR, Sysmon, antivirus and process-monitoring tools may observe executable paths, process arguments or file activity.
- Screen capture, clipboard monitoring, backup, filesystem snapshots and forensic tooling are outside application control.
- Local folders may be cloud-synchronised by other software.
- Native Windows Recent Items suppression is best-effort.
- Abnormal process termination may leave the extracted trusted FFmpeg/FFprobe binaries in the random runtime TEMP directory. Those binaries do not contain source/patient media.
- The runtime file-sharing locks do not defend against a compromised operating system/kernel or sufficiently privileged attacker.
- Broad input parsing remains enabled for compatibility and therefore retains media-parser attack surface.
- The custom FFmpeg build disables networking but retains required local file/pipe protocols.
- The complete build is not fully reproducible because signed MSYS2 package repositories are rolling.
- Universal cloud-sync detection is not possible.
- Audio is not inspected or redacted when retained.
- Blur and Pixelate are not secure irreversible redaction.
- Long-path support beyond normal Windows path limits is not claimed for the standalone release.
- An ordinary desktop application cannot promise zero OS-level forensic artefacts.
- Zoom/pan correctness reduces viewport-related placement risk but does not compensate for a user selecting the wrong source region or choosing an inappropriate redaction mode.

## 26. Security conclusion

Within the stated threat model, the frozen TinyRedactionTool v2.1.0 source retains the hardened v2.0.0 media/timing/export architecture while adding draft-only geometry editing and more convenient viewport navigation without coupling those UI states to export geometry.

The source/regression evidence demonstrates:

- canonical media-space geometry remains independent of zoom/pan/window state;
- resize/vertex handles are screen-space, draft-only decoration;
- committed redactions use the final edited canonical geometry and remain immutable;
- always-on wheel zoom and middle-button pan reuse the existing viewport transform;
- protected CFR/VFR, frame extraction and export-list functions were not rewritten for the resize feature;
- conventional Black/Blur/Pixelate behaviour remains unchanged from the tested architecture; and
- the existing trust, metadata/audio, partial-export and post-export validation controls remain part of the source.

The v2.1.0 Windows builder run, source/media-tool hash gates, media-tool smoke tests, packaged launch and independent final EXE hash verification have all been completed. The final packaged release identity is `TinyRedactionTool.exe` SHA-256 `1770318460DA5FCE5E7E5957F9937674D2ABF57C409189DAF915268D4A55BCB2`; the secure builder package identity is `6DF3F0A51D37B42E649CD4A5DD2E0B4289F3B2B499BCF2D9B096B9038D974C7F`.

TinyRedactionTool should be described as **security-conscious/fail-closed redaction software**, not as a mechanism that can erase all traces of sensitive data from Windows or guarantee protection against a compromised host.
