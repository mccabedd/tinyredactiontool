# Verification: 3.4.0, 24 November 2026

Status: **`--release-340-only` 27 passed (a fake GitHub; no network). The real check and download against GitHub (`--update-probe 3.2.0`) found v3.3.0 and passed every check. Full suite: 1559 passed, none failed (after one run stopped on a known mouse/focus check, and one on the About text check, updated for the new button).** Build: 0 errors, 0 warnings. 3.3.0's evidence is in test-history/TEST-RESULTS-3.3.0.md.

## What changed
- Help › About › Check for Updates (Updater.cs, UpdateSwap, CaptureController.Update.cs). Nothing goes online until it is clicked (opening the About box asks nothing).
- Addresses: HTTPS only, to api.github.com, github.com, objects.githubusercontent.com and release-assets.githubusercontent.com on the usual port. Redirects are not followed automatically: each one is checked the same way (at most five), so TRT never contacts another site.
- Release: `releases/latest` of mccabedd/tinyredactiontool; drafts and pre-releases ignored; offered only when its version is newer than the running one. The asset must be `TinyRedactionTool-<version>.exe`, 1 MB to 1 GB, with GitHub's SHA-256 (the asset's digest, or the release's SHA256SUMS file).
- Download: beside the .exe as `<exe>.download` (a `.partial` file while it arrives), stopped as soon as it is longer than listed, then checked: exact size, SHA-256, a Windows x64 program (MZ, PE, AMD64) whose version details say TinyRedactionTool and that version. Anything else is deleted.
- Install: the running .exe is renamed to `<exe>.old` and the download takes its name (shortcuts, the startup entry and Open with TRT keep working); TRT quits as usual (asking about unsaved work); the new TRT is started with `--after-update <process id>` (and the same `--managed-policy` file, if any), waits for the old one to end, and says it was updated. If TRT doesn't quit, the swap is undone and the download kept. A development build, or a folder TRT can't write to, only downloads into `%TEMP%\TinyRedactionTool-Update` and says where.
- File menu: New Image, Open Media, Save, Save As, Open Project, Save Project, Add Image, File Info.
- Not done yet (David, 24 Nov): a signature from a key kept off GitHub, and an organisation policy switch to turn the check off.

## How it was checked
- Release340Checks (`--release-340-only`), with a pretend GitHub (HttpMessageHandler): allowed and refused addresses (HTTP, other sites, look-alike names, other ports); a newer release found with notes, size and SHA-256; download through a redirect to GitHub's download server; same, older and pre-release versions not offered; a redirect to another site refused before contacting it; a redirect to HTTP refused; a wrong SHA-256, a changed file, a short file, no SHA-256, and a file that matches its SHA-256 but isn't TRT x64 of that version all deleted; the SHA256SUMS fallback; the swap, its undo, and a failed swap putting the old program back; the About box button (on only with the capture side, no request when the box opens); the whole flow: asks with the notes, No downloads nothing, nothing newer is reported, a development build downloads and says where, and TRT kept open for unsaved work undoes the swap.
- By hand: `--update-probe 3.2.0 <folder>` against the real GitHub found v3.3.0 (GitHub lists SHA-256 digests; downloads redirect to release-assets.githubusercontent.com), downloaded 122,750,111 bytes and passed every check; the file was then deleted.
- Release027Checks: the new File menu order; the About box's privacy line.

## Not checked
- Installing over a running standalone .exe and restarting: it needs a release newer than 3.4.0 on GitHub. Once 3.4.0 is published, the next release (3.4.1) is the first real test.

## Package
- standalone/3.4.0/TinyRedactionTool-3.4.0.exe (product version 3.4.0, x64: what the updater itself checks for); its SHA-256 is in the release's SHA256SUMS file.
