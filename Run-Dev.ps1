$ErrorActionPreference = 'Stop'
$env:DOTNET_ROOT = Join-Path $PSScriptRoot '.sdk'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$dotnet = Join-Path $env:DOTNET_ROOT 'dotnet.exe'
$application = Join-Path $PSScriptRoot 'Desktop/bin/Debug/net10.0-windows/TinyRedactionTool.dll'
$selector = Join-Path $PSScriptRoot 'current-build.txt'
if (Test-Path -LiteralPath $selector) {
    $relative = (Get-Content -LiteralPath $selector -Raw).Trim()
    if ([System.IO.Path]::IsPathRooted($relative)) { throw 'The development build path must be relative.' }
    $application = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $relative))
    $allowedRoot = [System.IO.Path]::GetFullPath($PSScriptRoot) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $application.StartsWith($allowedRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'The development build must remain inside this folder.' }
}
if (-not (Test-Path -LiteralPath $application)) { throw 'Run Build-Dev.ps1 first.' }
& $dotnet $application @args
