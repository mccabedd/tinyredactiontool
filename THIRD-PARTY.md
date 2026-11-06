# Third-party components

TinyRedactionTool 3.0 by David McCabe (mccabedd), https://github.com/mccabedd/tinyredactiontool, is licensed under GPL-2.0-or-later (see LICENSE). It is a C# rewrite of TinyRedactionTool v2.5.1, whose source is kept in `history/v2.5.1`. The TRT icon comes from v2.5.1. Notices inherited from v2.5.1 are in docs/BASELINE-THIRD-PARTY.md.

The released `TinyRedactionTool-3.0.0.exe` contains the components below. The source repository does not contain their binaries; `Bootstrap-Dev.ps1` fetches the exact pinned versions and checks their hashes.

## Microsoft .NET (not included)

TRT 3.0 needs the **.NET 10 Desktop Runtime** (Windows x64), which the user installs from Microsoft. It is not bundled. Builds use the .NET SDK 10.0.403, pinned with its SHA-512 in dependencies/dotnet-sdk-pin.json.

## VideoLAN: LibVLCSharp and libVLC (video preview playback)

| Component | Version | Licence | SHA-256 of the package |
|---|---|---|---|
| LibVLCSharp | 3.10.2 | LGPL-2.1-or-later | A7473E6D7C3595C74D3FB42BB0791053224D07B797ADCEE8C16F00E6F99BB8F9 |
| VideoLAN.LibVLC.Windows (libVLC 3.0.24) | 3.0.24 | LGPL-2.1-or-later (core); some plugins GPL-2.0-or-later | 3DA3F37EE2B2B10E5C788D830A3B513658C36521EA1B0F966ED86EB69F41EF3C |

- Packages: https://www.nuget.org/packages/LibVLCSharp/3.10.2 and https://www.nuget.org/packages/VideoLAN.LibVLC.Windows/3.0.24
- Source: https://code.videolan.org/videolan/LibVLCSharp (commit 3082c09ca955131c705fc4767fde03e9c4a14999) and https://code.videolan.org/videolan/vlc (tag 3.0.24); release source archives at https://download.videolan.org/pub/videolan/vlc/3.0.24/
- TRT ships a subset of 224 libVLC files (listed with hashes in dependencies/native-manifest.json; the 99 left out are in dependencies/excluded-native-modules.txt). TRT checks every file's hash before loading it. The files are unmodified.

## FFmpeg and FFprobe (inspection, frames and export)

| Binary | SHA-256 |
|---|---|
| ffmpeg.exe | 643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC |
| ffprobe.exe | 84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2 |

These are the same custom FFmpeg/FFprobe builds as TinyRedactionTool v2.5.1 (unchanged, same hashes). The build includes GPL-enabled components, so the binaries are distributed under the GPL. Their build configuration and notices are in `history/v2.5.1` (the v2.5.1 packaging and docs/BASELINE-THIRD-PARTY.md). TRT uses only these exact files: it checks their hashes and never falls back to another FFmpeg.

## Tracking

The appearance matcher is TRT's own implementation of standard zero-mean normalised correlation with a local scale and position search. It does not link or ship OpenCV or any model.

## Building from source

1. Run `Bootstrap-Dev.ps1`. It downloads only the pinned .NET SDK and packages, checks their hashes and stages the libVLC files.
2. Put the two approved FFmpeg binaries (the hashes above) in `tools/`.
3. Run `Build-Dev.ps1` to build offline and run the checks, then `Package-Standalone.ps1` for the single .exe.
