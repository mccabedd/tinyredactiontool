$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5){throw 'Use Windows PowerShell 5.1 for this pinned build.'}
$root=$PSScriptRoot
$pins=@{
 'release/TinyRedactionTool-Hardened-Embedded.ps1'='2BDA3D0E6ED8F6E12004B549B16E54998CC3A04AACFC7A8B8AD8D0221AA2F7A4'
 'release/icon.ico'='11B392E79197689035BE9876B762AC99E62CE37BB02E7939CED078C2C0D89B7C'
 'ffmpeg.exe.gz'='E1A56476BC46685869D2C7B0B9AA101816D89A2907826DC2BA2B418D644268AC'
 'ffprobe.exe.gz'='A4657F326AD8AFB9999CB83C87D33D895F25729ECDF4207CBDC23AAECBDA82E7'
 'vendor/ps2exe.1.0.18/ps2exe.ps1'='94613E703FA2EC67A01255E5917A056A9406FD31C557685B7AE76417F706A09A'
 'vendor/ps2exe-resource-only.ps1'='67023624DDCDA0BC6D6DC68568ABD5B15EC7CCF570F5738E87FECAA51E6315DB'
}
foreach($entry in $pins.GetEnumerator()){if((Get-FileHash (Join-Path $root $entry.Key)).Hash -cne $entry.Value){throw ('Pinned input changed: '+$entry.Key)}}
$tokens=$null;$errors=$null
[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'release/TinyRedactionTool-Hardened-Embedded.ps1'),[ref]$tokens,[ref]$errors)|Out-Null
if($errors.Count){throw ($errors|Out-String)}
foreach($pair in @(@('ffmpeg','643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC'),@('ffprobe','84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2'))){
 $inputStream=[IO.File]::OpenRead((Join-Path $root ($pair[0]+'.exe.gz')));$gzip=[IO.Compression.GZipStream]::new($inputStream,[IO.Compression.CompressionMode]::Decompress);$sha=[Security.Cryptography.SHA256]::Create()
 try{$hash=[BitConverter]::ToString($sha.ComputeHash($gzip)).Replace('-','');if($hash -cne $pair[1]){throw 'Approved expanded media-tool hash mismatch'}}finally{$sha.Dispose();$gzip.Dispose();$inputStream.Dispose()}
}
[void][IO.Directory]::CreateDirectory((Join-Path $root 'output'))
. (Join-Path $root 'vendor/ps2exe-resource-only.ps1')
Invoke-PS2EXE -inputFile (Join-Path $root 'release/TinyRedactionTool-Hardened-Embedded.ps1') -outputFile (Join-Path $root 'output/TinyRedactionTool.exe') -iconFile (Join-Path $root 'release/icon.ico') -embedFiles @{'resource-ffmpeg'=(Join-Path $root 'ffmpeg.exe.gz');'resource-ffprobe'=(Join-Path $root 'ffprobe.exe.gz')} -title 'TinyRedactionTool' -description 'Local image and video redaction' -company 'David McCabe' -product 'TinyRedactionTool' -copyright 'Copyright (C) 2026 David McCabe' -version '2.5.1.0' -STA -x64 -noConsole -noOutput -DPIAware -supportOS
if(-not (Test-Path (Join-Path $root 'output/TinyRedactionTool.exe'))){throw 'EXE build failed'}
Get-FileHash (Join-Path $root 'output/TinyRedactionTool.exe')
