# Effect behaviour — development 0.3.1

The visible REDACT toolbar offers Coloured box, Blur and Pixelate before drawing. Choose an effect, choose a shape, then drag. The same buttons immediately change a selected region. Default/Aggressive and strength are next to the tools and become the defaults for new regions. Numeric details, colour, coverage margin and keyframes are under the expandable Region details and keyframes section. These numeric edits still use Apply details. Projects persist all effect fields. Coloured box remains the startup default.

## Shared rendering

`EffectRenderer` is the single CPU compositor used by exact paused inspection,
PNG export and effect-video export. It processes regions in project order.
Later effects operate on the already composed image, so they cannot recover
source pixels hidden by an earlier opaque region. Outlines remain editing-only.
All shape masks are binary; protected effect pixels are alpha 255. Transparent
input patches are composited over black before sampling, avoiding resurrection
of hidden RGB. Pixels outside the expanded region remain unchanged in PNGs.

Default Blur uses three separable box passes with clamped crop edges. Strength
1-10 retains the inherited radius targets 10/12/16/20/26/33/42/54/68/86.
Default Pixelate shrinks a region patch then reconstructs nearest-neighbour;
its inherited divisors are 6/9/12/15/18/24/30/38/48/60.

Aggressive follows the inherited structural-proxy design: five cells along the
long axis, at least two along the short axis, a 4x sampling lattice, overlapping
8x8 reflected pooling, eight luma levels, and seven neutral-centred chroma
symbols. Subsequent cosmetic Blur/Pixelate reconstruction reads only the tiny
quantised proxy. Aggressive is fixed at the inherited strength-5 cosmetic
density; its strength slider is disabled. This implementation uses C# bilinear
resampling rather than the old GDI+ bicubic lattice. Exact baseline appearance
and information-reduction equivalence have NOT been accepted. The full parity
register remains open; these development capabilities are not a privacy proof.

An effect uses the bounding crop of the expanded geometry, followed by its
rectangle/oval/polygon mask. Coverage includes the existing outward margin.
Live playback applies the renderer to its at-most-1280-pixel proxy; it therefore
approximates full-resolution appearance. Inspect exact paused frames for edits.
CPU effects can reduce playback throughput, particularly with many regions.

## Video transport

Opaque-only video keeps the efficient original geometry-mask pipeline. Video
with any Blur/Pixelate region decodes sequential full-resolution PNGs through
one approved FFmpeg process, composes each frame in memory, and feeds PNGs to
a second approved FFmpeg encoder through a minimal forward-only Matroska pipe.
There are no new dependencies or changes to the approved tool hashes.

The transport has one V_MS/VFW/FOURCC MPNG track, no lacing, one independent
PNG keyframe per cluster, a microsecond TimestampScale and explicit block
durations. It carries the validated source frame map's normalised timestamps;
collapsed microsecond timestamps fail closed. Encoded input PNG frames are
bounded by the source dimensions and a 256 MiB ceiling. No decoded source
images, intermediate redacted video or source-derived thumbnails go to disk.
Effect export is CPU-heavy and slower than opaque-only export; high-resolution
performance and broad container compatibility still need acceptance.

Both paths use the same policy/fingerprint/review gates, source read lock,
optional primary audio mapping, metadata removal, owned partial transaction,
stream/dimension/duration/frame-count/timestamp/full-decode validation, and
cancellation cleanup. Lossy video encoding can change colours and edges;
runtime structural validation cannot prove semantic coverage.

## Warnings and remaining acceptance

Blur and Pixelate obscure appearance and do not guarantee removal of readable
or recoverable information. A session warning appears when first choosing or
exporting these effects. Managed policy can prohibit them while keeping
Coloured box available. The full inherited warning-dialog/suppression UX still
needs final parity review. Use opaque replacement when information must be
removed. Tracking review remains mandatory and independent of effect choice.

Primary transport references:
- https://www.matroska.org/technical/elements.html
- https://www.matroska.org/technical/codec_specs.html
- https://raw.githubusercontent.com/FFmpeg/FFmpeg/master/libavformat/riff.c
