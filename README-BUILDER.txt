TinyRedactionTool v2.5.1 — offline EXE packaging builder

Run BUILD-TinyRedactionTool-CUSTOM.cmd on Windows with Windows PowerShell 5.1.
The root wrapper checks the frozen v2.5.1 root source and supplied icon, then invokes
packaging/BUILD-v2.5.1.ps1. Keep the rest of the existing packaging directory intact.

Output: packaging/output/TinyRedactionTool.exe

The v2.5.1 builder parses the source and verifies pinned source/icon/compiler, compressed
payload hashes and the decompressed approved FFmpeg/FFprobe hashes before compilation.
No network access or administrator rights are required when the complete v2.5.0 packaging
inputs are already present.

The approved FFmpeg/FFprobe resources and PS2EXE inputs are unchanged from v2.5.0.
This is an EXE packaging rebuild from approved media binaries; it does not recreate the
complete original FFmpeg/MSYS2 source build or its toolchain.

Source SHA-256: 2BDA3D0E6ED8F6E12004B549B16E54998CC3A04AACFC7A8B8AD8D0221AA2F7A4

A final EXE hash must be recorded after the Windows build and acceptance check. Do not
reuse the v2.5.0 EXE hash. PS2EXE output may contain varying compiler metadata, and
company signing changes the final EXE hash again.

Historical v2.5.0 evidence remains provenance for the unchanged packaging/media-tool
architecture. v2.5.1 application changes are documented in packaging/V2.5.0-TO-V2.5.1.patch,
RELEASE-NOTES-v2.5.1.md and SECURITY-v2.5.1.md.
