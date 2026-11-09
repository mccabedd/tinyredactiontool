# Verification: 3.1.1, 9 November 2026

Status: **the release checks for this change passed (`--release-300-only` 21 checks, `--release-025-only` 44 checks), none failed.** Build: 0 errors, 0 warnings. The rest of the program is unchanged from 3.1.0, whose full run passed 1396 checks.

## What changed
- "Open with TRT" in File Explorer's right-click menu: when it is switched on and TRT starts from a different .exe (a newer version, or the old one was deleted), TRT points the entry at itself (ExplorerMenu.Refresh, called beside PictureApp.Refresh and StartupEntry.Refresh when TRT starts). Before, an entry left by a deleted TRT gave "Application not found".

## New checks (Release300Checks, on a throw-away registry key)
- A fresh entry starts this TRT; an entry that starts a deleted TRT is noticed; a development run never rewrites it; rewriting points every format at this TRT; with the setting cleared, starting TRT adds nothing.
- The version is 3.1.1.

## Package
- TinyRedactionTool-3.1.1.exe, 117 MB, SHA-256 648B283B34246ED6FE5C3EA3B6BC85EEDA81E40D627D433869531465E4FCFA7E (product version 3.1.1).