# Verification: 3.0.0, 5 November 2026

Status: **`Build-Dev.ps1` (build and all checks) passed: 1342 checks, none failed.** Build: 0 errors, 0 warnings.

## New checks (Checks/Release300Checks.cs; `--release-300-only` runs these 18)
- The Help manual is beside the program, every one of its 78 pictures and icons is there, every contents link goes to a section, nothing comes from the internet, and the picture-making notes are not shipped.
- With Edge, it opens in an Edge app window (`--app=file:///…TRT-Help.html#theme=dark|light`); without Edge, in the default browser. The page follows the theme TRT asks for.
- The Help window has its own icon (the TRT icon with a yellow question mark, 16 to 256 pixels), and in Dark the manual's scroll bars are dark (checked on an Edge screenshot too).
- Windows calls the program TinyRedactionTool (the .exe's description, product and company), and the picture-app registration names it for Open With; an older registration without the name is updated when TRT starts (throw-away registry key).
- Clean-up: the internal name is TinyRedactionTool; projects saved by older builds still open, and projects from other programs are still refused (the first suite run after the rename caught a slip that had silenced this refusal; fixed); a development run never rewrites the Windows startup entry.
- The version is 3.0.0. The capture bar's menu has Help (Release028Checks).

## Window memory and arrow-key nudge (Checks/Release300EditChecks.cs; `--window-nudge-only` runs these 24)
- The editor's window place is saved as text and read back (other monitors too); a missing, damaged or tiny one is ignored and the editor opens maximised, as before.
- A real window opens windowed at the remembered size and place; closed while minimised it is remembered as it was before; closed in F11 full screen, as it was before full screen; minimised from maximised, as maximised. A place on a monitor that is gone (-60000, -60000) opens on a connected screen.
- Through the capture controller, closing the editor writes the place to the settings file; exported settings leave it out.
- Arrow keys nudge a selected redaction 1 pixel each way without changing its size; Shift-size steps are 10 pixels; one Undo takes back one press, or one held press with its key repeats; nudges stop at the picture's edge; lines and several selected shapes nudge too; with nothing selected nothing moves; a list in the side panel keeps its arrow keys.
## Help in TRT's own window (Release300EditChecks; `--window-nudge-only`)
- The window lists all 24 sections in the manual's groups, shows all 86 pictures and icons, all the text (no tags or codes), 13 tables, the numbered steps and the 7 tip/warning/stop boxes; links go to their sections.
- Clicking a section puts its heading at the top; the first goes back to the top; a link marks its section in the contents. One Help window at a time; it follows a theme change while open; light and dark colours are the manual's.
- The Help code never starts a browser or another program (source scan). Pictures of the window: test-output/help-window*.png.

## Changed checks
- The last menu is Help, with Help, Settings and About (Release022, Program.cs).

## Not checked
- Nudging with Shift held on the real keyboard (the check calls the 10-pixel step directly; checks cannot hold Shift).
- The Help window on a real screen (the checks show it off-screen and take pictures of it).

## Package
`development/standalone/3.0.0/TinyRedactionTool-3.0.0.exe`, 117 MB (the manual adds 1.5 MB), SHA-256 FEA99D690451DD2CB620BE4A403D6B195E8A772C0AF02B7A62D4CF8632356F28.