$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5){throw 'Run this builder in Windows PowerShell 5.1.'}
$pins=@{
 'TinyRedactionTool-Hardened-Embedded.ps1'='EA3AB99E84C36196469238A531885553A51B59EF08EE9BA9E0249391FA085770'
 'icon.ico'='11B392E79197689035BE9876B762AC99E62CE37BB02E7939CED078C2C0D89B7C'
}
foreach($entry in $pins.GetEnumerator()){if((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $entry.Key)).Hash -ne $entry.Value){throw ('Repository input differs from frozen candidate: '+$entry.Key)}}
$builder=Join-Path $PSScriptRoot 'packaging/BUILD-v2.5.0.ps1'
if(-not (Test-Path -LiteralPath $builder)){throw 'Upload/extract the complete packaging directory before building.'}
& $builder
