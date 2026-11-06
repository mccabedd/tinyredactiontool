# TinyRedactionTool v2.5.1 source/build handoff

Run `BUILD-v2.5.1.cmd` on Windows with Windows PowerShell 5.1. No administrator rights or downloads are required when the complete existing `packaging/` inputs are present. The result is `output\TinyRedactionTool.exe`. The builder pins the v2.5.1 source, supplied icon, original/adapted compiler, compressed payloads and both decompressed approved media-binary hashes, and parses the source before compilation.

The current v2.5.1 application source SHA-256 is `0AFF19CF403D84A5F45242D3F72125D4E5ADF2F2E9E55E3451E43FDED1D16F8D`. The EXE file version is `2.5.1.0`.

## Relationship to v2.5.0

v2.5.1 is a focused maintenance release promoted from the user-tested `v2.5.0-r8` candidate. `V2.5.0-TO-V2.5.1.patch` is the complete source diff against the published v2.5.0 source (`EA3AB99E84C36196469238A531885553A51B59EF08EE9BA9E0249391FA085770`).

The maintenance changes cover outline-only Rectangle/Oval/Freeform drawing annotations; screenshot copy/export eligibility and button state; exact annotation geometry; dark-theme floating-editor styling; Dark Mode startup; maximized/one-shot foreground startup; and removal of focus-on-mouse-enter activation.

The current v2.5.1 source additionally themes the floating Text Bold/Italic/alignment mirror buttons in Dark Mode and makes still-image region capture save from the desktop snapshot taken before the selector appears. This preserves transient UI such as dropdowns, menus and tooltips that may close when the selector receives focus. Video capture remains live and unchanged.

The approved embedded FFmpeg/FFprobe binaries, decompressed media-tool identities, resource-only PS2EXE adaptation and runtime ownership model are unchanged. Historical v2.5.0 evidence therefore remains useful provenance for those unchanged components, but it must not be misrepresented as a complete automated validation record for the new v2.5.1 application source.

## Approved decompressed media-tool hashes

- FFmpeg: `643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC`
- FFprobe: `84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2`

Compressed payload hashes remain:

- `ffmpeg.exe.gz`: `E1A56476BC46685869D2C7B0B9AA101816D89A2907826DC2BA2B418D644268AC`
- `ffprobe.exe.gz`: `A4657F326AD8AFB9999CB83C87D33D895F25729ECDF4207CBDC23AAECBDA82E7`

## Compiler

PS2EXE 1.0.18 and `vendor/ps2exe-resource-only.ps1` are unchanged from v2.5.0. The adapted compiler suppresses automatic pre-script file extraction while retaining named resource embedding. `COMPILER-RESOURCE-ONLY.patch` remains the review artifact for that one-assignment adaptation.

## Release identity

The application version remains `2.5.1.0`. The current source SHA-256 is pinned by both repository builders. Current executable and archive identities are published in `SHA256SUMS-v2.5.1.txt` with the release assets. Rebuilding or signing can change the final EXE hash and requires the checksum manifest to be refreshed.


## Frozen v2.5.1 identity

The user-approved final application source is frozen at SHA-256:

`CA2CC6EBD3BDB48737B249A96F8953D2007DCB38780606AC2EEE74E5F40A2C3C`

No application-code changes are permitted under this release identity. Any later behavioural change should be treated as a new development baseline. Current executable/archive hashes are maintained in `SHA256SUMS-v2.5.1.txt`.
