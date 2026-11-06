TinyRedactionTool v2.5.1 — offline EXE packaging builder

Run Build-TinyRedactionTool-Custom.ps1 using Windows PowerShell 5.1.

The root builder verifies the frozen application source and supplied icon,
then invokes packaging/BUILD-v2.5.1.ps1.

Expected output:
    packaging\output\TinyRedactionTool.exe

The standalone TinyRedactionTool-v2.5.1-SOURCE-BUILD.zip includes all inputs
required by this packaging route. No downloads or administrator rights are
required.

Frozen application source SHA-256:
CA2CC6EBD3BDB48737B249A96F8953D2007DCB38780606AC2EEE74E5F40A2C3C

The builder also validates the pinned icon/compiler inputs, compressed media
resources and approved decompressed FFmpeg/FFprobe hashes before compilation.

The bundle repackages the approved media binaries; it is not a complete
historical FFmpeg/MSYS2 source-toolchain archive.

Current executable/archive hashes are published in SHA256SUMS-v2.5.1.txt.
A rebuild can produce a different EXE hash because compiler metadata may vary.
Signing also changes the final executable hash.
