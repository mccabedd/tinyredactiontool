# TinyRedactionTool

TinyRedactionTool is a lightweight Windows application for quickly redacting sensitive areas in videos and images.

It supports rectangular, oval and freeform selections, with three redaction styles:

- **Black Box**
- **Blur**
- **Pixelate**

Video redactions can be applied across a selected frame range, while images are handled as single-frame stills.

The application is written in PowerShell using Windows Forms and uses a custom stripped-down static build of FFmpeg for media decoding, processing and export.

## Features

- Redact videos and still images
- Rectangle, oval and freeform selection tools
- Black box, blur and pixelate redaction modes
- Adjustable blur and pixelation strength
- Frame-by-frame video navigation
- Play / pause preview
- Set redaction start and end frames
- Multiple redactions per file
- Optional audio preservation when exporting video
- Multiple output quality levels
- Dark-mode Windows Forms interface
- Single-file standalone Windows executable
- No separate FFmpeg installation required

## Supported Input Formats

TinyRedactionTool uses FFmpeg for media decoding. The application currently exposes the following formats in its file picker.

### Video

- MP4
- MOV
- M4V
- AVI
- MKV
- WebM
- WMV
- ASF
- MPG / MPEG / MPE
- VOB
- TS / MTS / M2TS / M2T
- FLV
- 3GP / 3G2
- F4V
- OGV
- RM / RMVB
- MXF
- WTV
- DV
- MJPEG / MJPG
- MLV
- R3D

### Images

- JPG / JPEG / JPE
- PNG / APNG
- GIF
- WebP
- BMP
- TIFF / TIF
- TGA
- DDS
- EXR
- HDR
- DPX
- JPEG 2000: JP2 / J2K / J2C / JPC
- JPEG-LS: JLS
- PSD
- PCX
- QOI
- AVIF
- HEIC / HEIF

> Animated image formats such as GIF and APNG are treated as still images for redaction.

## Output Formats

### Video

| Format | Video | Audio |
| --- | --- | --- |
| MP4 | H.264 | AAC |
| MOV | H.264 | AAC |
| M4V | H.264 | AAC |
| AVI | H.264 | AAC |
| MKV | H.264 | AAC |
| WebM | VP9 | Opus |

### Images

- PNG
- JPG
- GIF
- WebP

## Standalone EXE

TinyRedactionTool can be compiled into a single:

```text
TinyRedactionTool.exe
```

The executable contains a custom static FFmpeg build internally.

At runtime, the FFmpeg payload is extracted to a temporary folder, used by the application, and cleaned up when TinyRedactionTool closes.

No separate FFmpeg installation or PATH configuration is required.

## Custom FFmpeg Build

The included build process creates a stripped-down static FFmpeg specifically for TinyRedactionTool.

The build retains broad input decoding support while removing unnecessary output codecs, filters, devices, networking features and command-line tools.

Only the encoders, muxers and filters required by TinyRedactionTool are retained.

This significantly reduces the size of the FFmpeg binary compared with a general-purpose static FFmpeg build.

## Building TinyRedactionTool

The project includes build scripts for creating the custom FFmpeg binary and packaging the final application.

Run:

```text
BUILD-TinyRedactionTool-CUSTOM.cmd
```

The first build compiles the custom FFmpeg binary and then packages TinyRedactionTool.

The final result is:

```text
TinyRedactionTool.exe
```

For future application-only changes, the previously compiled custom FFmpeg binary can be reused instead of rebuilding FFmpeg from source.

## Requirements

### Running the compiled application

- Windows 10 or Windows 11
- 64-bit Windows

No PowerShell configuration or FFmpeg installation is required for the standalone EXE.

### Running the PowerShell source directly

- Windows PowerShell 5.1
- `ffmpeg.exe` available either:
  - beside the PowerShell script, or
  - in the system PATH

### Building

The supplied build process handles the required FFmpeg/MSYS2 build environment and uses PS2EXE to create the final Windows executable.

## Notes

TinyRedactionTool is intended as a quick local redaction utility rather than a full video editor.

Redactions are permanently rendered into exported files. Always keep the original source file if you may need an unredacted copy later.

## Third-Party Components

TinyRedactionTool uses FFmpeg and selected third-party libraries including x264, libvpx, Opus and WebP.

These components retain their own respective licenses and copyright notices.