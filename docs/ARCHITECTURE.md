# Architecture and current decisions — development 0.4.0

## Protected baseline

`sources/` was empty. The local v2.5.0 source/build/documentation and the v2.5.1 corrected overlay were read as references. Their files and publishing scripts were not modified or executed. The approved FFmpeg/FFprobe hashes match the v2.5.1 source. The retrieved public GitHub page described an older release, so requirements use the union of that feature list and later local behaviour. The acceptance register retains all 138 entries. No previous-conversation design mock-up was found; the supplied written layout direction was used.

## Runtime and dependencies

The rewrite now targets .NET 10 WPF, built with portable SDK 10.0.403 and runtime/reference packs 10.0.14. The SDK archive was checked against the SHA-512 in official Microsoft release metadata. No SDK was installed machine-wide. NuGet resolves against a local feed only, with lock files. LibVLCSharp 3.10.2 and VideoLAN.LibVLC.Windows 3.0.24 are pinned by version and downloaded-package SHA-256.

The new playback stage includes 224 pinned x64 native DLLs and excludes 99 modules, including normal network access, discovery, Lua, playlist and streaming-output components. Exact native contents and hashes are embedded in the application and verified before loading; read-sharing-only leases remain for the process lifetime. Unexpected or changed DLLs fail closed. The plugin search path is fixed to this private directory, global VLC configuration is ignored, external subtitle discovery and network metadata are disabled, and the engine receives managed file callbacks rather than a media URL. These measures are not a formal OS network sandbox or a custom network-disabled libVLC build; privacy/security acceptance must retain that distinction.

## Playback

The earlier WPF MediaPlayer prototype depended on installed Windows codecs and did not meet broad playback requirements. It has been replaced by private VideoLAN playback, with decoded video returned through memory callbacks and audio scheduled by libVLC. Its native scheduler owns timing, seeking, speed and AV playback. The UI's small timer only refreshes transport text; it does not drive decoding.

CPU output is capped at 1280 pixels on the long side. Eight native picture slots keep decode completion separate from presentation; a published frame and its clock sample are copied atomically, and WPF queues at most one update. Pictures are copied into managed memory only on presentation. Native state getters must not run inside video callbacks: Stop can hold a player lock while waiting for callbacks, which produced a deadlock during testing. The live clock advances monotonically from playback start/seek, using a local monotonic clock at the chosen speed. Advancing native time events can correct it forwards; repeated stale native times cannot rewind it. Pause/buffering transitions preserve elapsed time before suspending interpolation. Explicit seeks reset the clock anchor. This handles silent MP4 inputs whose native reported time remains at 0.25s even while pictures continue. Each presented WPF frame updates the playhead directly, avoiding reliance on a lower-priority timer. LibVLC 3's callbacks do not expose exact frame PTS. Live animation therefore remains approximate; exact paused PTS inspection is authoritative for editing, and export never depends on the live view.

Hardware decoding is explicitly disabled in this CPU-callback implementation. Hardware decode plus GPU readback is not assumed faster or zero-copy. Large/high-FPS sources can overload decoding, conversion or memory transfers. At 1280×720, the nine native buffers occupy about 32 MiB, in addition to the managed/WPF images and native decoder state. Full source maps and still-image inspection add memory/time. No universal 4K/60 FPS performance claim is made.

## Coordinates, timestamps and editing

The displayed-media coordinate space is autorotated and normalised to square pixels. The same approved scale expression is used by exact inspection, tracking and export; native playback is configured to the same display aspect and dimensions. Normalisation expands an axis rather than discarding source resolution. Projects record the coordinate convention; legacy development projects without this field are recognised and reprojected only after the source fingerprint matches. Migration is conservative about coverage margins and invalidates prior tracking review when geometry changes.

The complete source frame map retains raw integer PTS and a presentation-time origin. Normalised timestamps drive geometry; raw PTS selects exact paused frames. Ambiguous/duplicate frame identities fail closed. Region ranges are inclusive source-frame ranges, buffered two logical frames each side; geometry holds its active-range endpoint during the buffer. Keyframes interpolate linearly in media time and hold their outer endpoints. Geometry remains in displayed-media pixels through Fit, letterboxing, manual zoom, pan and resize. Physical-pixel zoom accounts for WPF DPI scale; actual monitor scaling still requires runtime acceptance.

Editing on a moving/paused live proxy first requests exact inspection. Property application is disabled while playing, processing or seeking. Begin/End use inspected source timestamps. Decoration visibility is independent of effect/export coverage.

## Assisted tracking

Initial tracking deliberately uses a small C# appearance matcher rather than adding an unverified OpenCV runtime. It compares a 16×16 normalised patch with nearby translation/scale candidates. Search is limited to 8–24 pixels at analysis resolution, and scale candidates span roughly ±10% per frame. Bilinear sampling, integer candidate bounds, a minimum texture check, minimum correlation and separation from spatially distinct alternatives provide defensible stop rules. These numbers are diagnostics, not probabilities. They are not presented as identity confidence.

Analysis uses one continuous approved FFmpeg image pipe for the requested source-frame interval. Frames stay in memory at up to 640 pixels on the long side; backward processing uses a bounded 128 MiB reverse buffer. PNG framing is parsed by chunk lengths with explicit memory limits, not by scanning for incidental signatures. Cancellation kills the owned decoder and commits no results.

Manual anchors reseed analysis explicitly and are never silently replaced. Retracking replaces automatic data only inside the requested range, retaining outside segments and manual points. Every new segment is Unreviewed. Low texture, mismatch or ambiguity records a Lost remainder and stops; no automatic reacquisition is claimed. Explicit manual correction invalidates previous review. Results persist as editable keyframes/review ranges; export is blocked on unresolved ranges. This is selected-appearance tracking, not global camera-motion compensation, face recognition or proof of redaction.

## Opaque export

Image export prepares a separate opaque raster, writes a partial PNG, decodes it and compares every output pixel before finalisation. Source metadata is not copied. Existing destinations are not replaced in this development slice.

Video export snapshots project data, rechecks policy/source fingerprint, and generates only geometry/colour masks. Mask files never contain copied source imagery. Deduplicated full-frame binary masks are fed through a microsecond-timebase concat input, slightly advanced to avoid rounding a mask just after its source frame. The original video remains the timing-driving stream. Its presentation origin is shifted consistently; frame sync is passthrough with the filter timebase retained. AVI disables B-frames and negative-timestamp shifting because that combination otherwise lost/changed timestamps in tests.

H.264 is used for MP4/MOV/M4V/AVI/MKV, VP9 for WebM. Audio is off by default; only primary audio is optionally encoded as AAC or Opus after a warning. Metadata/chapters, subtitle/data/attachment and extra audio streams are excluded. The promotion gate checks codec/stream counts, dimensions, container duration against the displayed timeline, permitted housekeeping metadata, audio state, complete decoded frame count and every normalised PTS, then performs a full decode check. Failure/cancellation removes owned partial/mask files and leaves originals/existing destinations untouched. Source deletion is not implemented.

The video encoder is lossy. Runtime structural/timeline checks are not proof of semantic coverage. Separate synthetic tests inspect decoded moving coverage and boundary frames. The source renderer and opaque margin are conservative; eccentric ovals may be over-covered. Effect baseline-profile equivalence, annotation/crop layering and the full output/input matrix remain release gates.

## Shared effects

Default/Aggressive Blur and Pixelate now use a shared CPU compositor for exact paused preview, PNG export and effect-video export. Live playback applies the same renderer at proxy resolution. Effect-video export uses two sequential PNG pipes and a minimal timestamped Matroska transport, keeping decoded source imagery in memory. It carries source-map timestamps and durations directly because the approved media tool omits setpts/settb. Policy, source/review gates and complete output validation are retained. See EFFECTS.md for algorithms, transport details and remaining profile/performance limits.

The interface follows a classic capture-tool layout (menu bar, icon toolbar, options bar, workspace), with TRT's own artwork, without changing the inherited feature scope.

## Separation and remaining work

`Core` holds project/region/keyframe/timeline/policy/history, coordinate migration and the appearance matcher. `Desktop` holds WPF interaction/preview, private playback, approved media tools/thumbnails, tracking analysis and independent image/video export services. UI coordination still lives largely in MainWindow; a view-model/command split should accompany remaining workflows rather than adding a framework solely for this milestone.

Next required work remains final baseline-effect acceptance, annotations/crop, draft/vertex editing, user rotation, capture/tray/single-instance/clipboard, optional deletion with inherited safeguards, session-warning UX, resource extraction/leases/crash cleanup, packaging/licensing assembly and the complete acceptance register. The published application is retained throughout; no publication or release replacement is authorised.

## Primary references

- https://github.com/mccabedd/tinyredactiontool
- https://github.com/videolan/libvlcsharp
- https://videolan.videolan.me/vlc/master/index.html
- https://www.nuget.org/packages/LibVLCSharp/3.10.2
- https://www.nuget.org/packages/VideoLAN.LibVLC.Windows/3.0.24
- https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/10.0/releases.json
- https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core
- https://docs.opencv.org/4.2.0/de/da9/tutorial_template_matching.html (correlation mathematics only; OpenCV is not a dependency)


## Development 0.3.1 interaction update

Visible top effect buttons set drawing defaults and update selected regions; all three shape constructors use those defaults. Managed policy is also enforced at new-region creation. The horizontal tool strips replace the side rail; the right panel promotes tracking and collapses numerical details. Hover popups use cursor-relative custom placement and the actual slider track for time mapping, with request generations suppressing stale async results. Launcher and assembly/title versions identify this build as 0.3.1.

## Development 0.3.2 positioning correction

The 0.3.1 custom Popup path double-counted its horizontal offset. It has been replaced by an in-editor Canvas/Border overlay with one TranslatePoint conversion, above-track positioning and editor-edge clamping. Regression checks now measure actual visual bounds and screen coordinates rather than only the callback calculation. Tracking preflight distinguishes same-frame ranges, already-at-target direction errors and playheads outside the range, with actionable messages.

## Development 0.4.0 natural following

Drawing already establishes the start and default video end. Core RedactionWorkflow now selects the initial/manual-correction follow seed and clips a stopped region while preserving interpolation and required review. Follow subject prepares analysis and its exact seed image before an atomic undoable commit, then returns the paused playhead there. Stop redaction here pauses live playback for exact inspection, clips future keys/review ranges, and retains replaceable computed boundaries. Directional tracking and manual range controls are advanced. Existing project schema and all export/review gates remain.

Build output is versioned under artifacts/<version> because the previous app was open and locked its files. Build-Dev promotes a relative current-build.txt selector after success; Run-Dev validates that it stays inside the development folder. Running earlier versions are not interrupted.
