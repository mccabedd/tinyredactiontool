$ErrorActionPreference='Stop';$build=Join-Path $PSScriptRoot 'TRT-v2.5.0-Release-Build';$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $build 'release/TinyRedactionTool-Hardened-Embedded.ps1'),[ref]$tokens,[ref]$errors)
foreach($name in @('Get-NetworkPathReason','ConvertTo-ManagedPolicyV1','Initialize-ManagedPolicy')){$function=$ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)[0];Invoke-Expression $function.Extent.Text}
$restricted=Join-Path $build 'release/policy-restricted.json';$normal=Join-Path $build 'release/policy-permissive.json'
$p=ConvertTo-ManagedPolicyV1 $restricted
foreach($name in @('BlockNetworkSource','BlockNetworkDestination','DisableSourceDeletion','DisableAudioRetention','DisableVisualObscuration')){if(-not $p.$name){throw 'Restricted sample control not applied'}}
$p=ConvertTo-ManagedPolicyV1 $normal
foreach($name in @('BlockNetworkSource','BlockNetworkDestination','DisableSourceDeletion','DisableAudioRetention','DisableVisualObscuration')){if($p.$name){throw 'Permissive sample unexpectedly restricted'}}
$scratch=Join-Path $build 'policy-check';[void][IO.Directory]::CreateDirectory($scratch)
$script:ManagedPolicyMachinePath=$restricted;$script:ManagedPolicyExplicit=$true;$ManagedPolicyPath=$normal
Initialize-ManagedPolicy;if($script:ManagedPolicy.PolicyId -ne 'company-normal'){throw 'Explicit policy precedence changed'}
$script:ManagedPolicyExplicit=$false;Initialize-ManagedPolicy;if($script:ManagedPolicy.PolicyId -ne 'company-restricted'){throw 'Machine policy not selected'}
$script:ManagedPolicyMachinePath=Join-Path $scratch 'absent.json';Initialize-ManagedPolicy;if($script:ManagedPolicy){throw 'Absent policy behaviour changed'}
$valid=[IO.File]::ReadAllText($restricted)
$cases=@('','{not-json}',$valid.Replace('"schemaVersion": 1','"schemaVersion": 2'),$valid.Replace('"blockNetworkSource": true','"blockNetworkSource": "true"'),$valid.Replace('"blockNetworkSource": true','"unsupportedControl": true'),$valid.Replace('"controls": {','"extra": 1, "controls": {'))
foreach($value in $cases){$path=Join-Path $scratch 'invalid.json';[IO.File]::WriteAllText($path,$value,[Text.UTF8Encoding]::new($false));$rejected=$false;try{ConvertTo-ManagedPolicyV1 $path|Out-Null}catch{$rejected=$true};if(-not $rejected){throw 'Invalid policy unexpectedly accepted'}}
@('PASS: all five restricted/permissive sample controls parsed correctly','PASS: accepted explicit override precedence demonstrated','PASS: machine policy fallback and absent-policy public behaviour demonstrated','PASS: empty, malformed, unsupported schema, non-Boolean control and unknown field/control rejected')|Set-Content (Join-Path $build 'RELEASE-POLICY-CHECKS.txt')
Get-Content (Join-Path $build 'RELEASE-POLICY-CHECKS.txt')
