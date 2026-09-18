TinyRedactionTool Secure Custom Builder v2.1.0
================================================

RELEASE SOURCE
--------------
This builder packages the frozen TinyRedactionTool v2.1.0 PowerShell source.
The consolidated v2.1.0 RC1 completed the full application regression on
2026-09-18. Release preparation then changed only the About-dialog label from
"TinyRedactionTool v2.1.0 RC1" to "TinyRedactionTool v2.1.0".

The builder verifies the release source before packaging and refuses any source
whose SHA-256 is not:

2BC392FD52587343AB4CEA95B19C295286E44E4D3543634D9D3D1E383567BDC7

The main window title remains "TinyRedactionTool". The About dialog reports
"TinyRedactionTool v2.1.0".

V2.1.0 APPLICATION CHANGES
--------------------------
- Rectangle/Square drafts can be resized before commit with 8 handles.
- Oval/Circle drafts can be resized before commit with 4 cardinal handles.
- Closed Freeform draft vertices can be moved individually before commit.
- The first click outside a closed Freeform dismisses it and is consumed.
- Mouse-wheel pointer-centred zoom is always available over the preview.
- Middle-button drag pans without changing the selected drawing tool.
- Existing Space+left-drag pan and the dedicated Zoom tool are retained.

These are draft-editing/viewport changes. The protected CFR/VFR timing, exact
frame identity, export generation/validation, metadata/audio handling and
trusted-media-tool architecture were not redesigned for v2.1.0.

The experimental replacement-first Blur/Pixelate prototype is NOT included in
v2.1.0. Blur and Pixelate retain the conventional visual-obscuration behaviour
and warning from v2.0.0.

MEDIA TOOLS
-----------
The v2.1.0 changes do not require a different FFmpeg or FFprobe build. This
production builder therefore requires the exact approved v2.0.0 media binaries:

FFmpeg  SHA-256: 28612C0A94D50A29AABD0555C91E086D1CCDF13260757B83B4BBD53A0C2CDCE0
FFprobe SHA-256: BB8CBA76F9D4F05DD608F319477A0604D8A8C289FB6A885B03919F07C4DC9855

The existing capability, network-disable, exact-frame, VFR and timestamp
round-trip smoke tests still run before packaging. Even if a clean rebuild
produces binaries that pass those tests, the v2.1.0 release builder refuses
them unless the hashes above also match.

IMPORTANT WHEN UPDATING AN EXISTING BUILD FOLDER
------------------------------------------------
Keep the existing ffmpeg-custom.exe, ffprobe-custom.exe and _CustomFFmpegBuild
folder. Stage and verify this builder package first, then copy its files over the
existing builder files. Do not delete the cached media tools merely because the
application source changed.

If TinyRedactionTool.exe is running, close it before starting the builder or the
existing output EXE may be locked against replacement.

BUILD
-----
1. Close TinyRedactionTool.exe if it is running.
2. Confirm ffmpeg-custom.exe and ffprobe-custom.exe remain beside the builder.
3. Double-click BUILD-TinyRedactionTool-CUSTOM.cmd.
4. The builder validates the exact v2.1.0 source and approved media-tool hashes,
   runs the media smoke tests, injects the hashes into the packaged source,
   embeds both GZip payloads and creates one TinyRedactionTool.exe.
5. The output file version is 2.1.0.0.
6. Record the final EXE SHA-256 printed by the builder.
7. Independently calculate the EXE SHA-256 after the builder exits.
8. Launch the packaged EXE and perform the final image/CFR/VFR/resize/viewport
   smoke test before declaring the packaged v2.1.0 release final.

PS2EXE remains pinned to 1.0.18. The FFmpeg source/profile, MSYS2 pinning and
media-tool smoke-test logic are unchanged from the known-good v2.0.0 builder.

RELEASE DOCUMENTATION STATUS
----------------------------
README.md and SECURITY-AUDIT.md in this builder package deliberately describe
the final v2.1.0 EXE/build identity as PENDING. Do not replace those placeholders
with an EXE or builder-package hash until the Windows build has succeeded, the
packaged EXE has launched, and its hash has been independently verified.

HISTORICAL BUILDER NOTES
------------------------
The hardened builder fixes introduced through v1.3.8 remain present unchanged:
- exact hash-slot uniqueness checks before media-tool hash injection;
- genuinely single-file PS2EXE packaging (no .config sidecar);
- memory-only image2pipe preview capability;
- null + wrapped_avframe functional validation;
- explicit output codecs;
- native VFR timing support;
- exact logical-frame and exact-PTS preview smoke tests; and
- timestamp-preserving MP4/H.264 and WebM/VP9 VFR round-trip smoke tests.
