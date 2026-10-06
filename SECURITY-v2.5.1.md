# TinyRedactionTool v2.5.1 security addendum

This addendum describes the focused v2.5.1 maintenance changes. It supplements `SECURITY-v2.5.0.md` and the historical `SECURITY-AUDIT.md`; it is not an independent security audit or company approval.

## Scope

v2.5.1 retains the v2.5.0 media binaries and established redaction/timing/export architecture. The maintenance changes are concentrated in annotation drawing, screenshot capture/copy/export behaviour, theme/window behaviour and related UI state.

The approved decompressed media-tool identities remain:

- FFmpeg: `643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC`
- FFprobe: `84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2`

## Outline drawing annotations are not redactions

The new Rectangle/Oval/Freeform Drawing tools create annotation `ShapeOutline` objects. They have no opaque, Blur or Pixelate interior and must not be represented as a security boundary. They reuse annotation colour/thickness/style controls and annotation timing.

Their geometry intentionally retains exact floating-point displayed-media coordinates. The secure redaction normaliser that floors/snaps redaction rectangles for export safety is not applied to these annotation objects. This separation fixes handle/outline drift without changing the established opaque-redaction normalisation path.

## Screenshot copy and export

A still screenshot created by the current TRT session is now eligible for Copy and Export Image even when no edit has been committed. This is a deliberate convenience exception based on current-session capture provenance; arbitrary still images opened from disk retain the ordinary committed-content/crop requirement.

Copy deliberately discloses screenshot pixels to the Windows clipboard. Clipboard history, destination applications and other OS-level consumers remain outside TRT's cleanup boundary. A no-edit screenshot export deliberately writes the captured pixels to the selected destination through the existing image-export/validation path.

Still-region capture uses the full-desktop bitmap acquired before the region selector is shown, then crops the selected rectangle from that snapshot. This allows transient UI such as dropdowns, menus and tooltips to remain present in the captured pixels even if showing or interacting with the selector later changes focus. Video capture remains a live-region recording path and is unchanged by this behaviour.

## Window and theme behaviour

Dark Mode is now the startup default. Floating annotation editors explicitly use themed foreground/background colours, including the Text Bold, Italic and alignment controls. These changes do not alter media processing.

Startup now reasserts maximized state and makes a one-shot foreground activation request after the form is shown. TRT is not made permanently TopMost. The previous focus-on-mouse-enter behaviour was removed so pointer movement alone should not activate TRT or reorder unrelated windows.

## Preserved controls and residual limits

The v2.5.0 managed-policy controls, optional source deletion rules, audio-off-by-default behaviour, metadata/extra-stream stripping, transaction/validation model, network-disabled embedded FFmpeg profile and runtime ownership/cleanup model remain applicable.

Blur and Pixelate remain visual obscuration only. For sensitive information use opaque Black/Coloured Box redaction. No guarantee is made for erasure from clipboard history, backups/snapshots, pagefiles, crash dumps, SSD remapping, cloud synchronisation, monitoring software or a compromised/privileged host.

## Release evidence note

The v2.5.1 source was promoted from the user-tested maintenance sequence and subsequently rechecked after the Text-editor theme and pre-selector screenshot fixes. The approved media binaries remain unchanged. Repository build documentation records the current source identity and preserved media-tool identities. Binary/archive identities are published separately in `SHA256SUMS-v2.5.1.txt`.

## Final v2.5.1 maintenance refinements

The final accepted source additionally changes user-interface workflow only:

- still-image screenshot output is cropped from the desktop snapshot captured before the region selector is displayed, preserving transient UI visible at invocation time;
- completed still-image redaction/annotation drafts may be committed by an outside click using the same established commit paths as the green Create controls;
- floating editors provide direct delete/cancel controls; and
- floating editor layout/theme changes improve visibility and compactness without changing redaction/export semantics.

These changes do not alter the approved FFmpeg/FFprobe binaries, video timing model, opaque-redaction safety margins, Blur/Pixelate semantics, export validation, managed-policy behaviour, metadata stripping or audio defaults.
