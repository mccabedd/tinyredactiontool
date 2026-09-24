# Changelog

All notable changes to TinyRedactionTool are documented in this file.

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
