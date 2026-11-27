# Verification: 3.5.1, 27 November 2026

Status: **`--release-340-only` 30 passed (3 new). Full suite: 1602 passed, none failed.** Build: 0 errors, 0 warnings. 3.5.0's evidence is in test-history/TEST-RESULTS-3.5.0.md.

## What changed
- Check for Updates installs the update and restarts by itself. 3.4.0 and 3.5.0 decided whether TRT could replace itself from where its code was loaded from; the packaged .exe unpacks its code into a temporary folder, so it always looked like a development build and only downloaded the update into `%TEMP%\TinyRedactionTool-Update`. Now the program file decides (Updater.IsSingleFileProgram): a TinyRedactionTool .exe with no TinyRedactionTool.dll beside it.
- The first start after an update deletes the previous version (`.old`) and the download (`.download`, `.download.partial`), tried for about ten seconds while the old program ends (UpdateSwap.CleanUp), as notepad.md does.
- The update question says TRT "reopens as the new version"; Help › Updates describes the swap and the clean-up.

## How it was checked
- Release340Checks: this build's TinyRedactionTool.exe on its own in a folder can replace itself, also renamed; the development build (its .dll beside it), dotnet.exe and no path can't; the clean-up deletes .old, .download and .download.partial and leaves the program.
- By hand, `--single-file-probe` on real program files: the packaged standalone/3.5.1/TinyRedactionTool-3.5.1.exe → True; an installed 3.4.0 standalone .exe → True; the development build's TinyRedactionTool.exe → False.

## Not checked
- A real install and restart from GitHub: it needs a release newer than the running TRT. 3.4.0 and 3.5.0 still have the old test, so the update to 3.5.1 is put in place by hand; 3.5.1 updating to the next release is the first fully automatic one.

## Package
- standalone/3.5.1/TinyRedactionTool-3.5.1.exe (product version 3.5.1), SHA-256 32E453AD2FCDDA75154A1234465DFB9290277FFA8EDB4C0E3E91775010419D32.
