$ErrorActionPreference = 'Stop'
$cache = Join-Path $PSScriptRoot 'dependencies'
New-Item -ItemType Directory -Path $cache -Force | Out-Null
function Get-PinnedFile([string]$url, [string]$destination, [string]$algorithm, [string]$hash) {
    $full = [IO.Path]::GetFullPath($destination)
    if (-not $full.StartsWith([IO.Path]::GetFullPath($cache) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid cache destination.' }
    if (Test-Path -LiteralPath $full) {
        if ((Get-FileHash -LiteralPath $full -Algorithm $algorithm).Hash -ne $hash) { throw "Cached input hash mismatch: $full" }
        return
    }
    $partial = $full + '.partial.' + [Guid]::NewGuid().ToString('N')
    try {
        Invoke-WebRequest -Uri $url -OutFile $partial
        if ((Get-FileHash -LiteralPath $partial -Algorithm $algorithm).Hash -ne $hash) { throw 'Downloaded input hash mismatch.' }
        Move-Item -LiteralPath $partial -Destination $full
    } finally { if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial } }
}
$sdk = Get-Content -LiteralPath (Join-Path $cache 'dotnet-sdk-pin.json') -Raw | ConvertFrom-Json
if ($sdk.url -ne 'https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.403/dotnet-sdk-10.0.403-win-x64.zip') { throw 'Unsupported SDK pin.' }
Get-PinnedFile $sdk.url (Join-Path $cache 'dotnet-sdk.zip') 'SHA512' $sdk.hash
Get-PinnedFile 'https://api.nuget.org/v3-flatcontainer/libvlcsharp/3.10.2/libvlcsharp.3.10.2.nupkg' (Join-Path $cache 'libvlcsharp.3.10.2.nupkg') 'SHA256' 'A7473E6D7C3595C74D3FB42BB0791053224D07B797ADCEE8C16F00E6F99BB8F9'
Get-PinnedFile 'https://api.nuget.org/v3-flatcontainer/videolan.libvlc.windows/3.0.24/videolan.libvlc.windows.3.0.24.nupkg' (Join-Path $cache 'videolan.libvlc.windows.3.0.24.nupkg') 'SHA256' '3DA3F37EE2B2B10E5C788D830A3B513658C36521EA1B0F966ED86EB69F41EF3C'
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.sdk/sdk/10.0.403'))) {
    $target = Join-Path $PSScriptRoot '.sdk'
    if (Test-Path -LiteralPath $target) { throw 'Portable SDK directory is incomplete; preserve it for inspection before rebuilding the cache.' }
    Expand-Archive -LiteralPath (Join-Path $cache 'dotnet-sdk.zip') -DestinationPath $target
}
& (Join-Path $PSScriptRoot 'Stage-Native.ps1')
Write-Output 'Pinned development dependencies ready. Approved FFmpeg/FFprobe in tools/ are separate required inputs; see THIRD-PARTY.md.'
