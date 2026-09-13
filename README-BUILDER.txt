TinyRedactionTool Secure Custom Builder v1.3.8
================================================

IMPORTANT
---------
This builder is for the hardened TinyRedactionTool source that requires BOTH
FFmpeg and FFprobe. Do not use the older v1.2.1 builder with the hardened app:
v1.2.1 explicitly disabled FFprobe and embedded only FFmpeg.

SECURITY-SENSITIVE BUILD BEHAVIOUR
----------------------------------
- Builds a private static ffmpeg.exe AND ffprobe.exe from one pinned FFmpeg
  source revision.
- FFmpeg networking is disabled at configure time.
- FFplay, capture devices and hardware acceleration are disabled.
- FFmpeg output encoders/muxers/filters are restricted to TinyRedactionTool's
  requirements; broad native input decoding/demuxing remains for compatibility.
- The exact SHA-256 of both produced binaries is injected into the application
  source before PS2EXE packaging.
- Both binaries are GZip-compressed and embedded inside one TinyRedactionTool.exe.
- At runtime they are expanded into a unique per-run TEMP directory, hash-checked
  before use, and cleaned up when the GUI closes.
- TinyRedactionTool never searches PATH for FFmpeg or FFprobe.

PINNED FFMPEG SOURCE
--------------------
FFmpeg commit: fd7c73d01e976d2e332e85862ab63ab608710834
This is the source revision corresponding to the 2026-09-10 Gyan git-master
Windows build. Pinning the revision prevents a later rebuild from silently
using different upstream source.

BUILD
-----
Double-click BUILD-TinyRedactionTool-CUSTOM.cmd and follow the console output.
Do not distribute the result until the runtime security test plan has passed.


SUPPLY-CHAIN PINNING IN v1.3.8
--------------------------------
- MSYS2 base archive is downloaded by fixed GitHub release-asset ID 560868716.
- Expected size: 42915960 bytes.
- Expected SHA-256: F6BBDE384F3331FB293C5051D5B9DBEC01C772BCCDCEEE83B78213801264D0BD
- The archive is rejected and deleted if either check fails.
- PS2EXE is pinned to version 1.0.18 and that exact version is imported.

NOTE: MSYS2 packages installed by pacman are still obtained from the signed rolling MSYS2 repositories at build time. This builder therefore improves supply-chain pinning, but it does not claim bit-for-bit reproducibility of the complete compiler/library toolchain.


v1.3.3 BUILDER FIX
------------------
- Corrected the exact hash-slot uniqueness check used before injecting the
  compiled FFmpeg and FFprobe SHA-256 values. The prior v1.3.2 check used
  String.Split and could falsely report that a unique empty slot was absent.
- This change does not alter the hardened application source or custom
  FFmpeg/FFprobe build configuration.
- Existing validated ffmpeg-custom.exe and ffprobe-custom.exe are reused.


v1.3.4 PACKAGING FIX
--------------------
- Removed PS2EXE -longPaths because PS2EXE implements that option by
  generating a TinyRedactionTool.exe.config sidecar.
- The release target is a genuinely single standalone EXE. The builder
  deletes any stale .config before packaging and fails closed if a new
  sidecar appears.
- Long-path support beyond normal Windows path limits is therefore not
  claimed for the standalone release.
- Existing validated ffmpeg-custom.exe and ffprobe-custom.exe are reused.


v1.3.5 IMAGE2PIPE FIX
---------------------
- Enables FFmpeg's image2pipe muxer, which TinyRedactionTool requires to
  decode preview frames directly through stdout without writing decoded
  patient/source frames to disk.
- Adds image2pipe and local pipe-protocol checks to the Windows-side media
  tool validation gate.
- Adds a build-profile marker so a pinned source checkout is reconfigured
  whenever TinyRedactionTool's required FFmpeg feature set changes.
- Existing v1.3.4 custom media tools are automatically detected as stale
  and rebuilt; the existing MSYS2/toolchain cache is retained.


v1.3.6 NULL-MUXER FIX
---------------------
- Enables FFmpeg's null muxer, required by TinyRedactionTool's VFR/timing
  and decode-safety checks. These checks intentionally decode/process media
  while discarding output rather than writing decoded patient/source frames.
- The Windows-side FFmpeg validation gate now requires both image2pipe and
  null, plus the local pipe protocol, before packaging is allowed.
- Existing v1.3.5 media tools are automatically detected as stale and rebuilt.
- Audited all hardened-script FFmpeg output paths: image2pipe and null are the
  only special non-file muxers; normal exports use the already-enabled
  MOV/MP4/IPOD, AVI, Matroska/WebM, image2, GIF and WebP muxers.


v1.3.7 EXPLICIT-CODEC + WRAPPED_AVFRAME FIX
-------------------------------------------
- Enables FFmpeg's wrapped_avframe encoder, which is the null muxer's native
  video codec and is required when all non-allowlisted encoders are disabled.
- TinyRedactionTool now explicitly requests wrapped_avframe for both null-muxer
  safety paths instead of relying on FFmpeg's automatic encoder selection.
- PNG, JPG, GIF and WebP exports now also name their encoders explicitly.
  Together with the already-explicit video codecs, every TinyRedactionTool
  output path now avoids automatic encoder selection.
- The Windows-side validation gate requires wrapped_avframe and performs real
  runtime smoke tests for null+wrapped_avframe and image2pipe+PNG before the
  application can be packaged.
- Existing v1.3.6 media tools are detected as stale and rebuilt automatically.


v1.3.8 NATIVE VFR + EXACT PREVIEW FRAME IDENTITY
--------------------------------------------------
- Replaces the old vfrdet rejection gate with a validated per-frame timing map
  from trusted FFprobe plus an independent full FFmpeg decoded-frame-count
  reconciliation pass. VFR is accepted only when both agree exactly.
- Adds FFmpeg's select filter for exact memory-only preview extraction. Preview
  uses -copyts and selects the mapped best-effort PTS exactly; a missing target
  frame fails closed instead of returning a neighbouring frame.
- Removes the no-longer-needed vfrdet filter from the stripped FFmpeg profile.
- Adds a functional seek+PTS preview smoke test that compares the selected frame
  byte-for-byte with an exact from-start logical-frame baseline.
- Retains exact logical-frame export activation and timestamp-preserving MP4/VP9
  export validation introduced during the staged VFR work.
- Existing v1.3.7 media tools are detected as stale because they lack select and
  are rebuilt using the existing MSYS2/toolchain/source cache.
