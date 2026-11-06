param([switch]$Check)
$ErrorActionPreference = 'Stop'
$env:DOTNET_CLI_HOME = Join-Path $PSScriptRoot '.dotnet'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
$env:DOTNET_GENERATE_ASPNET_CERTIFICATE = 'false'
$env:DOTNET_ADD_GLOBAL_TOOLS_TO_PATH = 'false'
$env:MSBuildEnableWorkloadResolver = 'false'
$env:DOTNET_ROOT = Join-Path $PSScriptRoot '.sdk'
$dotnet = Join-Path $env:DOTNET_ROOT 'dotnet.exe'
if (-not (Test-Path -LiteralPath $dotnet)) { throw 'Portable .NET 10 SDK missing. See dependencies/dotnet-sdk-pin.json.' }
Push-Location $PSScriptRoot
try {
    $pins = @{
        'ffmpeg.exe' = '643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC'
        'ffprobe.exe' = '84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2'
    }
    foreach ($name in $pins.Keys) {
        $toolPath = Join-Path $PSScriptRoot "tools/$name"
        if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) { throw "Missing approved development tool: $name. See THIRD-PARTY.md." }
        if ((Get-FileHash -LiteralPath $toolPath -Algorithm SHA256).Hash -ne $pins[$name]) { throw "Approved tool hash mismatch: $name" }
    }
    $project = if ($Check) { 'Checks/TinyRedaction.Checks.csproj' } else { 'Desktop/TinyRedaction.Desktop.csproj' }
    [xml]$buildProperties = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Directory.Build.props') -Raw
    $buildVersion = ([string]$buildProperties.Project.PropertyGroup.Version).Split('-')[0]
    $artifactRoot = Join-Path $PSScriptRoot "artifacts/$buildVersion"
    & $dotnet build $project --configuration Debug --artifacts-path $artifactRoot --configfile NuGet.Config -m:1
    if ($LASTEXITCODE -ne 0) { throw 'Development build failed.' }
    if ($Check) {
        # Windows PowerShell 5.1 turns any native stderr line (such as harmless decoder-shutdown
        # noise) into a terminating error under 'Stop'. The exit code decides pass/fail instead.
        $ErrorActionPreference = 'Continue'
        & $dotnet (Join-Path $artifactRoot 'bin/TinyRedaction.Checks/debug/TinyRedaction.Checks.dll') (Join-Path $PSScriptRoot 'test-output')
        $checksExit = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        if ($checksExit -ne 0) { throw 'Development checks failed.' }
    }
    $selector = Join-Path $PSScriptRoot 'current-build.txt'
    $pendingSelector = $selector + '.' + [Guid]::NewGuid().ToString('N')
    [System.IO.File]::WriteAllText($pendingSelector, "artifacts/$buildVersion/bin/TinyRedaction.Desktop/debug/TinyRedactionTool.dll")
    if (Test-Path -LiteralPath $selector) { [System.IO.File]::Replace($pendingSelector, $selector, $selector + '.previous') }
    else { [System.IO.File]::Move($pendingSelector, $selector) }
} finally { Pop-Location }
