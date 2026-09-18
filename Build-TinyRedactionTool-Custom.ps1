#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Build TinyRedactionTool.exe - Secure Custom FFmpeg/FFprobe v2.1.0'

function Write-Step([string]$Text) { Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Fail([string]$Text) { Write-Host "`nBUILD FAILED: $Text" -ForegroundColor Red; throw $Text }
function Format-MB([long]$Bytes) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }

# v2.1.0 production release identity. The standalone builder must package the
# exact frozen, regression-tested v2.1.0 release source and the exact approved
# media tools retained from the v2.0.0 production release. Draft editing and
# viewport usability do not require a media-tool change.
$releaseSourceSha256 = '2BC392FD52587343AB4CEA95B19C295286E44E4D3543634D9D3D1E383567BDC7'
$releaseFFmpegSha256 = '28612C0A94D50A29AABD0555C91E086D1CCDF13260757B83B4BBD53A0C2CDCE0'
$releaseFFprobeSha256 = 'BB8CBA76F9D4F05DD608F319477A0604D8A8C289FB6A885B03919F07C4DC9855'

function Compress-GZipFile([string]$Source, [string]$Destination) {
    $input=$null; $output=$null; $gzip=$null
    try {
        $input=[System.IO.File]::OpenRead($Source)
        $output=[System.IO.File]::Create($Destination)
        $gzip=[System.IO.Compression.GZipStream]::new($output,[System.IO.Compression.CompressionLevel]::Optimal,$false)
        $input.CopyTo($gzip,1MB)
    }
    finally {
        if ($gzip) {$gzip.Dispose()}; if ($output) {$output.Dispose()}; if ($input) {$input.Dispose()}
    }
}

function Test-TinyFFmpeg([string]$FFmpeg) {
    Write-Step 'Validating custom FFmpeg on normal Windows'
    $version = & $FFmpeg -hide_banner -version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $version -notmatch 'ffmpeg version') { Fail 'Custom ffmpeg.exe could not run on normal Windows.' }

    $protocols = & $FFmpeg -hide_banner -protocols 2>&1 | Out-String
    foreach ($networkProto in @('http','https','ftp','sftp','rtmp','rtsp','tcp','udp')) {
        if ($protocols -match "(?m)^\s*$([regex]::Escape($networkProto))\s*$") { Fail "Custom FFmpeg unexpectedly contains network protocol '$networkProto'." }
    }

    $filters = & $FFmpeg -hide_banner -filters 2>&1 | Out-String
    foreach ($name in @('drawbox','crop','boxblur','scale','split','overlay','format','alphamerge','palettegen','paletteuse','aformat','aresample','select')) {
        if ($filters -notmatch "(?m)^ .{2,4}\s+$([regex]::Escape($name))\s") { Fail "Custom FFmpeg is missing required filter '$name'." }
    }

    $encoders = & $FFmpeg -hide_banner -encoders 2>&1 | Out-String
    foreach ($name in @('libx264','libvpx-vp9','aac','libopus','png','mjpeg','gif','libwebp','wrapped_avframe')) {
        if ($encoders -notmatch "(?m)^ .{5,8}\s+$([regex]::Escape($name))\s") { Fail "Custom FFmpeg is missing required encoder '$name'." }
    }

    # Preview frames are intentionally emitted to stdout and decoded directly
    # from process memory. The image2pipe muxer + pipe protocol are therefore
    # security-critical runtime capabilities, not optional conveniences.
    $muxers = & $FFmpeg -hide_banner -muxers 2>&1 | Out-String
    foreach ($name in @('image2pipe','null')) {
        if ($muxers -notmatch "(?m)^\s*E\s+$([regex]::Escape($name))\s") {
            Fail "Custom FFmpeg is missing required muxer '$name'."
        }
    }
    if ($protocols -notmatch '(?m)^\s*pipe\s*$') {
        Fail "Custom FFmpeg is missing required local protocol 'pipe'."
    }

    # Functional smoke test for the exact class of capability the application
    # relies on. Merely listing a muxer/encoder is not enough: verify that a
    # decoded frame can actually pass through wrapped_avframe into the null
    # muxer on normal Windows.
    $smokeDir = Join-Path ([System.IO.Path]::GetTempPath()) ("TinyRedactionTool-build-smoke-" + [guid]::NewGuid().ToString("N"))
    try {
        New-Item -ItemType Directory -Path $smokeDir -Force | Out-Null
        $smokePng = Join-Path $smokeDir 'input.png'
        $smokeBytes = [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAC0lEQVR4nGNgQAYAAA4AAamRc7EAAAAASUVORK5CYII=')
        [System.IO.File]::WriteAllBytes($smokePng, $smokeBytes)

        $nullSmoke = & $FFmpeg -hide_banner -nostdin -loglevel error -i $smokePng -map 0:v:0 -frames:v 1 -an -sn -dn -c:v wrapped_avframe -f null NUL 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Fail ("Custom FFmpeg null/wrapped_avframe runtime smoke test failed: " + $nullSmoke.Trim())
        }

        $pipeSmoke = Join-Path $smokeDir 'preview.bin'
        $pipeText = & $FFmpeg -hide_banner -nostdin -loglevel error -i $smokePng -map 0:v:0 -frames:v 1 -f image2pipe -vcodec png -y $pipeSmoke 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $pipeSmoke) -or (Get-Item -LiteralPath $pipeSmoke).Length -le 0) {
            Fail ("Custom FFmpeg image2pipe/PNG runtime smoke test failed: " + $pipeText.Trim())
        }

        # SECURITY: export redaction activation now uses the generic timeline
        # variable n (sequential decoded frame number, starting at zero). Prove
        # both filter classes used by TinyRedactionTool accept that exact
        # expression rather than merely trusting a filter-capability listing.
        $timingGif = Join-Path $smokeDir 'timing.gif'
        $gifBytes = [Convert]::FromBase64String('R0lGODlhAgACAIEAAAAAAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAAAAAgACAAAIBgABCAQQEAAh+QQBFAABACwAAAAAAgACAIH///8AAAAAAAAAAAAIBgABCAQQEAAh+QQBCgABACwAAAAAAgACAIGAgIAAAAAAAAAAAAAIBgABCAQQEAA7')
        [System.IO.File]::WriteAllBytes($timingGif, $gifBytes)

        $drawboxSmoke = & $FFmpeg -hide_banner -nostdin -loglevel error -i $timingGif -map 0:v:0 -vf "drawbox=x=0:y=0:w=1:h=1:color=black:t=fill:enable='between(n\,1\,1)'" -frames:v 3 -an -sn -dn -c:v wrapped_avframe -f null NUL 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Fail ("Custom FFmpeg frame-index drawbox timeline smoke test failed: " + $drawboxSmoke.Trim())
        }

        $overlaySmoke = & $FFmpeg -hide_banner -nostdin -loglevel error -i $timingGif -i $smokePng -filter_complex "[0:v][1:v]overlay=0:0:enable='between(n\,1\,1)'[out]" -map '[out]' -frames:v 3 -an -sn -dn -c:v wrapped_avframe -f null NUL 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Fail ("Custom FFmpeg frame-index overlay timeline smoke test failed: " + $overlaySmoke.Trim())
        }


        # Native VFR preview uses a coarse input seek only as an accelerator,
        # then selects the exact decoded source frame by raw PTS with -copyts.
        # Compare that path byte-for-byte with a from-start n=1 extraction so a
        # build cannot pass if seeking silently changes frame identity.
        $exactByIndex = Join-Path $smokeDir 'exact-by-index.png'
        $exactByPts = Join-Path $smokeDir 'exact-by-pts.png'
        $indexText = & $FFmpeg -hide_banner -nostdin -loglevel error -i $timingGif -map 0:v:0 -vf "select='eq(n\,1)'" -frames:v 1 -f image2pipe -vcodec png -y $exactByIndex 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exactByIndex) -or (Get-Item -LiteralPath $exactByIndex).Length -le 0) {
            Fail ("Custom FFmpeg exact-frame index baseline smoke test failed: " + $indexText.Trim())
        }
        $ptsText = & $FFmpeg -hide_banner -nostdin -loglevel error -copyts -ss 0.05 -i $timingGif -map 0:v:0 -vf "select='eq(pts\,10)'" -frames:v 1 -f image2pipe -vcodec png -y $exactByPts 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $exactByPts) -or (Get-Item -LiteralPath $exactByPts).Length -le 0) {
            Fail ("Custom FFmpeg exact-frame PTS preview smoke test failed: " + $ptsText.Trim())
        }
        $indexHash = (Get-FileHash -LiteralPath $exactByIndex -Algorithm SHA256).Hash
        $ptsHash = (Get-FileHash -LiteralPath $exactByPts -Algorithm SHA256).Hash
        if ($indexHash -ne $ptsHash) {
            Fail 'Custom FFmpeg PTS-selected preview did not match the exact logical frame baseline.'
        }
    }
    finally {
        Remove-Item -LiteralPath $smokeDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host '    Required features + exact-preview/frame-index smoke tests + network-disable checks: OK' -ForegroundColor Green
}

function Test-TinyFFprobe([string]$FFprobe) {
    Write-Step 'Validating custom FFprobe on normal Windows'
    $version = & $FFprobe -hide_banner -version 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $version -notmatch 'ffprobe version') { Fail 'Custom ffprobe.exe could not run on normal Windows.' }

    $help = & $FFprobe -hide_banner -h 2>&1 | Out-String
    foreach ($token in @('-show_streams','-show_chapters','-show_format','-show_frames','-show_entries','-select_streams','-of')) {
        if ($help -notmatch [regex]::Escape($token)) { Fail "Custom FFprobe does not expose required option '$token'." }
    }
    # Functional smoke test for per-frame presentation timing. Use a tiny
    # three-frame GIF with deliberately unequal frame intervals (100 ms then
    # 200 ms) so the test proves FFprobe can enumerate real frame timestamps,
    # rather than merely exposing the command-line option names.
    $smokeDir = Join-Path ([System.IO.Path]::GetTempPath()) ("TinyRedactionTool-ffprobe-smoke-" + [guid]::NewGuid().ToString("N"))
    try {
        New-Item -ItemType Directory -Path $smokeDir -Force | Out-Null
        $smokeGif = Join-Path $smokeDir 'timing.gif'
        $gifBytes = [Convert]::FromBase64String('R0lGODlhAgACAIEAAAAAAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAAAAAgACAAAIBgABCAQQEAAh+QQBFAABACwAAAAAAgACAIH///8AAAAAAAAAAAAIBgABCAQQEAAh+QQBCgABACwAAAAAAgACAIGAgIAAAAAAAAAAAAAIBgABCAQQEAA7')
        [System.IO.File]::WriteAllBytes($smokeGif, $gifBytes)

        $frameText = & $FFprobe -hide_banner -v error -select_streams v:0 -show_frames -show_entries frame=best_effort_timestamp,best_effort_timestamp_time,duration_time,key_frame -of 'compact=p=0:nk=0' -i $smokeGif 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Fail ("Custom FFprobe frame-timing runtime smoke test failed: " + $frameText.Trim())
        }
        $frameLines = @($frameText -split '\r?\n' | Where-Object { $_ -match 'best_effort_timestamp_time=' })
        if ($frameLines.Count -ne 3 -or
            $frameLines[0] -notmatch 'best_effort_timestamp_time=0\.000000.*duration_time=0\.100000' -or
            $frameLines[1] -notmatch 'best_effort_timestamp_time=0\.100000.*duration_time=0\.200000' -or
            $frameLines[2] -notmatch 'best_effort_timestamp_time=0\.300000.*duration_time=0\.100000') {
            Fail 'Custom FFprobe did not return the expected three-frame presentation timeline.'
        }
    }
    finally {
        Remove-Item -LiteralPath $smokeDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host '    Structured inspection + functional frame-timing smoke test: OK' -ForegroundColor Green
}


function Get-SmokeFrameTimes([string]$FFprobe, [string]$Path) {
    $text = & $FFprobe -hide_banner -v error -select_streams v:0 -show_frames -show_entries frame=best_effort_timestamp_time -of 'compact=p=0:nk=0' -i $Path 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Fail ("Custom FFprobe could not inspect VFR round-trip output: " + $text.Trim())
    }
    $values = New-Object System.Collections.Generic.List[double]
    foreach ($m in [regex]::Matches($text, '(?m)best_effort_timestamp_time=([-+0-9.eE]+)')) {
        $v = [double]0.0
        if (-not [double]::TryParse($m.Groups[1].Value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$v)) {
            Fail 'Custom FFprobe returned an unparsable VFR round-trip timestamp.'
        }
        $values.Add($v)
    }
    return $values.ToArray()
}

function Test-VFRTimingRoundTrip([string]$FFmpeg, [string]$FFprobe) {
    Write-Step 'Validating timestamp-preserving video export on normal Windows'
    $smokeDir = Join-Path ([System.IO.Path]::GetTempPath()) ("TinyRedactionTool-vfr-export-smoke-" + [guid]::NewGuid().ToString("N"))
    try {
        New-Item -ItemType Directory -Path $smokeDir -Force | Out-Null
        $smokeGif = Join-Path $smokeDir 'timing.gif'
        $gifBytes = [Convert]::FromBase64String('R0lGODlhAgACAIEAAAAAAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAAAAAgACAAAIBgABCAQQEAAh+QQBFAABACwAAAAAAgACAIH///8AAAAAAAAAAAAIBgABCAQQEAAh+QQBCgABACwAAAAAAgACAIGAgIAAAAAAAAAAAAAIBgABCAQQEAA7')
        [System.IO.File]::WriteAllBytes($smokeGif, $gifBytes)

        $cases = @(
            @{ Name='MP4/H.264'; Path=(Join-Path $smokeDir 'timing.mp4'); Codec=@('-c:v','libx264','-preset','medium','-crf','22','-pix_fmt','yuv420p') },
            @{ Name='WebM/VP9'; Path=(Join-Path $smokeDir 'timing.webm'); Codec=@('-c:v','libvpx-vp9','-b:v','0','-crf','31','-pix_fmt','yuv420p') }
        )
        $expected = @(0.0, 0.1, 0.3)

        foreach ($case in $cases) {
            $ffArgs = @('-hide_banner','-nostdin','-loglevel','error','-y','-i',$smokeGif,'-map','0:v:0','-an','-sn','-dn') +
                      $case.Codec + @('-fps_mode:v:0','passthrough','-enc_time_base:v:0','filter',$case.Path)
            $encodeText = & $FFmpeg @ffArgs 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $case.Path)) {
                Fail ("Custom FFmpeg $($case.Name) timestamp-preserving export smoke test failed: " + $encodeText.Trim())
            }

            $times = @(Get-SmokeFrameTimes $FFprobe $case.Path)
            if ($times.Count -ne 3) {
                Fail "Custom FFmpeg $($case.Name) VFR round-trip produced $($times.Count) frames; expected 3."
            }
            $base = [double]$times[0]
            for ($i = 0; $i -lt 3; $i++) {
                $relative = [double]$times[$i] - $base
                if ([Math]::Abs($relative - [double]$expected[$i]) -gt 0.002) {
                    Fail "Custom FFmpeg $($case.Name) VFR round-trip altered presentation timing at frame $i."
                }
            }
        }
    }
    finally {
        Remove-Item -LiteralPath $smokeDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host '    MP4/H.264 + WebM/VP9 VFR timestamp round-trip smoke tests: OK' -ForegroundColor Green
}

if (-not [Environment]::Is64BitOperatingSystem) { Fail 'This builder requires 64-bit Windows.' }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceTemplate = Join-Path $root 'TinyRedactionTool-Hardened-Embedded.ps1'
$icon = Join-Path $root 'icon.ico'
$shellTemplate = Join-Path $root 'build-tinyffmpeg.sh'
$output = Join-Path $root 'TinyRedactionTool.exe'
$customFFmpeg = Join-Path $root 'ffmpeg-custom.exe'
$customFFprobe = Join-Path $root 'ffprobe-custom.exe'
$cache = Join-Path $root '_CustomFFmpegBuild'
$msysRoot = Join-Path $cache 'msys64'
$stagingSource = Join-Path $cache 'TinyRedactionTool-Packaged.ps1'

foreach ($required in @($sourceTemplate,$icon,$shellTemplate)) {
    if (-not (Test-Path -LiteralPath $required)) { Fail "Missing required build file: $required" }
}
New-Item -ItemType Directory -Path $cache -Force | Out-Null

Write-Step 'Verifying frozen v2.1.0 release source'
$actualSourceSha256 = (Get-FileHash -LiteralPath $sourceTemplate -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actualSourceSha256 -ne $releaseSourceSha256) {
    Fail "Release source SHA-256 mismatch. Expected $releaseSourceSha256; got $actualSourceSha256. Refusing to package a non-frozen v2.1.0 source."
}
Write-Host "    v2.1.0 source SHA-256 verified: $actualSourceSha256" -ForegroundColor Green

$needsMediaBuild = (-not (Test-Path -LiteralPath $customFFmpeg) -or -not (Test-Path -LiteralPath $customFFprobe))
if (-not $needsMediaBuild) {
    # The hardened application requires image2pipe for memory-only frame decoding
    # and null for VFR/decode safety checks that intentionally produce no file.
    # Existing binaries from older build profiles must be rebuilt rather than
    # silently reused with either security-critical runtime capability absent.
    $existingMuxers = & $customFFmpeg -hide_banner -muxers 2>&1 | Out-String
    $existingProtocols = & $customFFmpeg -hide_banner -protocols 2>&1 | Out-String
    $existingEncoders = & $customFFmpeg -hide_banner -encoders 2>&1 | Out-String
    $existingFilters = & $customFFmpeg -hide_banner -filters 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or
        $existingMuxers -notmatch '(?m)^\s*E\s+image2pipe\s' -or
        $existingMuxers -notmatch '(?m)^\s*E\s+null\s' -or
        $existingEncoders -notmatch '(?m)^ .{5,8}\s+wrapped_avframe\s' -or
        $existingProtocols -notmatch '(?m)^\s*pipe\s*$' -or
        $existingFilters -notmatch '(?m)^ .{2,4}\s+select\s') {
        Write-Step 'Existing media tools predate the required exact-frame VFR preview build profile; rebuilding them'
        $needsMediaBuild = $true
    }
}

if ($needsMediaBuild) {
    Write-Step 'Preparing hash-pinned local portable MSYS2 build environment'
    if (-not (Test-Path -LiteralPath (Join-Path $msysRoot 'msys2_shell.cmd'))) {
        # Supply-chain hardening: use the exact MSYS2 base asset reviewed for this
        # builder revision and verify it byte-for-byte before extraction. Do not
        # silently follow the moving "latest" asset without a matching hash.
        $headers = @{ 'User-Agent'='TinyRedactionTool-Secure-Builder'; 'Accept'='application/octet-stream' }
        $msysAssetId = '560868716'
        $msysAssetName = 'msys2-base-x86_64-latest.tar.xz'
        $msysExpectedSize = 42915960
        $msysExpectedSha256 = 'F6BBDE384F3331FB293C5051D5B9DBEC01C772BCCDCEEE83B78213801264D0BD'
        $msysAssetApi = "https://api.github.com/repos/msys2/msys2-installer/releases/assets/$msysAssetId"
        $archive = Join-Path $cache $msysAssetName

        if (-not (Test-Path -LiteralPath $archive)) {
            Write-Host "    Downloading pinned MSYS2 asset ID $msysAssetId"
            Invoke-WebRequest -Uri $msysAssetApi -Headers $headers -OutFile $archive -UseBasicParsing
        } else {
            Write-Host "    Found cached $msysAssetName; verifying before reuse"
        }

        $archiveItem = Get-Item -LiteralPath $archive
        if ($archiveItem.Length -ne $msysExpectedSize) {
            Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
            Fail "MSYS2 archive size mismatch. Expected $msysExpectedSize bytes; got $($archiveItem.Length). Cache/download was removed."
        }
        $archiveHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($archiveHash -ne $msysExpectedSha256) {
            Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
            Fail "MSYS2 archive SHA-256 mismatch. Expected $msysExpectedSha256; got $archiveHash. Cache/download was removed."
        }
        Write-Host "    MSYS2 SHA-256 verified: $archiveHash" -ForegroundColor Green

        $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
        if (-not $tar) { Fail 'Windows tar.exe was not found.' }
        & $tar.Source -xf $archive -C $cache
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $msysRoot 'msys2_shell.cmd'))) { Fail 'MSYS2 extraction failed.' }
    } else { Write-Host '    Reusing existing local MSYS2 build cache.' }

    Copy-Item -LiteralPath $shellTemplate -Destination (Join-Path $msysRoot 'build-tinyffmpeg.sh') -Force
    Write-Step 'Building pinned, network-disabled custom FFmpeg + FFprobe'
    $msysShell = Join-Path $msysRoot 'msys2_shell.cmd'
    & $msysShell -defterm -no-start -ucrt64 -c 'bash /build-tinyffmpeg.sh'
    if ($LASTEXITCODE -ne 0) { Fail 'Custom FFmpeg/FFprobe compilation failed.' }

    $builtFFmpeg = Join-Path $msysRoot 'tinyredactiontool-out\ffmpeg-custom.exe'
    $builtFFprobe = Join-Path $msysRoot 'tinyredactiontool-out\ffprobe-custom.exe'
    if (-not (Test-Path -LiteralPath $builtFFmpeg) -or -not (Test-Path -LiteralPath $builtFFprobe)) { Fail 'Compilation reported success but one or both media tools were not found.' }
    Copy-Item -LiteralPath $builtFFmpeg -Destination $customFFmpeg -Force
    Copy-Item -LiteralPath $builtFFprobe -Destination $customFFprobe -Force
} else {
    Write-Step 'Using existing ffmpeg-custom.exe and ffprobe-custom.exe beside the builder'
}

Test-TinyFFmpeg $customFFmpeg
Test-TinyFFprobe $customFFprobe
Test-VFRTimingRoundTrip $customFFmpeg $customFFprobe

$ffmpegHash = (Get-FileHash -LiteralPath $customFFmpeg -Algorithm SHA256).Hash.ToUpperInvariant()
$ffprobeHash = (Get-FileHash -LiteralPath $customFFprobe -Algorithm SHA256).Hash.ToUpperInvariant()
if ($ffmpegHash -ne $releaseFFmpegSha256) {
    Fail "FFmpeg SHA-256 differs from the approved v2.1.0 release binary. Expected $releaseFFmpegSha256; got $ffmpegHash."
}
if ($ffprobeHash -ne $releaseFFprobeSha256) {
    Fail "FFprobe SHA-256 differs from the approved v2.1.0 release binary. Expected $releaseFFprobeSha256; got $ffprobeHash."
}
Write-Host '    Approved v2.1.0 media-tool hashes: OK' -ForegroundColor Green
Write-Step 'Pinning exact SHA-256 hashes into the packaged application source'
Write-Host "    FFmpeg : $ffmpegHash"
Write-Host "    FFprobe: $ffprobeHash"

$sourceText = [System.IO.File]::ReadAllText($sourceTemplate, [System.Text.Encoding]::UTF8)
$oldFFmpeg = '$script:ExpectedFFmpegSha256 = ""'
$oldFFprobe = '$script:ExpectedFFprobeSha256 = ""'
# Match the exact literal assignment strings. Do not use String.Split here:
# Windows PowerShell/.NET overload binding can interpret a string argument as a
# character-separator set rather than one exact substring, producing a false
# uniqueness failure even when the slot occurs exactly once.
$ffmpegSlotMatches = [regex]::Matches($sourceText, [regex]::Escape($oldFFmpeg))
$ffprobeSlotMatches = [regex]::Matches($sourceText, [regex]::Escape($oldFFprobe))
if ($ffmpegSlotMatches.Count -ne 1) { Fail "Could not uniquely locate the empty FFmpeg hash slot (found $($ffmpegSlotMatches.Count))." }
if ($ffprobeSlotMatches.Count -ne 1) { Fail "Could not uniquely locate the empty FFprobe hash slot (found $($ffprobeSlotMatches.Count))." }
$sourceText = $sourceText.Replace($oldFFmpeg, ('$script:ExpectedFFmpegSha256 = "' + $ffmpegHash + '"'))
$sourceText = $sourceText.Replace($oldFFprobe, ('$script:ExpectedFFprobeSha256 = "' + $ffprobeHash + '"'))
[System.IO.File]::WriteAllText($stagingSource, $sourceText, (New-Object System.Text.UTF8Encoding($true)))

Write-Step 'Compressing embedded media-tool payloads'
$ffmpegGz = Join-Path $cache 'ffmpeg.exe.gz'
$ffprobeGz = Join-Path $cache 'ffprobe.exe.gz'
Compress-GZipFile $customFFmpeg $ffmpegGz
Compress-GZipFile $customFFprobe $ffprobeGz
Write-Host ('    FFmpeg  raw/GZip: ' + (Format-MB (Get-Item $customFFmpeg).Length) + ' / ' + (Format-MB (Get-Item $ffmpegGz).Length))
Write-Host ('    FFprobe raw/GZip: ' + (Format-MB (Get-Item $customFFprobe).Length) + ' / ' + (Format-MB (Get-Item $ffprobeGz).Length))

Write-Step 'Loading pinned PS2EXE 1.0.18'
$ps2exeVersion = [version]'1.0.18'
$ps2exeInstalled = Get-Module -ListAvailable -Name PS2EXE | Where-Object { $_.Version -eq $ps2exeVersion } | Select-Object -First 1
if (-not $ps2exeInstalled) {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    }
    Install-Module -Name PS2EXE -RequiredVersion $ps2exeVersion -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -Confirm:$false
}
Import-Module PS2EXE -RequiredVersion $ps2exeVersion -Force
$loadedPS2EXE = Get-Module PS2EXE | Select-Object -First 1
if (-not (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue) -or -not $loadedPS2EXE -or $loadedPS2EXE.Version -ne $ps2exeVersion) {
    Fail "Pinned PS2EXE $ps2exeVersion could not be loaded."
}
Write-Host "    PS2EXE version: $($loadedPS2EXE.Version)" -ForegroundColor Green

Write-Step 'Building final single-file TinyRedactionTool.exe'
if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Force }
$outputConfig = "$output.config"
if (Test-Path -LiteralPath $outputConfig) { Remove-Item -LiteralPath $outputConfig -Force }

$embeddedFiles = @{
    '%TEMP%\TinyRedactionTool\payload\ffmpeg.exe.gz' = $ffmpegGz
    '%TEMP%\TinyRedactionTool\payload\ffprobe.exe.gz' = $ffprobeGz
}
Invoke-ps2exe `
    -inputFile $stagingSource `
    -outputFile $output `
    -x64 `
    -STA `
    -noConsole `
    -iconFile $icon `
    -embedFiles $embeddedFiles `
    -title 'TinyRedactionTool' `
    -product 'TinyRedactionTool' `
    -description 'Standalone local image and video redaction tool' `
    -version '2.1.0.0' `
    -supportOS

if (-not (Test-Path -LiteralPath $output)) { Fail 'PS2EXE did not create TinyRedactionTool.exe.' }
if (Test-Path -LiteralPath $outputConfig) {
    Fail 'Packaging produced TinyRedactionTool.exe.config; refusing a non-single-file release.'
}
$exeHash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToUpperInvariant()
Write-Host "`nSUCCESS" -ForegroundColor Green
Write-Host "Created: $output"
Write-Host ('Final EXE: ' + (Format-MB (Get-Item $output).Length))
Write-Host "Final EXE SHA-256: $exeHash"
Write-Host "Single-file packaging check: OK (no .config sidecar)" -ForegroundColor Green
Write-Host "`nThe final EXE contains the exact hashed FFmpeg and FFprobe binaries above." -ForegroundColor Green
Write-Host 'Do not delete the build folder until the compiled EXE has passed the runtime security test plan.'
