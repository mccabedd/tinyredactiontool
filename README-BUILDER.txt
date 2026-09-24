TinyRedactionTool Secure Builder — v2.2.0 FINAL
==================================================

RC1 has been accepted by user testing.

The final source differs from RC1 only in release identity:
    TinyRedactionTool v2.2.0 RC1
becomes:
    TinyRedactionTool v2.2.0

RC1 source SHA-256:
FEA81D64DADD5DF6B7CBD389ADE0E373D9CD58C2B300726E9919364A11AD76E4

Final frozen source SHA-256:
E8845C6791E340F1D8002997B0E50622317500C7ACACF3B981AD61B8F9CFE7D0

Approved media tools:
FFmpeg : 643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC
FFprobe: 84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2

RECOMMENDED BUILD PATH
----------------------
Extract this final builder directly into the same folder containing the already
approved D1 media tools as:

    ffmpeg.exe
    ffprobe.exe

The builder will verify their exact hashes and adopt them automatically as
ffmpeg-custom.exe / ffprobe-custom.exe.

Then run:
    VERIFY-STAGED-FINAL.cmd
    BUILD-TinyRedactionTool-CUSTOM.cmd

The expected output is:
    TinyRedactionTool.exe

After building:
1. Record the printed SHA-256.
2. Independently verify it with Get-FileHash.
3. Run FINAL-RELEASE-SMOKE-CHECKLIST.md.
4. Send the final EXE SHA-256 back so the immutable final release-record pack
   can be generated.

Do not publish a different build under the same v2.2.0 version identity.
