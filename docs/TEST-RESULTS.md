# Verification: 3.1.3, 12 November 2026

Status: **`Build-Dev.ps1` (build and all checks) passed: 1410 checks, none failed.** Build: 0 errors, 0 warnings.

## What changed
- Toolbar spacer (Settings › Toolbar › Add Spacer): a blank gap the size of a button, kept in EditorToolbar as "_".
- First-start defaults from David's "TRT Default Settings.json": toolbar order (Save Media before Save Project, Copy and Paste in their own group), hidden buttons (New, Add Image, Open/Save Project, Previous, Next, Original, Rotate, Flip, Zoom, Settings), the navigation bar in the editor at 48 pixels, a 30-pixel red tab.
- Save Copy button renamed Save Media, tooltip "Save Media As… (No Redactions)"; the capture bar's red tab has no tooltip.
- Edit menu: Copy Image, Paste Image and Paste onto Image before Transform, Rotate and Resize.
- File names: REDACTED_ for every export (CROPPED_ gone); CAPTURE_ for everything made before export (was SCREENSHOT_, RECORDING_, FRAME_, PASTED_, NEW_, EDITED_; Remove History still clears the old names). Save Media As adds _COPY once.
- Help manual: Settings › Toolbar row mentions Add Spacer; Save Media in the toolbar table; editor, Edit menu and Settings pictures redrawn.

## New checks (Release027Checks)
- Edit menu order; Save Media caption and tooltip; red tab without a tooltip; _COPY once; two spacers make two 36-pixel gaps; spacers survive saving; Settings lists, adds and removes spacers; David's new defaults (toolbar, hidden buttons, nav bar, red tab).

## Changed checks
- Capture names expect CAPTURE_ (CaptureChecks, Release014/019/020/021, Release300LayerChecks); leftover CAPTURE_ files are wiped after a crash (Release018).
- Toolbar order and defaults: FrameSpeedChecks (Save Media after Export; Rotate hidden), Release015 (Fit Width between Fit and Actual Size), Release024/025/026/027 (new hidden buttons, nav bar shown at 48, New and Add Image hidden).

## Not checked
- The real keyboard and mouse on David's screen (the checks drive the same code off-screen).

## Package
- TinyRedactionTool-3.1.3.exe, 117 MB, SHA-256 180CA1002762BEA6286EC35A219CF9D3BF50D88468B386FD97CBB77352ED3365 (product version 3.1.3).
