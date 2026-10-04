$ErrorActionPreference='Stop';$root=$PSScriptRoot;$out=Join-Path $root 'TRT-v2.5.0-Release-Build';$release=Join-Path $out 'release'
New-Item -ItemType Directory $release -Force|Out-Null
$base=Join-Path $root 'TRT-v2.5.0-C9-Package/TinyRedactionTool-Hardened-Embedded-v2.5.0-C9.ps1'
if((Get-FileHash $base).Hash -ne 'AC9640B796405FD13AA61DC32001EAC38DBB809DB662AA25B552BF8645BCD498'){throw 'Accepted C9 source mismatch'}
$icon='I:\#Torrent\TRT\icon.ico'
if((Get-FileHash $icon).Hash -ne '11B392E79197689035BE9876B762AC99E62CE37BB02E7939CED078C2C0D89B7C'){throw 'Supplied icon mismatch'}
Copy-Item -LiteralPath $icon -Destination (Join-Path $release 'icon.ico') -Force
$s=[IO.File]::ReadAllText($base);$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseInput($s,[ref]$t,[ref]$e)
$helper=[IO.File]::ReadAllText((Join-Path $root 'release-runtime-v250.txt'))
foreach($name in @('Expand-EmbeddedGzipTool','Initialize-EmbeddedMediaTools','Remove-EmbeddedMediaTools')){
    $old=$ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)[0].Extent.Text
    $h=[Management.Automation.Language.Parser]::ParseInput($helper,[ref]$t,[ref]$e)
    $new=$h.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)[0].Extent.Text
    $s=$s.Replace($old,$new);$helper=$helper.Replace($new,'')
}
$s=$s.Replace('function Expand-EmbeddedGzipTool(', $helper+"`nfunction Expand-EmbeddedGzipTool(")
$s=$s.Replace('$script:EmbeddedFFmpegPayloadGzip = Join-Path $env:TEMP "TinyRedactionTool\payload\ffmpeg.exe.gz"','$script:EmbeddedFFmpegPayloadGzip = "ffmpeg.exe.gz"')
$s=$s.Replace('$script:EmbeddedFFprobePayloadGzip = Join-Path $env:TEMP "TinyRedactionTool\payload\ffprobe.exe.gz"','$script:EmbeddedFFprobePayloadGzip = "ffprobe.exe.gz"')
$start=$s.IndexOf('# WinForms does not automatically adopt the PS2EXE assembly icon')
$end=$s.IndexOf('# Shared tooltip component',$start)
$icon64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($icon))
$iconBlock=@'
# Supplied TRT icon: identical embedded asset for script and compiled host.
$script:TRTIconBase64='__ICON__'
$iconStream=[IO.MemoryStream]::new([Convert]::FromBase64String($script:TRTIconBase64))
try{
    $assetIcon=[Drawing.Icon]::new($iconStream)
    try{$script:mainFormIcon=[Drawing.Icon]$assetIcon.Clone()}finally{$assetIcon.Dispose()}
}finally{$iconStream.Dispose()}
$form.Icon=$script:mainFormIcon;$form.ShowIcon=$true

'@
$s=$s.Substring(0,$start)+$iconBlock.Replace('__ICON__',$icon64)+$s.Substring($end)
Add-Type -AssemblyName System.Drawing
# The supplied ICO already has PNG frames. Preserve its 128px PNG directly;
# .NET Framework Icon.ToBitmap cannot decode this large PNG-backed frame.
$iconBytes=[IO.File]::ReadAllBytes($icon);$count=[BitConverter]::ToUInt16($iconBytes,4);$logo=$null
for($i=0;$i -lt $count;$i++){
    $entry=6+16*$i
    if($iconBytes[$entry] -ne 128 -or $iconBytes[$entry+1] -ne 128){continue}
    $size=[BitConverter]::ToUInt32($iconBytes,$entry+8);$offset=[BitConverter]::ToUInt32($iconBytes,$entry+12)
    if($offset+$size -gt $iconBytes.Length){throw 'ICO frame bounds invalid'}
    $frame=New-Object byte[] $size;[Array]::Copy($iconBytes,$offset,$frame,0,$size)
    if([BitConverter]::ToString($frame,0,8) -ne '89-50-4E-47-0D-0A-1A-0A'){throw 'ICO header frame is not PNG'}
    $logo=[Convert]::ToBase64String($frame);break
}
if(-not $logo){throw 'Supplied ICO has no 128px header frame'}
$s=[regex]::Replace($s,'\$script:AppIconBase64 = "[^"\r\n]+"','$script:AppIconBase64 = "'+$logo+'"')
$s=$s.Replace('# TinyRedactionTool v2.5.0 C9 CANDIDATE','# TinyRedactionTool v2.5.0 RELEASE CANDIDATE r1')
$s=$s.Replace('# PS2EXE writes the two GZip payloads below before this script starts. For the','# GZip tools remain assembly resources until the owning instance expands them. For the')
$dest=Join-Path $release 'TinyRedactionTool-Hardened-Embedded.ps1'
[IO.File]::WriteAllText($dest,$s,[Text.UTF8Encoding]::new($true))
[Management.Automation.Language.Parser]::ParseFile($dest,[ref]$t,[ref]$e)|Out-Null;if($e.Count){throw ($e|Out-String)}
foreach($pair in @(@('ffmpeg','643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC'),@('ffprobe','84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2'))){
    $inputPath='I:\#Torrent\TRT\'+$pair[0]+'-custom.exe'
    if((Get-FileHash $inputPath).Hash -ne $pair[1]){throw 'Approved media-tool mismatch'}
    $sourceStream=[IO.File]::OpenRead($inputPath);$output=[IO.File]::Create((Join-Path $out ($pair[0]+'.exe.gz')))
    $gzip=[IO.Compression.GZipStream]::new($output,[IO.Compression.CompressionMode]::Compress)
    try{$sourceStream.CopyTo($gzip)}finally{$gzip.Dispose();$output.Dispose();$sourceStream.Dispose()}
}
$vendor=Join-Path $out 'vendor/ps2exe.1.0.18/ps2exe.ps1'
if((Get-FileHash $vendor).Hash -ne '94613E703FA2EC67A01255E5917A056A9406FD31C557685B7AE76417F706A09A'){throw 'Pinned compiler mismatch'}
$v=[IO.File]::ReadAllText($vendor);$vAst=[Management.Automation.Language.Parser]::ParseInput($v,[ref]$t,[ref]$e)
$assignment=@($vAst.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$EMBEDSECTION' -and $n.Extent.Text.Contains('tgtFile = Environment.ExpandEnvironmentVariables')},$true))
if($assignment.Count -ne 1){throw 'Compiler resource-only adaptation anchor mismatch'}
$v=$v.Replace($assignment[0].Extent.Text,'$EMBEDSECTION += ""')
[IO.File]::WriteAllText((Join-Path $out 'vendor/ps2exe-resource-only.ps1'),$v,[Text.UTF8Encoding]::new($true))
Write-Output ('Release source SHA-256: '+(Get-FileHash $dest).Hash)
