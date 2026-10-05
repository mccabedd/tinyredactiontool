# TinyRedactionTool v2.5.1 source/build handoff

Run `BUILD-v2.5.1.cmd` on Windows with Windows PowerShell 5.1. No administrator rights or downloads are required when the complete existing `packaging/` inputs are present. The result is `output\TinyRedactionTool.exe`. The builder pins the v2.5.1 source, supplied icon, original/adapted compiler, compressed payloads and both decompressed approved media-binary hashes, and parses the source before compilation.

The v2.5.1 application source SHA-256 is `2BDA3D0E6ED8F6E12004B549B16E54998CC3A04AACFC7A8B8AD8D0221AA2F7A4`. The EXE file version is `2.5.1.0`.

## Relationship to v2.5.0

v2.5.1 is a focused maintenance release promoted from the user-tested `v2.5.0-r8` candidate. `V2.5.0-TO-V2.5.1.patch` is the complete source diff against the published v2.5.0 source (`EA3AB99E84C36196469238A531885553A51B59EF08EE9BA9E0249391FA085770`).

The maintenance changes cover outline-only Rectangle/Oval/Freeform drawing annotations; screenshot copy/export eligibility and button state; exact annotation geometry; dark-theme floating-editor styling; Dark Mode startup; maximized/one-shot foreground startup; and removal of focus-on-mouse-enter activation.

The approved embedded FFmpeg/FFprobe binaries, decompressed media-tool identities, resource-only PS2EXE adaptation and runtime ownership model are unchanged. Historical v2.5.0 evidence therefore remains useful provenance for those unchanged components, but it must not be misrepresented as a complete automated validation record for the new v2.5.1 application source.

## Approved decompressed media-tool hashes

- FFmpeg: `643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC`
- FFprobe: `84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2`

Compressed payload hashes remain:

- `ffmpeg.exe.gz`: `E1A56476BC46685869D2C7B0B9AA101816D89A2907826DC2BA2B418D644268AC`
- `ffprobe.exe.gz`: `A4657F326AD8AFB9999CB83C87D33D895F25729ECDF4207CBDC23AAECBDA82E7`

## Compiler

PS2EXE 1.0.18 and `vendor/ps2exe-resource-only.ps1` are unchanged from v2.5.0. The adapted compiler suppresses automatic pre-script file extraction while retaining named resource embedding. `COMPILER-RESOURCE-ONLY.patch` remains the review artifact for that one-assignment adaptation.

## Final promotion requirement

Build the EXE on Windows, perform the v2.5.1 manual acceptance checks in `RELEASE-NOTES-v2.5.1.md`, then record the resulting EXE SHA-256 in `VERSION.txt`/release hashes before publishing binary release artifacts. Do not copy the v2.5.0 EXE hash forward. Any company signing step changes the final executable hash.
