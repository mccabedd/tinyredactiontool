# Verification: 3.2.2, 20 November 2026

Status: **targeted checks passed: `--release-322-only` 23, `--release-027-only` 28, `--release-300-only` 21, `--release-320-only` 42, `--release-021-only` 58, `--still-only` 1086 (the 3.2.0 and earlier groups plus the new 3.2.2 checks); none failed.** Build: 0 errors, 0 warnings. The full suite was not run for this change. 3.2.1's evidence is in test-history/TEST-RESULTS-3.2.1.md.

## What changed
- File › Save (Ctrl+S, MainWindow.SaveAsync): the redacted picture or video replaces the opened file. It is written beside the file and checked exactly as an export is, then TRT lets go of its own hold on the file (read lock, player, background frame reading) and moves the checked file over the old one in one step (ExportReplace.Finish; a refused move is tried again for up to two seconds). The first Save of each file asks once. The saved file is opened again, so the redactions become part of it and Undo starts again. If the swap fails, the old file is left as it was and opened again with the work unchanged. Captures and New Image (no file yet) go to Export; formats TRT can't write go to Export with a message.
- Export (MainWindow.ExportToAsync): after Windows' "replace?" question is answered Yes, an existing file is replaced the same way (ExportReplace.Existing). The file open in TRT is refused (use Save). The exporters still refuse an existing file when no replacing was asked for.
- The window title names the open file (MainWindow.UpdateTitle): "TinyRedactionTool 3.2.2 - 01.png"; nothing is added for captures and New Image.

## How it was checked
- Release322Checks (`--release-322-only`), in a throw-away folder: the title names 01.png; Save asks once with the agreed wording, writes the redaction into 01.png, reopens it with the redaction part of the picture and holds it again, leaves no extra files; a second Save doesn't ask; a read-only file can't be replaced, so Save reports it and the file, the redaction and the hold stay as they were; answering No leaves 02.png unchanged; Export refuses an existing file unless replacing was confirmed, replaces a confirmed one, and never replaces the open file; Save on an MP4 replaces it with the redacted video (same 7 frames) and reopens it; a New Image has no file name in the title.
- Release027Checks: the File menu reads New Image, Open Media, Save (Ctrl+S), Export, Save Media As, Add Image, Open Project, Save Project, File Info.
- The existing export checks (an existing destination is refused by the exporter by default) still pass.

## Not checked
- The rest of the full suite.

## Package
- standalone/3.2.2/TinyRedactionTool-3.2.2.exe (product version 3.2.2); its SHA-256 is in the release's SHA256SUMS file.
