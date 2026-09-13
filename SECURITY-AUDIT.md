# TinyRedactionTool Security Audit

**Application:** TinyRedactionTool  
**Audited version:** v1.3.8  
**Audit/test date:** 2026-09-13  
**Platform:** 64-bit Windows / Windows PowerShell 5.1 builder  
**Primary use case:** Local redaction of still images and video that may contain sensitive information  
**License:** GPL-2.0-or-later

## 1. Executive summary

TinyRedactionTool v1.3.8 is a local Windows redaction application with a security model built around four core principles:

1. **Fail closed when media identity or timing is ambiguous.**
2. **Use opaque replacement, not reversible-looking effects, for security-sensitive redaction.**
3. **Do not trust arbitrary FFmpeg/FFprobe binaries from the host environment.**
4. **Do not promote an export to the final destination until it has passed post-export inspection.**

The v1.3.8 work replaced the previous blanket rejection of variable-frame-rate video with a frame-identity model based on actual per-frame presentation timing. CFR and VFR sources now use the same validated logical-frame model. Preview, frame navigation, redaction activation and export validation no longer depend on `frame / fps` arithmetic.

The runtime test plan exercised CFR and real smartphone VFR material, exact redaction boundaries, MP4/H.264 and WebM/VP9 exports, metadata stripping, audio handling, rotation, temporary-data behaviour, source immutability, network warnings, MRU behaviour, failed finalisation, error sanitisation and embedded-tool integrity.

A security-significant issue was discovered during testing: the initial v1.3.8 candidate verified FFmpeg/FFprobe at startup but did not prevent modification of the already-verified extracted files later in the same session. This was fixed before the final tested build by retaining read-only file handles with `FileShare.Read` for the life of the GUI. The post-fix tamper attempt was blocked by Windows before the runtime FFprobe could be modified.

No claim is made that TinyRedactionTool eliminates all operating-system forensic artefacts, protects against a compromised Windows kernel/administrator, or makes Blur/Pixelate irreversible.

## 2. Tested build identity

The final runtime-tested v1.3.8 build produced these hashes:

| Artifact | SHA-256 |
|---|---|
| `TinyRedactionTool.exe` | `8590DC0C584A064A9C56619D9CB1E944501A8FFDC5EB2D022182C8434290AB96` |
| embedded `ffmpeg.exe` | `28612C0A94D50A29AABD0555C91E086D1CCDF13260757B83B4BBD53A0C2CDCE0` |
| embedded `ffprobe.exe` | `BB8CBA76F9D4F05DD608F319477A0604D8A8C289FB6A885B03919F07C4DC9855` |

Any later source/build change invalidates the direct applicability of this test record to the resulting binary. Because the full toolchain is not bit-for-bit reproducible, a later clean rebuild may also have different hashes even when the intended source revision is unchanged.

## 3. Security objectives

For sensitive information-oriented use, TinyRedactionTool aims to:

- process source media locally unless the user deliberately selects a network/cloud-backed path;
- avoid application telemetry and background upload services;
- leave the source file unchanged;
- avoid intentionally writing unredacted decoded preview frames to disk;
- provide a clearly identified opaque redaction method with hard security edges;
- distinguish opaque redaction from visual obscuration;
- keep redaction activation aligned to exact logical frames on CFR and VFR sources;
- strip source metadata, chapters and unintended streams;
- disable audio by default and retain only the primary audio stream when explicitly enabled;
- validate a temporary export before replacing/creating the user's final destination;
- avoid arbitrary FFmpeg/FFprobe discovery through `PATH`;
- verify the exact bundled media tools before use and protect the verified runtime copies against ordinary post-verification modification;
- sanitise sensitive source paths from captured media-tool error text where practical;
- warn when source/destination paths are detected as network backed; and
- reduce Windows Recent Items exposure using native dialog flags where practical.

## 4. Threat model

### 4.1 In scope

The application attempts to mitigate or detect:

- accidental export of the wrong frame range because of CFR/VFR timing assumptions;
- one-frame redaction leaks at range boundaries;
- semi-transparent anti-aliased edges on opaque oval/freeform masks;
- accidental use of an untrusted `ffmpeg.exe` or `ffprobe.exe` from `PATH`;
- modification/replacement of the verified extracted media tools through ordinary Windows file opens during the application session;
- source metadata, chapters, subtitle/data/attachment streams and secondary audio tracks leaking into output;
- unredacted preview frame files being left in `%TEMP%` after a crash;
- invalid/incomplete exports replacing an existing destination;
- unexpected network-backed source/destination use;
- direct disclosure of a sensitive source path in captured FFmpeg/FFprobe error text;
- source-file modification by the application; and
- silent frame duplication/drop or CFR conversion during VFR video export.

### 4.2 Out of scope / residual platform risk

TinyRedactionTool cannot guarantee protection from:

- a compromised Windows kernel, administrator or sufficiently privileged attacker;
- process-memory inspection;
- Windows pagefile contents;
- crash dumps;
- EDR/Sysmon/antivirus/process-monitoring telemetry;
- screen capture or photography of the display;
- filesystem snapshots, backup clients or cloud sync controlled by other software;
- shell/process-history mechanisms outside the application's control;
- physical access to the host;
- malware that already controls the user's session;
- sensitive information present in audio when the user enables audio retention; or
- vulnerabilities in the broad set of enabled input decoders/demuxers required for media compatibility.

## 5. Local-processing and network model

The application contains no telemetry service, media upload service or background update checker. Runtime media processing uses the bundled custom FFmpeg/FFprobe build.

The custom FFmpeg configuration is compiled with networking disabled. Local file and pipe protocols remain enabled because the application requires them.

The About dialog contains a GitHub hyperlink. Clicking that link intentionally invokes the user's browser. Therefore the security documentation must not claim that TinyRedactionTool can never cause any network connection under any user action.

UNC paths and mapped network drives are permitted but produce separate Source and Destination warnings. Each warning has its own session-only suppression state. This is an informed-consent control, not a prohibition.

Universal cloud-sync detection is not attempted. A path that appears local may still be synchronised by another application.

## 6. Trusted FFmpeg/FFprobe supply chain

### 6.1 Pinned major inputs

The v1.3.8 builder pins:

- **FFmpeg source commit:** `fd7c73d01e976d2e332e85862ab63ab608710834`
- **MSYS2 base release asset ID:** `560868716`
- **MSYS2 expected archive size:** `42915960` bytes
- **MSYS2 expected SHA-256:** `F6BBDE384F3331FB293C5051D5B9DBEC01C772BCCDCEEE83B78213801264D0BD`
- **PS2EXE:** `1.0.18`

The builder verifies the FFmpeg `FETCH_HEAD` against the full pinned commit.

### 6.2 Reproducibility limitation

MSYS2 packages installed by `pacman` are obtained from signed rolling MSYS2 repositories. The builder therefore improves supply-chain pinning but does **not** make the complete compiler/library environment immutable. Bit-for-bit reproducibility is not claimed.

### 6.3 Restricted output profile

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

Broad native input decoding/demuxing remains enabled for compatibility. That is an explicit attack-surface trade-off and is documented as residual risk.

## 7. Runtime embedded-tool trust model

The packaged application embeds GZip-compressed FFmpeg and FFprobe payloads.

At startup it:

1. creates `%TEMP%\TinyRedactionTool\run-<random GUID>\`;
2. expands `ffmpeg.exe` and `ffprobe.exe` into that unique directory;
3. verifies each binary against the SHA-256 value injected by the builder;
4. hashes through an already-open read handle;
5. retains that handle for the full GUI session with `FileShare.Read` only;
6. allows execution/read access but prevents ordinary later write/delete opens; and
7. releases the locks and removes the runtime directory on normal exit.

TinyRedactionTool never searches `PATH` for media tools.

### 7.1 Integrity issue found and fixed during testing

An earlier v1.3.8 candidate hash-verified the extracted runtime tools at startup but released the files afterward. A controlled test appended a byte to the extracted `ffprobe.exe` after startup; the application continued to open CFR and VFR media, proving a post-verification tamper window existed.

The final v1.3.8 source was changed to keep verified file handles open with read-only sharing for the session. The same tamper attempt was repeated. Windows rejected the write open with an `IOException` because FFprobe was in use by another process. Normal media opening was then regression-tested successfully while the locks were active.

This control protects against ordinary file replacement/modification semantics. It is not represented as protection against a compromised kernel or highly privileged attacker.

## 8. Frame preview and temporary-data model

### 8.1 Memory-only decoded preview

Preview frames are emitted by FFmpeg through `image2pipe`/stdout and loaded into a process memory stream. TinyRedactionTool does not intentionally write decoded unredacted preview PNG/JPG files to disk.

During runtime inspection of `%TEMP%\TinyRedactionTool`, only the random runtime directory and extracted `ffmpeg.exe`/`ffprobe.exe` were observed for the test session. No decoded source frames were present.

After normal application exit the runtime directory was absent.

### 8.2 Geometry mask files

Non-rectangular redactions can use temporary PNG masks. These contain geometry/colour coverage information, not copied patient/source imagery.

## 9. CFR/VFR timing architecture

### 9.1 Timing map

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

### 9.2 UI frame model

Logical frame indexes are the canonical identity used by the UI and redaction state.

- Previous/Next increments/decrements the logical frame index.
- Seek-bar position is based on presentation time rather than frame-number percentage.
- Seek-bar clicks find the source frame corresponding to real presentation time.
- Playback timer intervals use actual mapped frame durations.

An average FPS value may exist for display/informational purposes, but it is not the timing authority.

### 9.3 Exact preview identity

For video preview, TinyRedactionTool performs a coarse time seek only as a decode accelerator. It then uses `-copyts` and FFmpeg `select='eq(pts,targetPts)'` to identify the exact mapped source frame.

If the requested mapped frame is not decoded, preview extraction fails rather than returning a neighbouring frame.

The builder contains a functional seek+PTS smoke test that byte-compares the selected result against an exact from-start logical-frame baseline.

### 9.4 Redaction timing

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

This avoids floating-point timestamp boundaries and eliminates the previous dependency on `frame / fps` conversion.

### 9.5 Timestamp-preserving export

Video export explicitly uses:

```text
-fps_mode:v:0 passthrough
-enc_time_base:v:0 filter
```

The intent is to preserve the filtergraph/source presentation cadence rather than allowing an automatic CFR decision that could duplicate/drop frames.

### 9.6 Post-export timeline reconciliation

Before finalisation, the output timeline is rebuilt with the trusted FFprobe.

Validation requires:

- exact source/output decoded frame-count equality; and
- every normalised output presentation timestamp to match its source counterpart within a small muxer-quantisation tolerance.

The tolerance is deliberately much smaller than one frame and varies between approximately 1.5 ms and 5 ms depending on nominal frame interval.

This catches silent CFR conversion, frame duplication/drop and meaningful presentation-timing distortion before the `.partial` file can be promoted.

## 10. Rotation architecture

FFmpeg autorotation is used consistently for:

- first-frame geometry/preflight;
- exact preview extraction; and
- export.

Displayed dimensions are obtained from the decoded/autorotated image rather than trusting only raw encoded width/height metadata.

Runtime tests covered 90°, 180° and 270° orientation metadata, verifying that preview orientation, selection coordinates and exported placement aligned.

## 11. Secure mask semantics

### 11.1 Rectangle

Opaque rectangular replacement uses `drawbox` with `t=fill`.

### 11.2 Oval and Freeform

Opaque non-rectangular masks deliberately disable anti-aliasing so the security edge has binary coverage rather than partially transparent pixels.

Freeform opaque masks also draw a hard edge stroke to dilate the polygon boundary by approximately one pixel within the export mask.

### 11.3 Spatial safety margin

An export-only copy of every Black/Coloured Box redaction expands the bounding geometry by one pixel on every available side, clamped to the media boundary. The on-screen user selection itself is not altered.

### 11.4 Blur/Pixelate distinction

Blur and Pixelate intentionally retain smoother visual edges and are not represented as irreversible redaction. The application displays a warning and recommends Black/Coloured Box for information that must not be recoverable.

## 12. Metadata, chapters and extra streams

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

A controlled test source was created with fake identifiers in global metadata, video-stream metadata and chapter metadata, plus the chapter-related data stream. After TinyRedactionTool export, all fake values were absent, chapters were empty and only the intended video stream remained.

## 13. Audio handling

Audio is disabled by default.

Enabling **Keep audio** displays a warning that TinyRedactionTool does not inspect or redact audio. The warning can be suppressed only for the current session.

When enabled, the export maps only:

```text
0:a:0?
```

The source's additional audio tracks are therefore not silently copied.

Runtime tests verified:

- audio-off export contained zero audio streams;
- audio-on export retained one AAC source track;
- source-specific audio metadata such as creation time and source handler name did not survive;
- a controlled two-audio-stream source exported with exactly one audio stream; and
- metadata labels placed on both source audio tracks did not survive.

Audio itself remains a residual disclosure channel when the user elects to retain it.

## 14. Partial-file and commit workflow

TinyRedactionTool writes to a same-directory temporary path:

```text
<stem>.partial.<GUID>.<ext>
```

The final destination is not created/replaced until the temporary export has passed post-export security validation.

For an existing destination, the application attempts an atomic `File.Replace`; otherwise it moves the validated partial into place.

A controlled test held an existing destination open under an exclusive lock. TinyRedactionTool completed and validated the partial export but could not finalise it. The application reported that the existing destination was left untouched, removed the partial file, and the pre/post SHA-256 of the protected destination matched exactly.

## 15. Post-export validation

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

### Validation-failure test limitation

A post-export validator failure was **not separately induced** in the final production build. The original test plan explicitly allowed this test "where practical". Creating a dedicated production test hook or racing/corrupting the transient partial file solely to manufacture this condition was judged less useful than preserving the production design.

The validation path was exercised on every successful video export, and the separate finalisation-failure test proved that a validated partial is not promoted when commit fails. The source contains an explicit validation-failure branch that deletes the partial and returns without finalising it, but this specific branch is documented as code-reviewed rather than deliberately fault-injected during the final run.

## 16. Network/cloud warning model

UNC and mapped-network source paths trigger an opening warning explaining that unredacted content will traverse the network.

Detected network destinations trigger a separate warning explaining that the exported file will traverse the network and may be cloud-synchronised.

Source and destination warning suppression states are separate and session-only.

The runtime test verified both warning classes appeared with the intended controls.

The control is not described as universal cloud-sync detection.

## 17. Windows Recent Items / MRU

TinyRedactionTool uses native Windows Open/Save dialogs with `OFN_DONTADDTORECENT`.

During the v1.3.8 test session, no new Recent Items entries corresponding to the current source filenames or current evening exports were observed. Historical TinyRedactionTool-related `.lnk` files from earlier development activity were already present.

Result: **best-effort control passed for the test session**, with the explicit limitation that zero operating-system/EDR traces are not guaranteed.

## 18. Error and path hygiene

Captured FFmpeg/FFprobe error text replaces the current sensitive source path with:

```text
[source media]
```

Captured text is also truncated to limit oversized diagnostics.

A deliberately invalid file named `TEST_PATIENT_67890_SECRET.mp4` was opened during testing. The displayed media-safety error contained `[source media]` and did not expose the fake sensitive filename/path.

No claim is made that every Windows, EDR or third-party diagnostic path is sanitised.

## 19. Source immutability

The known-good CFR test source was SHA-256 hashed before and after repeated TinyRedactionTool processing.

Both hashes were:

```text
66CFC6A19EED2FD76F2FC130E948013D70F3CACB1B215CC4C47ADB55D566D1D7
```

Result: source file remained byte-for-byte unchanged.

## 20. Runtime test record

| Test | Result | Notes |
|---|---|---|
| Application launch / embedded tool extraction | PASS | Single EXE launched and extracted trusted tools to random runtime directory. |
| Runtime FFmpeg/FFprobe hash verification | PASS | Final embedded tool hashes matched pinned build hashes. |
| Runtime post-verification tool tamper resistance | PASS after fix | Initial candidate exposed a tamper window; final build's session locks blocked the write attempt. |
| CFR open | PASS | Known-good CFR source opened under final v1.3.8 build. |
| CFR Previous/Next | PASS | Exact-frame stepping regression passed. |
| CFR seek bar | PASS | Time-based seek mapping regression passed. |
| CFR playback | PASS | Frame-duration playback regression passed. |
| CFR Black Box export | PASS | Export validated and frame boundaries verified. |
| VFR smartphone source open | PASS | Old VFR rejection removed; validated timing map accepted real VFR source. |
| VFR Previous/Next | PASS | Exact-frame stepping passed. |
| VFR seek bar | PASS | Actual presentation-time mapping passed. |
| VFR playback | PASS | Variable frame durations behaved correctly in preview playback. |
| VFR frame-range live preview | PASS | User frames 20–24 with ±2-frame buffer produced OFF 17 / ON 18 / ON 26 / OFF 27. |
| VFR MP4/H.264 export | PASS | Finished/validated, reopened, exact boundary frames verified. |
| VFR WebM/VP9 export | PASS | Finished/validated, reopened, exact boundary frames verified. |
| CFR regression after final VFR changes | PASS | Navigation, seek, playback, export and boundaries all rechecked. |
| Metadata stripping | PASS | Fake global/stream/chapter metadata removed; chapter/data stream absent. |
| Audio OFF | PASS | Export contained zero audio streams. |
| Audio warning | PASS | Warning displayed when enabling audio. |
| Audio ON | PASS | Primary AAC audio retained; source-specific audio metadata removed. |
| Multi-audio source | PASS | Only primary audio retained; secondary audio absent. |
| Black Box rectangle | PASS | Exact frame coverage previously verified; opaque replacement export worked. |
| Black Box oval | PASS | Hard opaque edge visually verified. |
| Black Box freeform | PASS | Hard opaque edge visually verified. |
| Blur | PASS | Warning/effect/export regression passed. |
| Pixelate | PASS | Warning/effect/export regression passed. |
| Rotation 90° | PASS | Preview/redaction/export placement aligned. |
| Rotation 180° | PASS | Preview/redaction/export placement aligned. |
| Rotation 270° | PASS | Preview/redaction/export placement aligned. |
| Export finalisation failure | PASS | Existing locked destination preserved; partial removed. |
| Post-export validation-failure fault injection | NOT SEPARATELY INDUCED | Validation branch code-reviewed; no production test hook introduced. |
| Network source warning | PASS | Warning shown. |
| Network destination warning | PASS | Warning shown. |
| Recent Items/MRU | PASS, best-effort | No current-session source/new export entry observed; historical entries existed. |
| Temp data while running | PASS | Only trusted runtime tools observed; no decoded unredacted frame images. |
| Normal-exit TEMP cleanup | PASS | Runtime directory absent after close. |
| Source immutability | PASS | Pre/post SHA-256 identical. |
| Neutral output filename | PASS | `REDACTED_yyyyMMdd_HHmmss.ext`. |
| Error/path sanitisation | PASS | Fake sensitive source filename/path absent from application error dialog. |

## 21. Build-time smoke tests

Before packaging, the v1.3.8 builder validates the custom media tools on normal Windows.

The gate includes:

- required encoder/muxer/filter/protocol checks;
- explicit network-protocol absence checks;
- `null` + `wrapped_avframe` functional decode/discard;
- `image2pipe` + PNG functional output;
- exact logical-frame `select` behaviour;
- exact PTS-based preview selection;
- FFprobe `-show_frames`, `-show_entries`, `-select_streams` and structured output;
- controlled unequal-frame-timing enumeration; and
- timestamp-preserving VFR round trips through MP4/H.264 and WebM/VP9.

During staged development, the WebM/VP9 smoke test exposed an unsupported `gbrap` pixel-format path before packaging. The application and builder were corrected to specify `yuv420p`, and the round-trip test subsequently passed. This is evidence that the functional smoke tests are capable of catching real integration failures rather than merely confirming feature names exist.

## 22. Known residual risks and explicit non-guarantees

The following limitations are intentional and must remain visible in release documentation:

- Windows pagefile may contain process memory outside TinyRedactionTool's control.
- Crash dumps may contain process memory outside application control.
- EDR, Sysmon, antivirus and process-monitoring tools may observe executable paths, process arguments or file activity.
- Screen capture, backup, filesystem snapshots and forensic tooling are outside application control.
- Local folders may be cloud-synchronised by other software.
- Native Windows Recent Items suppression is best-effort.
- Abnormal process termination may leave the extracted trusted FFmpeg/FFprobe binaries in the random runtime TEMP directory. Those binaries do not contain patient media.
- The runtime file-sharing locks do not defend against a compromised operating system/kernel or sufficiently privileged attacker.
- Broad input parsing remains enabled for compatibility and therefore retains media-parser attack surface.
- The custom FFmpeg build disables networking but retains required local file/pipe protocols.
- The complete build is not fully reproducible because signed MSYS2 package repositories are rolling.
- Universal cloud-sync detection is not possible.
- Audio is not inspected or redacted when retained.
- Blur and Pixelate are not secure irreversible redaction.
- Long-path support beyond normal Windows path limits is not claimed for the standalone release.
- An ordinary desktop application cannot promise zero OS-level forensic artefacts.

## 23. Security conclusion

Within the stated threat model, the final tested v1.3.8 build demonstrates a substantially hardened redaction workflow:

- trusted, pinned and session-locked media tools;
- local memory-only preview;
- native CFR/VFR frame identity without FPS arithmetic;
- exact logical-frame redaction activation;
- hard opaque security masks with spatial/temporal safety margins;
- metadata/chapter/extra-stream stripping;
- conservative audio handling;
- transactional partial-file export and validation;
- post-export frame-timeline reconciliation;
- source immutability;
- network-location warnings; and
- explicit disclosure of platform limitations.

The application should therefore be described as **security-conscious/fail-closed redaction software**, not as a mechanism that can erase all traces of sensitive data from Windows or guarantee protection against a compromised host.
