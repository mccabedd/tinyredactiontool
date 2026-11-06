# TinyRedactionTool v2.5.0 security addendum

This describes the delivered release and supplied validation evidence. It supplements the historical `SECURITY-AUDIT.md`; it is not an independent audit or company approval.

## Changes requiring review

Screen capture creates original, potentially sensitive captured media in app-owned temporary storage so it can be opened and processed. This differs from ordinary memory-only decoded previews. A tray session is still running and may retain current captures and extracted tools. Replacing media or Clear Screen releases unused captures; normal Quit cleans owned files. Forced termination can leave files until recovery on the next successful launch. The application does not sweep arbitrary TEMP directories or guarantee recovery of every older test-package folder.

Copy intentionally sends the validated redacted/cropped image to the Windows clipboard. Clipboard history and destination applications are outside TRT's cleanup boundary. Retained audio remains unredacted; audio retention is off by default.

The optional original-source deletion workflow is off by default. It runs only after successful validated export and the accepted eligibility/warning checks. It is separate from app-owned temporary cleanup. Managed `disableSourceDeletion` forbids original deletion without switching off temporary cleanup. Original-source immutability statements in older reports refer to the processing/default workflow, not this explicit opt-in operation.

The policy loader supports independent Boolean restrictions for network opening/saving, original deletion, audio retention and Blur/Pixelate. Unknown/invalid configured policies fail startup. **It is not mandatory tamper-proof enforcement:** an explicit local policy path overrides automatic discovery, discovery uses the process's ProgramData environment value, and missing automatic policy gives normal public behaviour. Policies are unsigned. Deployment ACLs, application control and any required mandatory managed edition need company review. See [MANAGED-POLICY-DEPLOYMENT.md](MANAGED-POLICY-DEPLOYMENT.md).

## Standalone resource lifecycle

The compiler's automatic pre-script file extraction is suppressed by one documented assignment change. Approved GZip media resources stay in the assembly until the owning instance has acquired the single-instance guard and validated its selected policy. The source expands them into a unique local runtime folder with an exclusive ownership lease, then applies the existing approved binary hashes and read-only sharing locks.

Normal exit removes recognised runtime tools. Next-launch recovery skips active leases and rejects redirected/outside-root folders or unexpected entries. It recognises interrupted ownership-marker/tool writes in this format. It does not claim immediate cleanup after process kill, power loss or a machine that is never started again. Unknown entries stop cleanup to avoid deleting unrelated data.

## Preserved behaviour and checked evidence

The final C9-to-final application changes are limited to icon/header assets and media-resource bootstrap. All 301 other existing functions and protected top-level event handlers/statements/parameters were compared exactly. The approved media binaries, export renderers/validation, CFR/VFR mapping, Begin/End semantics, original deletion implementation and accepted audio/network/policy controls are unchanged in that promotion.

Supplied evidence records successful Windows PowerShell parsing, exact original/adapted compiler checks, all seven icon resource frames, approved tools after compiled expansion, compiled startup, second-instance handoff, forced termination/relaunch recovery and normal process-local session-end cleanup. A separate compiled fixture exercises actual synthetic cropped/redacted image export validation and light/dark loading/clipboard dialogs under public and restricted policy, using a bitmap sink instead of the user's clipboard. Runtime ownership tests cover partial markers/tools, active leases, foreign markers, unexpected contents and outside-root rejection. Policy tests cover sample values, explicit-path precedence, machine fallback, absent-policy behaviour and malformed controls/envelopes.

Final acceptance should exercise representative long CFR/VFR videos, native capture shortcuts, real clipboard paste, UNC/mapped paths, deployment ACLs, all restriction combinations and capture/export cancellation/error/crash paths. Reports and provenance are under `packaging/evidence`; source/build details are in `packaging/BUILD-AND-AUDIT.md`.

## Residual limits

The EXE is unsigned and compiled PowerShell is not a boundary against altered/unmanaged copies or privileged attackers. No guarantee is made for erasure from SSD remapping, backups/snapshots, cloud sync, clipboard history, pagefiles, crash dumps or monitoring tools. Blur/Pixelate remain visual obscuration; opaque Coloured Box is the sensitive-content redaction method. The offline builder repackages approved binaries; it is not the complete corresponding FFmpeg/toolchain source archive. Preserve and review matching media-tool source/build inputs separately.
