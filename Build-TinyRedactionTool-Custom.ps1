$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5){throw 'Run this builder in Windows PowerShell 5.1.'}
$pins=@{
 'TinyRedactionTool-Hardened-Embedded.ps1'='CA2CC6EBD3BDB48737B249A96F8953D2007DCB38780606AC2EEE74E5F40A2C3C'
 'icon.ico'='11B392E79197689035BE9876B762AC99E62CE37BB02E7939CED078C2C0D89B7C'
}
foreach($entry in $pins.GetEnumerator()){if((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $entry.Key)).Hash -ne $entry.Value){throw ('Repository input differs from frozen v2.5.1 source: '+$entry.Key)}}
$builder=Join-Path $PSScriptRoot 'packaging/BUILD-v2.5.1.ps1'
if(-not (Test-Path -LiteralPath $builder)){throw 'Upload/extract the complete packaging directory before building.'}
& $builder
