TinyRedactionTool Secure Custom Builder v2.0.0
================================================

RELEASE SOURCE
--------------
This builder packages the frozen TinyRedactionTool v2.0.0 RC3 PowerShell source.
The builder verifies the source before packaging and refuses any source whose
SHA-256 is not:

11698B006A1FF8759D7FF222246475FE9B0A091C5A4F61023AC4649ACBF2B4FB

The main window title remains "TinyRedactionTool". The About dialog reports
"TinyRedactionTool v2.0.0".


FINAL VERIFIED RELEASE BUILD
----------------------------
The final Windows standalone EXE built from this release source passed the
packaged-runtime smoke checks on 2026-09-16.

TinyRedactionTool.exe SHA-256:
F2C76CA945209101BADA2D995056BE3B8B3CC3763FAFED08E3A29E394F397A4F

This hash identifies the tested release executable. A later rebuild may differ
if the non-fully-reproducible compiler environment changes.

MEDIA TOOLS
-----------
Zoom/pan is a viewport-only feature and does not require a different FFmpeg or
FFprobe build. This production builder therefore requires the exact approved
media binaries already used by the production baseline:

FFmpeg  SHA-256: 28612C0A94D50A29AABD0555C91E086D1CCDF13260757B83B4BBD53A0C2CDCE0
FFprobe SHA-256: BB8CBA76F9D4F05DD608F319477A0604D8A8C289FB6A885B03919F07C4DC9855

The existing capability, network-disable, exact-frame, VFR and timestamp
round-trip smoke tests still run before packaging. Even if a clean rebuild
produces binaries that pass those tests, the v2.0.0 release builder will refuse
them unless the hashes above also match.

IMPORTANT WHEN UPDATING AN EXISTING BUILD FOLDER
------------------------------------------------
Keep the existing ffmpeg-custom.exe, ffprobe-custom.exe and _CustomFFmpegBuild
folder. Stage and verify this builder package first, then copy its files over the
existing builder files. Do not delete the cached media tools merely because the
application source changed.

BUILD
-----
1. Close TinyRedactionTool.exe if it is running.
2. Double-click BUILD-TinyRedactionTool-CUSTOM.cmd.
3. The builder validates the exact source and media-tool hashes, runs the media
   smoke tests, injects the hashes into the packaged source, embeds both GZip
   payloads and creates one TinyRedactionTool.exe.
4. The output file version is 2.0.0.0.
5. Record the final EXE SHA-256 printed by the builder.

PS2EXE remains pinned to 1.0.18. The FFmpeg source/profile and MSYS2 pinning
logic are unchanged from the hardened v1.3.8 builder.

HISTORICAL BUILDER NOTES
------------------------
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
