# TinyRedactionTool v2.5.0 source/build handoff

Run `BUILD-v2.5.0.cmd` on Windows with Windows PowerShell 5.1. No administrator rights or downloads are required. The result is `output\TinyRedactionTool.exe`; the delivered release EXE is not overwritten. The builder pins source, supplied icon, original and adapted compiler, compressed payloads and the hashes of both decompressed approved media binaries. It parses the source before compiling. Inputs are pinned; byte-for-byte reproducible EXE hashes are not promised because compiler outputs may contain varying build metadata.

This bundle repackages the exact accepted media binaries. It does not contain/rebuild the complete historic MSYS2/FFmpeg source toolchain. Preserve `_CustomFFmpegBuild` if you already have it. The upstream README's original FFmpeg build information is retained for reference, but is not a claim that that historical toolchain is included here. A company requesting a complete media-tool rebuild must retain/review the matching source/toolchain separately.

PS2EXE 1.0.18 was fetched from the official PowerShell Gallery package, whose original package SHA-256 is `692124163D0E71262D76E2F2B2588E1661DF28A8F0CF3B1725E47A957AFCE39F`. The original compiler script and its licence are supplied under vendor. See https://github.com/MScholtes/PS2EXE and https://www.powershellgallery.com/packages/ps2exe/1.0.18 .

The adapted `vendor/ps2exe-resource-only.ps1` differs by exactly one AST assignment: the `$EMBEDSECTION` assignment containing `tgtFile = Environment.ExpandEnvironmentVariables` is replaced by `$EMBEDSECTION += ""`. This keeps resource embedding but removes the automatic pre-script filesystem extraction. `COMPILER-RESOURCE-ONLY.patch` makes the adaptation reviewable. The script reads named GZip resources from its own entry assembly after obtaining the instance guard and validating policy, then expands, verifies and locks the approved tools in its own leased runtime folder.

`C9-TO-RELEASE.patch` documents the application changes: icon/header assets, resource names, three resource-bootstrap functions and three runtime ownership helpers. All 301 other C9 functions, the source parameter block and protected top-level event handlers/statements remain byte-identical. Parser/static and runtime reports are supplied in evidence. C9 is the user-accepted behavioural baseline.

Approved decompressed tool hashes:

- FFmpeg: `643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC`
- FFprobe: `84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2`

The packaged source and licence are supplied; PS2EXE packaging does not hide or authenticate the source. The shipped EXE is unsigned. Any company signing changes its final EXE hash and needs a new signed-artifact manifest. The source/build bundle includes original compiler inputs and adaptation, rather than requiring reviewers to trust an opaque new compiler.

Acceptance limits: synthetic fixture tests exercise the compiled resource bootstrap, approved media tools, actual image export validation, crop/redaction output, themed loading/clipboard dialogs and normal Quit. A bitmap sink substitutes only clipboard transfer to preserve the user's clipboard. Runtime tests separately launch the unmodified delivered EXE, test second-launch handoff, force termination/relaunch recovery, and send a session-end message only to that owned process to verify normal shutdown cleanup. No private screen recording is made. Representative long videos, live global capture shortcuts, actual clipboard paste, UNC/mapped shares, deployment ACLs and mandatory-policy decisions remain explicit final acceptance work in the policy guide.

## Final promotion

The user approved v2.5.0 final. Only the top source identity comment changed during promotion; all subsequent source bytes are identical to the tested release candidate. The EXE was rebuilt and its final runtime checks passed. Historical evidence retains its original labels. Use the new final source/EXE/ZIP hashes.
