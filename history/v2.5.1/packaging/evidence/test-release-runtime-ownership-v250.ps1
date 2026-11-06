$ErrorActionPreference='Stop';$build=Join-Path $PSScriptRoot 'TRT-v2.5.0-Release-Build'
$scratch=Join-Path $build 'ownership-check';[void][IO.Directory]::CreateDirectory($scratch)
$env:TEMP=$scratch;$env:TMP=$scratch
function Get-NetworkPathReason {param($path);return ''}
function Close-ApprovedMediaToolLocks {}
Invoke-Expression ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'release-runtime-v250.txt')))
$parent=Get-TRTRuntimeRoot
function New-OwnedFixture([string]$tag){$p=Join-Path $parent ('run-'+[guid]::NewGuid().ToString('N'));[void][IO.Directory]::CreateDirectory($p);[IO.File]::WriteAllText((Join-Path $p '.runtime.lock'),$tag,[Text.Encoding]::ASCII);return $p}
foreach($tag in @('','TRT-RUN','TRT-RUNTIME-v250-1')){$p=New-OwnedFixture $tag;[IO.File]::WriteAllText((Join-Path $p 'ffmpeg.exe'),'interrupted partial extraction');Recover-OwnedRuntimeFolders;if(Test-Path $p){throw 'Interrupted marker/resource was not recovered'}}
$p=New-OwnedFixture 'TRT-RUNTIME-v250-1';$lease=[IO.File]::Open((Join-Path $p '.runtime.lock'),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try{Recover-OwnedRuntimeFolders;if(-not (Test-Path $p)){throw 'Live runtime lease was removed'}}finally{$lease.Dispose()}
Recover-OwnedRuntimeFolders
$unknown=New-OwnedFixture 'foreign-marker';Recover-OwnedRuntimeFolders;if(-not (Test-Path $unknown)){throw 'Foreign marker deleted'}
$unexpected=New-OwnedFixture 'TRT-RUNTIME-v250-1';[IO.File]::WriteAllText((Join-Path $unexpected 'unrelated.txt'),'preserve')
$rejected=$false;try{Remove-TRTRuntimeFolder $unexpected}catch{$rejected=$true};if(-not $rejected -or -not (Test-Path (Join-Path $unexpected 'unrelated.txt'))){throw 'Unknown contents not protected'}
$outside=Join-Path $scratch 'outside';[void][IO.Directory]::CreateDirectory($outside)
$rejected=$false;try{Remove-TRTRuntimeFolder $outside}catch{$rejected=$true};if(-not $rejected -or -not (Test-Path $outside)){throw 'Outside target not protected'}
@('PASS: interrupted empty/partial/complete ownership markers and partial tools recovered','PASS: active exclusive lease untouched','PASS: foreign ownership marker untouched','PASS: unexpected files stop cleanup without deleting them','PASS: outside-root cleanup rejected')|Set-Content (Join-Path $build 'RELEASE-OWNERSHIP-CHECKS.txt')
Get-Content (Join-Path $build 'RELEASE-OWNERSHIP-CHECKS.txt')
