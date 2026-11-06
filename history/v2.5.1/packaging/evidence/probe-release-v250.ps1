$ErrorActionPreference='Stop'
$root=$PSScriptRoot;$build=Join-Path $root 'TRT-v2.5.0-Release-Build';$exe=Join-Path $build 'release/TinyRedactionTool.exe'
$scratch=Join-Path $build 'runtime-check';[void][IO.Directory]::CreateDirectory($scratch)
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class ReleaseWindow { [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h,int m,IntPtr w,IntPtr l); }
'@
function Start-IsolatedTRT {
 $si=[Diagnostics.ProcessStartInfo]::new($exe);$si.UseShellExecute=$false
 $si.EnvironmentVariables['TEMP']=$scratch;$si.EnvironmentVariables['TMP']=$scratch
 $si.EnvironmentVariables['ProgramData']=$scratch
 return [Diagnostics.Process]::Start($si)
}
function Wait-Ready($p){
 $limit=[DateTime]::UtcNow.AddSeconds(35)
 do{Start-Sleep -Milliseconds 250;$p.Refresh();if($p.HasExited){throw 'Release EXE exited before readiness'}}while($p.MainWindowHandle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $limit)
 if($p.MainWindowHandle -eq [IntPtr]::Zero){throw 'Main window did not open'}
 $dirs=@(Get-ChildItem (Join-Path $scratch 'TinyRedactionTool') -Directory -Filter 'run-*')
 if($dirs.Count -ne 1){throw 'Expected exactly one runtime folder'}
 foreach($pair in @(@('ffmpeg.exe','643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC'),@('ffprobe.exe','84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2'))){if((Get-FileHash (Join-Path $dirs[0].FullName $pair[0])).Hash -ne $pair[1]){throw 'Runtime tool hash mismatch'}}
 if(@(Get-ChildItem $scratch -Recurse -Filter '*.gz').Count){throw 'Compressed payload leaked to TEMP'}
 return $dirs[0].FullName
}
$p=$null;$q=$null
try{
 $p=Start-IsolatedTRT;$first=Wait-Ready $p
 $q=Start-IsolatedTRT;if(-not $q.WaitForExit(10000)){throw 'Second launch did not hand off'}
 if($q.ExitCode -ne 0 -or @(Get-ChildItem (Join-Path $scratch 'TinyRedactionTool') -Directory -Filter 'run-*').Count -ne 1){throw 'Single-instance launch created extra runtime files'}
 $p.Kill();$p.WaitForExit();$p=$null
 $p=Start-IsolatedTRT;$second=Wait-Ready $p
 if(Test-Path -LiteralPath $first){throw 'Abandoned tool folder not recovered'}
 # Simulate Windows session-end on this process only; no system logoff.
 [void][ReleaseWindow]::SendMessage($p.MainWindowHandle,0x11,[IntPtr]::Zero,[IntPtr]::Zero)
 [void][ReleaseWindow]::SendMessage($p.MainWindowHandle,0x16,[IntPtr]1,[IntPtr]::Zero)
 if(-not $p.WaitForExit(10000)){throw 'Session-end shutdown did not finish'}
 if(Test-Path -LiteralPath $second){throw 'Normal lifecycle tool cleanup failed'}
 @('PASS: compiled EXE startup','PASS: exact approved embedded FFmpeg/FFprobe hashes','PASS: no compressed tool payload written to TEMP','PASS: second launch reuses first instance without extra files','PASS: forced termination tool recovery on next launch','PASS: process-local session-end normal lifecycle cleanup')|Set-Content (Join-Path $build 'RELEASE-RUNTIME-CHECKS.txt')
 Get-Content (Join-Path $build 'RELEASE-RUNTIME-CHECKS.txt')
}finally{foreach($owned in @($p,$q)){if($owned -and -not $owned.HasExited){$owned.Kill();$owned.WaitForExit()}}}
