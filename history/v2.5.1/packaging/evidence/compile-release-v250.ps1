$ErrorActionPreference='Stop';$root=$PSScriptRoot;$build=Join-Path $root 'TRT-v2.5.0-Release-Build'
. (Join-Path $build 'vendor/ps2exe-resource-only.ps1')
Invoke-PS2EXE -inputFile (Join-Path $build 'release/TinyRedactionTool-Hardened-Embedded.ps1') -outputFile (Join-Path $build 'release/TinyRedactionTool.exe') -iconFile (Join-Path $build 'release/icon.ico') -embedFiles @{'resource-ffmpeg'=(Join-Path $build 'ffmpeg.exe.gz');'resource-ffprobe'=(Join-Path $build 'ffprobe.exe.gz')} -title 'TinyRedactionTool' -description 'Local image and video redaction' -company 'David McCabe' -product 'TinyRedactionTool' -copyright 'Copyright (C) 2026 David McCabe' -version '2.5.0.0' -STA -x64 -noConsole -noOutput -DPIAware -supportOS
if(-not (Test-Path (Join-Path $build 'release/TinyRedactionTool.exe'))){throw 'EXE build failed'}
Get-FileHash (Join-Path $build 'release/TinyRedactionTool.exe')
