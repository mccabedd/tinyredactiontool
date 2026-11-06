$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5){throw 'Run this builder in Windows PowerShell 5.1.'}
$pins=@{
 'TinyRedactionTool-Hardened-Embedded.ps1'='5F2B4E58A9FA2D86EA8B8CB84F880364F2D4446CCDE4FDCC9A4ABABF0E0F35C5'
 'icon.ico'='11B392E79197689035BE9876B762AC99E62CE37BB02E7939CED078C2C0D89B7C'
}
foreach($entry in $pins.GetEnumerator()){if((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $entry.Key)).Hash -ne $entry.Value){throw ('Repository input differs from frozen v2.5.1 source: '+$entry.Key)}}
$builder=Join-Path $PSScriptRoot 'packaging/BUILD-v2.5.1.ps1'
if(-not (Test-Path -LiteralPath $builder)){throw 'Upload/extract the complete packaging directory before building.'}
& $builder
