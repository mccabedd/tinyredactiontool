# TinyRedactionTool v2.5.0 managed policy

The application reads one local UTF-8 JSON file at startup. IT normally deploys it at `%ProgramData%\TinyRedactionTool\policy.json` (usually `C:\ProgramData\TinyRedactionTool\policy.json`). Create that folder and install the file through your organisation's deployment tools. Give standard users read access; restrict writing, replacement and deletion of the file and its parent folder to administrators/deployment services. Restart TRT after changes; opening a second instance restores the existing session and does not reload policy.

Each setting is an independent restriction. `true` prohibits the feature; `false` or an omitted control preserves normal application behaviour. It does not force a feature on or select it for the user.

| JSON control | Effect when true | Normal behaviour when false/absent |
|---|---|---|
| `blockNetworkSource` | Blocks UNC and mapped-network media opening before inspection. | Network opening remains available with the existing warning. |
| `blockNetworkDestination` | Blocks UNC and mapped-network export destinations before encoding. | Network saving remains available with the existing warning. |
| `disableSourceDeletion` | Disables the optional original-file deletion workflow. | Eligible original deletion remains an explicit user choice, off by default, with existing warnings and checks. |
| `disableAudioRetention` | Disables Keep Audio and enforces audio-free video export. | Keep Audio remains an explicit choice, off by default; retained audio is not redacted. |
| `disableVisualObscuration` | Disables Blur and Pixelate. Opaque Coloured Box redaction remains available. | Existing Blur/Pixelate choices and warnings remain. |

For example, the supplied `policy-restricted.json` contains:

```json
{
  "schemaVersion": 1,
  "policyId": "company-restricted",
  "policyVersion": "1.0",
  "controls": {
    "blockNetworkSource": true,
    "blockNetworkDestination": true,
    "disableSourceDeletion": true,
    "disableAudioRetention": true,
    "disableVisualObscuration": true
  }
}
```

Copy the selected sample to the machine location as `policy.json`; the samples are not activated merely by being beside the EXE. `policy-permissive.json` preserves normal user choices. Edit individual Boolean controls for a mixed profile. There is no separate administration console or built-in GPO template; your management platform distributes the file. About shows the loaded policy identity/version and active restrictions.

An explicitly supplied `-ManagedPolicyPath "C:\local\policy.json"` takes precedence over the automatic machine file. This is useful for governance tests. A configured invalid policy stops startup; it is not silently ignored. Validation rejects unknown fields/controls, non-Boolean controls, unsupported schema, invalid JSON/UTF-8, network policy locations, reparse-point policy files and files outside the 1-byte–64-KiB size limit. The envelope requires exactly `schemaVersion`, `policyId`, `policyVersion` and `controls`. IDs allow letters/numbers/dot/underscore/hyphen (ID 1–64 characters, version 1–32).

## Enforcement limitations for security review

The existing accepted loader is unchanged. The JSON file alone is **not mandatory, tamper-proof organisation-wide enforcement**:

- A caller can pass a different valid local policy using `-ManagedPolicyPath`; that override wins over the machine policy.
- Automatic discovery uses the process's `ProgramData` environment value. A changed launch environment can redirect discovery.
- If no automatic policy is found and no explicit policy is requested, TRT starts with normal public behaviour.
- Policies are not digitally signed. `policyId` and `policyVersion` are descriptive metadata, not authentication.
- The EXE is an unsigned compiled PowerShell application, and the source is supplied. Packaging is not a security boundary against a user running an altered/unmanaged copy.

Company reviewers should decide whether these accepted test/deployment behaviours suit their threat model. A mandatory managed edition would need a separate, explicitly reviewed change covering authoritative machine-policy precedence, fixed discovery, missing-policy behaviour and permitted test overrides, plus company deployment/application controls. Those changes are not silently included in this final release.

## Temporary cleanup versus original deletion

`disableSourceDeletion` governs the **user's original source file**, not session-owned temporary captures, export scratch files or extracted tools. Normal cleanup remains active in either policy profile. Tray residency is an active session, not application exit: current captures and tools may remain while needed. Clear Screen/replacing media releases unused captures; Quit cleans up owned captures and runtime tools. After forced termination, owned files can remain until the next successful launch recovers them. The resource-only build does not write compressed tool payloads to TEMP before startup or on second launch.

TRT does not indiscriminately erase TEMP or files belonging to other programs. It validates ownership, paths, leases and expected names. Unrecognised contents stop cleanup rather than risking unrelated data. Previously created test-package folders are not all covered by the new ownership marker. Any historical cleanup must be separately identified and reviewed. This package has not deleted your existing TEMP contents.

Overwrite/delete does not guarantee erasure from SSD remapping, snapshots, backups, pagefiles, crash dumps or other software's copies. Copy to Clipboard deliberately transfers the redacted result to Windows/other applications; TRT does not control clipboard history or pasted copies.

## Company acceptance checks

1. Verify delivered EXE/source/tool hashes; retain the source/build bundle with the review record. Verify About identifies v2.5.0 and the expected policy ID/version.
2. Deploy each restriction independently, then all five together. Test local image/video workflows under every profile.
3. With network restrictions on, test UNC and mapped-drive opening/saving. Confirm no media inspection/encoding begins for prohibited paths. With controls off, confirm the existing warning/normal workflow.
4. Confirm original deletion cannot be selected when disabled and original bytes remain after export. With it allowed, exercise the existing eligibility, warning and deletion checks using disposable fixtures only.
5. Confirm Keep Audio cannot be selected when disabled and independently inspect exported streams. With it allowed, verify off-by-default and explicit opt-in behaviour.
6. Confirm Blur/Pixelate are unavailable under their restriction and opaque redaction still works. Check ordinary annotation/crop/clipboard functions remain usable.
7. Test malformed/unknown/non-Boolean policy values: startup must fail. Separately demonstrate the explicit-path override, altered `ProgramData` and absent-policy limitations above; record the company's deployment decision.
8. Test normal Quit, capture cancellation, Clear Screen, forced termination and next-launch recovery using synthetic captures. Check active sessions are not swept. Also inspect app-owned export masks/scratch files after cancellation and export errors.
9. Test long video loading/export, Cancel, minimize/restore/maximize, tray reopening and second launch. Verify output frame/timing/audio/stream rules on representative company CFR/VFR media.

Automated checks supplied with this package cover parser/static preservation, exact packaged tools/icons, compiled startup, second-launch handling, runtime crash recovery and synthetic themed clipboard workflows. Actual company network paths, policy ACL deployment and representative long videos remain company acceptance checks.
