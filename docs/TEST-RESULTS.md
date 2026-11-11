# Verification: 3.1.2, 11 November 2026

Status: **the checks for this change passed (`--release-027-only` 20 checks, `--release-300-only` 21 checks), none failed.** Build: 0 errors, 0 warnings. The rest of the program is unchanged from 3.1.0, whose full run passed 1396 checks.

## What changed
- File menu order (David): New Image, Open Media (Ctrl+O), Export (Ctrl+E), Save Media As (Ctrl+Shift+S), Add Image, Open Project, Save Project, File Info. The new shortcuts do nothing when their menu item is greyed out. The Help manual's shortcut table lists them, and its File menu picture (docs/help/images/menu-file.png) was redrawn.

## New and changed checks
- Release027Checks: the File menu's first eight items, in this order, with these shortcuts (replaces the 0.27.0 check that Add Image came third).
- Release300Checks: the version is 3.1.2.

## Not checked
- Ctrl+O, Ctrl+E and Ctrl+Shift+S on the real keyboard (the checks cannot hold Ctrl; they check the menu wording).
- The rest of the full suite (unchanged code).

## Package
- TinyRedactionTool-3.1.2.exe, 117 MB, SHA-256 B154D79E31DD165FB47C2549A4E6472CA582B404E66BAAF7E63C74BFA3DAE019 (product version 3.1.2).
