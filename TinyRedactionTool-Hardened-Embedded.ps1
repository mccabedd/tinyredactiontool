Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Native Open/Save dialog wrapper used so Windows does not add patient
# filenames/paths to Recent Items/MRU history. Windows PowerShell 5.1's
# WinForms FileDialog does not expose AddToRecent, so use the documented
# OFN_DONTADDTORECENT flag directly instead of relying on a newer .NET API.
#
# SECURITY/COMPATIBILITY NOTE:
# OPENFILENAME contains writable native character buffers. Do not use
# StringBuilder fields inside this structure: .NET Framework cannot marshal
# StringBuilder as a structure field. Use explicitly allocated unmanaged
# UTF-16 buffers and free them immediately after the dialog closes.
if (-not ("SecureFileDialogNativeV2" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

public static class SecureFileDialogNativeV2
{
    [StructLayout(LayoutKind.Sequential)]
    private struct OPENFILENAME
    {
        public int lStructSize;
        public IntPtr hwndOwner;
        public IntPtr hInstance;
        public IntPtr lpstrFilter;
        public IntPtr lpstrCustomFilter;
        public int nMaxCustFilter;
        public int nFilterIndex;
        public IntPtr lpstrFile;
        public int nMaxFile;
        public IntPtr lpstrFileTitle;
        public int nMaxFileTitle;
        public IntPtr lpstrInitialDir;
        public IntPtr lpstrTitle;
        public int Flags;
        public short nFileOffset;
        public short nFileExtension;
        public IntPtr lpstrDefExt;
        public IntPtr lCustData;
        public IntPtr lpfnHook;
        public IntPtr lpTemplateName;
        public IntPtr pvReserved;
        public int dwReserved;
        public int FlagsEx;
    }

    private const int OFN_OVERWRITEPROMPT = 0x00000002;
    private const int OFN_HIDEREADONLY = 0x00000004;
    private const int OFN_NOCHANGEDIR = 0x00000008;
    private const int OFN_PATHMUSTEXIST = 0x00000800;
    private const int OFN_FILEMUSTEXIST = 0x00001000;
    private const int OFN_EXPLORER = 0x00080000;
    private const int OFN_ENABLESIZING = 0x00800000;
    private const int OFN_DONTADDTORECENT = 0x02000000;
    private const int FileBufferChars = 32768;

    [DllImport("comdlg32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetOpenFileName(ref OPENFILENAME ofn);

    [DllImport("comdlg32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetSaveFileName(ref OPENFILENAME ofn);

    [DllImport("comdlg32.dll")]
    private static extern int CommDlgExtendedError();

    private static string MakeFilter(string filter)
    {
        if (String.IsNullOrEmpty(filter)) return "All files\0*.*\0\0";
        return filter.Replace("|", "\0") + "\0\0";
    }

    private static IntPtr AllocUtf16(string value)
    {
        if (value == null) return IntPtr.Zero;
        byte[] bytes = Encoding.Unicode.GetBytes(value + "\0");
        IntPtr ptr = Marshal.AllocHGlobal(bytes.Length);
        Marshal.Copy(bytes, 0, ptr, bytes.Length);
        return ptr;
    }

    private static IntPtr AllocFileBuffer(string initialFile)
    {
        int byteCount = FileBufferChars * 2;
        byte[] buffer = new byte[byteCount];

        if (!String.IsNullOrEmpty(initialFile))
        {
            byte[] initial = Encoding.Unicode.GetBytes(initialFile);
            int copyCount = Math.Min(initial.Length, byteCount - 2);
            Buffer.BlockCopy(initial, 0, buffer, 0, copyCount);
        }

        IntPtr ptr = Marshal.AllocHGlobal(byteCount);
        Marshal.Copy(buffer, 0, ptr, byteCount);
        return ptr;
    }

    private static void Free(ref IntPtr ptr)
    {
        if (ptr != IntPtr.Zero)
        {
            Marshal.FreeHGlobal(ptr);
            ptr = IntPtr.Zero;
        }
    }

    private static OPENFILENAME Create(
        IntPtr owner,
        IntPtr filter,
        IntPtr title,
        IntPtr fileBuffer,
        IntPtr defaultExt,
        int flags)
    {
        OPENFILENAME ofn = new OPENFILENAME();
        ofn.lStructSize = Marshal.SizeOf(typeof(OPENFILENAME));
        ofn.hwndOwner = owner;
        ofn.lpstrFilter = filter;
        ofn.nFilterIndex = 1;
        ofn.lpstrFile = fileBuffer;
        ofn.nMaxFile = FileBufferChars;
        ofn.lpstrFileTitle = IntPtr.Zero;
        ofn.nMaxFileTitle = 0;
        ofn.lpstrTitle = title;
        ofn.lpstrDefExt = defaultExt;
        ofn.Flags = flags | OFN_EXPLORER | OFN_ENABLESIZING | OFN_NOCHANGEDIR | OFN_DONTADDTORECENT;
        return ofn;
    }

    private static string Finish(bool ok, ref OPENFILENAME ofn)
    {
        if (ok) return Marshal.PtrToStringUni(ofn.lpstrFile);

        int error = CommDlgExtendedError();
        if (error == 0) return null; // user cancelled

        throw new Win32Exception(error, "Windows file dialog failed (CommDlgExtendedError 0x" + error.ToString("X4") + ").");
    }

    public static string ShowOpen(IntPtr owner, string filter, string title)
    {
        IntPtr filterPtr = IntPtr.Zero;
        IntPtr titlePtr = IntPtr.Zero;
        IntPtr filePtr = IntPtr.Zero;

        try
        {
            filterPtr = AllocUtf16(MakeFilter(filter));
            titlePtr = AllocUtf16(title);
            filePtr = AllocFileBuffer(null);

            OPENFILENAME ofn = Create(
                owner, filterPtr, titlePtr, filePtr, IntPtr.Zero,
                OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY);

            bool ok = GetOpenFileName(ref ofn);
            return Finish(ok, ref ofn);
        }
        finally
        {
            Free(ref filePtr);
            Free(ref titlePtr);
            Free(ref filterPtr);
        }
    }

    public static string ShowSave(IntPtr owner, string filter, string title, string initialFile, string defaultExt)
    {
        IntPtr filterPtr = IntPtr.Zero;
        IntPtr titlePtr = IntPtr.Zero;
        IntPtr filePtr = IntPtr.Zero;
        IntPtr defaultExtPtr = IntPtr.Zero;

        try
        {
            filterPtr = AllocUtf16(MakeFilter(filter));
            titlePtr = AllocUtf16(title);
            filePtr = AllocFileBuffer(initialFile);
            defaultExtPtr = AllocUtf16(defaultExt);

            OPENFILENAME ofn = Create(
                owner, filterPtr, titlePtr, filePtr, defaultExtPtr,
                OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT | OFN_HIDEREADONLY);

            bool ok = GetSaveFileName(ref ofn);
            return Finish(ok, ref ofn);
        }
        finally
        {
            Free(ref defaultExtPtr);
            Free(ref filePtr);
            Free(ref titlePtr);
            Free(ref filterPtr);
        }
    }
}
"@
}

[System.Windows.Forms.Application]::EnableVisualStyles()

# ----------------------------
# Packaged media-tool bootstrap
# ----------------------------
# PS2EXE writes the two GZip payloads below before this script starts. For the
# packaged EXE only, expand them into a unique per-run directory under TEMP,
# verify their SHA-256 pins before execution, and remove the runtime directory
# when the GUI closes. The distributed application remains one EXE.
$script:EmbeddedMediaRuntimeDir = $null
$script:EmbeddedFFmpegRuntimePath = $null
$script:EmbeddedFFprobeRuntimePath = $null
# SECURITY: once an approved runtime tool has been hash-verified, keep a read
# handle open without write/delete sharing for the entire application session.
# This closes the post-verification tamper window without re-hashing a ~27 MB
# executable before every frame-preview invocation.
$script:ApprovedFFmpegLock = $null
$script:ApprovedFFprobeLock = $null
$script:EmbeddedFFmpegPayloadGzip = Join-Path $env:TEMP "TinyRedactionTool\payload\ffmpeg.exe.gz"
$script:EmbeddedFFprobePayloadGzip = Join-Path $env:TEMP "TinyRedactionTool\payload\ffprobe.exe.gz"

function Expand-EmbeddedGzipTool([string]$gzipPath, [string]$destinationPath) {
    $input = $null
    $gzip = $null
    $output = $null
    try {
        $input = [System.IO.File]::OpenRead($gzipPath)
        $gzip = New-Object System.IO.Compression.GZipStream($input, [System.IO.Compression.CompressionMode]::Decompress)
        $output = [System.IO.File]::Create($destinationPath)
        $gzip.CopyTo($output)
        $output.Flush()
    }
    finally {
        if ($output) { $output.Dispose() }
        if ($gzip) { $gzip.Dispose() }
        if ($input) { $input.Dispose() }
    }

    if (-not (Test-Path -LiteralPath $destinationPath -PathType Leaf) -or (Get-Item -LiteralPath $destinationPath).Length -lt 256KB) {
        throw "Embedded media-tool payload could not be expanded."
    }
}

function Initialize-EmbeddedMediaTools {
    # Plain .ps1 development mode deliberately skips this bootstrap and uses
    # application-local binaries beside the script instead.
    if (-not (Test-IsPackagedHost)) { return }

    if (-not (Test-Path -LiteralPath $script:EmbeddedFFmpegPayloadGzip -PathType Leaf) -or
        -not (Test-Path -LiteralPath $script:EmbeddedFFprobePayloadGzip -PathType Leaf)) {
        throw "The packaged FFmpeg/FFprobe payload is missing."
    }

    $runDir = Join-Path $env:TEMP ("TinyRedactionTool\run-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null

    try {
        $runtimeFFmpeg = Join-Path $runDir "ffmpeg.exe"
        $runtimeFFprobe = Join-Path $runDir "ffprobe.exe"
        Expand-EmbeddedGzipTool $script:EmbeddedFFmpegPayloadGzip $runtimeFFmpeg
        Expand-EmbeddedGzipTool $script:EmbeddedFFprobePayloadGzip $runtimeFFprobe

        $script:EmbeddedMediaRuntimeDir = $runDir
        $script:EmbeddedFFmpegRuntimePath = $runtimeFFmpeg
        $script:EmbeddedFFprobeRuntimePath = $runtimeFFprobe
    }
    catch {
        Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
        throw
    }
    finally {
        # The staging payload contains only program binaries, not patient data.
        # Remove it once the unique per-run copies have been created.
        Remove-Item -LiteralPath $script:EmbeddedFFmpegPayloadGzip -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:EmbeddedFFprobePayloadGzip -Force -ErrorAction SilentlyContinue
        $payloadDir = Split-Path -Parent $script:EmbeddedFFmpegPayloadGzip
        if ($payloadDir) { Remove-Item -LiteralPath $payloadDir -Force -ErrorAction SilentlyContinue }
    }
}

function Close-ApprovedMediaToolLocks {
    foreach ($name in @('ApprovedFFmpegLock','ApprovedFFprobeLock')) {
        $handle = Get-Variable -Name $name -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($handle) {
            try { $handle.Dispose() } catch {}
            Set-Variable -Name $name -Scope Script -Value $null
        }
    }
}

function Remove-EmbeddedMediaTools {
    # Release the trust locks only when the application is done using the tools;
    # otherwise Windows correctly refuses to delete the verified executables.
    Close-ApprovedMediaToolLocks
    if ($script:EmbeddedMediaRuntimeDir) {
        Remove-Item -LiteralPath $script:EmbeddedMediaRuntimeDir -Recurse -Force -ErrorAction SilentlyContinue
        $script:EmbeddedMediaRuntimeDir = $null
        $script:EmbeddedFFmpegRuntimePath = $null
        $script:EmbeddedFFprobeRuntimePath = $null
    }
}
 
# ----------------------------
# Helpers
# ----------------------------
# Standalone builder/bootstrap integration points.
#
# DEVELOPMENT / PLAIN-PS1 USE:
#   These may remain blank while testing the script. In that mode TinyRedactionTool
#   still location-pins both binaries beside this PS1 and NEVER searches PATH.
#
# PACKAGED RELEASES:
#   The standalone builder MUST inject the SHA-256 of the exact ffmpeg.exe and
#   ffprobe.exe it ships. A packaged EXE fails closed if either value is blank.
#
# Compute the approved hashes from the exact release binaries with:
#   (Get-FileHash -LiteralPath .\ffmpeg.exe  -Algorithm SHA256).Hash
#   (Get-FileHash -LiteralPath .\ffprobe.exe -Algorithm SHA256).Hash
#
# Then replace the two empty strings below with the resulting 64-character hashes
# before packaging. Do not hash a different build and do not use placeholder values.
$script:ExpectedFFmpegSha256 = ""
$script:ExpectedFFprobeSha256 = ""

function Test-IsPackagedHost {
    try {
        $hostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $hostName = [System.IO.Path]::GetFileNameWithoutExtension($hostExe)
        return ($hostName -notin @("powershell", "powershell_ise", "pwsh"))
    }
    catch {
        # If host identity cannot be established, err on the secure side.
        return $true
    }
}

function Test-ApprovedTool([string]$path, [string]$expectedHash, [string]$displayName) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }

    if ([string]::IsNullOrWhiteSpace($expectedHash)) {
        if (Test-IsPackagedHost) {
            [System.Windows.Forms.MessageBox]::Show(
                "$displayName SHA-256 pinning was not populated by the standalone builder. This packaged release will not execute an unpinned media tool.",
                "$displayName trust check failed",
                "OK",
                "Error"
            ) | Out-Null
            return $false
        }

        # Plain-PS1 development mode: location pinning still prevents an
        # arbitrary PATH binary from being selected. Release packaging is not
        # allowed to rely on this weaker development-only state.
        return $true
    }

    if ($expectedHash -notmatch '^[0-9A-Fa-f]{64}$') {
        [System.Windows.Forms.MessageBox]::Show(
            "$displayName hash verification is configured incorrectly. The expected SHA-256 must contain exactly 64 hexadecimal characters.",
            "$displayName trust check failed",
            "OK",
            "Error"
        ) | Out-Null
        return $false
    }

    # SECURITY: open the exact executable with FileShare.Read only, hash the
    # bytes through that already-open handle, and retain the handle for the
    # lifetime of the GUI. Other readers (including CreateProcess) are allowed,
    # but later write/delete opens are denied by Windows. This prevents a tool
    # from being modified after startup verification and then executed via the
    # already-resolved path.
    $lock = $null
    $sha = $null
    try {
        $lock = [System.IO.File]::Open(
            $path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::Read
        )
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha.ComputeHash($lock)
        $actual = ([System.BitConverter]::ToString($hashBytes)).Replace('-', '')

        if (-not $actual.Equals($expectedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
            $lock.Dispose()
            $lock = $null
            [System.Windows.Forms.MessageBox]::Show(
                "The bundled $displayName does not match the approved SHA-256 hash and will not be executed.",
                "$displayName trust check failed",
                "OK",
                "Error"
            ) | Out-Null
            return $false
        }

        # Retain the verified handle so the approved bytes cannot be replaced or
        # appended to while TinyRedactionTool is running.
        if ($displayName -eq 'FFmpeg') {
            if ($script:ApprovedFFmpegLock) { try { $script:ApprovedFFmpegLock.Dispose() } catch {} }
            $script:ApprovedFFmpegLock = $lock
        }
        elseif ($displayName -eq 'FFprobe') {
            if ($script:ApprovedFFprobeLock) { try { $script:ApprovedFFprobeLock.Dispose() } catch {} }
            $script:ApprovedFFprobeLock = $lock
        }
        else {
            $lock.Dispose()
            $lock = $null
            throw "Unknown approved media tool."
        }
        $lock = $null # ownership transferred to the script-scoped trust lock
    }
    catch {
        if ($lock) { try { $lock.Dispose() } catch {} }
        [System.Windows.Forms.MessageBox]::Show(
            "The bundled $displayName could not be verified and locked against modification and will not be executed.",
            "$displayName trust check failed",
            "OK",
            "Error"
        ) | Out-Null
        return $false
    }
    finally {
        if ($sha) { $sha.Dispose() }
    }
    return $true
}

function Find-ApprovedMediaTool([string]$fileName, [string]$expectedHash, [string]$displayName) {
    # SECURITY: Never search PATH. FFmpeg receives the complete unredacted
    # source media; FFprobe is a post-export security gate. Both are therefore
    # restricted to the application/script directory and, in packaged builds,
    # must be cryptographically pinned by the standalone builder.
    $candidates = New-Object System.Collections.Generic.List[string]

    # In the single-EXE build, PS2EXE payloads are expanded into a unique
    # per-run directory before tool resolution. Hash verification below still
    # occurs before either executable is used.
    if ($fileName -eq "ffmpeg.exe" -and $script:EmbeddedFFmpegRuntimePath) {
        [void]$candidates.Add($script:EmbeddedFFmpegRuntimePath)
    }
    elseif ($fileName -eq "ffprobe.exe" -and $script:EmbeddedFFprobeRuntimePath) {
        [void]$candidates.Add($script:EmbeddedFFprobeRuntimePath)
    }

    try {
        $hostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $hostName = [System.IO.Path]::GetFileNameWithoutExtension($hostExe)
        $exeDir = Split-Path -Parent $hostExe

        if ($hostName -in @("powershell", "powershell_ise", "pwsh")) {
            if ($PSScriptRoot) { [void]$candidates.Add((Join-Path $PSScriptRoot $fileName)) }
        }
        elseif ($exeDir) {
            [void]$candidates.Add((Join-Path $exeDir $fileName))
        }
    } catch {}

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            if (Test-ApprovedTool $candidate $expectedHash $displayName) {
                return [System.IO.Path]::GetFullPath($candidate)
            }
            return $null
        }
    }

    [System.Windows.Forms.MessageBox]::Show(
        "The approved application-local $fileName was not found.`r`n`r`nPut the intended $fileName beside this script (or beside the packaged .exe). TinyRedactionTool will not fall back to a copy found on PATH.",
        "$displayName not found",
        "OK",
        "Error"
    ) | Out-Null
    return $null
}

function Find-FFmpeg {
    return Find-ApprovedMediaTool "ffmpeg.exe" $script:ExpectedFFmpegSha256 "FFmpeg"
}

function Find-FFprobe {
    return Find-ApprovedMediaTool "ffprobe.exe" $script:ExpectedFFprobeSha256 "FFprobe"
}

function SecToText([double]$seconds) {
    $ts = [TimeSpan]::FromSeconds($seconds)
    return "{0:00}:{1:00}:{2:00.000}" -f [math]::Floor($ts.TotalHours), $ts.Minutes, ($ts.Seconds + ($ts.Milliseconds/1000.0))
}

# Implements the Windows/MSVCRT command-line quoting rules, including embedded
# quotes and trailing backslashes. Media processes still use UseShellExecute
# = $false; this only makes .Arguments unambiguous for unusual legal paths.
function Quote-Arg([string]$s) {
    if ($null -eq $s) { return '""' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0
    foreach ($ch in $s.ToCharArray()) {
        if ($ch -eq '\') {
            $slashes++
            continue
        }
        if ($ch -eq '"') {
            if ($slashes -gt 0) { [void]$sb.Append((('\' * ($slashes * 2)) -join '')) }
            [void]$sb.Append('\"')
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) {
            [void]$sb.Append((('\' * $slashes) -join ''))
            $slashes = 0
        }
        [void]$sb.Append($ch)
    }
    if ($slashes -gt 0) { [void]$sb.Append((('\' * ($slashes * 2)) -join '')) }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Get-NetworkPathReason([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    try {
        $full = [System.IO.Path]::GetFullPath($path)
    }
    catch {
        $full = $path
    }

    if ($full.StartsWith('\\') -or $full.StartsWith('\\?\UNC\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return "UNC/network path"
    }

    try {
        $root = [System.IO.Path]::GetPathRoot($full)
        if ($root -and $root -match '^[A-Za-z]:\\$') {
            $drive = New-Object System.IO.DriveInfo($root)
            if ($drive.DriveType -eq [System.IO.DriveType]::Network) {
                return "mapped network drive"
            }
        }
    } catch {}
    return $null
}

function Get-SafeFFmpegError([string]$text, [string]$sensitivePath) {
    if ([string]::IsNullOrWhiteSpace($text)) { return "FFmpeg reported an error." }
    $safe = $text
    if (-not [string]::IsNullOrWhiteSpace($sensitivePath)) {
        $safe = $safe.Replace($sensitivePath, "[source media]")
    }
    $safe = $safe.Trim()
    if ($safe.Length -gt 1600) { $safe = $safe.Substring(0,1600) + "..." }
    return $safe
}

function Get-FrameTimingMap($ffprobe, [string]$path) {
    # SECURITY: enumerate the actual presentation timing of every decoded frame
    # with the trusted embedded FFprobe. Keep only compact typed arrays in
    # memory; do not materialize a huge JSON object or write timing data to disk.
    # This is the timing authority for both CFR and VFR video. A source is
    # accepted only when this complete map can be established and independently
    # reconciled with a full FFmpeg decode pass.
    $result = @{
        Ok = $false; Error = ""; FrameCount = 0; Duration = 0.0; AverageFps = 0.0
        FirstPresentationTime = 0.0; LastPresentationTime = 0.0
        NominalInterval = 0.0; HasVariableIntervals = $false
        Timestamps = $null; Times = $null; Durations = $null; KeyFrames = $null
    }

    if ([string]::IsNullOrWhiteSpace($ffprobe) -or -not (Test-Path -LiteralPath $ffprobe)) {
        $result.Error = "The trusted FFprobe executable is unavailable."
        return $result
    }

    # Bound memory use. Two million frames is already more than 18 hours at
    # 30 fps (or more than 9 hours at 60 fps). Sources beyond this deliberate
    # safety bound fail closed rather than risking runaway process memory.
    $maxFrames = 2000000
    $timestamps = [System.Collections.Generic.List[System.Int64]]::new()
    $rawTimes = [System.Collections.Generic.List[System.Double]]::new()
    $reportedDurations = [System.Collections.Generic.List[System.Double]]::new()
    $keyFrames = [System.Collections.Generic.List[System.Byte]]::new()

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffprobe
    $psi.Arguments = "-hide_banner -v error -select_streams v:0 -show_frames -show_entries frame=best_effort_timestamp,best_effort_timestamp_time,duration_time,key_frame -of compact=p=0:nk=0 -i " + (Quote-Arg $path)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $p = $null
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $stderrTask = $p.StandardError.ReadToEndAsync()
        $parseError = $null
        $lineNumber = 0

        while (($line = $p.StandardOutput.ReadLine()) -ne $null) {
            $lineNumber++
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            if ($line.Length -gt 4096) {
                $parseError = "FFprobe returned an unexpectedly long frame-timing record."
                try { $p.Kill() } catch {}
                break
            }

            $fields = @{}
            foreach ($part in $line.Split('|')) {
                $eq = $part.IndexOf('=')
                if ($eq -le 0) { continue }
                $fields[$part.Substring(0,$eq)] = $part.Substring($eq + 1)
            }

            if (-not $fields.ContainsKey('best_effort_timestamp') -or
                -not $fields.ContainsKey('best_effort_timestamp_time') -or
                -not $fields.ContainsKey('key_frame')) {
                $parseError = "FFprobe returned a frame without the required presentation-timing fields."
                try { $p.Kill() } catch {}
                break
            }

            $pts = [int64]0
            $time = [double]0.0
            $key = [int]0
            if (-not [int64]::TryParse($fields['best_effort_timestamp'], [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$pts) -or
                -not [double]::TryParse($fields['best_effort_timestamp_time'], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$time) -or
                -not [int]::TryParse($fields['key_frame'], [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$key) -or
                [double]::IsNaN($time) -or [double]::IsInfinity($time) -or
                ($key -ne 0 -and $key -ne 1)) {
                $parseError = "FFprobe returned an unusable frame presentation timestamp."
                try { $p.Kill() } catch {}
                break
            }

            # FFmpeg filter expressions evaluate numeric operands as doubles.
            # Keep raw PTS values inside the exact IEEE-754 integer range so the
            # exact-preview selector eq(pts,target) cannot round to a neighbour.
            $maxExactPts = [int64]9007199254740991
            if ($pts -gt $maxExactPts -or $pts -lt (-1 * $maxExactPts)) {
                $parseError = "A frame timestamp is too large for exact FFmpeg frame selection."
                try { $p.Kill() } catch {}
                break
            }

            if ($rawTimes.Count -gt 0) {
                $lastIndex = $rawTimes.Count - 1
                if ($time -le $rawTimes[$lastIndex] -or $pts -le $timestamps[$lastIndex]) {
                    $parseError = "Frame presentation timestamps are not strictly increasing, so a unique frame-to-time mapping cannot be established safely."
                    try { $p.Kill() } catch {}
                    break
                }
            }

            $reportedDuration = [double]::NaN
            if ($fields.ContainsKey('duration_time') -and
                -not [string]::IsNullOrWhiteSpace($fields['duration_time']) -and
                $fields['duration_time'] -ne 'N/A') {
                $parsedDuration = [double]0.0
                if ([double]::TryParse($fields['duration_time'], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedDuration) -and
                    -not [double]::IsNaN($parsedDuration) -and -not [double]::IsInfinity($parsedDuration) -and
                    $parsedDuration -gt 0.0) {
                    $reportedDuration = $parsedDuration
                }
            }

            $timestamps.Add($pts)
            $rawTimes.Add($time)
            $reportedDurations.Add($reportedDuration)
            $keyFrames.Add([byte]$key)

            if ($timestamps.Count -gt $maxFrames) {
                $parseError = "The video contains too many frames to build the timing map within the application's safety memory bound."
                try { $p.Kill() } catch {}
                break
            }

            if (($lineNumber % 250) -eq 0) {
                [System.Windows.Forms.Application]::DoEvents()
            }
        }

        $p.WaitForExit()
        $stderrTask.Wait(2000) | Out-Null
        $stderr = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }

        if ($parseError) {
            $result.Error = $parseError
            return $result
        }
        if ($p.ExitCode -ne 0) {
            $safeProbeError = if ([string]::IsNullOrWhiteSpace($stderr)) { "FFprobe reported an error." } else { Get-SafeFFmpegError $stderr $path }
            $result.Error = "FFprobe could not enumerate video frame timing. " + $safeProbeError
            return $result
        }
        if ($timestamps.Count -le 0) {
            $result.Error = "FFprobe returned no video frames, so frame timing cannot be established safely."
            return $result
        }

        $count = $timestamps.Count
        $firstTime = $rawTimes[0]
        $lastTime = $rawTimes[$count - 1]
        $nominalInterval = 0.0
        if ($count -gt 1) {
            $nominalInterval = ($lastTime - $firstTime) / [double]($count - 1)
            if ($nominalInterval -le 0.0 -or [double]::IsNaN($nominalInterval) -or [double]::IsInfinity($nominalInterval)) {
                $result.Error = "The frame timing map does not contain a usable presentation interval."
                return $result
            }
        }

        $relativeTimes = [System.Collections.Generic.List[System.Double]]::new()
        $durations = [System.Collections.Generic.List[System.Double]]::new()
        $hasVariableIntervals = $false
        $intervalTolerance = if ($nominalInterval -gt 0.0) { [Math]::Max(0.00005, $nominalInterval * 0.002) } else { 0.00005 }

        for ($i = 0; $i -lt $count; $i++) {
            $relative = $rawTimes[$i] - $firstTime
            if ($relative -lt 0.0 -or [double]::IsNaN($relative) -or [double]::IsInfinity($relative)) {
                $result.Error = "The frame timing map could not be normalized safely."
                return $result
            }
            $relativeTimes.Add($relative)

            if ($i -lt ($count - 1)) {
                $frameDuration = $rawTimes[$i + 1] - $rawTimes[$i]
                if ($frameDuration -le 0.0) {
                    $result.Error = "The frame timing map contains a non-positive presentation interval."
                    return $result
                }
                if ($nominalInterval -gt 0.0 -and [Math]::Abs($frameDuration - $nominalInterval) -gt $intervalTolerance) {
                    $hasVariableIntervals = $true
                }
                $durations.Add($frameDuration)
            }
            else {
                $lastDuration = $reportedDurations[$i]
                if ([double]::IsNaN($lastDuration) -or [double]::IsInfinity($lastDuration) -or $lastDuration -le 0.0) {
                    $lastDuration = $nominalInterval
                }
                if ($lastDuration -le 0.0 -or [double]::IsNaN($lastDuration) -or [double]::IsInfinity($lastDuration)) {
                    $result.Error = "The final frame duration could not be established safely."
                    return $result
                }
                if ($nominalInterval -gt 0.0 -and [Math]::Abs($lastDuration - $nominalInterval) -gt $intervalTolerance) {
                    $hasVariableIntervals = $true
                }
                $durations.Add($lastDuration)
            }
        }

        $duration = ($lastTime - $firstTime) + $durations[$count - 1]
        if ($duration -le 0.0 -or [double]::IsNaN($duration) -or [double]::IsInfinity($duration)) {
            $result.Error = "The video duration could not be established from the frame timing map."
            return $result
        }

        $averageFps = [double]$count / $duration
        if ($averageFps -le 0.0 -or [double]::IsNaN($averageFps) -or [double]::IsInfinity($averageFps)) {
            $result.Error = "The frame timing map produced an invalid average frame rate."
            return $result
        }

        $result.FrameCount = $count
        $result.Duration = $duration
        $result.AverageFps = $averageFps
        $result.FirstPresentationTime = $firstTime
        $result.LastPresentationTime = $relativeTimes[$count - 1]
        $result.NominalInterval = $nominalInterval
        $result.HasVariableIntervals = $hasVariableIntervals
        $result.Timestamps = $timestamps.ToArray()
        $result.Times = $relativeTimes.ToArray()
        $result.Durations = $durations.ToArray()
        $result.KeyFrames = $keyFrames.ToArray()
        $result.Ok = $true
        return $result
    }
    catch {
        $result.Error = "The trusted frame timing map could not be established."
        return $result
    }
    finally {
        if ($p) { $p.Dispose() }
    }
}

# Secure media preflight. Dimensions are taken from an explicitly autorotated
# decoded frame held only in memory, so the UI and export filter graph use the
# same display-coordinate space even when the source carries a rotation matrix.
# For video, trusted FFprobe establishes the complete presentation-timing map;
# a separate full FFmpeg decode pass must then report exactly the same number of
# decoded frames. VFR is accepted only through that validated/reconciled model.
function Get-VideoInfo($ffmpeg, $ffprobe, $path, [bool]$imageMode = $false) {
    $info = @{
        Width = 0; Height = 0; Duration = 0.0; Fps = 0.0; FrameCount = 0
        HasAudio = $false; IsSafe = $false; IsVfr = $false; Error = ""
        FrameTimeline = $null
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = "-hide_banner -nostdin -loglevel error -autorotate -i " + (Quote-Arg $path) + " -map 0:v:0 -frames:v 1 -f image2pipe -vcodec png pipe:1"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $ms = New-Object System.IO.MemoryStream
        $copyTask = $p.StandardOutput.BaseStream.CopyToAsync($ms)
        $stderrTask = $p.StandardError.ReadToEndAsync()
        $copyTask.GetAwaiter().GetResult()
        $p.WaitForExit()
        $stderrTask.Wait(1000) | Out-Null
        $frameErr = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }
        $bytes = $ms.ToArray()
        $ms.Dispose()

        if ($p.ExitCode -ne 0 -or $bytes.Length -eq 0) {
            $info.Error = "FFmpeg could not decode the first video/image frame. " + (Get-SafeFFmpegError $frameErr $path)
            return $info
        }

        $imgStream = New-Object System.IO.MemoryStream(,$bytes)
        try {
            $img = [System.Drawing.Image]::FromStream($imgStream)
            $info.Width = $img.Width
            $info.Height = $img.Height
            $img.Dispose()
        }
        finally {
            $imgStream.Dispose()
        }
    }
    catch {
        $info.Error = "The media preflight could not decode the first frame."
        return $info
    }

    if ($imageMode) {
        $info.Duration = 0.0
        $info.Fps = 1.0
        $info.FrameCount = 1
        $info.IsSafe = $true
        return $info
    }

    # SECURITY: native VFR support is fail-closed. FFprobe's complete frame map
    # is authoritative for logical frame identity and timing; failure to build a
    # strict, usable map rejects the source rather than falling back to fps math.
    $timing = Get-FrameTimingMap $ffprobe $path
    if (-not $timing.Ok) {
        $info.Error = "The video's frame timing could not be established safely. " + $timing.Error
        return $info
    }
    $info.FrameTimeline = $timing

    # Independent reconciliation: fully decode the selected video stream with
    # trusted FFmpeg and count decoded frames. No decoded media is written to
    # disk; wrapped_avframe is discarded by the null muxer.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = "-progress pipe:1 -hide_banner -nostdin -nostats -loglevel info -autorotate -i " + (Quote-Arg $path) + " -map 0:v:0 -an -sn -dn -c:v wrapped_avframe -fps_mode:v:0 passthrough -enc_time_base:v:0 filter -f null NUL"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $stdoutTask = $p.StandardOutput.ReadToEndAsync()
        $stderrTask = $p.StandardError.ReadToEndAsync()
        while (-not $p.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 30
        }
        $p.WaitForExit()
        $stdoutTask.Wait(2000) | Out-Null
        $stderrTask.Wait(2000) | Out-Null
        $progressText = if ($stdoutTask.IsCompleted) { $stdoutTask.Result } else { "" }
        $probeText = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }

        if ($p.ExitCode -ne 0) {
            $info.Error = "FFmpeg could not complete the frame-identity reconciliation pass. " + (Get-SafeFFmpegError $probeText $path)
            return $info
        }

        $info.HasAudio = [bool]($probeText -match '(?m)^\s*Stream #\d+:\d+.*Audio:')

        $frameMatches = [regex]::Matches($progressText, '(?m)^frame=(\d+)\s*$')
        if ($frameMatches.Count -eq 0) {
            $info.Error = "FFmpeg did not return a reliable decoded-frame count. The file was not opened."
            return $info
        }

        $frameCount = [int64]$frameMatches[$frameMatches.Count - 1].Groups[1].Value
        if ($frameCount -le 0) {
            $info.Error = "The video's decoded-frame count could not be established safely."
            return $info
        }

        if ([int64]$timing.FrameCount -ne $frameCount) {
            $info.Error = "FFprobe and FFmpeg reported different decoded frame counts. The file was not opened because frame identity cannot be reconciled safely."
            return $info
        }

        $info.FrameCount = $frameCount
        $info.Duration = [double]$timing.Duration
        $info.Fps = [double]$timing.AverageFps   # informational average only
        $info.IsVfr = [bool]$timing.HasVariableIntervals
        if ($info.Duration -le 0 -or $info.Fps -le 0 -or
            [double]::IsNaN($info.Duration) -or [double]::IsInfinity($info.Duration) -or
            [double]::IsNaN($info.Fps) -or [double]::IsInfinity($info.Fps)) {
            $info.Error = "The validated frame timeline did not produce usable duration/rate information."
            return $info
        }

        $probeText = $null
        $progressText = $null
        $info.IsSafe = $true
        return $info
    }
    catch {
        $info.Error = "The video frame-identity reconciliation check failed."
        return $info
    }
}

function Get-OutputInspection($ffprobe, [string]$path) {
    $result = @{
        Ok = $false; Error = ""; VideoCount = 0; AudioCount = 0; SubtitleCount = 0
        DataCount = 0; AttachmentCount = 0; ChapterCount = 0
        Width = 0; Height = 0; Duration = 0.0; MetadataKeys = @()
    }

    # SECURITY: this function is part of the post-export commit gate. Use
    # ffprobe's structured JSON rather than regexing FFmpeg's human-readable
    # -i banner, so a formatting change cannot silently turn into a false pass.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffprobe
    $psi.Arguments = "-v error -show_streams -show_chapters -show_format -of json " + (Quote-Arg $path)
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $stdoutTask = $p.StandardOutput.ReadToEndAsync()
        $stderrTask = $p.StandardError.ReadToEndAsync()
        $p.WaitForExit()
        $stdoutTask.Wait(2000) | Out-Null
        $stderrTask.Wait(2000) | Out-Null

        $jsonText = if ($stdoutTask.IsCompleted) { $stdoutTask.Result } else { "" }
        $probeErr = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }

        if ($p.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($jsonText)) {
            $result.Error = "The exported file could not be inspected by FFprobe. " + (Get-SafeFFmpegError $probeErr $path)
            return $result
        }

        try {
            $probe = $jsonText | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            $result.Error = "FFprobe returned malformed structured inspection data."
            return $result
        }
    }
    catch {
        $result.Error = "The exported file could not be inspected by FFprobe."
        return $result
    }

    # ConvertFrom-Json in Windows PowerShell 5.1 may represent a single item
    # differently from an array, so always force collection semantics here.
    $streams = @($probe.streams)
    foreach ($stream in $streams) {
        switch ([string]$stream.codec_type) {
            "video"      { $result.VideoCount++ }
            "audio"      { $result.AudioCount++ }
            "subtitle"   { $result.SubtitleCount++ }
            "data"       { $result.DataCount++ }
            "attachment" { $result.AttachmentCount++ }
        }
    }

    $result.ChapterCount = @($probe.chapters).Count

    $videoStreams = @($streams | Where-Object { $_.codec_type -eq "video" })
    if ($videoStreams.Count -gt 0) {
        $firstVideo = $videoStreams[0]
        if ($null -ne $firstVideo.width)  { $result.Width = [int]$firstVideo.width }
        if ($null -ne $firstVideo.height) { $result.Height = [int]$firstVideo.height }
    }

    # Prefer the container duration; fall back to the first video stream only
    # if the muxer does not expose a format duration. Images legitimately have
    # no useful duration and are handled separately by Test-ExportSecurity.
    $durationValue = $null
    if ($probe.format -and $null -ne $probe.format.duration) {
        $durationValue = [string]$probe.format.duration
    }
    if (($null -eq $durationValue -or $durationValue -eq "" -or $durationValue -eq "N/A") -and $videoStreams.Count -gt 0) {
        if ($null -ne $videoStreams[0].duration) { $durationValue = [string]$videoStreams[0].duration }
    }
    if ($durationValue -and $durationValue -ne "N/A") {
        $parsedDuration = 0.0
        if ([double]::TryParse($durationValue, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedDuration)) {
            $result.Duration = $parsedDuration
        }
    }

    # Inspect global, stream and chapter tag *keys*. After -map_metadata -1 /
    # -map_metadata:s -1 / -map_chapters -1, only explicitly allowed muxer or
    # encoder housekeeping may remain. Any unfamiliar key fails closed later.
    $keys = New-Object System.Collections.Generic.List[string]
    function Add-InspectionTagKeys($tags) {
        if ($null -eq $tags) { return }
        foreach ($prop in $tags.PSObject.Properties) {
            $name = [string]$prop.Name
            if (-not [string]::IsNullOrWhiteSpace($name) -and -not $keys.Contains($name)) {
                [void]$keys.Add($name)
            }
        }
    }

    if ($probe.format) { Add-InspectionTagKeys $probe.format.tags }
    foreach ($stream in $streams) { Add-InspectionTagKeys $stream.tags }
    foreach ($chapter in @($probe.chapters)) { Add-InspectionTagKeys $chapter.tags }

    $result.MetadataKeys = @($keys)
    $result.Ok = ($result.VideoCount -gt 0)
    if (-not $result.Ok) {
        $result.Error = "No readable video/image stream was found in the exported file."
    }

    # Drop the structured inspection object after extracting the required
    # security properties. TinyRedactionTool does not persist the JSON.
    $probe = $null
    $jsonText = $null
    return $result
}

function Test-ExportSecurity($ffmpeg, $ffprobe, [string]$path, [bool]$imageMode, [bool]$expectAudio, [int]$expectedWidth, [int]$expectedHeight, [double]$expectedDuration, $expectedTimeline) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return @{ Ok = $false; Error = "The temporary export was not created." }
    }
    try {
        if ((Get-Item -LiteralPath $path -ErrorAction Stop).Length -le 0) {
            return @{ Ok = $false; Error = "The temporary export is empty." }
        }
    } catch {
        return @{ Ok = $false; Error = "The temporary export could not be read." }
    }

    $inspect = Get-OutputInspection $ffprobe $path
    if (-not $inspect.Ok) { return @{ Ok = $false; Error = $inspect.Error } }
    if ($inspect.VideoCount -ne 1) { return @{ Ok = $false; Error = "Validation found an unexpected number of video/image streams." } }
    if ($inspect.SubtitleCount -ne 0 -or $inspect.DataCount -ne 0 -or $inspect.AttachmentCount -ne 0) {
        return @{ Ok = $false; Error = "Validation found an unexpected subtitle, data or attachment stream." }
    }
    if ($inspect.ChapterCount -ne 0) { return @{ Ok = $false; Error = "Validation found chapter metadata in the export." } }

    $expectedAudioCount = if ($expectAudio) { 1 } else { 0 }
    if ($inspect.AudioCount -ne $expectedAudioCount) {
        return @{ Ok = $false; Error = "Validation found an unexpected audio-stream state." }
    }
    if ($inspect.Width -ne $expectedWidth -or $inspect.Height -ne $expectedHeight) {
        return @{ Ok = $false; Error = "Validation found unexpected output dimensions ($($inspect.Width)x$($inspect.Height))." }
    }

    # Allow only muxer/encoder bookkeeping that FFmpeg itself generates after
    # metadata stripping. Anything else fails closed rather than guessing
    # whether an unfamiliar tag might have originated in the patient source.
    $allowedMetadata = @(
        'major_brand','minor_version','compatible_brands','encoder','handler_name',
        'vendor_id','duration','language','software'
    )
    foreach ($key in $inspect.MetadataKeys) {
        if ($allowedMetadata -notcontains $key.ToLowerInvariant()) {
            return @{ Ok = $false; Error = "Validation found unexpected metadata key '$key'." }
        }
    }

    if (-not $imageMode) {
        $tol = [Math]::Max(1.0, $expectedDuration * 0.02)
        if ($inspect.Duration -le 0 -or [Math]::Abs($inspect.Duration - $expectedDuration) -gt $tol) {
            return @{ Ok = $false; Error = "Validation found an implausible output duration." }
        }

        # SECURITY: a successful encode is not enough. Re-enumerate the actual
        # decoded output frames with trusted FFprobe and reconcile them against
        # the already-validated source timeline. This detects silent CFR
        # conversion, frame duplication/drop, or timestamp distortion before a
        # .partial file is promoted to the user's destination. Both timelines
        # are normalized to their first presentation timestamp by
        # Get-FrameTimingMap, so harmless container start-time offsets do not
        # affect the comparison.
        if (-not $expectedTimeline -or -not $expectedTimeline.Ok -or
            -not $expectedTimeline.Times -or -not $expectedTimeline.Durations -or
            [int64]$expectedTimeline.FrameCount -le 0) {
            return @{ Ok = $false; Error = "The validated source frame timeline is unavailable for export verification." }
        }

        $actualTimeline = Get-FrameTimingMap $ffprobe $path
        if (-not $actualTimeline.Ok) {
            return @{ Ok = $false; Error = "Validation could not establish the exported frame timeline safely. $($actualTimeline.Error)" }
        }
        if ([int64]$actualTimeline.FrameCount -ne [int64]$expectedTimeline.FrameCount) {
            return @{ Ok = $false; Error = "Validation found a frame-count mismatch between source and export." }
        }

        $nominal = [double]$expectedTimeline.NominalInterval
        # WebM commonly represents timestamps at millisecond resolution, while
        # MP4 may use a finer timescale. Allow only a small muxer-quantization
        # tolerance; this is intentionally far tighter than one video frame.
        $timeTolerance = if ($nominal -gt 0.0) {
            [Math]::Max(0.0015, [Math]::Min(0.005, $nominal * 0.02))
        } else { 0.0015 }

        for ($i = 0; $i -lt [int]$expectedTimeline.FrameCount; $i++) {
            $expectedTime = [double]$expectedTimeline.Times[$i]
            $actualTime = [double]$actualTimeline.Times[$i]
            if ([Math]::Abs($actualTime - $expectedTime) -gt $timeTolerance) {
                return @{ Ok = $false; Error = "Validation found altered presentation timing at output frame $i." }
            }
        }

        # Do not compare Get-FrameTimingMap.Duration here: after H.264
        # encoding FFprobe may report a nominal per-frame duration on the final
        # decoded frame even when the container/video duration and every actual
        # presentation timestamp are correct. Frame count + every normalized
        # frame start are the unambiguous invariants. Container duration is
        # validated separately above.
    }

    # Decode one frame from the newly generated (already-redacted) file. This
    # is intentionally lightweight; exact colour-byte comparison would give a
    # false sense of security on lossy codecs because compression alters solid
    # colours slightly around block/edge boundaries.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = "-hide_banner -nostdin -loglevel error -i " + (Quote-Arg $path) + " -map 0:v:0 -frames:v 1 -an -sn -dn -c:v wrapped_avframe -f null NUL"
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $decodeErr = $p.StandardError.ReadToEnd()
        $null = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) {
            return @{ Ok = $false; Error = "Validation could not decode the exported video/image stream." }
        }
    }
    catch {
        return @{ Ok = $false; Error = "Validation could not decode the exported video/image stream." }
    }

    return @{ Ok = $true; Error = "" }
}

# Maps the user-facing 1-10 Blur/Pixelate strength slider to the actual
# parameters each effect uses under the hood. Each table's index-5 (strength
# 5, the slider's default position) reproduces this app's original hardcoded
# constant, so anyone who never touches the slider sees the exact same result
# as before - the slider only ever makes the effect adjustable, not different
# by default.
#
# Get-BlurRadiusTarget: target luma radius fed into Get-SafeBoxBlurSpec below
# (used for the real FFmpeg export). It's a *target* rather than the radius
# actually used, since Get-SafeBoxBlurSpec still has to clamp it down for
# small redaction boxes where a large radius isn't legal.
function Get-BlurRadiusTarget([int]$strength) {
    # Re-based so the slider's default (5) hides text far more reliably on
    # high-resolution images: every position now maps to what used to sit
    # 3 notches higher (old position 8's radius, 26, is the new position 5;
    # old position 5's radius, 12, is the new position 2), and positions 8-10
    # extend the same growth curve past the old table's ceiling of 42.
    $table = @(10,12,16,20,26,33,42,54,68,86)
    $idx = [Math]::Max(1, [Math]::Min(10, $strength)) - 1
    return $table[$idx]
}

# Get-PixelateDivisor: how many times smaller the redaction box is shrunk
# before being scaled back up with nearest-neighbor interpolation - a bigger
# divisor means bigger, chunkier blocks (stronger pixelation). Shared by both
# the real FFmpeg export (Build-RedactionFilterComplex) and the live image
# preview (Get-LiveEffectPatch) so what's shown matches what's exported.
function Get-PixelateDivisor([int]$strength) {
    $table = @(6,9,12,15,18,24,30,38,48,60)
    $idx = [Math]::Max(1, [Math]::Min(10, $strength)) - 1
    return $table[$idx]
}

# Get-BlurLiveDivisor: the equivalent shrink-then-bicubic-upscale divisor used
# only by the live image preview's cheap GDI+ blur approximation (there's no
# GDI+ box blur, so this stands in for Get-BlurRadiusTarget's real boxblur on
# that path). Kept as a separate table from Get-PixelateDivisor since the two
# approximations respond differently to the same divisor value.
function Get-BlurLiveDivisor([int]$strength) {
    # Shifted by the same 3 notches as Get-BlurRadiusTarget above, so the
    # live GDI+ preview keeps tracking the strengthened real boxblur curve
    # position-for-position.
    $table = @(8,10,13,16,20,25,30,38,46,58)
    $idx = [Math]::Max(1, [Math]::Min(10, $strength)) - 1
    return $table[$idx]
}

# FFmpeg's boxblur limits the radius independently for the luma and chroma
# planes. With common 4:2:0 video, the chroma plane is half-resolution, so a
# fixed radius such as 12 can fail on short/narrow redaction boxes even though
# the same radius is valid for the luma plane.
#
# Build a visually equivalent blur specification whose radii are automatically
# clamped to values that are legal for the current crop size. $targetRadius
# is normally the output of Get-BlurRadiusTarget above (defaults to the
# original hardcoded 12 so existing callers/tests are unaffected).
function Get-SafeBoxBlurSpec([int]$w, [int]$h, [int]$targetRadius = 12) {
    $minDim = [Math]::Max(2, [Math]::Min($w, $h))

    # Luma radius must be <= min(luma_w,luma_h)/2.
    $lumaMax = [Math]::Max(0, [int][Math]::Floor(($minDim - 1) / 2.0))
    $lumaRadius = [Math]::Min($targetRadius, $lumaMax)

    # For the common yuv420p input format, chroma dimensions are approximately
    # half the luma dimensions, making the legal chroma radius approximately
    # one quarter of the smallest crop dimension. Using this conservative
    # value is also harmless for formats with higher chroma resolution.
    $chromaMax = [Math]::Max(0, [int][Math]::Floor(($minDim - 1) / 4.0))
    $chromaRadius = [Math]::Min($lumaRadius, $chromaMax)

    return "boxblur=luma_radius=$lumaRadius`:luma_power=2`:chroma_radius=$chromaRadius`:chroma_power=2"
}
 
# Builds the -filter_complex string (and the name of the final video label to map)
# for an ordered list of redaction entries. Kept free of any WinForms dependency so
# it can be exercised by a plain script for testing.
#
# $redactionList entries with Shape "Rectangle" (or no Shape at all, for safety)
# use the original rectangle-only drawbox/crop+overlay approach - unchanged from
# earlier versions, and does not need a mask file.
#
# Entries with Shape "Oval" or "Polygon" need a per-redaction mask image (same
# W x H as the entry's bounding box, already rendered to disk by the caller via
# New-ShapeMaskFile - this function is only handed the resulting file *paths*,
# so it stays free of any System.Drawing dependency and can be tested with fake
# paths that don't need to exist). Each such entry consumes one extra ffmpeg
# input; $maskPaths must contain a path for every non-rectangular index.
#   - "Black box": the mask is a real RGBA PNG (transparent background, solid
#     opaque black shape) and is overlaid directly - no need to sample the
#     original frame content.
#   - "Blur"/"Pixelate": the mask is a plain white-shape-on-black PNG. The
#     usual crop+effect patch is generated exactly as for rectangles, then
#     `alphamerge` copies the mask's luma in as that patch's alpha channel
#     before it's overlaid, so only the shape (not its bounding box) actually
#     changes in the output.
function Build-RedactionFilterComplex($redactionList, $maskPaths) {
    if (-not $maskPaths) { $maskPaths = @{} }
 
    $filterParts = New-Object System.Collections.Generic.List[string]
    $maskInputArgs = New-Object System.Collections.Generic.List[string]
    $cur = "0:v"
    $nextInputIndex = 1
 
    for ($i = 0; $i -lt $redactionList.Count; $i++) {
        $r = $redactionList[$i]
        $x = $r.X; $y = $r.Y; $w = $r.W; $h = $r.H
        $startFrame = [int]$r.BufferedStartFrame
        $endFrame = [int]$r.BufferedEndFrame
        if ($startFrame -lt 0 -or $endFrame -lt $startFrame -or
            $script:totalFrames -le 0 -or $endFrame -ge $script:totalFrames) {
            throw "Build-RedactionFilterComplex: invalid buffered frame range."
        }
        # SECURITY: export activation is keyed to the sequential decoded input
        # frame number, not timestamp arithmetic. FFmpeg timeline variable `n`
        # starts at 0, matching TinyRedactionTool's logical FrameIndex exactly.
        # The inclusive buffered frame range therefore cannot leak a boundary
        # frame merely because VFR timestamps or floating-point rounding differ.
        $enable = "between(n\,$startFrame\,$endFrame)"
        $nextLabel = "v$i"
        $isRect = (-not $r.Shape) -or ($r.Shape -eq "Rectangle")
        # Older redactions created before the strength slider existed won't
        # have a Strength field - fall back to 5 (the slider's default/
        # original-behavior position) so they still export exactly as before.
        $strength = if ($r.Strength) { [int]$r.Strength } else { 5 }
        # Likewise, redactions from before the Coloured Box picker existed
        # won't have a Color field - fall back to plain black, matching the
        # original hardcoded "black box" behavior exactly.
        $boxColor = if ($r.Color) { $r.Color } else { [System.Drawing.Color]::Black }
        $colorHex = "0x{0:X2}{1:X2}{2:X2}" -f $boxColor.R, $boxColor.G, $boxColor.B

        if ($isRect) {
            if ($r.Mode -eq "Black box") {
                # NOTE: every "$var:" below is escaped with a backtick. Without the
                # backtick, PowerShell parses "$x:y" as a *scoped variable lookup*
                # (like $env:PATH) instead of "value of $x, then a literal colon",
                # and it silently resolves to an empty string. That bug is what
                # made the original "Black box" export always produce a broken
                # ffmpeg filter graph.
                $filterParts.Add("[$cur]drawbox=x=$x`:y=$y`:w=$w`:h=$h`:color=$colorHex`:t=fill:enable='$enable'[$nextLabel]")
            }
            else {
                $baseLbl = "b$i"; $tmpLbl = "t$i"; $effLbl = "e$i"
                if ($r.Mode -eq "Blur") {
                    $blurSpec = Get-SafeBoxBlurSpec $w $h (Get-BlurRadiusTarget $strength)
                    $eff = "crop=$w`:$h`:$x`:$y,$blurSpec"
                }
                else {
                    $pixelDivisor = Get-PixelateDivisor $strength
                    $smallW = [Math]::Max(8, [int]($w / $pixelDivisor))
                    $smallH = [Math]::Max(8, [int]($h / $pixelDivisor))
                    $eff = "crop=$w`:$h`:$x`:$y,scale=$smallW`:$smallH`:flags=neighbor,scale=$w`:$h`:flags=neighbor"
                }
                $filterParts.Add("[$cur]split[$baseLbl][$tmpLbl]")
                $filterParts.Add("[$tmpLbl]$eff" + "[$effLbl]")
                $filterParts.Add("[$baseLbl][$effLbl]overlay=$x`:$y`:enable='$enable'[$nextLabel]")
            }
        }
        else {
            if (-not $maskPaths.ContainsKey($i)) {
                throw "Build-RedactionFilterComplex: missing mask path for non-rectangular redaction index $i"
            }
            # Using ${...} (rather than a backtick) to delimit the variable name
            # sidesteps the same "$var:" scoped-lookup parsing gotcha noted above -
            # PowerShell stops reading the variable name at the closing brace, so
            # the following ":v]" is treated as plain literal text either way.
            $maskInputIdx = $nextInputIndex
            $maskInputArgs.Add((Quote-Arg $maskPaths[$i]))
            $nextInputIndex++
 
            if ($r.Mode -eq "Black box") {
                $maskFmtLbl = "mf$i"
                $filterParts.Add("[${maskInputIdx}:v]format=rgba[$maskFmtLbl]")
                $filterParts.Add("[$cur][$maskFmtLbl]overlay=$x`:$y`:enable='$enable'[$nextLabel]")
            }
            else {
                $baseLbl = "b$i"; $tmpLbl = "t$i"; $effLbl = "e$i"; $mergedLbl = "m$i"
                if ($r.Mode -eq "Blur") {
                    $blurSpec = Get-SafeBoxBlurSpec $w $h (Get-BlurRadiusTarget $strength)
                    $eff = "crop=$w`:$h`:$x`:$y,$blurSpec"
                }
                else {
                    $pixelDivisor = Get-PixelateDivisor $strength
                    $smallW = [Math]::Max(8, [int]($w / $pixelDivisor))
                    $smallH = [Math]::Max(8, [int]($h / $pixelDivisor))
                    $eff = "crop=$w`:$h`:$x`:$y,scale=$smallW`:$smallH`:flags=neighbor,scale=$w`:$h`:flags=neighbor"
                }
                $filterParts.Add("[$cur]split[$baseLbl][$tmpLbl]")
                $filterParts.Add("[$tmpLbl]$eff" + "[$effLbl]")
                $filterParts.Add("[$effLbl][${maskInputIdx}:v]alphamerge[$mergedLbl]")
                $filterParts.Add("[$baseLbl][$mergedLbl]overlay=$x`:$y`:enable='$enable'[$nextLabel]")
            }
        }
        $cur = $nextLabel
    }
 
    return @{ FilterComplex = [string]::Join(";", $filterParts); FinalLabel = $cur; MaskInputArgs = $maskInputArgs }
}
 
# Clamps/normalizes a raw video-space rectangle: keeps it inside the frame and
# forces even width/height (required by yuv420p and several filters). x/y are
# only ever rounded *down* (never shrinking the box away from its top-left
# content) and w/h are rounded *up* when there's room to do so (never shrinking
# the box away from its bottom-right content) - so the normalized box always
# fully contains the raw one. That matters most for polygons: every polygon
# point must land inside its own bounding-box mask image, or it gets clipped.
function Normalize-VideoRect([double]$x, [double]$y, [double]$w, [double]$h) {
    $x = [int][Math]::Floor($x)
    $y = [int][Math]::Floor($y)
    $w = [int][Math]::Ceiling($w)
    $h = [int][Math]::Ceiling($h)
 
    $x = [Math]::Max(0, [Math]::Min($x, $videoWidth - 2))
    $y = [Math]::Max(0, [Math]::Min($y, $videoHeight - 2))
    $w = [Math]::Max(2, [Math]::Min($w, $videoWidth - $x))
    $h = [Math]::Max(2, [Math]::Min($h, $videoHeight - $y))
 
    if ($x % 2 -ne 0) { $x -= 1 }
    if ($y % 2 -ne 0) { $y -= 1 }
    if ($w % 2 -ne 0) {
        if ($x + $w + 1 -le $videoWidth) { $w += 1 } else { $w -= 1 }
    }
    if ($h % 2 -ne 0) {
        if ($y + $h + 1 -le $videoHeight) { $h += 1 } else { $h -= 1 }
    }
    if ($w -lt 2) { $w = 2 }
    if ($h -lt 2) { $h = 2 }
 
    return @{ X = $x; Y = $y; W = $w; H = $h }
}
 
# Given a drag delta (in whatever coordinate space the caller uses) and whether
# Shift-constrain is active, returns a delta with equal magnitude on both axes
# (preserving each axis's original direction) so a dragged Rectangle becomes a
# square and a dragged Oval becomes a circle. Pure math - no controls involved.
function Get-ConstrainedDelta([double]$dx, [double]$dy, [bool]$constrain) {
    if (-not $constrain) { return @{ Dx = $dx; Dy = $dy } }
 
    $side = [Math]::Max([Math]::Abs($dx), [Math]::Abs($dy))
    $sx = if ($dx -lt 0) { -1 } else { 1 }
    $sy = if ($dy -lt 0) { -1 } else { 1 }
    return @{ Dx = $side * $sx; Dy = $side * $sy }
}
 
# Creates an export-only copy of the redaction list. Secure opaque redactions
# are expanded by one pixel on each available side as a small safety margin;
# the on-screen selection and stored user geometry remain unchanged.
function Get-ExportRedactionList($sourceList) {
    $margin = 1
    $list = New-Object System.Collections.ArrayList
    foreach ($r in $sourceList) {
        $x = [int]$r.X; $y = [int]$r.Y; $w = [int]$r.W; $h = [int]$r.H
        if ($r.Mode -eq "Black box") {
            $right = [Math]::Min($videoWidth, $x + $w + $margin)
            $bottomEdge = [Math]::Min($videoHeight, $y + $h + $margin)
            $x = [Math]::Max(0, $x - $margin)
            $y = [Math]::Max(0, $y - $margin)
            $w = $right - $x
            $h = $bottomEdge - $y
        }
        $copy = [PSCustomObject]@{
            Shape = $r.Shape
            X = $x; Y = $y; W = $w; H = $h
            Points = $r.Points
            Mode = $r.Mode
            Strength = $r.Strength
            Color = $r.Color
            # Logical frame indexes are the sole export timing authority.
            # Display timestamps stay on the UI redaction objects but are not
            # copied into this export-only structure, preventing an accidental
            # return to second/fps-based filter activation.
            StartFrame = [int]$r.StartFrame
            EndFrame = [int]$r.EndFrame
            BufferedStartFrame = [int]$r.BufferedStartFrame
            BufferedEndFrame = [int]$r.BufferedEndFrame
        }
        [void]$list.Add($copy)
    }
    return ,$list
}

# Given a candidate freeform (Polygon) point and the previous vertex already
# placed, returns a point at the same distance from $from but with its angle
# snapped to the nearest 0/45/90 degree step (measured from $from), whenever
# $constrain is true. Mirrors how Get-ConstrainedDelta above locks a
# Rectangle/Oval drag to a square/circle when Shift is held - this is the
# freeform-tool equivalent, snapping each new segment to a horizontal,
# vertical, or 45-degree diagonal instead. Pure math - no controls involved.
function Get-AngleSnappedPoint([System.Drawing.Point]$from, [System.Drawing.Point]$to, [bool]$constrain) {
    if (-not $constrain) { return $to }
 
    $dx = $to.X - $from.X
    $dy = $to.Y - $from.Y
    $dist = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
    if ($dist -lt 1) { return $to }
 
    $angle = [Math]::Atan2($dy, $dx)
    $step = [Math]::PI / 4.0
    $snapped = [Math]::Round($angle / $step) * $step
 
    $nx = $from.X + [int][Math]::Round([Math]::Cos($snapped) * $dist)
    $ny = $from.Y + [int][Math]::Round([Math]::Sin($snapped) * $dist)
    return New-Object System.Drawing.Point($nx, $ny)
}

# Standard ray-casting point-in-polygon test, used to decide whether a click
# on a closed-but-uncommitted freeform shape should start moving it (see
# $movingShape below) rather than starting a brand new path. Points are
# display-space, same as $polygonPoints itself.
function Test-PointInPolygon([System.Drawing.Point]$pt, $polyPoints) {
    $inside = $false
    $n = $polyPoints.Count
    $j = $n - 1
    for ($i = 0; $i -lt $n; $i++) {
        $pi = $polyPoints[$i]; $pj = $polyPoints[$j]
        if ((($pi.Y -gt $pt.Y) -ne ($pj.Y -gt $pt.Y)) -and
            ($pt.X -lt (($pj.X - $pi.X) * ($pt.Y - $pi.Y) / ($pj.Y - $pi.Y) + $pi.X))) {
            $inside = -not $inside
        }
        $j = $i
    }
    return $inside
}

# Bounding box (display-space) of a set of points - used to clamp a Polygon
# move so the whole shape stays within the displayed image, the same way a
# Rectangle/Oval move clamps against $moveOrigSelection directly.
function Get-PointsBoundingRect($points) {
    $minX = $points[0].X; $maxX = $points[0].X
    $minY = $points[0].Y; $maxY = $points[0].Y
    foreach ($pt in $points) {
        if ($pt.X -lt $minX) { $minX = $pt.X }
        if ($pt.X -gt $maxX) { $maxX = $pt.X }
        if ($pt.Y -lt $minY) { $minY = $pt.Y }
        if ($pt.Y -gt $maxY) { $maxY = $pt.Y }
    }
    return New-Object System.Drawing.Rectangle($minX, $minY, ($maxX - $minX), ($maxY - $minY))
}

# Given a shape's original bounding box and a raw (dx,dy) the mouse has
# moved, returns the same delta clipped so the translated bounding box never
# leaves $imgRect - i.e. dragging a shape to the edge of the image stops it
# right at the edge instead of letting it slide off/out of frame.
function Get-ClampedTranslation($origBounds, [double]$dx, [double]$dy, $imgRect) {
    $minDx = $imgRect.X - $origBounds.X
    $maxDx = ($imgRect.X + $imgRect.Width) - ($origBounds.X + $origBounds.Width)
    $minDy = $imgRect.Y - $origBounds.Y
    $maxDy = ($imgRect.Y + $imgRect.Height) - ($origBounds.Y + $origBounds.Height)
    $cdx = [Math]::Max($minDx, [Math]::Min($maxDx, $dx))
    $cdy = [Math]::Max($minDy, [Math]::Min($maxDy, $dy))
    return @{ Dx = $cdx; Dy = $cdy }
}
 
# Maps a time (seconds) onto an X pixel position within a track of the given
# width, given the video's total duration. Pure math, no controls involved,
# so it can be unit tested on its own.
function Get-MarkerX([double]$time, [double]$duration, [int]$trackWidth) {
    if ($duration -le 0) { return 0 }
    $frac = $time / $duration
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $frac))
    return [int]($frac * $trackWidth)
}

# VFR-safe navigation helpers. The validated FFprobe frame timeline is the
# timing authority; average FPS is never used to decide which frame is active.
function Get-FramePresentationTime([int]$frameIndex) {
    if ($isImageMode) { return 0.0 }
    if (-not $frameTimeline -or -not $frameTimeline.Ok -or -not $frameTimeline.Times) { return [double]::NaN }
    if ($frameIndex -lt 0 -or $frameIndex -ge $frameTimeline.Times.Length) { return [double]::NaN }
    return [double]$frameTimeline.Times[$frameIndex]
}

function Get-FramePresentationDuration([int]$frameIndex) {
    if ($isImageMode) { return 0.0 }
    if (-not $frameTimeline -or -not $frameTimeline.Ok -or -not $frameTimeline.Durations) { return [double]::NaN }
    if ($frameIndex -lt 0 -or $frameIndex -ge $frameTimeline.Durations.Length) { return [double]::NaN }
    return [double]$frameTimeline.Durations[$frameIndex]
}

function Get-FrameIndexAtPresentationTime([double]$time) {
    if ($isImageMode) { return 0 }
    if (-not $frameTimeline -or -not $frameTimeline.Ok -or -not $frameTimeline.Times -or $frameTimeline.Times.Length -le 0) { return -1 }
    if ([double]::IsNaN($time) -or [double]::IsInfinity($time)) { return -1 }

    $times = $frameTimeline.Times
    if ($time -le [double]$times[0]) { return 0 }
    $last = $times.Length - 1
    if ($time -ge [double]$times[$last]) { return $last }

    # Return the frame whose presentation interval contains the requested
    # timeline time: the greatest frame start timestamp <= target time.
    $lo = 0
    $hi = $last
    while ($lo -le $hi) {
        $mid = $lo + [int](($hi - $lo) / 2)
        $midTime = [double]$times[$mid]
        if ($midTime -le $time) {
            $lo = $mid + 1
        }
        else {
            $hi = $mid - 1
        }
    }
    return [Math]::Max(0, [Math]::Min($hi, $last))
}

function Format-FFmpegSeconds([double]$seconds) {
    if ([double]::IsNaN($seconds) -or [double]::IsInfinity($seconds) -or $seconds -lt 0.0) {
        throw 'An invalid media timestamp was supplied to FFmpeg.'
    }
    return $seconds.ToString('0.#########', [System.Globalization.CultureInfo]::InvariantCulture)
}
 
# Redaction membership is frame-index authoritative. Do not infer membership
# from seconds or average FPS: on VFR material those are not interchangeable.
# Both ends are inclusive because Begin/End Redaction describe displayed
# frames, and the automatic safety buffer is also defined in whole frames.
function Test-FrameInRange([int]$frameIndex, [int]$rangeStartFrame, [int]$rangeEndFrame) {
    if ($frameIndex -lt 0 -or $rangeStartFrame -lt 0 -or $rangeEndFrame -lt $rangeStartFrame) { return $false }
    return ($frameIndex -ge $rangeStartFrame -and $frameIndex -le $rangeEndFrame)
}
 
# ----------------------------
# State
# ----------------------------
if (Test-IsPackagedHost) {
    try {
        Initialize-EmbeddedMediaTools
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "The packaged FFmpeg/FFprobe payload could not be prepared. TinyRedactionTool will not continue without its approved media tools.",
            "Media-tool bootstrap failed",
            "OK",
            "Error"
        ) | Out-Null
        Remove-EmbeddedMediaTools
        exit
    }
}

$ffmpeg = Find-FFmpeg
if (-not $ffmpeg) { exit }
$ffprobe = Find-FFprobe
if (-not $ffprobe) { exit }

# Belt-and-braces cleanup for older sessions: Load-PreviewFrame no longer
# touches disk at all (it pipes ffmpeg's output straight into memory), but a
# previous run of this app - or an earlier build, before that change - could
# have crashed between writing one of these temp files and deleting it,
# leaving a frame that may contain whatever the user was about to redact
# sitting in %TEMP% indefinitely. Sweep for and remove any such leftovers
# from prior sessions every time the app starts. Failures here (a file still
# locked by another process, permissions, etc.) are silently skipped rather
# than surfaced - this is opportunistic best-effort hygiene, not something
# that should ever block startup.
try {
    # Older preview files used exactly TinyVideoRedactor_<GUID>.png. Do not
    # delete a broad prefix wildcard that could match unrelated files.
    Get-ChildItem -Path $env:TEMP -Filter "TinyVideoRedactor_*.png" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^TinyVideoRedactor_[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\.png$' } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
} catch {}
 
$videoPath = $null
$isImageMode = $false
$videoWidth = 0
$videoHeight = 0
$videoDuration = 0.0
$fps = 0.0
$sourceHasAudio = $false
$frameTimeline = $null
$totalFrames = 0
$currentFrame = 0
$previewSeconds = 0.0
$loadedFrame = -1
 
$dragging = $false
$dragStart = New-Object System.Drawing.Point(0,0)
$selection = New-Object System.Drawing.Rectangle(0,0,0,0)
$previewImage = $null

# Moving a drawn-but-not-yet-committed shape (Rectangle/Oval/closed Polygon)
# by dragging inside it, rather than starting a brand new one. $moveStart is
# the display-space point the drag began at; $moveOrigSelection/
# $moveOrigPolygonPoints snapshot the shape's own position at that moment,
# so the whole shape translates by the same delta the mouse has moved
# without accumulating rounding drift frame to frame.
$movingShape = $false
$moveStart = New-Object System.Drawing.Point(0,0)
$moveOrigSelection = $null
$moveOrigPolygonPoints = $null
 
# Drawing tool: "Rectangle", "Oval", or "Polygon" (the freeform tool). Rectangle
# and Oval are drag-based and use $selection above; Polygon is click-to-add-point
# and uses the three variables below instead.
$toolMode = "Rectangle"
$polygonActive = $false
$polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.Point]
$polygonMousePos = $null
 
$pendingRedaction = $null
$redactions = New-Object System.Collections.ArrayList

# Blur/Pixelate strength, 1 (lightest) - 10 (strongest). Whatever this is set
# to at the moment a redaction is created gets baked into that redaction's own
# Strength field, so different redactions in the same file can use different
# strengths, and adjusting the slider later never retroactively changes ones
# already added.
$redactionStrength = 5

# Coloured Box fill color, baked into each new redaction's own Color field
# the same way $redactionStrength is baked into Strength above - changing
# this later never retroactively changes redactions already added, unless
# the user explicitly re-picks a color while that redaction is selected in
# the Redactions list (see Get-ColorEditTarget / Set-ActiveRedactionColor).
$redactionColor = [System.Drawing.Color]::Black

# Whether the eyedropper is currently armed, waiting for the user's next
# click on the preview to sample a color from it.
$eyedropperActive = $false

# Shared session-level suppression for the Blur/Pixelate obscuration warning.
# One checkbox controls both visual-obscuration modes.
$script:suppressVisualObscurationWarning = $false
$script:visualObscurationWarningOpen = $false

# Network-backed media is permitted after an explicit warning. Keep source and
# destination suppression separate because opening unredacted source media and
# exporting a redacted file have materially different disclosure risks.
$script:suppressNetworkSourceWarning = $false
$script:suppressNetworkDestinationWarning = $false
$script:networkLocationWarningOpen = $false
 
$isPlaying = $false
$seekDragging = $false

$BUFFER_FRAMES = 2
 
# ----------------------------
# Form / polished UI
# ----------------------------

# ---------- visual helpers ----------
function New-UIFont([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
    # Segoe UI Variable is preferred on Windows 11; fall back cleanly on older systems.
    try {
        return New-Object System.Drawing.Font("Segoe UI Variable Text", $size, $style)
    } catch {
        return New-Object System.Drawing.Font("Segoe UI", $size, $style)
    }
}


# ---------- rounded-button rendering ----------
# WinForms has no border-radius property, so a soft rounded look has to be
# painted by hand. Region-clipping a button to a rounded rect is the simple
# way to do this, but it clips with hard (non-antialiased) pixel edges - it
# looks noticeably jagged next to the smooth curves in the mockup. Instead,
# each rounded control gets its own Paint handler that:
#   1. repaints its FULL bounds in the parent's background color first, which
#      erases whatever the native control chrome (square corners included)
#      already drew before this Paint handler ran;
#   2. fills+strokes a rounded-rect GraphicsPath in the control's own colors
#      with anti-aliasing on;
#   3. redraws the control's own Text centered on top.
# This only works cleanly when the control sits on a solid-color parent
# (true everywhere in this app - no gradients/images behind any button), and
# the parent color is read from $sender.Parent.BackColor at *paint* time so
# it keeps working correctly after a light/dark theme switch.
function Get-RoundedRectPath([System.Drawing.Rectangle]$rect, [int]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = [Math]::Max(2, $radius * 2)
    if ($d -gt $rect.Width) { $d = $rect.Width }
    if ($d -gt $rect.Height) { $d = $rect.Height }
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc(($rect.Right - $d), $rect.Y, $d, $d, 270, 90)
    $path.AddArc(($rect.Right - $d), ($rect.Bottom - $d), $d, $d, 0, 90)
    $path.AddArc($rect.X, ($rect.Bottom - $d), $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

# $radius is captured per-control via GetNewClosure() - without it every
# button's Paint handler would look up a single shared $radius variable
# dynamically when the event fires (the same dynamic-scoping trap that bit
# earlier versions of this app's event handlers), instead of each button
# keeping the radius it was actually given.
function Enable-RoundedPaint($control, [int]$radius = 10) {
    # The Paint handler below draws a rounded shape on top of the control,
    # but that alone doesn't stop Windows from drawing its OWN square-cornered
    # chrome for this control outside that shape - most visibly the dotted
    # focus rectangle / checked-state highlight a Button or a RadioButton
    # with Appearance="Button" draws at its own full rectangular bounds,
    # which happens independently of (and can redraw after) the custom Paint
    # handler here. Setting Control.Region clips literally everything about
    # how this control renders - our own painting AND every bit of native
    # chrome - to the rounded shape, so nothing square can ever show past its
    # corners, regardless of what triggered it.
    $applyRoundedRegion = {
        param($ctrl, $rad)
        if ($ctrl.Width -le 0 -or $ctrl.Height -le 0) { return }
        $useRadius = [Math]::Min($rad, [int]([Math]::Min($ctrl.Width, $ctrl.Height) / 2))
        $regionPath = Get-RoundedRectPath (New-Object System.Drawing.Rectangle(0, 0, $ctrl.Width, $ctrl.Height)) $useRadius
        $oldRegion = $ctrl.Region
        $ctrl.Region = New-Object System.Drawing.Region($regionPath)
        $regionPath.Dispose()
        if ($oldRegion) { $oldRegion.Dispose() }
    }.GetNewClosure()
    & $applyRoundedRegion $control $radius
    # Buttons here are all fixed-size, but reapply on Resize too in case that
    # ever changes - a stale Region from before a resize would bring the same
    # hard-corner problem right back on whatever newly-added edge.
    $control.Add_Resize({ & $applyRoundedRegion $control $radius }.GetNewClosure())

    $control.Add_Paint({
        param($sender,$e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $parentColor = if ($sender.Parent) { $sender.Parent.BackColor } else { $sender.BackColor }
        $eraseBrush = New-Object System.Drawing.SolidBrush($parentColor)
        $e.Graphics.FillRectangle($eraseBrush, 0, 0, $sender.Width, $sender.Height)
        $eraseBrush.Dispose()

        $useRadius = [Math]::Min($radius, [int]([Math]::Min($sender.Width, $sender.Height) / 2))
        $inner = New-Object System.Drawing.Rectangle(0, 0, ($sender.Width - 1), ($sender.Height - 1))
        $path = Get-RoundedRectPath $inner $useRadius

        $fillBrush = New-Object System.Drawing.SolidBrush($sender.BackColor)
        $e.Graphics.FillPath($fillBrush, $path)
        $fillBrush.Dispose()

        $borderColor = $sender.FlatAppearance.BorderColor
        if ($borderColor -ne [System.Drawing.Color]::Empty) {
            $pen = New-Object System.Drawing.Pen($borderColor, 1.3)
            $e.Graphics.DrawPath($pen, $path)
            $pen.Dispose()
        }

        # Icon toolbar/playback buttons carry an .Image instead of .Text (set
        # by New-ToolbarIconButton / New-IconButton) - drawn inset a few px so
        # the rounded background still peeks through as a "selected" halo.
        if ($sender.Image) {
            $margin = 4
            $imgRect = New-Object System.Drawing.Rectangle($margin, $margin, ($sender.Width - $margin*2), ($sender.Height - $margin*2))
            $e.Graphics.DrawImage($sender.Image, $imgRect)
        }
        elseif ($sender.Text) {
            $textBrush = New-Object System.Drawing.SolidBrush($sender.ForeColor)
            $fmt = New-Object System.Drawing.StringFormat
            $fmt.Alignment = [System.Drawing.StringAlignment]::Center
            $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
            $textRect = New-Object System.Drawing.RectangleF(0, 0, $sender.Width, $sender.Height)
            $e.Graphics.DrawString($sender.Text, $sender.Font, $textBrush, $textRect, $fmt)
            $textBrush.Dispose()
            $fmt.Dispose()
        }

        $path.Dispose()
    }.GetNewClosure())
}

# Rounded "input field" look for the read-only X/Y/W/H value chips in the
# Redaction Area section. Border/fill colors are read live (via $script:
# variables Apply-Theme keeps current) rather than closure-captured, the
# same pattern the seek bar's Paint handler uses, so the chips keep
# tracking light/dark theme switches correctly.
function Enable-RoundedFieldPaint($panel) {
    $panel.Add_Paint({
        param($sender,$e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $parentColor = if ($sender.Parent) { $sender.Parent.BackColor } else { $sender.BackColor }
        $eraseBrush = New-Object System.Drawing.SolidBrush($parentColor)
        $e.Graphics.FillRectangle($eraseBrush, 0, 0, $sender.Width, $sender.Height)
        $eraseBrush.Dispose()

        $inner = New-Object System.Drawing.Rectangle(0, 0, ($sender.Width - 1), ($sender.Height - 1))
        $path = Get-RoundedRectPath $inner 6

        $fillColor = if ($script:fieldFillColor) { $script:fieldFillColor } else { $sender.BackColor }
        $fillBrush = New-Object System.Drawing.SolidBrush($fillColor)
        $e.Graphics.FillPath($fillBrush, $path)
        $fillBrush.Dispose()

        $borderColor = if ($script:fieldBorderColor) { $script:fieldBorderColor } else { [System.Drawing.Color]::Gray }
        $pen = New-Object System.Drawing.Pen($borderColor, 1)
        $e.Graphics.DrawPath($pen, $path)
        $pen.Dispose()

        $path.Dispose()
    })
}

function Style-FlatButton($button, [bool]$primary = $false, [int]$radius = 10) {
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 1
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Font = New-UIFont 9.5 ([System.Drawing.FontStyle]::Regular)
    $button.UseVisualStyleBackColor = $false
    if ($primary) { $button.Tag = "primary" } else { $button.Tag = "button" }
    Enable-RoundedPaint $button $radius
}

function Style-ChoiceButton($control) {
    $control.Appearance = "Button"
    $control.FlatStyle = "Flat"
    $control.FlatAppearance.BorderSize = 1
    $control.TextAlign = "MiddleCenter"
    $control.Cursor = [System.Windows.Forms.Cursors]::Hand
    $control.Font = New-UIFont 9.0
    $control.Tag = "choice"
    Enable-RoundedPaint $control 10
}

function Add-SectionTitle($parent, [string]$text, [int]$x, [int]$y, [int]$w = 300) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($x,$y)
    $l.Size = New-Object System.Drawing.Size($w,25)
    $l.Font = New-UIFont 11 ([System.Drawing.FontStyle]::Bold)
    $l.Tag = "heading"
    $parent.Controls.Add($l)
    return $l
}

function Add-Rule($parent, [int]$x, [int]$y, [int]$w) {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($x,$y)
    $p.Size = New-Object System.Drawing.Size($w,1)
    $p.Tag = "rule"
    $parent.Controls.Add($p)
    return $p
}

function New-MiniField($parent, [string]$caption, [int]$x, [int]$width, [int]$height = 34) {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($x, 0)
    $panel.Size = New-Object System.Drawing.Size($width, $height)
    $panel.Tag = "input"
    Enable-RoundedFieldPaint $panel
    $parent.Controls.Add($panel)

    $capLbl = New-Object System.Windows.Forms.Label
    $capLbl.Text = $caption
    $capLbl.Location = New-Object System.Drawing.Point(7,3)
    $capLbl.Size = New-Object System.Drawing.Size(($width-14),12)
    $capLbl.Font = New-UIFont 6.5
    $capLbl.Tag = "muted"
    $capLbl.BackColor = [System.Drawing.Color]::Transparent
    $panel.Controls.Add($capLbl)

    $valLbl = New-Object System.Windows.Forms.Label
    $valLbl.Text = "--"
    $valLbl.Location = New-Object System.Drawing.Point(7,15)
    $valLbl.Size = New-Object System.Drawing.Size(($width-14),18)
    $valLbl.Font = New-UIFont 9.5 ([System.Drawing.FontStyle]::Bold)
    $valLbl.BackColor = [System.Drawing.Color]::Transparent
    $panel.Controls.Add($valLbl)

    return $valLbl
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Video | Image Redactor"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1540,980)
$form.MinimumSize = New-Object System.Drawing.Size(1320,820)
$form.KeyPreview = $true
$form.Font = New-UIFont 9.0
$form.AutoScaleMode = "Dpi"
$form.BackColor = [System.Drawing.Color]::FromArgb(246,248,251)

# Shared tooltip component for the icon-only toolbar/playback buttons, which
# have no visible text of their own to explain what they do.
$script:appToolTip = New-Object System.Windows.Forms.ToolTip
$script:appToolTip.AutoPopDelay = 5000
$script:appToolTip.InitialDelay = 400
$script:appToolTip.ReshowDelay = 200

# Header
$top = New-Object System.Windows.Forms.Panel
$top.Dock = "None"
$top.Location = New-Object System.Drawing.Point(0,0)
$top.Size = New-Object System.Drawing.Size($form.ClientSize.Width,82)
$top.Anchor = "Top,Left,Right"
$top.Padding = New-Object System.Windows.Forms.Padding(22,0,22,0)
$top.Tag = "header"
$form.Controls.Add($top)

# Embedded header icon: a small original "video frame + play triangle +
# redaction bar" glyph, stored as base64 PNG so the whole app stays a
# single script file with no extra image asset to ship alongside it.
# Decoded once at startup into an Image and shown in a PictureBox, in
# place of the plain Unicode glyph the tile used before.
$script:AppIconBase64 = "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"

function Get-AppIconImage {
    $bytes = [Convert]::FromBase64String($script:AppIconBase64)
    $ms = New-Object System.IO.MemoryStream(,$bytes)
    return [System.Drawing.Image]::FromStream($ms)
}

# Embedded toolbar/playback icon glyphs, stored as base64 PNGs for the
# same single-file-script reason as $script:AppIconBase64 above. Each was
# supplied as a full pre-styled icon (dark rounded tile + glyph); the flat
# background around the tile was flood-fill removed so they drop onto any
# button/theme cleanly, leaving the tile+glyph as one flattened image.
$script:IconBase64 = @{
    "play" = "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"
    "pause" = "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"
    "next_frame" = "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"
    "previous_frame" = "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"
    "freeform" = "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"
    "oval" = "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"
    "rectangle" = "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"
    "pixelate" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAALY0lEQVR4nO2ca4ycVRnHf+/ctp1t2dLdLb1QKWJLlaaAYFEDNiAqKkSjsQHjFaMfNPpN/eLlkzEmmpj4wVvEGxqlKipU0WpNDXhBqFaJRS0F2wW6S7e37WW7uzPjh/95PO/Ozs5ld864Y88/eTMz7/W85znn/1zPQEREREREREREREREREREREREREREREREREREREQwJAHvmwEqdY7PdqxZVOZwj4Tp71zdjvSxSupzvm2NWKho9wywEbUMuBo4CpzDz4YEKAODwBngFJB115aBySafkwVG3f2zNB6hCVBy7VrjntMLXODuMwEsApa7e024e+eAMeDftGfWzkCuzffLoBe9BvgVsBM4CBTc8QQJ5G3A34GHUUfgrjvZxDPKwBLgfuA+973cRLvGXLveD4wA17rf9wGHgY3ADe78s8DdQD/wCPBpukQABuuQK4ErkAAm8XyaAy4HVqGOT1AH/cRdV0GdNtu9c2gGlanP0Tbr7Lo1wFbUwaPA94HrgUNICCXgt66tr3XPsXcJoi9DCWACGEYjKAc8hzrbcBzNhCKiAZAAEnd+htnpKK3g643I9HlJ1b41eIW8BhhHAsi4bTFwsbtmRf1XnR9mG2VzhXXIEeDH7vM54C7gGXe8DOwGvo1opIzn/zISSl8b2lIAepCOKKN3fRK417VrNbDNtekMXlBb8VQE4SxFoP0zwBo7ALwRKb0s8Ha3z0bdzcB1QB4/CLJICeZpzOnQmI8n8LxtQng+8Cakd54GHgVuATYggd0DvMZds9O1/09NPm9OaPcMMPQAF6HOzKHRVkC0cwhZPysQRQ0hCrC2TNHYGjI9km1wjukIg820DHAaOIAsnAlgpTvHaCrfoA1tQSgBVJjO0TaiTwAPIhp4EgnkXuBZ1JlHgWM0toYqSMgFZlJEtbNlz8+45zyElHARDYzfAHsQ7W1DOqkXzdJXAa9I3bftCCUAmN5gU4aDwB2IjmwkTuH5N73VQwbx9lmmj3Cjm54a55cQBb0BdfDFqMMX4WecfZ4EvuaeERShrKBaSHfqdWjE5YBbEV1NMP9RZg5XPbMUNAsHkO1/PZoNINrZi/RDAQkzaB+FFoDxMIjnQSNurfteRiMxj+ioFWSoLbAKEkI9/NO1ZyOaFaCZeAY5aaN4L3isxXa1hJAUZIrSbOsH3JbBK8dTyEQ9jLh3iunO1WxbCdnqRWYXwmxtSivmCt5BHAG+jEIot7i2/cxt9e45L4ScAQmazsdR4ze5fb8GtgBL8Xz9GPAEoqJx6tNRGc/xk8y0VrLMdOTsXjYgbnLPN8cvcc9+C6ImkBm92G2fr9OeeSGUACbR1N2PPOIKsrUT4K/AJW7fmGvDkLvmlNtXj44qaOQfRzOmhKe5dAgj7UtMuc9jSNDLkOBG3fcSstAKyCyt4P2RoI5Yu29u9LIR+CSyUsxWN142p8gsnwrSC4eAj7a5PdUoIKr7ALL7J4APIaX7MeSd9zCdbkruvCDopBJOB8XSv+28TiQ9zMT9OeroEvK+e5Bh8A68yTzp9h8CfkGXRUMXOobwVHUAeeRF4FI8/RSRv9CLBBAE56MAEpQTGEC8/xEUKPwE8AM0KzYA70XhiqDOWEgzdCGijBTyduSM9QI/Bf6ID2v0oJDId5FHXKx5pzbhfJsBi5G5OYJo6Ijb+pAAphD9jAG/R0mjqZp3ahPOFwGYdbYeeCeyavYCn0MW0YX4vLBFQwdQutJM4q5zxBYi8sgM/SwyPUvAV5Dztx74FPKGH8dbaY3CGvPC+SIAG71PoyzcMMpHXIWPUYG89KPu2LVu32GkL6IZOg9Yxw2jdOg4CgJuRVbOElSl8UWkhDe6YwW3/8FQDQspgOqkzHzPmw9MB2xCOuAzqCTmH0gAJXxKtILCER9G5moz6dE5I5QAEvRCFhirh0rq3NCwVONW4F9odL8MWUFHUJyqjATxEqQvRkI2KJQASsiJOUtzAphy57aCVuJY6UxbGaUaB5FOeDUqTfkbyhNkULBwG7KMRltsV0sIFemzpHyz0zeDXvZwC89YTHNVcXb/Uyi/+27U6UVEP32Iih5AnH8rCtSdQ++xG1VKZAlgEYWeAc3yekLrDk+z+ePqczOIetbhR34FeCmwDzloFXcc5BsEQ6hQRFoH1NoySPj5qv2dQIJqfR5HEc89KOTwQjRw/uK2CbeN17pJu9AJK6gWEvRillqkzrntRhklYYaAbyKraBjFh3rcNoaKtIpIQMHaF9oPMH5Oz7QEjawrUUc8ROdGvz3/HOL55yHFa5aOlUna9xzNl8zPCaGjoYuYyaEJeqnLUXlKp1efGD2uRAn4vUgJL0JK2D6t6qKrakMNNsrucL+/jl7MMmRFFOjK0NnRD1L221DI4S5EOXlklt6E2j6Msmazlb60DaEEUEGjyEo6Cswc6VYR14mchJm5lwCvB3ahBP05NAAm3fECCjscdO2zCo1gCF2WcqTOc4JP7yrYoFiKRvsF7vcBFI5e5847hgSyyR0/HrJRoZWw1ewslFWGpmRfnto3hPyBzal9g/g1AuZ8dVVdkCHd8el6nVrLQTsBK8wCBdx2oQ7ej7eETqM23s3/gRmahjk0Vg5idUGd0AHWeUdRx48j/l+L/JDjKC6Uc+f2olBKD75SLgg65YjZIjzQS9lypCyiKbOOqtd+pQNos90/vWWqvhvs+oNIyY6gFZI3u/1PISrKo6DghcCNqedYW9qOdgvAAlbXoClsnQrTC7IS1BHDwJvRix9EUcosGnXvQos3DgHvQ52yC1Uw3Ol+96KA2hbgRe6ZVyEFuh0J2uz+08j5eyWycHpSbVoN3I7PeuXcOVlar9puCaFmQC9wWYNzEmRxXIZiMc8ixbcfCW0VUoyrUYrwKTSLLNI6gDj6HIqK4s5d6r6vxC+BzaCRfRF+XXIaBfxaZoNd25V+gFkblmkyvjdk8HX5ZbRYbg/wVuAbSAgngRfji2i/hUZ0P+pMs+FB1dV/RgLZ536nFa75ARN4uqt2AP8nllpIHWB8nOZie8ldaI3YIHAbykq9APgeylZtRR10I6pWGEez4H4UyVyKDxeM4ynoHiSkAio134mEl6XxEqhO+iT/RWgrKEEc/QSiGqsyG0DC6HfnLEKJkQri9inE9WtRZ59Ao/owGvkPow5fjzr8KKKwSURdq5GiNR2wYBHaCkoQXexDnWKr5jfj1xA8g3KwaUvnGKrTLCPlPIr+QqCCZsoP8Ys+LkWdbenEFW7fj/AKeMEiZDDOzMd+FPwCjdLvAO9BI/pR1Gm3IQHZtTmkWJejGVEAPohf3/txJMAS8DqUXNmNbPrHUISzus5/QaLdArAXPgLsQNw8iDdH+9E/pfShqoMrkGJcjneOQLQ1BfwS+AM+HJBBNHY7EtoN7pwTSFmX3DuZQ7Xg0alQhPFwAT/Sz7rnm6c5ifREHvH+BrwlZaUro4iyNuOV/BA+eZJ+Zlcg1H9FrEBh3+r9VoKSB36HOu9Od3wpMkPBh4Ct842SdqAQ91eRE3fCXWvedNchFAWNIJNxCxKGKWTrLFA27OrUtafwS4FGgC+gcpBVSG/kkbWzBOVx1+EDe13Z+RA2IWMOTzrwNon0wwDKB4NmRIJfl7sG6YL9yOI5jcxYW29stUB272Zrj6qvaSQ00ztBSxPbHYk0qlmFlORK/HJ/yzztYHqi244laJXiCBJQH0rYb0edXkSWzRTwJVQ60o98iGKT2xJ8ALBe2UwW/1cFtUIXbUO7nRSjg2UoKJbeZ9UQNgPSaUrzFx5BlGWrE22ApEdr2rwdoLlqNbum6NpWHRqpBTvnGBJ2V1NdxCwI5abXS7TUG33pCGQj7p1rpLLVa9JrnSMiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiK6Cf8BwsL9Fo90DzcAAAAASUVORK5CYII="
    "blur" = "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"
    "black" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABLklEQVR4nO3bQUrDQBiG4b+tB6g38eDeo1s34jFcdWfURSYUBBExMx8jzwOh7Sb/pG/SrqYKAAAAAAAAAACAXR0GzjoOnreXj6p6Ty+CTkbckYda76KHqrpv72d4ErZ1vlbVU92uYzqn9nqp9QJmOy5frmNXdz1O+o1rVS3t6HIxO9vWee05ZGSAY92++BkCVK3rPPYc0PXk/EyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgbuUFjqaq39jrDXqttnUvPISMDnNu8kTP/YlvnecSQnra7/bGqnmvdczvDT9+2zpf2eYanlt8auV/3NHjeXrr/DwAAAAAAAAAAAADwP3wC3V5LI/al5bMAAAAASUVORK5CYII="
    "eyedropper" = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAACsElEQVR4nO2bTW4TQRCFSwkcAU+/V2sCAlZYSHCKIJEQJH4kYM0ZAtwDgVhE/FwAwQ2SHZwhBCQ2WSQs4mBUYUbuGHtsx/a4e3qeVBtrPOqvXne5etwj0qhRozqo3W6ft5CEtETyLoCPJH+Q7JL8Q3IPwAdVXbdrpI4C0Cb5LYceGgC+ArgudZJz7g6Aw1HwXhwAWJU6SFXXSR5NAF/MhN/OuRuSIjy95RBtTSC5MQ18EXlhTMt5np4F7yVF59mLPUnRefbiOIpmSecDf5IAETkniU37rlcDvkuiznfzBLyTEJRl2dUqnS9CVddk0QLwnGTHOfegKueDaYTwD74Y1EkSKoI/tA3UQuGzLLs2APRo3vB2f9tASQhS1bUKgP3oALgvIUmrS0J48KYq1nwDjwDhOfh3ftZF0O61IZE43zGnZlgTwnReS+C9a6ZNQrzwM0hC/PBTJKE+8GdIQv3gJ0hCfeHHSEL94Uc0Tae20qnBd4NLAod3ePdmfL//PrMttoTovDujOxN2jJuzJwoU3rumSMJmKtN+Y5wHqrV3PhgBuL0o5xcukisk95N03gTgS/9gk3De5Jy7kp/A8gf8WFKANwF42Tfgz5IKvInkjj9o59xDSQXeOXfB/lf3Bn3carWyWhc8X6r6qG/g25IKvInklj94qwdS92lf5p6q3pQUnNcBT2QA/BKR5VHfJfkkaucBXB5wHrcUIMuyltWLAQ1TXPAmkm/HAFgmeSvvEXb6finihTeR/FnW9RmQLYeSR1ZF7Md4Unupr+3t+Ot+zMNM9v1PtoGSGMXeGxhF8XtmBwwBPC2BtyWwDeCF1RCJWQDeDAEctL63rDW2Iih1EclL9qbFiGkeX3GbRABWS5JwEMzJq3mK5AqA1wB281qwC+CVql5c9NgaNWrUqJFMr7/GqKf+LELoegAAAABJRU5ErkJggg=="
    "info" = "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"
}

$script:IconImageCache = @{}
function Get-IconImage([string]$name) {
    if ($script:IconImageCache.ContainsKey($name)) { return $script:IconImageCache[$name] }
    $bytes = [Convert]::FromBase64String($script:IconBase64[$name])
    $ms = New-Object System.IO.MemoryStream(,$bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    $script:IconImageCache[$name] = $img
    return $img
}

# ----------------------------
# Themeable line-art icons
# ----------------------------
# The Shape/Style toolbar icons (rectangle/oval/freeform/blur/pixelate/black)
# and the eyedropper icon are stored as pure black ink on a fully transparent
# background (see $script:IconBase64 above) rather than the old baked-in grey
# tile. That means the button's own BackColor - which Apply-Theme already
# keeps in sync with the light/dark theme - shows through the transparent
# surround, and the ink itself can be recolored to match whichever theme is
# active. Get-ThemedIconImage does that recoloring: since every source pixel
# is exactly black (0,0,0) at some alpha, a ColorMatrix whose RGB rows are
# all zero and whose translation row is the target color remaps every pixel
# to "target color at the same alpha" in one GPU-side pass, with no per-pixel
# loop needed.
$script:ThemedIconCache = @{}
function Get-ThemedIconImage([string]$name, [System.Drawing.Color]$color) {
    $cacheKey = "$name|$($color.ToArgb())"
    if ($script:ThemedIconCache.ContainsKey($cacheKey)) { return $script:ThemedIconCache[$cacheKey] }

    $src = Get-IconImage $name
    $bmp = New-Object System.Drawing.Bitmap($src.Width, $src.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $r = $color.R / 255.0
    $gc = $color.G / 255.0
    $b = $color.B / 255.0
    $matrixElements = [float[][]]@(
        @(0,0,0,0,0),
        @(0,0,0,0,0),
        @(0,0,0,0,0),
        @(0,0,0,1,0),
        @($r,$gc,$b,0,1)
    )
    $colorMatrix = New-Object System.Drawing.Imaging.ColorMatrix(,$matrixElements)
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    $attr.SetColorMatrix($colorMatrix)
    $destRect = New-Object System.Drawing.Rectangle(0,0,$src.Width,$src.Height)
    $g.DrawImage($src, $destRect, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
    $attr.Dispose()
    $g.Dispose()

    $script:ThemedIconCache[$cacheKey] = $bmp
    return $bmp
}

# Every control showing a themed line-art icon registers itself here (name +
# whether it's a checkable tool button) so Update-ThemedIcons can restyle all
# of them in one pass whenever the theme changes or a selection changes.
$script:ThemedIconButtons = New-Object System.Collections.Generic.List[object]
function Register-ThemedIcon($control, [string]$iconName) {
    [void]$script:ThemedIconButtons.Add(@{ Control = $control; IconName = $iconName })
}

# Recolors every registered themed icon: a checked tool/style RadioButton
# gets the accent color (matching its own accent-tinted selected background),
# everything else gets the theme's normal text/icon color.
function Update-ThemedIcons([System.Drawing.Color]$normalColor, [System.Drawing.Color]$accentColor) {
    foreach ($entry in $script:ThemedIconButtons) {
        $ctl = $entry.Control
        $isChecked = ($ctl -is [System.Windows.Forms.RadioButton]) -and $ctl.Checked
        $color = if ($isChecked) { $accentColor } else { $normalColor }
        $ctl.Image = Get-ThemedIconImage $entry.IconName $color
        $ctl.Invalidate()
    }
}

$logo = New-Object System.Windows.Forms.PictureBox
$logo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$logo.Image = Get-AppIconImage
$logo.Location = New-Object System.Drawing.Point(22,17)
$logo.Size = New-Object System.Drawing.Size(46,46)
$logo.Tag = "logo"
$top.Controls.Add($logo)

$lblAppTitle = New-Object System.Windows.Forms.Label
$lblAppTitle.Text = "Video | Image Redactor"
$lblAppTitle.Location = New-Object System.Drawing.Point(82,14)
$lblAppTitle.Size = New-Object System.Drawing.Size(300,28)
$lblAppTitle.Font = New-UIFont 15 ([System.Drawing.FontStyle]::Bold)
$lblAppTitle.Tag = "heading"
$top.Controls.Add($lblAppTitle)

$lblAppSub = New-Object System.Windows.Forms.Label
$lblAppSub.Text = "Simple. Private. Secure."
$lblAppSub.Location = New-Object System.Drawing.Point(84,43)
$lblAppSub.Size = New-Object System.Drawing.Size(300,22)
$lblAppSub.Font = New-UIFont 9.2
$lblAppSub.Tag = "muted"
$top.Controls.Add($lblAppSub)

# Everything from here to $btnTheme sits in the header's right-hand cluster:
# theme toggle, then (moving left) the privacy/credit note, then the
# Open/Change file button. Each is positioned from $form.ClientSize.Width at
# construction time and kept flush via Anchor="Top,Right" - the same
# established pattern already proven reliable for $btnTheme itself.
$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = [char]0x263E
$btnTheme.Size = New-Object System.Drawing.Size(44,34)
$btnTheme.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 75),24)
$btnTheme.Anchor = "Top,Right"
$btnTheme.Tag = "button"
Style-FlatButton $btnTheme
$top.Controls.Add($btnTheme)

# A small circular "i" info button replaces the old
# always-on privacy/credit text: clicking it opens the About dialog (see
# Show-AboutDialog) with the full copyright/license/no-telemetry statement,
# keeping the header itself uncluttered. Sits just left of the theme toggle,
# in the same right-hand cluster.
$btnInfo = New-Object System.Windows.Forms.Button
$btnInfo.Text = ""
$btnInfo.Size = New-Object System.Drawing.Size(34,34)
$btnInfo.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 119),24)
$btnInfo.Anchor = "Top,Right"
Style-FlatButton $btnInfo $false 999
$top.Controls.Add($btnInfo)
Register-ThemedIcon $btnInfo "info"
$script:appToolTip.SetToolTip($btnInfo, "About TinyRedactionTool")

# "Open Video | Image" - now lives in the header itself, not floating over
# the preview, so it's visible immediately (before any file is loaded) and
# never sits on top of the video. Renamed to "Change Video | Image" once a
# file is loaded - see the file-open handler further down. Sits immediately
# after the app title (fixed position, not right-anchored), so the header
# reads left-to-right as: title -> Open/Change button -> file name/path.
$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = "Open Video | Image"
$btnOpen.Size = New-Object System.Drawing.Size(170,34)
$btnOpen.Location = New-Object System.Drawing.Point(400,24)
Style-FlatButton $btnOpen $true
$top.Controls.Add($btnOpen)

# File name/path + hint, filling the space between the Open/Change button
# and the right-hand cluster (privacy/credit note + theme toggle). Its width
# has to be recomputed by Update-PolishedLayout on every resize (there's no
# single Anchor setting that means "stretch, but stop short of that other
# anchored control"), so only its fixed X/Y are set here.
$lblFile = New-Object System.Windows.Forms.Label
$lblFile.Text = "No Video | Image Loaded"
$lblFile.AutoEllipsis = $true
$lblFile.Location = New-Object System.Drawing.Point(590,18)
$lblFile.Size = New-Object System.Drawing.Size(400,22)
$lblFile.Font = New-UIFont 9.6 ([System.Drawing.FontStyle]::Bold)
$lblFile.Tag = "heading"
$top.Controls.Add($lblFile)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Open a file to begin."
$lblHint.AutoEllipsis = $true
$lblHint.Location = New-Object System.Drawing.Point(590,40)
$lblHint.Size = New-Object System.Drawing.Size(400,20)
$lblHint.Font = New-UIFont 8.4
$lblHint.Tag = "muted"
$top.Controls.Add($lblHint)

# Main layout: a narrow Photoshop-style tool rail, the preview workspace,
# and the inspector. Losing the old 245px wizard rail in favor of a 60px
# icon rail is most of where the extra preview space comes from.
$main = New-Object System.Windows.Forms.TableLayoutPanel
$main.Dock = "None"
$main.Location = New-Object System.Drawing.Point(0,132)
$main.Size = New-Object System.Drawing.Size($form.ClientSize.Width,([Math]::Max(1,$form.ClientSize.Height - 132)))
$main.Anchor = "Top,Bottom,Left,Right"
$main.ColumnCount = 3
$main.RowCount = 1
$main.Padding = New-Object System.Windows.Forms.Padding(0)
$main.Margin = New-Object System.Windows.Forms.Padding(0)
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,60)))
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,100)))
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,390)))
$form.Controls.Add($main)

# Header must stay visually above the workspace; geometry keeps the two from overlapping.
$top.BringToFront()

# TOOLBAR --------------------------------------------------------------
# A narrow Photoshop-style icon rail replacing the old wizard steps: Shape
# tools, then Style (redaction mode). These reuse the exact same
# $rbRectangle/$rbOval/$rbFreeform/$rbModeBlack/$rbModeBlur/$rbModePixelate
# RadioButtons the right panel used before (created further down, then
# re-parented here) so all of their existing Set-ToolMode/Get-SelectedMode
# wiring, Apply-Theme coloring, and Update-RedactionButtons enable/disable
# logic carries over unchanged - only their container and skin change.
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Dock = "Fill"
$toolbar.Padding = New-Object System.Windows.Forms.Padding(0)
$toolbar.Tag = "toolbar"
$main.Controls.Add($toolbar,0,0)

$lblToolsHeading = New-Object System.Windows.Forms.Label
$lblToolsHeading.Text = "Tools"
$lblToolsHeading.TextAlign = "MiddleCenter"
$lblToolsHeading.Location = New-Object System.Drawing.Point(0,10)
$lblToolsHeading.Size = New-Object System.Drawing.Size(60,16)
$lblToolsHeading.Font = New-UIFont 7.2 ([System.Drawing.FontStyle]::Bold)
$lblToolsHeading.Tag = "muted"
$toolbar.Controls.Add($lblToolsHeading)

# Icon-only RadioButton used by both toolbar groups (Shape and Style) -
# same rounded-paint/Enable-RoundedPaint mechanics as every other button in
# this app, just image-only instead of text.
function New-ToolbarIconButton($parent, [string]$iconName, [int]$x, [int]$y, [string]$tooltipText) {
    $b = New-Object System.Windows.Forms.RadioButton
    $b.Appearance = "Button"
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 1
    $b.Text = ""
    # Placeholder until Update-ThemedIcons (called from Apply-Theme, which
    # runs once at startup) recolors it for the active theme - registering
    # below is what makes that happen.
    $b.Image = Get-ThemedIconImage $iconName ([System.Drawing.Color]::Black)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Location = New-Object System.Drawing.Point($x,$y)
    $b.Size = New-Object System.Drawing.Size(40,40)
    $b.Tag = "choice"
    Enable-RoundedPaint $b 10
    $parent.Controls.Add($b)
    $script:appToolTip.SetToolTip($b, $tooltipText)
    Register-ThemedIcon $b $iconName
    return $b
}

$rbRectangle = New-ToolbarIconButton $toolbar "rectangle" 10 32 "Rectangle Selection"
$rbRectangle.Checked = $true
$rbOval = New-ToolbarIconButton $toolbar "oval" 10 76 "Oval Selection"
$rbFreeform = New-ToolbarIconButton $toolbar "freeform" 10 120 "Freeform Selection"

Add-Rule $toolbar 10 166 40 | Out-Null

$lblStyleHeading = New-Object System.Windows.Forms.Label
$lblStyleHeading.Text = "Style"
$lblStyleHeading.TextAlign = "MiddleCenter"
$lblStyleHeading.Location = New-Object System.Drawing.Point(0,176)
$lblStyleHeading.Size = New-Object System.Drawing.Size(60,16)
$lblStyleHeading.Font = New-UIFont 7.2 ([System.Drawing.FontStyle]::Bold)
$lblStyleHeading.Tag = "muted"
$toolbar.Controls.Add($lblStyleHeading)

# Redaction mode as its own isolated panel so WinForms' "RadioButtons
# auto-group by immediate parent" behavior doesn't lump these in with the
# Rectangle/Oval/Freeform tool buttons sitting directly on $toolbar.
$modeRow = New-Object System.Windows.Forms.Panel
$modeRow.Location = New-Object System.Drawing.Point(0,198)
$modeRow.Size = New-Object System.Drawing.Size(60,136)
$toolbar.Controls.Add($modeRow)

$rbModeBlack = New-ToolbarIconButton $modeRow "black" 10 0 "Coloured Box - secure opaque redaction"
$rbModeBlack.Checked = $true   # Secure opaque redaction is the default mode
$rbModeBlur = New-ToolbarIconButton $modeRow "blur" 10 44 "Blur - visual obscuration only; use Coloured Box for secure redaction"
$rbModePixelate = New-ToolbarIconButton $modeRow "pixelate" 10 88 "Pixelate - visual obscuration only; use Coloured Box for secure redaction"

# CENTER -------------------------------------------------------------
$center = New-Object System.Windows.Forms.Panel
$center.Dock = "Fill"
$center.Padding = New-Object System.Windows.Forms.Padding(16,16,16,16)
$center.Tag = "workspace"
$main.Controls.Add($center,1,0)

# Playback / timeline panel at the bottom of the center column.
$bottom = New-Object System.Windows.Forms.Panel
$bottom.Dock = "Bottom"
$bottom.Height = 214
$bottom.Padding = New-Object System.Windows.Forms.Padding(0)
$bottom.Tag = "workspace"
$center.Controls.Add($bottom)

$lblPos = New-Object System.Windows.Forms.Label
$lblPos.Text = "Preview frame"
$lblPos.Location = New-Object System.Drawing.Point(0,6)
$lblPos.Size = New-Object System.Drawing.Size(110,22)
$lblPos.Font = New-UIFont 8.5
$lblPos.Tag = "muted"
$bottom.Controls.Add($lblPos)

$lblPosValue = New-Object System.Windows.Forms.Label
$lblPosValue.Text = "00:00:00.000"
$lblPosValue.Location = New-Object System.Drawing.Point(112,4)
$lblPosValue.Size = New-Object System.Drawing.Size(110,24)
$lblPosValue.Font = New-UIFont 9.1 ([System.Drawing.FontStyle]::Bold)
$lblPosValue.Tag = "heading"
$bottom.Controls.Add($lblPosValue)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Load Frame"
$btnRefresh.Location = New-Object System.Drawing.Point(420,3)
$btnRefresh.Size = New-Object System.Drawing.Size(95,26)
$btnRefresh.Anchor = "Top,Right"
$btnRefresh.Enabled = $false
$btnRefresh.Font = New-UIFont 7.8
Style-FlatButton $btnRefresh
$bottom.Controls.Add($btnRefresh)

$lblFrameCount = New-Object System.Windows.Forms.Label
$lblFrameCount.Text = "Frame 0 / 0"
$lblFrameCount.TextAlign = "MiddleRight"
$lblFrameCount.Location = New-Object System.Drawing.Point(520,6)
$lblFrameCount.Size = New-Object System.Drawing.Size(170,24)
$lblFrameCount.Anchor = "Top,Right"
$lblFrameCount.Font = New-UIFont 8.5
$lblFrameCount.Tag = "muted"
$bottom.Controls.Add($lblFrameCount)

# Custom slim seek bar, replacing the native TrackBar - WinForms' stock
# TrackBar has a chunky beveled OS-native look that doesn't match the
# mockup's thin track + round accent-colored thumb. It's driven directly off
# $currentFrame/$totalFrames rather than its own Value/Minimum/Maximum
# properties, so there's a single source of truth instead of two numbers
# that could drift out of sync.
$seekBar = New-Object System.Windows.Forms.Panel
$seekBar.Location = New-Object System.Drawing.Point(0,34)
$seekBar.Size = New-Object System.Drawing.Size(690,45)
# No Anchor here - same reasoning as $btnCancelRedaction below: $bottom
# hasn't been through a real WinForms layout pass yet at construction time,
# so an Anchor="Top,Left,Right" set now would capture a wrong baseline width
# and never track $bottom's true live width afterwards (in either windowed
# or maximized state). Update-PolishedLayout sets .Width explicitly instead,
# from $bottom's live ClientSize.Width, every time the form resizes.
$seekBar.Enabled = $false
$seekBar.Cursor = [System.Windows.Forms.Cursors]::Hand
$seekBar.Tag = "seekbar"
$bottom.Controls.Add($seekBar)

# Moves the playhead to whatever frame corresponds to a given X pixel within
# $seekBar - shared by MouseDown (click-to-seek) and MouseMove (drag-to-seek).
function Set-FrameFromSeekX([int]$x) {
    if (-not $videoPath -or $isImageMode -or $totalFrames -le 1) { return }
    $w = $seekBar.ClientSize.Width
    if ($w -le 0 -or $videoDuration -le 0) { return }

    # The seek bar is time-linear, not frame-linear. On VFR material half the
    # duration does not necessarily mean half the frame count.
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $x / [double]$w))
    $targetTime = $frac * $videoDuration
    $newFrame = Get-FrameIndexAtPresentationTime $targetTime
    if ($newFrame -lt 0) { return }

    $mappedTime = Get-FramePresentationTime $newFrame
    if ([double]::IsNaN($mappedTime) -or [double]::IsInfinity($mappedTime)) { return }
    if ($newFrame -eq $currentFrame) { return }

    $script:currentFrame = $newFrame
    $script:previewSeconds = $mappedTime
    $lblPosValue.Text = SecToText $previewSeconds
    $lblFrameCount.Text = "Frame $($currentFrame + 1) / $totalFrames"
    $seekBar.Invalidate()
    $previewTimer.Stop()
    $previewTimer.Start()
}

$seekBar.Add_Paint({
    param($sender,$e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $w = $sender.ClientSize.Width
    $trackY = 20
    $trackH = 4
    $trackColor = if ($sender.Enabled) { $script:seekTrackColor } else { $script:seekTrackDisabledColor }
    $accentColor = if ($sender.Enabled) { $script:seekAccentColor } else { $script:seekTrackDisabledColor }

    $bgBrush = New-Object System.Drawing.SolidBrush($trackColor)
    $e.Graphics.FillRectangle($bgBrush, 0, $trackY, $w, $trackH)
    $bgBrush.Dispose()

    # Display the playhead on the real presentation timeline. For VFR this is
    # intentionally not currentFrame/totalFrames.
    $frac = if ($videoDuration -gt 0) { $previewSeconds / [double]$videoDuration } else { 0.0 }
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $frac))
    $filledW = [int]($frac * $w)
    $fillBrush = New-Object System.Drawing.SolidBrush($accentColor)
    if ($filledW -gt 0) { $e.Graphics.FillRectangle($fillBrush, 0, $trackY, $filledW, $trackH) }

    $thumbR = 7
    $cx = $filledW
    $cy = $trackY + [int]($trackH / 2)
    $e.Graphics.FillEllipse($fillBrush, ($cx - $thumbR), ($cy - $thumbR), ($thumbR * 2), ($thumbR * 2))
    $fillBrush.Dispose()
})

$seekBar.Add_MouseDown({
    param($sender,$e)
    if (-not $seekBar.Enabled -or $e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }
    Stop-Playback
    $script:seekDragging = $true
    Set-FrameFromSeekX $e.X
})
$seekBar.Add_MouseMove({
    param($sender,$e)
    if ($script:seekDragging) { Set-FrameFromSeekX $e.X }
})
$seekBar.Add_MouseUp({
    param($sender,$e)
    $script:seekDragging = $false
})

$scrubberMarkers = New-Object System.Windows.Forms.Panel
# Sits in its own row clear of the seek bar's own rectangle (0,34)-(width,79)
# rather than overlapping its bottom few pixels, so the red redaction-range
# marks can never end up rendered behind/under the seek bar itself.
$scrubberMarkers.Location = New-Object System.Drawing.Point(10,82)
$scrubberMarkers.Size = New-Object System.Drawing.Size(670,10)
# No Anchor - same Anchor-baseline-timing issue as $seekBar just above (and
# $btnCancelRedaction further down). It's kept 10px narrower than $seekBar
# on each side by design (inset from the seek bar's own edges); Update-
# PolishedLayout preserves that same inset explicitly instead of leaving it
# to two independently-anchored controls to (not) stay in sync.
$scrubberMarkers.Tag = "marker"
$bottom.Controls.Add($scrubberMarkers)
$scrubberMarkers.BringToFront()

# Icon-only playback/frame-step buttons (Button, not RadioButton - no
# mutual exclusivity needed here, unlike the toolbar's Shape/Style groups).
function New-IconButton([string]$iconName, [int]$w, [int]$h, [int]$radius = 10) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = ""
    $b.Image = Get-IconImage $iconName
    $b.Size = New-Object System.Drawing.Size($w,$h)
    Style-FlatButton $b $false $radius
    return $b
}

# Unified redaction/playback control row: Begin Redaction - Previous Frame -
# Play/Pause - Next Frame - End Redaction, with Cancel Redaction
# right-justified on the same row. Play/Pause is centered under the preview;
# Begin/Prev/Next/End cluster symmetrically around it - the X positions
# below are placeholders, recomputed to stay centered on every resize by
# Update-PolishedLayout (WinForms anchoring alone can't express "centered").
$btnStartRedaction = New-Object System.Windows.Forms.Button
$btnStartRedaction.Text = "Begin Redaction"
$btnStartRedaction.Size = New-Object System.Drawing.Size(132,40)
$btnStartRedaction.Location = New-Object System.Drawing.Point(0,100)
$btnStartRedaction.Enabled = $false
$btnStartRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnStartRedaction $true
$bottom.Controls.Add($btnStartRedaction)

$btnAddRedaction = New-Object System.Windows.Forms.Button
$btnAddRedaction.Text = "Create Redaction"
$btnAddRedaction.Size = New-Object System.Drawing.Size(132,40)
$btnAddRedaction.Location = New-Object System.Drawing.Point(0,100)
$btnAddRedaction.Enabled = $false
$btnAddRedaction.Visible = $false
$btnAddRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnAddRedaction $true
$bottom.Controls.Add($btnAddRedaction)

$btnPrevFrame = New-IconButton "previous_frame" 44 44
$btnPrevFrame.Enabled = $false
$bottom.Controls.Add($btnPrevFrame)
$script:appToolTip.SetToolTip($btnPrevFrame, "Previous Frame")

$btnPlayPause = New-IconButton "play" 52 52 999   # large radius self-clamps to a perfect circle
$btnPlayPause.Enabled = $false
$bottom.Controls.Add($btnPlayPause)
$script:appToolTip.SetToolTip($btnPlayPause, "Play")

$btnNextFrame = New-IconButton "next_frame" 44 44
$btnNextFrame.Enabled = $false
$bottom.Controls.Add($btnNextFrame)
$script:appToolTip.SetToolTip($btnNextFrame, "Next Frame")

$btnEndRedaction = New-Object System.Windows.Forms.Button
$btnEndRedaction.Text = "End Redaction"
$btnEndRedaction.Size = New-Object System.Drawing.Size(132,40)
$btnEndRedaction.Location = New-Object System.Drawing.Point(0,100)
$btnEndRedaction.Enabled = $false
$btnEndRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnEndRedaction
$bottom.Controls.Add($btnEndRedaction)

$btnCancelRedaction = New-Object System.Windows.Forms.Button
$btnCancelRedaction.Text = "Cancel Redaction"
$btnCancelRedaction.Location = New-Object System.Drawing.Point(560,110)
$btnCancelRedaction.Size = New-Object System.Drawing.Size(130,30)
# No Anchor here - Update-PolishedLayout repositions this button by hand on
# every resize (see the comment there for why trusting Anchor's own math
# caused it to overlap End Redaction / Next Frame).
$btnCancelRedaction.Enabled = $false
$btnCancelRedaction.Font = New-UIFont 8.2
Style-FlatButton $btnCancelRedaction
$bottom.Controls.Add($btnCancelRedaction)

# Blur/Pixelate strength slider - left-justified on the same row as
# Play/Pause (mirroring how Cancel Redaction is right-justified on it), and
# only ever shown when Blur or Pixelate is the selected style, since it has
# no effect on Black box. Its label text switches between the two so it's
# always obvious which effect the number applies to. Fixed at X=0 rather
# than centered - Update-PolishedLayout still repositions it vertically to
# stay aligned with the row, but its X never needs to move.
$lblStrength = New-Object System.Windows.Forms.Label
$lblStrength.Text = "Blur Strength: 5"
$lblStrength.Location = New-Object System.Drawing.Point(0,100)
$lblStrength.Size = New-Object System.Drawing.Size(170,18)
$lblStrength.Font = New-UIFont 8.0
$lblStrength.Tag = "muted"
$bottom.Controls.Add($lblStrength)

$sliderStrength = New-Object System.Windows.Forms.TrackBar
$sliderStrength.Minimum = 1
$sliderStrength.Maximum = 10
$sliderStrength.Value = $redactionStrength
$sliderStrength.TickStyle = [System.Windows.Forms.TickStyle]::None
$sliderStrength.Location = New-Object System.Drawing.Point(0,118)
$sliderStrength.Size = New-Object System.Drawing.Size(170,30)
$script:appToolTip.SetToolTip($sliderStrength, "How strong the Blur/Pixelate effect is")
$bottom.Controls.Add($sliderStrength)
$sliderStrength.BringToFront()

# Updates the label text/number and, for image mode, refreshes the preview
# immediately so dragging the slider shows the real effect strengthening or
# weakening live - matching how Get-LiveEffectPatch/Draw-RedactionShapeLiveEffect
# already re-sample the real pixels on every repaint.
$sliderStrength.Add_ValueChanged({
    $script:redactionStrength = $sliderStrength.Value
    $modeName = if ($rbModePixelate.Checked) { "Pixelation" } else { "Blur" }
    $lblStrength.Text = "$modeName Strength: $($sliderStrength.Value)"
    if ($isImageMode) { $picture.Invalidate() }
})

# Shows/hides the strength label+slider for the currently selected style -
# called from Apply-Theme, which already re-runs on every Shape/Style
# CheckedChanged (see the foreach below) as well as at startup.
function Update-StrengthSliderVisibility {
    $show = $rbModeBlur.Checked -or $rbModePixelate.Checked
    $lblStrength.Visible = $show
    $sliderStrength.Visible = $show
    if ($show) {
        $modeName = if ($rbModePixelate.Checked) { "Pixelation" } else { "Blur" }
        $lblStrength.Text = "$modeName Strength: $($sliderStrength.Value)"
    }
}

# Coloured Box color picker: a clickable swatch showing the current
# redaction color, plus an eyedropper button that samples a color straight
# from the loaded frame. Occupies the exact same row position as the
# Blur/Pixelate strength controls above, and the two are mutually exclusive
# (Update-StrengthSliderVisibility / Update-ColorPickerVisibility) since only
# one style is ever selected at a time.
$lblColor = New-Object System.Windows.Forms.Label
$lblColor.Text = "Box Colour"
$lblColor.Location = New-Object System.Drawing.Point(0,100)
$lblColor.Size = New-Object System.Drawing.Size(170,18)
$lblColor.Font = New-UIFont 8.0
$lblColor.Tag = "muted"
$bottom.Controls.Add($lblColor)

$swatchColor = New-Object System.Windows.Forms.Panel
$swatchColor.Location = New-Object System.Drawing.Point(0,118)
$swatchColor.Size = New-Object System.Drawing.Size(60,30)
$swatchColor.Cursor = [System.Windows.Forms.Cursors]::Hand
$swatchColor.BackColor = $redactionColor
$script:appToolTip.SetToolTip($swatchColor, "Click to choose the redaction box colour")
$bottom.Controls.Add($swatchColor)

# A thin border around the swatch so a black (or, in dark mode, a near-
# background-colored) swatch never visually disappears into its surroundings.
$swatchColor.Add_Paint({
    param($sender,$e)
    $borderColor = if ($script:fieldBorderColor) { $script:fieldBorderColor } else { [System.Drawing.Color]::Gray }
    $pen = New-Object System.Drawing.Pen($borderColor, 1)
    $rect = New-Object System.Drawing.Rectangle(0,0,($sender.Width-1),($sender.Height-1))
    $e.Graphics.DrawRectangle($pen, $rect)
    $pen.Dispose()
})

$btnEyedropper = New-Object System.Windows.Forms.Button
$btnEyedropper.Text = ""
$btnEyedropper.Size = New-Object System.Drawing.Size(30,30)
$btnEyedropper.Location = New-Object System.Drawing.Point(70,118)
Style-FlatButton $btnEyedropper
$bottom.Controls.Add($btnEyedropper)
Register-ThemedIcon $btnEyedropper "eyedropper"
$script:appToolTip.SetToolTip($btnEyedropper, "Pick a colour from the loaded frame")

# Returns the redaction whose color the swatch/eyedropper should affect right
# now: the selected item in the Redactions list, if any and if it's a
# Coloured/Black box - otherwise $null, meaning "the default color used for
# the next new redaction" ($script:redactionColor) applies instead. This is
# how scrubbing to an existing redaction and selecting it in the list lets
# the user recolor that specific box, on any frame it appears on.
function Get-ColorEditTarget {
    if ($lvRedactions.SelectedIndices.Count -eq 0) { return $null }
    $idx = $lvRedactions.SelectedIndices[0]
    if ($idx -lt 0 -or $idx -ge $redactions.Count) { return $null }
    $sel = $redactions[$idx]
    if ($sel.Mode -ne "Black box") { return $null }
    return $sel
}

# Refreshes the swatch to show whichever color is currently "live" - the
# selected existing Coloured box redaction's own color if one is selected,
# otherwise the default color that will be baked into the next new redaction.
function Update-ColorSwatch {
    $target = Get-ColorEditTarget
    $c = if ($target) { Get-RedactionColor $target } else { $script:redactionColor }
    $swatchColor.BackColor = $c
}

# Applies a newly-picked color either to the selected existing redaction (if
# one is selected and it's a Coloured box) or to the default used for new
# redactions, then refreshes anything that shows it.
function Set-ActiveRedactionColor([System.Drawing.Color]$color) {
    $target = Get-ColorEditTarget
    if ($target) {
        $target.Color = $color
        $picture.Invalidate()
    }
    else {
        $script:redactionColor = $color
    }
    Update-ColorSwatch
}

# Shows/hides the color swatch+eyedropper for the currently selected style -
# called from Apply-Theme, which already re-runs on every Shape/Style
# CheckedChanged (see the foreach below) as well as at startup.
function Update-ColorPickerVisibility {
    $show = $rbModeBlack.Checked
    $lblColor.Visible = $show
    $swatchColor.Visible = $show
    $btnEyedropper.Visible = $show
    if ($show) { Update-ColorSwatch }
}

$swatchColor.Add_Click({
    $dlg = New-Object System.Windows.Forms.ColorDialog
    $dlg.FullOpen = $true
    $dlg.Color = $swatchColor.BackColor
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Set-ActiveRedactionColor $dlg.Color
    }
})

$btnEyedropper.Add_Click({
    if (-not $previewImage) { return }
    $script:eyedropperActive = -not $script:eyedropperActive
    $picture.Cursor = if ($script:eyedropperActive) { [System.Windows.Forms.Cursors]::Cross } else { [System.Windows.Forms.Cursors]::Default }
    Set-RedactionButtonColor $btnEyedropper $(if ($script:eyedropperActive) { "red" } else { "grey" })
})

$lblPending = New-Object System.Windows.Forms.Label
$lblPending.Text = "No redaction in progress."
$lblPending.TextAlign = "MiddleCenter"
# Y=158 sits clear below the button row's tallest member (Play/Pause, which
# runs from y=100 to y=152) - it previously started at y=146, inside that
# band, which is what let this text render underneath/behind the buttons.
$lblPending.Location = New-Object System.Drawing.Point(0,158)
$lblPending.Size = New-Object System.Drawing.Size(690,18)
$lblPending.Anchor = "Top,Left,Right"
$lblPending.Font = New-UIFont 8.0
$lblPending.Tag = "muted"
$bottom.Controls.Add($lblPending)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready."
$status.Location = New-Object System.Drawing.Point(0,178)
$status.Size = New-Object System.Drawing.Size(690,18)
$status.Anchor = "Top,Left,Right"
$status.Font = New-UIFont 8.2
$status.Tag = "muted"
$bottom.Controls.Add($status)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(0,198)
$progress.Size = New-Object System.Drawing.Size(690,6)
$progress.Anchor = "Top,Left,Right"
$progress.Style = "Marquee"
$progress.Visible = $false
$bottom.Controls.Add($progress)

# Video preview between file card and timeline
$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Dock = "Fill"
$previewPanel.Padding = New-Object System.Windows.Forms.Padding(0,14,0,14)
$previewPanel.Tag = "workspace"
$center.Controls.Add($previewPanel)
$previewPanel.BringToFront()

$pictureFrame = New-Object System.Windows.Forms.Panel
$pictureFrame.Dock = "Fill"
$pictureFrame.Padding = New-Object System.Windows.Forms.Padding(1)
$pictureFrame.Tag = "previewframe"
$previewPanel.Controls.Add($pictureFrame)

$picture = New-Object System.Windows.Forms.PictureBox
$picture.Dock = "Fill"
$picture.BackColor = [System.Drawing.Color]::FromArgb(22,26,32)
$picture.SizeMode = "Zoom"
$pictureFrame.Controls.Add($picture)

# $btnOpen now lives in the header ($top) itself - see its creation right
# after $lblAppSub, further up this file - rather than floating over the
# preview, so it's visible before any file is loaded and stays out of the
# video's own display area.

# RIGHT PANEL --------------------------------------------------------
$right = New-Object System.Windows.Forms.Panel
$right.Dock = "Fill"
$right.Padding = New-Object System.Windows.Forms.Padding(18,16,18,16)
$right.AutoScroll = $true
$right.Tag = "inspector"
$main.Controls.Add($right,2,0)

# Keep top-level geometry deterministic. WinForms Dock ordering can otherwise
# let a Fill control occupy the header area depending on z-order.
function Update-PolishedLayout {
    $topH = 82
    $headerH = $topH

    $top.Location = New-Object System.Drawing.Point(0,0)
    $top.Size = New-Object System.Drawing.Size($form.ClientSize.Width,$topH)

    # $lblFile/$lblHint sit between the fixed-position Open/Change button and
    # the right-hand cluster (info button / theme toggle). There's no single
    # Anchor setting for "stretch, but stop short of that other anchored
    # control", so their width is recomputed by hand here, from the same
    # right-cluster offset $btnInfo's own Location uses.
    $rightClusterX = $form.ClientSize.Width - 119
    $fileInfoW = [Math]::Max(60, $rightClusterX - 590 - 20)
    $lblFile.Size = New-Object System.Drawing.Size($fileInfoW,22)
    $lblHint.Size = New-Object System.Drawing.Size($fileInfoW,20)

    $main.Location = New-Object System.Drawing.Point(0,$headerH)
    $main.Size = New-Object System.Drawing.Size(
        $form.ClientSize.Width,
        [Math]::Max(1, $form.ClientSize.Height - $headerH)
    )

    # Center the Begin/Prev/Play/Next/End redaction control cluster under the
    # preview. $bottom Docks "Bottom" inside $center (which Fills the middle
    # grid column), so its width tracks the live window width -- read it here
    # rather than assuming a fixed design width.
    $rowW = $bottom.ClientSize.Width
    if ($rowW -gt 0) {
        # Same fix as $btnCancelRedaction below: $seekBar/$scrubberMarkers used
        # to carry Anchor="Top,Left,Right" instead of this, which captured a
        # wrong baseline width before $bottom's first real layout pass and then
        # never tracked its true live width afterwards - in windowed mode the
        # seek bar's rendered width didn't match the actual preview window,
        # and since the red range markers are drawn proportionally to their
        # own ClientSize.Width (see Get-MarkerX), that same mismatch offset
        # them too. Setting both widths by hand from the live $rowW here fixes
        # both at once, in either windowed or maximized state, and keeps the
        # markers' original 10px-inset-per-side relationship to the seek bar.
        $seekBar.Width = $rowW
        $scrubberMarkers.Width = [Math]::Max(0, $rowW - 20)

        $gap = 10
        $wBeginEnd = 132
        $wPrevNext = 44
        $wPlay = 52
        $totalW = ($wBeginEnd * 2) + ($wPrevNext * 2) + $wPlay + ($gap * 4)
        $x = [Math]::Max(0, [int](($rowW - $totalW) / 2))

        $rowTop = 100
        $yPlay = $rowTop
        $yPrevNext = $rowTop + [int](($wPlay - $wPrevNext) / 2)
        $yBeginEnd = $rowTop + [int](($wPlay - 40) / 2)

        $btnStartRedaction.Location = New-Object System.Drawing.Point($x,$yBeginEnd)
        $btnAddRedaction.Location = New-Object System.Drawing.Point($x,$yBeginEnd)
        $x += $wBeginEnd + $gap

        $btnPrevFrame.Location = New-Object System.Drawing.Point($x,$yPrevNext)
        $x += $wPrevNext + $gap

        $btnPlayPause.Location = New-Object System.Drawing.Point($x,$yPlay)
        $x += $wPlay + $gap

        $btnNextFrame.Location = New-Object System.Drawing.Point($x,$yPrevNext)
        $x += $wPrevNext + $gap

        $clusterRight = $x + $wPrevNext
        $btnEndRedaction.Location = New-Object System.Drawing.Point($x,$yBeginEnd)

        # Cancel Redaction is positioned by hand rather than trusted to its
        # own Anchor="Top,Right" math: at the point it's constructed, $bottom
        # hasn't been through a real WinForms layout pass yet, so the anchor
        # can capture a wrong baseline margin and the button can end up
        # overlapping End Redaction / Next Frame instead of sitting clear of
        # them. Recomputing its X here on every resize (and clamping it to
        # never sit closer than $gap to the centered cluster) fixes that for
        # good, regardless of what the anchor itself thinks.
        $cancelW = 130
        $yCancel = $rowTop + [int](($wPlay - 30) / 2)
        $cancelX = [Math]::Max($clusterRight + $gap, $rowW - $cancelW - 20)
        $btnCancelRedaction.Location = New-Object System.Drawing.Point($cancelX,$yCancel)
    }
}

$form.Add_SizeChanged({
    Update-PolishedLayout
})

$form.Add_Shown({
    Update-PolishedLayout
    # Keep the inspector at its true top and put keyboard focus somewhere harmless.
    $right.AutoScrollPosition = New-Object System.Drawing.Point(0,0)
    $form.ActiveControl = $btnOpen
})

Add-SectionTitle $right "Redaction Area" 0 2 330 | Out-Null

# Redaction Area: a row of 4 small read-only "chip" fields (X/Y/W/H),
# matching the mockup's numeric-field look, shown whenever there's a
# concrete rectangle/bounding-box selection. $lblSelStatus (free text)
# shares the exact same bounds for the cases that aren't a plain rect --
# "no selection yet" and the in-progress freeform hints -- and the two
# are toggled via Update-SelectionFields so only one is visible at a time.
$selFieldsPanel = New-Object System.Windows.Forms.Panel
$selFieldsPanel.Location = New-Object System.Drawing.Point(0,34)
$selFieldsPanel.Size = New-Object System.Drawing.Size(325,34)
$selFieldsPanel.Visible = $false
$right.Controls.Add($selFieldsPanel)

$lblFieldX = New-MiniField $selFieldsPanel "X" 0 78
$lblFieldY = New-MiniField $selFieldsPanel "Y" 82 78
$lblFieldW = New-MiniField $selFieldsPanel "W" 164 78
$lblFieldH = New-MiniField $selFieldsPanel "H" 246 79

$lblSelStatus = New-Object System.Windows.Forms.Label
$lblSelStatus.Text = "Selection: none"
$lblSelStatus.Location = New-Object System.Drawing.Point(0,34)
$lblSelStatus.Size = New-Object System.Drawing.Size(325,34)
$lblSelStatus.Font = New-UIFont 8.5
$lblSelStatus.Tag = "muted"
$right.Controls.Add($lblSelStatus)

# Shows the X/Y/W/H chips for a concrete rect ($vr non-null, any tool
# mode -- Selection-To-VideoRect / the polygon-bounds equivalent both
# return a plain rect with .X/.Y/.W/.H), otherwise falls back to the
# free-text status label (e.g. "Selection: none", freeform-in-progress
# hints) with whatever $statusText the caller supplies.
function Update-SelectionFields($vr, [string]$statusText = "Selection: none") {
    if ($vr) {
        $lblFieldX.Text = "$($vr.X)"
        $lblFieldY.Text = "$($vr.Y)"
        $lblFieldW.Text = "$($vr.W)"
        $lblFieldH.Text = "$($vr.H)"
        $selFieldsPanel.Visible = $true
        $lblSelStatus.Visible = $false
    }
    else {
        $lblFieldX.Text = "--"
        $lblFieldY.Text = "--"
        $lblFieldW.Text = "--"
        $lblFieldH.Text = "--"
        $selFieldsPanel.Visible = $false
        $lblSelStatus.Text = $statusText
        $lblSelStatus.Visible = $true
    }
}

$lblToolHint = New-Object System.Windows.Forms.Label
$lblToolHint.Text = "Freeform: click points, then click the yellow start point to close."
$lblToolHint.Location = New-Object System.Drawing.Point(0,72)
$lblToolHint.Size = New-Object System.Drawing.Size(325,28)
$lblToolHint.Font = New-UIFont 8.0
$lblToolHint.Tag = "muted"
$right.Controls.Add($lblToolHint)

$lblSecurityNote = New-Object System.Windows.Forms.Label
$lblSecurityNote.Location = New-Object System.Drawing.Point(0,102)
$lblSecurityNote.Size = New-Object System.Drawing.Size(325,40)
$lblSecurityNote.Font = New-UIFont 8.0
$lblSecurityNote.Tag = "muted"
$right.Controls.Add($lblSecurityNote)

$lblBufferNote = New-Object System.Windows.Forms.Label
$lblBufferNote.Text = "Every redaction is padded automatically by $BUFFER_FRAMES frames before and after the marked range."
$lblBufferNote.Location = New-Object System.Drawing.Point(0,146)
$lblBufferNote.Size = New-Object System.Drawing.Size(325,34)
$lblBufferNote.Font = New-UIFont 8.0
$lblBufferNote.Tag = "muted"
$right.Controls.Add($lblBufferNote)

function Update-SecurityModeNote {
    if ($rbModeBlack.Checked) {
        $lblSecurityNote.Text = "Secure Redaction: an opaque Coloured Box replaces the selected source pixels."
    }
    else {
        $lblSecurityNote.Text = "Visual Obscuration: Blur/Pixelate are not guaranteed irreversible. Use an opaque Coloured Box for permanent removal."
    }
}

# Blur and Pixelate are useful visual-obscuration tools, but unlike an opaque
# Coloured Box they transform source pixels rather than replacing them. Warn
# when either mode is selected; the suppression checkbox is shared by both
# modes and lasts only for the current application session.
function Show-VisualObscurationWarning {
    if ($script:suppressVisualObscurationWarning -or $script:visualObscurationWarningOpen) { return }

    $script:visualObscurationWarningOpen = $true
    try {
        $isDark = $script:isDarkMode
        $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(20,26,33) } else { [System.Drawing.Color]::White }
        $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
        $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(180,190,201) } else { [System.Drawing.Color]::FromArgb(78,91,110) }
        $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }

        $warn = New-Object System.Windows.Forms.Form
        $warn.Text = "Visual obscuration warning"
        $warn.StartPosition = "CenterParent"
        $warn.FormBorderStyle = "FixedDialog"
        $warn.MaximizeBox = $false
        $warn.MinimizeBox = $false
        $warn.ShowInTaskbar = $false
        $warn.BackColor = $cBg
        $warn.ClientSize = New-Object System.Drawing.Size(540,250)
        $warn.Font = New-UIFont 9.0
        $warn.AutoScaleMode = "Dpi"

        $icon = New-Object System.Windows.Forms.PictureBox
        $icon.Image = [System.Drawing.SystemIcons]::Warning.ToBitmap()
        $icon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
        $icon.Location = New-Object System.Drawing.Point(24,28)
        $icon.Size = New-Object System.Drawing.Size(40,40)
        $warn.Controls.Add($icon)

        $title = New-Object System.Windows.Forms.Label
        $title.Text = "Blur and Pixelate are not secure redaction"
        $title.Font = New-UIFont 11 ([System.Drawing.FontStyle]::Bold)
        $title.ForeColor = $cText
        $title.BackColor = [System.Drawing.Color]::Transparent
        $title.Location = New-Object System.Drawing.Point(78,24)
        $title.Size = New-Object System.Drawing.Size(430,28)
        $warn.Controls.Add($title)

        $message = New-Object System.Windows.Forms.Label
        $message.Text = "Blur and Pixelate obscure content, but don't destroy it - the original detail can potentially be reconstructed with the right tools. For information that must not be recoverable, use a Black/Coloured Box instead."
        $message.Font = New-UIFont 9.0
        $message.ForeColor = $cMuted
        $message.BackColor = [System.Drawing.Color]::Transparent
        $message.Location = New-Object System.Drawing.Point(78,58)
        $message.Size = New-Object System.Drawing.Size(430,96)
        $warn.Controls.Add($message)

        $dontShow = New-Object System.Windows.Forms.CheckBox
        $dontShow.Text = "Don't show again this session"
        $dontShow.Font = New-UIFont 8.8
        $dontShow.ForeColor = $cText
        $dontShow.BackColor = $cBg
        $dontShow.Location = New-Object System.Drawing.Point(78,160)
        $dontShow.Size = New-Object System.Drawing.Size(260,26)
        $warn.Controls.Add($dontShow)

        $ok = New-Object System.Windows.Forms.Button
        $ok.Text = "OK"
        $ok.Size = New-Object System.Drawing.Size(100,36)
        $ok.Location = New-Object System.Drawing.Point(408,198)
        $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
        Style-FlatButton $ok $true
        $ok.BackColor = $cAccent
        $ok.ForeColor = [System.Drawing.Color]::White
        $ok.FlatAppearance.BorderColor = $cAccent
        $warn.Controls.Add($ok)

        $warn.AcceptButton = $ok
        $warn.CancelButton = $ok

        [void]$warn.ShowDialog($form)
        if ($dontShow.Checked) {
            $script:suppressVisualObscurationWarning = $true
        }

        if ($icon.Image) { $icon.Image.Dispose() }
        $warn.Dispose()
    }
    finally {
        $script:visualObscurationWarningOpen = $false
    }
}


# Network-backed paths are allowed, but require informed consent rather than a
# hard block. The two warning classes have independent session suppression so
# accepting a network source does not also suppress the later export warning.
function Show-NetworkLocationWarning([ValidateSet("Source","Destination")][string]$kind) {
    if ($kind -eq "Source") {
        if ($script:suppressNetworkSourceWarning) { return $true }
        $titleText = "Network/cloud source warning"
        $headingText = "Opening media from a network location"
        $messageText = "This file is on a network or cloud-synced location — opening it means its unredacted content will be transmitted over the network to this computer. If it must not leave a specific machine, copy it to a local folder first."
    }
    else {
        if ($script:suppressNetworkDestinationWarning) { return $true }
        $titleText = "Network/cloud save warning"
        $headingText = "Saving media to a network location"
        $messageText = "This save location is on a network or cloud-synced drive — the exported file will be transmitted over the network (and potentially to the cloud) once written here. Choose a local folder if this file must not leave this computer."
    }

    # Avoid accidental re-entry while a modal warning is already open.
    if ($script:networkLocationWarningOpen) { return $false }
    $script:networkLocationWarningOpen = $true

    try {
        $isDark = $script:isDarkMode
        $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(20,26,33) } else { [System.Drawing.Color]::White }
        $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
        $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(180,190,201) } else { [System.Drawing.Color]::FromArgb(78,91,110) }
        $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }

        $warn = New-Object System.Windows.Forms.Form
        $warn.Text = $titleText
        $warn.StartPosition = "CenterParent"
        $warn.FormBorderStyle = "FixedDialog"
        $warn.MaximizeBox = $false
        $warn.MinimizeBox = $false
        $warn.ShowInTaskbar = $false
        $warn.BackColor = $cBg
        $warn.ClientSize = New-Object System.Drawing.Size(570,285)
        $warn.Font = New-UIFont 9.0
        $warn.AutoScaleMode = "Dpi"

        $icon = New-Object System.Windows.Forms.PictureBox
        $icon.Image = [System.Drawing.SystemIcons]::Warning.ToBitmap()
        $icon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
        $icon.Location = New-Object System.Drawing.Point(24,28)
        $icon.Size = New-Object System.Drawing.Size(40,40)
        $warn.Controls.Add($icon)

        $title = New-Object System.Windows.Forms.Label
        $title.Text = $headingText
        $title.Font = New-UIFont 11 ([System.Drawing.FontStyle]::Bold)
        $title.ForeColor = $cText
        $title.BackColor = [System.Drawing.Color]::Transparent
        $title.Location = New-Object System.Drawing.Point(78,24)
        $title.Size = New-Object System.Drawing.Size(460,30)
        $warn.Controls.Add($title)

        $message = New-Object System.Windows.Forms.Label
        $message.Text = $messageText
        $message.Font = New-UIFont 9.0
        $message.ForeColor = $cMuted
        $message.BackColor = [System.Drawing.Color]::Transparent
        $message.Location = New-Object System.Drawing.Point(78,62)
        $message.Size = New-Object System.Drawing.Size(460,120)
        $warn.Controls.Add($message)

        $dontShow = New-Object System.Windows.Forms.CheckBox
        $dontShow.Text = "Don't show again this session"
        $dontShow.Font = New-UIFont 8.8
        $dontShow.ForeColor = $cText
        $dontShow.BackColor = $cBg
        $dontShow.Location = New-Object System.Drawing.Point(78,186)
        $dontShow.Size = New-Object System.Drawing.Size(270,26)
        $warn.Controls.Add($dontShow)

        $cancel = New-Object System.Windows.Forms.Button
        $cancel.Text = "Cancel"
        $cancel.Size = New-Object System.Drawing.Size(100,36)
        $cancel.Location = New-Object System.Drawing.Point(326,230)
        $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        Style-FlatButton $cancel $false
        $warn.Controls.Add($cancel)

        $continue = New-Object System.Windows.Forms.Button
        $continue.Text = "Continue"
        $continue.Size = New-Object System.Drawing.Size(110,36)
        $continue.Location = New-Object System.Drawing.Point(436,230)
        $continue.DialogResult = [System.Windows.Forms.DialogResult]::OK
        Style-FlatButton $continue $true
        $continue.BackColor = $cAccent
        $continue.ForeColor = [System.Drawing.Color]::White
        $continue.FlatAppearance.BorderColor = $cAccent
        $warn.Controls.Add($continue)

        $warn.AcceptButton = $continue
        $warn.CancelButton = $cancel

        $result = $warn.ShowDialog($form)
        $accepted = ($result -eq [System.Windows.Forms.DialogResult]::OK)

        # Suppression only takes effect after an affirmative Continue. Ticking
        # the box and then cancelling must not silently suppress a later warning.
        if ($accepted -and $dontShow.Checked) {
            if ($kind -eq "Source") {
                $script:suppressNetworkSourceWarning = $true
            }
            else {
                $script:suppressNetworkDestinationWarning = $true
            }
        }

        if ($icon.Image) { $icon.Image.Dispose() }
        $warn.Dispose()
        return $accepted
    }
    finally {
        $script:networkLocationWarningOpen = $false
    }
}

# Shape (Rectangle/Oval/Freeform) and Style (Black box/Blur/Pixelate) are
# chosen from the vertical icon toolbar on the far left now - see
# New-ToolbarIconButton and the $rbRectangle/.../$rbModePixelate creation
# there. Only the pure mode-lookup helper lives here, since it's referenced
# from this file's redaction-building code regardless of where the
# controls it reads live.
function Get-SelectedMode {
    if ($rbModeBlack.Checked) { return "Black box" }
    if ($rbModePixelate.Checked) { return "Pixelate" }
    return "Blur"
}

# Redactions created before the Coloured Box picker existed (or any created
# via a code path that didn't set one) won't have a Color field - fall back
# to black, matching the original hardcoded "black box" behavior exactly.
function Get-RedactionColor($r) {
    if ($r.Color) { return $r.Color }
    return [System.Drawing.Color]::Black
}

# Formats a color as ffmpeg's "0xRRGGBB" literal, used by drawbox's color=
# option in Build-RedactionFilterComplex.
function Get-FFmpegColorHex([System.Drawing.Color]$c) {
    return "0x{0:X2}{1:X2}{2:X2}" -f $c.R, $c.G, $c.B
}

Add-Rule $right 0 184 325 | Out-Null
Add-SectionTitle $right "Redactions" 0 198 330 | Out-Null

$lvRedactions = New-Object System.Windows.Forms.ListView
$lvRedactions.View = "Details"
$lvRedactions.FullRowSelect = $true
$lvRedactions.GridLines = $false
$lvRedactions.MultiSelect = $false
$lvRedactions.Location = New-Object System.Drawing.Point(0,230)
$lvRedactions.Size = New-Object System.Drawing.Size(325,140)
$lvRedactions.BorderStyle = "FixedSingle"
$lvRedactions.Font = New-UIFont 8.2
$lvRedactions.Tag = "list"
[void]$lvRedactions.Columns.Add("#", 30)
[void]$lvRedactions.Columns.Add("Shape", 66)
[void]$lvRedactions.Columns.Add("Mode", 72)
[void]$lvRedactions.Columns.Add("Marked range", 145)
[void]$lvRedactions.Columns.Add("Export range (buffered)", 0)
[void]$lvRedactions.Columns.Add("Rect (bounding box)", 0)
$right.Controls.Add($lvRedactions)

# Selecting a redaction here is what lets the color swatch/eyedropper target
# that specific existing redaction instead of the default used for new ones
# (see Get-ColorEditTarget) - scrubbing to a frame and selecting its
# redaction in this list is how the color gets changed after the fact.
$lvRedactions.Add_SelectedIndexChanged({
    Update-ColorSwatch
    $picture.Invalidate()
})

$btnRemoveRedaction = New-Object System.Windows.Forms.Button
$btnRemoveRedaction.Text = "Remove Selected"
$btnRemoveRedaction.Location = New-Object System.Drawing.Point(0,378)
$btnRemoveRedaction.Size = New-Object System.Drawing.Size(155,34)
Style-FlatButton $btnRemoveRedaction
$right.Controls.Add($btnRemoveRedaction)

$btnClearRedactions = New-Object System.Windows.Forms.Button
$btnClearRedactions.Text = "Clear All"
$btnClearRedactions.Location = New-Object System.Drawing.Point(170,378)
$btnClearRedactions.Size = New-Object System.Drawing.Size(155,34)
Style-FlatButton $btnClearRedactions
$right.Controls.Add($btnClearRedactions)

Add-Rule $right 0 424 325 | Out-Null
Add-SectionTitle $right "Output" 0 438 330 | Out-Null

# Format and Quality sit side by side to save vertical space. Format's item
# list and selection swap between video and image extensions in
# Apply-ModeLabels (mirroring how $cmbQuality/$chkAudio are shown/hidden
# there already).
$lblFormat = New-Object System.Windows.Forms.Label
$lblFormat.Text = "Format"
$lblFormat.Location = New-Object System.Drawing.Point(0,474)
$lblFormat.Size = New-Object System.Drawing.Size(150,22)
$lblFormat.Font = New-UIFont 8.5
$lblFormat.Tag = "muted"
$right.Controls.Add($lblFormat)

$lblQuality = New-Object System.Windows.Forms.Label
$lblQuality.Text = "Quality"
$lblQuality.Location = New-Object System.Drawing.Point(175,474)
$lblQuality.Size = New-Object System.Drawing.Size(150,22)
$lblQuality.Font = New-UIFont 8.5
$lblQuality.Tag = "muted"
$right.Controls.Add($lblQuality)

$VIDEO_FORMATS = @("MP4","MOV","M4V","AVI","MKV","WEBM")
$IMAGE_FORMATS = @("PNG","JPG","GIF","WEBP")

$cmbFormat = New-Object System.Windows.Forms.ComboBox
$cmbFormat.DropDownStyle = "DropDownList"
$cmbFormat.Items.AddRange($VIDEO_FORMATS)
$cmbFormat.SelectedIndex = 0
$cmbFormat.Location = New-Object System.Drawing.Point(0,494)
$cmbFormat.Size = New-Object System.Drawing.Size(150,30)
$cmbFormat.Font = New-UIFont 9.1
$cmbFormat.Tag = "input"
$right.Controls.Add($cmbFormat)

$cmbQuality = New-Object System.Windows.Forms.ComboBox
$cmbQuality.DropDownStyle = "DropDownList"
$cmbQuality.Items.AddRange(@("High quality","Normal quality","Smaller file size"))
$cmbQuality.SelectedIndex = 1
$cmbQuality.Location = New-Object System.Drawing.Point(175,494)
$cmbQuality.Size = New-Object System.Drawing.Size(150,30)
$cmbQuality.Font = New-UIFont 9.1
$cmbQuality.Tag = "input"
$right.Controls.Add($cmbQuality)

$chkAudio = New-Object System.Windows.Forms.CheckBox
$chkAudio.Text = "Keep original audio"
$chkAudio.Checked = $false
$chkAudio.Location = New-Object System.Drawing.Point(0,532)
$chkAudio.Size = New-Object System.Drawing.Size(220,26)
$chkAudio.Font = New-UIFont 8.8
$right.Controls.Add($chkAudio)
$chkAudio.Add_CheckedChanged({
    if ($chkAudio.Checked) {
        $answer = [System.Windows.Forms.MessageBox]::Show(
            "TinyRedactionTool does not inspect or redact audio. Audio information will remain in the exported file.`r`n`r`nInclude the primary audio track anyway?",
            "Audio is not redacted",
            "YesNo",
            "Warning"
        )
        if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
            $chkAudio.Checked = $false
        }
    }
})

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export Redacted Video"
$btnExport.Location = New-Object System.Drawing.Point(0,566)
$btnExport.Size = New-Object System.Drawing.Size(325,44)
$btnExport.Enabled = $false
$btnExport.Font = New-UIFont 10 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnExport $true
$right.Controls.Add($btnExport)

# ---------- theme engine ----------
$script:isDarkMode = $false

# Fixed status colors for the Begin/End Redaction buttons. These signal
# state (ready-to-begin / in-progress) rather than the neutral UI palette,
# so they stay constant across the light/dark theme toggle.
$script:colorGreenBg     = [System.Drawing.Color]::FromArgb(34,197,94)
$script:colorGreenBorder = [System.Drawing.Color]::FromArgb(22,163,74)
$script:colorRedBg       = [System.Drawing.Color]::FromArgb(239,68,68)
$script:colorRedBorder   = [System.Drawing.Color]::FromArgb(220,38,38)

# Populated by Apply-Theme with the current theme's neutral button/text/
# border colors, so Update-RedactionButtons (and anything else that needs
# the "inactive/grey" look) can match the active theme without duplicating
# the light/dark color logic.
$script:cButtonCurrent = [System.Drawing.Color]::FromArgb(251,252,254)
$script:cTextCurrent   = [System.Drawing.Color]::FromArgb(18,27,42)
$script:cBorderCurrent = [System.Drawing.Color]::FromArgb(218,224,232)

function Apply-Theme {
    if ($script:isDarkMode) {
        $cBg       = [System.Drawing.Color]::FromArgb(14,18,23)
        $cWorkspace= [System.Drawing.Color]::FromArgb(16,21,27)
        $cPanel    = [System.Drawing.Color]::FromArgb(20,26,33)
        $cCard     = [System.Drawing.Color]::FromArgb(24,31,39)
        $cInput    = [System.Drawing.Color]::FromArgb(27,35,44)
        $cText     = [System.Drawing.Color]::FromArgb(241,245,249)
        $cMuted    = [System.Drawing.Color]::FromArgb(158,170,184)
        $cBorder   = [System.Drawing.Color]::FromArgb(53,65,79)
        $cAccent   = [System.Drawing.Color]::FromArgb(38,132,255)
        $cAccent2  = [System.Drawing.Color]::FromArgb(18,79,153)
        $cButton   = [System.Drawing.Color]::FromArgb(28,36,45)
        $cPreview  = [System.Drawing.Color]::FromArgb(5,8,12)
        $btnTheme.Text = [char]0x2600
    }
    else {
        $cBg       = [System.Drawing.Color]::FromArgb(246,248,251)
        $cWorkspace= [System.Drawing.Color]::FromArgb(249,250,252)
        $cPanel    = [System.Drawing.Color]::White
        $cCard     = [System.Drawing.Color]::FromArgb(250,251,253)
        $cInput    = [System.Drawing.Color]::White
        $cText     = [System.Drawing.Color]::FromArgb(18,27,42)
        $cMuted    = [System.Drawing.Color]::FromArgb(99,112,132)
        $cBorder   = [System.Drawing.Color]::FromArgb(218,224,232)
        $cAccent   = [System.Drawing.Color]::FromArgb(18,113,255)
        $cAccent2  = [System.Drawing.Color]::FromArgb(224,238,255)
        $cButton   = [System.Drawing.Color]::FromArgb(251,252,254)
        $cPreview  = [System.Drawing.Color]::FromArgb(22,26,32)
        $btnTheme.Text = [char]0x263E
    }

    $form.BackColor = $cBg
    $top.BackColor = $cPanel
    $toolbar.BackColor = $cPanel
    $center.BackColor = $cWorkspace
    $right.BackColor = $cPanel
    $bottom.BackColor = $cWorkspace
    $previewPanel.BackColor = $cWorkspace
    $pictureFrame.BackColor = $cBorder
    $picture.BackColor = $cPreview
    $scrubberMarkers.BackColor = $cWorkspace
    $seekBar.BackColor = $cWorkspace
    $script:seekTrackColor = $cBorder
    $script:seekTrackDisabledColor = $cBorder
    $script:seekAccentColor = $cAccent
    $seekBar.Invalidate()

    foreach ($ctl in @($form,$top,$toolbar,$center,$right,$bottom,$previewPanel)) {
        foreach ($child in $ctl.Controls) {
            if ($child.Tag -eq "heading") {
                $child.ForeColor = $cText
                if ($child -is [System.Windows.Forms.Label]) { $child.BackColor = [System.Drawing.Color]::Transparent }
            }
            elseif ($child.Tag -eq "muted") {
                $child.ForeColor = $cMuted
                if ($child -is [System.Windows.Forms.Label]) { $child.BackColor = [System.Drawing.Color]::Transparent }
            }
            elseif ($child.Tag -eq "accenttext") {
                $child.ForeColor = $cAccent
                if ($child -is [System.Windows.Forms.Label]) { $child.BackColor = [System.Drawing.Color]::Transparent }
            }
            elseif ($child.Tag -eq "rule") {
                $child.BackColor = $cBorder
            }
        }
    }

    # The embedded icon PNG already bakes in its own dark rounded-tile
    # background; $logo.BackColor only shows through its transparent
    # corner cutouts, so it should match the header bar behind it rather
    # than carry its own theme-driven tile color.
    $logo.BackColor = $cPanel

    foreach ($b in @($btnTheme,$btnPrevFrame,$btnNextFrame,$btnRefresh,$btnEndRedaction,$btnCancelRedaction,$btnRemoveRedaction,$btnClearRedactions)) {
        $b.BackColor = $cButton
        $b.ForeColor = $cText
        $b.FlatAppearance.BorderColor = $cBorder
    }

    foreach ($b in @($btnOpen,$btnPlayPause,$btnStartRedaction,$btnAddRedaction,$btnExport)) {
        $b.BackColor = $cAccent
        $b.ForeColor = [System.Drawing.Color]::White
        $b.FlatAppearance.BorderColor = $cAccent
    }

    foreach ($r in @($rbRectangle,$rbOval,$rbFreeform,$rbModeBlack,$rbModeBlur,$rbModePixelate)) {
        if ($r.Checked) {
            $r.BackColor = if ($script:isDarkMode) { [System.Drawing.Color]::FromArgb(19,56,97) } else { $cAccent2 }
            $r.ForeColor = $cAccent
            $r.FlatAppearance.BorderColor = $cAccent
        } else {
            $r.BackColor = $cButton
            $r.ForeColor = $cText
            $r.FlatAppearance.BorderColor = $cBorder
        }
    }
    $modeRow.BackColor = $cPanel
    Update-StrengthSliderVisibility
    Update-ThemedIcons $cText $cAccent

    # Redaction Area X/Y/W/H chip fields. Fill/border colors are read live
    # by Enable-RoundedFieldPaint's Paint handler (see that function), so
    # setting the $script: vars here and invalidating is enough to repaint
    # them correctly on a theme switch.
    $script:fieldFillColor = $cInput
    $script:fieldBorderColor = $cBorder
    foreach ($fld in @($lblFieldX,$lblFieldY,$lblFieldW,$lblFieldH)) {
        $fldPanel = $fld.Parent
        $fldPanel.BackColor = $cPanel
        $fldPanel.Controls[0].ForeColor = $cMuted
        $fldPanel.Controls[1].ForeColor = $cText
        $fldPanel.Invalidate()
    }

    # Update-ColorPickerVisibility (and the swatch's own border) reads
    # $script:fieldBorderColor, so this runs after it's set just above.
    Update-ColorPickerVisibility
    $swatchColor.Invalidate()

    foreach ($c in @($cmbQuality,$cmbFormat)) {
        $c.BackColor = $cInput
        $c.ForeColor = $cText
    }

    $chkAudio.BackColor = $cPanel
    $chkAudio.ForeColor = $cText
    Update-SecurityModeNote

    $lvRedactions.BackColor = $cInput
    $lvRedactions.ForeColor = $cText

    $status.ForeColor = $cMuted
    $lblSelStatus.ForeColor = $cMuted
    $lblPending.ForeColor = $cMuted
    $lblBufferNote.ForeColor = $cMuted
    $lblHint.ForeColor = $cMuted
    $lblFile.ForeColor = $cText
    $lblPos.ForeColor = $cMuted
    $lblPosValue.ForeColor = $cText
    $lblFrameCount.ForeColor = $cMuted
    $lblFormat.ForeColor = $cMuted
    $lblQuality.ForeColor = $cMuted
    $lblToolHint.ForeColor = $cMuted

    $script:cButtonCurrent = $cButton
    $script:cTextCurrent = $cText
    $script:cBorderCurrent = $cBorder

    $picture.Invalidate()
    $scrubberMarkers.Invalidate()
}

$btnTheme.Add_Click({
    $script:isDarkMode = -not $script:isDarkMode
    Apply-Theme
    # Apply-Theme itself must not call Update-RedactionButtons (it's invoked
    # once, near the top of the script, before Update-RedactionButtons is
    # defined) -- so re-apply the green/red/grey redaction-button state here,
    # once both functions are known to exist.
    Update-RedactionButtons
})

# ----------------------------
# About dialog
# ----------------------------
# Adds a centered, word-wrapped label to $panel at the current $script:aboutY
# cursor, using the Label control's own preferred-size calculation plus a
# small DPI-safe allowance, then advances the cursor past it.
function Add-CenteredAboutLabel($panel, [string]$text, $font, [System.Drawing.Color]$color, [int]$width, [int]$topPad = 0, [int]$bottomPad = 10) {
    $script:aboutY += $topPad

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $text
    $lbl.Font = $font
    $lbl.ForeColor = $color
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $lbl.TextAlign = "TopCenter"

    # UI: use the Label control's own layout engine to calculate the wrapped
    # height, then add a small DPI-safe allowance. TextRenderer alone can
    # under-measure the final wrapped line on some Windows DPI/font setups.
    $lbl.AutoSize = $true
    $lbl.MaximumSize = New-Object System.Drawing.Size($width, 0)
    $lbl.MinimumSize = New-Object System.Drawing.Size($width, 0)
    $preferred = $lbl.GetPreferredSize((New-Object System.Drawing.Size($width, 0)))
    $lbl.AutoSize = $false
    $lbl.Location = New-Object System.Drawing.Point(0, $script:aboutY)
    $lbl.Size = New-Object System.Drawing.Size($width, ($preferred.Height + 10))

    $panel.Controls.Add($lbl)
    $script:aboutY += $lbl.Height + $bottomPad
    return $lbl
}

# Builds and shows the About/info dialog: app name, copyright, the no-
# telemetry/no-network statement, license text, and a clickable link to the
# GitHub repo. Content and heading levels match the markdown the user
# supplied 1:1; everything is centered per that spec.
function Show-AboutDialog {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(20,26,33) } else { [System.Drawing.Color]::White }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(158,170,184) } else { [System.Drawing.Color]::FromArgb(99,112,132) }
    $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }
    $cBorder = if ($isDark) { [System.Drawing.Color]::FromArgb(53,65,79) } else { [System.Drawing.Color]::FromArgb(218,224,232) }

    $dlgWidth = 480
    $contentWidth = $dlgWidth - 60

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "About TinyRedactionTool"
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgWidth, 480)
    $dlg.Font = New-UIFont 9.0
    $dlg.AutoScaleMode = "Dpi"

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(30,20)
    $panel.Size = New-Object System.Drawing.Size($contentWidth, 1)
    $panel.AutoSize = $false
    $dlg.Controls.Add($panel)

    $script:aboutY = 0

    Add-CenteredAboutLabel $panel "TinyRedactionTool" (New-UIFont 20 ([System.Drawing.FontStyle]::Bold)) $cText $contentWidth 0 14 | Out-Null
    Add-CenteredAboutLabel $panel "Copyright (C) 2026 David McCabe" (New-UIFont 12 ([System.Drawing.FontStyle]::Bold)) $cText $contentWidth 0 14 | Out-Null
    Add-CenteredAboutLabel $panel "All media processing is performed locally. TinyRedactionTool contains no telemetry and never uploads media. Files in locally synchronised folders may still be uploaded by other software outside TinyRedactionTool's control." (New-UIFont 8.5 ([System.Drawing.FontStyle]::Bold)) $cMuted $contentWidth 0 16 | Out-Null
    Add-CenteredAboutLabel $panel "Open-source, GPL-licensed. Source available on GitHub." (New-UIFont 9.0) $cText $contentWidth 0 10 | Out-Null
    Add-CenteredAboutLabel $panel "TinyRedactionTool is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later version." (New-UIFont 9.0) $cText $contentWidth 0 10 | Out-Null
    Add-CenteredAboutLabel $panel "SPDX-License-Identifier: GPL-2.0-or-later" (New-UIFont 8.7) $cMuted $contentWidth 0 6 | Out-Null
    Add-CenteredAboutLabel $panel "The full GNU GPL version 2 text is provided in the repository's LICENSE file." (New-UIFont 8.7) $cMuted $contentWidth 0 16 | Out-Null

    $link = New-Object System.Windows.Forms.LinkLabel
    $link.Text = "Github: https://github.com/mccabedd/tinyredactiontool/"
    $link.Font = New-UIFont 9.0
    $link.LinkColor = $cAccent
    $link.ActiveLinkColor = $cAccent
    $link.VisitedLinkColor = $cAccent
    $link.TextAlign = "TopCenter"
    $link.BackColor = [System.Drawing.Color]::Transparent
    $link.Location = New-Object System.Drawing.Point(0, $script:aboutY)
    $link.Size = New-Object System.Drawing.Size($contentWidth, 20)
    $link.LinkArea = New-Object System.Windows.Forms.LinkArea(8, 46)
    $link.Add_LinkClicked({
        param($sender,$e)
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "https://github.com/mccabedd/tinyredactiontool/"
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    })
    $panel.Controls.Add($link)
    $script:aboutY += $link.Height + 20

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Size = New-Object System.Drawing.Size(110,36)
    $btnClose.Location = New-Object System.Drawing.Point((($contentWidth - 110) / 2), $script:aboutY)
    $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
    Style-FlatButton $btnClose $true
    $btnClose.BackColor = $cAccent
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.FlatAppearance.BorderColor = $cAccent
    $panel.Controls.Add($btnClose)
    $script:aboutY += $btnClose.Height + 10

    $panel.Size = New-Object System.Drawing.Size($contentWidth, $script:aboutY)
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgWidth, ($script:aboutY + 40))
    $dlg.AcceptButton = $btnClose

    $dlg.ShowDialog($form) | Out-Null
    $dlg.Dispose()
}

$btnInfo.Add_Click({ Show-AboutDialog })

$rbModeBlur.Add_CheckedChanged({
    if ($rbModeBlur.Checked) { Show-VisualObscurationWarning }
})
$rbModePixelate.Add_CheckedChanged({
    if ($rbModePixelate.Checked) { Show-VisualObscurationWarning }
})

foreach ($r in @($rbRectangle,$rbOval,$rbFreeform,$rbModeBlack,$rbModeBlur,$rbModePixelate)) {
    $r.Add_CheckedChanged({ Apply-Theme })
}

Apply-Theme

# ----------------------------
# Geometry mapping
# ----------------------------
function Get-DisplayedImageRect {
    if (-not $picture.Image) { return $null }
 
    $pbW = $picture.ClientSize.Width
    $pbH = $picture.ClientSize.Height
    $imgW = $picture.Image.Width
    $imgH = $picture.Image.Height
 
    if ($pbW -le 0 -or $pbH -le 0 -or $imgW -le 0 -or $imgH -le 0) { return $null }
 
    $scale = [Math]::Min($pbW / $imgW, $pbH / $imgH)
    $w = [int]($imgW * $scale)
    $h = [int]($imgH * $scale)
    $x = [int](($pbW - $w) / 2)
    $y = [int](($pbH - $h) / 2)
 
    return New-Object System.Drawing.Rectangle($x,$y,$w,$h)
}
 
function Clamp-PointToImage([System.Drawing.Point]$pt) {
    $r = Get-DisplayedImageRect
    if (-not $r) { return $pt }
 
    $x = [Math]::Max($r.Left, [Math]::Min($pt.X, $r.Right - 1))
    $y = [Math]::Max($r.Top, [Math]::Min($pt.Y, $r.Bottom - 1))
    return New-Object System.Drawing.Point($x,$y)
}
 
function Selection-To-VideoRect {
    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect -or $selection.Width -lt 2 -or $selection.Height -lt 2) { return $null }
 
    $rawX = ($selection.X - $imgRect.X) * $videoWidth / $imgRect.Width
    $rawY = ($selection.Y - $imgRect.Y) * $videoHeight / $imgRect.Height
    $rawW = $selection.Width * $videoWidth / $imgRect.Width
    $rawH = $selection.Height * $videoHeight / $imgRect.Height
 
    return Normalize-VideoRect $rawX $rawY $rawW $rawH
}
 
function VideoRect-To-Display($vx, $vy, $vw, $vh) {
    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect -or $videoWidth -le 0 -or $videoHeight -le 0) { return $null }
 
    $x = [int]($imgRect.X + ($vx * $imgRect.Width / $videoWidth))
    $y = [int]($imgRect.Y + ($vy * $imgRect.Height / $videoHeight))
    $w = [int]($vw * $imgRect.Width / $videoWidth)
    $h = [int]($vh * $imgRect.Height / $videoHeight)
 
    return New-Object System.Drawing.Rectangle($x,$y,$w,$h)
}
 
function VideoPoints-To-DisplayPoints($pts) {
    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect -or $videoWidth -le 0 -or $videoHeight -le 0) { return $null }
 
    $out = New-Object System.Collections.Generic.List[System.Drawing.Point]
    foreach ($p in $pts) {
        $dx = [int]($imgRect.X + ($p.X * $imgRect.Width / $videoWidth))
        $dy = [int]($imgRect.Y + ($p.Y * $imgRect.Height / $videoHeight))
        $out.Add((New-Object System.Drawing.Point($dx,$dy)))
    }
    return $out.ToArray()
}
 
function DisplayPoint-To-VideoPoint([System.Drawing.Point]$pt) {
    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect) { return $null }
 
    $vx = ($pt.X - $imgRect.X) * $videoWidth / $imgRect.Width
    $vy = ($pt.Y - $imgRect.Y) * $videoHeight / $imgRect.Height
    $vx = [Math]::Max(0, [Math]::Min($vx, $videoWidth - 1))
    $vy = [Math]::Max(0, [Math]::Min($vy, $videoHeight - 1))
    return @{ X = [int][Math]::Round($vx); Y = [int][Math]::Round($vy) }
}
 
# Converts a completed freeform click-path (display-space points) into a
# video-space Polygon shape descriptor: absolute video-space vertex points
# plus a normalized bounding box that fully contains every one of them.
function Polygon-To-VideoShape($displayPoints) {
    if ($displayPoints.Count -lt 3) { return $null }
 
    $vpts = @()
    foreach ($p in $displayPoints) {
        $vp = DisplayPoint-To-VideoPoint $p
        if (-not $vp) { return $null }
        $vpts += ,$vp
    }
 
    $minX = ($vpts | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum
    $maxX = ($vpts | ForEach-Object { $_.X } | Measure-Object -Maximum).Maximum
    $minY = ($vpts | ForEach-Object { $_.Y } | Measure-Object -Minimum).Minimum
    $maxY = ($vpts | ForEach-Object { $_.Y } | Measure-Object -Maximum).Maximum
 
    $bbox = Normalize-VideoRect $minX $minY ([Math]::Max(2, $maxX - $minX)) ([Math]::Max(2, $maxY - $minY))
    return @{ Shape = "Polygon"; X = $bbox.X; Y = $bbox.Y; W = $bbox.W; H = $bbox.H; Points = $vpts }
}
 
# Returns the shape descriptor for whatever is currently drawn-but-not-yet-
# committed (a finished drag for Rectangle/Oval, or a closed click-path for
# Polygon), or $null if there's nothing ready to become a redaction yet.
function Get-CurrentShapeVideoData {
    if ($toolMode -eq "Polygon") {
        if ($polygonActive -or $polygonPoints.Count -lt 3) { return $null }
        return Polygon-To-VideoShape $polygonPoints
    }
    else {
        $vr = Selection-To-VideoRect
        if (-not $vr) { return $null }
        return @{ Shape = $toolMode; X = $vr.X; Y = $vr.Y; W = $vr.W; H = $vr.H }
    }
}
 
# Draws one redaction's shape (committed, pending, or a preview) onto the
# PictureBox in video-space -> converted to display coordinates here, so the
# same function serves the Paint handler for both committed (green) and
# pending (orange) redactions.
function Draw-RedactionShape($gfx, $r, [System.Drawing.Color]$borderColor, [System.Drawing.Color]$fillColor) {
    $pen = New-Object System.Drawing.Pen($borderColor, 2)
    $brush = New-Object System.Drawing.SolidBrush($fillColor)
 
    if ($r.Shape -eq "Oval") {
        $dr = VideoRect-To-Display $r.X $r.Y $r.W $r.H
        if ($dr) {
            $gfx.FillEllipse($brush, $dr)
            $gfx.DrawEllipse($pen, $dr)
        }
    }
    elseif ($r.Shape -eq "Polygon") {
        $dpts = VideoPoints-To-DisplayPoints $r.Points
        if ($dpts -and $dpts.Count -ge 3) {
            $gfx.FillPolygon($brush, $dpts)
            $gfx.DrawPolygon($pen, $dpts)
        }
    }
    else {
        $dr = VideoRect-To-Display $r.X $r.Y $r.W $r.H
        if ($dr) {
            $gfx.FillRectangle($brush, $dr)
            $gfx.DrawRectangle($pen, $dr)
        }
    }
 
    $brush.Dispose()
    $pen.Dispose()
}
 
# Renders the per-redaction mask PNG used by Build-RedactionFilterComplex for
# non-rectangular shapes. Sized exactly to the redaction's bounding box (W x H)
# so it lines up pixel-for-pixel once ffmpeg overlays/alphamerges it back at
# (X,Y). "Black box" masks carry real alpha (transparent background, opaque
# black shape) and get overlaid directly; Blur/Pixelate masks are a plain
# white-shape-on-black image whose luma becomes the processed patch's alpha
# via `alphamerge`.
function New-ShapeMaskFile($r, [string]$outPath) {
    $bmp = New-Object System.Drawing.Bitmap([int]$r.W, [int]$r.H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
 
    $isBlackBox = ($r.Mode -eq "Black box")
    # SECURITY: opaque redaction masks must have binary coverage. AntiAlias
    # creates partially transparent edge pixels that blend source + replacement.
    # Blur/Pixelate keep their smoother mask edge because they are explicitly
    # visual-obscuration modes, not guaranteed irreversible redaction.
    $g.SmoothingMode = if ($isBlackBox) { [System.Drawing.Drawing2D.SmoothingMode]::None } else { [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias }
    if ($isBlackBox) {
        # Older redactions created before the Coloured Box picker existed
        # won't have a Color field - fall back to plain black, matching the
        # original hardcoded "black box" behavior exactly.
        $boxColor = if ($r.Color) { $r.Color } else { [System.Drawing.Color]::Black }
        $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
        $shapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $boxColor.R, $boxColor.G, $boxColor.B))
    }
    else {
        $g.Clear([System.Drawing.Color]::Black)
        $shapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    }
 
    if ($r.Shape -eq "Oval") {
        $g.FillEllipse($shapeBrush, 0, 0, $r.W, $r.H)
    }
    elseif ($r.Shape -eq "Polygon") {
        $pts = @()
        foreach ($p in $r.Points) {
            $pts += New-Object System.Drawing.Point(($p.X - $r.X), ($p.Y - $r.Y))
        }
        if ($pts.Count -ge 3) {
            $g.FillPolygon($shapeBrush, $pts)
            if ($isBlackBox) {
                # Export geometry has a 1 px larger bounding box. A 2 px hard
                # stroke therefore dilates a freeform boundary by ~1 px without
                # being clipped except at the actual media edge.
                $edgePen = New-Object System.Drawing.Pen($shapeBrush.Color, 2)
                $edgePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
                $g.DrawPolygon($edgePen, $pts)
                $edgePen.Dispose()
            }
        }
    }
 
    $shapeBrush.Dispose()
    $g.Dispose()
 
    if (Test-Path $outPath) { Remove-Item $outPath -Force -ErrorAction SilentlyContinue }
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}
 
# ----------------------------
# UI state helpers
# ----------------------------
# Paints a Begin/End/Create-Redaction button as either its theme-neutral
# "grey" (inactive) look, or a fixed "green" (ready to begin) / "red"
# (in progress, ready to end) status color. Called from Update-RedactionButtons
# any time enable state changes, and from the theme-toggle handler so the
# grey state stays in sync with the active theme.
function Set-RedactionButtonColor([System.Windows.Forms.Button]$btn, [string]$state) {
    switch ($state) {
        "green" {
            $btn.BackColor = $script:colorGreenBg
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = $script:colorGreenBorder
        }
        "red" {
            $btn.BackColor = $script:colorRedBg
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = $script:colorRedBorder
        }
        default {
            $btn.BackColor = $script:cButtonCurrent
            $btn.ForeColor = $script:cTextCurrent
            $btn.FlatAppearance.BorderColor = $script:cBorderCurrent
        }
    }
}

function Update-RedactionButtons {
    $hasVideo = [bool]$videoPath
    $hasSelection = [bool](Get-CurrentShapeVideoData)

    if ($isImageMode) {
        # Images have no "in progress" state -- a selection is created in
        # one step, so $btnAddRedaction is just ready (green) or not (grey).
        $btnAddRedaction.Enabled = ($hasVideo -and $hasSelection)
        Set-RedactionButtonColor $btnAddRedaction $(if ($btnAddRedaction.Enabled) { "green" } else { "grey" })
        $rbRectangle.Enabled = $true
        $rbOval.Enabled = $true
        $rbFreeform.Enabled = $true
        $rbModeBlack.Enabled = $true; $rbModeBlur.Enabled = $true; $rbModePixelate.Enabled = $true
    }
    elseif ($pendingRedaction) {
        # A redaction range has been begun: Begin goes inactive/grey, End
        # becomes the active, red "finish it" action.
        $btnStartRedaction.Enabled = $false
        Set-RedactionButtonColor $btnStartRedaction "grey"
        $btnEndRedaction.Enabled = $true
        Set-RedactionButtonColor $btnEndRedaction "red"
        $btnCancelRedaction.Enabled = $true
        $rbModeBlack.Enabled = $false; $rbModeBlur.Enabled = $false; $rbModePixelate.Enabled = $false
        $rbRectangle.Enabled = $false
        $rbOval.Enabled = $false
        $rbFreeform.Enabled = $false
    }
    else {
        # No redaction in progress: Begin turns green as soon as there's a
        # selection to start from; End stays inactive/grey either way.
        $btnStartRedaction.Enabled = ($hasVideo -and $hasSelection)
        Set-RedactionButtonColor $btnStartRedaction $(if ($btnStartRedaction.Enabled) { "green" } else { "grey" })
        $btnEndRedaction.Enabled = $false
        Set-RedactionButtonColor $btnEndRedaction "grey"
        $btnCancelRedaction.Enabled = $false
        $rbModeBlack.Enabled = $true; $rbModeBlur.Enabled = $true; $rbModePixelate.Enabled = $true
        $rbRectangle.Enabled = $true
        $rbOval.Enabled = $true
        $rbFreeform.Enabled = $true
    }

    $btnExport.Enabled = ($hasVideo -and $redactions.Count -gt 0)
    $btnEyedropper.Enabled = $hasVideo
}
 
function Refresh-RedactionList {
    $lvRedactions.Items.Clear()
    for ($i = 0; $i -lt $redactions.Count; $i++) {
        $r = $redactions[$i]
        $item = New-Object System.Windows.Forms.ListViewItem(($i+1).ToString())
        [void]$item.SubItems.Add($r.Shape)
        [void]$item.SubItems.Add($r.Mode)
        [void]$item.SubItems.Add("$(SecToText $r.MarkStart) - $(SecToText $r.MarkEnd)")
        [void]$item.SubItems.Add("$(SecToText $r.BufferedStart) - $(SecToText $r.BufferedEnd)")
        [void]$item.SubItems.Add("x=$($r.X), y=$($r.Y), w=$($r.W), h=$($r.H)")
        [void]$lvRedactions.Items.Add($item)
    }
    $scrubberMarkers.Invalidate()
    # A committed redaction's shape can be showing on the current preview
    # frame; any time the list changes (added, removed, cleared) that overlay
    # may need to appear or disappear, so repaint the preview too.
    $picture.Invalidate()
    # Selection can end up cleared (e.g. after Remove/Clear All) without a
    # SelectedIndexChanged event always firing predictably - refresh the
    # swatch explicitly so it never keeps showing a just-deleted redaction's
    # color as if it were still the active edit target.
    Update-ColorSwatch
}
 
function Stop-Playback {
    if ($isPlaying) {
        $script:isPlaying = $false
        $playTimer.Stop()
        $btnPlayPause.Image = Get-IconImage "play"
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
    }
}
 
# Clears whatever is currently being drawn (an in-progress drag, or an
# in-progress/just-closed freeform click-path) without touching any already
# committed or pending redaction. Called whenever the tool changes, a
# redaction is started/ended/cancelled, or a new file is loaded.
function Reset-DrawingState {
    $script:dragging = $false
    $script:selection = New-Object System.Drawing.Rectangle(0,0,0,0)
    $script:polygonActive = $false
    $script:polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.Point]
    $script:polygonMousePos = $null
    $script:movingShape = $false
    $script:moveOrigSelection = $null
    $script:moveOrigPolygonPoints = $null
    if ($picture) { $picture.Invalidate() }
}
 
function Reset-RedactionState {
    $script:redactions = New-Object System.Collections.ArrayList
    $script:pendingRedaction = $null
    Reset-DrawingState
    Update-SelectionFields $null
    $lblPending.Text = "No redaction in progress."
    Refresh-RedactionList
}
 
# Swaps the handful of UI bits that read differently depending on whether a
# video or a still image is currently loaded: the Start/End/Cancel Redaction
# workflow (buffered time ranges) doesn't make sense for a single image, so
# that becomes one "Add Redaction" button, and video-only controls (audio,
# quality) are hidden. "Open video/file..." itself never changes - it always
# accepts either kind of file.
function Apply-ModeLabels {
    if ($isImageMode) {
        $lblHint.Text = "Load an image, drag a shape over the area to hide, pick a mode, then Create Redaction. Repeat for more redactions, then Export."
        $lblPos.Text = "Preview:"
        $btnExport.Text = "Export Redacted Image"
        $lblBufferNote.Text = "Redactions apply to the whole image - there's no timeline (and so no before/after buffer) for a still image."
        $btnStartRedaction.Visible = $false
        $btnEndRedaction.Visible = $false
        $btnCancelRedaction.Visible = $false
        $lblPending.Visible = $false
        $btnAddRedaction.Visible = $true
        $chkAudio.Visible = $false
        $lblQuality.Visible = $false
        $cmbQuality.Visible = $false
        $lvRedactions.Columns[3].Width = 0
        $lvRedactions.Columns[4].Width = 0

        # Output format list swaps to the image container set. Default: PNG.
        $cmbFormat.Items.Clear()
        $cmbFormat.Items.AddRange($IMAGE_FORMATS)
        $cmbFormat.SelectedIndex = 0
    }
    else {
        $lblHint.Text = "Load a video, step to a frame, drag a shape, then Begin Redaction ... move to the end frame ... End Redaction. Repeat for more redactions, then Export."
        $lblPos.Text = "Preview frame:"
        $btnExport.Text = "Export Redacted Video"
        $lblBufferNote.Text = "Every redaction is padded automatically by $BUFFER_FRAMES frames before and after the marked range."
        $btnStartRedaction.Visible = $true
        $btnEndRedaction.Visible = $true
        $btnCancelRedaction.Visible = $true
        $lblPending.Visible = $true
        $btnAddRedaction.Visible = $false
        $chkAudio.Visible = $true
        $lblQuality.Visible = $true
        $cmbQuality.Visible = $true
        $lvRedactions.Columns[3].Width = 145
        $lvRedactions.Columns[4].Width = 0

        # Output format list swaps to the video container set. Default: MP4.
        $cmbFormat.Items.Clear()
        $cmbFormat.Items.AddRange($VIDEO_FORMATS)
        $cmbFormat.SelectedIndex = 0
    }
}
 
# ----------------------------
# Preview extraction
# ----------------------------
function Load-PreviewFrame {
    if (-not $videoPath) { return }
    if ($previewImage -and $loadedFrame -eq $currentFrame) { return }

    $status.Text = if ($isImageMode) { "Loading image..." } else { "Loading preview frame..." }
    $form.Refresh()

    # Extracted frames used to be written to a temp PNG in %TEMP% and then
    # deleted once loaded - if the app or Windows crashed in the narrow
    # window between those two steps, that PNG (a full frame of whatever is
    # on screen, including anything the user is about to redact) could be
    # left behind on disk indefinitely. Piping ffmpeg's output straight into
    # this process's own memory instead removes that window entirely: the
    # frame is never written to a file at all, so there is nothing on disk
    # to leak even if PowerShell, ffmpeg, or Windows itself dies mid-extract.
    #
    # Runs FFmpeg to extract exactly the logical frame identified by the trusted
    # frame map. The selector compares the decoded frame PTS to FFprobe's exact
    # best_effort_timestamp; it never asks FFmpeg for "whatever frame is near"
    # a floating-point time. -copyts keeps source PTS intact across the coarse
    # seek. If the exact mapped PTS is not decoded, extraction returns no frame
    # and TinyRedactionTool fails closed rather than showing a neighbour.
    $tryExtractFrame = {
        param([int]$targetFrame)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $ffmpeg
        if ($isImageMode) {
            # A still image has no timeline to seek within - just decode it (via
            # ffmpeg rather than System.Drawing so formats like .webp, which GDI+
            # doesn't understand, work the same as everything else here).
            $psi.Arguments = "-hide_banner -nostdin -loglevel error -autorotate -i " + (Quote-Arg $videoPath) + " -map 0:v:0 -frames:v 1 -f image2pipe -vcodec png pipe:1"
        }
        else {
            if (-not $frameTimeline -or -not $frameTimeline.Ok -or
                -not $frameTimeline.Timestamps -or -not $frameTimeline.Times -or
                $targetFrame -lt 0 -or $targetFrame -ge $frameTimeline.Timestamps.Length -or
                $targetFrame -ge $frameTimeline.Times.Length) {
                return @{ Ok = $false; Err = "The exact frame timing map is unavailable for this preview frame."; Bytes = @() }
            }

            $targetPts = [int64]$frameTimeline.Timestamps[$targetFrame]
            $targetSeconds = [double]$frameTimeline.Times[$targetFrame]
            $coarse = [Math]::Max(0.0, $targetSeconds - 2.0)
            $coarseText = Format-FFmpegSeconds $coarse
            $ptsText = $targetPts.ToString([System.Globalization.CultureInfo]::InvariantCulture)
            $selectExpr = "select='eq(pts\,$ptsText)'"

            # SECURITY: -copyts is essential here. Input -ss is only a decode
            # accelerator; frame identity is decided solely by exact source PTS.
            $psi.Arguments = "-hide_banner -nostdin -loglevel error -copyts -ss $coarseText -autorotate -i " + (Quote-Arg $videoPath) + " -map 0:v:0 -vf " + (Quote-Arg $selectExpr) + " -frames:v 1 -f image2pipe -vcodec png pipe:1"
        }
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)

        # Read stdout (the PNG bytes) and stderr concurrently - reading them
        # one after another can deadlock if ffmpeg fills one pipe's OS buffer
        # while waiting for the other end to be drained.
        $stdoutMs = New-Object System.IO.MemoryStream
        $copyTask = $proc.StandardOutput.BaseStream.CopyToAsync($stdoutMs)
        $stderrText = $proc.StandardError.ReadToEnd()
        $copyTask.GetAwaiter().GetResult()
        $proc.WaitForExit()

        $bytes = $stdoutMs.ToArray()
        $stdoutMs.Dispose()

        return @{ Ok = ($proc.ExitCode -eq 0 -and $bytes.Length -gt 0); Err = $stderrText; Bytes = $bytes }
    }.GetNewClosure()

    $result = & $tryExtractFrame $currentFrame

    if (-not $result.Ok) {
        $status.Text = "Couldn't extract preview frame."
        [System.Windows.Forms.MessageBox]::Show(
            "FFmpeg couldn't extract the exact mapped preview frame.`r`n`r`n$(Get-SafeFFmpegError $result.Err $videoPath)",
            "Preview error",
            "OK",
            "Error"
        ) | Out-Null
        return
    }

    if ($previewImage) {
        $picture.Image = $null
        $previewImage.Dispose()
        $script:previewImage = $null
    }
 
    $ms = New-Object System.IO.MemoryStream(,$result.Bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    $script:previewImage = New-Object System.Drawing.Bitmap($img)
    $img.Dispose()
    $ms.Dispose()
 
    $picture.Image = $previewImage
    $picture.Refresh()
    $script:loadedFrame = $currentFrame
    $picture.Invalidate()
 
    $status.Text = "Preview loaded."
}
 
function Set-PlaybackIntervalForFrame([int]$frameIndex) {
    if ($isImageMode -or -not $frameTimeline) { return }
    $frameDuration = Get-FramePresentationDuration $frameIndex
    if ([double]::IsNaN($frameDuration) -or [double]::IsInfinity($frameDuration) -or $frameDuration -le 0.0) { return }
    $intervalMs = [Math]::Round($frameDuration * 1000.0)
    if ($intervalMs -lt 1) { $intervalMs = 1 }
    if ($intervalMs -gt [int]::MaxValue) { $intervalMs = [int]::MaxValue }
    $playTimer.Interval = [int]$intervalMs
}

function Step-Frame([int]$delta) {
    if (-not $videoPath -or $isImageMode -or $totalFrames -le 0) { return }
 
    $newFrame = [Math]::Max(0, [Math]::Min($currentFrame + $delta, $totalFrames - 1))
    if ($newFrame -eq $currentFrame) { return }

    $mappedTime = Get-FramePresentationTime $newFrame
    if ([double]::IsNaN($mappedTime) -or [double]::IsInfinity($mappedTime)) {
        Stop-Playback
        $status.Text = "Frame timing is unavailable; playback stopped."
        return
    }
 
    $script:currentFrame = $newFrame
    $script:previewSeconds = $mappedTime
    $seekBar.Invalidate()
    $lblPosValue.Text = SecToText $previewSeconds
    $lblFrameCount.Text = "Frame $($currentFrame + 1) / $totalFrames"

    # If playback is active, the next tick should wait for this frame's actual
    # presentation duration rather than a synthetic 1/fps interval.
    Set-PlaybackIntervalForFrame $currentFrame
    $previewTimer.Stop()
    Load-PreviewFrame
}
 
# ----------------------------
# Events
# ----------------------------
$btnOpen.Add_Click({
    Stop-Playback

    $openFilter = "Video or image|*.mp4;*.mov;*.m4v;*.avi;*.mkv;*.webm;*.wmv;*.asf;*.mpg;*.mpeg;*.mpe;*.vob;*.ts;*.mts;*.m2ts;*.m2t;*.flv;*.3gp;*.3g2;*.f4v;*.ogv;*.rm;*.rmvb;*.mxf;*.wtv;*.dv;*.mjpeg;*.mjpg;*.mlv;*.r3d;*.jpg;*.jpeg;*.jpe;*.png;*.apng;*.gif;*.webp;*.bmp;*.tif;*.tiff;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|Video files|*.mp4;*.mov;*.m4v;*.avi;*.mkv;*.webm;*.wmv;*.asf;*.mpg;*.mpeg;*.mpe;*.vob;*.ts;*.mts;*.m2ts;*.m2t;*.flv;*.3gp;*.3g2;*.f4v;*.ogv;*.rm;*.rmvb;*.mxf;*.wtv;*.dv;*.mjpeg;*.mjpg;*.mlv;*.r3d|Image files|*.jpg;*.jpeg;*.jpe;*.png;*.apng;*.gif;*.webp;*.bmp;*.tif;*.tiff;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|All files|*.*"
    try {
        $selectedPath = [SecureFileDialogNativeV2]::ShowOpen($form.Handle, $openFilter, "Choose a video or image")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(("Windows could not open the secure file-selection dialog.`r`n`r`n" + $_.Exception.Message), "File dialog error", "OK", "Error") | Out-Null
        return
    }
    if ([string]::IsNullOrWhiteSpace($selectedPath)) { return }

    $networkReason = Get-NetworkPathReason $selectedPath
    if ($networkReason) {
        # UNC and mapped-network sources are permitted after an explicit warning.
        # No patient filename/path is logged or persisted by this warning.
        if (-not (Show-NetworkLocationWarning "Source")) { return }
    }

    $ext = [System.IO.Path]::GetExtension($selectedPath).ToLowerInvariant()
    $newImageMode = $ext -in @( ".jpg", ".jpeg", ".jpe", ".png", ".apng", ".gif", ".webp", ".bmp", ".tif", ".tiff", ".tga", ".dds", ".exr", ".hdr", ".dpx", ".jp2", ".j2k", ".j2c", ".jpc", ".jls", ".psd", ".pcx", ".qoi", ".avif", ".heic", ".heif" )

    $status.Text = if ($newImageMode) { "Inspecting image..." } else { "Analysing video frame timing and media geometry..." }
    $form.Refresh()
    $info = Get-VideoInfo $ffmpeg $ffprobe $selectedPath $newImageMode
    if (-not $info.IsSafe) {
        $status.Text = "File not opened."
        [System.Windows.Forms.MessageBox]::Show(
            $info.Error,
            "Media safety check failed",
            "OK",
            "Error"
        ) | Out-Null
        return
    }

    $script:videoPath = $selectedPath
    $script:isImageMode = $newImageMode
    $script:videoWidth = $info.Width
    $script:videoHeight = $info.Height
    $script:sourceHasAudio = [bool]$info.HasAudio
    $script:frameTimeline = $info.FrameTimeline
    # Audio is an explicit per-source opt-in. Changing/opening media always
    # returns the control to its secure default rather than carrying consent
    # from a previously opened file.
    $chkAudio.Checked = $false
    $lblFile.Text = $script:videoPath

    if ($videoWidth -le 0 -or $videoHeight -le 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "I couldn't read that file's display dimensions safely.",
            "File error",
            "OK",
            "Error"
        ) | Out-Null
        $script:videoPath = $null
        return
    }

    if ($isImageMode) {
        $script:videoDuration = 0.0
        $script:fps = 1.0
        $script:totalFrames = 1
        $script:currentFrame = 0
        $script:previewSeconds = 0.0
        $script:loadedFrame = -1
        $seekBar.Enabled = $false
        $seekBar.Invalidate()

        $btnRefresh.Enabled = $false
        $btnPrevFrame.Enabled = $false
        $btnNextFrame.Enabled = $false
        $btnPlayPause.Enabled = $false
        $btnPlayPause.Image = Get-IconImage "play"
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        $lblPosValue.Text = "n/a"
        $lblFrameCount.Text = "Image"
        $status.Text = "$videoWidth x $videoHeight   |   Still image"
    }
    else {
        $script:fps = $info.Fps  # informational average only; never a navigation authority
        $script:totalFrames = [int]$info.FrameCount
        if (-not $frameTimeline -or -not $frameTimeline.Ok -or
            -not $frameTimeline.Times -or -not $frameTimeline.Durations -or
            $frameTimeline.Times.Length -ne $totalFrames -or
            $frameTimeline.Durations.Length -ne $totalFrames) {
            [System.Windows.Forms.MessageBox]::Show(
                "The video's validated frame timeline is unavailable or inconsistent.",
                "Video error",
                "OK",
                "Error"
            ) | Out-Null
            $script:videoPath = $null
            return
        }
        $script:videoDuration = [double]$frameTimeline.Duration
        if ($videoDuration -le 0 -or $totalFrames -le 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "The video's frame timing could not be established safely.",
                "Video error",
                "OK",
                "Error"
            ) | Out-Null
            $script:videoPath = $null
            return
        }

        $script:currentFrame = 0
        $script:previewSeconds = Get-FramePresentationTime 0
        if ([double]::IsNaN($previewSeconds) -or [double]::IsInfinity($previewSeconds)) {
            [System.Windows.Forms.MessageBox]::Show(
                "The first frame does not have a usable presentation timestamp.",
                "Video error",
                "OK",
                "Error"
            ) | Out-Null
            $script:videoPath = $null
            return
        }
        Set-PlaybackIntervalForFrame 0
        $script:loadedFrame = -1
        $seekBar.Enabled = $true
        $seekBar.Invalidate()

        $btnRefresh.Enabled = $true
        $btnPrevFrame.Enabled = $true
        $btnNextFrame.Enabled = $true
        $btnPlayPause.Enabled = $true
        $btnPlayPause.Image = Get-IconImage "play"
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        $lblPosValue.Text = SecToText $previewSeconds
        $lblFrameCount.Text = "Frame 1 / $totalFrames"
        $timingStatus = if ($info.IsVfr) { "VFR timing verified" } else { "CFR timing verified" }
        $status.Text = "$videoWidth x $videoHeight   |   Duration: $(SecToText $videoDuration)   |   $([Math]::Round($fps,3)) avg fps   |   $timingStatus"
    }

    Apply-ModeLabels
    Reset-RedactionState
    Update-RedactionButtons
    $btnOpen.Text = "Change Video | Image"

    Load-PreviewFrame
})
 
$previewTimer = New-Object System.Windows.Forms.Timer
$previewTimer.Interval = 350
$previewTimer.Add_Tick({
    $previewTimer.Stop()
    if ($videoPath) { Load-PreviewFrame }
})
 
# "Play" steps forward one frame at a time through the same ffmpeg-per-frame
# extraction used everywhere else in this app. That extraction involves
# spawning a process per frame, so this will not play at true source frame
# rate on most machines - it's a best-effort scrub, not a smooth video
# player. Real smooth playback would need a live decoded-frame pipe read on
# a background thread with cross-thread UI updates, which is a materially
# riskier design to get right in a script like this.
$playTimer = New-Object System.Windows.Forms.Timer
$playTimer.Interval = 40
$playTimer.Add_Tick({
    if (-not $videoPath -or $currentFrame -ge $totalFrames - 1) {
        Stop-Playback
        return
    }
    Step-Frame 1
})
 
$btnPlayPause.Add_Click({
    if (-not $videoPath) { return }
    if ($isPlaying) {
        Stop-Playback
    }
    else {
        if ($currentFrame -ge $totalFrames - 1) {
            $script:currentFrame = 0
            $script:previewSeconds = Get-FramePresentationTime 0
            $lblPosValue.Text = SecToText $previewSeconds
            $lblFrameCount.Text = "Frame 1 / $totalFrames"
            $seekBar.Invalidate()
        }
        Set-PlaybackIntervalForFrame $currentFrame
        $script:isPlaying = $true
        $btnPlayPause.Image = Get-IconImage "pause"
        $script:appToolTip.SetToolTip($btnPlayPause, "Pause")
        $playTimer.Start()
    }
})

$btnRefresh.Add_Click({
    Stop-Playback
    $script:loadedFrame = -1
    Load-PreviewFrame
})

$btnPrevFrame.Add_Click({ Stop-Playback; Step-Frame -1 })
$btnNextFrame.Add_Click({ Stop-Playback; Step-Frame 1 })
 
$form.Add_KeyDown({
    param($sender,$e)
    if (-not $videoPath) { return }
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Left) {
        Stop-Playback
        Step-Frame -1
        $e.Handled = $true
    }
    elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Right) {
        Stop-Playback
        Step-Frame 1
        $e.Handled = $true
    }
    elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        if ($toolMode -eq "Polygon" -and ($polygonActive -or $polygonPoints.Count -gt 0)) {
            Reset-DrawingState
            Update-SelectionFields $null
            Update-RedactionButtons
            $e.Handled = $true
        }
    }
})
 
function Set-ToolMode([string]$mode) {
    if ($script:toolMode -eq $mode) { return }
    $script:toolMode = $mode
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
}
$rbRectangle.Add_CheckedChanged({ if ($rbRectangle.Checked) { Set-ToolMode "Rectangle" } })
$rbOval.Add_CheckedChanged({ if ($rbOval.Checked) { Set-ToolMode "Oval" } })
$rbFreeform.Add_CheckedChanged({ if ($rbFreeform.Checked) { Set-ToolMode "Polygon" } })
 
$picture.Add_MouseDown({
    param($sender,$e)
    if (-not $picture.Image) { return }

    # Eyedropper takes priority over everything else while armed: this click
    # samples a color rather than drawing/placing a shape, then disarms
    # itself either way (a stray click outside the image just cancels it).
    if ($eyedropperActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $imgRect = Get-DisplayedImageRect
            $pt = New-Object System.Drawing.Point($e.X,$e.Y)
            if ($imgRect -and $imgRect.Contains($pt) -and $previewImage) {
                $vp = DisplayPoint-To-VideoPoint $pt
                if ($vp) {
                    $sampled = $previewImage.GetPixel($vp.X, $vp.Y)
                    Set-ActiveRedactionColor $sampled
                }
            }
        }
        $script:eyedropperActive = $false
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        Set-RedactionButtonColor $btnEyedropper "grey"
        return
    }

    if ($pendingRedaction) { return }
 
    if ($toolMode -eq "Polygon" -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
        # Right-click cancels an in-progress freeform path.
        if ($polygonActive -or $polygonPoints.Count -gt 0) {
            Stop-Playback
            Reset-DrawingState
            Update-SelectionFields $null
            Update-RedactionButtons
        }
        return
    }
    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }
 
    Stop-Playback
 
    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect) { return }
 
    $pt = New-Object System.Drawing.Point($e.X,$e.Y)
    if (-not $imgRect.Contains($pt)) { return }
    $clamped = Clamp-PointToImage $pt
 
    if ($toolMode -eq "Polygon") {
        if (-not $polygonActive -and $polygonPoints.Count -ge 3 -and (Test-PointInPolygon $clamped $polygonPoints)) {
            # Clicked inside the closed-but-uncommitted path: move the whole
            # shape instead of starting a new one (see $movingShape).
            $script:movingShape = $true
            $picture.Capture = $true
            $script:moveStart = $clamped
            $script:moveOrigPolygonPoints = New-Object System.Collections.Generic.List[System.Drawing.Point]
            foreach ($pt in $polygonPoints) { [void]$script:moveOrigPolygonPoints.Add($pt) }
            $picture.Invalidate()
            return
        }
        if (-not $polygonActive) {
            # Starting fresh discards any previously closed-but-uncommitted path.
            $script:polygonActive = $true
            $script:polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.Point]
            $script:polygonPoints.Add($clamped)
            $script:polygonMousePos = $clamped
            Update-SelectionFields $null "Selection: freeform started (1 point). Click to add points; click the yellow start point to close (need at least 3)."
        }
        else {
            # Shift snaps this new segment (from the previous vertex to here)
            # to the nearest 0/45/90 degree angle, same modifier/behavior as
            # the Rectangle/Oval square-and-circle constrain above.
            $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
            $lastPolyPt = $polygonPoints[$polygonPoints.Count - 1]
            $clamped = Clamp-PointToImage (Get-AngleSnappedPoint $lastPolyPt $clamped $constrainAngle)
            $dxs = $clamped.X - $polygonPoints[0].X
            $dys = $clamped.Y - $polygonPoints[0].Y
            $distToStart = [Math]::Sqrt(($dxs * $dxs) + ($dys * $dys))
            if ($polygonPoints.Count -ge 3 -and $distToStart -le 10) {
                $script:polygonActive = $false
                Update-SelectionFields $null "Selection: freeform closed ($($polygonPoints.Count) points)."
            }
            else {
                $script:polygonPoints.Add($clamped)
                Update-SelectionFields $null "Selection: freeform, $($polygonPoints.Count) points (click the yellow start point to close)."
            }
        }
        Update-RedactionButtons
        $picture.Invalidate()
        return
    }
 
    if ($selection.Width -gt 1 -and $selection.Height -gt 1 -and $selection.Contains($clamped)) {
        # Clicked inside the existing uncommitted Rectangle/Oval selection:
        # move it instead of starting a new one (see $movingShape). This
        # uses the bounding box for Oval too, which is a deliberate, common
        # drawing-app simplification - clicking just inside a corner of an
        # oval's box still grabs and moves it.
        $script:movingShape = $true
        $picture.Capture = $true
        $script:moveStart = $clamped
        $script:moveOrigSelection = $selection
        $picture.Invalidate()
        return
    }

    # Rectangle / Oval: drag-based, as before.
    $script:dragging = $true
    $picture.Capture = $true
    $script:dragStart = $clamped
    $script:selection = New-Object System.Drawing.Rectangle($dragStart.X,$dragStart.Y,1,1)
    $picture.Invalidate()
})
 
$picture.Add_MouseMove({
    param($sender,$e)

    if ($movingShape) {
        $imgRect = Get-DisplayedImageRect
        if (-not $imgRect) { return }
        $rawPt = Clamp-PointToImage (New-Object System.Drawing.Point($e.X,$e.Y))
        $dx = $rawPt.X - $moveStart.X
        $dy = $rawPt.Y - $moveStart.Y

        if ($toolMode -eq "Polygon") {
            $origBounds = Get-PointsBoundingRect $moveOrigPolygonPoints
            $clampedD = Get-ClampedTranslation $origBounds $dx $dy $imgRect
            $newPoints = New-Object System.Collections.Generic.List[System.Drawing.Point]
            foreach ($origPt in $moveOrigPolygonPoints) {
                [void]$newPoints.Add((New-Object System.Drawing.Point(($origPt.X + $clampedD.Dx), ($origPt.Y + $clampedD.Dy))))
            }
            $script:polygonPoints = $newPoints
        }
        else {
            $clampedD = Get-ClampedTranslation $moveOrigSelection $dx $dy $imgRect
            $script:selection = New-Object System.Drawing.Rectangle(
                ($moveOrigSelection.X + $clampedD.Dx), ($moveOrigSelection.Y + $clampedD.Dy),
                $moveOrigSelection.Width, $moveOrigSelection.Height)
        }
        $picture.Invalidate()
        return
    }

    if ($toolMode -eq "Polygon") {
        if ($polygonActive) {
            $rawPt = Clamp-PointToImage (New-Object System.Drawing.Point($e.X,$e.Y))
            if ($polygonPoints.Count -gt 0) {
                $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
                $lastPolyPt = $polygonPoints[$polygonPoints.Count - 1]
                $rawPt = Clamp-PointToImage (Get-AngleSnappedPoint $lastPolyPt $rawPt $constrainAngle)
            }
            $script:polygonMousePos = $rawPt
            $picture.Invalidate()
        }
        elseif (-not $pendingRedaction -and $polygonPoints.Count -ge 3) {
            # Idle (not drawing, nothing pending): hint that the shape can be
            # picked up and dragged by swapping to a move cursor over it.
            $hoverPt = Clamp-PointToImage (New-Object System.Drawing.Point($e.X,$e.Y))
            $picture.Cursor = if (Test-PointInPolygon $hoverPt $polygonPoints) { [System.Windows.Forms.Cursors]::SizeAll } else { [System.Windows.Forms.Cursors]::Default }
        }
        return
    }
 
    if (-not $dragging) {
        if (-not $pendingRedaction -and $selection.Width -gt 1 -and $selection.Height -gt 1) {
            $hoverPt = Clamp-PointToImage (New-Object System.Drawing.Point($e.X,$e.Y))
            $picture.Cursor = if ($selection.Contains($hoverPt)) { [System.Windows.Forms.Cursors]::SizeAll } else { [System.Windows.Forms.Cursors]::Default }
        }
        return
    }
 
    $pt = New-Object System.Drawing.Point($e.X,$e.Y)
    $p = Clamp-PointToImage $pt
 
    # Shift constrains Rectangle to a square / Oval to a circle, by forcing
    # equal width/height while keeping the drag's original direction on each
    # axis. Checked live (not just at drag-start) so toggling Shift mid-drag
    # takes effect immediately.
    $constrain = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
    $delta = Get-ConstrainedDelta ($p.X - $dragStart.X) ($p.Y - $dragStart.Y) $constrain
 
    $x = [Math]::Min($dragStart.X, $dragStart.X + $delta.Dx)
    $y = [Math]::Min($dragStart.Y, $dragStart.Y + $delta.Dy)
    $w = [Math]::Max(1, [Math]::Abs($delta.Dx))
    $h = [Math]::Max(1, [Math]::Abs($delta.Dy))
 
    $script:selection = New-Object System.Drawing.Rectangle($x,$y,$w,$h)
    $picture.Invalidate()
})
 
$picture.Add_MouseUp({
    param($sender,$e)
    if ($movingShape) {
        $script:movingShape = $false
        $picture.Capture = $false
        $script:moveOrigSelection = $null
        $script:moveOrigPolygonPoints = $null
        Update-SelectionFields (Get-CurrentShapeVideoData) "Selection moved."
        Update-RedactionButtons
        $picture.Invalidate()
        return
    }
    if ($toolMode -eq "Polygon") { return }
    if (-not $dragging) { return }
    $script:dragging = $false
    $picture.Capture = $false
 
    $vr = Selection-To-VideoRect
    Update-SelectionFields $vr
    Update-RedactionButtons
    $picture.Invalidate()
})
 
# Crops the given video/image-pixel-space rectangle out of $previewImage and
# returns a small Bitmap with the actual Blur or Pixelate effect applied to
# it - the same two-step scale-down/scale-up technique Build-RedactionFilterComplex
# uses for the real ffmpeg export (nearest-neighbor for Pixelate; here, Blur
# uses a bicubic resample instead of ffmpeg's boxblur, since GDI+ has no
# built-in blur filter - it's a close enough visual approximation for a live
# preview, not a claim of pixel-identical output). Returns $null for "Black
# box" (the caller just fills solid black directly - no source pixels needed)
# or if there's no loaded image to sample from.
function Get-LiveEffectPatch([string]$mode, [int]$sx, [int]$sy, [int]$sw, [int]$sh, [int]$strength = 5) {
    if (-not $previewImage -or $sw -le 0 -or $sh -le 0) { return $null }
    if ($mode -ne "Blur" -and $mode -ne "Pixelate") { return $null }

    $sx = [Math]::Max(0, [Math]::Min($sx, $previewImage.Width - 1))
    $sy = [Math]::Max(0, [Math]::Min($sy, $previewImage.Height - 1))
    $sw = [Math]::Max(1, [Math]::Min($sw, $previewImage.Width - $sx))
    $sh = [Math]::Max(1, [Math]::Min($sh, $previewImage.Height - $sy))
    $srcRect = New-Object System.Drawing.Rectangle($sx,$sy,$sw,$sh)

    $divisor = if ($mode -eq "Blur") { Get-BlurLiveDivisor $strength } else { Get-PixelateDivisor $strength }
    $interp = if ($mode -eq "Blur") {
        [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    } else {
        [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    }
    $smallW = [Math]::Max(1, [int]($sw / $divisor))
    $smallH = [Math]::Max(1, [int]($sh / $divisor))

    # GDI+'s Graphics.DrawImage defaults to WrapMode.Tile for its internal
    # sampling. With interpolation (bicubic here) that means pixels near the
    # edge of the destination rectangle get blended against pixels wrapped in
    # from the OPPOSITE edge of the source, rather than clamped/extended from
    # the nearest source edge. The blend band this produces is a fixed number
    # of SOURCE pixels wide, but gets mapped to a growing number of
    # DESTINATION pixels as the upscale factor increases (i.e. as the strength
    # slider - via Get-BlurLiveDivisor - shrinks $tiny more before blowing it
    # back up) - visually that band looks like an unblurred/"clean" edge
    # eating inward, i.e. the blurred area appears to shrink as strength goes
    # up. Passing an ImageAttributes with WrapMode.TileFlipXY makes GDI+
    # mirror-extend at the edges instead of wrapping around, which removes
    # that artifact regardless of how far the image is scaled.
    $wrapAttr = New-Object System.Drawing.Imaging.ImageAttributes
    $wrapAttr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)

    $tiny = New-Object System.Drawing.Bitmap($smallW, $smallH)
    $tg = [System.Drawing.Graphics]::FromImage($tiny)
    $tg.InterpolationMode = $interp
    $tg.DrawImage($previewImage, (New-Object System.Drawing.Rectangle(0,0,$smallW,$smallH)), $srcRect.X, $srcRect.Y, $srcRect.Width, $srcRect.Height, [System.Drawing.GraphicsUnit]::Pixel, $wrapAttr)
    $tg.Dispose()

    $patch = New-Object System.Drawing.Bitmap($sw, $sh)
    $g = [System.Drawing.Graphics]::FromImage($patch)
    $g.InterpolationMode = $interp
    $g.DrawImage($tiny, (New-Object System.Drawing.Rectangle(0,0,$sw,$sh)), 0, 0, $smallW, $smallH, [System.Drawing.GraphicsUnit]::Pixel, $wrapAttr)
    $g.Dispose()
    $tiny.Dispose()
    $wrapAttr.Dispose()

    return $patch
}

# Image-mode counterpart to Draw-RedactionShape: instead of a translucent
# color tint standing in for the redaction, this composites the REAL effect
# (the actual blurred/pixelated/blacked pixels, sampled from $previewImage)
# onto the preview, clipped to the exact shape. Only used in image mode -
# there's a single static frame to sample from, so this stays cheap; video
# mode keeps the lighter tint overlay, since re-sampling/re-blurring a fresh
# source frame on every drag or frame step would be far more expensive there.
function Draw-RedactionShapeLiveEffect($gfx, $r, [System.Drawing.Color]$borderColor) {
    $pen = New-Object System.Drawing.Pen($borderColor, 2)

    if ($r.Mode -eq "Black box") {
        $brush = New-Object System.Drawing.SolidBrush((Get-RedactionColor $r))
        if ($r.Shape -eq "Oval") {
            $dr = VideoRect-To-Display $r.X $r.Y $r.W $r.H
            if ($dr) { $gfx.FillEllipse($brush, $dr); $gfx.DrawEllipse($pen, $dr) }
        }
        elseif ($r.Shape -eq "Polygon") {
            $dpts = VideoPoints-To-DisplayPoints $r.Points
            if ($dpts -and $dpts.Count -ge 3) { $gfx.FillPolygon($brush, $dpts); $gfx.DrawPolygon($pen, $dpts) }
        }
        else {
            $dr = VideoRect-To-Display $r.X $r.Y $r.W $r.H
            if ($dr) { $gfx.FillRectangle($brush, $dr); $gfx.DrawRectangle($pen, $dr) }
        }
        $brush.Dispose()
        $pen.Dispose()
        return
    }

    $dr = VideoRect-To-Display $r.X $r.Y $r.W $r.H
    if (-not $dr) { $pen.Dispose(); return }
    $liveStrength = if ($r.Strength) { [int]$r.Strength } else { 5 }
    $patch = Get-LiveEffectPatch $r.Mode $r.X $r.Y $r.W $r.H $liveStrength
    if (-not $patch) { $pen.Dispose(); return }

    if ($r.Shape -eq "Oval") {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddEllipse($dr)
        $savedClip = $gfx.Clip.Clone()
        $gfx.SetClip($path, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        $gfx.DrawImage($patch, $dr)
        $gfx.Clip = $savedClip
        $gfx.DrawEllipse($pen, $dr)
        $path.Dispose()
    }
    elseif ($r.Shape -eq "Polygon") {
        $dpts = VideoPoints-To-DisplayPoints $r.Points
        if ($dpts -and $dpts.Count -ge 3) {
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $path.AddPolygon($dpts)
            $savedClip = $gfx.Clip.Clone()
            $gfx.SetClip($path, [System.Drawing.Drawing2D.CombineMode]::Intersect)
            $gfx.DrawImage($patch, $dr)
            $gfx.Clip = $savedClip
            $gfx.DrawPolygon($pen, $dpts)
        }
    }
    else {
        $gfx.DrawImage($patch, $dr)
        $gfx.DrawRectangle($pen, $dr)
    }

    $patch.Dispose()
    $pen.Dispose()
}

$picture.Add_Paint({
    param($sender,$e)

    # Already-committed redactions: show each one's shape whenever the
    # current frame falls within its exact buffered frame range, so scrubbing
    # back over an earlier redaction shows you what's covered where. Frame
    # membership never depends on seconds or average FPS. Still-image entries
    # use frame 0 for every range field, so no special-case is needed here.
    # In image mode this shows the real applied effect rather than a
    # translucent tint, since there's just one static frame to composite against.
    foreach ($r in $redactions) {
        if (Test-FrameInRange $currentFrame $r.BufferedStartFrame $r.BufferedEndFrame) {
            if ($isImageMode) {
                Draw-RedactionShapeLiveEffect $e.Graphics $r ([System.Drawing.Color]::Lime)
            }
            elseif ($r.Mode -eq "Black box") {
                # Show the redaction's own assigned color while scrubbing,
                # rather than the generic green marker used for Blur/Pixelate,
                # so it's obvious at a glance which box is which color.
                $boxColor = Get-RedactionColor $r
                $fillTint = [System.Drawing.Color]::FromArgb(90, $boxColor.R, $boxColor.G, $boxColor.B)
                Draw-RedactionShape $e.Graphics $r $boxColor $fillTint
            }
            else {
                Draw-RedactionShape $e.Graphics $r ([System.Drawing.Color]::Lime) ([System.Drawing.Color]::FromArgb(60,0,255,0))
            }
        }
    }
 
    if ($pendingRedaction) {
        # The timeline only moves forward from here: a pending redaction has
        # a start but no end yet, so it should show on its start frame and
        # every frame after, until End Redaction gives it an end. It should
        # NOT show on frames before the start.
        if ($currentFrame -ge $pendingRedaction.StartFrame) {
            Draw-RedactionShape $e.Graphics $pendingRedaction ([System.Drawing.Color]::Orange) ([System.Drawing.Color]::FromArgb(60,255,165,0))
        }
    }
    elseif ($toolMode -eq "Polygon") {
        if ($polygonPoints.Count -gt 0) {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
            for ($i = 0; $i -lt $polygonPoints.Count - 1; $i++) {
                $e.Graphics.DrawLine($pen, $polygonPoints[$i], $polygonPoints[$i+1])
            }
 
            if ($polygonActive -and $polygonMousePos) {
                $dashPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
                $dashPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
                $e.Graphics.DrawLine($dashPen, $polygonPoints[$polygonPoints.Count - 1], $polygonMousePos)
                $dashPen.Dispose()
            }
            elseif (-not $polygonActive -and $polygonPoints.Count -ge 3) {
                # Closed but not yet committed via Begin/Create Redaction.
                if ($isImageMode) {
                    $shapeData = Polygon-To-VideoShape $polygonPoints
                    if ($shapeData) {
                        $shapeData.Mode = Get-SelectedMode
                        $shapeData.Strength = $redactionStrength
                        $shapeData.Color = $redactionColor
                        Draw-RedactionShapeLiveEffect $e.Graphics $shapeData ([System.Drawing.Color]::Red)
                    }
                }
                else {
                    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55,255,0,0))
                    $e.Graphics.FillPolygon($brush, $polygonPoints.ToArray())
                    $e.Graphics.DrawPolygon($pen, $polygonPoints.ToArray())
                    $brush.Dispose()
                }
            }
 
            # Marker on the start point, so it's obvious where to click to close.
            $startPt = $polygonPoints[0]
            $markerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $e.Graphics.FillEllipse($markerBrush, ($startPt.X - 4), ($startPt.Y - 4), 8, 8)
            $e.Graphics.DrawEllipse($pen, ($startPt.X - 4), ($startPt.Y - 4), 8, 8)
            $markerBrush.Dispose()
            $pen.Dispose()
        }
    }
    elseif ($selection.Width -gt 0 -and $selection.Height -gt 0) {
        if ($isImageMode) {
            $vr = Selection-To-VideoRect
            if ($vr) {
                $shapeData = @{
                    Shape = if ($toolMode -eq "Oval") { "Oval" } else { "Rectangle" }
                    X = $vr.X; Y = $vr.Y; W = $vr.W; H = $vr.H
                    Mode = Get-SelectedMode
                    Strength = $redactionStrength
                    Color = $redactionColor
                }
                Draw-RedactionShapeLiveEffect $e.Graphics $shapeData ([System.Drawing.Color]::Red)
            }
        }
        else {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55,255,0,0))
            if ($toolMode -eq "Oval") {
                $e.Graphics.FillEllipse($brush, $selection)
                $e.Graphics.DrawEllipse($pen, $selection)
            }
            else {
                $e.Graphics.FillRectangle($brush, $selection)
                $e.Graphics.DrawRectangle($pen, $selection)
            }
            $brush.Dispose()
            $pen.Dispose()
        }
    }
})
 
$scrubberMarkers.Add_Paint({
    param($sender,$e)
    if ($videoDuration -le 0 -or $redactions.Count -eq 0) { return }
 
    $w = $scrubberMarkers.ClientSize.Width
    $midY = [int]($scrubberMarkers.ClientSize.Height / 2)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
 
    foreach ($r in $redactions) {
        $x1 = Get-MarkerX $r.BufferedStart $videoDuration $w
        $x2 = Get-MarkerX $r.BufferedEnd $videoDuration $w
        $e.Graphics.DrawLine($pen, $x1, $midY, $x2, $midY)
        $e.Graphics.FillEllipse($brush, ($x1 - 3), ($midY - 3), 6, 6)
        $e.Graphics.FillEllipse($brush, ($x2 - 3), ($midY - 3), 6, 6)
    }
 
    $pen.Dispose()
    $brush.Dispose()
})
 
$btnStartRedaction.Add_Click({
    if (-not $videoPath) { return }
    Stop-Playback
 
    $shapeData = Get-CurrentShapeVideoData
    if (-not $shapeData) {
        [System.Windows.Forms.MessageBox]::Show(
            "Draw a shape over the area to redact first.",
            "Nothing selected",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }
 
    $script:pendingRedaction = @{
        Shape = $shapeData.Shape
        X = $shapeData.X; Y = $shapeData.Y; W = $shapeData.W; H = $shapeData.H
        Points = $shapeData.Points
        Mode = Get-SelectedMode
        Strength = $redactionStrength
        Color = $redactionColor
        StartTime = Get-FramePresentationTime $currentFrame
        StartFrame = $currentFrame
    }

    if ([double]::IsNaN([double]$pendingRedaction.StartTime) -or
        [double]::IsInfinity([double]$pendingRedaction.StartTime)) {
        $script:pendingRedaction = $null
        [System.Windows.Forms.MessageBox]::Show(
            "The selected start frame does not have a usable presentation timestamp.",
            "Frame timing error",
            "OK",
            "Error"
        ) | Out-Null
        Update-RedactionButtons
        return
    }
 
    $lblPending.Text = "Pending: started at frame $($currentFrame + 1) ($(SecToText $pendingRedaction.StartTime)). Move to the end frame, then click End Redaction."
    Update-RedactionButtons
    $picture.Invalidate()
})
 
$btnCancelRedaction.Add_Click({
    Stop-Playback
    $script:pendingRedaction = $null
    Reset-DrawingState
    Update-SelectionFields $null
    $lblPending.Text = "No redaction in progress."
    Update-RedactionButtons
    $picture.Invalidate()
})
 
$btnEndRedaction.Add_Click({
    if (-not $pendingRedaction) { return }
    Stop-Playback
 
    if ($currentFrame -lt $pendingRedaction.StartFrame) {
        [System.Windows.Forms.MessageBox]::Show(
            "The end frame must be at or after the start frame ($(SecToText $pendingRedaction.StartTime)).",
            "Invalid range",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }
 
    # The marked range and the safety buffer are defined in exact logical
    # frames. Average FPS is deliberately not involved. This makes the range
    # semantics identical for CFR and VFR and prevents rounding from dropping
    # the first/last intended frame.
    $endFrame = [int]$currentFrame
    $bufferedStartFrame = [int][Math]::Max(0, ([int]$pendingRedaction.StartFrame - $BUFFER_FRAMES))
    $bufferedEndFrame = [int][Math]::Min(($totalFrames - 1), ($endFrame + $BUFFER_FRAMES))

    # Keep seconds only as derived UI/current-export compatibility values.
    # The frame indexes above are canonical and will drive the n-based export
    # activation in the next implementation slice.
    $markStartTime = Get-FramePresentationTime ([int]$pendingRedaction.StartFrame)
    $markEndTime = Get-FramePresentationTime $endFrame
    $bufferedStartTime = Get-FramePresentationTime $bufferedStartFrame
    $bufferedEndTime = Get-FramePresentationTime $bufferedEndFrame
    $rangeTimes = @($markStartTime, $markEndTime, $bufferedStartTime, $bufferedEndTime)
    foreach ($rangeTime in $rangeTimes) {
        if ([double]::IsNaN([double]$rangeTime) -or [double]::IsInfinity([double]$rangeTime)) {
            [System.Windows.Forms.MessageBox]::Show(
                "The selected redaction range does not have a complete validated frame-timing map.",
                "Frame timing error",
                "OK",
                "Error"
            ) | Out-Null
            return
        }
    }
 
    $entry = [PSCustomObject]@{
        Shape = $pendingRedaction.Shape
        X = $pendingRedaction.X; Y = $pendingRedaction.Y; W = $pendingRedaction.W; H = $pendingRedaction.H
        Points = $pendingRedaction.Points
        Mode = $pendingRedaction.Mode
        Strength = $pendingRedaction.Strength
        Color = $pendingRedaction.Color
        StartFrame = [int]$pendingRedaction.StartFrame
        EndFrame = $endFrame
        BufferedStartFrame = $bufferedStartFrame
        BufferedEndFrame = $bufferedEndFrame
        MarkStart = [double]$markStartTime
        MarkEnd = [double]$markEndTime
        BufferedStart = [double]$bufferedStartTime
        BufferedEnd = [double]$bufferedEndTime
    }
    [void]$script:redactions.Add($entry)
    Refresh-RedactionList
 
    $script:pendingRedaction = $null
    Reset-DrawingState
    Update-SelectionFields $null
    $lblPending.Text = "Redaction #$($redactions.Count) added. Draw a new shape for the next redaction, or export."
    Update-RedactionButtons
    $picture.Invalidate()
})
 
$btnAddRedaction.Add_Click({
    if (-not $videoPath) { return }
 
    $shapeData = Get-CurrentShapeVideoData
    if (-not $shapeData) {
        [System.Windows.Forms.MessageBox]::Show(
            "Draw a shape over the area to redact first.",
            "Nothing selected",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }
 
    $entry = [PSCustomObject]@{
        Shape = $shapeData.Shape
        X = $shapeData.X; Y = $shapeData.Y; W = $shapeData.W; H = $shapeData.H
        Points = $shapeData.Points
        Mode = Get-SelectedMode
        Strength = $redactionStrength
        Color = $redactionColor
        StartFrame = 0; EndFrame = 0
        BufferedStartFrame = 0; BufferedEndFrame = 0
        MarkStart = 0.0; MarkEnd = 0.0
        BufferedStart = 0.0; BufferedEnd = 0.0
    }
    [void]$script:redactions.Add($entry)
    Refresh-RedactionList
 
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
})
 
$btnRemoveRedaction.Add_Click({
    if ($lvRedactions.SelectedIndices.Count -eq 0) { return }
    $idx = $lvRedactions.SelectedIndices[0]
    $script:redactions.RemoveAt($idx)
    Refresh-RedactionList
    Update-RedactionButtons
})
 
$btnClearRedactions.Add_Click({
    if ($redactions.Count -eq 0) { return }
    $script:redactions.Clear()
    Refresh-RedactionList
    Update-RedactionButtons
})
 
$btnExport.Add_Click({
    if (-not $videoPath) { return }
    Stop-Playback

    if ($redactions.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Add at least one redaction before exporting.",
            "Nothing to redact",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    $selectedFormat = [string]$cmbFormat.SelectedItem
    if (-not $selectedFormat) { $selectedFormat = if ($isImageMode) { "PNG" } else { "MP4" } }
    $outExt = "." + $selectedFormat.ToLowerInvariant()
    $neutralName = "REDACTED_" + (Get-Date -Format "yyyyMMdd_HHmmss") + $outExt
    $saveFilter = if ($isImageMode) { "$selectedFormat image|*$outExt|All files|*.*" } else { "$selectedFormat video|*$outExt|All files|*.*" }
    $saveTitle = if ($isImageMode) { "Save redacted image" } else { "Save redacted video" }

    try {
        $out = [SecureFileDialogNativeV2]::ShowSave($form.Handle, $saveFilter, $saveTitle, $neutralName, $selectedFormat.ToLowerInvariant())
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(("Windows could not open the secure save dialog.`r`n`r`n" + $_.Exception.Message), "File dialog error", "OK", "Error") | Out-Null
        return
    }
    if ([string]::IsNullOrWhiteSpace($out)) { return }

    # Keep the filename/container extension consistent with the selected export
    # format even if the user typed a different extension in the native dialog.
    if (-not [System.IO.Path]::GetExtension($out).Equals($outExt, [System.StringComparison]::OrdinalIgnoreCase)) {
        $out = [System.IO.Path]::ChangeExtension($out, $outExt)
    }

    $networkReason = Get-NetworkPathReason $out
    if ($networkReason) {
        # UNC and mapped-network destinations are permitted after an explicit
        # warning. The same-directory partial/validation workflow remains intact.
        if (-not (Show-NetworkLocationWarning "Destination")) { return }
    }

    # Never encode directly over the user's chosen destination. The temporary
    # redacted output lives beside it (same volume), is validated there, then
    # is atomically moved/replaced only after validation succeeds.
    $outDir = [System.IO.Path]::GetDirectoryName($out)
    $outStem = [System.IO.Path]::GetFileNameWithoutExtension($out)
    $partial = Join-Path $outDir ($outStem + ".partial." + [guid]::NewGuid().ToString("N") + $outExt)

    $exportRedactions = Get-ExportRedactionList $redactions

    # Oval/Polygon redactions each need a pre-rendered geometry-only mask.
    $maskPaths = @{}
    $maskTempFiles = New-Object System.Collections.Generic.List[string]
    try {
        for ($i = 0; $i -lt $exportRedactions.Count; $i++) {
            $r = $exportRedactions[$i]
            if ($r.Shape -and $r.Shape -ne "Rectangle") {
                $maskFile = Join-Path $env:TEMP ("TinyVideoRedactor_mask_" + [guid]::NewGuid().ToString() + ".png")
                New-ShapeMaskFile $r $maskFile
                $maskPaths[$i] = $maskFile
                [void]$maskTempFiles.Add($maskFile)
            }
        }

        $built = Build-RedactionFilterComplex $exportRedactions $maskPaths
        $filterComplex = $built.FilterComplex
        $finalLabel = $built.FinalLabel
        $maskInputArgsStr = if ($built.MaskInputArgs.Count -gt 0) { " -i " + ([string]::Join(" -i ", $built.MaskInputArgs)) } else { "" }

        $progress.Minimum = 0
        $progress.Maximum = 100
        if ($isImageMode) {
            $progress.Style = "Marquee"
        }
        else {
            $progress.Style = "Continuous"
            $progress.Value = 0
        }
        $progress.Visible = $true
        $btnExport.Enabled = $false
        $status.Text = "Exporting $($redactions.Count) redaction(s)..."
        $form.Refresh()

        $metadataArgs = " -map_metadata -1 -map_metadata:s -1 -map_chapters -1"

        if ($isImageMode) {
            if ($selectedFormat -eq "GIF") {
                $paletteStage = "[$finalLabel]split[gpal1][gpal2];[gpal1]palettegen=stats_mode=single[gpal];[gpal2][gpal]paletteuse=dither=bayer[gout]"
                $args = "-hide_banner -nostdin -y -autorotate -i " + (Quote-Arg $videoPath) + $maskInputArgsStr +
                        " -filter_complex " + (Quote-Arg "$filterComplex;$paletteStage") +
                        " -map " + (Quote-Arg "[gout]") + $metadataArgs +
                        " -frames:v 1 -c:v gif " +
                        (Quote-Arg $partial)
            }
            else {
                # Do not rely on FFmpeg's container/default encoder selection.
                # Every supported still-image output names its encoder explicitly,
                # just as video exports already do.
                $qualityArg = switch ($selectedFormat) {
                    "PNG"  { "-c:v png" }
                    "JPG"  { "-c:v mjpeg -q:v 3" }
                    "WEBP" { "-c:v libwebp -q:v 90" }
                    default { throw "Unsupported image output format." }
                }
                $args = "-hide_banner -nostdin -y -autorotate -i " + (Quote-Arg $videoPath) + $maskInputArgsStr +
                        " -filter_complex " + (Quote-Arg $filterComplex) +
                        " -map " + (Quote-Arg "[$finalLabel]") + $metadataArgs +
                        " -frames:v 1 -update 1 $qualityArg " +
                        (Quote-Arg $partial)
            }
        }
        else {
            $isWebm = ($selectedFormat -eq "WEBM")

            if ($isWebm) {
                $crf = switch ($cmbQuality.SelectedIndex) {
                    0 { 24 }
                    1 { 31 }
                    default { 38 }
                }
                $vcodecArgs = "-c:v libvpx-vp9 -b:v 0 -crf $crf -pix_fmt yuv420p"
                $audioCodecArg = if ($chkAudio.Checked) { "-c:a libopus -b:a 128k" } else { "-an" }
            }
            else {
                $crf = switch ($cmbQuality.SelectedIndex) {
                    0 { 18 }
                    1 { 22 }
                    default { 26 }
                }
                $vcodecArgs = "-c:v libx264 -preset medium -crf $crf -pix_fmt yuv420p"
                $audioCodecArg = if ($chkAudio.Checked) { "-c:a aac -b:a 192k" } else { "-an" }
            }

            # Audio is unsanitised. If the user explicitly enables it, include
            # only the primary audio stream instead of silently carrying every
            # commentary/secondary track in the source.
            $audioMapArg = if ($chkAudio.Checked) { " -map 0:a:0?" } else { "" }
            # Preserve the filtergraph's presentation timestamps explicitly.
            # FFmpeg's default auto fps mode is not acceptable here because a
            # muxer may otherwise select CFR and duplicate/drop source frames.
            $videoTimingArgs = "-fps_mode:v:0 passthrough -enc_time_base:v:0 filter"
            $args = "-hide_banner -nostdin -y -autorotate -i " + (Quote-Arg $videoPath) + $maskInputArgsStr +
                    " -filter_complex " + (Quote-Arg $filterComplex) +
                    " -map " + (Quote-Arg "[$finalLabel]") + $audioMapArg + $metadataArgs +
                    " $vcodecArgs $videoTimingArgs $audioCodecArg " +
                    (Quote-Arg $partial)
        }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $ffmpeg
        $psi.Arguments = "-progress pipe:1 -nostats " + $args
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $totalUs = if (-not $isImageMode -and $videoDuration -gt 0) { $videoDuration * 1000000.0 } else { 0.0 }
        $script:ffmpegOutTimeUs = 0.0
        $p = $null
        $err = ""

        $form.Enabled = $false
        try {
            $p = [System.Diagnostics.Process]::Start($psi)
            $stdout = $p.StandardOutput
            $stderrTask = $p.StandardError.ReadToEndAsync()
            $lineTask = $stdout.ReadLineAsync()

            while (-not $p.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40

                while ($lineTask.IsCompleted -and -not $p.HasExited) {
                    $line = $lineTask.Result
                    if ($null -eq $line) { break }
                    if ($line -match '^out_time_us=(-?\d+)') {
                        $script:ffmpegOutTimeUs = [double]$Matches[1]
                    }
                    $lineTask = $stdout.ReadLineAsync()
                }

                if ($totalUs -gt 0) {
                    $pct = [Math]::Max(0, [Math]::Min(99, [int](($script:ffmpegOutTimeUs / $totalUs) * 100)))
                    $progress.Value = $pct
                    $status.Text = "Exporting $($redactions.Count) redaction(s)... $pct%"
                }
            }
            $p.WaitForExit()
            $lineTask.Wait(250) | Out-Null
            while ($lineTask.IsCompleted -and $lineTask.Result -ne $null) {
                if ($lineTask.Result -match '^out_time_us=(-?\d+)') {
                    $script:ffmpegOutTimeUs = [double]$Matches[1]
                }
                $lineTask = $stdout.ReadLineAsync()
                if (-not $lineTask.Wait(200)) { break }
            }
            $stderrTask.Wait(2000) | Out-Null
            $err = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }
            if ($progress.Style -eq "Continuous") { $progress.Value = 100 }
        }
        finally {
            $form.Enabled = $true
        }

        if (-not $p -or $p.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $partial)) {
            Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
            $progress.Visible = $false
            Update-RedactionButtons
            $status.Text = "Export failed."
            [System.Windows.Forms.MessageBox]::Show(
                "FFmpeg failed to create a complete redacted export. No destination file was replaced.`r`n`r`n$(Get-SafeFFmpegError $err $videoPath)",
                "Export failed",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        $status.Text = "Validating redacted export..."
        $form.Refresh()
        $expectAudio = (-not $isImageMode -and $chkAudio.Checked -and $sourceHasAudio)
        $validation = Test-ExportSecurity $ffmpeg $ffprobe $partial $isImageMode $expectAudio $videoWidth $videoHeight $videoDuration $frameTimeline
        if (-not $validation.Ok) {
            Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
            $progress.Visible = $false
            Update-RedactionButtons
            $status.Text = "Export validation failed."
            [System.Windows.Forms.MessageBox]::Show(
                "The redacted file failed post-export security validation and was not finalized.`r`n`r`n$($validation.Error)",
                "Export validation failed",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        # Commit only after validation. Existing destination files remain
        # untouched until this point; File.Replace is atomic on supported
        # same-volume Windows filesystems.
        try {
            if (Test-Path -LiteralPath $out -PathType Leaf) {
                [System.IO.File]::Replace($partial, $out, $null)
            }
            else {
                [System.IO.File]::Move($partial, $out)
            }
        }
        catch {
            Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
            $progress.Visible = $false
            Update-RedactionButtons
            $status.Text = "Could not finalize export."
            [System.Windows.Forms.MessageBox]::Show(
                "The redacted temporary file passed validation, but Windows could not atomically finalize it. Any existing destination file was left untouched.",
                "Could not finalize export",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        $progress.Visible = $false
        Update-RedactionButtons
        $status.Text = "Done: $out"
        [System.Windows.Forms.MessageBox]::Show(
            "Finished and validated.`r`n`r`n$out",
            "Redaction complete",
            "OK",
            "Information"
        ) | Out-Null
    }
    catch {
        # Fail closed for unexpected mask/filter/process/finalization exceptions.
        # The selected destination is never touched before validation/commit.
        if ($partial -and (Test-Path -LiteralPath $partial)) {
            Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
        }
        $status.Text = "Export failed."
        [System.Windows.Forms.MessageBox]::Show(
            "The export stopped because an unexpected error occurred. No unvalidated destination file was finalized.",
            "Export failed",
            "OK",
            "Error"
        ) | Out-Null
    }
    finally {
        foreach ($f in $maskTempFiles) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue }
        $form.Enabled = $true
        $progress.Visible = $false
        Update-RedactionButtons
    }
})
 
$form.Add_FormClosed({
    $playTimer.Stop()
    $previewTimer.Stop()
    if ($previewImage) { $previewImage.Dispose() }
    Remove-EmbeddedMediaTools
})
 
Update-RedactionButtons
 
[void]$form.ShowDialog()