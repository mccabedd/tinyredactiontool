Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
 
[System.Windows.Forms.Application]::EnableVisualStyles()
 
# ----------------------------
# Helpers
# ----------------------------
function Find-FFmpeg {
    $cmd = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
 
    # Beside the .ps1 script (the normal case when run as a plain script).
    if ($PSScriptRoot) {
        $local = Join-Path $PSScriptRoot "ffmpeg.exe"
        if (Test-Path $local) { return $local }
    }
 
    # Beside the running executable itself. This matters once this script is
    # wrapped into a standalone .exe (e.g. with ps2exe): $PSScriptRoot isn't
    # guaranteed to point at the .exe's own folder in every wrapper/version,
    # but the current process's own main-module path always does.
    try {
        $exeDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        if ($exeDir) {
            $local = Join-Path $exeDir "ffmpeg.exe"
            if (Test-Path $local) { return $local }
        }
    } catch {}
 
    [System.Windows.Forms.MessageBox]::Show(
        "ffmpeg.exe was not found.`r`n`r`nPut ffmpeg.exe beside this script (or beside the .exe, if you're running a packaged build), or add FFmpeg to PATH.",
        "FFmpeg not found",
        "OK",
        "Error"
    ) | Out-Null
    return $null
}
 
function Get-VideoInfo($ffmpeg, $path) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = "-hide_banner -i `"$path`""
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
 
    $w = 0; $h = 0; $duration = 0.0; $fps = 0.0
 
    if ($err -match 'Duration:\s*(\d+):(\d+):([\d\.]+)') {
        $duration = ([double]$matches[1] * 3600) + ([double]$matches[2] * 60) + [double]$matches[3]
    }
 
    if ($err -match 'Video:.*?(\d{2,5})x(\d{2,5})') {
        $w = [int]$matches[1]
        $h = [int]$matches[2]
    }
 
    # Frame rate: prefer "NN.NN fps", fall back to "NN.NN tbr" if fps wasn't printed.
    if ($err -match 'Video:.*?(\d+(?:\.\d+)?)\s*fps') {
        $fps = [double]$matches[1]
    }
    elseif ($err -match 'Video:.*?(\d+(?:\.\d+)?)\s*tbr') {
        $fps = [double]$matches[1]
    }
 
    return @{ Width=$w; Height=$h; Duration=$duration; Fps=$fps }
}
 
function SecToText([double]$seconds) {
    $ts = [TimeSpan]::FromSeconds($seconds)
    return "{0:00}:{1:00}:{2:00.000}" -f [math]::Floor($ts.TotalHours), $ts.Minutes, ($ts.Seconds + ($ts.Milliseconds/1000.0))
}
 
function Quote-Arg([string]$s) {
    return '"' + $s.Replace('"','\"') + '"'
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
    $table = @(2,5,8,10,12,16,20,26,33,42)
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
    $table = @(3,5,7,8,10,13,16,20,25,30)
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
        $enable = "between(t\,$($r.BufferedStart)\,$($r.BufferedEnd))"
        $nextLabel = "v$i"
        $isRect = (-not $r.Shape) -or ($r.Shape -eq "Rectangle")
        # Older redactions created before the strength slider existed won't
        # have a Strength field - fall back to 5 (the slider's default/
        # original-behavior position) so they still export exactly as before.
        $strength = if ($r.Strength) { [int]$r.Strength } else { 5 }

        if ($isRect) {
            if ($r.Mode -eq "Black box") {
                # NOTE: every "$var:" below is escaped with a backtick. Without the
                # backtick, PowerShell parses "$x:y" as a *scoped variable lookup*
                # (like $env:PATH) instead of "value of $x, then a literal colon",
                # and it silently resolves to an empty string. That bug is what
                # made the original "Black box" export always produce a broken
                # ffmpeg filter graph.
                $filterParts.Add("[$cur]drawbox=x=$x`:y=$y`:w=$w`:h=$h`:color=black:t=fill:enable='$enable'[$nextLabel]")
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
 
# Maps a time (seconds) onto an X pixel position within a track of the given
# width, given the video's total duration. Pure math, no controls involved,
# so it can be unit tested on its own.
function Get-MarkerX([double]$time, [double]$duration, [int]$trackWidth) {
    if ($duration -le 0) { return 0 }
    $frac = $time / $duration
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $frac))
    return [int]($frac * $trackWidth)
}
 
# Whether a given time falls inside [rangeStart, rangeEnd], with half a frame
# of tolerance on each side. BufferedStart/BufferedEnd are rounded to 3
# decimal places for display, which can leave them a fraction of a
# millisecond off an exact frame boundary - the tolerance keeps the very
# first/last frame of a redaction's range from being wrongly excluded.
function Test-FrameInRange([double]$time, [double]$rangeStart, [double]$rangeEnd, [double]$fps) {
    $eps = 0.5 / [Math]::Max(1.0, $fps)
    return ($time -ge ($rangeStart - $eps) -and $time -le ($rangeEnd + $eps))
}
 
# ----------------------------
# State
# ----------------------------
$ffmpeg = Find-FFmpeg
if (-not $ffmpeg) { exit }
 
$videoPath = $null
$isImageMode = $false
$videoWidth = 0
$videoHeight = 0
$videoDuration = 0.0
$fps = 25.0
$totalFrames = 0
$currentFrame = 0
$previewSeconds = 0.0
$loadedFrame = -1
 
$dragging = $false
$dragStart = New-Object System.Drawing.Point(0,0)
$selection = New-Object System.Drawing.Rectangle(0,0,0,0)
$previewImage = $null
 
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
    "previous_frame" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAkeUlEQVR42u19aawk13Xed+6t6n7LrJyNHC7DdWgOLYocyxJpWX6iLUWUKURW4EfJNgTDdhDEyI8gcRIgCOIREyM/syBBAtiwohiJFM+QCUw7sp3ICQnHCi1ZNCWRI+7bDGfjcOZt3V1V955z8uPeunWr38DhkPPixHgFNN7rfv2qq849y3fO+c5tYPPYPDaPzWPz2Dw2j81j89g8No/NY/P4v3rQxp5eCUdAC3jcAB+9wud+HOGcj1/x0z7R/SLAwwpA/79a1cWjao+qWqK/ABpKwOLiUYvFRfv/vAUsHlX76OcMi7QKc2AGP/rrh245uO/OHXvmD1h115RGDRWUVEq8glngPcAq6VzeK4wJlyjMUBGQKFQBEYGIgGFgVAAIAIY0DqICiELFAzCAOkAYkPC+9u/dcwXEQQGIFyir9407PVlbeXX0ygvP4/yvPgOgAQBVJXroIYNjx/hKyay4Mp5G6QhADxMxANzyN57+xD2H9v3UtVfP/sieXeVNe/bOoRwiChRwDDQMcHxUDdD48LtngBVwDhBWsMSfrBAWsBd4ZjALhBWqCmhYEGEJr4tARaCqEGZAw/OwcBwWCBrewxyEz9x5GiWoKMYr92Bt+cEXVy6+/T9OHv/el4noCQC8uHjUHjv2kFwJ1/SeLWBx8ah95NhDrADu/jsvfvq+D+z6+3ffufNDN90AkAfWVhQra57HE9G6EVS1R9UwaseonYfLHiIM9gLHDGGGcx7sPVSjML0DOwdmhoiAVKAqEM9gCa+pClQUYA7argoVhghD2UHYA1CohAUAwiIqh88BFGQsTFHSYHabndmxH4Ote7G6Msb5E2/84ctPfeuf4OV/9ntEgOoRAzwsf24LsHhU7bGHiPGhr+176BcO/4tPLOz87MHrgNFFlgvLKuMJTNWIqR3DRYE2tUPtGY3zcA3DeYZvhc0+aTGLwLsgMJXgglgkLAgzVAEWBoQhHBciPleNQhWBio8/w+8Sz6USFgdo/8Zx8aRbMGFARYy1MnfVfrPt+veb0QR445mnvnTmv/7y3waWL2Jx0b4Xl0TvVfjbf/6Fe372J6599JMLcze5JeG33mKqPQxLEKTzjLqJAncOjQu/N87De4aPLsW5IHzJhe08hIPGa+ZmOiFFwUnQdmUJ7kYRtDkKUkQA5Sj04HakFbhqsKT0PkmvQwSqwYWJbwBV3nH9Hdhy4F77+vPHj7/y6G88BPf7z76XRaB353bUPnKMeMvPH7/vrz500+/+2A/ObD/5Su1HIy2IgvBcK1zPQeMbD+89vBc47+E8g5nBzgeNZ4bnKDSNVuBdT9vZcxI41mmrIAR/ie6F4yK0ApXMKhjaLgiCoCUuMuLCaVyUdkEABVThmzHKuW3+6rs/XZw9dfbic//lN34M5x/703e7CJe/AEfU0D8i0c9/95a//tAtf/yjh2d3vXR8lV3D1hgN6IQjshGBc4zGBw333idB+yh4YR//JyASYYbGBWHvgsCgmfZnQVUFiC5KYtCFxvdp64qiq4m/twsYXkdvMcK5Ob4/nkMyNxUXgl0NYwre/4M/ac+8ee7si49+8T5qvvaq6i9fdkwwl5tYLd4J0huOzDz40esf+dBds7u++6dv8/LK2E6aCqNxjdGkxmhcYTSeYG00wWhSoa5q1HWDKv5s6gZN4+CdA3sP7xx8G2DTQvkITz1cXYOdg/gmBGLvYlAN8cN7H2IFx5/qo8vxQbsj+lHuWxDExxjBScBhrRSimlyZtJaCEKyJCOxre/LJ/+ivvuG6ffvvf/ArqlosLt5Jl6vU9vL8/hfssYeIb/qb//4ffu5Tez97+oULbnlpXKj4qOEB2dSNQ9141LVLAmoaD+/ah4NkwmPvwT4E0BBoQ/DlLGC2CCe5HuZgPeyjtmoXOCW4IUmarskdtdqcQ9PWzVAUMtLncIwBHdTtFlAhbmLqiyfc3jvuv2HZ7XFPf+1vPYHFoxbHj+mVd0FH1OjDUPr04wd+7ufvPX5wnwxeevaUGZZEqgoWXYfFRRQchcERWnJELcH9xCDJkkHG9vVOOFDtsH1aiJgLiAepdm5EBdRqcPv/0B7C0eyzkq+HgNrgnbmvAHfbAB2thUPiBxj4Zk33HvqErjXDyYu/9a/u0OqbJwlfoHfqit6xC1q8E0Qgveu+W//uwZtmZl/+3ml1TU2TSYWqblDXNZoq/qyDq6lrh6Zp4sMFt9N4cHQ34j0kxgV2Dq5p4JwLcDS6FWEOv0vQ+ABVXQzQrkM00c0ECButQ+Ij4n9JMLR9+Jgxhxgh2gXsZBWaxQZpFy0uNjcwdkAXXvoj2bZrz/z2uz/xSwRSLLxzuRbvNNN9lIhx6Neuuu3a7T+9dGpZly4s27I08OHvQBsoJWDwZAVtcI3ay60fbrVcNcJPicmQJoG2SRKAzqXIFBJSRLfCEcloF3yhoGQZ2rMyQoeMCBoQlGYW00LXhJ44Iao2uVNlEBk04wu2Ov+C7rz62p9ZxvYv0BMPL2nwLnpFLGDhC49bAbDjhw//+DXXbN1x9sRpUfHEPmB71zRwjYNroWb08wFickI/wde372+iJTRg14QAG7Vb2iDs28DqkhYrNylwhgX3YNdA2ceajw+WIeF/26y5tSTlEKAly5w7V7feAlr/D1UopLfAQVk8iIhGp74rs1t27C5v/tQnFQAWjtgrZgF77/yoAsC11+388QGgKxdX1BDDO5+0K1pxKG61Gh8vVnyeSHEUZBc4ESGlivS1LPPlCg34XHz8vK4OlCBj5tcDckGn1dFKE6YHQK2FZefpIGiXNwCxdpTB2RbaAgKFQbN6XudkrFv23PDgxVfwFey9U6/UAtAjnzUMwO6aHx5u1laoriamtJTdcLylBN9irUW1C6ZtwOMuE02vowu+mkO+GNiRMtM2g41oJQuoSNoZnhtElyMCRbugWCd4zRYn1md7iVuHiNr/Dy5L0SV9UIX4yvDoLSrn5u4BYPTooryTcvz/2QUdOUJQBW74lb2zhbl+svQ22DnyyaV07kJapOM5JlfZ68Lw7MESA2Iya4S4IdqKPWgwt5DSZz9bFBJcSSpDsEsuiDQIXEP5GAoCNMLzKBGFCctAFJeDOiWKz1vrUY3WR0ixIVlHFmsUIB5fQFEWB4BDe4lIgSPmvVvA8TvD1Vx3cF9ZFnOT1RWId6Skyf202s+tVSIG4wQlWxwetYgo3C1FK0rpS0x+omVIKg2Em+aE8XOtj/CSWs2O9hMtE0QA2Q5za/glWQBFlMM+9hUMAh5F53pEu6opANLueTIrgHy1BDu3ex47D+zBxeNnrlgMUADYtWfGWAM3qlSEyXv0/HCoXWnSYFXq+WS0aU4UCMGEmxGFaZMeNlBSKLIyQmyeiIbmQecatEMr0FDDB0WNDYInigpIJj6yxSAKMEUCMFBqQoBXzqyAEN7VBebWatMCorsW4UZBShjMzUXtpSsDQwFg4iAuZK8qAmk1IwWrVvgxELfCkFYgpnMDpoAtSigV8CjCLXoP9TWMmYDruHheofCxvjOV1aKnfeE1ok7QrRshC5gCxpZQU4BMAbIlarFwnmDUYVhOIM0I3IyhvoaygiguKLr4Bu3gKyXhZ4E7weOGrmweAAATdL6ZPVRNr34iElxJa65hAVo/CYAktMRMiXJmDm64E3b+KuzZNgMGQT1jPJrgwrnzKM056GQJwqPu/mLYaz11z/xbX082LnRYBDIWMCWoGMAUM7DDWTQ0By534NBNu3HDniFOn1vBM8+dAMbnYMwSuFpNJWvteQHNStTaKYB2VwbV6J42oiXpAGWNGSWnxAtR+6X1vVOoIggvCoQs7GAGfm4v3nfoRnz+h7Zj2zxQs8ILofaKP3r2ajz6tRdBKkDqYCG6g/A5SAlU7C2ThZKJ2l10C2EHoGKIcjgHLrehHuzCwVuvwYP37sHN182h9sD8APiTbx/Arx39YxgKxTYWB+UmyljTo80FejAVmSvOFOTKL4APxTZqXZBqKtUGS4yJCks/eiTfa2CKAXSwDdcduA5/78Ht8GCcXgacB9bqEMQf+MBWeH8bvvLVEYZuAnY1IKbT+mhdRNS5GmNhyAYXE4UOO4QpZ4DhVtSDnbj2umvwwAf34K7b5rA6UXz7dYe6ZlgD3Hv3bhx/5Tb8wRPLmCmjKyIb3dCUUkVrhOY5BBJEDYHcbYQFuNT8YO9grY2WgG4B2nZgJyaQCa6JyMAUQzSDbfjw922FsYIXTwHEirVa0DhF5RQrE8VdB7fgd5/chdXxOZApIWjae4fmkJIMYGzQfFPCFAOgmIUdzsIMt6Apd2LH3qvxY4f34Ie+fw6VB5474bGy5mE0ZulqcHZpiNtvvgr/7etbQFwCJliRRHgaPzjB5Nb1EKLb1RCyWxcFvyGsiBLqBa5uIN73kphUQ8/8I5GBkAkKgQAOlAzMcBZb5wssVwrxisYxnBNUNcML0ChhxzwwOzeLJRqAQMHtkAk3bjQiGQOy0cfbAUw5CzOcQzGzBU2xDXb7Pnz8nn34S4fnUZbAy6cYF1c82IUyReU4rmERzksGZEsIFREBaQrkndAlxZ1ecE5aGF8t/EZYwCRovsYgjCzrzf1kFrSgAhiKHxOgoJoCAoL3ikkj8I3HeOLRsIDVoLBlCOogCChmihQEblpIaQFjg5sphrCDOdjZefhyO9yWffjAoX34yx/cgn07Ca+dF5x+g1FXoTLrmwbeh3JGWVgUAxORW4THKZATuiCWQV7Ngq/EHkL2Hig2ygLQS99FuqSpzWYTvqb29SC4Nt8WDc+NCfyfumG4OjRwGs9QKqBFTKBay4KFtogGRXA5tow+fhbF7Dx0uB3NzB7cfuvV+Il7t+P2awlvrSqeeY2xMvKoqwZV1aBuHMTHrBkAoYSxBcRLUhAQxeCeQdAe+pKUbac+w1TBbmNiAFxsmIdimoFJ9Z5UMo6mnC6eTEAz6eLC66zh4RmBH9R4eBGQMTASIax0ph600oJsCLKIyAbDbahn9uK6G67Bpz64A/ceLDCqBc+eEIwniqp2GK1NUDUOTe3gG5eqocYYFAaQooTnLFdpM+BM03uN+QwQ99xOG6xlo1AQAiWQfKi5hNJsho+j1gok1VhAgEBAkVYo2T05DzReYgxgOFbAMtRL7K5pdM0GsGXIaosh7HAOZrgFbmY3tu/bj5/4gd342PsGMJbxylnG0qqirj0mlcOkajCZ1KFk7roFICiKwoa0hDm40lSKQ4TUmuJZoC9qCsTtm1uUlJeqwxnKDbIAVai4UAOHTVqSSr9oFYCC4AxAahJk66xF4RlonKBpPGrn4QWAEIxjpNMRBY0nC1uUsDNb4Ac7YHZcg4/dcw0+88E5bN+iOHGe8dayoqoZde0wmgThV1XoxLWNf3YNRBiGAJUCZAi25LTYXW+p1RTO/DvWW0SPQ6SJ4rIxLii2BcEC8R6m6IQvknlLDa4n9Psp9E6F25QplpgBL8H9VE3gCElIo0NBr60kmCL4+aKADLbCze7D4UPX4HMf2Y6b9wGnlxjH3wAmE0ZVO1S1w7gKCxDapE0m/FhBje4HqrBsEp9IYpk80YbzskfWQ2gz35b41Q/ArRz8xuQB4pqMtISuTh7hZ1v8SmVgMBQEk/oBbZOlJeAyGsfwPlqRJTgfCLkEwJYDFKZAVWzHrbdcj5/6yG4cvsVitRZ876RiPAlc09Vxg6Z2mNRR8xvGpAqvedeksjhF1GJtLAVyAfZNQDMBOaQ2ZIY8ctOIWq59+ImuVwCVDYoBZdkJVwMzGSqpNBAQmHTX2ybCsBBVmIzVIAp4VnhRiBKcD2VrAwPPgkBoVpAtQVuuwi98/CZ88vAsvApeOctYHQnqhjGeNBhVQfMnkxp1E4i/rTW4xqUWp3gPgsAQAUJgApglBfsgRM7IWdJ14jJSV0ttaZsyeUBOaGhjakGTZGYqDCLq5QHU4vUW7QhCDiAMijfV4mhmwEXqeeMCPhclkFoYAbwooB6OZvGLDxzAp+6dxfOnPFbWAO88RlXr52tMJg0mtUdVB95pVTtUVRMo7M5DfICeiLwfY0OxzjJFEpdiqraWmvD9bpv00JCm6mjMefIakHMbg4JC0hG7U0S9VmSAoJS6SsGNMkB9Hmd4hEVoEVCLekACxwoiwNU19l81g4W75vDsSY+1NY3sOofGeUwmDdZGgRIzmTSJ9DuZ1PCOEwnAx0a8oaAPqgbWlElekkhfsQNAlLExNCNmZT5eNGNkdAiQ2n7HxsDQQAdE5OtTLA30TThr+6mkiYzUScoM1rGiaTxYNARhAQCG9QrPirpqsG/HELUQVkZAVTlMxlWkNzqMJg3Gkya6mwbOcaI+imigK3qf+KTWKNSEEoawSZQYRdvz6TpeXd9YUgeuRwSYCsi9RFX4clDoZeYB3qfEKg04RNgp2l16KpTF/oGxmiM4iAYIKhy0tq5dqMWQwEtk2fmA270HxpVgPK4xHlWoJhUmkzq4nMahmtSoHMN7hqsb+BZ2ek7aH90+CmtBKMG2pbZnEDq2R7saP/ol5rwJpP0EDPruB2UuYwF8136UAFPCWE+LGVskEJrdRJo6Uiqc6H2BpBWu3bFAOVgRq8CQgFUjbzYgroYRAmvVYnuH8aRG07huuqaOXCPP8M6FgiFzIoEBGqGngAiwZQFRjX/PysxZENW2qzfVnF3HtppCQ23hckNckGpsSKsEjY2ups2Ik+/X0NslmFCO1syMRZLbZAE4Y8fBCkQQLCAKr+GwUMEyECdq4gyC8+Fn06Bp6kQI85H22KIYVQWsBRNgjAlNFx/nDaJC9LpdcREo5wPlUBNdL1ghsW+Mrji3MQ0ZdPV+7fy6as4cQIoBgIHE6ROj+TBdsAQfB+ycD7MCLdsgDNUhMOK8ByHUjCS5ifAzpBYK1zRxsTT9TxBwiFkEwFAUpSGo2I4cFicu815zS1VvCb40XZBT9PICymtHyVVtBAoqypSsiDBITY+63VliqAGF9MABUoSgnbicbZWTQgaaeKAExBsHAEuKt5fGgCoGwwKuKsLwXDkIhSQygDFQMl3XqgUD0e20miwAjCjEE9gYeF9gCGSsig75tIMf03Azdb6mumF55twx6TZiQKMsooziRIl2kyaSceYTl18k8nA6NnHLfEuWkwSuYA1Q1MSCZFkWeO3kWXzzT07hnluHKOfmQeU8BjNzGAxnUQxmYMshbDmALUNZuYWAgXKioRWRZ4XIGipRbrYoYAxNNfmRrj3FBOTJQjdLoNP94I1LxHyaQoRw6ExpO+icXyR1zSQRkNFIyJJe0mMIsAax7RK4aoaQXAZgMDQTfPHRb2BpdA8WPnwAb49n8PxrKyjFBEqLEkoN7ohZYNMCx2w9CpFSn8LAGAoBGSEeEFG3UL0yc86Glqz8MNUPzoNxaxHObwwMTUEYXRxAS4SaTshEoEbCJHvk0bQ30Aq61SAiwBLBWoI1QNE2pLgBj9/Elx5ZxpNP34IH778dhw/uxZsXZvHqiRXMwcDaIgZRgjEFalNAYGBhgJY1raHXQBQehihmxOH6DcUmf2rAt5TEPg9J/4wAq3k54nI8++WVoyWBMeq4bh0bTSnTIZvms9oJlnaATqKmGCIUhYVvQs5WWsLAKCxFpjU7qIywxYzw0veW8U9fegM/eM/34YH7D+LwoV145dQMTp9ZwSwVMIMhsDaCxN5uXY2hMFDjAfExNTEgW8CUwe0QAGttb0wo74MlJcubL3qpvTumkrGNQUGTVKRCRgVPiVmiQkR/SiEtJ5XeKFCLWMqCUFiDwloUNvQPCksooxWIAsoC8TWYG5RmjAEm+MaTF/D0s6/ho/fdgR/5oZuxb9fVeOnkGs6fuwhjSthygHoyAtkStpwBN1WsBTGsoeDzW0uwFoUNbqnL6jUqjGaZ+6UEn/WAcx4IYYPK0bFu0paWA/7KHtolYqEnEBy9KoMkdtGkK8iVhcWwNPAlQQcWCoOiCMK3qb4iEG4AX4FVoM0EM+UYGFX4va+9jW98+3V8/CPfhw8cvh4rV8/jhdeXsHxhBYOZGdRVhXoygasrcFOBXQOChAUoShhboogBuN3DonU/kjdaEhcIGQpKjLNs1mAKsFy5BTgW3+mmaiEGhGycJ8VdTZdELSTUbCsA5h58KwxBbAjFZWEwKAiFydp9wlBfB+sjA88NyDeYG1ao3h7j2GNn8UffuhGfWLgdH7hjH84sb8XLbyyBVldRDIZoqgrNZAzfVBBhFIZgBwVsUcAWNkLrREjPBvtadNpXNNKcJBmpiG1+0rqgDQnCHsnfS2xgdAFLU+qO9id1hK3khtLAHIOUYAuDwaCAcAGAMCgMBtEFRWpFJIN5kIRMHMYAEuiD5CrMDSc4f3INX/rN0zh4y414YOEgPnzXbrxybiteP7EEM1iDLUs01RAQD0uAIUU5iO7IGlhLvfFUTE3N9BFPZ/HU4wZpmrC8sjHg2KXhkFI3O7uOpBrhnyiDUKRaEIRTbd4awkxp0QzKgESMwXBmgJmBRdrpqR2m9g1UmhD6haDkAQl08sbXMOUYszNjvPz8Mv7lq2/i7u+/BQ989DZcf/hqPHdijDNnljCYGUN8lcrphQVsUaIoShTWwkDj+JNkeY702RG9mQDtZ8eqvSmcjSnGtT1QdNkvdfMomUYgkVg7TM0hM+YaBoKyLDAcDgBfwhgDQ0BZlhiWNrgg9QC7MJurPg5QaOKEqtjwmg1EWudr2MEEpY7x9FMXcfz513HfB27H/T98M269dj9ePLGGlYtrMFwB3IDUYzhTohiUMNaG62MHUg+SrC1JlLUd83mALA5QZiC0YQvQZoh52a3LuXT6WWvOHMoGKg7qa/jxCsarY2zbsgNFUcLMzYLbuGAs5uaGsCRYWVqCkUkQStq1hBPlhYgjSYrDAokDs4M0E5SDVZCu4vEn3sa3vvMafvSHb8d9HzyA0f55vHZ6hGpthBnjUFjCYDBAUVqoeqibhPkA6fhDlFjQmujnin49qNM6vewtnC6Lni4aMlaIgCz16yK9xnTnhsLNGJBvwM0EQ7OMP3jyVXz8Q9fg4I3b8NaFAQiKhhXDQYE7D8zgy4+9hIvnz2COx/C+BsT1BiGSZqrE/SAcQAVgGqgdQrmC+gozgxHqt1fwn3/7LJ586gA+uXA77nnf1Ri7eZw4uwb1jOH8ANfvsXjk+VPQegnCVThfi9yUezA0H9bIp2PSXPLGWYC7hC+Uzh1FykkwjRigWQFLIPFQriHNBNYu4+RrL+BXfnWAn37wDlyzc4hGQvbbOMGXH3sJR3/nScz6s+B6BHAT8w/uF9zi0AeBINwypQsQNwAPIL6CuAmoGGF2sIrzb1zEF79yArd981Z86v5b8f7b9gAFYccM8Pt/8DIe//rTmNVl+HoUXR/3hrN1XSOmD8FbRaQNqwVNJyQ5+slLEkJxyC2YLUmEk0xQmsBXQCmC49+p8csvn8T27dsBYyHeYzxaw9JbpzDL5yDVEtSNodykSmprBSlBolDvoVhXVPGA8SFg8wBgB/I1xE1gijHmZkd49bmL+OcvvYzbb74W+/fN49y5JTzz7AswVbAAdWPA1zEg558rl0BF2czOFHt6Q4JwEnJOTtL+yL9mnHpKuJpBcKF1oQLPHkVZA7yCpdUB0s6Ibow5PwLXa1A3gkoTNX96H594k5FgFYQQZ8SUQwncSHQjDvA12FcQP4EpVlGUF/Hcd17DM0wgaTCDEbhehTZrAFdQbl1Qf0qTWreTEXPpUgTmDekHlLNQlRADWmSQ+/+psc0uP4z8Sh9uhOJWAvA1yKwFzY0MCmUH9jXgK4Dr4H7EZyUQ7ZOm2hJ4gq1hHEopCJ+MDciLLOAtiGuoG4GrAoWxKAmxeVMHiOorKMeY01JpkgJ03M9uTDZwoVMhr60llRvRkqwntQijsBHXGztVmpV1qXnqEcdsERyTKuNDwERgUksaSQ3QU6UJ6En9JRKjGOh646LICAFty5SCSyIfLIVMyB3IhoVpHVkc/A55hQt7iIpPNa/pz9fe1gf9IT4yBYkIULtRePWQXoEFOKQEQNfevNA0TTMzmB+oikIttaSlrhY+VQ0MqWugKEo7rBfyASKLbPqnu7mYtOmU5vdIUTLdFNd+yZzy6XiJcYkAcoGaEmnomoYufLcPRUQ/6/3+VAxoYSkh8GBVleyA2LsKo4sXwtU8fCUs4OEg2eo/nW7GHztldm25UVWVIJTvGpL75hSUCGlECe2oamJO+Cy7z3eq0k7wrSCg6z6DehLvfqfoktIikKTSiBIBauL2Bf0OF/LF17ghk2qv7dpvxGQzESEmKBVzJDWfAE6eXVenfg8tSdWfPGoBNJOllW+j3K5kClHp7y6Sb3bU24NTfYKRiabYjoHGcoK2zzmUHEIA9Gknq7SToXDmGrLgnLYw4BQskTbj8zEDb2NPE4exm+4zuYHEwNttziS9Xbj6LU1dN6cMMkKDLcrN6DgAH/ea1isTA849SwCw8taZ32tuu/nTxcw83Gipl423AZKmGASB7YBswrAH3tIJqB2E0G73FEqbNfXHgNquZ39SXrs+hNIlMnVKnIG+95I0z9YJGx3XXzkrQct6v6+hGGMHW6FqqZksfzXU0M69o5TsnTXln4AQgPr5bzy2dvHt0exVN1gRViWach05/S3fVJX7maV0O50ENxP7zetcT77HG/ezz6xE0Kvdt3R5yTbnay1B810SfdqBpXdtbcMp5gFps7+8LZn3hmPJt9x6ta0ny2vu9Mu/FYXGV24B8LDo4lELfP3U0pmzv13uvIWMLXnd5EusgGo2C9DfMvjPenS7WfWYyJIJYN0ePzkike7Ruib0cXy7C0tqDqXtLac2ae0NZ0yxH/Kqb1uXsgO28/uoHl18DDh3Fnhn7ieG73d4HIcBjmNS73lpbvf+vzY3P0S1fMoQmZiEZRoHWR9YMeVGML1F2NSWkdN/7wXrKa5mRjfBNF+nx9+M9RpMsRsg68or3aRmru0d5kcc6lNxGO68Wb0YWj3z4s+hPn8GuJOA43oFLQAAjjEWjxq8dezpsy8/828Huw/ZYrDFd7OynV/sRll5aouvfNvgbIPsBAG526szs4z+fm6cXEO3gyFnu1x1jIb8vYnTOkWVR3au9BntefOGU4Z6uuaToJjZ5oudN9nxhZP/DsvPPQUsGuCdb2F8ed8KcfwocASm+c0v/6Fu3f/53Te9b/v43AuRwdf67q5rROumR3TdvFWOq/sWkiON/qRKy9kkZGUJdIkg5eeS+L4eq0E6i8RUgTG3lmxakto8L7K/4zSxzN/wYbv29punxq8++1eAX6qAfw1cRlH6MrcuJsXDxwk4eeHMt5/43MULa7Lj1gUoOwEMUlDOcUIvT+hcSRegpwfcOktBRmfEJVyFSN4K1MyfB6H3Xd+li4iavoGjz/mnLNlIxC5QpNETVL3MXX8vqvFIxmeP/wxw+nzcoOmyyqHv4ntRjisWFy2e+t3XVpbljZm9t31m+74bUL39mqoKwZgkhLw3oDo9Zdgv7+aJla7Tyml28iX4OljP19Gpc+tUVVenqSZR4ylL9ShRTcKuLBFq85YDHzZOh2bpjad+Vi4+9xiwUABfvezd09/dF9McP65YWCj02f/+1NJS88Jg+7Wf2Xng/daP3vK+WiaQod4NrysXdIy49Tx7ZNPq1Ou+9Vh4PeFPZcTo1ThwiZJln8idzQPQ1Dk0UhoVCrDTYn4Xz9+4UNSTWpZe/V+flwvP/Icg/Cf8uxHlu/9moNdfFywsFDj++HdWzi0/zuX8R3bc/KHdg5mtxNWK52YEqFAPshGt06+05w9Ra+vdKAS1qCPb7ky7c6H9G1E2TNG2LLO/p88yvWtJkzwwcWsdilstmF7XDcpiZ7by/LWHbbn3LrN67tUXV176nz+pay//znsR/rtoIV/i6L64YOfw5s/8g53X3/6LO/bsn9NmGfWFV7RZfYvFTaDsSMRTPvzc1XWyLc4wVfPPut1xc9Y2vybquyWFKmmPYkg9cNbthhhyac0pTG2Ma//fFmqH8yhnd9li237C4CqMl8+NR2df/Dfu9Nf/MYDlgPff2zcqXaGvscovZPfB2Vvu+7n53QcW57ZddctgbhsIHuLGsdwb6zXUbS2pUxtetF/EQ9S5hpz+l5PB0oJSPqUCUEs5j9aQFwpD1ZZjwS6DzgjbqpEtYYohRAFXT+DGKy9NLp54tD75jV8HmhfX3/Of+wLEcy0u5t+xNYOd7/+B+R3X3Uszs+8jW9xA1uywlG2GRLaf1UY4GTbSVjUxlrB2oz9kijUID0W5TF4i9UbURDFGj0ZtB98pTA3lUlRKUi2MoTDrrwwNe+IoCD5qxIqye0Oq1WcmKyf/GKtvPAWgygR/Rb7CaqMOg4WFAn/hjoXi8mH7n+9BwKLFwkKBhYUCR46YuJvre3u82/McOWLe8f8eOWLSdYe6DmHz2Dw2j81j89g8No/NY/PYPDaPzWPz2Dw2jytw/G9pBuPvCg1xvQAAAABJRU5ErkJggg=="
    "freeform" = "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"
    "oval" = "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"
    "rectangle" = "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"
    "pixelate" = "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"
    "blur" = "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"
    "black" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAe8ElEQVR42u19a4xc2XHeV+d2z/C1HD6WpNfc1WofsWSuvA6MxBEky7u2N3Asw4oMa6Q4CWLEhoME+hMkCBDkIYoyAjhAgPxLAsR/EsCRTQqIrURJrMgy1+uHokCIDS0HWllaecn17vLN4XBefU/Vlx91zrnn3h4uONxpSVHmAmTPdN/uvreqTtVXX1WdAXaP/ycP2RXB7rF77B67x64v35UdAID3+yFhV467hvydooBdJewqYff4NvNdpCyeQzh1zL/nqWe3GazOfWuEcuHCeTkP4PjSVZ47t2iA8D5kyW+ZVhfPsjlLNt8pVrp49myzuHi2uQeDlcG/t7QCZLtaXDzL5lMfEWV618HFF4/89AcefXrhSHgXwCdCIw8G4V6x0ASBmAEWDUHAtlUEBNBMNBpopCmFpgQAIwRUUAkIQFMBCTOlmAEgohpgJkGEgKJtJ2C7iaZpYKZQjQgwgApTBQmqtiICME5gMZLUVZheiTF+/eaNq19+4Tc/92Usf+YmAIgIPvShDzXnzp3TnVoNslOuhoCIiAGQnz975/0nH5r/2XGD5+bnRydGDdBuAnGiaCctrI2gGWAGNQNVoWowM9AUMEBVESctAMBMQVOQ8EdT0AjSHwECNKgqQP8MjS3MFAJCY+ufm14jCQFhsQXpCgGtCGPUNBAJboFmb2xM7POXr1z55B/++j/5DACePs1w5ozwTQS7lVw5EwWkizEA+IVf23j/44+P/vmevc274zqwcuUW7ty8HSebEzNtYRqhMQoturCpgBqiRZCEmcFUgdiKgYyxBc0gVKEpjKCZwkxhSjB9hjAKCVpWZowAsoIiqEmxIAAVkKRq9xytUo6RNAQRNKMm7Nm7b3Tg4IOY23sAk9a++Pqli5/44qf/5WdEBPzYxwLOnLG7eA6ZuQIWz7I592HRhR965fDf+aWH/vV3nxj/3MZNxbVLV9uNtVXQJgHaBphBGV1ANEDNFUFC1BCF/lobhVS3ZBg0GoEopgRJAiqmCqPBYgTpAjcjScLUIAKoxr5Q1a2cNAAqVKWpv18A/xwXflopBOA/myph0UajEQ4fPznet3ACK7dXf+Wz/+Ef/30Aq1hcbNB3SbXrlpkpIAv/R/7Z1Xc885OHfuPQwuidry5dbzduL0uQSWBsJWokNYqQiFTGGNPNubAsqkAVBvfljFEMBpdFFJolpamokqYGIAqNtCxgjWJGmmq5zyxcf71NrqRTGGmwnqA7BSAZCamA+Wd4zDGoTmxubo7f/di7xsrRl37v9z/70zcvfPYSTp+uV8IwdsqOKyC7nWdOX33ncz956PNzoXno1QtvTERXxjB3NbSI1pQwQzCK0thqBNQEJGISLjQKAdIUFhXGKBqNNAPQipn79uS6XTCkuyoSQCs0hWpaJFmQJMhWkpsjwErQ2T1pZfFI151XigGg0DUPkPBobdDYtiefeGqeYe/Xv/D853/01jd++yL5sQCcse0qIGxf+KcDPg6886OvHv3h5w5+ej40D1268NoEdnvEuOnBTyNMDYgqMINRYTEK2yQsmvtyjTAaaVFMXdAajf7+iBjNz4nm1m/+fkvB1s9TxOgrgHGSgri5xadgnWNLFr7l11yj/np2Qek5kPC1mmNNUhoNMgrji3/yRxObLD/xA+9+z38muff06Y/fDTlyR8m4p576uJwRsZ94/5F/d/Tw3J+7dOG1iWB1pHETMQk/svhYqkW0NKq6L1YzqCmQgqlGg0UPnFmgppqUoTTzwOmBW1kE77/DMoqx2HclNEdKmt6Tg3dSoBWhehAu7wGFoNA8VtFMCIJIhkQ3nDAajf7s5Qub8yP7gfd84B/8qzNnxBYXF8Nd8oK7KqHZrt8/82HRn/+Ptz/45Pfu/8TFL1+e6GR5pO0GqBGEgapCGiz5Z3V4Ak3CynZlqoCpuxhzBagqzNrKRSTBqUHExD2a+2dTq1wNiyshDBJUYOyCajJEIgmZDlJyPAAIakFEkhXtSkzXnM7LK8bfh2Z15Vo8fOLhd4f9D//OC7/163+KxcUGS0u8Vxe/rRVwdhGGUy/OfdfD439x+401rt++EbTdgMUJVFtobBHTo1qEkXTr1mSdJqJREFuBRSEjyFY0xhQkFWZMq8CfA6MA0YNwDpCWBK7RBZcCMGElNzCLJRhnRWWlQBLyycZQuaDko0BASBahIxmSn6flszfX17B68zUcO37sEwBw+tQpDtzPzrigZ07/zkhE+HP/6G0/9cCBPaeuXnw9AptBY5uCZHIbZlRTIEaJGqEawdgKzUABlWRUdatXKy7HkzArUNGMoD/STJhf73x1WmU0ECoF8/t5NBIQN8ACMcEkS/O0NikCfq6QEEtZNU1ZVgcII4TVKkBadSLSLF/7szhq8MxjP/gz7ztz5oxhcfGePcs9K+CjH3+WALBwLPyt9eVNxo0VWpyA2rr7SQICCFEVBzIGIcWxeBRLGa+qMbaW7jGCdEs3U5QEKUFCR4LuDiREgWlaGdn9WMkRiJThmnbKzMJi5fONgEVHWiwGSktCZwnChBUDNn8mB+mCqgwxTmyyfhsLBw//TQB45sqpe0aXo3ulGj4som/76y8cnhO8d/nKZVHdbJybcetSNYiaCAijQtNyF8Axu6nQPLiZWrFo0BBERS3C4yWRpOSegJ3ViyQhaoKJkjJb8wRWAFAgVM9mS/QTKYrIHsF/ZP+1pIz8v7Hz/UwuCLWCspKUYWP1Jpq9x54FMH7++U+098ql3dMKWDzn533fX3zy+0cyOrq+shxVo2h0JMIYJbsHVUV07JasQ0FT0eI+YrkZ0gO2uyJhsax0wzlA5/MtJmyIfKp1LgWEWbLQbLNGz5rNQHF/xLQaCsy0rJCkDBEp8cF1Ktnlkcmps/oe55XCxtoKoZPHjr7jRx73s07LjrmgUxc8mh85Mn9KQEzW75gkRlGjJ1A0hYI0i6A61xNbhbYRMZIayaikY/boGagfcISa/XOHu0VMBCaZuHNcUfl2CrIHsuxm1OjClh4QofkSEQEIcetOJmrZmklUcnVRk+RAsUWRYEZDMI0R4PjgvoPf41a7tHMKwLP+MN/gEcYWTqy50M0UkcaC32nUNkLblJAV3K1VwI0Sq+Br2cLT8rYi0EDSVwazp7Bu6RfheuTpQ46CwFmEDYifR5RHo68cV6q4ovJnSkftS/IotE7ozEsiv1VbQPCIx4ErsnMxIGs92lGdbKJYsBksxpTtGjM1bMW9OEOJ5CY6pEMSJmRa3d2Sd6wOc6Fk/x0EsJBeEycJKksVJIOXdI77k6QUSc8ndQlT7BAAAZJ+J4NQMk4SiEil6LvAej81uTu/PwEf3I5M70kBuZSolPnYTqBRIUJHI9omX+3WwMwuUuF0DYv/lIwioCLI1mfFElliQD+ZJAIohs6HaBEqJFsze16n+PQmQNgFTyIAARAKzFIgDwBMKQighAQeuqKWlXhjnTKKBXRxwYGB7NlxBVSrmqoK1dZXrLYCKjxJyq5BnKOHF1BULcNsXzXI8DE4OhJf2hIgkIZkcLQROlTiK0DcJQggocn+yM8rGaoWdCIAEPLv6lKkuaMSTRierkiLEIg/hnEi9GKCA1npUlIAqYXODlXlhG7HFXDhvN8PY0trzFeAGQijpKRJc5GkzgKZfGa62CAmEgAywDRAgltuAMRXAIQaKKMmB858p5CGaIiSTAmZYrH6wjImKjm75CovSTmBZAhp0X/WCDACNnIuSRvQIjzN8DuRwEJk+AqQfEngVjlvDhAzcUHGYCn9N1MEieI42C3dkY27hCxAkkAISSRC0IQIRHD/LhCQLcA5UgkZ+fMhuBcwI8wC89LPbkx6gMSlEdgpJ1MSLJnrgPO3nDlHiG56PtMoTFsvR0bJuk0UB1JcyAuurI8+6enQdYddUGoPsagSEd0FAQW1xESSZdFnhEIwuY0ACV5nzSs3SEBogt+Q7CERMEr+lhSICCVQgMBodBwSpFh1nefk+GLmyut4fqCSmJcqUz0BqR4AcxpbtQWshU7Woe06dLIBnWykJgCDBPOcDFaJXbqcpLBRmIELOnZeUqRXXwEtIA3MjGQU04RoUuAjJLnNBs1oDpAADXPQZi9kPAdIA4YGaHxluIKCB/Lkc+m+ihBBg8r/Z1INhEio4kuyfCCthI5m8ARWEdLqLexmJvTiBJhsgO0GuLGCMLmFMFoFZAUyyYHYQCiGMKGKxU4vywxcEM77g7YtLJfwBDD1YOt0QVqeISAECqWBNGOG+f2wPYdx9PhDePDwAxiPx2AzQmgaBHGsnfOmjDzNnS9ghtEoK8af8mDn1angiSsKeyE5TwCCmwGU/ugl0JgQXNVdoV621NhCJ5uYrG/gxq07uPanX8Fc8xratQa2ppDQQiwk68+5RIeIsrudyQroQ1+vXIk47kUi3dQsoZMAY2Bo5tDM7wcWTuIHT70dB1dfxqtf/V2s3r7ptYCUJLEEaod+OY4J6qw4UWLZshPtgES8mZq7swQGUgCq8g8tENdy+0tV4WLC8KaK8Z49OPrIu/DQn38fvvonC7DLS7A4Aa0FpC0JW6/8m+7B8xyGmSnArJXC00uTqlBeFCcJYUhVpQZoxtD9J/C+p96G61/4VfzGb30ad27fRNS2cwOJiyk4g+xDuyLITIyxJEiFNmbF5aD6Obsf2hRcqb8zK6kEawANPoW/8N4fw2M/+g/x0voKrF2DthuAbnbCF3E4WkPlnAvMSgHaKpROH4TkgsxxnQCBRnpeIwFR5vHYo4/i9d//JH7zP/1bNI1khCb5qrO1B5EiAMfpKcwSoLccISBnrIQIEXKeIP3EFEShLfx9oeJx0ouhIvTAAlyKAcgIL3zuv+CvHH8cx97+Qby2/CrCaAXSNpDgULXz++naSwUOOx8DzneEOXMQVmkSJVEWIQjze5MGsncB+3QZf/j5c2jbTZgFT34qe8xWq4Xk7NPBYMXtsMPhteX3zmON2cuTPQJt6E4zYGOqgjmjDWnG8/jaH/8evvd7/ipkz2GE9esQGRVqI6Xb5bt62fDsYoCxdCVUnXm0BM5C488EQTO/H+srN3Bn+SZM2+RJbMCQ34VlrHA+i4A7gXLYdMBOmR1HxM5LS86cBlQFakTbuS9L17W2cgNghIz3A2FUEF4RODpysDObWeQBhYyLjTVWuBIW9jJlANIkeQS/YHiNOLYThICq0lQ1y5B9Ky++WHpuonsdKVhzkA5wahX003IMOgbZaVi6BCrr3lLtOTSjZFjB4bIkSFyy4T4ONcPsFKBAajdhYiy149BDkzgASYmUUw3aTmAWAUq/kFFXpnq/T6+I+mcZVrqNvfUkThP2qeL0UlZe3y3liDPIZ90YxG0hYFhf6GuXpWhZ6hYzQUFtaxa8HmsV9s0A3RtpLQclMfUWQlMDAgaIBVM3wMqfi3R8TO8aKo6UnFKUcNCIkLyDsJelbx0Tat6xFGjSt4lUdYiqcJP1Qdi2hb99BcSJ2EhT0bt2GwYJI0ASj2/OnogApqkRqwM/U4Lv3McwFvT9MyrambUABy5LBP0yY+WzZavVtWU/m1uCDCxfqsK8SB0Hcu1ipolY6hiOLaR8U64UKRCaxL2zCKt0KKQkawqTT7ll9pXVc0E2cN/V68Ipqr4wqjVv1NNDKUOX2nxF8CUy0Erwrf1+EbwNWn9shgqI2kJTUd2XpHlVUxLGVwWCVfVS9tDJFJJhHQZr6+2Cb068utdlOjaAkMzXb9mIUN5PmRr4YgkvzPR/r7VWqjKk9BPEquEiZ/UzXQHUyNAwce05CXJaQEKA0dCU9j8gZn7E2C+wdJGxR9/mWSTeJQhP/87s3hP8Y50WbIlGWLKxQdpR/VYqbMVDGtJ0SNW821PtvTTB7YALSkV4aoQgODHHUJUHM9fugVdqzFJDtqlAyKr8dy83UePPnjCnk7P+F27h7Yf5ACQvAQ7ilLGrePUrYlLcpphxdisgOCPq/h5emKH7fkAQGudsQuqvF+kSKw5dR6auuVUX9zAwbBFgBxKuBD8gKHrpV4VburatfHkk6m6t7trR0duSE7VaARW8ziHg+dlwQW1gk8t6fhkSGjGfD4JJg2As2UxiB6uLxLQSpulWdLciNdvSz8UqSXNrxdVPy/TEVkcmy9C11VlbmrLpOiSqeiRzkLdSLbOoO78Cjj/lfaHaRiGctg2BiYvXhCIksZaGkGa4fKSIfciYW0jYT65QB9vEx2QZbOGWOiVA0MOywr7V9xuttkikRDhtCbkylObLqrLmVnlEdq+cUR5w5cJ5KTA0J2AiyR8KIQFGisAQPFp5qa8OWtKRVwMLrHxtEYX0266GiUNt99U6kEroMu3Ypr1S+bnGqQLJ7o7IhTmmtnTke0LXLFHXiGdMxol5y0mujxJA8FUAASTNUyXh1+TaEPrxzaPrMFQPu2N6Jkwyhxip4zPv8rl3HV5kqQlJ/tWiAtqWAg9Qlzsre0DJCWZZkFGjaOGCyMzRA6AQkmqu2nUeVERqohik5qOBfgK0pd2ya5KrF4Wwp4Sh9x8qLfmrLbIAqUi4qtTiFqfeKUFqx97mIg4HMWHWMJS0kOesfG2iEHDIM7sSU+9o69UB74TAsAZQhMQtgfowMx12Ata+CB05SrlLVzj7/02pZss2tBAaBBAWN6uhP+0ARWlZZ2Udsi0ftK3lkgcSSkE799pYNwRH+mhQu3oTsudBHDp6AqoREjpn+WZQnxVFkLrFp18eYJrOqIV9F9PfMyN/nkgHZ2svknoDGIK3Jx4+8Qgi5sDJSv+ey+CH9VjcxIbKzBTQTZ6g8Dw5MSujodrC4gS2eg031wVP//gvYgxl20aSgtI6nns6U5Ns10griXt3WrsDT5IQi+S2felaWLKmclt69y+RoZL+Vc9L9Rbpii0QmUwmsvDAXnniL30EV69cAScrMJ10M8W52F9a2m2LVrkZwFBq2xhigmNSEVHBPY3Rdx2RVchoHrcuLmHuyZ/Aj//iL8v/+W//BjeuvuEzY6l2XCDp1OrvcqXeApA6zrJCIyKss7Rh/tVvo+stoF5hRwKapsGDjzyBp//y38UNPITVy/8LFtdgMU2CWoV0BrQEAJjMoCacYahATAorGSr+o5oeMYXETWDzDuTOG7j8tT/CsSc/gPd89Icxuf51tJMNhODURQghd8u5zx01uaLrBR2pu978LoM3A/nvtMKg2aAkiVofeczI/HNCIg/zZzC1tsAUMprH+ODDuHprE7df/t/Q9RuIm6vempK66mjd5h89QAIBFLNDQQqvqpdidMWLeOwJxTpssooIoDHi9RevY7xwEnMHnkQ4sA8yGnc9nCKuEJ9CdErArIJ1vjeQtwZ1GbWMUutjmu8V9JnSPMKEMm/siE3GXje0qJAGiThsoYggJ7C1DWxcfglcvwqdrCBu3IJOVn1rG+36iOpZsY6Ss1nlAakvQqOoxN4gtaSqN4WlZ4naurVphLYbkPF+SLuK9vo3IKO50l3WmajPVYt0jU5dId6SzC11uCVoKyHtgNJR3iJACA3yzillkhLVZGPlrwU+lQNr0zVrepzA4gasXYe2a7B2s3u9NHkNmgaKK5LZ1YRBC8hQTDqCLPXDAGJgCPBBB++7hEag3YSGMaSZg4SRB1cJuYKUzDYUd+wlTeuqTGkmOPW2d9xQLwhqF1hLA1dXROp2QmEK1aysWUGdpDp3BHXi2F83PabppIzidsMeqQTJaiJfgNCIzVIBZd7LfXeuDKXxnDQ4kXuTRNIeDhBQmtQh3cBqNBKawieX5t7ehhlSqmHs4e1BvxCt6lLoAkDZDyjvKVGoEOv2FKJWO2olJJdmB/x3LYryIZBqP4qq8y61J86Ajj6fK2JRLWjCIda1CBZmUDsWJ7eJF6jpVs8KHtbdBvVcQ25U6BXSRYRGn//tVrnkmWLkNpl+vbIIu8bvHZBgiRGolGCWVm6Zrs8bgmjXHs9hxS8Fc4szcEHPJoLbFAgVt1Oywsz7SMUISifMaoKRhcfcKlnK4kvZMxWW9+mp6HqriwjVXFneC66XVVeWWvaKY7fPnKOaweR9ntQnyn5yOfDmCfmu0GRT5OLsVkCcBErXnFvzIXmCkTV4HPBcxVqsn9a6qw/FhXTdBtbVZVPX01aVqpplHTZ6dZlqt7NKh2DSzlg1uVZv6tFTnjrhVA/8Uaen642zq4ipths2yjehKLWhuq9nq9oGawuVLfl5DjoOhsxp3WiVP6c3fsR+YC6AqkNS2Qw6a5YBsVbtAVFoBuvcVzclyar9nVUbDADo2nZKYtusiG1e5fzIbyhNPda+sMdrdbsKTLPvRCneeNNT6PtTSJl26b237HKIfm9Q8cNdnsDUUWFFmChJXi97rTby6AfVakaBsVo9Xfxj1TovyXUaeW12dPTm2iXuO5hqvFVLdh5+qJsL6r6T3CfUez1ZWq/nhv02PwyY0TKoYT1rL8We2o2klCi7sWEnHarrzlvPdO0rtVvzkRz6DFYvl+idJ0HMiHZt/WKqCnPHFPD8cd8Bavna6y8dXDgAaZpgOhlcxIC8LyW8qiWxigPlPOPUnFXmmKRk3TI9gFH15uQtDFCNKWEQB6YmSJl3c2GPrui7lxK4pbgyVM1YnctiMzceqbXra2vXXsKbFePuawWcO2cAcO3iF758/OTbro9G80fZbiiQrcLBe6mLFovM4/vZjIH+JEx/lUy3LqJM2U8hjar9HMPJmpwZT/URWe889BI67SOnwUroB+/OGBKisjCab2K0r2Lj1qVU0rYtiwwDxdwrccTFxbMNli/e3Fi788J472EaVcsFWppSR1rGpoPiBQuSyCVLDBKaMrVIhVALLu9qEOmf9p8v0+nlOS3Q0Tf2K1ufdUUVWvX5eXs0JasNmzq+p9vJq5tXI7odWpwnCc1ebE7Wfts937PNm5Y7quOet9ZaOnalwSuv2GjhZNx36PhHuHHTaBqSVUqNjVlViljj5LJVZGpp6WHpuoGrHnxAbtgvNy7oQ0n/PKtmtFhQS/cd1XN1wM0rw0xAH/VMY/eCXjc0K1hlUndKN+O9gWFsqzde/3vWrl4BXrlnF7StrI2kiMj40ff+7S8tHJh/auPWpZQQdBZSN2Pl3iBJM2A0mxpo6KiHLcqVNa5n1/ZUmM5B4O4TZBnRdEVOor8nqPS+o36Ng1hBkiYyJN88WYx7D52cu7Oy/F/vvL70U8DpvIHrPR3NdpRyZmmpwdJSRDh4+YFjj34EcUWpGsh6R1q7S0cze/2WvRiQISmr/R1QuS7r3JSw9uVW/aw9S0feQMJ/lj40tqq5sCq7FXRVfUcXs6RuLgYEZsq5vQ/AMMKtN77xN2CbbwDPh+1U57f3RxaWlojFxWbzD/77kuw5+vTBY29/V1y/3pIMg57xyj2wR1ahh5o44FusH6RRv9/6vaU26DEacvMZ5fR5jH7OkBYBq/f0Orm6butBi5LzTs1oPs4dOD63fP3VX9bVK78KLDbA0ra2S9n+X7lYWhKcPi2r5/7950YLj/7MgUMnjsW1Gy3gVZVacLV36K+OQR21xuOc7rsZopEu3gD9cdOp1E22piTq7Sorg6gUWBtJ6YDIjUMkREK77/DD8ys33ji/fv3lXwAWBTi37da4+9093Utfc0ff+fDTP3b+0KGFE2s3vjGh2kikFmTF5wzmBTAc9a8xfW8MiFUSNT1X1uc92O9aG3z28DxONxMNrhOYHpc1SDPX7jt0cv7O8rUXb7/24jMAb5burPsQ5P0cBiw2mFz/yqt//D+fu3718svzh94+18zviWZqVpKnrsBSz9LWQq6Fxm6gq2Svgv5ndH6un/nWO+H2rLbOzKd6+uv8okd9pNqW0yQdsWQ62vOAzi88PL988/IXb7/24nMAbnQnbP94C39oZ4nAYgP70uU7l1/6tRgOPL534aHvm997IGjcjBYnLNs+5vZk3q1zTbqiNqRM2taUtWzRKdenvPPzgt4sZGZSpd8dIYJe60rhPKouUxHfxA+ANeN93HPwu8YM883KtYu/sn71az8L4GavEH4fx078DZlyAc2RxxYfPPHkP92/cOT7m0a8MD9ZU2qraUvJzsdPLfvhZlODUdNeFl1ByMqC++NPVrryCmTtDQ9Mu6+KQoU0DUIzbprx3kbG+6BRsb526w/uXHvll7B5+3+ki3pLwt8pBWQTdqgNjOaOPPbB/Ucf+Wt79uz7odFo7sRobo/vdVjqubmzuqaDq0pXtTlH6eWR4URK7YbqP9vCCihlGqT/ciH0yiWnGbdSoXOmN7abiFEvTTZWf3ftxmufxOTmZ/zDF5sUcPnWBbejx2Ij8imtLOsI9hw7NX/g8DtG4/EjIuODIUiDkIlQpi20fCuz3GBR7XmWYUraMIoE2IT055r8z1UZgZB2T+ndE4txWh7qDKmwDSDQh9pCKO2Evr24tSBvabt5sV1dvoB4+ysAVioqp0mcy7ftIcBi4zuIfyf8aUVJFo9mVp8+66sPwDP+Pc+8hU96/pst+OdR2v6+lX+WcPfYPXaP3eP/70O+id/zTUcN4dtUaPIWhCP3eT6/FYqQb9LncoevkW9yziAju+/v3EU+u8fusXvsHrvHTI//C96TiMaJ4fu7AAAAAElFTkSuQmCC"
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

$lblPrivacy = New-Object System.Windows.Forms.Label
$lblPrivacy.Text = "Your files stay on this computer.`r`nNothing is uploaded anywhere."
$lblPrivacy.TextAlign = "TopRight"
$lblPrivacy.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 319),14)
$lblPrivacy.Size = New-Object System.Drawing.Size(230,30)
$lblPrivacy.Anchor = "Top,Right"
$lblPrivacy.Font = New-UIFont 7.3
$lblPrivacy.Tag = "muted"
$top.Controls.Add($lblPrivacy)

$lblCredit = New-Object System.Windows.Forms.Label
$lblCredit.Text = "Created by David McCabe"
$lblCredit.TextAlign = "TopRight"
$lblCredit.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 319),46)
$lblCredit.Size = New-Object System.Drawing.Size(230,16)
$lblCredit.Anchor = "Top,Right"
$lblCredit.Font = New-UIFont 7.3
$lblCredit.Tag = "muted"
$top.Controls.Add($lblCredit)

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
    $b.Image = Get-IconImage $iconName
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Location = New-Object System.Drawing.Point($x,$y)
    $b.Size = New-Object System.Drawing.Size(40,40)
    $b.Tag = "choice"
    Enable-RoundedPaint $b 10
    $parent.Controls.Add($b)
    $script:appToolTip.SetToolTip($b, $tooltipText)
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

$rbModeBlur = New-ToolbarIconButton $modeRow "blur" 10 0 "Blur"
$rbModeBlur.Checked = $true   # Blur stays the default mode
$rbModePixelate = New-ToolbarIconButton $modeRow "pixelate" 10 44 "Pixelate"
$rbModeBlack = New-ToolbarIconButton $modeRow "black" 10 88 "Black Box"

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
    if (-not $videoPath -or $totalFrames -le 1) { return }
    $w = $seekBar.ClientSize.Width
    if ($w -le 0) { return }
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $x / [double]$w))
    $newFrame = [int][Math]::Round($frac * ($totalFrames - 1))
    if ($newFrame -eq $currentFrame) { return }
    $script:currentFrame = $newFrame
    $script:previewSeconds = $currentFrame / $fps
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

    $frac = if ($totalFrames -gt 1) { $currentFrame / [double]($totalFrames - 1) } else { 0.0 }
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
    # the right-hand cluster (privacy+credit note / theme toggle). There's no
    # single Anchor setting for "stretch, but stop short of that other
    # anchored control", so their width is recomputed by hand here, from the
    # same right-cluster offset $lblPrivacy/$lblCredit's own Location uses.
    $rightClusterX = $form.ClientSize.Width - 319
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

$lblBufferNote = New-Object System.Windows.Forms.Label
$lblBufferNote.Text = "Every redaction is padded automatically by $BUFFER_FRAMES frames before and after the marked range."
$lblBufferNote.Location = New-Object System.Drawing.Point(0,102)
$lblBufferNote.Size = New-Object System.Drawing.Size(325,34)
$lblBufferNote.Font = New-UIFont 8.0
$lblBufferNote.Tag = "muted"
$right.Controls.Add($lblBufferNote)

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

Add-Rule $right 0 142 325 | Out-Null
Add-SectionTitle $right "Redactions" 0 156 330 | Out-Null

$lvRedactions = New-Object System.Windows.Forms.ListView
$lvRedactions.View = "Details"
$lvRedactions.FullRowSelect = $true
$lvRedactions.GridLines = $false
$lvRedactions.MultiSelect = $false
$lvRedactions.Location = New-Object System.Drawing.Point(0,188)
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

$btnRemoveRedaction = New-Object System.Windows.Forms.Button
$btnRemoveRedaction.Text = "Remove Selected"
$btnRemoveRedaction.Location = New-Object System.Drawing.Point(0,336)
$btnRemoveRedaction.Size = New-Object System.Drawing.Size(155,34)
Style-FlatButton $btnRemoveRedaction
$right.Controls.Add($btnRemoveRedaction)

$btnClearRedactions = New-Object System.Windows.Forms.Button
$btnClearRedactions.Text = "Clear All"
$btnClearRedactions.Location = New-Object System.Drawing.Point(170,336)
$btnClearRedactions.Size = New-Object System.Drawing.Size(155,34)
Style-FlatButton $btnClearRedactions
$right.Controls.Add($btnClearRedactions)

Add-Rule $right 0 382 325 | Out-Null
Add-SectionTitle $right "Output" 0 396 330 | Out-Null

# Format and Quality sit side by side to save vertical space. Format's item
# list and selection swap between video and image extensions in
# Apply-ModeLabels (mirroring how $cmbQuality/$chkAudio are shown/hidden
# there already).
$lblFormat = New-Object System.Windows.Forms.Label
$lblFormat.Text = "Format"
$lblFormat.Location = New-Object System.Drawing.Point(0,432)
$lblFormat.Size = New-Object System.Drawing.Size(150,22)
$lblFormat.Font = New-UIFont 8.5
$lblFormat.Tag = "muted"
$right.Controls.Add($lblFormat)

$lblQuality = New-Object System.Windows.Forms.Label
$lblQuality.Text = "Quality"
$lblQuality.Location = New-Object System.Drawing.Point(175,432)
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
$cmbFormat.Location = New-Object System.Drawing.Point(0,452)
$cmbFormat.Size = New-Object System.Drawing.Size(150,30)
$cmbFormat.Font = New-UIFont 9.1
$cmbFormat.Tag = "input"
$right.Controls.Add($cmbFormat)

$cmbQuality = New-Object System.Windows.Forms.ComboBox
$cmbQuality.DropDownStyle = "DropDownList"
$cmbQuality.Items.AddRange(@("High quality","Normal quality","Smaller file size"))
$cmbQuality.SelectedIndex = 1
$cmbQuality.Location = New-Object System.Drawing.Point(175,452)
$cmbQuality.Size = New-Object System.Drawing.Size(150,30)
$cmbQuality.Font = New-UIFont 9.1
$cmbQuality.Tag = "input"
$right.Controls.Add($cmbQuality)

$chkAudio = New-Object System.Windows.Forms.CheckBox
$chkAudio.Text = "Keep original audio"
$chkAudio.Checked = $true
$chkAudio.Location = New-Object System.Drawing.Point(0,490)
$chkAudio.Size = New-Object System.Drawing.Size(220,26)
$chkAudio.Font = New-UIFont 8.8
$right.Controls.Add($chkAudio)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export Redacted Video"
$btnExport.Location = New-Object System.Drawing.Point(0,524)
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

    foreach ($c in @($cmbQuality,$cmbFormat)) {
        $c.BackColor = $cInput
        $c.ForeColor = $cText
    }

    $chkAudio.BackColor = $cPanel
    $chkAudio.ForeColor = $cText

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
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
 
    $isBlackBox = ($r.Mode -eq "Black box")
    if ($isBlackBox) {
        $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
        $shapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,0,0,0))
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
        if ($pts.Count -ge 3) { $g.FillPolygon($shapeBrush, $pts) }
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

    $tmp = Join-Path $env:TEMP ("TinyVideoRedactor_" + [guid]::NewGuid().ToString() + ".png")

    # Runs ffmpeg to extract a single frame at $targetSeconds into $tmp.
    # Pulled out into its own scriptblock so the caller below can retry it at
    # a slightly earlier timestamp on failure (see why just past this
    # function's definition).
    $tryExtractFrame = {
        param([double]$targetSeconds)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $ffmpeg
        if ($isImageMode) {
            # A still image has no timeline to seek within - just decode it (via
            # ffmpeg rather than System.Drawing so formats like .webp, which GDI+
            # doesn't understand, work the same as everything else here).
            $psi.Arguments = "-hide_banner -loglevel error -i " + (Quote-Arg $videoPath) + " -frames:v 1 " + (Quote-Arg $tmp) + " -y"
        }
        else {
            # Hybrid seek: coarse-seek (fast, keyframe-based) to ~2s before the target,
            # then a small precise decode-based seek for the rest. This keeps single
            # frame stepping accurate without paying the cost of decoding from the
            # very start of the file on every step.
            $coarse = [Math]::Max(0.0, $targetSeconds - 2.0)
            $fine = $targetSeconds - $coarse
            $psi.Arguments = "-hide_banner -loglevel error -ss $coarse -i " + (Quote-Arg $videoPath) + " -ss $fine -frames:v 1 " + (Quote-Arg $tmp) + " -y"
        }
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stderrText = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        return @{ Ok = ($proc.ExitCode -eq 0 -and (Test-Path $tmp)); Err = $stderrText }
    }.GetNewClosure()

    $result = & $tryExtractFrame $previewSeconds

    # $totalFrames is only an estimate (Get-VideoInfo parses fps/duration back
    # out of FFmpeg's own printed text, which can be a hair imprecise), so the
    # very last frame or two can occasionally compute a seek timestamp just
    # past what the container actually has - that's what produced "FFmpeg
    # couldn't extract the preview frame" when dragging all the way to the
    # end of the seek bar. Rather than surface that as an error straight
    # away, nudge the target a little earlier (in whole-frame steps) and
    # retry a few times first - the user asked to see the last frame, not
    # that exact millisecond, so a frame or two earlier is a better outcome
    # than a dead end.
    if (-not $result.Ok -and -not $isImageMode) {
        $frameDuration = if ($fps -gt 0) { 1.0 / $fps } else { 0.04 }
        for ($nudge = 1; $nudge -le 5 -and -not $result.Ok; $nudge++) {
            $target = [Math]::Max(0.0, $previewSeconds - ($frameDuration * $nudge))
            $result = & $tryExtractFrame $target
        }
    }

    if (-not $result.Ok) {
        $status.Text = "Couldn't extract preview frame."
        [System.Windows.Forms.MessageBox]::Show(
            "FFmpeg couldn't extract the preview frame.`r`n`r`n$($result.Err)",
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
 
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    $ms = New-Object System.IO.MemoryStream(,$bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    $script:previewImage = New-Object System.Drawing.Bitmap($img)
    $img.Dispose()
    $ms.Dispose()
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
 
    $picture.Image = $previewImage
    $picture.Refresh()
    $script:loadedFrame = $currentFrame
    $picture.Invalidate()
 
    $status.Text = "Preview loaded."
}
 
function Step-Frame([int]$delta) {
    if (-not $videoPath -or $totalFrames -le 0) { return }
 
    $newFrame = [Math]::Max(0, [Math]::Min($currentFrame + $delta, $totalFrames - 1))
    if ($newFrame -eq $currentFrame) { return }
 
    $script:currentFrame = $newFrame
    $script:previewSeconds = $currentFrame / $fps
    $seekBar.Invalidate()
    $lblPosValue.Text = SecToText $previewSeconds
    $lblFrameCount.Text = "Frame $($currentFrame + 1) / $totalFrames"

    $previewTimer.Stop()
    Load-PreviewFrame
}
 
# ----------------------------
# Events
# ----------------------------
$btnOpen.Add_Click({
    Stop-Playback
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Video or image|*.mp4;*.mov;*.m4v;*.avi;*.mkv;*.webm;*.wmv;*.asf;*.mpg;*.mpeg;*.mpe;*.vob;*.ts;*.mts;*.m2ts;*.m2t;*.flv;*.3gp;*.3g2;*.f4v;*.ogv;*.rm;*.rmvb;*.mxf;*.wtv;*.dv;*.mjpeg;*.mjpg;*.mlv;*.r3d;*.jpg;*.jpeg;*.jpe;*.png;*.apng;*.gif;*.webp;*.bmp;*.tif;*.tiff;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|Video files|*.mp4;*.mov;*.m4v;*.avi;*.mkv;*.webm;*.wmv;*.asf;*.mpg;*.mpeg;*.mpe;*.vob;*.ts;*.mts;*.m2ts;*.m2t;*.flv;*.3gp;*.3g2;*.f4v;*.ogv;*.rm;*.rmvb;*.mxf;*.wtv;*.dv;*.mjpeg;*.mjpg;*.mlv;*.r3d|Image files|*.jpg;*.jpeg;*.jpe;*.png;*.apng;*.gif;*.webp;*.bmp;*.tif;*.tiff;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|All files|*.*"
    $ofd.Title = "Choose a video or image"
 
    if ($ofd.ShowDialog() -eq "OK") {
        $script:videoPath = $ofd.FileName
        $ext = [System.IO.Path]::GetExtension($videoPath).ToLowerInvariant()
        $script:isImageMode = $ext -in @( ".jpg", ".jpeg", ".jpe", ".png", ".apng", ".gif", ".webp", ".bmp", ".tif", ".tiff", ".tga", ".dds", ".exr", ".hdr", ".dpx", ".jp2", ".j2k", ".j2c", ".jpc", ".jls", ".psd", ".pcx", ".qoi", ".avif", ".heic", ".heif" )
        $lblFile.Text = $script:videoPath
 
        # ffmpeg reports width/height for a still image the same way it does
        # for a video stream, so Get-VideoInfo is reused as-is for both - and
        # unlike System.Drawing/GDI+, it also understands .webp.
        $info = Get-VideoInfo $ffmpeg $script:videoPath
        $script:videoWidth = $info.Width
        $script:videoHeight = $info.Height
 
        if ($videoWidth -le 0 -or $videoHeight -le 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "I couldn't read that file's dimensions.",
                "File error",
                "OK",
                "Error"
            ) | Out-Null
            return
        }
 
        if ($isImageMode) {
            # A still image (GIFs are treated as their first frame - this app
            # has no notion of per-frame redaction on an animated image).
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
            $script:videoDuration = $info.Duration
            if ($videoDuration -le 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    "I couldn't read the video's duration.",
                    "Video error",
                    "OK",
                    "Error"
                ) | Out-Null
                return
            }
 
            $fpsNote = ""
            if ($info.Fps -gt 0) {
                $script:fps = $info.Fps
            }
            else {
                $script:fps = 25.0
                $fpsNote = "  (frame rate not detected - assuming 25 fps)"
            }
            $playTimer.Interval = [Math]::Max(1, [int][Math]::Round(1000.0 / $fps))
 
            $script:totalFrames = [Math]::Max(1, [int][Math]::Floor($videoDuration * $fps))
            $script:currentFrame = 0
            $script:previewSeconds = 0
            $script:loadedFrame = -1
            $seekBar.Enabled = $true
            $seekBar.Invalidate()

            $btnRefresh.Enabled = $true
            $btnPrevFrame.Enabled = $true
            $btnNextFrame.Enabled = $true
            $btnPlayPause.Enabled = $true
            $btnPlayPause.Image = Get-IconImage "play"
            $script:appToolTip.SetToolTip($btnPlayPause, "Play")
            $lblPosValue.Text = SecToText 0
            $lblFrameCount.Text = "Frame 1 / $totalFrames"
            $status.Text = "$videoWidth x $videoHeight   |   Duration: $(SecToText $videoDuration)   |   ~$fps fps$fpsNote"
        }
 
        Apply-ModeLabels
        Reset-RedactionState
        Update-RedactionButtons
        $btnOpen.Text = "Change Video | Image"

        Load-PreviewFrame
    }
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
            $script:previewSeconds = 0.0
            $lblPosValue.Text = SecToText 0
            $lblFrameCount.Text = "Frame 1 / $totalFrames"
            $seekBar.Invalidate()
        }
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
        if (-not $polygonActive) {
            # Starting fresh discards any previously closed-but-uncommitted path.
            $script:polygonActive = $true
            $script:polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.Point]
            $script:polygonPoints.Add($clamped)
            $script:polygonMousePos = $clamped
            Update-SelectionFields $null "Selection: freeform started (1 point). Click to add points; click the yellow start point to close (need at least 3)."
        }
        else {
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
 
    # Rectangle / Oval: drag-based, as before.
    $script:dragging = $true
    $picture.Capture = $true
    $script:dragStart = $clamped
    $script:selection = New-Object System.Drawing.Rectangle($dragStart.X,$dragStart.Y,1,1)
    $picture.Invalidate()
})
 
$picture.Add_MouseMove({
    param($sender,$e)
 
    if ($toolMode -eq "Polygon") {
        if ($polygonActive) {
            $script:polygonMousePos = Clamp-PointToImage (New-Object System.Drawing.Point($e.X,$e.Y))
            $picture.Invalidate()
        }
        return
    }
 
    if (-not $dragging) { return }
 
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

    $tiny = New-Object System.Drawing.Bitmap($smallW, $smallH)
    $tg = [System.Drawing.Graphics]::FromImage($tiny)
    $tg.InterpolationMode = $interp
    $tg.DrawImage($previewImage, (New-Object System.Drawing.Rectangle(0,0,$smallW,$smallH)), $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $tg.Dispose()

    $patch = New-Object System.Drawing.Bitmap($sw, $sh)
    $g = [System.Drawing.Graphics]::FromImage($patch)
    $g.InterpolationMode = $interp
    $g.DrawImage($tiny, (New-Object System.Drawing.Rectangle(0,0,$sw,$sh)))
    $g.Dispose()
    $tiny.Dispose()

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
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
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
    # current frame falls within its buffered export range, so scrubbing
    # back over an earlier redaction shows you what's covered where. (For a
    # still image, BufferedStart/BufferedEnd are always 0/0 and previewSeconds
    # never moves off 0, so this is simply always true - no special-casing
    # needed for image mode.) In image mode this shows the real applied
    # effect rather than a translucent tint, since there's just one static
    # frame to composite against.
    foreach ($r in $redactions) {
        if (Test-FrameInRange $previewSeconds $r.BufferedStart $r.BufferedEnd $fps) {
            if ($isImageMode) {
                Draw-RedactionShapeLiveEffect $e.Graphics $r ([System.Drawing.Color]::Lime)
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
        StartTime = $previewSeconds
        StartFrame = $currentFrame
    }
 
    $lblPending.Text = "Pending: started at frame $($currentFrame + 1) ($(SecToText $previewSeconds)). Move to the end frame, then click End Redaction."
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
 
    $bufferSeconds = $BUFFER_FRAMES / $fps
    $bs = [Math]::Round([Math]::Max(0.0, $pendingRedaction.StartTime - $bufferSeconds), 3)
    $be = [Math]::Round([Math]::Min($videoDuration, $previewSeconds + $bufferSeconds), 3)
 
    $entry = [PSCustomObject]@{
        Shape = $pendingRedaction.Shape
        X = $pendingRedaction.X; Y = $pendingRedaction.Y; W = $pendingRedaction.W; H = $pendingRedaction.H
        Points = $pendingRedaction.Points
        Mode = $pendingRedaction.Mode
        Strength = $pendingRedaction.Strength
        MarkStart = $pendingRedaction.StartTime
        MarkEnd = $previewSeconds
        BufferedStart = $bs
        BufferedEnd = $be
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

    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $base = [System.IO.Path]::GetFileNameWithoutExtension($videoPath)
    if ($isImageMode) {
        $sfd.FileName = "${base}_REDACTED$outExt"
        $sfd.Filter = "$selectedFormat image|*$outExt|All files|*.*"
        $sfd.Title = "Save redacted image"
    }
    else {
        $sfd.FileName = "${base}_REDACTED$outExt"
        $sfd.Filter = "$selectedFormat video|*$outExt|All files|*.*"
        $sfd.Title = "Save redacted video"
    }

    if ($sfd.ShowDialog() -ne "OK") { return }
    $out = $sfd.FileName
 
    # Oval/Polygon redactions each need a pre-rendered mask image (see
    # New-ShapeMaskFile / Build-RedactionFilterComplex); Rectangle redactions
    # don't need one and are skipped here.
    $maskPaths = @{}
    $maskTempFiles = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $redactions.Count; $i++) {
        $r = $redactions[$i]
        if ($r.Shape -and $r.Shape -ne "Rectangle") {
            $maskFile = Join-Path $env:TEMP ("TinyVideoRedactor_mask_" + [guid]::NewGuid().ToString() + ".png")
            New-ShapeMaskFile $r $maskFile
            $maskPaths[$i] = $maskFile
            [void]$maskTempFiles.Add($maskFile)
        }
    }
 
    $built = Build-RedactionFilterComplex $redactions $maskPaths
    $filterComplex = $built.FilterComplex
    $finalLabel = $built.FinalLabel
    $maskInputArgsStr = if ($built.MaskInputArgs.Count -gt 0) { " -i " + ([string]::Join(" -i ", $built.MaskInputArgs)) } else { "" }
 
    $progress.Visible = $true
    $btnExport.Enabled = $false
    $status.Text = "Exporting $($redactions.Count) redaction(s)..."
    $form.Refresh()
 
    if ($isImageMode) {
        if ($selectedFormat -eq "GIF") {
            # GIF has no direct high-quality RGB encoder - even for a single
            # still frame, ffmpeg's default fixed palette can band badly on
            # smooth gradients/screenshots. Generate a palette from this exact
            # frame, then re-quantize against it for a much closer match.
            $paletteStage = "[$finalLabel]split[gpal1][gpal2];[gpal1]palettegen=stats_mode=single[gpal];[gpal2][gpal]paletteuse=dither=bayer[gout]"
            $args = "-hide_banner -y -i " + (Quote-Arg $videoPath) + $maskInputArgsStr +
                    " -filter_complex " + (Quote-Arg "$filterComplex;$paletteStage") +
                    " -map " + (Quote-Arg "[gout]") +
                    " -frames:v 1 " +
                    (Quote-Arg $out)
        }
        else {
            # -update 1 tells ffmpeg's image2 muxer this is a single still
            # image rather than a numbered sequence - without it, some
            # ffmpeg builds only warn (and still write the file), but it's
            # not guaranteed and the warning is worth avoiding either way.
            $qualityArg = switch ($selectedFormat) {
                "JPG"  { "-q:v 3" }
                "WEBP" { "-q:v 90" }
                default { "" }   # PNG is lossless; no quality flag needed.
            }
            $args = "-hide_banner -y -i " + (Quote-Arg $videoPath) + $maskInputArgsStr +
                    " -filter_complex " + (Quote-Arg $filterComplex) +
                    " -map " + (Quote-Arg "[$finalLabel]") +
                    " -frames:v 1 -update 1 $qualityArg " +
                    (Quote-Arg $out)
        }
    }
    else {
        # WEBM can only mux VP9/Opus (it cannot carry H.264/AAC); every other
        # container here (MP4/MOV/M4V/AVI/MKV) uses the same H.264 + AAC pair.
        $isWebm = ($selectedFormat -eq "WEBM")

        if ($isWebm) {
            # VP9's CRF scale (0-63, lower = better) sits in a different range
            # than x264's (0-51), so map the same 3 quality tiers separately.
            $crf = switch ($cmbQuality.SelectedIndex) {
                0 { 24 }
                1 { 31 }
                default { 38 }
            }
            $vcodecArgs = "-c:v libvpx-vp9 -b:v 0 -crf $crf"
            $audioArg = if ($chkAudio.Checked) { "-c:a libopus -b:a 128k" } else { "-an" }
        }
        else {
            $crf = switch ($cmbQuality.SelectedIndex) {
                0 { 18 }
                1 { 22 }
                default { 26 }
            }
            $vcodecArgs = "-c:v libx264 -preset medium -crf $crf -pix_fmt yuv420p"
            $audioArg = if ($chkAudio.Checked) { "-c:a aac -b:a 192k" } else { "-an" }
        }

        $args = "-hide_banner -y -i " + (Quote-Arg $videoPath) + $maskInputArgsStr +
                " -filter_complex " + (Quote-Arg $filterComplex) +
                " -map " + (Quote-Arg "[$finalLabel]") + " -map 0:a? " +
                " $vcodecArgs $audioArg " +
                (Quote-Arg $out)
    }
 
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = $args
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
 
    $p = [System.Diagnostics.Process]::Start($psi)
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
 
    foreach ($f in $maskTempFiles) { Remove-Item $f -Force -ErrorAction SilentlyContinue }
 
    $progress.Visible = $false
    Update-RedactionButtons
 
    if ($p.ExitCode -eq 0 -and (Test-Path $out)) {
        $status.Text = "Done: $out"
        [System.Windows.Forms.MessageBox]::Show(
            "Finished.`r`n`r`n$out",
            "Redaction complete",
            "OK",
            "Information"
        ) | Out-Null
    }
    else {
        $status.Text = "Export failed."
        [System.Windows.Forms.MessageBox]::Show(
            "FFmpeg failed to export.`r`n`r`n$err",
            "Export failed",
            "OK",
            "Error"
        ) | Out-Null
    }
})
 
$form.Add_FormClosed({
    $playTimer.Stop()
    $previewTimer.Stop()
    if ($previewImage) { $previewImage.Dispose() }
})
 
Update-RedactionButtons
 
[void]$form.ShowDialog()