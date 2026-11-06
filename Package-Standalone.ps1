# Packages the current development version as one standalone TinyRedactionTool .exe (since 0.13.0;
# the version comes from Directory.Build.props).
# It uses the private SDK and the pinned local packages only. The .exe needs the .NET 10 Desktop
# Runtime, which is installed on David's laptop; the private SDK has no runtime packs to bundle it.
# Approved FFmpeg/FFprobe and the private VideoLAN files travel inside the .exe and unpack to a
# per-user temporary folder on first start, where TRT verifies their hashes as usual.
$ErrorActionPreference = 'Stop'
$env:DOTNET_CLI_HOME = Join-Path $PSScriptRoot '.dotnet'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE = 'false'
$env:DOTNET_ADD_GLOBAL_TOOLS_TO_PATH = 'false'
$env:MSBuildEnableWorkloadResolver = 'false'
$env:DOTNET_ROOT = Join-Path $PSScriptRoot '.sdk'
$dotnet = Join-Path $env:DOTNET_ROOT 'dotnet.exe'
Push-Location $PSScriptRoot
try {
    [xml]$props = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Directory.Build.props') -Raw
    $version = ([string]$props.Project.PropertyGroup.Version).Split('-')[0]
    $output = Join-Path $PSScriptRoot "standalone/$version"
    if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Recurse -Force }
    & $dotnet publish Desktop/TinyRedaction.Desktop.csproj --configuration Release --runtime win-x64 --self-contained false `
        --artifacts-path (Join-Path $PSScriptRoot "artifacts/$version-standalone") --configfile NuGet.Config -m:1 --output $output `
        -p:PublishSingleFile=true -p:IncludeAllContentForSelfExtract=true -p:DebugType=embedded -p:EnableSingleFileAnalyzer=false -p:DisableTransitiveFrameworkReferenceDownloads=true
    if ($LASTEXITCODE -ne 0) { throw 'Standalone packaging failed.' }
    $built = Join-Path $output "TinyRedactionTool.exe"
    if (-not (Test-Path -LiteralPath $built)) { throw 'The standalone .exe was not produced.' }
    $exe = Join-Path $output "TinyRedactionTool-$version.exe"
    Move-Item -LiteralPath $built -Destination $exe
    if (-not (Test-Path -LiteralPath $exe)) { throw 'The standalone .exe was not produced.' }
    Get-ChildItem -LiteralPath $output | Where-Object { $_.FullName -ne $exe } | Remove-Item -Recurse -Force
    $hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
    Set-Content -LiteralPath "$exe.sha256" -Value "$hash  TinyRedactionTool-$version.exe" -Encoding ascii
    Write-Output "Packaged $exe ($([math]::Round((Get-Item -LiteralPath $exe).Length / 1MB)) MB, SHA-256 $hash)"
} finally { Pop-Location }
