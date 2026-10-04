$ErrorActionPreference='Stop';$root=$PSScriptRoot;$build=Join-Path $root 'TRT-v2.5.0-Release-Build'
$fixture=Join-Path $build 'fixture';[void][IO.Directory]::CreateDirectory($fixture)
$s=[IO.File]::ReadAllText((Join-Path $build 'release/TinyRedactionTool-Hardened-Embedded.ps1'))
$s=$s.Replace('Local\TinyRedactionTool-v250-','Local\TRTReleaseFixture-v250-')
$s=$s.Replace('$form.Text = "TinyRedactionTool"','$form.Text = "TRT Release Fixture"'+"`n"+'$form.Opacity=0.0')
$s=$s.Replace('if($missing.Count) {','if($false) {')
$s=$s.Replace('$legacyLive=[TRTSessionWindows]::HasOtherTRTWindow($PID)','$legacyLive=$false')
$s=$s.Replace('[Windows.Forms.Clipboard]::SetImage($clipboardBitmap)','[C9ClipboardFixture]::SetImage($clipboardBitmap)')
$actions=[IO.File]::ReadAllText((Join-Path $root 'c9-dialog-probe-actions.txt'))
$escaped=$fixture.Replace("'","''")
$actions=$actions.Replace('$PSScriptRoot',("'"+$escaped+"'"))
$actions=$actions.Replace('../TRT-v2.5.0-C9-Package/','')
$actions=$actions.Replace('$script:C9Phase=0;',@'
if(-not $form.ShowIcon -or -not $form.Icon -or $script:CaptureState.Tray.Icon.Handle -ne $form.Icon.Handle){throw 'Window/tray icon identity mismatch'}
$iconBytes=[Convert]::FromBase64String($script:TRTIconBase64)
$sha=[Security.Cryptography.SHA256]::Create()
try{if([BitConverter]::ToString($sha.ComputeHash($iconBytes)).Replace('-','') -ne '11B392E79197689035BE9876B762AC99E62CE37BB02E7939CED078C2C0D89B7C'){throw 'Icon asset hash mismatch'}}finally{$sha.Dispose()}
$script:C9Phase=0;
'@)
$s=$s.Replace('[System.Windows.Forms.Application]::Run($form)',$actions)
$path=Join-Path $fixture 'release-fixture.ps1';[IO.File]::WriteAllText($path,$s,[Text.UTF8Encoding]::new($true))
. (Join-Path $build 'vendor/ps2exe-resource-only.ps1')
Invoke-PS2EXE -inputFile $path -outputFile (Join-Path $fixture 'release-fixture.exe') -iconFile (Join-Path $build 'release/icon.ico') -embedFiles @{'resource-ffmpeg'=(Join-Path $build 'ffmpeg.exe.gz');'resource-ffprobe'=(Join-Path $build 'ffprobe.exe.gz')} -STA -x64 -noConsole -noOutput -DPIAware -supportOS
foreach($managed in @($false,$true)){
 $temp=Join-Path $fixture ('temp-'+$managed);[void][IO.Directory]::CreateDirectory($temp)
 $si=[Diagnostics.ProcessStartInfo]::new((Join-Path $fixture 'release-fixture.exe'));$si.UseShellExecute=$false
 $si.EnvironmentVariables['TEMP']=$temp;$si.EnvironmentVariables['TMP']=$temp;$si.EnvironmentVariables['ProgramData']=$temp
 if($managed){$si.Arguments='-ManagedPolicyPath "'+(Join-Path $root 'TRT-v2.5.0-C9-Package/SAMPLE-POLICY-ALL-CONTROLS.json')+'"'}
 $p=[Diagnostics.Process]::Start($si)
 try{if(-not $p.WaitForExit(40000)){throw 'Compiled fixture timed out'};if($p.ExitCode -ne 0){throw ('Fixture exit code '+$p.ExitCode)}}finally{if(-not $p.HasExited){$p.Kill();$p.WaitForExit()}}
 if(Test-Path (Join-Path $fixture 'c9-dialog-error.txt')){throw (Get-Content (Join-Path $fixture 'c9-dialog-error.txt') -Raw)}
 if(@(Get-ChildItem $temp -Recurse -File).Count){throw 'Compiled fixture left temporary files'}
}
Get-Content (Join-Path $fixture 'C9-DIALOG-VALIDATION.txt')
Get-Content (Join-Path $fixture 'C9-MANAGED-DIALOG-VALIDATION.txt')
'PASS: compiled fixture window/tray icon identity, exact ICO hash, normal Quit cleanup'|Set-Content (Join-Path $build 'RELEASE-FIXTURE-CHECKS.txt')
