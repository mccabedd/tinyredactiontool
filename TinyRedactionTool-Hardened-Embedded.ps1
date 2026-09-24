# TinyRedactionTool v2.2.0 FINAL
# Consolidated from user-tested B1-r4 source SHA-256
# 594488A98BAFC465F90ECEB7CA43CC4E4C50879869CC5619A14BCC07F6AE1D0D
# Frozen v2.1.0 ancestry SHA-256
# 2BC392FD52587343AB4CEA95B19C295286E44E4D3543634D9D3D1E383567BDC7
# Accepted D1b Default Pixelate preview-parity source SHA-256
# 177906F4208F0E2F629108057169EDF8647DD6C713885ED65FD726D02C2CDA21
#
# D2 is an RC-facing polish slice only: user-facing Default/Aggressive
# terminology, the locked Blur/Pixelate warning copy, and the lighter
# #3C3F47 Dark Mode base. Export/media logic remains D1b.
#
# D3 changes ONLY the compact warning-dialog presentation plumbing needed for
# the Blur/Pixelate warning: bold the word Aggressive and pre-tick the
# session-suppression checkbox for that warning only.
##
# RC1 freeze note:
# Application behaviour is frozen from the accepted D3 candidate. The only
# runtime-visible RC-preparation change was the About-dialog identity
# "TinyRedactionTool v2.2.0 RC1".
#
# Final v2.2.0 promotion note:
# RC1 passed user regression testing. The only runtime-visible RC1 -> final
# change is the About-dialog identity "TinyRedactionTool v2.2.0".
#
# D1 is the first staged candidate that enables export for both additional
# UserRotation and committed Enhanced Blur/Pixelate redactions.
#
# D1 REQUIRES the matching D1 custom FFmpeg build profile. The old v2.1 media
# tool intentionally lacks transpose/avgblur/lutyuv and must not be used for D1.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# v2.0.0 Slice 4: WinForms has no built-in magnifying-glass cursor. Build one
# at runtime from the already-embedded Zoom glyph, using a tiny native helper
# to convert an HICON into an HCURSOR with the hotspot inside the lens.
if (-not ("ZoomCursorNativeV1" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ZoomCursorNativeV1
{
    [StructLayout(LayoutKind.Sequential)]
    private struct ICONINFO
    {
        [MarshalAs(UnmanagedType.Bool)] public bool fIcon;
        public uint xHotspot;
        public uint yHotspot;
        public IntPtr hbmMask;
        public IntPtr hbmColor;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetIconInfo(IntPtr hIcon, out ICONINFO pIconInfo);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr CreateIconIndirect(ref ICONINFO icon);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyIcon(IntPtr hIcon);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyCursor(IntPtr hCursor);

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern bool DeleteObject(IntPtr hObject);

    public static IntPtr CreateCursorFromIcon(IntPtr hIcon, uint hotX, uint hotY)
    {
        ICONINFO info;
        if (!GetIconInfo(hIcon, out info)) return IntPtr.Zero;
        try
        {
            info.fIcon = false;
            info.xHotspot = hotX;
            info.yHotspot = hotY;
            return CreateIconIndirect(ref info);
        }
        finally
        {
            if (info.hbmMask != IntPtr.Zero) DeleteObject(info.hbmMask);
            if (info.hbmColor != IntPtr.Zero) DeleteObject(info.hbmColor);
        }
    }

    public static void DestroyIconHandle(IntPtr hIcon)
    {
        if (hIcon != IntPtr.Zero) DestroyIcon(hIcon);
    }

    public static void DestroyCursorHandle(IntPtr hCursor)
    {
        if (hCursor != IntPtr.Zero) DestroyCursor(hCursor);
    }
}
"@
}

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

function Test-D1MediaToolCapabilities([string]$ffmpegPath) {
    $filters = & $ffmpegPath -hide_banner -filters 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { return $false }

    foreach ($name in @("transpose","avgblur","lutyuv")) {
        if ($filters -notmatch ("(?m)^ .{2,4}\s+" + [regex]::Escape($name) + "\s")) {
            return $false
        }
    }
    return $true
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

# ---------------------------------------------------------------------------
# v2.2.0 C1 Enhanced Blur/Pixelate — strength-5 application prototype.
#
# Exact public deterministic A1-R8 5P20-CN reference:
#   - long axis: 5 structural cells (short axis aspect-derived, minimum 2);
#   - 4x oversampled intermediate lattice;
#   - 2.0x overlapping pooled neighbourhoods;
#   - 8 luma levels;
#   - 7-symbol non-uniform neutral-centred chroma codebook.
#
# SECURITY BOUNDARY: protected source pixels are consulted only while building
# the tiny proxy. Final Enhanced Blur/Pixelate rendering uses only that proxy.
# C1 applies this exact renderer to still-image live preview. Enhanced export is
# fail-closed until the custom FFmpeg profile is extended and reapproved.
function Get-EnhancedProxyDimensions {
    param([int]$RegionWidth,[int]$RegionHeight,[int]$LongAxisCells = 5)
    if ($RegionWidth -ge $RegionHeight) {
        $pw = $LongAxisCells
        $ph = [Math]::Max(2,[Math]::Round($LongAxisCells * ($RegionHeight / [double]$RegionWidth)))
    } else {
        $ph = $LongAxisCells
        $pw = [Math]::Max(2,[Math]::Round($LongAxisCells * ($RegionWidth / [double]$RegionHeight)))
    }
    return @([int]$pw,[int]$ph)
}

function Quantize-EnhancedLuma {
    param([double]$Value,[int]$Levels = 8)
    $v = [Math]::Max(0.0,[Math]::Min(255.0,$Value))
    $step = 255.0 / ($Levels - 1)
    return [Math]::Round($v / $step) * $step
}

function Quantize-EnhancedChromaNeutral {
    param([double]$Value)
    [double[]]$symbols = @(-48.0,-24.0,-10.0,0.0,10.0,24.0,48.0)
    $delta = [Math]::Max(-127.0,[Math]::Min(127.0,$Value - 128.0))
    $best = $symbols[0]
    $bestDistance = [Math]::Abs($delta - $best)
    foreach ($symbol in $symbols) {
        $distance = [Math]::Abs($delta - $symbol)
        if ($distance -lt $bestDistance) { $best = $symbol; $bestDistance = $distance }
    }
    return 128.0 + $best
}

function Quantize-EnhancedProxy {
    param([System.Drawing.Bitmap]$Proxy)
    for ($yy=0; $yy -lt $Proxy.Height; $yy++) {
        for ($xx=0; $xx -lt $Proxy.Width; $xx++) {
            $c=$Proxy.GetPixel($xx,$yy)
            $yv=0.2126*$c.R + 0.7152*$c.G + 0.0722*$c.B
            $cb=128.0 + (($c.B-$yv)*0.5389)
            $cr=128.0 + (($c.R-$yv)*0.6350)
            $qy=Quantize-EnhancedLuma $yv 8
            $qcb=Quantize-EnhancedChromaNeutral $cb
            $qcr=Quantize-EnhancedChromaNeutral $cr
            $r=$qy + 1.5748*($qcr-128.0)
            $b=$qy + 1.8556*($qcb-128.0)
            $g=($qy - 0.2126*$r - 0.0722*$b) / 0.7152
            $ri=[int][Math]::Round([Math]::Max(0.0,[Math]::Min(255.0,$r)))
            $gi=[int][Math]::Round([Math]::Max(0.0,[Math]::Min(255.0,$g)))
            $bi=[int][Math]::Round([Math]::Max(0.0,[Math]::Min(255.0,$b)))
            $Proxy.SetPixel($xx,$yy,[System.Drawing.Color]::FromArgb($ri,$gi,$bi))
        }
    }
}

function Get-EnhancedReflectedIndex {
    param([int]$Index,[int]$Length)
    if ($Length -le 1) { return 0 }
    $i=$Index
    while ($i -lt 0 -or $i -ge $Length) {
        if ($i -lt 0) { $i=-$i-1 }
        elseif ($i -ge $Length) { $i=(2*$Length)-$i-1 }
    }
    return $i
}

function New-EnhancedStructuralProxy {
    param([System.Drawing.Bitmap]$Source,[System.Drawing.Rectangle]$Region)
    $dims=Get-EnhancedProxyDimensions $Region.Width $Region.Height 5
    $proxyW=[int]$dims[0]; $proxyH=[int]$dims[1]
    $oversample=4; $poolFactor=2.0
    $latticeW=[Math]::Max($proxyW,$proxyW*$oversample)
    $latticeH=[Math]::Max($proxyH,$proxyH*$oversample)
    $lattice=New-Object System.Drawing.Bitmap($latticeW,$latticeH,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $lg=[System.Drawing.Graphics]::FromImage($lattice)
    try {
        $lg.Clear([System.Drawing.Color]::Black)
        $lg.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $lg.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $lg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $lg.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $lg.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $dest=New-Object System.Drawing.Rectangle(0,0,$latticeW,$latticeH)
        $lg.DrawImage($Source,$dest,$Region.X,$Region.Y,$Region.Width,$Region.Height,[System.Drawing.GraphicsUnit]::Pixel)
    } finally { $lg.Dispose() }
    $proxy=New-Object System.Drawing.Bitmap($proxyW,$proxyH,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    try {
        $windowW=[Math]::Max(1,[int][Math]::Round($oversample*$poolFactor))
        $windowH=[Math]::Max(1,[int][Math]::Round($oversample*$poolFactor))
        for ($py=0; $py -lt $proxyH; $py++) {
            for ($px=0; $px -lt $proxyW; $px++) {
                $centerX=(($px+0.5)*$oversample)-0.5
                $centerY=(($py+0.5)*$oversample)-0.5
                $left=[int][Math]::Floor($centerX-(($windowW-1)/2.0))
                $top=[int][Math]::Floor($centerY-(($windowH-1)/2.0))
                [double]$sumR=0; [double]$sumG=0; [double]$sumB=0; [int]$count=0
                for ($wy=0; $wy -lt $windowH; $wy++) {
                    $ly=Get-EnhancedReflectedIndex ($top+$wy) $latticeH
                    for ($wx=0; $wx -lt $windowW; $wx++) {
                        $lx=Get-EnhancedReflectedIndex ($left+$wx) $latticeW
                        $c=$lattice.GetPixel($lx,$ly)
                        $sumR+=$c.R; $sumG+=$c.G; $sumB+=$c.B; $count++
                    }
                }
                $r=[int][Math]::Round($sumR/$count); $g=[int][Math]::Round($sumG/$count); $b=[int][Math]::Round($sumB/$count)
                $proxy.SetPixel($px,$py,[System.Drawing.Color]::FromArgb($r,$g,$b))
            }
        }
    } finally { $lattice.Dispose() }
    Quantize-EnhancedProxy $proxy
    return $proxy
}

function New-EnhancedReconstructedPatch {
    param(
        [System.Drawing.Bitmap]$Proxy,
        [int]$TargetWidth,
        [int]$TargetHeight,
        [ValidateSet("Blur","Pixelate")]
        [string]$Mode
    )

    # C1a changes ONLY the cosmetic reconstruction after the accepted safe
    # structural proxy has already been built. Nothing in this function reads
    # protected source pixels.
    #
    # The C1 renderer stretched the tiny 5xN proxy directly to output size:
    #   Blur     -> bicubic, which could ring/halo and look "inverted";
    #   Pixelate -> nearest-neighbour, exposing only a handful of giant cells.
    #
    # C1a first creates a denser COSMETIC grid from the safe proxy. Those extra
    # samples are interpolation only and contain no additional source detail.
    # The final visual therefore resembles conventional Blur/Pixelate while
    # preserving the exact same structural-information ceiling.

    if ($TargetWidth -le 0 -or $TargetHeight -le 0) { return $null }

    $wrapAttr = New-Object System.Drawing.Imaging.ImageAttributes
    $wrapAttr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)

    try {
        if ($Mode -eq "Pixelate") {
            # Match the visual block density of Standard strength 5, but derive
            # every cosmetic cell solely from the already-safe proxy.
            $divisor = Get-PixelateDivisor 5
            $gridW = [Math]::Max(
                $Proxy.Width,
                [Math]::Max(2,[int][Math]::Floor($TargetWidth / [double]$divisor)))
            $gridH = [Math]::Max(
                $Proxy.Height,
                [Math]::Max(2,[int][Math]::Floor($TargetHeight / [double]$divisor)))

            $grid = New-Object System.Drawing.Bitmap(
                $gridW,
                $gridH,
                [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

            $gg = [System.Drawing.Graphics]::FromImage($grid)
            try {
                $gg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $gg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
                $gg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $gg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

                $dest = New-Object System.Drawing.Rectangle(0,0,$gridW,$gridH)
                $gg.DrawImage(
                    $Proxy,
                    $dest,
                    0,0,$Proxy.Width,$Proxy.Height,
                    [System.Drawing.GraphicsUnit]::Pixel,
                    $wrapAttr)
            }
            finally {
                $gg.Dispose()
            }

            $patch = New-Object System.Drawing.Bitmap(
                $TargetWidth,
                $TargetHeight,
                [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

            $pg = [System.Drawing.Graphics]::FromImage($patch)
            try {
                $pg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $pg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $pg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

                $dest = New-Object System.Drawing.Rectangle(0,0,$TargetWidth,$TargetHeight)
                $pg.DrawImage(
                    $grid,
                    $dest,
                    0,0,$grid.Width,$grid.Height,
                    [System.Drawing.GraphicsUnit]::Pixel,
                    $wrapAttr)
            }
            finally {
                $pg.Dispose()
                $grid.Dispose()
            }

            return $patch
        }

        # Enhanced Blur: build a Standard-strength-5-density cosmetic image
        # from the safe proxy using bilinear interpolation (not bicubic, which
        # caused visible ringing), then low-pass it once more before scaling to
        # final size. The smoothing stages operate ONLY on proxy-derived pixels.
        $divisor = Get-BlurLiveDivisor 5
        $gridW = [Math]::Max(
            $Proxy.Width,
            [Math]::Max(2,[int][Math]::Floor($TargetWidth / [double]$divisor)))
        $gridH = [Math]::Max(
            $Proxy.Height,
            [Math]::Max(2,[int][Math]::Floor($TargetHeight / [double]$divisor)))

        $grid = New-Object System.Drawing.Bitmap(
            $gridW,
            $gridH,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

        $gg = [System.Drawing.Graphics]::FromImage($grid)
        try {
            $gg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $gg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
            $gg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $gg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            $dest = New-Object System.Drawing.Rectangle(0,0,$gridW,$gridH)
            $gg.DrawImage(
                $Proxy,
                $dest,
                0,0,$Proxy.Width,$Proxy.Height,
                [System.Drawing.GraphicsUnit]::Pixel,
                $wrapAttr)
        }
        finally {
            $gg.Dispose()
        }

        # One extra proxy-only low-pass stage makes the result read as Blur
        # rather than a magnified structural heat-map.
        $smoothW = [Math]::Max(
            $Proxy.Width,
            [Math]::Max(2,[int][Math]::Ceiling($gridW / 2.0)))
        $smoothH = [Math]::Max(
            $Proxy.Height,
            [Math]::Max(2,[int][Math]::Ceiling($gridH / 2.0)))

        $smooth = New-Object System.Drawing.Bitmap(
            $smoothW,
            $smoothH,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

        $sg = [System.Drawing.Graphics]::FromImage($smooth)
        try {
            $sg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $sg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
            $sg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            $dest = New-Object System.Drawing.Rectangle(0,0,$smoothW,$smoothH)
            $sg.DrawImage(
                $grid,
                $dest,
                0,0,$grid.Width,$grid.Height,
                [System.Drawing.GraphicsUnit]::Pixel,
                $wrapAttr)
        }
        finally {
            $sg.Dispose()
            $grid.Dispose()
        }

        $patch = New-Object System.Drawing.Bitmap(
            $TargetWidth,
            $TargetHeight,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

        $pg = [System.Drawing.Graphics]::FromImage($patch)
        try {
            $pg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $pg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
            $pg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            $dest = New-Object System.Drawing.Rectangle(0,0,$TargetWidth,$TargetHeight)
            $pg.DrawImage(
                $smooth,
                $dest,
                0,0,$smooth.Width,$smooth.Height,
                [System.Drawing.GraphicsUnit]::Pixel,
                $wrapAttr)
        }
        finally {
            $pg.Dispose()
            $smooth.Dispose()
        }

        return $patch
    }
    finally {
        $wrapAttr.Dispose()
    }
}

function Get-EnhancedExportEffectSpec {
    param(
        [string]$Mode,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H
    )

    # Export information ceiling mirrors the accepted application architecture:
    # 5-cell long axis, 4x intermediate lattice, P20 overlapping pooling,
    # 8 luma levels, 7 neutral-centred chroma symbols.
    #
    # FFmpeg implements the pooling as an 8x8 average on the 4x lattice before
    # collapsing to the final tiny proxy. Everything after that point is purely
    # cosmetic reconstruction from the tiny proxy.
    $dims = Get-EnhancedProxyDimensions $W $H 5
    $proxyW = [int]$dims[0]
    $proxyH = [int]$dims[1]
    $latticeW = $proxyW * 4
    $latticeH = $proxyH * 4

    # 8 luma symbols across full 0..255.
    $yExpr = "floor((val+18.2142857)/36.4285714)*36.4285714"

    # R8/C1a public 7-symbol neutral-centred chroma codebook:
    # signed deviations -48,-24,-10,0,+10,+24,+48 around 128.
    # Midpoint thresholds become absolute 8-bit values:
    # 92,111,123,133,145,164 -> 80,104,118,128,138,152,176.
    $cExpr = "if(lt(val\,92)\,80\,if(lt(val\,111)\,104\,if(lt(val\,123)\,118\,if(lt(val\,133)\,128\,if(lt(val\,145)\,138\,if(lt(val\,164)\,152\,176))))))"

    $base = "crop=$W`:$H`:$X`:$Y," +
            "scale=$latticeW`:$latticeH`:flags=bicubic`:out_range=full," +
            "format=yuv444p," +
            "avgblur=sizeX=8`:sizeY=8," +
            "scale=$proxyW`:$proxyH`:flags=neighbor," +
            "lutyuv=y='$yExpr'`:u='$cExpr'`:v='$cExpr'"

    if ($Mode -eq "Pixelate") {
        # Cosmetic block density tracks Standard strength 5, but every one of
        # these extra blocks is interpolated only from the already-tiny proxy.
        $divisor = Get-PixelateDivisor 5
        $gridW = [Math]::Max($proxyW,[Math]::Max(2,[int][Math]::Floor($W / [double]$divisor)))
        $gridH = [Math]::Max($proxyH,[Math]::Max(2,[int][Math]::Floor($H / [double]$divisor)))
        return $base + ",scale=$gridW`:$gridH`:flags=bilinear,scale=$W`:$H`:flags=neighbor"
    }

    # Cosmetic Enhanced Blur follows C1a's renderer structure: proxy-derived
    # dense representation, one further low-pass resize, then smooth final scale.
    $divisor = Get-BlurLiveDivisor 5
    $gridW = [Math]::Max($proxyW,[Math]::Max(2,[int][Math]::Floor($W / [double]$divisor)))
    $gridH = [Math]::Max($proxyH,[Math]::Max(2,[int][Math]::Floor($H / [double]$divisor)))
    $smoothW = [Math]::Max($proxyW,[Math]::Max(2,[int][Math]::Ceiling($gridW / 2.0)))
    $smoothH = [Math]::Max($proxyH,[Math]::Max(2,[int][Math]::Ceiling($gridH / 2.0)))

    return $base +
           ",scale=$gridW`:$gridH`:flags=bilinear" +
           ",scale=$smoothW`:$smoothH`:flags=bilinear" +
           ",scale=$W`:$H`:flags=bilinear"
}

function Get-RedactionEnhanced($r) {
    if (-not $r) { return $false }
    if ($r -is [hashtable]) {
        if ($r.ContainsKey("Enhanced")) { return [bool]$r["Enhanced"] }
        return $false
    }
    if ($r.PSObject -and $r.PSObject.Properties["Enhanced"]) { return [bool]$r.Enhanced }
    return $false
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

    # Trusted FFmpeg -autorotate resolves source orientation first. Additional
    # UserRotation is then baked into pixels before any redaction geometry is
    # applied, exactly matching the application's canonical working space.
    switch ([int]$script:userRotation) {
        0 { }
        90 {
            $filterParts.Add("[0:v]transpose=clock[ur0]")
            $cur = "ur0"
        }
        180 {
            $filterParts.Add("[0:v]transpose=clock[urA]")
            $filterParts.Add("[urA]transpose=clock[ur0]")
            $cur = "ur0"
        }
        270 {
            $filterParts.Add("[0:v]transpose=cclock[ur0]")
            $cur = "ur0"
        }
        default {
            throw "Build-RedactionFilterComplex: invalid UserRotation '$script:userRotation'."
        }
    }

    for ($i = 0; $i -lt $redactionList.Count; $i++) {
        $r = $redactionList[$i]
        $x = $r.X; $y = $r.Y; $w = $r.W; $h = $r.H
        $startFrame = [int]$r.BufferedStartFrame
        $endFrame = [int]$r.BufferedEndFrame

        if ($startFrame -lt 0 -or $endFrame -lt $startFrame -or
            $script:totalFrames -le 0 -or $endFrame -ge $script:totalFrames) {
            throw "Build-RedactionFilterComplex: invalid buffered frame range."
        }

        $enable = "between(n\,$startFrame\,$endFrame)"
        $nextLabel = "v$i"
        $isRect = (-not $r.Shape) -or ($r.Shape -eq "Rectangle")
        $strength = if ($r.Strength) { [int]$r.Strength } else { 5 }
        $enhanced = Get-RedactionEnhanced $r
        $boxColor = if ($r.Color) { $r.Color } else { [System.Drawing.Color]::Black }
        $colorHex = "0x{0:X2}{1:X2}{2:X2}" -f $boxColor.R, $boxColor.G, $boxColor.B

        if ($isRect) {
            if ($r.Mode -eq "Black box") {
                $filterParts.Add("[$cur]drawbox=x=$x`:y=$y`:w=$w`:h=$h`:color=$colorHex`:t=fill:enable='$enable'[$nextLabel]")
            }
            else {
                $baseLbl = "b$i"; $tmpLbl = "t$i"; $effLbl = "e$i"

                if ($enhanced) {
                    $eff = Get-EnhancedExportEffectSpec $r.Mode $x $y $w $h
                }
                elseif ($r.Mode -eq "Blur") {
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

                if ($enhanced) {
                    $eff = Get-EnhancedExportEffectSpec $r.Mode $x $y $w $h
                }
                elseif ($r.Mode -eq "Blur") {
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

    return @{
        FilterComplex = [string]::Join(";", $filterParts)
        FinalLabel = $cur
        MaskInputArgs = $maskInputArgs
    }
}
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
            Enhanced = Get-RedactionEnhanced $r
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
# placed, returns a MEDIA-space PointF at the same distance from $from but with
# its angle snapped to the nearest 0/45/90 degree step whenever $constrain is
# true. Keeping this in media space means the draft remains canonical while
# Shift still produces visually correct horizontal/vertical/45-degree segments.
function Get-AngleSnappedPoint([System.Drawing.PointF]$from, [System.Drawing.PointF]$to, [bool]$constrain) {
    if (-not $constrain) { return $to }

    $dx = [double]$to.X - [double]$from.X
    $dy = [double]$to.Y - [double]$from.Y
    $dist = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
    if ($dist -lt 0.01) { return $to }

    $angle = [Math]::Atan2($dy, $dx)
    $step = [Math]::PI / 4.0
    $snapped = [Math]::Round($angle / $step) * $step

    $nx = [single]([double]$from.X + ([Math]::Cos($snapped) * $dist))
    $ny = [single]([double]$from.Y + ([Math]::Sin($snapped) * $dist))
    return New-Object System.Drawing.PointF($nx, $ny)
}

# Standard ray-casting point-in-polygon test, used to decide whether a click
# on a closed-but-uncommitted freeform shape should start moving it rather
# than starting a brand new path. Both the test point and polygon vertices are
# canonical MEDIA-space PointF values in v2.0.0 Slice 2.
function Test-PointInPolygon([System.Drawing.PointF]$pt, $polyPoints) {
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

# Bounding box (MEDIA space) of a set of draft freeform points. It is used
# only to clamp whole-shape movement to the canonical media bounds.
function Get-PointsBoundingRect($points) {
    $minX = [double]$points[0].X; $maxX = [double]$points[0].X
    $minY = [double]$points[0].Y; $maxY = [double]$points[0].Y
    foreach ($pt in $points) {
        if ($pt.X -lt $minX) { $minX = [double]$pt.X }
        if ($pt.X -gt $maxX) { $maxX = [double]$pt.X }
        if ($pt.Y -lt $minY) { $minY = [double]$pt.Y }
        if ($pt.Y -gt $maxY) { $maxY = [double]$pt.Y }
    }
    return New-Object System.Drawing.RectangleF(
        [single]$minX, [single]$minY,
        [single]($maxX - $minX), [single]($maxY - $minY))
}

# The legal extent for uncommitted draft vertices/endpoints. Mouse points map
# to media pixel positions 0..(size-1), matching Clamp-MediaPoint.
function Get-DraftMediaBounds {
    if ($videoWidth -le 0 -or $videoHeight -le 0) { return $null }
    return New-Object System.Drawing.RectangleF(
        0.0, 0.0,
        [single][Math]::Max(0.0, ([double]$videoWidth - 1.0)),
        [single][Math]::Max(0.0, ([double]$videoHeight - 1.0)))
}

# Given a shape's original bounding box and a raw (dx,dy) the mouse has
# moved, returns the same delta clipped so the translated bounding box never
# leaves the supplied bounds. In Slice 2 the caller supplies MEDIA bounds.
function Get-ClampedTranslation($origBounds, [double]$dx, [double]$dy, $bounds) {
    $minDx = $bounds.X - $origBounds.X
    $maxDx = ($bounds.X + $bounds.Width) - ($origBounds.X + $origBounds.Width)
    $minDy = $bounds.Y - $origBounds.Y
    $maxDy = ($bounds.Y + $bounds.Height) - ($origBounds.Y + $origBounds.Height)
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

if (-not (Test-D1MediaToolCapabilities $ffmpeg)) {
    [System.Windows.Forms.MessageBox]::Show(
        "This D1 candidate requires the matching custom FFmpeg build with transpose, avgblur and lutyuv enabled. The media tool beside this script is from an older build profile or is otherwise incompatible.",
        "D1 media-tool capability check failed",
        "OK",
        "Error"
    ) | Out-Null
    exit
}

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
# v2.2.0 B1 rotation-only slice: source display dimensions remain the output
# of the existing trusted -autorotate preflight. UserRotation is a separate
# per-media quarter-turn applied after source orientation and before any
# redaction geometry is created. videoWidth/videoHeight remain the canonical
# working dimensions used by the existing viewport/geometry stack.
$sourceDisplayWidth = 0
$sourceDisplayHeight = 0
$userRotation = 0
$videoDuration = 0.0
$fps = 0.0
$sourceHasAudio = $false
$frameTimeline = $null
$totalFrames = 0
$currentFrame = 0
$previewSeconds = 0.0
$loadedFrame = -1
 
$dragging = $false

# v2.0.0 Slice 2: all *draft* redaction geometry is now canonical displayed-media
# geometry from the moment the user creates it. Rectangle/Oval use RectangleF;
# Freeform uses PointF vertices. Viewport resizing/panel changes therefore never
# mutate the draft itself - Paint simply projects the same media geometry back
# into the current Fit viewport.
$dragStart = New-Object System.Drawing.PointF(0,0)
$selection = New-Object System.Drawing.RectangleF(0,0,0,0)
$previewImage = $null

# v2.0.0 viewport state. Slice 4 exposes Fit/manual zoom while redaction geometry
# remains canonical media-space. 1.0 means one displayed-media pixel equals
# one viewport pixel (100%).
$zoomMode = "Fit"
$zoomFactor = 1.0
$panOffsetX = 0.0
$panOffsetY = 0.0
$maxZoomFactor = 8.0
$minZoomFactor = 0.01
$zoomStepFactor = 1.25
$zoomToolActive = $false
$script:zoomCursor = $null
$script:zoomCursorHandle = [IntPtr]::Zero

# v2.0.0 Slice 5: left-button drag while the Zoom tool is active pans the
# manual-zoom viewport. A small screen-pixel threshold distinguishes a click
# (zoom in) from a drag (pan), so ordinary left-click zoom behaviour remains
# intact. Pan offsets remain VIEW-space state only; redaction geometry stays
# canonical media-space.
$script:zoomPanCandidate = $false
$script:zoomPanning = $false
$script:zoomPanStartPoint = New-Object System.Drawing.PointF(0,0)
$script:zoomPanStartOffsetX = 0.0
$script:zoomPanStartOffsetY = 0.0
$zoomPanDragThreshold = 4.0

# v2.0.0 Slice 6: holding Space while a drawing tool is selected temporarily
# borrows the same left-drag pan gesture without changing toolMode, radio-button
# state, draft geometry, or Begin/End redaction state. Releasing Space returns
# immediately to the existing drawing tool because the tool was never changed.
$script:spacePanActive = $false

# v2.1 Viewport Usability Slice 1: middle-button drag is an always-available
# viewport pan gesture. v2.2.0 B1-r3 adds right-button DRAG as an equally
# available laptop/trackpad-friendly route while preserving simple right-click
# semantics (Zoom tool = zoom out; Freeform = cancel in-progress path).
# Both routes deliberately reuse the proven zoomPanCandidate / zoomPanning
# state so pan maths, clamping and media-space isolation stay unchanged.
$script:middlePanActive = $false
$script:rightPanActive = $false

# Moving a drawn-but-not-yet-committed shape (Rectangle/Oval/closed Polygon)
# by dragging inside it, rather than starting a brand new one. $moveStart,
# $moveOrigSelection and $moveOrigPolygonPoints are all MEDIA-space snapshots,
# so viewport changes cannot alter what is being moved.
$movingShape = $false
$moveStart = New-Object System.Drawing.PointF(0,0)
$moveOrigSelection = $null
$moveOrigPolygonPoints = $null

# ===== v2.1 Resize Integration: draft resizing is now normal behavior =====
# Rectangle/Square, Oval/Circle and closed-Freeform draft editing have passed
# their isolated Slice tests and are enabled by default in this integration
# candidate. The existing internal flags are deliberately retained as TRUE
# constants so the already-tested helper/wiring paths remain mechanically
# unchanged. Export/timing/security architecture remains outside this feature.
$script:resizeSlice3Enabled = $true
$script:resizeSlice2Enabled = $true
$script:resizeSlice1Enabled = $true
$script:resizingShape = $false
$script:resizeHandle = "None"
$script:resizeShapeKind = "None"
$script:resizeOrigSelection = $null
$script:resizeHandleVisualSize = 8.0
$script:resizeHandleHitSize = 14.0
$script:resizeMinMediaSize = 2.0
# r2: distinguish an intentional Rectangle drag from an ordinary click. Without
# this, MouseDown creates the usual 0.01 x 0.01 seed rectangle and MouseUp can
# leave all eight handles collapsed onto one apparent "lone anchor".
$script:resizeDraftDrawStartView = $null
$script:resizeDraftDrawMoved = $false
$script:resizeDraftDrawThreshold = 3.0

# Slice 3: a closed Freeform polygon exposes one constant-screen-size handle
# at every canonical media-space vertex. Vertex editing is kept separate from
# Rectangle/Oval bounding-box resizing so the earlier known-good paths remain
# mechanically untouched.
$script:editingPolygonVertex = $false
$script:polygonVertexIndex = -1
# ===== End Resize Slice 1/2/3 state =====

# Drawing tool: "Rectangle", "Oval", or "Polygon" (the freeform tool). Rectangle
# and Oval are drag-based and use the media-space $selection above; Polygon is
# click-to-add-point and stores media-space PointF vertices below.
$toolMode = "Rectangle"
$polygonActive = $false
$polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
$polygonMousePos = $null

$pendingRedaction = $null
$redactions = New-Object System.Collections.ArrayList

# Blur/Pixelate strength, 1 (lightest) - 10 (strongest). Whatever this is set
# to at the moment a redaction is created gets baked into that redaction's own
# Strength field, so different redactions in the same file can use different
# strengths, and adjusting the slider later never retroactively changes ones
# already added.
$redactionStrength = 5

# C1 Enhanced Blur/Pixelate is explicitly opt-in. Standard remains the default
# and the flag is baked into each committed redaction so changing the checkbox
# later never retroactively changes existing redactions.
$script:redactionEnhanced = $false

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

# Audio is not inspected/redacted. The warning can be suppressed for the
# current session only, matching the visual-obscuration/network warnings.
$script:suppressAudioWarning = $false
$script:audioWarningOpen = $false

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
            $availW = [Math]::Max(1, $sender.Width - ($margin * 2))
            $availH = [Math]::Max(1, $sender.Height - ($margin * 2))
            $side = [Math]::Min($availW, $availH)
            $imgX = [int](($sender.Width - $side) / 2)
            $imgY = [int](($sender.Height - $side) / 2)
            $imgRect = New-Object System.Drawing.Rectangle($imgX, $imgY, $side, $side)
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

# ----------------------------------------------------------------------
# TinyRedactionTool v2.0.0 release UI
# ----------------------------------------------------------------------
# Shared compact-layout constants. "UiGap" is the small edge/gutter distance
# used consistently around the toolbar, panel toggle and header action icons.
$script:UiGap = 4
$script:UiIconButtonSize = 34
$script:ToolbarWidth = $script:UiIconButtonSize + (2 * $script:UiGap) # 42 = 4 + 34 + 4
$script:InspectorCollapsedWidth = $script:UiIconButtonSize + (2 * $script:UiGap) # 42
$script:InspectorExpandedWidth = 350
$script:CompactButtonWidth = 130
$script:OpenButtonWidth = 150
$script:ExportButtonWidth = 176
$script:CompactButtonHeight = 30
$script:HeaderHeight = 64

# v2.0.0 preserves the approved compact v1.4.0 UI while adding viewport-only
# zoom/pan. Rectangle, Oval and Freeform draft/committed geometry remains in
# canonical displayed-media coordinates; zoom/pan/window/panel state remains
# view-only state and is not part of export geometry. Existing CFR/VFR timing,
# export/security validation and FFmpeg/FFprobe trust behaviour are preserved.
# ----------------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "TinyRedactionTool"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1540,980)
$form.MinimumSize = New-Object System.Drawing.Size(1320,820)
$form.KeyPreview = $true
$form.Font = New-UIFont 9.0
$form.AutoScaleMode = "Dpi"
$form.BackColor = [System.Drawing.Color]::FromArgb(223,238,245)

# WinForms does not automatically adopt the PS2EXE assembly icon for a Form
# created dynamically from PowerShell. In packaged mode, explicitly assign the
# icon embedded in TinyRedactionTool.exe so the window/taskbar uses the same
# custom application icon as Explorer. This is presentation-only state.
if (Test-IsPackagedHost) {
    try {
        $hostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $script:mainFormIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($hostExe)
        if ($script:mainFormIcon) { $form.Icon = $script:mainFormIcon }
    } catch {}
}

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
$top.Size = New-Object System.Drawing.Size($form.ClientSize.Width,$script:HeaderHeight)
$top.Anchor = "Top,Left,Right"
$top.Padding = New-Object System.Windows.Forms.Padding($script:UiGap,0,$script:UiGap,0)
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
# same single-file-script reason as $script:AppIconBase64 above. v1.4's
# Rectangle/Oval/Freeform/Zoom/Copy and Moon/Sun glyphs are normalized
# transparent RGBA line-art assets with a consistent apparent size/stroke.
# The theme engine tints monochrome glyphs at runtime, so one canonical asset
# works in both Day and Dark modes without maintaining duplicate PNG sets.
$script:IconBase64 = @{
    "play" = "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"
    "pause" = "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"
    "next_frame" = "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"
    "previous_frame" = "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"
    "rotate_ccw" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAALBUlEQVR4nO2da6xdRRXHf/ee9ra32FLbWqmAgFTFIj4ApdSYRmPwgSWCNb5AJIohSCAmxooaTYNGv9QPPiJqQ0yqEgGjYAkVUNr4BrHW0hbRlkehreUhpcTS+zp+WPPvzJkze5997z2n53H3P9k5++w9M3tmrTVr1sysmYESbUVfuzMwAfRFVyNUo6uj0OkM6AP63W8VGG1CehV3XwXGaDNTOpEBIlKK4BVgIXACcDxwHDAfmAPMxJg1AvwPOAA8BewFngB2A/9NfE8MaQszOokBIkRI9BcBbwSWAW8GlgAnAseMM+0qRvxHga3AX4A/AduAoSDcNJpT07oGfVih+4Nn84GPADdh0hvrcKmOEWC4wDWSk8YuYC2wApgd5KEfLxA9iwq+BvYDy4F1mKSG+nkUT8zR4Pl4r7EorbHoO3uB7wJnBXnsSUaEhRoAPgrcTy2xJN0TJXbRSwwZiZ5txGqFamaFHmFEKPUrgQepl848oitcrH5GElf8fjQnXaUdf/+vwPkZ+e8qSNcDvAq4i1pdnqWns6R0opeI3IjRMcPuBl7n8l+hts2aNGFaDWV2DLgCWAPMwgrYR7owY+6KJW4EeBz4N7ATMy33A88Ch1ycaS79eZiZehKwGDgVM2HD9LK+I8gaqmBMWwOsBl5wzzreWpLenAX8FC9dWdKcevcv4PvAh7DaMzDBvMikvRy4EdiT+HaWmgrztRXfUE+jg1WSiH8CvpEdIl3148I/DnwTWApMT6TdjxU+vCrBFb9LEekY4DzgBuDpnLzE6kvluCooZ9NUUrMg4r8W6/xU8ZmPCzWCZ8q9WB8g7miJkBqWmAik7sQsPQNTV1dRaxSE+cqqDTfgGdwxVpIyciamn7OIL2umCmwB3oMniBrtVlodIlpIuAHgYuChRB5jwRly9/dgDIQOYIIy8HrgSbzEpKSoijVmq/AWkiT0aOtVMVzfnQF8FhtPUn5TtUGCtQV4mYvbNiZIDy7GrJMs4ivT24E3uDid0tGJh0ZeDtxOftug8jyIDRBCG8qiDM8DHqAx8W/Fj710oiUR14grsdraqFxbMVMXjmLDrImRfuDXUYZSmbw+yGAnSH0epBIBzgYepnH5fg8MujiFBSu0DsYrkSLimgKZWxPE6TjTLQdiwkuBP5BdTjXMP3PhC5UxZdoVne5Txj5M4+r5LRe2W8dTJGiDwB00FrYvu/DTKIBXYgT6FfA1YJF7nkeosNFVRya2FJSZHweF6EbiCxLW6cB68k3sKmZaQwNVuwx4hloJfgSzAPTRFERIDazF0q//GzH7umit6nSIHjOA35IuuxjwKKa2IKfsf3aBD7uEDrn/a937FPdUrT5DWgqUgcfwplk36fxGSFl9sYkqmqxzYTNrQTw0q/s9wItdmJB7+virgeeiOGEao8DbGn28i6EynU79LF6sBd4XxanB/kRkRfxAIqIY8MsobMz5L7pwhRqhLoXK9kHStUD/d+DHt+pU0Y+oJ6Tub3JhKtHvRYk44f97sj7WgxATvke+QF4bhT+C86IIYW14Bm8RSfJnYj2+mOOK8zw2ChrG6WVIyOZicxdZdNlPhnU5QLohEScvdeFmuN9ryJf+L7hwvax6YkgzXEh+g3xdFP4IvhEFDAl6WxBuHmbZxG2GPvh3PKOmgvoJodp+G/UCGho2C1y4GvqcQz1Rdf8ccIoLdy35ZucFLlwvWj2NIAacjadHSE/R7GoXbloc+R9kq6FPunBPJBJWmPVRRvLQq7VDgvcT6muB6Ho/tRNPRzhxHdlq6GbgE4lEw2uZSyeLAfFkS0dN4zUJKvu5pGkkwV3uwlXCSGdmRKpiM0N7yJb+m8MEowzFvp/9mDdzJfjfS1B57qZeYCXc33Fh6gwVDUvErbj8Z7IYFEp/iuhgLiWrMM/kJzHP5Evcu15SSRKsi8lWQ7vwcwaA58Qq0o1sigFKeIOLO0B9DTgJa3R+hx8rjzNzeZTxboeEaT6wj2zj5q1hJEnra/CEauQYKwJe6OKKicdhjfad+IE9pScXw9CrYDv1biLdDpVnHfUCrfuvxJFU+I3kN7Yh8f/m4szDvJxvBQ5GYbP8OsXgp8iwjbsYYkBqokr3d8WRJMFXk1ZDKQbcAfyA+lFROS/l1aLD1DKxlxB6VTxPLW1So801kU7Fq45Gaii2iIp4HSuMwq103+2VNkBQbb6XbI2yNLRUxjAm7AQ2Bc8aQQlnTeiPJsIMYQ3zu4Bb3Hc73tN4nJBAbXa/1eCd6HpGbIf2u5c/B95Z4COh33+I0O1bGRnGpOEWrK14GO/OUoTR3YotiWdixpL4haT3eMznvogaCtuFWAWNYET/HNYPCNENfkGTgcr2Dur7Vrpfn4ootfQLillDMdFHsWr3JWy6LkRqVWSvIpy6jQfnwtHjOsQ9uVSnTCsWw+c7gK9iiyBCAk8looeQNllIvTbR7+68iPPx4z9DpIm+E1tIcS61bcFUJXoI0XEQ76wc14QDWZFFuBX4jpUi7wN+CLyd2uVCJdFrIQZUSE9VVoHDjTzfxjC/93djVWkH8BuMKfpI1r4OUx3aYKQPm/Jdgjf1hWoiXg2ylgR1ij9/JyOc99hOugaMNpo4H6PW1pf+KqW9OCpkr+wcLuK5IFO0xMQwA1umC75WSDUdKhvM1mMOtkY5hQMlA1qH0JyfHT1T4/t0yYDWQcQ+0f2G411iwGMlA1oHMeA095sacHyoZEDrICk/I/FOzNlWMqB1kKmujT1i15wxzDOkRAsQzi5qfXE8EvoIMLusAa2B6LoM6wdobyTwqukB4GDJgNZARD4/592mxLsSTYAkfQHwH+pnFXV/TltyNwWgQcpLqZ9RlP7/J24jqlIFNR9SMZck3qkvsAGb4JpKq4iOCoq6p7/FhSuH9JuMIgs07mtP1nofkv6z8IRPraW40oUr1U+TkbeAPfQHne/C9YojckdAqucC0lOPcu1ZHYUv0QRIkmfjt70c10LtEpODdPm3STuy6f/no/AlmgAR8/1keD3gO16Zm3WUmBikx08je8cwNcQXRXFKTBKyeObiF7hn7ZJyYxSnxCQRblmWWgscqp7d2KJFKFVPUxBu2qdNOfI27Vvh4pWqpwlQgzuL/G0rtfx2dRSvxCQQroHWbgJ5xNdOY6XenyTCrYuX4vdKytuw9Y/UuyKWGCfizbuvwa9rbrR590tcnFL6J4B4kckp2OSJCJ+3ff022rh9fbcjJvxMbOhAq4OyFqBL52/Gm5sl8QsidYTJdOBj1C4pytrnQpJ/J3Csi18SPweNDvH5NDZmIwIXOcTnenxbMSV0fni4z3iOsUoRZxBbRL2W2rGcIsdYHQI+5dLptrMQJozJHGEFRvDTgY9j+/ho6Wgo2UUOctuMd7id9PEr3WKnasXhAuAybN71IGaX78MfZTiKSeQgplYWAicDr8DOSFhErbSO5yjDIeDr2PkKw3TJUYbNQLjkX4fCTeZM4fBs4qxwcW3YgO0mBlNI5QgqrI6TeoH0qdnNOs42PDT6PvyuMbKaukVrNAUq7Bz88ebNPOQ53McufLYJeC89eKDzeBFK2xayx2GKEjs8DDret2E/dmrrm4Jv9vqWOoUgAlyG7xyFZ8On1FD8Lkv97MWO2V2J70xBSfg6qCZcQfb8a6NrGFuVcju2l9Fy0qe2HlXCd1ODonVVczE7fDG2Mewi92wQI94I1lA/i6mV3Rjhd7n7w1G6alhVS0rkoBnSGQ5HtF0A256BCUDjLmHeq8FvzdbwwfPwKlHC8H82Df4GZIg8uwAAAABJRU5ErkJggg=="
    "rotate_cw" = "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"
    "freeform" = "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"
    "oval" = "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"
    "rectangle" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABw0lEQVR42u3bTUoDMQBA4Zfp1J2CgrcQ0QO4cyF4S2/g3ou4EUEENy78QQXbxsVksIgg7aTtmHkfFFdlbF4mk4oBSZIkSZIkSZIkSZKkEoUNv78k8b/FczJnGMTdVD4MeNYH4AmYrStAlV4XwFm6cDXwALfAOfCw6uWoDbYHfKQL+Wpep2lsRosMaN2h/CuwNfAliLQCBGCyzJvrDheu5gY+bHI3sOGHbfgxFmsL4O4og9wBIvA8d1vGwmZ+BLZzjludceDb7dhx+lni0hOBS+AEmC76wF3XHfAIvBS8anz2eQkCGKfZUtoSVM0trb0OEOcGvqQAcRWfZ6jfYHt1W8kABpABDCADGEAGMIAMYAAZwAAygAFkAAPIAAaQAQwgAxhABjCADGAAZVKvKGp7ZCcWOFl7/d/RkeZswKzAydp+pkkfA7SzYge4yv1L9sxRzuU79x1Q0xzfGYLQxwDQnJ0qfeMScs7YLuv9b0YMz9KnZ+oOt99WejAN/aT8lOZc3HhdAQLwDtwAh+7kqYA34O6PlSHbg6Td3+8DBwMf/JgC3APXBX73KX9XFDpe0D9lfN8JM4dBkiRJkiRJkiRJkiSp9QWexYaAl1n83wAAAABJRU5ErkJggg=="
    "pixelate" = "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"
    "blur" = "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"
    "black" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABLklEQVR4nO3bQUrDQBiG4b+tB6g38eDeo1s34jFcdWfURSYUBBExMx8jzwOh7Sb/pG/SrqYKAAAAAAAAAACAXR0GzjoOnreXj6p6Ty+CTkbckYda76KHqrpv72d4ErZ1vlbVU92uYzqn9nqp9QJmOy5frmNXdz1O+o1rVS3t6HIxO9vWee05ZGSAY92++BkCVK3rPPYc0PXk/EyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgbuUFjqaq39jrDXqttnUvPISMDnNu8kTP/YlvnecSQnra7/bGqnmvdczvDT9+2zpf2eYanlt8auV/3NHjeXrr/DwAAAAAAAAAAAADwP3wC3V5LI/al5bMAAAAASUVORK5CYII="
    "eyedropper" = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAACsElEQVR4nO2bTW4TQRCFSwkcAU+/V2sCAlZYSHCKIJEQJH4kYM0ZAtwDgVhE/FwAwQ2SHZwhBCQ2WSQs4mBUYUbuGHtsx/a4e3qeVBtrPOqvXne5etwj0qhRozqo3W6ft5CEtETyLoCPJH+Q7JL8Q3IPwAdVXbdrpI4C0Cb5LYceGgC+ArgudZJz7g6Aw1HwXhwAWJU6SFXXSR5NAF/MhN/OuRuSIjy95RBtTSC5MQ18EXlhTMt5np4F7yVF59mLPUnRefbiOIpmSecDf5IAETkniU37rlcDvkuiznfzBLyTEJRl2dUqnS9CVddk0QLwnGTHOfegKueDaYTwD74Y1EkSKoI/tA3UQuGzLLs2APRo3vB2f9tASQhS1bUKgP3oALgvIUmrS0J48KYq1nwDjwDhOfh3ftZF0O61IZE43zGnZlgTwnReS+C9a6ZNQrzwM0hC/PBTJKE+8GdIQv3gJ0hCfeHHSEL94Uc0Tae20qnBd4NLAod3ePdmfL//PrMttoTovDujOxN2jJuzJwoU3rumSMJmKtN+Y5wHqrV3PhgBuL0o5xcukisk95N03gTgS/9gk3De5Jy7kp/A8gf8WFKANwF42Tfgz5IKvInkjj9o59xDSQXeOXfB/lf3Bn3carWyWhc8X6r6qG/g25IKvInklj94qwdS92lf5p6q3pQUnNcBT2QA/BKR5VHfJfkkaucBXB5wHrcUIMuyltWLAQ1TXPAmkm/HAFgmeSvvEXb6finihTeR/FnW9RmQLYeSR1ZF7Md4Unupr+3t+Ot+zMNM9v1PtoGSGMXeGxhF8XtmBwwBPC2BtyWwDeCF1RCJWQDeDAEctL63rDW2Iih1EclL9qbFiGkeX3GbRABWS5JwEMzJq3mK5AqA1wB281qwC+CVql5c9NgaNWrUqJFMr7/GqKf+LELoegAAAABJRU5ErkJggg=="
    "info" = "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"
    "zoom" = "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"
    "panel_expand" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAELElEQVR42u2dvW4TQRSFv3WchBSEQIAUIBAdNaLkHehoeIDACyConFSIN+AFoKCCd6AhiYCKFkGLFIkfifzYXgrfUQbLa+/as//nSKMom3g9c87cOzN37u6AIAiCIAiCIAiCUCiinP+/rYhDi9QV+flwFqX4u6/mut1YSEYf+DWFw9QCuA+eAx4BD4BbwKo4nopj4CvwBngJHM0SYRI69vM6sGcfVsle9oxDn9OZFhBZWQXeA3eAE40DmQfhPrACfATumWXE45YwSZUlYAhse+Sv2P9GBZQmDMAd4+zEONw2TpfS3iAC9oGBKSl3Ml/pG4d7SR2smzDwrgM3TMm4YNP9ab0lqqHb6QAXvLo7r3ETOG+zo/8G5KQpZRdYLrjykZF/FzgsQfxF3c4QuAQcABtjdV9O4rpbwV70Y2weXScMsnaaKi6qlj1/WScLiOfxGlUUwJ+qxTXq/fE89e1oyl4uJIAEkACCBJAAggQorL0dCVBeW4dWOhKg2FWqC7G/sOJCw6UH/LotIb8P9IAndv0vsGPtzxy/ybvCMIrqHVrFhuQfN3ffcWjfTaDe6e6xY/c/tRLbNdcJo5x4y9yuJgnQYRQce+6R70gJLcLcAnQb7HpcRsd9uxZ7jffdElVyR02zAIBNRhvjsdfz47HfF7UEuaAZIlwFPk0QIZQ7kgBT4DIRriRYQggRJMCCIizqjiRARhFCuyMJULI7kgAlu6NGCbDJWXpfXumPbv2zBXzmLIttXktolADrBa99LnKWAT6YU4TGrIQjcw1L5J8ZF1v7T4CHwDvgtheudpaS64q5WyHiYZRXeUBxuaEun/OYUTr+pATapLBFv4nh6IhRXmWVQ9pOBLfB07j9gLgCljjpuu+O1oBnIUTQpnzJqKIFRBW1yoHxtQPsNtUFFf2AxvggvDGD/F0rjRuEy3hAw5+GbgFvbRYWe655nHx/Gpqr+bdtIbY/YyHWy2shplCEQhGlBeNC7pJJgBzI76UkXwKU2PMlQAXIlwAluR0JkCHUorQUykvMupwz+RIgoR2RLeq+2L1PArudIAI0NRrqQhtHjHa6XMPjKbGdSqSpNzU9vYfS00ubBXXHRAjldoII0IY3IPruZs0I2LXpaelupw0CuEBbB3jqjX2DKlSuTe8A9Z+OHFalUm17CeuwahXSprwEkACCBJAAggRoJ6qaGVe390hHk8IMdRXAj9nXabXt6l5rAYp8QCN0vd2ri6MQAvTnUTOACRf9gEZoK3Av73Zt8i3jNI0AbiPjN/Cd0XZeTMr33gcSYqNBY6zrSN+AP0x4HXPSAQ4x8IpyooZ1PzPAx8A4fJ3UkXWESX6dKNURJrPWB9eAD+gkjEIP8WFsEFkFHqNjrNIi0zFWOsgtPDId5JZ2ZiL/nxNnOswz35WxIAiCIAiCIAiCUDX8A158x9XvmkSZAAAAAElFTkSuQmCC"
    "panel_collapse" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAEe0lEQVR42u2dzY7cRBSFP7udkETKJCRhNcoE3oAFO8Q2W1YgeILME4zY9cwmUp6ANyCRYM8TsJos2EEQJNJskcI/hIx7zMK3RMVpd9s9XXbZPkcqTU+31V0+p+6tW7eqXCAIgiAIgiAIgiB0iiTw9VNFsW2RMpEfhrOkwee+mjv2xUI9cuD3FRw2FiAFzoDLwD7wEfAO8IY4Xol/gWfAV8DnwD8el42R2t/bwGNTUKV9eWwc+pyutYDEyiXgG+Bd4KX6gdadcA5cBL4F3gdeeMK81tJ9zMxc9j3yL9q1YxAg6aCkxtmpcXjPOJ21qeAxsDAl5U42K7lxeOzx+gqymqhnB9gzJYuKaf1maiYDdAspcK3DujuvsQdctejolaioLqTMgAuVyidG/nvA8yXixO52zoAb1jFe9+6pC1yo4zrboBX9XIlzh4RFbI0m21DNZN0AI0ILKCpWPVgB/FCqGFDrL2Ksb6qQXQJIAEECSABBAkiASOqTSoD+6nJmJZUA3Y5SXQr8gRWXuh39/EMWCfk5MAcO7P2/gSOrX3T5m9CEQJk1fG437txCYe/dqFx7nt9yDeDQvv/USmHvsSUrqLuv0PMBrXnrSoA68t1vORHu8/9s3CgFSCNwO3N77Xy+X8FPgCt0m7sfdSfsk39oJa90uLlZxxPgA+BXhpX6jrYPWOV2Cu//AvieNcs51Ae0E8Anf15Dfr6E/FnghjUJAdq0/CcByJ+0AE3Izz3y9wKQP1kB2ridkORPUoA2bueHwORHLUAW6Gb9UHO+JNRc2G//BNwFTry0QxJQgOjHEue1gCZux+V2vgN2O76/nTFbQJOW70a0J8CnlAu83rLrksANy62Mi8oKtinAOvJ99d8Evqbc/LHoiBR/bWg07mhbAqQrcjvLcNXK5JFtifyCciLlwMvlNGmRffZzo0vGFWrP/ViAm8P9jHJD2mEDFzSIkHBIfcCZfdeRN/haJcIfwF89dsLJ2ATwB1erRHBu6hfgQxuIXeo4DO1jg4YGYrEOxELkgtok4X4E3vasMeSuxQS4OcVk3LxBMu7OVJNxoQRoawmhM6KakKHfOQFNSTZ0R6FE0KQ8mpTvfWVcG0vQshTCLE1sK8LulkSQABuK8NRGrQnnX4sapQB9LE8v1qQtfDyiXKruUgmjR1/L031L0PL0jgSoE6Gw1356YrQC9L1DpuqOLlsFj8wdjX53TAyPoHRjADep46KexRR8fkzPAPV3R06iw41NgEkRzxZHmYIEkACCBJAAggSYRhjqrzYYCqLdoLGJAC5ZNrRHVrq6D1qAhHJDxYzhPrp4EBs08kprcZW+Rrm0b+gP7+7aHZ3WWV+2pJIJ5eLZE+CWvTfzKn1dXWdjuIZ6AvzJkmde1B3gUAAPWZ6VHPoz/bvEwjj8otKQX3Mty6IcHWFyPnfX6AiTdeOD25SnP+g0jM3KMRsc4uN/Vpgl7AMfo2OsmsAdY/Ul5TFWL1hxjJUOcts+Wh3k1jSGlv8PxJkO8ww78hYEQRAEQRAEQRBiw3+mUHW2m+Ug7wAAAABJRU5ErkJggg=="
    "copy" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAADp0lEQVR42u2cwWoUMRzGf5lORbGtij5Iq3jswYsHH8SjF8GDvoNH7z6CIIIg3kREUQ+e9AlELbXipdvZeNiEHcad3SmdSTLZ7wdhaRs6k3zJ/598mxkQQgghhBBCCCGEEEIIIQbHrPn1V2FzFn9jJPdoch6BF4DzbqSZxEa9BX7nGAKMKw+Bu8DFBEORBSrgOfAA+JVLSPJh55FrzBjKS6BwZfQJ3wDbwHfgxJVpwuXYiXBzqLxVRpjam8A515hm7LcJDJLmjLXAzlAXLCM00rrRNZZlqXH5IBsB2jraAkdOHBN4Nvjrbbf0iclNgGbHG7fk2wux9FsiwDNg3434IPuUMqGpbt1y70/Ee5iEvmBKAuAStIkQgopa6FtrAWxjJxrjutkIYFp+Nh32CiZQp0dnKAE2FizdbIc4Owk4Gjdc2LE5ClDRbrRdahnhBrg68KwMarTFEGCZ0eYTa1HbWTaF+RxgH7DIaCuWbA5Hw5iNNj8QX7vfn9SEssCtRht7XX71NfKnbid5z914taThq1YjIcoEuA3ccB0++hAkoy2BHHBWo81EEKXKSYC2TqwbbT4JmyV1+kzC0Yy2FHbCdaPtOnAIXAY+uk9b64ShzLhoRltKVoQ32o5qybmtzlBm3IQECekFeaNts0OdPkNQNKMtNQFOswztc9UUzWgLuQ8QEkACCAkgAYQEkABCAkgAIQEkgJAAEkCsoExwQBT0b0dDux1ddKizFgJYZl/G9H0+x/+/tpMPfzvUyVoAP+p2gFcDdsJuy4x4wuyr0kV11moGlMy+sw0luP/cW1InWwHa4vuQR0SKlo6tH9BdVGfQh8hjPaTnT083p3qM0wrFivxRDjkwigij/pDZEREvQqhnfu2STl5UTlznfwM+MD9+mSR+il4BDpifkPMNP3B/83WvAS9I//DuF+YPaRe5hCAD/ATuuMZtBQgxU+CxW+X403k+tt8HPvH/QyUV8JbZeaLBRn+sHOBnzPuA1/3RCIX+Pt4A7zoImOUqKETS9R3YdiBsy93HoseqpkPH/dj7gCqQ2KuScBXwfqKtgoQESI8ysNh9O52nGWRrfTh3KKezC9GczhQECOV0dmE3xbBbBrzOfiJtNrkLEMPp7JoLgjqdMQRIzelclRvKBAZGb/i3zD5l/iB0lWjxLwX5yvx1CmbsAvhGyOlMJCGFcDrPYoHUnc6sXtI9pulcpNBZQ+aElJmS+evphRBCCCGEEEIIIYQQQgghBPAPlM4RjvwKObMAAAAASUVORK5CYII="
    "moon" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAFbElEQVR42u2cTYgcRRTHf90TF7Nh3TVKFDQedEk0JuCuJHqJGEHQiyBZvKkkEDyIePLiRUkuikLuGxDiweDRqx8gCuJBc1ARBRFFJVmM0QRBk53u9lCvmErZO9sf1TPTPe8PzXzQM939f/U+61WBQqFQKBQKhUKhUCgUCoWiICI5Wv0AbUHsEJ4Bqby2Gr0WDJCevKY5xC8A2+S7RDUg7H3FHqm3AQeA+4H9Qv4uYA04CFyQ81qvFZOklTPAE8B7wGUh1z8OOiZKEWDUW+KPAl97ZPeBdeCKfH6xJaa0VaP+cY/4vhyp8zkDPpHztyh9YcifA055xCeeBlhn+y+wrKanPuzoXQLODiE+80b/aTU94cjfD1wUYtc3IN6O/hT4B9jt+QxFAPL7Q8h3hfOOjv4wNt8lP9mEfHtOAhxyEjRFhXICwL4K5GfA96I9kVJZvaywDfiqoNnxzc/rGnrWNz1vFXC4eRqQAg+r/a9H/lMVyLcJ2B/ATY42KUqWGG7GFM6Sgnbfj/0/7GLoGY/oGinwPLBD3pe5rq1ufiHvNfYvSX6EKRv/5djyrIIGPNtFBxyP4P8z4DlgXsgva7/t+T95GqEoQFwkZmfNKSVkJY9EnPYBjYCqlRteqhD55EVA812MgJo0QdbZHhYSo5ra1EnnGzf4vymwiCk1q+kYgwAAnsRML4boWIhUAOXMD8BjgcizPkQFUHCkppL57qt5HduENQvsVCdc7j/vBrZXjP390X89cIsKoJytXnK0IQQW1ASVw67A/uQ+1YByhO0NRJj9/b1dLEU0pQEhEycrgAcxs2kJOh+wKVkLwO9eOaHOkWKqostdS+qa1ICQZeNESH+ka36gSSecNaBZK56fUQGMCD0R6JI4487MjLXpIRJMXekIOjW5qanYjpmCDOWE3d7QNUx3ROsX6DWhAXZkXsZ0sYW01zar3gG8INfSEvcQoX5Mue63olqQYNaD3SrXilUD8s3Qzw1FQ5mYoNco3+IyVQL4tsGIKAGeBh4VDVNT5BEEZjKmaPdzlU6JDDgvPkEXa+Ro1U7g78CRUF7D1meOALRG5JihGPiyAUecJ4RTjvapJjh1oDep3hNU9LD/vZpjBqfeDzxA+W7oOkJ4F7jRGQRRQG1upRmaAb5r0BnnCeGsCJ6agmj9OrRRmiFfCOvAcYmQXK3cMsRZ25He49pS+ixmZU7rnLxV23swa3urtKbXCVEzqRu9Aty+wf3FQ7LpOUxL/I+0eE8Ke8NnRqgF7gya/XwJs7r+CLCH/A6LWeAOTDffScnkM+A3BnsWRU3Y6aYFkAIPAR+NYRRZYbjXTIA/JVN3WyYXMc1kW73fvyxljx4t3RTKPvzpEWtBnkYUyUf6mO1w+hJAzLQ9ybM3vxu4yrVbz2RjEoYrEHu4PsoOkme6klfYB3h1jFpQZVVm3JWkzoZ41wGfN1yeCDHfcBG4q8GK8VjD0jvlAUeRIZcl/6q8X+lqScM+0IqjBemECMCSf9JLJDtbqDs2QULwC3qd35ElTwjJmEf+qhe1TU3J+lhOBDLqbHnVMZFTNaljhXCUwcasoyzauTZ/amfUrBCWGeyc2JRvcE3dBcz2OVNNvi+EOeAEg51x7WhNA5ga18ecYbCCR3ffykl49mJ21rrC//eM6LPxvhNumWE9x6e8j2lloatxfoiMuecJ4g3gF4bvpDgsqbsEvO0RPzEdddEEa0PklH9vwMxKHRJfsQezXGmr97tEnPkPwDfAp8AHwK9eSSSZpBE36WYpFlPiYl6Esuh9fx44h+nMzsvAk0lU+TYV8yLHzoc8XwVQ4b7zpghd269QKBQKhUKhUCgUCoVCoVAoFAqFwuA/cp9gBTN36BIAAAAASUVORK5CYII="
    "sun" = "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"
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
$logo.Location = New-Object System.Drawing.Point(10,11)
$logo.Size = New-Object System.Drawing.Size(40,40)
$logo.Tag = "logo"
$top.Controls.Add($logo)

$lblAppTitle = New-Object System.Windows.Forms.Label
$lblAppTitle.Text = "TinyRedactionTool"
$lblAppTitle.Location = New-Object System.Drawing.Point(62,7)
$lblAppTitle.Size = New-Object System.Drawing.Size(260,26)
$lblAppTitle.Font = New-UIFont 14 ([System.Drawing.FontStyle]::Bold)
$lblAppTitle.Tag = "heading"
$top.Controls.Add($lblAppTitle)

$lblAppSub = New-Object System.Windows.Forms.Label
$lblAppSub.Text = "Simple. Private. Secure."
$lblAppSub.Location = New-Object System.Drawing.Point(64,33)
$lblAppSub.Size = New-Object System.Drawing.Size(260,20)
$lblAppSub.Font = New-UIFont 9.2
$lblAppSub.Tag = "muted"
$top.Controls.Add($lblAppSub)

# Everything from here to $btnTheme sits in the header's right-hand cluster:
# theme toggle, then (moving left) the privacy/credit note, then the
# Open/Change file button. Each is positioned from $form.ClientSize.Width at
# construction time and kept flush via Anchor="Top,Right" - the same
# established pattern already proven reliable for $btnTheme itself.
$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = ""
$btnTheme.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
$btnTheme.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - $script:UiGap - $script:UiIconButtonSize),15)
$btnTheme.Anchor = "Top,Right"
$btnTheme.Tag = "button"
$btnTheme.Image = Get-ThemedIconImage "moon" ([System.Drawing.Color]::FromArgb(32,32,32))
Style-FlatButton $btnTheme $false 8
$top.Controls.Add($btnTheme)
$script:appToolTip.SetToolTip($btnTheme, "Switch to Dark Mode")

# A small circular "i" info button replaces the old
# always-on privacy/credit text: clicking it opens the About dialog (see
# Show-AboutDialog) with the full copyright/license/no-telemetry statement,
# keeping the header itself uncluttered. Sits just left of the theme toggle,
# in the same right-hand cluster.
$btnInfo = New-Object System.Windows.Forms.Button
$btnInfo.Text = ""
$btnInfo.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
$btnInfo.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - (2 * $script:UiIconButtonSize) - (2 * $script:UiGap)),15)
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
$btnOpen.Size = New-Object System.Drawing.Size($script:OpenButtonWidth,$script:CompactButtonHeight)
$btnOpen.Location = New-Object System.Drawing.Point(330,17)
$btnOpen.Font = New-UIFont 8.3
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
$lblFile.Location = New-Object System.Drawing.Point(($btnOpen.Right + 14),11)
$lblFile.Size = New-Object System.Drawing.Size(400,22)
$lblFile.Font = New-UIFont 9.6 ([System.Drawing.FontStyle]::Bold)
$lblFile.Tag = "heading"
$top.Controls.Add($lblFile)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Open a file to begin."
$lblHint.AutoEllipsis = $true
$lblHint.Location = New-Object System.Drawing.Point(($btnOpen.Right + 14),33)
$lblHint.Size = New-Object System.Drawing.Size(400,20)
$lblHint.Font = New-UIFont 8.4
$lblHint.Tag = "muted"
$top.Controls.Add($lblHint)

# Main layout: a narrow Photoshop-style tool rail, the preview workspace,
# and the inspector. Losing the old 245px wizard rail in favor of a 60px
# icon rail is most of where the extra preview space comes from.
$main = New-Object System.Windows.Forms.TableLayoutPanel
$main.Dock = "None"
$main.Location = New-Object System.Drawing.Point(0,$script:HeaderHeight)
$main.Size = New-Object System.Drawing.Size($form.ClientSize.Width,([Math]::Max(1,$form.ClientSize.Height - $script:HeaderHeight)))
$main.Anchor = "Top,Bottom,Left,Right"
$main.ColumnCount = 3
$main.RowCount = 1
$main.Padding = New-Object System.Windows.Forms.Padding(0)
$main.Margin = New-Object System.Windows.Forms.Padding(0)
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,$script:ToolbarWidth)))
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,100)))
# v1.4 preview starts with the inspector collapsed; its slim host contains
# only the persistent restore button until the user opens Redaction Area.
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,$script:InspectorCollapsedWidth)))
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
# TableLayoutPanel gives child controls a default 3px Margin. In the compact
# 38px toolbar column that silently reduced the usable width below the 34px
# icon-button width and clipped the buttons on their right edge. The toolbar
# itself must occupy the entire column; UiGap provides the intended spacing.
$toolbar.Margin = New-Object System.Windows.Forms.Padding(0)
$toolbar.Padding = New-Object System.Windows.Forms.Padding(0)
$toolbar.Tag = "toolbar"
$main.Controls.Add($toolbar,0,0)

$lblToolsHeading = New-Object System.Windows.Forms.Label
$lblToolsHeading.Text = "Tools"
$lblToolsHeading.TextAlign = "MiddleCenter"
$lblToolsHeading.Location = New-Object System.Drawing.Point(0,4)
$lblToolsHeading.Size = New-Object System.Drawing.Size($script:ToolbarWidth,14)
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
    $b.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
    $b.Tag = "choice"
    Enable-RoundedPaint $b 10
    $parent.Controls.Add($b)
    $script:appToolTip.SetToolTip($b, $tooltipText)
    Register-ThemedIcon $b $iconName
    return $b
}

$rbRectangle = New-ToolbarIconButton $toolbar "rectangle" $script:UiGap 22 "Rectangle Selection"
$rbRectangle.Checked = $true
$rbOval = New-ToolbarIconButton $toolbar "oval" $script:UiGap 60 "Oval Selection"
$rbFreeform = New-ToolbarIconButton $toolbar "freeform" $script:UiGap 98 "Freeform Selection"
$rbZoom = New-ToolbarIconButton $toolbar "zoom" $script:UiGap 136 "Zoom Tool - left click in, right click out; right-drag pans; mouse wheel zooms around pointer"

Add-Rule $toolbar $script:UiGap 176 ($script:ToolbarWidth - (2 * $script:UiGap)) | Out-Null

$lblStyleHeading = New-Object System.Windows.Forms.Label
$lblStyleHeading.Text = "Style"
$lblStyleHeading.TextAlign = "MiddleCenter"
$lblStyleHeading.Location = New-Object System.Drawing.Point(0,184)
$lblStyleHeading.Size = New-Object System.Drawing.Size($script:ToolbarWidth,14)
$lblStyleHeading.Font = New-UIFont 7.2 ([System.Drawing.FontStyle]::Bold)
$lblStyleHeading.Tag = "muted"
$toolbar.Controls.Add($lblStyleHeading)

# Redaction mode as its own isolated panel so WinForms' "RadioButtons
# auto-group by immediate parent" behavior doesn't lump these in with the
# Rectangle/Oval/Freeform tool buttons sitting directly on $toolbar.
$modeRow = New-Object System.Windows.Forms.Panel
$modeRow.Location = New-Object System.Drawing.Point(0,202)
$modeRow.Size = New-Object System.Drawing.Size($script:ToolbarWidth,110)
$toolbar.Controls.Add($modeRow)

$rbModeBlack = New-ToolbarIconButton $modeRow "black" $script:UiGap 0 "Coloured Box - secure opaque redaction"
$rbModeBlack.Checked = $true   # Secure opaque redaction is the default mode
$rbModeBlur = New-ToolbarIconButton $modeRow "blur" $script:UiGap 38 "Blur - visual obscuration only; use Coloured Box for secure redaction"
$rbModePixelate = New-ToolbarIconButton $modeRow "pixelate" $script:UiGap 76 "Pixelate - visual obscuration only; use Coloured Box for secure redaction"

# CENTER -------------------------------------------------------------
$center = New-Object System.Windows.Forms.Panel
$center.Dock = "Fill"
# UiGap is the exact space between the left toolbar and preview. The right
# padding is deliberately zero so, when Redaction Area is collapsed, the
# preview stops exactly UiGap pixels before the persistent restore icon.
$center.Padding = New-Object System.Windows.Forms.Padding($script:UiGap,$script:UiGap,0,2)
$center.Tag = "workspace"
$main.Controls.Add($center,1,0)

# Playback / timeline panel at the bottom of the center column.
$bottom = New-Object System.Windows.Forms.Panel
$bottom.Dock = "Bottom"
$bottom.Height = 156
$bottom.Padding = New-Object System.Windows.Forms.Padding(0)
$bottom.Tag = "workspace"
$center.Controls.Add($bottom)

$lblPos = New-Object System.Windows.Forms.Label
$lblPos.Text = "Preview frame"
$lblPos.Location = New-Object System.Drawing.Point(0,1)
$lblPos.Size = New-Object System.Drawing.Size(110,22)
$lblPos.Font = New-UIFont 8.5
$lblPos.Tag = "muted"
$bottom.Controls.Add($lblPos)

$lblPosValue = New-Object System.Windows.Forms.Label
$lblPosValue.Text = "00:00:00.000"
$lblPosValue.Location = New-Object System.Drawing.Point(112,0)
$lblPosValue.Size = New-Object System.Drawing.Size(110,24)
$lblPosValue.Font = New-UIFont 9.1 ([System.Drawing.FontStyle]::Bold)
$lblPosValue.Tag = "heading"
$bottom.Controls.Add($lblPosValue)

$lblFrameCount = New-Object System.Windows.Forms.Label
$lblFrameCount.Text = "Frame 0 / 0"
$lblFrameCount.TextAlign = "MiddleRight"
$lblFrameCount.Location = New-Object System.Drawing.Point(520,1)
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
$seekBar.Location = New-Object System.Drawing.Point(0,20)
$seekBar.Size = New-Object System.Drawing.Size(690,28)
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
    $trackY = 12
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
# Sits in its own compact row directly below the seek bar, keeping the red
# redaction-range marks clear of the seek track itself.
$scrubberMarkers.Location = New-Object System.Drawing.Point(10,48)
$scrubberMarkers.Size = New-Object System.Drawing.Size(670,8)
# No Anchor - same Anchor-baseline-timing issue as $seekBar just above.
# It stays 10px inset on each side and Update-PolishedLayout resizes it from
# the live bottom-panel width. Parent + child invalidation there also clears
# the OLD bounds whenever this strip shrinks, preventing stale red range
# pixels from being left behind after panel/window layout changes.
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

# v2.2.0 B1-r2: compact quarter-turn controls now use the user-supplied
# transparent PNG glyphs, embedded in the single-file script just like the
# established toolbar icons. Runtime tinting gives them a consistent Day/Dark
# appearance and lets the disabled state be unmistakably greyed out.
function New-RotateButton([string]$iconName, [string]$tooltipText) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = ""
    $b.Image = Get-IconImage $iconName
    $b.Size = New-Object System.Drawing.Size(38,38)
    $b.Enabled = $false
    Style-FlatButton $b $false 10
    $script:appToolTip.SetToolTip($b, $tooltipText)
    return $b
}

# The custom rounded-button painter draws icons itself, so WinForms' normal
# disabled greying is not visible. B1-r3 keeps Rotate/Previous/Next as clean
# icon-only controls with no visible tile/border; their glyph alone changes
# between normal and deliberately muted disabled colours. Play/Pause keeps its
# accented circular treatment.
function Update-TransportButtonVisuals {
    if (-not $btnRotateCCW -or -not $btnRotateCW -or -not $btnPrevFrame -or
        -not $btnNextFrame -or -not $btnPlayPause) { return }

    $disabledBack = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(55,58,65)
    } else {
        [System.Drawing.Color]::FromArgb(222,227,230)
    }
    $disabledBorder = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(88,93,103)
    } else {
        [System.Drawing.Color]::FromArgb(197,205,210)
    }
    $disabledIcon = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(142,149,159)
    } else {
        [System.Drawing.Color]::FromArgb(148,158,166)
    }

    foreach ($entry in @(
        @{ Button = $btnRotateCCW; Icon = "rotate_ccw" },
        @{ Button = $btnPrevFrame; Icon = "previous_frame" },
        @{ Button = $btnNextFrame; Icon = "next_frame" },
        @{ Button = $btnRotateCW; Icon = "rotate_cw" }
    )) {
        $b = $entry.Button
        # Match the parent transport row so there is no visible square/rounded
        # tile behind these four glyphs. Disabled state remains obvious through
        # the lower-contrast icon itself.
        $b.BackColor = if ($b.Parent) { $b.Parent.BackColor } else { $script:cPanelCurrent }
        # WinForms ButtonBase does not permit Transparent BorderColor.
        # Make these controls genuinely chrome-free by disabling the native
        # flat border, while matching the painter's border colour to the
        # surrounding row so the custom rounded painter also has nothing
        # visibly distinct to draw.
        $b.FlatAppearance.BorderSize = 0
        $b.FlatAppearance.BorderColor = $b.BackColor
        if ($b.Enabled) {
            $b.Image = Get-ThemedIconImage $entry.Icon $script:cTextCurrent
        }
        else {
            $b.Image = Get-ThemedIconImage $entry.Icon $disabledIcon
        }
        $b.Invalidate()
    }

    $playIconName = if ($script:isPlaying) { "pause" } else { "play" }
    if ($btnPlayPause.Enabled) {
        $btnPlayPause.BackColor = $script:cAccentCurrent
        $btnPlayPause.FlatAppearance.BorderColor = $script:cAccentCurrent
        $btnPlayPause.Image = Get-ThemedIconImage $playIconName ([System.Drawing.Color]::White)
    }
    else {
        $btnPlayPause.BackColor = $disabledBack
        $btnPlayPause.FlatAppearance.BorderColor = $disabledBorder
        $btnPlayPause.Image = Get-ThemedIconImage $playIconName $disabledIcon
    }
    $btnPlayPause.Invalidate()
}

# Unified redaction/playback control row: Begin Redaction - Rotate CCW -
# Previous Frame - Play/Pause - Next Frame - Rotate CW - End Redaction, with
# embedded user-supplied transport/rotation artwork and explicit disabled-state
# greying for controls that are unavailable,
# Cancel Redaction right-justified on the same row. Play/Pause is centered
# under the preview;
# Begin/Prev/Next/End cluster symmetrically around it - the X positions
# below are placeholders, recomputed to stay centered on every resize by
# Update-PolishedLayout (WinForms anchoring alone can't express "centered").
$btnStartRedaction = New-Object System.Windows.Forms.Button
$btnStartRedaction.Text = "Begin Redaction"
$btnStartRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
$btnStartRedaction.Location = New-Object System.Drawing.Point(0,69)
$btnStartRedaction.Enabled = $false
$btnStartRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnStartRedaction $true
$bottom.Controls.Add($btnStartRedaction)

$btnAddRedaction = New-Object System.Windows.Forms.Button
$btnAddRedaction.Text = "Create Redaction"
$btnAddRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
$btnAddRedaction.Location = New-Object System.Drawing.Point(0,69)
$btnAddRedaction.Enabled = $false
$btnAddRedaction.Visible = $false
$btnAddRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnAddRedaction $true
$bottom.Controls.Add($btnAddRedaction)

$btnRotateCCW = New-RotateButton "rotate_ccw" "Rotate 90° anticlockwise"
$bottom.Controls.Add($btnRotateCCW)

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

$btnRotateCW = New-RotateButton "rotate_cw" "Rotate 90° clockwise"
$bottom.Controls.Add($btnRotateCW)

$btnEndRedaction = New-Object System.Windows.Forms.Button
$btnEndRedaction.Text = "End Redaction"
$btnEndRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
$btnEndRedaction.Location = New-Object System.Drawing.Point(0,69)
$btnEndRedaction.Enabled = $false
$btnEndRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnEndRedaction
$bottom.Controls.Add($btnEndRedaction)

$btnCancelRedaction = New-Object System.Windows.Forms.Button
$btnCancelRedaction.Text = "Cancel Redaction"
$btnCancelRedaction.Location = New-Object System.Drawing.Point(560,69)
$btnCancelRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
# No Anchor here - Update-PolishedLayout repositions this button by hand on
# every resize (see the comment there for why trusting Anchor's own math
# caused it to overlap End Redaction / Next Frame).
$btnCancelRedaction.Enabled = $false
$btnCancelRedaction.Font = New-UIFont 8.2
Style-FlatButton $btnCancelRedaction
$bottom.Controls.Add($btnCancelRedaction)

# C1 Standard / Enhanced selector.
# Standard remains the default. Enhanced sits immediately before the existing
# Blur/Pixelation strength control and is visible only for those two modes.
# C1 evaluates Enhanced at strength 5 only, so the strength slider remains
# visible but disabled while Enhanced is checked.
$chkEnhanced = New-Object System.Windows.Forms.CheckBox
$chkEnhanced.Text = "Aggressive"
$chkEnhanced.Checked = $false
$chkEnhanced.Location = New-Object System.Drawing.Point(0,70)
$chkEnhanced.Size = New-Object System.Drawing.Size(88,24)
$chkEnhanced.Font = New-UIFont 8.4
$script:appToolTip.SetToolTip($chkEnhanced, "Aggressive - discards more source detail before applying the effect, making reconstruction more difficult. Unchecked uses Default mode.")
$bottom.Controls.Add($chkEnhanced)

$lblStrength = New-Object System.Windows.Forms.Label
$lblStrength.Text = "Blur Strength: 5"
$lblStrength.Location = New-Object System.Drawing.Point(94,62)
$lblStrength.Size = New-Object System.Drawing.Size(170,18)
$lblStrength.Font = New-UIFont 8.0
$lblStrength.Tag = "muted"
$bottom.Controls.Add($lblStrength)

$sliderStrength = New-Object System.Windows.Forms.TrackBar
$sliderStrength.Minimum = 1
$sliderStrength.Maximum = 10
$sliderStrength.Value = $redactionStrength
$sliderStrength.TickStyle = [System.Windows.Forms.TickStyle]::None
$sliderStrength.AutoSize = $false
$sliderStrength.Location = New-Object System.Drawing.Point(94,79)
$sliderStrength.Size = New-Object System.Drawing.Size(170,28)
$script:appToolTip.SetToolTip($sliderStrength, "How strong the Blur/Pixelate effect is")
$bottom.Controls.Add($sliderStrength)
$sliderStrength.BringToFront()

$sliderStrength.Add_ValueChanged({
    $script:redactionStrength = $sliderStrength.Value
    $modeName = if ($rbModePixelate.Checked) { "Pixelation" } else { "Blur" }
    if ($script:redactionEnhanced) { $lblStrength.Text = "$modeName Strength: 5 (Aggressive)" }
    else { $lblStrength.Text = "$modeName Strength: $($sliderStrength.Value)" }
    if ($isImageMode) { $picture.Invalidate() }
})

$chkEnhanced.Add_CheckedChanged({
    $script:redactionEnhanced = [bool]$chkEnhanced.Checked
    if ($script:redactionEnhanced -and $sliderStrength.Value -ne 5) { $sliderStrength.Value = 5 }
    Update-StrengthSliderVisibility
    Update-RedactionButtons
    if ($isImageMode) { $picture.Invalidate() }
})

function Update-StrengthSliderVisibility {
    $show = $rbModeBlur.Checked -or $rbModePixelate.Checked
    $chkEnhanced.Visible = $show
    $lblStrength.Visible = $show
    $sliderStrength.Visible = $show
    $canEdit = $show -and -not $pendingRedaction
    $chkEnhanced.Enabled = $canEdit
    $sliderStrength.Enabled = $canEdit -and -not $script:redactionEnhanced
    if ($show) {
        $modeName = if ($rbModePixelate.Checked) { "Pixelation" } else { "Blur" }
        if ($script:redactionEnhanced) { $lblStrength.Text = "$modeName Strength: 5 (Aggressive)" }
        else { $lblStrength.Text = "$modeName Strength: $($sliderStrength.Value)" }
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
$lblColor.Location = New-Object System.Drawing.Point(0,62)
$lblColor.Size = New-Object System.Drawing.Size(170,18)
$lblColor.Font = New-UIFont 8.0
$lblColor.Tag = "muted"
$bottom.Controls.Add($lblColor)

$swatchColor = New-Object System.Windows.Forms.Panel
$swatchColor.Location = New-Object System.Drawing.Point(0,79)
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
$btnEyedropper.Location = New-Object System.Drawing.Point(70,79)
Style-FlatButton $btnEyedropper
# This is an icon-only affordance beside the colour swatch, not a separate
# boxed field. Suppress the rounded-button outline so its left border cannot
# appear as a stray vertical separator between the swatch and eyedropper.
$btnEyedropper.FlatAppearance.BorderSize = 0
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
    if ($script:eyedropperActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Cross
    } else {
        Update-PreviewCursor
    }
    Set-RedactionButtonColor $btnEyedropper $(if ($script:eyedropperActive) { "red" } else { "grey" })
})

$lblPending = New-Object System.Windows.Forms.Label
$lblPending.Text = "No redaction in progress."
$lblPending.TextAlign = "MiddleLeft"
# Compact status row: left-aligned with Box Colour / Ready. so panel
# collapse/restore cannot make the message appear to jump horizontally.
$lblPending.Location = New-Object System.Drawing.Point(0,114)
$lblPending.Size = New-Object System.Drawing.Size(690,16)
$lblPending.Anchor = "Top,Left,Right"
$lblPending.Font = New-UIFont 8.0
$lblPending.Tag = "muted"
$bottom.Controls.Add($lblPending)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready."
$status.Location = New-Object System.Drawing.Point(0,132)
$status.Size = New-Object System.Drawing.Size(690,16)
$status.Anchor = "Top,Left,Right"
$status.Font = New-UIFont 8.2
$status.Tag = "muted"
$bottom.Controls.Add($status)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(0,150)
$progress.Size = New-Object System.Drawing.Size(690,5)
$progress.Anchor = "Top,Left,Right"
$progress.Style = "Marquee"
$progress.Visible = $false
$bottom.Controls.Add($progress)

# Video preview between file card and timeline
$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Dock = "Fill"
$previewPanel.Padding = New-Object System.Windows.Forms.Padding(0)
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
$picture.SizeMode = "Normal"
# PictureBox is normally non-selectable. Slice 4 makes it programmatically
# focusable (without putting it in normal Tab navigation) so WinForms routes
# MouseWheel messages to the preview while the Zoom tool is active.
$picture.TabStop = $false
try {
    $setStyleMethod = [System.Windows.Forms.Control].GetMethod(
        "SetStyle",
        [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
    )
    if ($setStyleMethod) {
        [void]$setStyleMethod.Invoke($picture, @([System.Windows.Forms.ControlStyles]::Selectable, $true))
    }
} catch {}
$pictureFrame.Controls.Add($picture)

# Slice 4 visible zoom HUD. It is a child of the preview itself so it remains
# pinned inside the viewport regardless of the Redaction Area width. The HUD
# stays hidden until media is actually loaded.
$zoomHud = New-Object System.Windows.Forms.Panel
$zoomHud.Size = New-Object System.Drawing.Size(144,56)
$zoomHud.Visible = $false
$zoomHud.Tag = "zoomhud"
$picture.Controls.Add($zoomHud)

$lblZoomIndicator = New-Object System.Windows.Forms.Label
$lblZoomIndicator.Text = "Fit"
$lblZoomIndicator.TextAlign = "MiddleCenter"
$lblZoomIndicator.Font = New-UIFont 8.0 ([System.Drawing.FontStyle]::Bold)
$lblZoomIndicator.Location = New-Object System.Drawing.Point(4,2)
$lblZoomIndicator.Size = New-Object System.Drawing.Size(136,18)
$lblZoomIndicator.Tag = "zoomindicator"
$zoomHud.Controls.Add($lblZoomIndicator)

$btnZoomOut = New-Object System.Windows.Forms.Button
$btnZoomOut.Text = [char]0x2212
$btnZoomOut.Location = New-Object System.Drawing.Point(4,22)
$btnZoomOut.Size = New-Object System.Drawing.Size(32,28)
$btnZoomOut.Font = New-UIFont 12.0 ([System.Drawing.FontStyle]::Regular)
Style-FlatButton $btnZoomOut $false 7
$zoomHud.Controls.Add($btnZoomOut)
$script:appToolTip.SetToolTip($btnZoomOut, "Zoom out")

$btnZoomFit = New-Object System.Windows.Forms.Button
$btnZoomFit.Text = "Fit"
$btnZoomFit.Location = New-Object System.Drawing.Point(40,22)
$btnZoomFit.Size = New-Object System.Drawing.Size(64,28)
$btnZoomFit.Font = New-UIFont 8.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnZoomFit $false 7
$zoomHud.Controls.Add($btnZoomFit)
$script:appToolTip.SetToolTip($btnZoomFit, "Fit media to preview")

$btnZoomIn = New-Object System.Windows.Forms.Button
$btnZoomIn.Text = "+"
$btnZoomIn.Location = New-Object System.Drawing.Point(108,22)
$btnZoomIn.Size = New-Object System.Drawing.Size(32,28)
$btnZoomIn.Font = New-UIFont 12.0 ([System.Drawing.FontStyle]::Regular)
Style-FlatButton $btnZoomIn $false 7
$zoomHud.Controls.Add($btnZoomIn)
$script:appToolTip.SetToolTip($btnZoomIn, "Zoom in")

# Slice 3 r2 requires a full synchronous repaint whenever the preview viewport
# changes size, otherwise stale pixels from the old Fit rectangle can survive.
# Slice 4 attaches that Resize handler later, after its Zoom HUD helper functions
# have been defined, so construction-time resize events cannot call undefined
# PowerShell functions.

# $btnOpen now lives in the header ($top) itself - see its creation right
# after $lblAppSub, further up this file - rather than floating over the
# preview, so it's visible before any file is loaded and stays out of the
# video's own display area.

# RIGHT PANEL --------------------------------------------------------
# A host panel owns the inspector so the entire Redaction Area column can
# collapse to a slim restore strip without destroying/recreating any controls.
$rightHost = New-Object System.Windows.Forms.Panel
$rightHost.Dock = "Fill"
$rightHost.Padding = New-Object System.Windows.Forms.Padding(0)
$rightHost.Tag = "inspectorhost"
$main.Controls.Add($rightHost,2,0)

$right = New-Object System.Windows.Forms.Panel
$right.Dock = "Fill"
$right.Padding = New-Object System.Windows.Forms.Padding(10,8,10,8)
$right.AutoScroll = $true
$right.Tag = "inspector"
$rightHost.Controls.Add($right)

# One persistent panel-toggle button lives in the host rather than having
# separate expand/collapse buttons in different parents. The right edge of
# $rightHost never moves when its column changes width, so pinning one button
# to that edge keeps the control at the exact same screen position whether
# the Redaction Area is open or collapsed.
$btnRightPanelToggle = New-Object System.Windows.Forms.Button
$btnRightPanelToggle.Text = ""
$btnRightPanelToggle.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
$btnRightPanelToggle.Tag = "button"
$btnRightPanelToggle.Image = Get-ThemedIconImage "panel_expand" ([System.Drawing.Color]::FromArgb(32,32,32))
Style-FlatButton $btnRightPanelToggle $false 8
$rightHost.Controls.Add($btnRightPanelToggle)
$btnRightPanelToggle.BringToFront()
$script:appToolTip.SetToolTip($btnRightPanelToggle, "Collapse Redaction Area")

# v1.4 UI preview opens with Redaction Area collapsed by default.
$script:rightPanelCollapsed = $true
$right.Visible = $false

function Position-RightPanelToggle {
    if (-not $btnRightPanelToggle -or -not $rightHost) { return }
    $x = [Math]::Max(0, $rightHost.ClientSize.Width - $btnRightPanelToggle.Width - $script:UiGap)
    $btnRightPanelToggle.Location = New-Object System.Drawing.Point($x,$script:UiGap)
    $btnRightPanelToggle.BringToFront()
}

function Update-RightPanelToggleAppearance {
    $iconColor = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(240,240,240)
    } else {
        [System.Drawing.Color]::FromArgb(32,32,32)
    }
    if ($script:rightPanelCollapsed) {
        # When collapsed, show the icon that indicates opening/restoring the pane.
        $btnRightPanelToggle.Image = Get-ThemedIconImage "panel_collapse" $iconColor
        $script:appToolTip.SetToolTip($btnRightPanelToggle, "Restore Redaction Area")
    }
    else {
        # When open, show the icon that indicates collapsing/hiding the pane.
        $btnRightPanelToggle.Image = Get-ThemedIconImage "panel_expand" $iconColor
        $script:appToolTip.SetToolTip($btnRightPanelToggle, "Collapse Redaction Area")
    }
    $btnRightPanelToggle.Invalidate()
}

$rightHost.Add_Resize({
    Position-RightPanelToggle
})

function Set-RightPanelCollapsed([bool]$collapsed) {
    $script:rightPanelCollapsed = $collapsed
    $right.Visible = -not $collapsed
    if ($collapsed) {
        $main.ColumnStyles[2].Width = $script:InspectorCollapsedWidth
    }
    else {
        $main.ColumnStyles[2].Width = $script:InspectorExpandedWidth
    }

    # Perform the table-layout change first, then place the persistent toggle
    # against the host's final right edge. The button therefore never jumps
    # sideways when the column collapses/restores.
    $form.PerformLayout()
    Update-PolishedLayout
    Position-RightPanelToggle
    Update-RightPanelToggleAppearance

    # The timeline controls are manually resized by Update-PolishedLayout.
    # Invalidating the whole bottom region (children included) is important:
    # when a child shrinks, pixels from its OLD bounds otherwise remain on the
    # newly-exposed parent surface until some unrelated repaint occurs. Those
    # stale pixels were the "randomly redrawing" redaction-line artefacts seen
    # in the UI-preview test recording.
    $bottom.Invalidate($true)
    $seekBar.Invalidate()
    $scrubberMarkers.Invalidate()
    $picture.Invalidate()
}

$btnRightPanelToggle.Add_Click({
    Set-RightPanelCollapsed (-not $script:rightPanelCollapsed)
})

# Keep top-level geometry deterministic. WinForms Dock ordering can otherwise
# let a Fill control occupy the header area depending on z-order.
function Update-PolishedLayout {
    $topH = $script:HeaderHeight
    $headerH = $topH

    $top.Location = New-Object System.Drawing.Point(0,0)
    $top.Size = New-Object System.Drawing.Size($form.ClientSize.Width,$topH)

    # Keep the header action icons on the same UiGap edge grid as the
    # Redaction Area collapse/restore button.
    $themeX = [Math]::Max(0, $form.ClientSize.Width - $script:UiGap - $btnTheme.Width)
    $btnTheme.Location = New-Object System.Drawing.Point($themeX,15)
    $infoX = [Math]::Max(0, $themeX - $script:UiGap - $btnInfo.Width)
    $btnInfo.Location = New-Object System.Drawing.Point($infoX,15)

    # File labels stretch only through the remaining header space.
    $fileInfoW = [Math]::Max(60, $infoX - $lblFile.Left - 10)
    $lblFile.Size = New-Object System.Drawing.Size($fileInfoW,22)
    $lblHint.Size = New-Object System.Drawing.Size($fileInfoW,20)

    $main.Location = New-Object System.Drawing.Point(0,$headerH)
    $main.Size = New-Object System.Drawing.Size(
        $form.ClientSize.Width,
        [Math]::Max(1, $form.ClientSize.Height - $headerH)
    )

    # Center the transport/redaction cluster in the space between the
    # left-side colour/strength utility and the right-side Cancel/Export pair.
    $rowW = $bottom.ClientSize.Width
    if ($rowW -gt 0) {
        $oldSeekWidth = $seekBar.Width
        $oldMarkerWidth = $scrubberMarkers.Width
        $seekBar.Width = $rowW
        $scrubberMarkers.Width = [Math]::Max(0, $rowW - 20)

        if ($oldSeekWidth -ne $seekBar.Width -or $oldMarkerWidth -ne $scrubberMarkers.Width) {
            $bottom.Invalidate($true)
            $seekBar.Invalidate()
            $scrubberMarkers.Invalidate()
        }

        $gap = 10
        $wBeginEnd = $script:CompactButtonWidth
        $wRotate = 38
        $wPrevNext = 44
        $wPlay = 52
        $totalW = ($wBeginEnd * 2) + ($wRotate * 2) + ($wPrevNext * 2) + $wPlay + ($gap * 6)

        # The two compact action buttons live flush-right, Export immediately
        # to the right of Cancel, using the same UiGap edge spacing. Export is
        $cancelW = $script:CompactButtonWidth
        $exportW = $script:ExportButtonWidth
        $actionGap = $script:UiGap
        $exportX = [Math]::Max(0, $rowW - $script:UiGap - $exportW)
        $cancelX = [Math]::Max(0, $exportX - $actionGap - $cancelW)

        # wider than the other compact action buttons so its label remains on one line.
        # Reserve enough room at the left for the colour picker or strength
        # slider, then center the transport cluster in the remaining middle.
        $clusterZoneLeft = if ($chkEnhanced -and $chkEnhanced.Visible) { 280 } else { 180 }
        $clusterZoneRight = [Math]::Max($clusterZoneLeft, $cancelX - $gap)
        $clusterZoneW = [Math]::Max(0, $clusterZoneRight - $clusterZoneLeft)
        $x = $clusterZoneLeft + [Math]::Max(0, [int](($clusterZoneW - $totalW) / 2))

        $rowTop = 58
        $yPlay = $rowTop
        $yPrevNext = $rowTop + [int](($wPlay - $wPrevNext) / 2)
        $yCompact = $rowTop + [int](($wPlay - $script:CompactButtonHeight) / 2)

        $btnStartRedaction.Location = New-Object System.Drawing.Point($x,$yCompact)
        $btnAddRedaction.Location = New-Object System.Drawing.Point($x,$yCompact)
        $x += $wBeginEnd + $gap

        $btnRotateCCW.Location = New-Object System.Drawing.Point($x,($rowTop + [int](($wPlay - $wRotate) / 2)))
        $x += $wRotate + $gap

        $btnPrevFrame.Location = New-Object System.Drawing.Point($x,$yPrevNext)
        $x += $wPrevNext + $gap

        $btnPlayPause.Location = New-Object System.Drawing.Point($x,$yPlay)
        $x += $wPlay + $gap

        $btnNextFrame.Location = New-Object System.Drawing.Point($x,$yPrevNext)
        $x += $wPrevNext + $gap

        $btnRotateCW.Location = New-Object System.Drawing.Point($x,($rowTop + [int](($wPlay - $wRotate) / 2)))
        $x += $wRotate + $gap

        $btnEndRedaction.Location = New-Object System.Drawing.Point($x,$yCompact)

        $btnCancelRedaction.Location = New-Object System.Drawing.Point($cancelX,$yCompact)
        $btnExport.Location = New-Object System.Drawing.Point($exportX,$yCompact)
    }
}

$form.Add_SizeChanged({
    Update-PolishedLayout
})

$form.Add_Shown({
    # Start compact: Redaction Area is collapsed by default in v1.4.
    Set-RightPanelCollapsed $true
    Update-PolishedLayout
    $right.AutoScrollPosition = New-Object System.Drawing.Point(0,0)
    $form.ActiveControl = $btnOpen
})

$lblRedactionAreaTitle = Add-SectionTitle $right "Redaction Area" 0 $script:UiGap 280

# The Redaction Area collapse/restore control is hosted by $rightHost above.
# Keeping a single persistent button there prevents it moving when this panel
# is hidden and lets the supplied panel-direction glyphs remain easy to see.

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
# Compact themed warning/consent dialog used by the Blur/Pixelate, audio,
# and network-location warnings. It deliberately follows stock MessageBox
# proportions much more closely than the earlier oversized custom forms,
# while retaining TinyRedactionTool theming and optional session suppression.
#
# Returns an object with:
#   Accepted   - primary action chosen
#   Suppress   - "Don't show again this session" checked
function Show-CompactWarningDialog(
    [string]$WindowTitle,
    [string]$Heading,
    [string]$Body,
    [string]$PrimaryText = "OK",
    [string]$SecondaryText = "",
    [bool]$ShowSuppression = $true,
    [string]$BoldToken = "",
    [bool]$SuppressionDefaultChecked = $false
) {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(60,63,71) } else { [System.Drawing.Color]::FromArgb(223,238,245) }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(202,208,216) } else { [System.Drawing.Color]::FromArgb(78,91,110) }
    $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }
    $cButton = if ($isDark) { [System.Drawing.Color]::FromArgb(71,75,84) } else { [System.Drawing.Color]::FromArgb(240,248,251) }
    $cBorder = if ($isDark) { [System.Drawing.Color]::FromArgb(100,105,117) } else { [System.Drawing.Color]::FromArgb(190,209,218) }

    # Keep close to a stock WinForms MessageBox footprint. Height is derived
    # from the wrapped message so the longer network warnings grow only when
    # they genuinely need to.
    $dlgW = 450
    $margin = 14
    $iconW = 34
    $textX = $margin + $iconW + 10
    $textW = $dlgW - $textX - $margin

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = $WindowTitle
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.Font = New-UIFont 8.7
    $dlg.AutoScaleMode = "Dpi"

    $icon = New-Object System.Windows.Forms.PictureBox
    $icon.Image = [System.Drawing.SystemIcons]::Warning.ToBitmap()
    $icon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
    $icon.Location = New-Object System.Drawing.Point($margin,16)
    $icon.Size = New-Object System.Drawing.Size($iconW,$iconW)
    $dlg.Controls.Add($icon)

    # PowerShell variable names are case-insensitive. Do not call this control
    # $heading because the function parameter is $Heading; doing so coerces the
    # Label into the typed string parameter and makes .Text assignments fail.
    $headingLabel = New-Object System.Windows.Forms.Label
    $headingLabel.Text = $Heading
    $headingLabel.Font = New-UIFont 9.0 ([System.Drawing.FontStyle]::Bold)
    $headingLabel.ForeColor = $cText
    $headingLabel.BackColor = [System.Drawing.Color]::Transparent
    $headingLabel.Location = New-Object System.Drawing.Point($textX,14)
    $headingLabel.Size = New-Object System.Drawing.Size($textW,20)
    $dlg.Controls.Add($headingLabel)

    $boldMessageFont = $null
    if ([string]::IsNullOrEmpty($BoldToken)) {
        $message = New-Object System.Windows.Forms.Label
        $message.Text = $Body
        $message.Font = New-UIFont 8.4
        $message.ForeColor = $cMuted
        $message.BackColor = [System.Drawing.Color]::Transparent
        $message.AutoSize = $true
        $message.MaximumSize = New-Object System.Drawing.Size($textW,0)

        # Let WinForms measure its own wrapped text, then freeze the size. This is
        # more reliable than hand-counting lines across DPI/font combinations.
        $pref = $message.GetPreferredSize((New-Object System.Drawing.Size($textW,0)))
        $message.AutoSize = $false
        $message.Location = New-Object System.Drawing.Point($textX,38)
        $message.Size = New-Object System.Drawing.Size($textW,([Math]::Max(36,$pref.Height + 2)))
    }
    else {
        # A Label cannot mix font weights. Use a borderless read-only RichTextBox
        # only for dialogs that explicitly request an inline bold token.
        $message = New-Object System.Windows.Forms.RichTextBox
        $message.Text = $Body
        $message.Font = New-UIFont 8.4
        $message.ForeColor = $cMuted
        $message.BackColor = $cBg
        $message.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $message.ReadOnly = $true
        $message.DetectUrls = $false
        $message.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::None
        $message.TabStop = $false
        $message.ShortcutsEnabled = $false

        $measureFlags = [System.Windows.Forms.TextFormatFlags]::WordBreak -bor [System.Windows.Forms.TextFormatFlags]::TextBoxControl
        $measured = [System.Windows.Forms.TextRenderer]::MeasureText(
            $Body,
            $message.Font,
            (New-Object System.Drawing.Size($textW,10000)),
            $measureFlags
        )
        $message.Location = New-Object System.Drawing.Point($textX,38)
        $message.Size = New-Object System.Drawing.Size($textW,([Math]::Max(36,$measured.Height + 6)))

        $tokenIndex = $Body.IndexOf($BoldToken, [System.StringComparison]::Ordinal)
        if ($tokenIndex -ge 0) {
            $boldMessageFont = New-Object System.Drawing.Font(
                $message.Font,
                [System.Drawing.FontStyle]::Bold
            )
            $message.Select($tokenIndex, $BoldToken.Length)
            $message.SelectionFont = $boldMessageFont
            $message.Select(0,0)
        }
    }

    $dlg.Controls.Add($message)

    $y = $message.Bottom + 6

    $dontShow = $null
    if ($ShowSuppression) {
        $dontShow = New-Object System.Windows.Forms.CheckBox
        $dontShow.Text = "Don't show again this session"
        $dontShow.Checked = $SuppressionDefaultChecked
        $dontShow.Font = New-UIFont 8.2
        $dontShow.ForeColor = $cText
        $dontShow.BackColor = $cBg
        $dontShow.Location = New-Object System.Drawing.Point($textX,$y)
        $dontShow.Size = New-Object System.Drawing.Size(235,22)
        $dlg.Controls.Add($dontShow)
        $y = $dontShow.Bottom + 8
    }
    else {
        $y += 4
    }

    $buttonH = 28
    $primaryW = if ($PrimaryText.Length -gt 8) { 88 } else { 74 }
    $secondaryW = if ($SecondaryText.Length -gt 8) { 88 } else { 74 }
    $buttonGap = 8

    $primary = New-Object System.Windows.Forms.Button
    $primary.Text = $PrimaryText
    $primary.Size = New-Object System.Drawing.Size($primaryW,$buttonH)
    $primary.Location = New-Object System.Drawing.Point(($dlgW - $margin - $primaryW),$y)
    $primary.DialogResult = [System.Windows.Forms.DialogResult]::OK
    Style-FlatButton $primary $true 7
    $primary.BackColor = $cAccent
    $primary.ForeColor = [System.Drawing.Color]::White
    $primary.FlatAppearance.BorderColor = $cAccent
    $dlg.Controls.Add($primary)

    $secondary = $null
    if (-not [string]::IsNullOrWhiteSpace($SecondaryText)) {
        $secondary = New-Object System.Windows.Forms.Button
        $secondary.Text = $SecondaryText
        $secondary.Size = New-Object System.Drawing.Size($secondaryW,$buttonH)
        $secondary.Location = New-Object System.Drawing.Point(($primary.Left - $buttonGap - $secondaryW),$y)
        $secondary.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        Style-FlatButton $secondary $false 7
        # Explicitly theme the secondary button so Enable-RoundedPaint draws
        # the complete rounded outline instead of exposing fragments of the
        # native WinForms flat-button border.
        $secondary.BackColor = $cButton
        $secondary.ForeColor = $cText
        $secondary.FlatAppearance.BorderSize = 1
        $secondary.FlatAppearance.BorderColor = $cBorder
        $dlg.Controls.Add($secondary)
        $dlg.CancelButton = $secondary
    }
    else {
        $dlg.CancelButton = $primary
    }

    $dlg.AcceptButton = $primary
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgW,($primary.Bottom + 12))

    $result = $dlg.ShowDialog($form)
    $accepted = ($result -eq [System.Windows.Forms.DialogResult]::OK)
    $suppress = ($dontShow -and $dontShow.Checked)

    if ($icon.Image) { $icon.Image.Dispose() }
    $dlg.Dispose()
    if ($boldMessageFont) { $boldMessageFont.Dispose() }

    return [pscustomobject]@{
        Accepted = $accepted
        Suppress = $suppress
    }
}

function Show-VisualObscurationWarning {
    if ($script:suppressVisualObscurationWarning -or $script:visualObscurationWarningOpen) { return }

    $script:visualObscurationWarningOpen = $true
    try {
        $visualObscurationBody = @'
Blur and Pixelate obscure content, but don't completely destroy it.

In testing, AI-based reconstruction attempts and a prolonged third-party tool attack failed to recover hidden information.
However, this does not guarantee that sensitive material can never be retrieved.

An "Aggressive" option is available. It first reduces the selected area to a low-detail representation before applying Blur or Pixelate.
This discards more source information and makes reconstruction more difficult, but may produce a coarser visual result.

For maximum obscuration, use Black Box or Coloured Box.
'@

        $result = Show-CompactWarningDialog `
            "Visual obscuration warning" `
            "Blur and Pixelate are unsecure redaction methods." `
            $visualObscurationBody `
            "OK" `
            "" `
            $true `
            "Aggressive" `
            $true

        if ($result.Suppress) {
            $script:suppressVisualObscurationWarning = $true
        }
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

    if ($script:networkLocationWarningOpen) { return $false }
    $script:networkLocationWarningOpen = $true

    try {
        $result = Show-CompactWarningDialog `
            $titleText `
            $headingText `
            $messageText `
            "Continue" `
            "Cancel" `
            $true

        if ($result.Accepted -and $result.Suppress) {
            if ($kind -eq "Source") {
                $script:suppressNetworkSourceWarning = $true
            }
            else {
                $script:suppressNetworkDestinationWarning = $true
            }
        }

        return $result.Accepted
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

function Get-SelectedEnhanced {
    $mode = Get-SelectedMode
    return [bool]($script:redactionEnhanced -and ($mode -eq "Blur" -or $mode -eq "Pixelate"))
}

function Test-HasEnhancedRedactions {
    foreach ($r in $redactions) { if (Get-RedactionEnhanced $r) { return $true } }
    return $false
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
[void]$lvRedactions.Columns.Add("Mode", 92)
[void]$lvRedactions.Columns.Add("Marked range", 125)
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
$btnRemoveRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
Style-FlatButton $btnRemoveRedaction
$right.Controls.Add($btnRemoveRedaction)

$btnClearRedactions = New-Object System.Windows.Forms.Button
$btnClearRedactions.Text = "Clear All"
$btnClearRedactions.Location = New-Object System.Drawing.Point(140,378)
$btnClearRedactions.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
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
    if (-not $chkAudio.Checked) { return }
    if ($script:suppressAudioWarning) { return }
    if ($script:audioWarningOpen) { return }

    $script:audioWarningOpen = $true
    try {
        $result = Show-CompactWarningDialog `
            "Audio is not redacted" `
            "Audio will remain in the exported file" `
            "TinyRedactionTool does not inspect or redact audio. Include the primary audio track anyway?" `
            "Yes" `
            "No" `
            $true

        if (-not $result.Accepted) {
            $chkAudio.Checked = $false
        }
        elseif ($result.Suppress) {
            $script:suppressAudioWarning = $true
        }
    }
    finally {
        $script:audioWarningOpen = $false
    }
})

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export Redacted Video"
$btnExport.Location = New-Object System.Drawing.Point(0,69)
$btnExport.Size = New-Object System.Drawing.Size($script:ExportButtonWidth,$script:CompactButtonHeight)
$btnExport.Enabled = $false
$btnExport.Font = New-UIFont 7.8 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnExport $true
# Export now sits beside Cancel in the compact transport/action row instead
# of consuming a full-width row in Redaction Area.
$bottom.Controls.Add($btnExport)

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
$script:cButtonCurrent = [System.Drawing.Color]::FromArgb(240,248,251)
$script:cTextCurrent   = [System.Drawing.Color]::FromArgb(18,27,42)
$script:cBorderCurrent = [System.Drawing.Color]::FromArgb(190,209,218)
$script:cAccentCurrent = [System.Drawing.Color]::FromArgb(18,113,255)

function Apply-Theme {
    if ($script:isDarkMode) {
        # v2.2 D2 Dark Mode: raise the common application/workspace/panel
        # base to #3C3F47. Nearby cards, inputs, buttons and borders are
        # lifted with it so the theme stays coherent rather than simply
        # replacing one background colour in isolation.
        $cBg       = [System.Drawing.Color]::FromArgb(60,63,71)  # #3C3F47
        $cWorkspace= [System.Drawing.Color]::FromArgb(60,63,71)  # #3C3F47
        $cPanel    = [System.Drawing.Color]::FromArgb(60,63,71)  # #3C3F47
        $cCard     = [System.Drawing.Color]::FromArgb(68,72,81)  # #444851
        $cInput    = [System.Drawing.Color]::FromArgb(73,77,86)  # #494D56
        $cText     = [System.Drawing.Color]::FromArgb(241,245,249)
        $cMuted    = [System.Drawing.Color]::FromArgb(192,199,208)
        $cBorder   = [System.Drawing.Color]::FromArgb(100,105,117)
        $cAccent   = [System.Drawing.Color]::FromArgb(38,132,255)
        $cAccent2  = [System.Drawing.Color]::FromArgb(35,77,122)
        $cButton   = [System.Drawing.Color]::FromArgb(71,75,84)  # #474B54
        $cPreview  = [System.Drawing.Color]::FromArgb(26,28,32)
        $cIconNormal = [System.Drawing.Color]::FromArgb(240,240,240) # #F0F0F0
        $btnTheme.Text = ""
        $btnTheme.Image = Get-ThemedIconImage "sun" $cIconNormal
        $script:appToolTip.SetToolTip($btnTheme, "Switch to Light Mode")
    }
    else {
        # v1.4 Day Mode: a deliberate cool off-white instead of pure white.
        $cBg       = [System.Drawing.Color]::FromArgb(223,238,245) # #DFEEF5
        $cWorkspace= [System.Drawing.Color]::FromArgb(223,238,245) # #DFEEF5 - unified with the main Day background
        $cPanel    = [System.Drawing.Color]::FromArgb(223,238,245) # #DFEEF5
        $cCard     = [System.Drawing.Color]::FromArgb(240,247,250)
        $cInput    = [System.Drawing.Color]::FromArgb(248,252,254)
        $cText     = [System.Drawing.Color]::FromArgb(18,27,42)
        $cMuted    = [System.Drawing.Color]::FromArgb(82,101,115)
        $cBorder   = [System.Drawing.Color]::FromArgb(190,209,218)
        $cAccent   = [System.Drawing.Color]::FromArgb(18,113,255)
        $cAccent2  = [System.Drawing.Color]::FromArgb(205,230,244)
        $cButton   = [System.Drawing.Color]::FromArgb(240,248,251)
        $cPreview  = [System.Drawing.Color]::FromArgb(22,26,32)
        $cIconNormal = [System.Drawing.Color]::FromArgb(32,32,32) # #202020
        $btnTheme.Text = ""
        $btnTheme.Image = Get-ThemedIconImage "moon" $cIconNormal
        $script:appToolTip.SetToolTip($btnTheme, "Switch to Dark Mode")
    }

    $form.BackColor = $cBg
    $top.BackColor = $cPanel
    $toolbar.BackColor = $cPanel
    $center.BackColor = $cWorkspace
    $rightHost.BackColor = $cPanel
    $right.BackColor = $cPanel
    $bottom.BackColor = $cWorkspace
    $chkEnhanced.BackColor = $cWorkspace
    $chkEnhanced.ForeColor = $cText
    $previewPanel.BackColor = $cWorkspace
    $pictureFrame.BackColor = $cBorder
    $picture.BackColor = $cPreview
    $scrubberMarkers.BackColor = $cWorkspace
    $seekBar.BackColor = $cWorkspace
    $script:seekTrackColor = $cBorder
    $script:seekTrackDisabledColor = $cBorder
    $script:seekAccentColor = $cAccent
    $seekBar.Invalidate()

    foreach ($ctl in @($form,$top,$toolbar,$center,$rightHost,$right,$bottom,$previewPanel)) {
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

    foreach ($b in @($btnTheme,$btnRightPanelToggle,$btnRotateCCW,$btnPrevFrame,$btnNextFrame,$btnRotateCW,$btnEndRedaction,$btnCancelRedaction,$btnRemoveRedaction,$btnClearRedactions,$btnZoomOut,$btnZoomFit,$btnZoomIn)) {
        $b.BackColor = $cButton
        $b.ForeColor = $cText
        $b.FlatAppearance.BorderColor = $cBorder
    }

    foreach ($b in @($btnOpen,$btnPlayPause,$btnStartRedaction,$btnAddRedaction,$btnExport)) {
        $b.BackColor = $cAccent
        $b.ForeColor = [System.Drawing.Color]::White
        $b.FlatAppearance.BorderColor = $cAccent
    }

    foreach ($r in @($rbRectangle,$rbOval,$rbFreeform,$rbZoom,$rbModeBlack,$rbModeBlur,$rbModePixelate)) {
        if ($r.Checked) {
            $r.BackColor = if ($script:isDarkMode) { [System.Drawing.Color]::FromArgb(42,67,96) } else { $cAccent2 }
            $r.ForeColor = $cAccent
            $r.FlatAppearance.BorderColor = $cAccent
        } else {
            $r.BackColor = $cButton
            $r.ForeColor = $cText
            $r.FlatAppearance.BorderColor = $cBorder
        }
    }
    $modeRow.BackColor = $cPanel
    $zoomHud.BackColor = $cPanel
    $lblZoomIndicator.BackColor = [System.Drawing.Color]::Transparent
    $lblZoomIndicator.ForeColor = $cText
    Update-StrengthSliderVisibility
    Update-ThemedIcons $cIconNormal $cAccent
    Update-RightPanelToggleAppearance

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

    # Keep the eyedropper icon on the same base colour as its surrounding
    # panel and without a visible button border. Its glyph itself is still
    # tinted by Update-ThemedIcons for the active Day/Dark theme.
    $btnEyedropper.BackColor = $cPanel
    $btnEyedropper.ForeColor = $cText
    $btnEyedropper.FlatAppearance.BorderSize = 0
        $btnEyedropper.Invalidate()

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
    $script:cAccentCurrent = $cAccent
    Update-TransportButtonVisuals

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
# telemetry/no-network statement, license text, and a selectable GitHub URL.
# v2.0 deliberately does not launch the URL. A copy icon places it on the
# clipboard and shows a brief inline status message instead.
function Show-AboutDialog {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(60,63,71) } else { [System.Drawing.Color]::FromArgb(223,238,245) }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(192,199,208) } else { [System.Drawing.Color]::FromArgb(99,112,132) }
    $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }
    $cBorder = if ($isDark) { [System.Drawing.Color]::FromArgb(100,105,117) } else { [System.Drawing.Color]::FromArgb(218,224,232) }

    $dlgWidth = 430
    $contentWidth = $dlgWidth - 40

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "About TinyRedactionTool"
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgWidth, 300)
    $dlg.Font = New-UIFont 9.0
    $dlg.AutoScaleMode = "Dpi"

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(20,14)
    $panel.Size = New-Object System.Drawing.Size($contentWidth, 1)
    $panel.AutoSize = $false
    $dlg.Controls.Add($panel)

    $script:aboutY = 0
    $aboutEmphasis = if ($isDark) { $cText } else { [System.Drawing.Color]::Black }

    Add-CenteredAboutLabel $panel "TinyRedactionTool v2.2.0" (New-UIFont 15.5 ([System.Drawing.FontStyle]::Bold)) $cText $contentWidth 0 6 | Out-Null
    Add-CenteredAboutLabel $panel "Copyright (C) 2026 David McCabe" (New-UIFont 9.5 ([System.Drawing.FontStyle]::Bold)) $cText $contentWidth 0 5 | Out-Null
    Add-CenteredAboutLabel $panel "Local media processing. No telemetry or media uploads." (New-UIFont 8.5 ([System.Drawing.FontStyle]::Bold)) $aboutEmphasis $contentWidth 0 0 | Out-Null
    Add-CenteredAboutLabel $panel "Licensed under GPL-2.0-or-later. Source available on GitHub." (New-UIFont 8.5) $cMuted $contentWidth -4 0 | Out-Null

    $repoUrl = "https://github.com/mccabedd/tinyredactiontool/"

    # Keep the URL and copy affordance as one compact centred group instead
    # of pinning the icon to the far-right edge of the dialog.
    $urlBox = New-Object System.Windows.Forms.TextBox
    $urlBox.Text = $repoUrl
    $urlBox.ReadOnly = $true
    $urlBox.TabStop = $false
    $urlBox.SelectionStart = 0
    $urlBox.SelectionLength = 0
    $urlBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $urlBox.BackColor = $cBg
    $urlBox.ForeColor = $cText
    $urlBox.Font = New-UIFont 9.0

    $urlTextSize = [System.Windows.Forms.TextRenderer]::MeasureText($repoUrl, $urlBox.Font)
    $urlBoxWidth = $urlTextSize.Width + 2
    $copyGap = 6
    $copySize = 24
    $urlGroupWidth = $urlBoxWidth + $copyGap + $copySize

    $urlRow = New-Object System.Windows.Forms.Panel
    $urlRow.Location = New-Object System.Drawing.Point(
        [int](($contentWidth - $urlGroupWidth) / 2),
        ([Math]::Max(0, $script:aboutY - 4))
    )
    $urlRow.Size = New-Object System.Drawing.Size($urlGroupWidth, 28)
    $urlRow.BackColor = [System.Drawing.Color]::Transparent
    $panel.Controls.Add($urlRow)

    $urlBox.Location = New-Object System.Drawing.Point(0,5)
    $urlBox.Size = New-Object System.Drawing.Size($urlBoxWidth,20)
    $urlRow.Controls.Add($urlBox)

    # Use an icon-only PictureBox rather than a tiny styled Button. This keeps
    # the copy glyph visually clean and lets SizeMode=Zoom scale the RGBA icon
    # properly without WinForms button-image clipping/chrome.
    $btnCopyUrl = New-Object System.Windows.Forms.PictureBox
    $btnCopyUrl.Size = New-Object System.Drawing.Size($copySize,$copySize)
    $btnCopyUrl.Location = New-Object System.Drawing.Point(($urlBoxWidth + $copyGap),2)
    $btnCopyUrl.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $btnCopyUrl.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCopyUrl.BackColor = [System.Drawing.Color]::Transparent
    $copyIconColor = if ($isDark) { [System.Drawing.Color]::FromArgb(240,240,240) } else { [System.Drawing.Color]::FromArgb(32,32,32) }
    $btnCopyUrl.Image = Get-ThemedIconImage "copy" $copyIconColor
    $urlRow.Controls.Add($btnCopyUrl)

    $copyStatus = New-Object System.Windows.Forms.Label
    $copyStatus.Text = ""
    $copyStatus.TextAlign = "TopCenter"
    $copyStatus.Font = New-UIFont 8.2
    $copyStatus.ForeColor = $cMuted
    $copyStatus.BackColor = [System.Drawing.Color]::Transparent
    $copyStatus.Location = New-Object System.Drawing.Point(0, ($script:aboutY + 24))
    $copyStatus.Size = New-Object System.Drawing.Size($contentWidth, 16)
    $panel.Controls.Add($copyStatus)

    $copyNoticeTimer = New-Object System.Windows.Forms.Timer
    $copyNoticeTimer.Interval = 1500
    $copyNoticeTimer.Add_Tick({
        $copyNoticeTimer.Stop()
        $copyStatus.Text = ""
    }.GetNewClosure())

    $btnCopyUrl.Add_Click({
        $copied = $false
        for ($attempt = 0; $attempt -lt 3 -and -not $copied; $attempt++) {
            try {
                [System.Windows.Forms.Clipboard]::SetText($repoUrl)
                $copied = $true
            }
            catch {
                Start-Sleep -Milliseconds 60
            }
        }

        $copyNoticeTimer.Stop()
        if ($copied) {
            $copyStatus.Text = "URL has been copied to Clipboard"
            $copyStatus.ForeColor = $cMuted
        }
        else {
            $copyStatus.Text = "Could not copy URL to Clipboard"
            $copyStatus.ForeColor = [System.Drawing.Color]::FromArgb(200,70,70)
        }
        $copyNoticeTimer.Start()
    }.GetNewClosure())

    # Use a dialog-local ToolTip for the PictureBox copy affordance.
    # The shared application ToolTip is not reliable on this nested control
    # inside a modal dialog on some WinForms/PowerShell 5.1 setups.
    $aboutToolTip = New-Object System.Windows.Forms.ToolTip
    $aboutToolTip.ShowAlways = $true
    $aboutToolTip.InitialDelay = 350
    $aboutToolTip.ReshowDelay = 100
    $aboutToolTip.AutoPopDelay = 3000

    $btnCopyUrl.Add_MouseEnter({
        $aboutToolTip.Show(
            "Copy GitHub URL",
            $btnCopyUrl,
            0,
            ($btnCopyUrl.Height + 2),
            3000
        )
    }.GetNewClosure())

    $btnCopyUrl.Add_MouseLeave({
        $aboutToolTip.Hide($btnCopyUrl)
    }.GetNewClosure())

    $script:aboutY += 40

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Size = New-Object System.Drawing.Size(90,30)
    $btnClose.Location = New-Object System.Drawing.Point((($contentWidth - 90) / 2), $script:aboutY)
    $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
    Style-FlatButton $btnClose $true
    $btnClose.BackColor = $cAccent
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.FlatAppearance.BorderColor = $cAccent
    $panel.Controls.Add($btnClose)
    $script:aboutY += $btnClose.Height + 6

    $panel.Size = New-Object System.Drawing.Size($contentWidth, $script:aboutY)
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgWidth, ($script:aboutY + 24))
    $dlg.AcceptButton = $btnClose
    $dlg.Add_Shown({
        $urlBox.SelectionStart = 0
        $urlBox.SelectionLength = 0
        $btnClose.Select()
    }.GetNewClosure())

    $dlg.ShowDialog($form) | Out-Null
    if ($copyNoticeTimer) {
        $copyNoticeTimer.Stop()
        $copyNoticeTimer.Dispose()
    }
    if ($aboutToolTip) {
        $aboutToolTip.Dispose()
    }
    $dlg.Dispose()
}

$btnInfo.Add_Click({ Show-AboutDialog })

$rbModeBlur.Add_CheckedChanged({
    if ($rbModeBlur.Checked) { Show-VisualObscurationWarning }
})
$rbModePixelate.Add_CheckedChanged({
    if ($rbModePixelate.Checked) { Show-VisualObscurationWarning }
})

foreach ($r in @($rbRectangle,$rbOval,$rbFreeform,$rbZoom,$rbModeBlack,$rbModeBlur,$rbModePixelate)) {
    $r.Add_CheckedChanged({
        Apply-Theme
        # Apply-Theme paints the generic accent/neutral palette first.
        # Immediately restore the semantic Begin/End state colours so
        # switching Shape/Zoom/Style cannot turn a valid green/red action blue.
        Update-RedactionButtons
    })
}

Apply-Theme

# ----------------------------
# Geometry mapping
# ----------------------------
# v2.0.0 viewport transform. Slice 4 now exposes manual zoom through the same
# renderer/projection layer established in Slice 3. Navigation, playback, media
# timing and export remain on their proven paths.
function Get-FitZoomFactor {
    if (-not $picture -or $videoWidth -le 0 -or $videoHeight -le 0) { return 1.0 }

    $viewportWidth = [double]$picture.ClientSize.Width
    $viewportHeight = [double]$picture.ClientSize.Height
    if ($viewportWidth -le 0.0 -or $viewportHeight -le 0.0) { return 1.0 }

    return [double][Math]::Min(
        $viewportWidth / [double]$videoWidth,
        $viewportHeight / [double]$videoHeight
    )
}

function Get-ViewportTransform {
    if (-not $picture -or $videoWidth -le 0 -or $videoHeight -le 0) { return $null }

    $viewportWidth = [double]$picture.ClientSize.Width
    $viewportHeight = [double]$picture.ClientSize.Height
    if ($viewportWidth -le 0.0 -or $viewportHeight -le 0.0) { return $null }

    $fitScale = Get-FitZoomFactor
    if ($zoomMode -eq "Fit") {
        # Preserve the exact integer Fit geometry previously produced by
        # PictureBox SizeMode=Zoom. Slice 3 draws the bitmap itself through
        # this transform, so there is still no intentional visible change.
        $displayWidth = [double][int]([double]$videoWidth * [double]$fitScale)
        $displayHeight = [double][int]([double]$videoHeight * [double]$fitScale)
        if ($displayWidth -le 0.0 -or $displayHeight -le 0.0) { return $null }

        $originX = [double][int](($viewportWidth - $displayWidth) / 2.0)
        $originY = [double][int](($viewportHeight - $displayHeight) / 2.0)

        # The legacy PictureBox mapping rounds width/height independently to
        # whole screen pixels. Keep both effective axes here so Slice 2's
        # overlay projection matches that renderer exactly, even where those
        # two rounded ratios differ by a tiny fraction.
        $scaleX = $displayWidth / [double]$videoWidth
        $scaleY = $displayHeight / [double]$videoHeight
        $scale = [Math]::Min($scaleX, $scaleY)
    }
    else {
        $scale = [double]$zoomFactor
        if ([double]::IsNaN($scale) -or [double]::IsInfinity($scale) -or $scale -le 0.0) {
            $scale = [double]$fitScale
        }
        $scale = [Math]::Min([double]$maxZoomFactor, $scale)
        if ($scale -le 0.0 -or [double]::IsNaN($scale) -or [double]::IsInfinity($scale)) { return $null }

        $scaleX = $scale
        $scaleY = $scale
        $displayWidth = [double]$videoWidth * $scale
        $displayHeight = [double]$videoHeight * $scale
        $originX = (($viewportWidth - $displayWidth) / 2.0) + [double]$panOffsetX
        $originY = (($viewportHeight - $displayHeight) / 2.0) + [double]$panOffsetY
    }

    if ($scale -le 0.0 -or [double]::IsNaN($scale) -or [double]::IsInfinity($scale)) { return $null }

    return [pscustomobject]@{
        Scale = $scale
        ScaleX = [double]$scaleX
        ScaleY = [double]$scaleY
        FitScale = [double]$fitScale
        OriginX = $originX
        OriginY = $originY
        DisplayWidth = $displayWidth
        DisplayHeight = $displayHeight
        MediaWidth = [double]$videoWidth
        MediaHeight = [double]$videoHeight
        ViewportWidth = $viewportWidth
        ViewportHeight = $viewportHeight
    }
}

function MediaPoint-To-ViewPoint([System.Drawing.PointF]$point) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $viewX = [single]($transform.OriginX + ([double]$point.X * $transform.ScaleX))
    $viewY = [single]($transform.OriginY + ([double]$point.Y * $transform.ScaleY))
    return New-Object System.Drawing.PointF($viewX,$viewY)
}

function ViewPoint-To-MediaPoint([System.Drawing.PointF]$point, [bool]$clamp = $false) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $mediaX = ([double]$point.X - $transform.OriginX) / $transform.ScaleX
    $mediaY = ([double]$point.Y - $transform.OriginY) / $transform.ScaleY

    if ($clamp) {
        $mediaX = [Math]::Max(0.0, [Math]::Min($mediaX, $transform.MediaWidth - 1.0))
        $mediaY = [Math]::Max(0.0, [Math]::Min($mediaY, $transform.MediaHeight - 1.0))
    }

    return New-Object System.Drawing.PointF([single]$mediaX, [single]$mediaY)
}

function MediaRect-To-ViewRect([System.Drawing.RectangleF]$rect) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $viewX = [single]($transform.OriginX + ([double]$rect.X * $transform.ScaleX))
    $viewY = [single]($transform.OriginY + ([double]$rect.Y * $transform.ScaleY))
    $viewW = [single]([double]$rect.Width * $transform.ScaleX)
    $viewH = [single]([double]$rect.Height * $transform.ScaleY)
    return New-Object System.Drawing.RectangleF($viewX,$viewY,$viewW,$viewH)
}

function MediaPoints-To-ViewPoints($points) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $output = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    foreach ($point in $points) {
        $viewX = [single]($transform.OriginX + ([double]$point.X * $transform.ScaleX))
        $viewY = [single]($transform.OriginY + ([double]$point.Y * $transform.ScaleY))
        $output.Add((New-Object System.Drawing.PointF($viewX,$viewY)))
    }
    return $output.ToArray()
}

function Get-MediaViewRect {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $viewX = [single]$transform.OriginX
    $viewY = [single]$transform.OriginY
    $viewW = [single]$transform.DisplayWidth
    $viewH = [single]$transform.DisplayHeight
    return New-Object System.Drawing.RectangleF($viewX,$viewY,$viewW,$viewH)
}

function Clamp-MediaPoint([System.Drawing.PointF]$point) {
    if ($videoWidth -le 0 -or $videoHeight -le 0) { return $point }

    $x = [Math]::Max(0.0, [Math]::Min([double]$point.X, [double]$videoWidth - 1.0))
    $y = [Math]::Max(0.0, [Math]::Min([double]$point.Y, [double]$videoHeight - 1.0))
    return New-Object System.Drawing.PointF([single]$x, [single]$y)
}


# ===== Resize Slice 1 helpers: Rectangle/Square only =====
# Handles are VIEW-space UI affordances with constant screen-pixel size. The
# rectangle itself remains canonical MEDIA-space geometry at all times.
function Get-RectangleResizeHandleCenters([System.Drawing.RectangleF]$rect) {
    $dr = MediaRect-To-ViewRect $rect
    if (-not $dr) { return @() }

    $left = [double]$dr.X
    $top = [double]$dr.Y
    $right = [double]$dr.X + [double]$dr.Width
    $bottom = [double]$dr.Y + [double]$dr.Height
    $midX = ($left + $right) / 2.0
    $midY = ($top + $bottom) / 2.0

    return @(
        [pscustomobject]@{ Name = "NW"; X = $left;  Y = $top },
        [pscustomobject]@{ Name = "N";  X = $midX;  Y = $top },
        [pscustomobject]@{ Name = "NE"; X = $right; Y = $top },
        [pscustomobject]@{ Name = "E";  X = $right; Y = $midY },
        [pscustomobject]@{ Name = "SE"; X = $right; Y = $bottom },
        [pscustomobject]@{ Name = "S";  X = $midX;  Y = $bottom },
        [pscustomobject]@{ Name = "SW"; X = $left;  Y = $bottom },
        [pscustomobject]@{ Name = "W";  X = $left;  Y = $midY }
    )
}

function Get-RectangleResizeHandleAtViewPoint([System.Drawing.PointF]$viewPoint, [System.Drawing.RectangleF]$rect) {
    $half = [double]$script:resizeHandleHitSize / 2.0
    $bestName = "None"
    $bestDist = [double]::PositiveInfinity

    foreach ($h in (Get-RectangleResizeHandleCenters $rect)) {
        $dx = [double]$viewPoint.X - [double]$h.X
        $dy = [double]$viewPoint.Y - [double]$h.Y
        if ([Math]::Abs($dx) -le $half -and [Math]::Abs($dy) -le $half) {
            $d2 = ($dx * $dx) + ($dy * $dy)
            if ($d2 -lt $bestDist) {
                $bestDist = $d2
                $bestName = [string]$h.Name
            }
        }
    }
    return $bestName
}

function Get-RectangleResizeCursor([string]$handle) {
    switch ($handle) {
        "N"  { return [System.Windows.Forms.Cursors]::SizeNS }
        "S"  { return [System.Windows.Forms.Cursors]::SizeNS }
        "E"  { return [System.Windows.Forms.Cursors]::SizeWE }
        "W"  { return [System.Windows.Forms.Cursors]::SizeWE }
        "NW" { return [System.Windows.Forms.Cursors]::SizeNWSE }
        "SE" { return [System.Windows.Forms.Cursors]::SizeNWSE }
        "NE" { return [System.Windows.Forms.Cursors]::SizeNESW }
        "SW" { return [System.Windows.Forms.Cursors]::SizeNESW }
        default { return [System.Windows.Forms.Cursors]::Default }
    }
}

function Get-RectangleResizeResult(
    [System.Drawing.RectangleF]$orig,
    [string]$handle,
    [System.Drawing.PointF]$pointer,
    [bool]$constrainSquare,
    [System.Drawing.RectangleF]$bounds
) {
    $minSize = [double]$script:resizeMinMediaSize
    $bL = [double]$bounds.X
    $bT = [double]$bounds.Y
    $bR = [double]$bounds.X + [double]$bounds.Width
    $bB = [double]$bounds.Y + [double]$bounds.Height

    $oL = [double]$orig.X
    $oT = [double]$orig.Y
    $oR = [double]$orig.X + [double]$orig.Width
    $oB = [double]$orig.Y + [double]$orig.Height
    $cx = ($oL + $oR) / 2.0
    $cy = ($oT + $oB) / 2.0

    $px = [Math]::Max($bL, [Math]::Min([double]$pointer.X, $bR))
    $py = [Math]::Max($bT, [Math]::Min([double]$pointer.Y, $bB))

    $l = $oL; $t = $oT; $r = $oR; $b = $oB

    if ($constrainSquare -and (@("NW","NE","SE","SW") -contains $handle)) {
        switch ($handle) {
            "NW" { $ax=$oR; $ay=$oB; $dx=-1.0; $dy=-1.0; $maxX=$ax-$bL; $maxY=$ay-$bT }
            "NE" { $ax=$oL; $ay=$oB; $dx= 1.0; $dy=-1.0; $maxX=$bR-$ax; $maxY=$ay-$bT }
            "SE" { $ax=$oL; $ay=$oT; $dx= 1.0; $dy= 1.0; $maxX=$bR-$ax; $maxY=$bB-$ay }
            "SW" { $ax=$oR; $ay=$oT; $dx=-1.0; $dy= 1.0; $maxX=$ax-$bL; $maxY=$bB-$ay }
        }
        $desired = [Math]::Max([Math]::Abs($px-$ax), [Math]::Abs($py-$ay))
        $maxSide = [Math]::Max(0.01, [Math]::Min($maxX,$maxY))
        $side = [Math]::Min($maxSide, [Math]::Max([Math]::Min($minSize,$maxSide), $desired))
        if ($dx -lt 0) { $l=$ax-$side; $r=$ax } else { $l=$ax; $r=$ax+$side }
        if ($dy -lt 0) { $t=$ay-$side; $b=$ay } else { $t=$ay; $b=$ay+$side }
    }
    elseif ($constrainSquare -and (@("N","S") -contains $handle)) {
        $anchorY = if ($handle -eq "N") { $oB } else { $oT }
        $desired = [Math]::Abs($py - $anchorY)
        $maxVertical = if ($handle -eq "N") { $anchorY-$bT } else { $bB-$anchorY }
        $maxHorizontal = 2.0 * [Math]::Min($cx-$bL, $bR-$cx)
        $maxSide = [Math]::Max(0.01, [Math]::Min($maxVertical,$maxHorizontal))
        $side = [Math]::Min($maxSide, [Math]::Max([Math]::Min($minSize,$maxSide), $desired))
        $l=$cx-($side/2.0); $r=$cx+($side/2.0)
        if ($handle -eq "N") { $t=$anchorY-$side; $b=$anchorY } else { $t=$anchorY; $b=$anchorY+$side }
    }
    elseif ($constrainSquare -and (@("E","W") -contains $handle)) {
        $anchorX = if ($handle -eq "W") { $oR } else { $oL }
        $desired = [Math]::Abs($px - $anchorX)
        $maxHorizontal = if ($handle -eq "W") { $anchorX-$bL } else { $bR-$anchorX }
        $maxVertical = 2.0 * [Math]::Min($cy-$bT, $bB-$cy)
        $maxSide = [Math]::Max(0.01, [Math]::Min($maxHorizontal,$maxVertical))
        $side = [Math]::Min($maxSide, [Math]::Max([Math]::Min($minSize,$maxSide), $desired))
        $t=$cy-($side/2.0); $b=$cy+($side/2.0)
        if ($handle -eq "W") { $l=$anchorX-$side; $r=$anchorX } else { $l=$anchorX; $r=$anchorX+$side }
    }
    else {
        switch ($handle) {
            "NW" { $l=[Math]::Max($bL,[Math]::Min($px,$oR-$minSize)); $t=[Math]::Max($bT,[Math]::Min($py,$oB-$minSize)) }
            "N"  { $t=[Math]::Max($bT,[Math]::Min($py,$oB-$minSize)) }
            "NE" { $r=[Math]::Min($bR,[Math]::Max($px,$oL+$minSize)); $t=[Math]::Max($bT,[Math]::Min($py,$oB-$minSize)) }
            "E"  { $r=[Math]::Min($bR,[Math]::Max($px,$oL+$minSize)) }
            "SE" { $r=[Math]::Min($bR,[Math]::Max($px,$oL+$minSize)); $b=[Math]::Min($bB,[Math]::Max($py,$oT+$minSize)) }
            "S"  { $b=[Math]::Min($bB,[Math]::Max($py,$oT+$minSize)) }
            "SW" { $l=[Math]::Max($bL,[Math]::Min($px,$oR-$minSize)); $b=[Math]::Min($bB,[Math]::Max($py,$oT+$minSize)) }
            "W"  { $l=[Math]::Max($bL,[Math]::Min($px,$oR-$minSize)) }
            default { return $orig }
        }
    }

    return New-Object System.Drawing.RectangleF(
        [single]$l,[single]$t,
        [single][Math]::Max(0.01,$r-$l),
        [single][Math]::Max(0.01,$b-$t))
}

function Test-RectangleDraftDragThreshold([System.Drawing.PointF]$startView, [System.Drawing.PointF]$currentView) {
    $dx = [double]$currentView.X - [double]$startView.X
    $dy = [double]$currentView.Y - [double]$startView.Y
    return ([Math]::Sqrt(($dx * $dx) + ($dy * $dy)) -ge [double]$script:resizeDraftDrawThreshold)
}

function Draw-RectangleResizeHandles($gfx, [System.Drawing.RectangleF]$rect) {
    if (-not $script:resizeSlice1Enabled -or -not $gfx) { return }
    $size = [double]$script:resizeHandleVisualSize
    $half = $size / 2.0
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
    try {
        foreach ($h in (Get-RectangleResizeHandleCenters $rect)) {
            $x = [single]([double]$h.X - $half)
            $y = [single]([double]$h.Y - $half)
            $gfx.FillRectangle($fill, $x, $y, [single]$size, [single]$size)
            $gfx.DrawRectangle($pen, $x, $y, [single]$size, [single]$size)
        }
    }
    finally {
        $fill.Dispose()
        $pen.Dispose()
    }
}


# ===== Resize Slice 2 helpers: Oval/Circle only =====
# Oval geometry remains the same canonical MEDIA-space RectangleF bounding box
# already used by v2.0.0. Only four VIEW-space handles are exposed: the north,
# east, south and west cardinal points of the ellipse.
function Get-OvalResizeHandleCenters([System.Drawing.RectangleF]$rect) {
    $dr = MediaRect-To-ViewRect $rect
    if (-not $dr) { return @() }

    $left = [double]$dr.X
    $top = [double]$dr.Y
    $right = [double]$dr.X + [double]$dr.Width
    $bottom = [double]$dr.Y + [double]$dr.Height
    $midX = ($left + $right) / 2.0
    $midY = ($top + $bottom) / 2.0

    return @(
        [pscustomobject]@{ Name = "N"; X = $midX;  Y = $top },
        [pscustomobject]@{ Name = "E"; X = $right; Y = $midY },
        [pscustomobject]@{ Name = "S"; X = $midX;  Y = $bottom },
        [pscustomobject]@{ Name = "W"; X = $left;  Y = $midY }
    )
}

function Get-OvalResizeHandleAtViewPoint([System.Drawing.PointF]$viewPoint, [System.Drawing.RectangleF]$rect) {
    $half = [double]$script:resizeHandleHitSize / 2.0
    $bestName = "None"
    $bestDist = [double]::PositiveInfinity

    foreach ($h in (Get-OvalResizeHandleCenters $rect)) {
        $dx = [double]$viewPoint.X - [double]$h.X
        $dy = [double]$viewPoint.Y - [double]$h.Y
        if ([Math]::Abs($dx) -le $half -and [Math]::Abs($dy) -le $half) {
            $d2 = ($dx * $dx) + ($dy * $dy)
            if ($d2 -lt $bestDist) {
                $bestDist = $d2
                $bestName = [string]$h.Name
            }
        }
    }
    return $bestName
}

function Get-OvalResizeCursor([string]$handle) {
    switch ($handle) {
        "N" { return [System.Windows.Forms.Cursors]::SizeNS }
        "S" { return [System.Windows.Forms.Cursors]::SizeNS }
        "E" { return [System.Windows.Forms.Cursors]::SizeWE }
        "W" { return [System.Windows.Forms.Cursors]::SizeWE }
        default { return [System.Windows.Forms.Cursors]::Default }
    }
}

function Get-OvalResizeResult(
    [System.Drawing.RectangleF]$orig,
    [string]$handle,
    [System.Drawing.PointF]$pointer,
    [bool]$constrainCircle,
    [System.Drawing.RectangleF]$bounds
) {
    # Cardinal-point ellipse resizing is mathematically the same bounding-box
    # edge operation already proven by Slice 1. Shift simply requests the
    # existing 1:1 side-handle constraint, producing a circle.
    if (@("N","E","S","W") -notcontains $handle) { return $orig }
    return Get-RectangleResizeResult $orig $handle $pointer $constrainCircle $bounds
}

function Draw-OvalResizeHandles($gfx, [System.Drawing.RectangleF]$rect) {
    if (-not $script:resizeSlice2Enabled -or -not $gfx) { return }
    $size = [double]$script:resizeHandleVisualSize
    $half = $size / 2.0
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
    try {
        foreach ($h in (Get-OvalResizeHandleCenters $rect)) {
            $x = [single]([double]$h.X - $half)
            $y = [single]([double]$h.Y - $half)
            $gfx.FillRectangle($fill, $x, $y, [single]$size, [single]$size)
            $gfx.DrawRectangle($pen, $x, $y, [single]$size, [single]$size)
        }
    }
    finally {
        $fill.Dispose()
        $pen.Dispose()
    }
}
# ===== End Resize Slice 2 helpers =====

# ===== Resize Slice 3 helpers: Freeform vertex editing only =====
# A closed Freeform polygon already stores every vertex as a canonical
# MEDIA-space PointF. These helpers only project the points for screen-space
# handles/hit-testing and return a cloned point list when one vertex moves.
function Get-FreeformVertexHandleCenters($points) {
    if (-not $points -or $points.Count -le 0) { return @() }
    $viewPoints = MediaPoints-To-ViewPoints $points
    if (-not $viewPoints) { return @() }

    $result = @()
    for ($i = 0; $i -lt $viewPoints.Count; $i++) {
        $vp = $viewPoints[$i]
        $result += [pscustomobject]@{ Index = [int]$i; X = [double]$vp.X; Y = [double]$vp.Y }
    }
    return $result
}

function Get-FreeformVertexHandleAtViewPoint([System.Drawing.PointF]$viewPoint, $points) {
    $half = [double]$script:resizeHandleHitSize / 2.0
    $bestIndex = -1
    $bestDist = [double]::PositiveInfinity

    foreach ($h in (Get-FreeformVertexHandleCenters $points)) {
        $dx = [double]$viewPoint.X - [double]$h.X
        $dy = [double]$viewPoint.Y - [double]$h.Y
        if ([Math]::Abs($dx) -le $half -and [Math]::Abs($dy) -le $half) {
            $d2 = ($dx * $dx) + ($dy * $dy)
            if ($d2 -lt $bestDist) {
                $bestDist = $d2
                $bestIndex = [int]$h.Index
            }
        }
    }
    return $bestIndex
}

function Get-FreeformVertexCursor {
    # Cross distinguishes precise single-vertex editing from SizeAll, which
    # continues to mean "move the whole closed Freeform shape".
    return [System.Windows.Forms.Cursors]::Cross
}

function Get-FreeformVertexEditResult(
    $points,
    [int]$vertexIndex,
    [System.Drawing.PointF]$pointer,
    [System.Drawing.RectangleF]$bounds
) {
    if (-not $points -or $vertexIndex -lt 0 -or $vertexIndex -ge $points.Count) { return ,$points }

    $bL = [double]$bounds.X
    $bT = [double]$bounds.Y
    $bR = [double]$bounds.X + [double]$bounds.Width
    $bB = [double]$bounds.Y + [double]$bounds.Height
    $x = [Math]::Max($bL, [Math]::Min([double]$pointer.X, $bR))
    $y = [Math]::Max($bT, [Math]::Min([double]$pointer.Y, $bB))

    $result = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    for ($i = 0; $i -lt $points.Count; $i++) {
        if ($i -eq $vertexIndex) {
            [void]$result.Add((New-Object System.Drawing.PointF([single]$x,[single]$y)))
        }
        else {
            $p = $points[$i]
            [void]$result.Add((New-Object System.Drawing.PointF([single]$p.X,[single]$p.Y)))
        }
    }
    return ,$result
}

function Draw-FreeformVertexHandles($gfx, $points) {
    if (-not $script:resizeSlice3Enabled -or -not $gfx -or -not $points -or $points.Count -lt 3) { return }
    $size = [double]$script:resizeHandleVisualSize
    $half = $size / 2.0
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
    try {
        foreach ($h in (Get-FreeformVertexHandleCenters $points)) {
            $x = [single]([double]$h.X - $half)
            $y = [single]([double]$h.Y - $half)
            $gfx.FillRectangle($fill, $x, $y, [single]$size, [single]$size)
            $gfx.DrawRectangle($pen, $x, $y, [single]$size, [single]$size)
        }
    }
    finally {
        $fill.Dispose()
        $pen.Dispose()
    }
}

# Resize Slice 3 r2: when a CLOSED, uncommitted Freeform is clicked outside,
# that first click is a dismissal gesture only. Clear the existing draft and
# consume the click; the next click may then start a new Freeform normally.
function Clear-ClosedFreeformDraftForOutsideClick {
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
    Update-PreviewCursor
}
# ===== End Resize Slice 3 helpers =====

# ===== End Resize Slice 1 helpers =====

function Reset-ViewportState {
    $script:zoomMode = "Fit"
    $script:zoomFactor = 1.0
    $script:panOffsetX = 0.0
    $script:panOffsetY = 0.0
    Update-ZoomHud
}

function Position-ZoomHud {
    if (-not $zoomHud -or -not $picture -or $zoomHud.IsDisposed -or $picture.IsDisposed) { return }
    $x = [Math]::Max($script:UiGap, $picture.ClientSize.Width - $zoomHud.Width - ($script:UiGap * 2))
    $y = [Math]::Max($script:UiGap, $picture.ClientSize.Height - $zoomHud.Height - ($script:UiGap * 2))
    $zoomHud.Location = New-Object System.Drawing.Point($x,$y)
    $zoomHud.BringToFront()
}

function Update-ZoomHud {
    if (-not $zoomHud -or -not $lblZoomIndicator) { return }

    $hasMedia = [bool]($videoPath -and $previewImage -and $videoWidth -gt 0 -and $videoHeight -gt 0)
    $zoomHud.Visible = $hasMedia
    if (-not $hasMedia) { return }

    $scale = if ($zoomMode -eq "Fit") { Get-FitZoomFactor } else { [double]$zoomFactor }
    if ([double]::IsNaN($scale) -or [double]::IsInfinity($scale) -or $scale -le 0.0) { $scale = 1.0 }
    $pct = [int][Math]::Round($scale * 100.0)
    if ($pct -lt 1) { $pct = 1 }
    $lblZoomIndicator.Text = if ($zoomMode -eq "Fit") { "Fit ($pct%)" } else { "$pct%" }

    $btnZoomIn.Enabled = ($scale -lt ([double]$maxZoomFactor - 0.000001))
    $btnZoomOut.Enabled = ($scale -gt ([double]$minZoomFactor + 0.000001))
    $btnZoomFit.Enabled = ($zoomMode -ne "Fit")
    Position-ZoomHud
}

function Clamp-ViewportPan([double]$minimumMaxX = 0.0, [double]$minimumMaxY = 0.0) {
    # Pan is purely VIEW state. Bound each axis at the natural edge limit:
    # when media is larger than the viewport it cannot be dragged past an edge
    # into avoidable blank space; when media is smaller it may move within the
    # available letterbox but cannot be dragged partly out of the viewport.
    if ($zoomMode -ne "Manual" -or -not $picture -or $videoWidth -le 0 -or $videoHeight -le 0) {
        if ($zoomMode -eq "Fit") {
            $script:panOffsetX = 0.0
            $script:panOffsetY = 0.0
        }
        return
    }

    $vw = [double]$picture.ClientSize.Width
    $vh = [double]$picture.ClientSize.Height
    $scale = [double]$zoomFactor
    if ($vw -le 0.0 -or $vh -le 0.0 -or $scale -le 0.0) { return }

    $displayWidth = [double]$videoWidth * $scale
    $displayHeight = [double]$videoHeight * $scale
    $maxPanX = [Math]::Max([Math]::Abs($displayWidth - $vw) / 2.0, [Math]::Abs($minimumMaxX))
    $maxPanY = [Math]::Max([Math]::Abs($displayHeight - $vh) / 2.0, [Math]::Abs($minimumMaxY))

    $script:panOffsetX = [Math]::Max(-$maxPanX, [Math]::Min($maxPanX, [double]$panOffsetX))
    $script:panOffsetY = [Math]::Max(-$maxPanY, [Math]::Min($maxPanY, [double]$panOffsetY))
}

function Reset-ZoomPanGesture {
    $script:zoomPanCandidate = $false
    $script:zoomPanning = $false
    $script:middlePanActive = $false
    $script:rightPanActive = $false
    $script:zoomPanStartPoint = New-Object System.Drawing.PointF(0,0)
    $script:zoomPanStartOffsetX = 0.0
    $script:zoomPanStartOffsetY = 0.0
    if ($picture -and -not $picture.IsDisposed -and $picture.Capture) {
        $picture.Capture = $false
    }
}

function Test-CursorOverPreview {
    if (-not $picture -or $picture.IsDisposed -or -not $picture.Visible) { return $false }
    try {
        $clientPoint = $picture.PointToClient([System.Windows.Forms.Cursor]::Position)
        return $picture.ClientRectangle.Contains($clientPoint)
    }
    catch {
        return $false
    }
}

function Stop-SpacePanMode {
    if (-not $script:spacePanActive) { return }
    $script:spacePanActive = $false
    Reset-ZoomPanGesture
    Update-PreviewCursor
}

function Stop-MiddlePanMode {
    if (-not $script:middlePanActive) { return }

    $wasPanning = [bool]$script:zoomPanning
    $startOffsetX = [double]$script:zoomPanStartOffsetX
    $startOffsetY = [double]$script:zoomPanStartOffsetY
    Reset-ZoomPanGesture

    if ($wasPanning) {
        Clamp-ViewportPan ([Math]::Abs($startOffsetX)) ([Math]::Abs($startOffsetY))
        $picture.Refresh()
    }

    # Eyedropper owns the normal crosshair while armed. Restore it explicitly
    # because Update-PreviewCursor intentionally does not override eyedropper.
    if ($eyedropperActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Cross
    }
    else {
        Update-PreviewCursor
    }
}

function Stop-RightPanMode {
    if (-not $script:rightPanActive) { return $false }

    $wasPanning = [bool]$script:zoomPanning
    $startOffsetX = [double]$script:zoomPanStartOffsetX
    $startOffsetY = [double]$script:zoomPanStartOffsetY
    Reset-ZoomPanGesture

    if ($wasPanning) {
        Clamp-ViewportPan ([Math]::Abs($startOffsetX)) ([Math]::Abs($startOffsetY))
        $picture.Refresh()
    }

    if ($eyedropperActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Cross
    }
    else {
        Update-PreviewCursor
    }

    return $wasPanning
}

function Set-ZoomFit {
    if (-not $previewImage) { return }
    Reset-ZoomPanGesture
    $script:zoomMode = "Fit"
    $script:zoomFactor = 1.0
    $script:panOffsetX = 0.0
    $script:panOffsetY = 0.0
    Update-ZoomHud
    $picture.Refresh()
}

function Set-ZoomAroundViewPoint([double]$targetScale, [System.Drawing.PointF]$viewPoint) {
    if (-not $previewImage -or $videoWidth -le 0 -or $videoHeight -le 0) { return }

    $before = Get-ViewportTransform
    if (-not $before) { return }

    # Capture the canonical media point under the requested screen point BEFORE
    # changing scale. The new pan offset is then solved so this same media point
    # lands back on the exact same screen point after zooming.
    $mediaX = ([double]$viewPoint.X - [double]$before.OriginX) / [double]$before.ScaleX
    $mediaY = ([double]$viewPoint.Y - [double]$before.OriginY) / [double]$before.ScaleY

    $targetScale = [Math]::Max([double]$minZoomFactor, [Math]::Min([double]$maxZoomFactor, $targetScale))
    if ([double]::IsNaN($targetScale) -or [double]::IsInfinity($targetScale) -or $targetScale -le 0.0) { return }

    $vw = [double]$picture.ClientSize.Width
    $vh = [double]$picture.ClientSize.Height
    if ($vw -le 0.0 -or $vh -le 0.0) { return }

    $baseOriginX = ($vw - ([double]$videoWidth * $targetScale)) / 2.0
    $baseOriginY = ($vh - ([double]$videoHeight * $targetScale)) / 2.0

    $script:zoomMode = "Manual"
    $script:zoomFactor = $targetScale
    $script:panOffsetX = [double]$viewPoint.X - $baseOriginX - ($mediaX * $targetScale)
    $script:panOffsetY = [double]$viewPoint.Y - $baseOriginY - ($mediaY * $targetScale)

    Update-ZoomHud
    $picture.Refresh()
}

function Step-ZoomAtViewPoint([int]$direction, [System.Drawing.PointF]$viewPoint) {
    if (-not $previewImage -or $direction -eq 0) { return }
    $currentScale = if ($zoomMode -eq "Fit") { Get-FitZoomFactor } else { [double]$zoomFactor }
    if ($currentScale -le 0.0) { $currentScale = 1.0 }
    if ($direction -gt 0 -and $currentScale -ge [double]$maxZoomFactor) { return }
    if ($direction -lt 0 -and $currentScale -le [double]$minZoomFactor) { return }

    $factor = [double]$zoomStepFactor
    $target = if ($direction -gt 0) { $currentScale * $factor } else { $currentScale / $factor }
    Set-ZoomAroundViewPoint $target $viewPoint
}

function Get-ViewportCenterPoint {
    return New-Object System.Drawing.PointF(
        [single]([double]$picture.ClientSize.Width / 2.0),
        [single]([double]$picture.ClientSize.Height / 2.0))
}

function Initialize-ZoomCursor {
    if ($script:zoomCursor) { return }
    try {
        # White outer glyph + slightly smaller black glyph gives the cursor a
        # two-tone edge that remains legible over both bright and dark media.
        $bmp = New-Object System.Drawing.Bitmap(32,32,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $outer = Get-ThemedIconImage "zoom" ([System.Drawing.Color]::White)
        $inner = Get-ThemedIconImage "zoom" ([System.Drawing.Color]::Black)
        $g.DrawImage($outer, (New-Object System.Drawing.Rectangle(0,0,32,32)))
        $g.DrawImage($inner, (New-Object System.Drawing.Rectangle(1,1,30,30)))
        $hIcon = $bmp.GetHicon()
        try {
            $hCursor = [ZoomCursorNativeV1]::CreateCursorFromIcon($hIcon, 11, 11)
            if ($hCursor -ne [IntPtr]::Zero) {
                $script:zoomCursorHandle = $hCursor
                $script:zoomCursor = [System.Windows.Forms.Cursor]::new($hCursor)
            }
        }
        finally {
            [ZoomCursorNativeV1]::DestroyIconHandle($hIcon)
        }
        $g.Dispose()
        $bmp.Dispose()
    }
    catch {
        $script:zoomCursor = $null
        $script:zoomCursorHandle = [IntPtr]::Zero
    }
}

function Update-PreviewCursor {
    if (-not $picture) { return }
    if ($script:middlePanActive -or $script:rightPanActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        return
    }
    if ($eyedropperActive) { return }
    if ($script:spacePanActive) {
        # Space is a temporary viewport override only; the underlying drawing
        # tool remains selected and resumes the instant Space is released.
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
    }
    elseif ($script:zoomToolActive) {
        if ($script:zoomPanCandidate -or $script:zoomPanning) {
            # WinForms has no standard closed-grab cursor; Hand is the closest
            # familiar visual language while a pan gesture is in progress.
            $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        }
        else {
            Initialize-ZoomCursor
            $picture.Cursor = if ($script:zoomCursor) { $script:zoomCursor } else { [System.Windows.Forms.Cursors]::Cross }
        }
    }
    else {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

# Attach only AFTER the Slice 4 helper functions exist. The PictureBox can resize
# several times while the form is still being built; wiring this earlier would
# let construction-time Resize events call helpers PowerShell has not defined yet.
# Refresh() deliberately preserves the Slice 3 r2 full-repaint fix.
$picture.Add_Resize({
    Position-ZoomHud
    Update-ZoomHud
    if ($picture -and -not $picture.IsDisposed) { $picture.Refresh() }
})
Position-ZoomHud
Update-ZoomHud

# Compatibility wrapper for older call sites. The displayed media rectangle
# now comes from the same viewport transform that draws the preview itself.
function Get-DisplayedImageRect {
    if (-not $previewImage) { return $null }
    $viewRect = Get-MediaViewRect
    if (-not $viewRect) { return $null }

    return New-Object System.Drawing.Rectangle([int]$viewRect.X,[int]$viewRect.Y,[int]$viewRect.Width,[int]$viewRect.Height)
}
 
function Clamp-PointToImage([System.Drawing.Point]$pt) {
    $r = Get-DisplayedImageRect
    if (-not $r) { return $pt }
 
    $x = [Math]::Max($r.Left, [Math]::Min($pt.X, $r.Right - 1))
    $y = [Math]::Max($r.Top, [Math]::Min($pt.Y, $r.Bottom - 1))
    return New-Object System.Drawing.Point($x,$y)
}
 
# Draft Rectangle/Oval geometry is already canonical MEDIA space.
# Commit-time normalization is the only conversion left here.
function Selection-To-VideoRect {
    if (-not $selection -or $selection.Width -lt 0.01 -or $selection.Height -lt 0.01) { return $null }
    return Normalize-VideoRect ([double]$selection.X) ([double]$selection.Y) ([double]$selection.Width) ([double]$selection.Height)
}
 
# Legacy-named view helpers now delegate to the v2 viewport transform. Keeping
# these wrappers avoids disturbing the proven committed-redaction model while
# making preview, committed overlays and draft overlays share one projection.
# System.Drawing.Graphics.DrawRectangle has Rectangle/int and float-coordinate
# overloads, but no RectangleF overload. Manual zoom intentionally projects
# media rectangles to RectangleF so sub-pixel viewport positions are preserved.
# Route rectangle outlines through this helper so Fit mode keeps the original
# Rectangle overload while manual zoom uses the float-coordinate overload.
function Draw-ViewportRectangleOutline($gfx, $pen, $rect) {
    if ($null -eq $rect) { return }

    if ($rect -is [System.Drawing.RectangleF]) {
        $gfx.DrawRectangle($pen,
            [single]$rect.X,
            [single]$rect.Y,
            [single]$rect.Width,
            [single]$rect.Height)
    }
    else {
        $gfx.DrawRectangle($pen, $rect)
    }
}

function VideoRect-To-Display($vx, $vy, $vw, $vh) {
    if ($zoomMode -ne "Fit") {
        $transform = Get-ViewportTransform
        if (-not $transform) { return $null }
        return New-Object System.Drawing.RectangleF(
            [single]([double]$transform.OriginX + ([double]$vx * [double]$transform.ScaleX)),
            [single]([double]$transform.OriginY + ([double]$vy * [double]$transform.ScaleY)),
            [single]([double]$vw * [double]$transform.ScaleX),
            [single]([double]$vh * [double]$transform.ScaleY))
    }

    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect -or $videoWidth -le 0 -or $videoHeight -le 0) { return $null }
 
    # Preserve r18's exact arithmetic order in Fit mode.
    $x = [int]($imgRect.X + ($vx * $imgRect.Width / $videoWidth))
    $y = [int]($imgRect.Y + ($vy * $imgRect.Height / $videoHeight))
    $w = [int]($vw * $imgRect.Width / $videoWidth)
    $h = [int]($vh * $imgRect.Height / $videoHeight)
 
    return New-Object System.Drawing.Rectangle($x,$y,$w,$h)
}
 
function VideoPoints-To-DisplayPoints($pts) {
    if ($zoomMode -ne "Fit") {
        $transform = Get-ViewportTransform
        if (-not $transform) { return $null }
        $outF = New-Object System.Collections.Generic.List[System.Drawing.PointF]
        foreach ($p in $pts) {
            $dx = [single]([double]$transform.OriginX + ([double]$p.X * [double]$transform.ScaleX))
            $dy = [single]([double]$transform.OriginY + ([double]$p.Y * [double]$transform.ScaleY))
            $outF.Add((New-Object System.Drawing.PointF($dx,$dy)))
        }
        return $outF.ToArray()
    }

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
    if ($zoomMode -ne "Fit") {
        $mp = ViewPoint-To-MediaPoint (New-Object System.Drawing.PointF([single]$pt.X,[single]$pt.Y)) $true
        if (-not $mp) { return $null }
        return @{ X = [int][Math]::Round($mp.X); Y = [int][Math]::Round($mp.Y) }
    }

    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect) { return $null }
 
    $vx = ($pt.X - $imgRect.X) * $videoWidth / $imgRect.Width
    $vy = ($pt.Y - $imgRect.Y) * $videoHeight / $imgRect.Height
    $vx = [Math]::Max(0, [Math]::Min($vx, $videoWidth - 1))
    $vy = [Math]::Max(0, [Math]::Min($vy, $videoHeight - 1))
    return @{ X = [int][Math]::Round($vx); Y = [int][Math]::Round($vy) }
}
 
# Converts a completed freeform draft that is ALREADY in canonical MEDIA space
# into the existing committed Polygon descriptor. Vertices are rounded/clamped
# only at this boundary so resizing the viewport can never alter draft geometry.
function Polygon-To-VideoShape($mediaPoints) {
    if ($mediaPoints.Count -lt 3) { return $null }

    $vpts = @()
    foreach ($p in $mediaPoints) {
        $cx = [Math]::Max(0.0, [Math]::Min([double]$p.X, [double]$videoWidth - 1.0))
        $cy = [Math]::Max(0.0, [Math]::Min([double]$p.Y, [double]$videoHeight - 1.0))
        $vpts += ,@{ X = [int][Math]::Round($cx); Y = [int][Math]::Round($cy) }
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
            Draw-ViewportRectangleOutline $gfx $pen $dr
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

# v2.2.0 B1 quarter-turn state helpers. Source orientation and user rotation are
# deliberately separate: sourceDisplayWidth/Height already include trusted
# FFmpeg autorotation; UserRotation is the additional user-selected turn.
function Set-WorkingDimensionsForUserRotation {
    if ($sourceDisplayWidth -le 0 -or $sourceDisplayHeight -le 0) {
        $script:videoWidth = 0
        $script:videoHeight = 0
        return
    }

    if (($userRotation % 180) -ne 0) {
        $script:videoWidth = [int]$sourceDisplayHeight
        $script:videoHeight = [int]$sourceDisplayWidth
    }
    else {
        $script:videoWidth = [int]$sourceDisplayWidth
        $script:videoHeight = [int]$sourceDisplayHeight
    }
}

# Rotation is a pre-redaction media setup operation. Any state that would need
# geometry transformation locks the controls rather than attempting to rotate
# existing rectangles, ovals, freeform vertices or timeline ranges.
function Test-HasRotationLockoutState {
    if ($redactions -and $redactions.Count -gt 0) { return $true }
    if ($pendingRedaction) { return $true }
    if ($dragging -or $movingShape -or $script:resizingShape -or $script:editingPolygonVertex) { return $true }
    if ($selection -and ($selection.Width -gt 0.0 -or $selection.Height -gt 0.0)) { return $true }
    if ($polygonActive -or ($polygonPoints -and $polygonPoints.Count -gt 0)) { return $true }
    return $false
}

function Update-RotationButtons {
    if (-not $btnRotateCCW -or -not $btnRotateCW) { return }
    $canRotate = [bool]($videoPath -and -not (Test-HasRotationLockoutState))
    $btnRotateCCW.Enabled = $canRotate
    $btnRotateCW.Enabled = $canRotate
    Update-TransportButtonVisuals
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

    # B1 intentionally proves preview/state/canonical geometry only. The frozen
    # approved FFmpeg lacks a quarter-turn filter, so non-zero UserRotation must
    # never reach the unchanged exporter: fail closed until the dedicated export
    # slice extends and re-approves the media-tool build.
    $btnExport.Enabled = ($hasVideo -and $redactions.Count -gt 0)
    # A disabled WinForms control does not reliably receive hover events, so
    # do not pretend the rotation lock can be explained by a normal ToolTip.
    # The lock itself is deliberate and temporary for B1; the click handler
    # remains a defence-in-depth guard if the control state is ever bypassed.
    $script:appToolTip.SetToolTip($btnExport, "")
    $btnEyedropper.Enabled = $hasVideo
    Update-StrengthSliderVisibility
    Update-RotationButtons
}
 
function Refresh-RedactionList {
    $lvRedactions.Items.Clear()
    for ($i = 0; $i -lt $redactions.Count; $i++) {
        $r = $redactions[$i]
        $item = New-Object System.Windows.Forms.ListViewItem(($i+1).ToString())
        [void]$item.SubItems.Add($r.Shape)
        $modeText = if (Get-RedactionEnhanced $r) { "$($r.Mode) A" } else { $r.Mode }
        [void]$item.SubItems.Add($modeText)
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
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        Update-TransportButtonVisuals
    }
}
 
# Clears whatever is currently being drawn (an in-progress drag, or an
# in-progress/just-closed freeform click-path) without touching any already
# committed or pending redaction. Called whenever the tool changes, a
# redaction is started/ended/cancelled, or a new file is loaded.
function Reset-DrawingState {
    $script:dragging = $false
    $script:dragStart = New-Object System.Drawing.PointF(0,0)
    $script:selection = New-Object System.Drawing.RectangleF(0,0,0,0)
    $script:polygonActive = $false
    $script:polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    $script:polygonMousePos = $null
    $script:movingShape = $false
    $script:moveStart = New-Object System.Drawing.PointF(0,0)
    $script:moveOrigSelection = $null
    $script:moveOrigPolygonPoints = $null
    $script:resizingShape = $false
    $script:resizeHandle = "None"
    $script:resizeShapeKind = "None"
    $script:resizeOrigSelection = $null
    $script:resizeDraftDrawStartView = $null
    $script:resizeDraftDrawMoved = $false
    $script:editingPolygonVertex = $false
    $script:polygonVertexIndex = -1
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
        $previewImage.Dispose()
        $script:previewImage = $null
    }
 
    $ms = New-Object System.IO.MemoryStream(,$result.Bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    $rotatedPreview = New-Object System.Drawing.Bitmap($img)
    $img.Dispose()
    $ms.Dispose()

    # Existing source -autorotate has already happened inside FFmpeg. Apply only
    # the additional per-session quarter-turn here, in memory, so frame identity
    # and the trusted PTS extraction path remain completely unchanged.
    switch ([int]$userRotation) {
        90  { $rotatedPreview.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        180 { $rotatedPreview.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        270 { $rotatedPreview.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }

    if ($rotatedPreview.Width -ne $videoWidth -or $rotatedPreview.Height -ne $videoHeight) {
        $rotatedPreview.Dispose()
        $status.Text = "Preview orientation mismatch."
        [System.Windows.Forms.MessageBox]::Show(
            "The rotated preview dimensions did not match the canonical working dimensions. No redaction geometry was changed.",
            "Rotation preview error",
            "OK",
            "Error"
        ) | Out-Null
        return
    }
    $script:previewImage = $rotatedPreview
 
    # Slice 3 keeps the bitmap out of PictureBox.Image. The PictureBox is now
    # only the viewport/canvas; its Paint handler draws $previewImage through
    # Get-ViewportTransform before drawing overlays. Slice 4 keeps the current
    # viewport state across frame changes and refreshes only the visible HUD.
    Update-ZoomHud
    Update-PreviewCursor
    $picture.Refresh()
    $script:loadedFrame = $currentFrame
    $picture.Invalidate()
 
    $status.Text = if ($userRotation -eq 0) { "Preview loaded." } else { "$videoWidth x $videoHeight   |   User rotation: $userRotation°" }
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
    # B1 reset boundary: every newly accepted media source starts with no
    # additional user rotation. The existing preflight dimensions already
    # represent source autorotation and are kept separately from UserRotation.
    $script:sourceDisplayWidth = [int]$info.Width
    $script:sourceDisplayHeight = [int]$info.Height
    $script:userRotation = 0
    Set-WorkingDimensionsForUserRotation
    $script:redactionEnhanced = $false
    $chkEnhanced.Checked = $false
    Update-StrengthSliderVisibility
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

        $btnPrevFrame.Enabled = $false
        $btnNextFrame.Enabled = $false
        $btnPlayPause.Enabled = $false
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        Update-TransportButtonVisuals
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

        $btnPrevFrame.Enabled = $true
        $btnNextFrame.Enabled = $true
        $btnPlayPause.Enabled = $true
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        Update-TransportButtonVisuals
        $lblPosValue.Text = SecToText $previewSeconds
        $lblFrameCount.Text = "Frame 1 / $totalFrames"
        $timingStatus = if ($info.IsVfr) { "VFR timing verified" } else { "CFR timing verified" }
        $status.Text = "$videoWidth x $videoHeight   |   Duration: $(SecToText $videoDuration)   |   $([Math]::Round($fps,3)) avg fps   |   $timingStatus"
    }

    # A successfully accepted new source is the zoom reset boundary. Slice 1
    # keeps the existing PictureBox rendering path unchanged, but establishes
    # the v2 viewport state ready for later zoom interaction slices.
    Reset-ViewportState

    Apply-ModeLabels
    Reset-RedactionState
    Update-RedactionButtons
    Update-TransportButtonVisuals
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
        $script:appToolTip.SetToolTip($btnPlayPause, "Pause")
        Update-TransportButtonVisuals
        $playTimer.Start()
    }
})

function Invoke-UserQuarterTurn([int]$deltaDegrees) {
    if (-not $videoPath) { return }
    if ($deltaDegrees -ne 90 -and $deltaDegrees -ne -90) { return }

    # The buttons should already be disabled in this state, but re-check in the
    # handler as a stale-UI safety belt. Never discard or transform redactions.
    if (Test-HasRotationLockoutState) {
        Update-RotationButtons
        [System.Windows.Forms.MessageBox]::Show(
            "Rotation can only be changed before redactions are added. Clear/reset the current redaction work first.",
            "Rotation locked",
            "OK",
            "Information"
        ) | Out-Null
        return
    }

    Stop-Playback

    $nextRotation = (([int]$userRotation + $deltaDegrees) % 360 + 360) % 360

    # Rotate the already decoded in-memory preview by exactly the requested
    # quarter turn for immediate UI response. Subsequent frame loads apply the
    # complete UserRotation afresh to newly decoded source-autorotated pixels.
    if ($previewImage) {
        if ($deltaDegrees -eq 90) {
            $previewImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
        }
        else {
            $previewImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
        }
    }

    $script:userRotation = [int]$nextRotation
    Set-WorkingDimensionsForUserRotation

    if ($previewImage -and ($previewImage.Width -ne $videoWidth -or $previewImage.Height -ne $videoHeight)) {
        # This should be impossible for a quarter-turn. Fail closed by throwing
        # away the cache and re-decoding the current logical frame.
        $previewImage.Dispose()
        $script:previewImage = $null
        $script:loadedFrame = -1
    }

    Reset-ViewportState
    Update-ZoomHud
    Update-RotationButtons
    $picture.Invalidate()

    $status.Text = "$videoWidth x $videoHeight   |   User rotation: $userRotation°"
    if (-not $previewImage) { Load-PreviewFrame }
}

$btnRotateCCW.Add_Click({ Invoke-UserQuarterTurn -90 })
$btnPrevFrame.Add_Click({ Stop-Playback; Step-Frame -1 })
$btnNextFrame.Add_Click({ Stop-Playback; Step-Frame 1 })
$btnRotateCW.Add_Click({ Invoke-UserQuarterTurn 90 })
 
$form.Add_KeyDown({
    param($sender,$e)
    if (-not $videoPath) { return }

    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Space) {
        # Once the temporary override is active, swallow keyboard auto-repeat
        # even if the drag has moved the pointer outside the preview. Otherwise
        # a repeated Space could accidentally activate whichever button still
        # owns keyboard focus while the user is panning.
        if ($script:spacePanActive) {
            $e.Handled = $true
            $e.SuppressKeyPress = $true
            return
        }

        # Optional power-user pan: only borrow Space when a drawing tool is
        # active and the pointer is actually over the preview. Do not steal an
        # already-running Rectangle/Oval drag or shape-move gesture. Suppressing
        # the key press also prevents Space from accidentally activating a
        # focused toolbar/button control while it is serving as the pan modifier.
        if (-not $script:zoomToolActive -and -not $eyedropperActive -and $previewImage -and
            -not $dragging -and -not $movingShape -and (Test-CursorOverPreview)) {
            Reset-ZoomPanGesture
            $script:spacePanActive = $true
            Update-PreviewCursor
            $e.Handled = $true
            $e.SuppressKeyPress = $true
            return
        }
    }

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

$form.Add_KeyUp({
    param($sender,$e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Space -and $script:spacePanActive) {
        Stop-SpacePanMode
        $e.Handled = $true
        $e.SuppressKeyPress = $true
    }
})

# If the application loses focus while Space is down, Windows may never deliver
# the matching KeyUp to this form. Clear the temporary override so the preview
# cannot get stuck in hand/pan mode when the user Alt-Tabs away and returns.
$form.Add_Deactivate({
    Stop-SpacePanMode
    Stop-MiddlePanMode
    [void](Stop-RightPanMode)
})
 
function Set-ToolMode([string]$mode) {
    if ($script:toolMode -eq $mode) { return }
    $script:toolMode = $mode
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
}
$rbRectangle.Add_CheckedChanged({
    if ($rbRectangle.Checked) {
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Rectangle"
        Update-PreviewCursor
    }
})
$rbOval.Add_CheckedChanged({
    if ($rbOval.Checked) {
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Oval"
        Update-PreviewCursor
    }
})
$rbFreeform.Add_CheckedChanged({
    if ($rbFreeform.Checked) {
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Polygon"
        Update-PreviewCursor
    }
})
$rbZoom.Add_CheckedChanged({
    if ($rbZoom.Checked) {
        # Zoom is a VIEW tool, not a new redaction shape. Preserve the last
        # drawing tool and any draft geometry while Zoom is temporarily active.
        $script:zoomToolActive = $true
        Update-PreviewCursor
    }
    elseif ($script:zoomToolActive) {
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Update-PreviewCursor
    }
})

$btnZoomFit.Add_Click({ Set-ZoomFit })
$btnZoomIn.Add_Click({ Step-ZoomAtViewPoint 1 (Get-ViewportCenterPoint) })
$btnZoomOut.Add_Click({ Step-ZoomAtViewPoint -1 (Get-ViewportCenterPoint) })

$picture.Add_MouseEnter({
    # v2.1: wheel zoom is always available while the pointer is over the loaded
    # preview, regardless of which drawing/view tool is selected. MouseWheel is
    # delivered to the focused WinForms control, so focus the preview on entry.
    # Form.KeyPreview keeps the existing keyboard shortcuts available.
    if ($previewImage) {
        [void]$picture.Focus()
    }

    if ($script:zoomToolActive -or $script:spacePanActive -or $script:middlePanActive -or $script:rightPanActive) {
        Update-PreviewCursor
    }
})
 
$picture.Add_MouseDown({
    param($sender,$e)
    if (-not $previewImage) { return }

    # v2.1 always-on middle-button pan takes priority over drawing/edit gestures
    # without changing the selected tool. The pointer only needs to be over the
    # displayed media when the gesture begins; capture then allows the drag to
    # continue naturally beyond the original hit area.
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Middle) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $mediaRect = Get-MediaViewRect
        if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

        Reset-ZoomPanGesture
        $script:middlePanActive = $true
        $script:zoomPanCandidate = $true
        $script:zoomPanning = $false
        $script:zoomPanStartPoint = $viewPt
        $script:zoomPanStartOffsetX = [double]$panOffsetX
        $script:zoomPanStartOffsetY = [double]$panOffsetY
        $picture.Capture = $true
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        return
    }

    # B1-r3: right-button DRAG pans from any tool, making panning practical on
    # laptops/trackpads that have no clickable middle button. A plain right-click
    # is deliberately deferred to MouseUp so existing click semantics survive:
    # Zoom tool -> zoom out; Freeform -> cancel the in-progress path.
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right -and
        -not $dragging -and -not $movingShape -and -not $script:resizingShape -and
        -not $script:editingPolygonVertex) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $mediaRect = Get-MediaViewRect
        if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

        Reset-ZoomPanGesture
        $script:rightPanActive = $true
        $script:zoomPanCandidate = $true
        $script:zoomPanning = $false
        $script:zoomPanStartPoint = $viewPt
        $script:zoomPanStartOffsetX = [double]$panOffsetX
        $script:zoomPanStartOffsetY = [double]$panOffsetY
        $picture.Capture = $true
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        return
    }

    # Eyedropper takes priority over normal left/right drawing input while armed. In Slice 3
    # it uses the same inverse viewport transform as draft geometry.
    if ($eyedropperActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $imgRect = Get-MediaViewRect
            $viewPtF = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
            $pt = New-Object System.Drawing.Point($e.X,$e.Y)
            if ($imgRect -and $imgRect.Contains($viewPtF) -and $previewImage) {
                $vp = DisplayPoint-To-VideoPoint $pt
                if ($vp) {
                    $sampled = $previewImage.GetPixel($vp.X, $vp.Y)
                    Set-ActiveRedactionColor $sampled
                }
            }
        }
        $script:eyedropperActive = $false
        Update-PreviewCursor
        Set-RedactionButtonColor $btnEyedropper "grey"
        return
    }

    if ($script:zoomToolActive -or $script:spacePanActive) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $mediaRect = Get-MediaViewRect
        if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            # Do NOT zoom on MouseDown. A left press may become a pan gesture;
            # MouseUp performs click-to-zoom only for the real Zoom tool. When
            # Space is the temporary override, a no-drag click is intentionally
            # a no-op so the underlying drawing tool is never invoked by accident.
            $script:zoomPanCandidate = $true
            $script:zoomPanning = $false
            $script:zoomPanStartPoint = $viewPt
            $script:zoomPanStartOffsetX = [double]$panOffsetX
            $script:zoomPanStartOffsetY = [double]$panOffsetY
            $picture.Capture = $true
            Update-PreviewCursor
        }
        return
    }

    if ($pendingRedaction) { return }

    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }

    Stop-Playback

    # From this point on, mouse input is converted to canonical MEDIA space
    # immediately. No draft shape stores PictureBox/view coordinates anymore.
    $viewRect = Get-MediaViewRect
    if (-not $viewRect) { return }

    $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)

    # Resize Slice 1/2: handle hit-testing deliberately happens before the
    # normal media-rectangle containment check. Handles centred on a media edge
    # are partly outside the image by design and must remain easy to grab.
    $resizeHandleCandidate = [bool](
        ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval"))
    if ($resizeHandleCandidate -and
        $selection.Width -gt 0.01 -and $selection.Height -gt 0.01 -and -not $dragging) {
        $hitHandle = if ($toolMode -eq "Oval") {
            Get-OvalResizeHandleAtViewPoint $viewPt $selection
        } else {
            Get-RectangleResizeHandleAtViewPoint $viewPt $selection
        }
        if ($hitHandle -ne "None") {
            $script:resizingShape = $true
            $script:resizeHandle = $hitHandle
            $script:resizeShapeKind = [string]$toolMode
            $script:resizeOrigSelection = New-Object System.Drawing.RectangleF(
                [single]$selection.X,[single]$selection.Y,[single]$selection.Width,[single]$selection.Height)
            $picture.Capture = $true
            $picture.Cursor = if ($toolMode -eq "Oval") {
                Get-OvalResizeCursor $hitHandle
            } else {
                Get-RectangleResizeCursor $hitHandle
            }
            $picture.Invalidate()
            return
        }
    }

    # Resize Slice 3: closed Freeform vertex handles take precedence over the
    # polygon interior move gesture. Hit-testing is VIEW-space so the handle
    # remains a comfortable fixed screen size at every zoom level.
    if ($script:resizeSlice3Enabled -and $toolMode -eq "Polygon" -and
        -not $polygonActive -and $polygonPoints.Count -ge 3) {
        $vertexIndex = Get-FreeformVertexHandleAtViewPoint $viewPt $polygonPoints
        if ($vertexIndex -ge 0) {
            $script:editingPolygonVertex = $true
            $script:polygonVertexIndex = [int]$vertexIndex
            $picture.Capture = $true
            $picture.Cursor = Get-FreeformVertexCursor
            $picture.Invalidate()
            return
        }
    }

    # Resize Slice 3 r2: a first click outside a closed Freeform is a
    # dismissal-only gesture. This also applies to preview letterbox space.
    # Vertex handles were already given priority above, so an edge handle that
    # straddles the media boundary is still editable rather than dismissed.
    if ($script:resizeSlice3Enabled -and $toolMode -eq "Polygon" -and
        -not $polygonActive -and $polygonPoints.Count -ge 3 -and
        -not $viewRect.Contains($viewPt)) {
        Clear-ClosedFreeformDraftForOutsideClick
        return
    }

    if (-not $viewRect.Contains($viewPt)) { return }

    $mediaPt = ViewPoint-To-MediaPoint $viewPt $true
    if (-not $mediaPt) { return }

    if ($toolMode -eq "Polygon") {
        if (-not $polygonActive -and $polygonPoints.Count -ge 3) {
            if (Test-PointInPolygon $mediaPt $polygonPoints) {
                # Clicked inside the closed-but-uncommitted path: move the whole
                # canonical media-space shape instead of starting a new one.
                $script:movingShape = $true
                $picture.Capture = $true
                $script:moveStart = $mediaPt
                $script:moveOrigPolygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
                foreach ($pt in $polygonPoints) {
                    [void]$script:moveOrigPolygonPoints.Add((New-Object System.Drawing.PointF([single]$pt.X,[single]$pt.Y)))
                }
                $picture.Invalidate()
                return
            }

            if ($script:resizeSlice3Enabled) {
                # r2 behavior: the first outside click clears the closed draft
                # and is consumed. Do NOT reuse this same click as point #1 of
                # the next polygon; a second click starts the next Freeform.
                Clear-ClosedFreeformDraftForOutsideClick
                return
            }
        }
        if (-not $polygonActive) {
            $script:polygonActive = $true
            $script:polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
            $script:polygonPoints.Add($mediaPt)
            $script:polygonMousePos = $mediaPt
            Update-SelectionFields $null "Selection: freeform started (1 point). Click to add points; click the yellow start point to close (need at least 3)."
        }
        else {
            # Shift snapping also happens in MEDIA space. Because the viewport
            # scale is uniform, media-space 45-degree snapping is visually 45
            # degrees on screen too.
            $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
            $lastPolyPt = $polygonPoints[$polygonPoints.Count - 1]
            $mediaPt = Clamp-MediaPoint (Get-AngleSnappedPoint $lastPolyPt $mediaPt $constrainAngle)

            # Closing remains a screen-pixel interaction: the yellow start
            # marker is 8 px across, so preserve the familiar 10 px close
            # tolerance even though the stored vertices are media-space.
            $candidateView = MediaPoint-To-ViewPoint $mediaPt
            $startView = MediaPoint-To-ViewPoint $polygonPoints[0]
            $distToStart = [double]::PositiveInfinity
            if ($candidateView -and $startView) {
                $dxs = [double]$candidateView.X - [double]$startView.X
                $dys = [double]$candidateView.Y - [double]$startView.Y
                $distToStart = [Math]::Sqrt(($dxs * $dxs) + ($dys * $dys))
            }

            if ($polygonPoints.Count -ge 3 -and $distToStart -le 10.0) {
                $script:polygonActive = $false
                Update-SelectionFields $null "Selection: freeform closed ($($polygonPoints.Count) points)."
            }
            else {
                $script:polygonPoints.Add($mediaPt)
                Update-SelectionFields $null "Selection: freeform, $($polygonPoints.Count) points (click the yellow start point to close)."
            }
        }
        Update-RedactionButtons
        $picture.Invalidate()
        return
    }

    if ($selection.Width -gt 0.01 -and $selection.Height -gt 0.01 -and $selection.Contains($mediaPt)) {
        # Clicked inside the existing uncommitted Rectangle/Oval selection:
        # move the canonical media-space shape instead of creating another.
        # Oval deliberately keeps the existing bounding-box hit behaviour.
        $script:movingShape = $true
        $picture.Capture = $true
        $script:moveStart = $mediaPt
        $script:moveOrigSelection = New-Object System.Drawing.RectangleF(
            [single]$selection.X,[single]$selection.Y,[single]$selection.Width,[single]$selection.Height)
        $picture.Invalidate()
        return
    }

    # Rectangle / Oval: the very first point is canonical MEDIA space. The
    # resize branch also tracks a small screen-pixel threshold so click-only
    # gestures cannot leave coincident handles behind.
    if (($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval")) {
        $script:resizeDraftDrawStartView = $viewPt
        $script:resizeDraftDrawMoved = $false
    }
    $script:dragging = $true
    $picture.Capture = $true
    $script:dragStart = $mediaPt
    $script:selection = New-Object System.Drawing.RectangleF(
        [single]$dragStart.X,[single]$dragStart.Y,[single]0.01,[single]0.01)
    Update-RotationButtons
    $picture.Invalidate()
})

$picture.Add_MouseMove({
    param($sender,$e)

    if ($script:zoomToolActive -or $script:spacePanActive -or $script:middlePanActive -or $script:rightPanActive) {
        if ($script:zoomPanCandidate) {
            $dxView = [double]$e.X - [double]$script:zoomPanStartPoint.X
            $dyView = [double]$e.Y - [double]$script:zoomPanStartPoint.Y

            if (-not $script:zoomPanning) {
                $distance = [Math]::Sqrt(($dxView * $dxView) + ($dyView * $dyView))
                if ($distance -ge [double]$zoomPanDragThreshold) {
                    $script:zoomPanning = $true
                }
            }

            if ($script:zoomPanning -and $zoomMode -eq "Manual") {
                $script:panOffsetX = [double]$script:zoomPanStartOffsetX + $dxView
                $script:panOffsetY = [double]$script:zoomPanStartOffsetY + $dyView
                Clamp-ViewportPan ([Math]::Abs([double]$script:zoomPanStartOffsetX)) ([Math]::Abs([double]$script:zoomPanStartOffsetY))
                $picture.Refresh()
            }
            Update-PreviewCursor
            return
        }

        Update-PreviewCursor
        return
    }

    if ($script:resizingShape) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if (-not $rawPt -or -not $mediaBounds -or -not $script:resizeOrigSelection) { return }

        $constrainOneToOne = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
        if ($script:resizeShapeKind -eq "Oval") {
            $script:selection = Get-OvalResizeResult $script:resizeOrigSelection $script:resizeHandle $rawPt $constrainOneToOne $mediaBounds
            $picture.Cursor = Get-OvalResizeCursor $script:resizeHandle
        }
        else {
            $script:selection = Get-RectangleResizeResult $script:resizeOrigSelection $script:resizeHandle $rawPt $constrainOneToOne $mediaBounds
            $picture.Cursor = Get-RectangleResizeCursor $script:resizeHandle
        }
        Update-SelectionFields (Selection-To-VideoRect) "Selection resizing."
        $picture.Invalidate()
        return
    }

    if ($script:editingPolygonVertex) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if (-not $rawPt -or -not $mediaBounds -or $script:polygonVertexIndex -lt 0) { return }

        $script:polygonPoints = Get-FreeformVertexEditResult $polygonPoints $script:polygonVertexIndex $rawPt $mediaBounds
        $picture.Cursor = Get-FreeformVertexCursor
        Update-SelectionFields $null "Selection: freeform vertex editing."
        $picture.Invalidate()
        return
    }

    if ($movingShape) {
        $mediaBounds = Get-DraftMediaBounds
        if (-not $mediaBounds) { return }

        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if (-not $rawPt) { return }

        $dx = [double]$rawPt.X - [double]$moveStart.X
        $dy = [double]$rawPt.Y - [double]$moveStart.Y

        if ($toolMode -eq "Polygon") {
            $origBounds = Get-PointsBoundingRect $moveOrigPolygonPoints
            $clampedD = Get-ClampedTranslation $origBounds $dx $dy $mediaBounds
            $newPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
            foreach ($origPt in $moveOrigPolygonPoints) {
                [void]$newPoints.Add((New-Object System.Drawing.PointF(
                    [single]([double]$origPt.X + [double]$clampedD.Dx),
                    [single]([double]$origPt.Y + [double]$clampedD.Dy))))
            }
            $script:polygonPoints = $newPoints
        }
        else {
            $clampedD = Get-ClampedTranslation $moveOrigSelection $dx $dy $mediaBounds
            $script:selection = New-Object System.Drawing.RectangleF(
                [single]([double]$moveOrigSelection.X + [double]$clampedD.Dx),
                [single]([double]$moveOrigSelection.Y + [double]$clampedD.Dy),
                [single]$moveOrigSelection.Width,
                [single]$moveOrigSelection.Height)
        }
        $picture.Invalidate()
        return
    }

    if ($toolMode -eq "Polygon") {
        if ($polygonActive) {
            $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
            $rawPt = ViewPoint-To-MediaPoint $viewPt $true
            if (-not $rawPt) { return }

            if ($polygonPoints.Count -gt 0) {
                $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
                $lastPolyPt = $polygonPoints[$polygonPoints.Count - 1]
                $rawPt = Clamp-MediaPoint (Get-AngleSnappedPoint $lastPolyPt $rawPt $constrainAngle)
            }
            $script:polygonMousePos = $rawPt
            $picture.Invalidate()
        }
        elseif (-not $pendingRedaction -and $polygonPoints.Count -ge 3) {
            # Slice 3 vertex handles take precedence over whole-polygon hover.
            # Because their hit area may straddle the media edge, test them
            # before enforcing media-rectangle containment.
            $viewRect = Get-MediaViewRect
            $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
            if ($script:resizeSlice3Enabled) {
                $hoverVertex = Get-FreeformVertexHandleAtViewPoint $viewPt $polygonPoints
                if ($hoverVertex -ge 0) {
                    $picture.Cursor = Get-FreeformVertexCursor
                    return
                }
            }
            # Idle interior hit-testing remains media-space. Outside the
            # displayed media, keep the normal cursor rather than clamping.
            if ($viewRect -and $viewRect.Contains($viewPt)) {
                $hoverPt = ViewPoint-To-MediaPoint $viewPt $true
                $picture.Cursor = if ($hoverPt -and (Test-PointInPolygon $hoverPt $polygonPoints)) {
                    [System.Windows.Forms.Cursors]::SizeAll
                } else {
                    [System.Windows.Forms.Cursors]::Default
                }
            }
            else {
                $picture.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        }
        return
    }

    if (-not $dragging) {
        if (-not $pendingRedaction -and $selection.Width -gt 0.01 -and $selection.Height -gt 0.01) {
            $viewRect = Get-MediaViewRect
            $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)

            # Resize handles take precedence over whole-shape movement. Their
            # hover zone may extend a few pixels outside the displayed media.
            $resizeHoverCandidate = [bool](
                ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
                ($script:resizeSlice2Enabled -and $toolMode -eq "Oval"))
            if ($resizeHoverCandidate) {
                $hoverHandle = if ($toolMode -eq "Oval") {
                    Get-OvalResizeHandleAtViewPoint $viewPt $selection
                } else {
                    Get-RectangleResizeHandleAtViewPoint $viewPt $selection
                }
                if ($hoverHandle -ne "None") {
                    $picture.Cursor = if ($toolMode -eq "Oval") {
                        Get-OvalResizeCursor $hoverHandle
                    } else {
                        Get-RectangleResizeCursor $hoverHandle
                    }
                    return
                }
            }

            if ($viewRect -and $viewRect.Contains($viewPt)) {
                $hoverPt = ViewPoint-To-MediaPoint $viewPt $true
                $picture.Cursor = if ($hoverPt -and $selection.Contains($hoverPt)) {
                    [System.Windows.Forms.Cursors]::SizeAll
                } else {
                    [System.Windows.Forms.Cursors]::Default
                }
            }
            else {
                $picture.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        }
        return
    }

    $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
    if ((($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
         ($script:resizeSlice2Enabled -and $toolMode -eq "Oval")) -and
        -not $script:resizeDraftDrawMoved -and $script:resizeDraftDrawStartView) {
        if (Test-RectangleDraftDragThreshold $script:resizeDraftDrawStartView $viewPt) {
            $script:resizeDraftDrawMoved = $true
        }
    }
    $p = ViewPoint-To-MediaPoint $viewPt $true
    if (-not $p) { return }

    # Shift constrains Rectangle to a square / Oval to a circle. This now
    # happens in MEDIA pixels, which is also the correct canonical geometry.
    $constrain = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
    $delta = Get-ConstrainedDelta ([double]$p.X - [double]$dragStart.X) ([double]$p.Y - [double]$dragStart.Y) $constrain

    $x = [Math]::Min([double]$dragStart.X, ([double]$dragStart.X + [double]$delta.Dx))
    $y = [Math]::Min([double]$dragStart.Y, ([double]$dragStart.Y + [double]$delta.Dy))
    $w = [Math]::Max(0.01, [Math]::Abs([double]$delta.Dx))
    $h = [Math]::Max(0.01, [Math]::Abs([double]$delta.Dy))

    $script:selection = New-Object System.Drawing.RectangleF(
        [single]$x,[single]$y,[single]$w,[single]$h)
    $picture.Invalidate()
})

$picture.Add_MouseWheel({
    param($sender,$e)

    # v2.1 always-on pointer-centred wheel zoom. Do not change scale in the
    # middle of an active geometry drag/edit or pan gesture; between gestures,
    # wheel zoom remains available with Rectangle/Oval/Freeform/Zoom selected.
    if (-not $previewImage -or $e.Delta -eq 0 -or $script:zoomPanCandidate -or
        $dragging -or $movingShape -or $script:resizingShape -or $script:editingPolygonVertex) { return }

    $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
    $mediaRect = Get-MediaViewRect
    if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

    Step-ZoomAtViewPoint $(if ($e.Delta -gt 0) { 1 } else { -1 }) $viewPt
})

$picture.Add_MouseUp({
    param($sender,$e)

    if ($script:rightPanActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            $clickPoint = New-Object System.Drawing.PointF(
                [single]$script:zoomPanStartPoint.X,
                [single]$script:zoomPanStartPoint.Y)
            $wasPanning = [bool](Stop-RightPanMode)

            if (-not $wasPanning) {
                if ($eyedropperActive) {
                    # Preserve the old behaviour where a non-left click simply
                    # dismisses an armed eyedropper without sampling a pixel.
                    $script:eyedropperActive = $false
                    Update-PreviewCursor
                    Set-RedactionButtonColor $btnEyedropper "grey"
                }
                elseif ($script:zoomToolActive) {
                    Step-ZoomAtViewPoint -1 $clickPoint
                }
                elseif ($toolMode -eq "Polygon" -and ($polygonActive -or $polygonPoints.Count -gt 0)) {
                    # Preserve the established Freeform right-click cancel.
                    Stop-Playback
                    Reset-DrawingState
                    Update-SelectionFields $null
                    Update-RedactionButtons
                }
            }
        }
        return
    }

    if ($script:middlePanActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Middle) {
            Stop-MiddlePanMode
        }
        return
    }

    if ($script:zoomToolActive -or $script:spacePanActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $script:zoomPanCandidate) {
            $wasPanning = [bool]$script:zoomPanning
            $clickPoint = New-Object System.Drawing.PointF(
                [single]$script:zoomPanStartPoint.X,
                [single]$script:zoomPanStartPoint.Y)

            $script:zoomPanCandidate = $false
            $script:zoomPanning = $false
            $picture.Capture = $false
            Update-PreviewCursor

            if (-not $wasPanning -and $script:zoomToolActive) {
                Step-ZoomAtViewPoint 1 $clickPoint
            }
            elseif ($wasPanning) {
                Clamp-ViewportPan ([Math]::Abs([double]$script:zoomPanStartOffsetX)) ([Math]::Abs([double]$script:zoomPanStartOffsetY))
                $picture.Refresh()
            }
        }
        return
    }

    if ($script:editingPolygonVertex) {
        $script:editingPolygonVertex = $false
        $picture.Capture = $false
        $script:polygonVertexIndex = -1
        Update-SelectionFields $null "Selection: freeform vertex moved."
        Update-RedactionButtons

        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $hoverVertex = Get-FreeformVertexHandleAtViewPoint $viewPt $polygonPoints
        if ($hoverVertex -ge 0) {
            $picture.Cursor = Get-FreeformVertexCursor
        }
        else {
            $viewRect = Get-MediaViewRect
            if ($viewRect -and $viewRect.Contains($viewPt)) {
                $hoverPt = ViewPoint-To-MediaPoint $viewPt $true
                $picture.Cursor = if ($hoverPt -and (Test-PointInPolygon $hoverPt $polygonPoints)) {
                    [System.Windows.Forms.Cursors]::SizeAll
                } else {
                    [System.Windows.Forms.Cursors]::Default
                }
            }
            else {
                $picture.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        }
        $picture.Invalidate()
        return
    }

    if ($script:resizingShape) {
        $resizeKind = [string]$script:resizeShapeKind
        $script:resizingShape = $false
        $picture.Capture = $false
        $script:resizeOrigSelection = $null
        Update-SelectionFields (Selection-To-VideoRect) "Selection resized."
        Update-RedactionButtons

        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $hoverHandle = if ($resizeKind -eq "Oval") {
            Get-OvalResizeHandleAtViewPoint $viewPt $selection
        } else {
            Get-RectangleResizeHandleAtViewPoint $viewPt $selection
        }
        if ($hoverHandle -ne "None") {
            $picture.Cursor = if ($resizeKind -eq "Oval") {
                Get-OvalResizeCursor $hoverHandle
            } else {
                Get-RectangleResizeCursor $hoverHandle
            }
        } else {
            $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        }
        $script:resizeHandle = "None"
        $script:resizeShapeKind = "None"
        $picture.Invalidate()
        return
    }

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

    $resizeTrackedShape = [bool](
        ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval"))
    $clickOnlyResizeShape = [bool]($resizeTrackedShape -and -not $script:resizeDraftDrawMoved)

    $script:dragging = $false
    $picture.Capture = $false

    if ($resizeTrackedShape) {
        $script:resizeDraftDrawStartView = $null
        $script:resizeDraftDrawMoved = $false
    }

    if ($clickOnlyResizeShape) {
        # A click is not a redaction. Remove the seed geometry entirely so
        # coincident resize handles cannot appear as one stray anchor point.
        $script:selection = New-Object System.Drawing.RectangleF(0,0,0,0)
        Update-SelectionFields $null
        Update-RedactionButtons
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }
 
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
function Get-LiveEffectPatch([string]$mode, [int]$sx, [int]$sy, [int]$sw, [int]$sh, [int]$strength = 5, [bool]$enhanced = $false) {
    if (-not $previewImage -or $sw -le 0 -or $sh -le 0) { return $null }
    if ($mode -ne "Blur" -and $mode -ne "Pixelate") { return $null }

    $sx = [Math]::Max(0, [Math]::Min($sx, $previewImage.Width - 1))
    $sy = [Math]::Max(0, [Math]::Min($sy, $previewImage.Height - 1))
    $sw = [Math]::Max(1, [Math]::Min($sw, $previewImage.Width - $sx))
    $sh = [Math]::Max(1, [Math]::Min($sh, $previewImage.Height - $sy))
    $srcRect = New-Object System.Drawing.Rectangle($sx,$sy,$sw,$sh)

    if ($enhanced) {
        $proxy = New-EnhancedStructuralProxy $previewImage $srcRect
        try { return New-EnhancedReconstructedPatch $proxy $sw $sh $mode }
        finally { $proxy.Dispose() }
    }

    # STANDARD PATH BELOW REMAINS THE B1-r4/v2.1 BEHAVIOUR.
    $divisor = if ($mode -eq "Blur") { Get-BlurLiveDivisor $strength } else { Get-PixelateDivisor $strength }
    $interp = if ($mode -eq "Blur") {
        [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    } else {
        [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    }
    # D1a preview/export parity fix:
    # Standard/Default Pixelate export has always enforced a minimum 8x8
    # reduced grid. Mirror that here so the on-screen Pixelate block layout
    # does not visibly change merely because the user exports the image.
    # Blur keeps its existing preview behaviour unchanged.
    if ($mode -eq "Pixelate") {
        $smallW = [Math]::Max(8, [int]($sw / $divisor))
        $smallH = [Math]::Max(8, [int]($sh / $divisor))
    }
    else {
        $smallW = [Math]::Max(1, [int]($sw / $divisor))
        $smallH = [Math]::Max(1, [int]($sh / $divisor))
    }

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
    if ($mode -eq "Pixelate") {
        # D1b: GDI+ NearestNeighbor needs half-pixel-centre sampling to keep
        # block selection aligned with the centre-sampled FFmpeg neighbour path.
        $tg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    }
    $tg.DrawImage($previewImage, (New-Object System.Drawing.Rectangle(0,0,$smallW,$smallH)), $srcRect.X, $srcRect.Y, $srcRect.Width, $srcRect.Height, [System.Drawing.GraphicsUnit]::Pixel, $wrapAttr)
    $tg.Dispose()

    $patch = New-Object System.Drawing.Bitmap($sw, $sh)
    $g = [System.Drawing.Graphics]::FromImage($patch)
    $g.InterpolationMode = $interp
    if ($mode -eq "Pixelate") {
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    }
    $g.DrawImage($tiny, (New-Object System.Drawing.Rectangle(0,0,$sw,$sh)), 0, 0, $smallW, $smallH, [System.Drawing.GraphicsUnit]::Pixel, $wrapAttr)
    $g.Dispose()
    $tiny.Dispose()
    $wrapAttr.Dispose()

    return $patch
}

# D1b: project an already-rendered live-effect patch into the viewport.
# Default Pixelate must remain nearest-neighbour at this final display stage;
# otherwise the PictureBox paint path can visually shift/blend block edges
# even when the media-space patch itself is correct.
function Draw-LiveEffectPatchToView($gfx, $patch, $dr, [string]$mode) {
    if ($mode -ne "Pixelate") {
        $gfx.DrawImage($patch, $dr)
        return
    }

    $savedState = $gfx.Save()
    try {
        $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $gfx.DrawImage($patch, $dr)
    }
    finally {
        $gfx.Restore($savedState)
    }
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

    # Resize Slice 1 r2 / Slice 2: an uncommitted Rectangle or Oval may still
    # contain fractional MEDIA coordinates after move/resize. Its handles are
    # projected from that RectangleF directly. Keep the draft effect/border on
    # exactly the same VIEW rectangle instead of projecting the commit-normalized
    # integer box, which could visibly separate handles from the border after zoom/pan.
    $draftDisplayRect = $null
    if ($r -is [hashtable] -and $r.ContainsKey("DraftDisplayRect")) {
        $draftDisplayRect = $r["DraftDisplayRect"]
    }
    elseif ($r.PSObject -and $r.PSObject.Properties["DraftDisplayRect"]) {
        $draftDisplayRect = $r.DraftDisplayRect
    }

    if ($r.Mode -eq "Black box") {
        $brush = New-Object System.Drawing.SolidBrush((Get-RedactionColor $r))
        if ($r.Shape -eq "Oval") {
            $dr = if ($draftDisplayRect) { $draftDisplayRect } else { VideoRect-To-Display $r.X $r.Y $r.W $r.H }
            if ($dr) { $gfx.FillEllipse($brush, $dr); $gfx.DrawEllipse($pen, $dr) }
        }
        elseif ($r.Shape -eq "Polygon") {
            $dpts = VideoPoints-To-DisplayPoints $r.Points
            if ($dpts -and $dpts.Count -ge 3) { $gfx.FillPolygon($brush, $dpts); $gfx.DrawPolygon($pen, $dpts) }
        }
        else {
            $dr = if ($draftDisplayRect) { $draftDisplayRect } else { VideoRect-To-Display $r.X $r.Y $r.W $r.H }
            if ($dr) { $gfx.FillRectangle($brush, $dr); Draw-ViewportRectangleOutline $gfx $pen $dr }
        }
        $brush.Dispose()
        $pen.Dispose()
        return
    }

    $dr = if ($draftDisplayRect -and ($r.Shape -eq "Rectangle" -or $r.Shape -eq "Oval")) { $draftDisplayRect } else { VideoRect-To-Display $r.X $r.Y $r.W $r.H }
    if (-not $dr) { $pen.Dispose(); return }
    $liveStrength = if ($r.Strength) { [int]$r.Strength } else { 5 }
    $liveEnhanced = Get-RedactionEnhanced $r
    $patch = Get-LiveEffectPatch $r.Mode $r.X $r.Y $r.W $r.H $liveStrength $liveEnhanced
    if (-not $patch) { $pen.Dispose(); return }

    if ($r.Shape -eq "Oval") {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddEllipse($dr)
        $savedClip = $gfx.Clip.Clone()
        $gfx.SetClip($path, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        Draw-LiveEffectPatchToView $gfx $patch $dr $r.Mode
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
            Draw-LiveEffectPatchToView $gfx $patch $dr $r.Mode
            $gfx.Clip = $savedClip
            $gfx.DrawPolygon($pen, $dpts)
        }
    }
    else {
        Draw-LiveEffectPatchToView $gfx $patch $dr $r.Mode
        Draw-ViewportRectangleOutline $gfx $pen $dr
    }

    $patch.Dispose()
    $pen.Dispose()
}

$picture.Add_Paint({
    param($sender,$e)

    # Slice 3: the PictureBox no longer renders its Image property. Draw the
    # current decoded/autorotated frame explicitly through the viewport
    # transform first, then layer committed/pending/draft redactions on top.
    # Fit geometry intentionally preserves r18's integer SizeMode=Zoom result.
    if ($previewImage) {
        $mediaViewRect = Get-MediaViewRect
        if ($mediaViewRect -and $mediaViewRect.Width -gt 0.0 -and $mediaViewRect.Height -gt 0.0) {
            if ($zoomMode -eq "Fit") {
                $destRect = New-Object System.Drawing.Rectangle([int]$mediaViewRect.X,[int]$mediaViewRect.Y,[int]$mediaViewRect.Width,[int]$mediaViewRect.Height)
                $e.Graphics.DrawImage(
                    $previewImage,
                    $destRect,
                    0,
                    0,
                    $previewImage.Width,
                    $previewImage.Height,
                    [System.Drawing.GraphicsUnit]::Pixel
                )
            }
            else {
                $destRectF = New-Object System.Drawing.RectangleF([single]$mediaViewRect.X,[single]$mediaViewRect.Y,[single]$mediaViewRect.Width,[single]$mediaViewRect.Height)
                $e.Graphics.DrawImage($previewImage, $destRectF)
            }
        }
    }

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
            # Draft freeform vertices live in MEDIA space; project them into
            # the current viewport for drawing only. Pen/marker sizes remain
            # screen-pixel constants.
            $dpts = MediaPoints-To-ViewPoints $polygonPoints
            if ($dpts -and $dpts.Count -gt 0) {
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)

                for ($i = 0; $i -lt $dpts.Count - 1; $i++) {
                    $e.Graphics.DrawLine($pen, $dpts[$i], $dpts[$i+1])
                }

                if ($polygonActive -and $polygonMousePos) {
                    $mouseView = MediaPoint-To-ViewPoint $polygonMousePos
                    if ($mouseView) {
                        $dashPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
                        $dashPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
                        $e.Graphics.DrawLine($dashPen, $dpts[$dpts.Count - 1], $mouseView)
                        $dashPen.Dispose()
                    }
                }
                elseif (-not $polygonActive -and $polygonPoints.Count -ge 3) {
                    # Closed but not yet committed via Begin/Create Redaction.
                    if ($isImageMode) {
                        $shapeData = Polygon-To-VideoShape $polygonPoints
                        if ($shapeData) {
                            $shapeData.Mode = Get-SelectedMode
                            $shapeData.Strength = $redactionStrength
                            $shapeData.Enhanced = Get-SelectedEnhanced
                            $shapeData.Color = $redactionColor
                            Draw-RedactionShapeLiveEffect $e.Graphics $shapeData ([System.Drawing.Color]::Red)
                        }
                    }
                    elseif ($dpts.Count -ge 3) {
                        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55,255,0,0))
                        $e.Graphics.FillPolygon($brush, $dpts)
                        $e.Graphics.DrawPolygon($pen, $dpts)
                        $brush.Dispose()
                    }
                }

                # Marker on the start point. Geometry moves with the media,
                # while the marker itself remains a constant 8 screen pixels.
                $startPt = $dpts[0]
                $markerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
                $e.Graphics.FillEllipse($markerBrush, ($startPt.X - 4), ($startPt.Y - 4), 8, 8)
                $e.Graphics.DrawEllipse($pen, ($startPt.X - 4), ($startPt.Y - 4), 8, 8)
                $markerBrush.Dispose()
                $pen.Dispose()

                # Slice 3: once the path is closed, every Freeform corner is
                # an editable vertex. Handles are pure VIEW-space decoration;
                # the underlying PointF list remains canonical media geometry.
                if ($script:resizeSlice3Enabled -and -not $polygonActive -and $polygonPoints.Count -ge 3) {
                    Draw-FreeformVertexHandles $e.Graphics $polygonPoints
                }
            }
        }
    }
    elseif ($selection.Width -gt 0.0 -and $selection.Height -gt 0.0) {
        $displaySelection = MediaRect-To-ViewRect $selection
        if ($displaySelection) {
            if ($isImageMode) {
                $vr = Selection-To-VideoRect
                if ($vr) {
                    $shapeData = @{
                        Shape = if ($toolMode -eq "Oval") { "Oval" } else { "Rectangle" }
                        X = $vr.X; Y = $vr.Y; W = $vr.W; H = $vr.H
                        Mode = Get-SelectedMode
                        Strength = $redactionStrength
                        Enhanced = Get-SelectedEnhanced
                        Color = $redactionColor
                    }
                    if (($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
                        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval")) {
                        # VIEW-only draft geometry: keeps border/effect and the
                        # resize handles on one identical projected RectangleF.
                        $shapeData.DraftDisplayRect = $displaySelection
                    }
                    Draw-RedactionShapeLiveEffect $e.Graphics $shapeData ([System.Drawing.Color]::Red)
                }
            }
            else {
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
                $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55,255,0,0))
                if ($toolMode -eq "Oval") {
                    $e.Graphics.FillEllipse($brush, $displaySelection)
                    $e.Graphics.DrawEllipse($pen, $displaySelection)
                }
                else {
                    $e.Graphics.FillRectangle($brush, $displaySelection)
                    Draw-ViewportRectangleOutline $e.Graphics $pen $displaySelection
                }
                $brush.Dispose()
                $pen.Dispose()
            }

            # Resize Slice 1/2: handles are constant screen-pixel UI only.
            # Rectangle keeps its eight handles; Oval exposes only N/E/S/W.
            if (-not $dragging) {
                if ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") {
                    Draw-RectangleResizeHandles $e.Graphics $selection
                }
                elseif ($script:resizeSlice2Enabled -and $toolMode -eq "Oval") {
                    Draw-OvalResizeHandles $e.Graphics $selection
                }
            }
        }
    }
})
 
$scrubberMarkers.Add_Paint({
    param($sender,$e)

    # Always clear this control explicitly before drawing the current model.
    # The v1.4 preview resizes this marker strip whenever the window or
    # Redaction Area changes width. Without an explicit clear, stale pixels
    # from a previous paint can survive long enough to look like extra or
    # differently-sized redaction ranges.
    $e.Graphics.Clear($sender.BackColor)

    if ($videoDuration -le 0 -or $redactions.Count -eq 0) { return }

    $w = $sender.ClientSize.Width
    if ($w -le 1) { return }
    $midY = [int]($sender.ClientSize.Height / 2)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
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
        Enhanced = Get-SelectedEnhanced
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
        Enhanced = [bool]$pendingRedaction.Enhanced
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
    $lblPending.Text = if (Get-RedactionEnhanced $entry) {
        "Aggressive redaction #$($redactions.Count) added. Draw a new shape for the next redaction, or export."
    } else {
        "Redaction #$($redactions.Count) added. Draw a new shape for the next redaction, or export."
    }
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
        Enhanced = Get-SelectedEnhanced
        Color = $redactionColor
        StartFrame = 0; EndFrame = 0
        BufferedStartFrame = 0; BufferedEndFrame = 0
        MarkStart = 0.0; MarkEnd = 0.0
        BufferedStart = 0.0; BufferedEnd = 0.0
    }
    [void]$script:redactions.Add($entry)
    Refresh-RedactionList

    if (Get-RedactionEnhanced $entry) {
        $lblPending.Text = "Aggressive redaction #$($redactions.Count) added. Draw a new shape for the next redaction, or export."
    }
 
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
    if ($script:zoomCursor) {
        try { $script:zoomCursor.Dispose() } catch {}
        $script:zoomCursor = $null
    }
    if ($script:zoomCursorHandle -ne [IntPtr]::Zero) {
        try { [ZoomCursorNativeV1]::DestroyCursorHandle($script:zoomCursorHandle) } catch {}
        $script:zoomCursorHandle = [IntPtr]::Zero
    }
    Remove-EmbeddedMediaTools
})
 
Update-RedactionButtons
 
[void]$form.ShowDialog()