param([string]$HelperPath = (Join-Path $PSScriptRoot '../.codex_tmp/native-tests/helper.exe'))
$ErrorActionPreference='Stop'
$taskDirectory=Join-Path ([IO.Path]::GetTempPath()) ('faca-festa-helper-failures-'+[guid]::NewGuid())
New-Item -ItemType Directory -Path $taskDirectory | Out-Null
$taskSource=Join-Path $taskDirectory 'fixture.cs'
@'
using System;
using System.IO;
using System.Threading;
class Fixture {
 static int Main(string[] args) {
  string trace=Environment.GetEnvironmentVariable("FACA_FESTA_HELPER_FAILURE_TRACE");
  if(args.Length>0 && args[0]=="--parent") { Thread.Sleep(4000); return 0; }
  if(args.Length==0) { File.AppendAllText(trace,"restarted\n"); return 0; }
  File.AppendAllText(trace,"installed\n");
  string mode=Environment.GetEnvironmentVariable("FACA_FESTA_HELPER_FAILURE_MODE");
  if(mode=="slow") Thread.Sleep(3000);
  return mode=="fail"?23:0;
 }
}
'@ | Set-Content -LiteralPath $taskSource
$taskFixture=Join-Path $taskDirectory 'fixture.exe'
& (Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe') /nologo /target:winexe "/out:$taskFixture" $taskSource
if($LASTEXITCODE -ne 0){throw 'Fixture compile failed'}
$taskPreviousTrace=$env:FACA_FESTA_HELPER_FAILURE_TRACE
$taskPreviousMode=$env:FACA_FESTA_HELPER_FAILURE_MODE
function Invoke-TestHelper($taskInstaller,$taskParentId,$taskHash) {
 $taskArguments=@('"'+$taskInstaller+'"',$taskParentId,'"'+$taskFixture+'"',$taskHash)-join ' '
 $taskProcess=Start-Process -FilePath $HelperPath -ArgumentList $taskArguments -WindowStyle Hidden -PassThru
 if(!$taskProcess.WaitForExit(7000)){throw 'Helper deadline failed'}
 return $taskProcess.ExitCode
}
try {
 foreach($taskMode in @('tampered','parent-timeout','fail','slow')) {
  $taskTrace=Join-Path $taskDirectory "$taskMode.txt"
  $env:FACA_FESTA_HELPER_FAILURE_TRACE=$taskTrace
  $env:FACA_FESTA_HELPER_FAILURE_MODE=$taskMode
  $taskInstaller=Join-Path $taskDirectory "$taskMode.exe"
  Copy-Item -LiteralPath $taskFixture -Destination $taskInstaller
  $taskHash=(Get-FileHash -LiteralPath $taskInstaller -Algorithm SHA256).Hash.ToLowerInvariant()
  $taskParentId=4294967294
  if($taskMode -eq 'tampered') { [IO.File]::AppendAllText($taskInstaller,'tampered') }
  if($taskMode -eq 'parent-timeout') {
   $taskParent=Start-Process -FilePath $taskFixture -ArgumentList '--parent' -WindowStyle Hidden -PassThru
   $taskParentId=$taskParent.Id
  }
  $taskCode=Invoke-TestHelper $taskInstaller $taskParentId $taskHash
  Start-Sleep -Milliseconds 300
  $taskText=if(Test-Path $taskTrace){[IO.File]::ReadAllText($taskTrace)}else{''}
  switch($taskMode) {
   'tampered' { if($taskCode -ne 1 -or $taskText.Contains('installed') -or !$taskText.Contains('restarted')){throw 'Tampered installer was not rejected'} }
   'parent-timeout' { if($taskCode -ne 3 -or $taskText -ne '' -or $taskParent.HasExited){throw 'Parent timeout was not respected'}; $taskParent.WaitForExit(5000)|Out-Null }
   'fail' { if($taskCode -ne 23 -or $taskText -notmatch 'installed\s+restarted'){throw 'Failed installation did not restart previous executable'} }
   'slow' { if($taskCode -ne 4 -or $taskText.Contains('restarted')){throw 'Installer timeout was not respected'}; Start-Sleep -Milliseconds 1800 }
  }
  if(!(Test-Path $taskInstaller)){throw 'Failed package unexpectedly removed'}
  Write-Output "OK: $taskMode"
 }
} finally { $env:FACA_FESTA_HELPER_FAILURE_TRACE=$taskPreviousTrace; $env:FACA_FESTA_HELPER_FAILURE_MODE=$taskPreviousMode }
