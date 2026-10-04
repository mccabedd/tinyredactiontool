$ErrorActionPreference='Stop';$root=$PSScriptRoot;$build=Join-Path $root 'TRT-v2.5.0-Release-Build'
$reference=Join-Path $root 'TRT-v2.5.0-C9-Package/TinyRedactionTool-Hardened-Embedded-v2.5.0-C9.ps1'
$source=Join-Path $build 'release/TinyRedactionTool-Hardened-Embedded.ps1'
$tokens=$null;$errors=$null;$old=[Management.Automation.Language.Parser]::ParseFile($reference,[ref]$tokens,[ref]$errors)
$new=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors);if($errors.Count){throw 'Windows PowerShell parser rejected release source'}
$allowed=@('Expand-EmbeddedGzipTool','Initialize-EmbeddedMediaTools','Remove-EmbeddedMediaTools')
$oldFunctions=@($old.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$true))
$newFunctions=@($new.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$true))
foreach($f in $oldFunctions){$match=@($newFunctions|Where-Object{$_.Name -eq $f.Name});if($match.Count -ne 1){throw ('Function identity mismatch: '+$f.Name)};if($f.Name -notin $allowed -and $match[0].Extent.Text -cne $f.Extent.Text){throw ('Protected function changed: '+$f.Name)}}
$added=@($newFunctions|Where-Object{$_.Name -notin $oldFunctions.Name}).Name
if(($added|Sort-Object) -join ',' -ne 'Get-TRTRuntimeRoot,Recover-OwnedRuntimeFolders,Remove-TRTRuntimeFolder'){throw 'Unexpected added function'}
function Get-ProtectedStatements($ast,[string]$iconAnchor){
 $full=$ast.Extent.Text;$start=$full.IndexOf($iconAnchor);$end=$full.IndexOf('# Shared tooltip component',$start)
 if($start -lt 0 -or $end -lt 0){throw 'Icon audit boundary missing'}
 foreach($statement in $ast.EndBlock.Statements){
  if($statement -is [Management.Automation.Language.FunctionDefinitionAst]){continue}
  if($statement.Extent.StartOffset -ge $start -and $statement.Extent.StartOffset -lt $end){continue}
  if($statement -is [Management.Automation.Language.AssignmentStatementAst] -and $statement.Left.Extent.Text -in @('$script:EmbeddedFFmpegPayloadGzip','$script:EmbeddedFFprobePayloadGzip','$script:AppIconBase64')){continue}
  $statement.Extent.Text
 }
}
$before=@(Get-ProtectedStatements $old '# WinForms does not automatically adopt the PS2EXE assembly icon')
$after=@(Get-ProtectedStatements $new '# Supplied TRT icon: identical embedded asset for script and compiled host.')
if($old.ParamBlock.Extent.Text -cne $new.ParamBlock.Extent.Text -or ($before -join "`n") -cne ($after -join "`n")){throw 'Protected top-level statements or parameters changed'}
Add-Type @"
using System;using System.Runtime.InteropServices;
public static class IconResourceAudit {
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode)] static extern IntPtr LoadLibraryEx(string s,IntPtr f,uint flags);
 [DllImport("kernel32.dll")] static extern IntPtr FindResource(IntPtr m,IntPtr id,IntPtr type);
 [DllImport("kernel32.dll")] static extern uint SizeofResource(IntPtr m,IntPtr r);
 [DllImport("kernel32.dll")] static extern IntPtr LoadResource(IntPtr m,IntPtr r);
 [DllImport("kernel32.dll")] static extern IntPtr LockResource(IntPtr r);
 [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr m);
 public static byte[] Read(string path,int id,int type){IntPtr m=LoadLibraryEx(path,IntPtr.Zero,2);try{IntPtr r=FindResource(m,(IntPtr)id,(IntPtr)type);if(r==IntPtr.Zero)throw new Exception("Missing icon resource");byte[] b=new byte[SizeofResource(m,r)];Marshal.Copy(LockResource(LoadResource(m,r)),b,0,b.Length);return b;}finally{FreeLibrary(m);}}
}
"@
$exe=Join-Path $build 'release/TinyRedactionTool.exe';$ico=[IO.File]::ReadAllBytes((Join-Path $build 'release/icon.ico'))
$group=[IconResourceAudit]::Read($exe,32512,14)
$count=[BitConverter]::ToUInt16($group,4);if($count -ne [BitConverter]::ToUInt16($ico,4)){throw 'ICO resource frame count mismatch'}
for($i=0;$i -lt $count;$i++){
 $id=[BitConverter]::ToUInt16($group,6+14*$i+12);$frame=[IconResourceAudit]::Read($exe,$id,3)
 $size=[BitConverter]::ToUInt32($ico,6+16*$i+8);$offset=[BitConverter]::ToUInt32($ico,6+16*$i+12)
 $expected=New-Object byte[] $size;[Array]::Copy($ico,$offset,$expected,0,$size)
 if([Convert]::ToBase64String($frame) -cne [Convert]::ToBase64String($expected)){throw 'Embedded icon frame bytes differ from supplied ICO'}
}
$version=[Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $build 'release/TinyRedactionTool.exe'));if($version.FileVersion -ne '2.5.0.0'){throw 'EXE version mismatch'}
$compiler=Join-Path $build 'vendor/ps2exe.1.0.18/ps2exe.ps1'
if((Get-FileHash $compiler).Hash -ne '94613E703FA2EC67A01255E5917A056A9406FD31C557685B7AE76417F706A09A'){throw 'Compiler pin mismatch'}
$c=[IO.File]::ReadAllText($compiler);$ca=[Management.Automation.Language.Parser]::ParseInput($c,[ref]$tokens,[ref]$errors)
$target=@($ca.FindAll({param($n)$n -is [Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq '$EMBEDSECTION' -and $n.Extent.Text.Contains('tgtFile = Environment.ExpandEnvironmentVariables')},$true))
if($target.Count -ne 1 -or $c.Replace($target[0].Extent.Text,'$EMBEDSECTION += ""') -cne [IO.File]::ReadAllText((Join-Path $build 'vendor/ps2exe-resource-only.ps1'))){throw 'Unexpected compiler adaptation'}
@('PASS: Windows PowerShell 5.1 source parser',('PASS: '+($oldFunctions.Count-3)+' accepted C9 functions byte-identical, including export/timing/security/governance and capture cleanup'),'PASS: protected top-level handlers/statements and source parameters byte-identical after explicitly excluding icon/resource assignments','PASS: only three existing media-resource bootstrap functions replaced; three scoped runtime ownership helpers added','PASS: all seven EXE shell/taskbar icon resource frames exactly match supplied ICO bytes','PASS: EXE version 2.5.0.0','PASS: pinned PS2EXE original and exact one-assignment resource-only adaptation')|Set-Content (Join-Path $build 'RELEASE-STATIC-CHECKS.txt')
Get-Content (Join-Path $build 'RELEASE-STATIC-CHECKS.txt')
