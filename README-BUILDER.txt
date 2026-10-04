TinyRedactionTool v2.5.0 — offline EXE packaging builder

Run BUILD-TinyRedactionTool-CUSTOM.cmd on Windows with Windows PowerShell 5.1.
The root wrapper checks the frozen root source and supplied icon, then invokes
packaging/BUILD-v2.5.0.ps1. Upload the entire packaging directory unchanged.

Output: packaging/output/TinyRedactionTool.exe

Alternatively, extract TinyRedactionTool-v2.5.0-SOURCE-BUILD.zip and run
BUILD-v2.5.0.cmd there. Its output is output/TinyRedactionTool.exe.

Neither route requires network access or administrator rights. The builder
parses the source and verifies pinned source/icon/compiler, compressed payload
hashes and the decompressed approved FFmpeg/FFprobe hashes before compilation.
See packaging/BUILD-AND-AUDIT.md for the resource-only compiler adaptation.

This is an EXE packaging rebuild from approved media binaries. It does not
recreate the complete original FFmpeg/MSYS2 source build or its toolchain.
The previous root build scripts are preserved under history/v2.2.0. Keep
any existing _CustomFFmpegBuild cache. Do not use the old source-hash pins
to compile the new root application source.

The delivered final EXE's hash is in SHA256SUMS-v2.5.0.txt. Rebuilding can
produce a different EXE hash because compiler metadata can vary. Record
the new hash and run acceptance checks; do not reuse the delivered hash.
Company signing also changes the final EXE hash.

The provided evidence is the actual final validation record. Evidence scripts
retain workspace-relative fixture paths; they are not a portable one-click
test suite. Reproduce/adapt those fixture paths deliberately when reviewing.
