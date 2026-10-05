$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5){throw 'Run this builder in Windows PowerShell 5.1.'}
$pins=@{
 'TinyRedactionTool-Hardened-Embedded.ps1'='2BDA3D0E6ED8F6E12004B549B16E54998CC3A04AACFC7A8B8AD8D0221AA2F7A4'
 'icon.ico'='11B392E79197689035BE9876B762AC99E62CE37BB02E7939CED078C2C0D89B7C'
}
foreach($entry in $pins.GetEnumerator()){if((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $entry.Key)).Hash -ne $entry.Value){throw ('Repository input differs from frozen v2.5.1 source: '+$entry.Key)}}
$builder=Join-Path $PSScriptRoot 'packaging/BUILD-v2.5.1.ps1'
if(-not (Test-Path -LiteralPath $builder)){throw 'Upload/extract the complete packaging directory before building.'}
& $builder
