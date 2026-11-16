# Verification: 3.2.1, 16 November 2026

Status: **targeted checks passed after the last change: `--scrolling-only` 16 and `--release-320-only` 42, none failed.** Build: 0 errors, 0 warnings. The last full run (1453 checks, all passed) was before the last scrolling changes and was not repeated.

## What changed
- Scrolling capture of a short scrolling area (about 330 pixels between a fixed header and a large fixed box): each wheel turn (two notches) moved it about 300 pixels, so the second join had no reliable overlap and the capture stopped with the first screen. ScrollingCapture.RunAsync now turns the wheel one notch first, then sizes each turn with WheelFor so the content moves about 45 % of the pane (30 to 240 units; tall pages keep two notches).
- When the picker gave a web pane (CaptureOverlay.SelectedWebPane), the pane's own top above the part that scrolls is kept (RunAsync keepPaneTop), with no side columns or fixed box.
- Floating buttons are left out: Stitch maps the spots that stay the same in the next picture although the page under them moved on (seen in at least two pairs of pictures, small colour changes allowed, widened by 2 pixels) and fills them from the next picture where they are clear; only the last screen's button is left.
- Scrolling waits until Shift, Ctrl and Alt are let go (Shift + wheel scrolls sideways in a browser, Ctrl + wheel zooms).
- A part-notch turn that moves nothing is followed by a whole notch before the end is decided; a join that fails is retried (the screen taken again after 0.5 s and 1 s, then one step back and a smaller step).
- A last step that ends on part of a pixel draws text a little differently: a brightness match from 85 % is taken when, leaving out plain rows, it beats every other step size by 30 points. A click in an empty part of a pane, where no pane is found from the click, uses the band of rows that changed (ChangedBand).
- A picked web pane keeps its full width, less its own scroll bar, and every row from the first to the last that changed, extended over blank rows of the pane's own background (ScrollingCapture.PartToKeep), so margins and the end of a short scrolling area are no longer cut off.

## How it was checked
- Reproduced with a local page shaped like such a layout (side columns, a header, a short scrolling area of 14 paragraphs, a 300-pixel fixed box) in a throwaway InPrivate Edge window, through `--scroll-probe` on the middle column: 3.2.0 joined 2 pictures; with the step sizing, 15 pictures, all 14 paragraphs in order.
- New checks (Release022Checks, `--scrolling-only`): a floating button that fades a little from screen to screen is joined in once and the page under it is whole; a step whose text is drawn a little differently in some rows still joins when one step size clearly wins; with the click where nothing moves, the band of rows that changed is kept; a picked web pane keeps its full width and its whole band (blank rows at the bottom of the first two screens included), and the long picture ends with the last line and keeps every row of a column that doesn't move in the first screens; scrolling waits until Shift, Ctrl and Alt are let go. Release320Checks: the wheel sizing. `--keep <before> <after> <x> <y> [top]` shows what is kept of two screens.

## Not checked
- The rest of the full suite after the last scrolling changes.

## Package
- TinyRedactionTool-3.2.1.exe (product version 3.2.1); its SHA-256 is in the release's SHA256SUMS file.
