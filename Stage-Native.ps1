$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$package = Join-Path $PSScriptRoot 'dependencies/videolan.libvlc.windows.3.0.24.nupkg'
if ((Get-FileHash -LiteralPath $package).Hash -ne '3DA3F37EE2B2B10E5C788D830A3B513658C36521EA1B0F966ED86EB69F41EF3C') { throw 'Native package hash mismatch.' }
$binding = Join-Path $PSScriptRoot 'dependencies/libvlcsharp.3.10.2.nupkg'
if ((Get-FileHash -LiteralPath $binding).Hash -ne 'A7473E6D7C3595C74D3FB42BB0791053224D07B797ADCEE8C16F00E6F99BB8F9') { throw 'Binding package hash mismatch.' }
$root = Join-Path $PSScriptRoot 'native-runtime'
New-Item -ItemType Directory -Path $root -Force | Out-Null
$manifest = [ordered]@{}
$excluded = [System.Collections.Generic.List[string]]::new()
$zip = [IO.Compression.ZipFile]::OpenRead($package)
try {
    foreach ($entry in $zip.Entries) {
        if (-not $entry.FullName.StartsWith('build/x64/')) { continue }
        $relative = $entry.FullName.Substring(10)
        if (-not $relative.EndsWith('.dll')) { continue }
        $parts = $relative.Split('/')
        $keep = $parts.Count -eq 1
        if ($parts[0] -eq 'plugins') {
            $category = $parts[1]; $name = $parts[-1]
            $keep = $category -in @('codec','packetizer','demux','video_chroma','video_filter','audio_filter','audio_mixer','audio_output','video_output','misc','stream_filter')
            if ($category -eq 'access') { $keep = $name -in @('libaccess_imem_plugin.dll','libimem_plugin.dll') }
            if ($name -in @('libadaptive_plugin.dll','libplaylist_plugin.dll','libnsc_plugin.dll','libdirectory_demux_plugin.dll','libdemux_chromecast_plugin.dll','libdemuxdump_plugin.dll','libstream_filter_chromecast_plugin.dll','liblua_plugin.dll')) { $keep = $false }
        }
        if (-not $keep) { $excluded.Add($relative); continue }
        $destination = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $destination.StartsWith([IO.Path]::GetFullPath($root) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe package path.' }
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force | Out-Null
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $true)
        $manifest[$relative] = (Get-FileHash -LiteralPath $destination).Hash
    }
} finally { $zip.Dispose() }
$manifest | ConvertTo-Json | Set-Content (Join-Path $PSScriptRoot 'dependencies/native-manifest.json') -Encoding utf8
$excluded | Set-Content (Join-Path $PSScriptRoot 'dependencies/excluded-native-modules.txt') -Encoding utf8
"Staged $($manifest.Count) pinned x64 native files; excluded $($excluded.Count) modules."
