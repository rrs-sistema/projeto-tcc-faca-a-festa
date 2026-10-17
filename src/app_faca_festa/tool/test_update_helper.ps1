param([string]$HelperPath = (Join-Path $PSScriptRoot '../build/windows/x64/runner/Release/faca_festa_update_helper.exe'))
$ErrorActionPreference = 'Stop'
# Instalação simulada: executáveis de teste, sem tocar no aplicativo ou dados.
$taskDirectory = Join-Path ([IO.Path]::GetTempPath()) ('faca-festa-helper-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $taskDirectory | Out-Null
$taskSource = Join-Path $taskDirectory 'fixture.cs'
@'
using System;
using System.IO;
using System.Threading;
class Fixture {
  static void Main(string[] args) {
    string trace = Environment.GetEnvironmentVariable("FACA_FESTA_HELPER_TEST_TRACE");
    if (args.Length > 0 && args[0] == "--parent") {
      Thread.Sleep(1500);
      File.AppendAllText(trace, "parent-exited\n");
    } else if (args.Length > 0) {
      File.AppendAllText(trace, "installer:" + string.Join(" ", args) + "\n");
    } else {
      File.AppendAllText(trace, "restarted\n");
    }
  }
}
'@ | Set-Content -LiteralPath $taskSource
$taskCompiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$taskFixture = Join-Path $taskDirectory 'fixture.exe'
& $taskCompiler /nologo /target:winexe "/out:$taskFixture" $taskSource
if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar fixture.' }
$taskInstaller = Join-Path $taskDirectory 'installer.exe'
Copy-Item -LiteralPath $taskFixture -Destination $taskInstaller
$taskHash = (Get-FileHash -LiteralPath $taskInstaller -Algorithm SHA256).Hash.ToLowerInvariant()
$taskTrace = Join-Path $taskDirectory 'trace.txt'
$taskPreviousTrace = $env:FACA_FESTA_HELPER_TEST_TRACE
try {
  $env:FACA_FESTA_HELPER_TEST_TRACE = $taskTrace
  $taskParent = Start-Process -FilePath $taskFixture -ArgumentList '--parent' -WindowStyle Hidden -PassThru
  $taskHelper = $HelperPath
  $taskArguments = @('"' + $taskInstaller + '"', $taskParent.Id, '"' + $taskFixture + '"', $taskHash) -join ' '
  $taskProcess = Start-Process -FilePath $taskHelper -ArgumentList $taskArguments -WindowStyle Hidden -PassThru
  if (!$taskProcess.WaitForExit(15000)) { throw 'Helper não terminou no prazo.' }
  if ($taskProcess.ExitCode -ne 0) { throw "Helper falhou: $($taskProcess.ExitCode)" }
  # A reabertura é assíncrona; aguarda apenas a fixture produzir o registro.
  $taskDeadline = [DateTime]::UtcNow.AddSeconds(5)
  do {
    Start-Sleep -Milliseconds 100
    $taskText = [IO.File]::ReadAllText($taskTrace)
  } while (!$taskText.Contains('restarted') -and [DateTime]::UtcNow -lt $taskDeadline)
  if ($taskText -notmatch '(?s)^parent-exited\s+installer:/SILENT.*restarted') { throw "Sequência incorreta: $taskText" }
  if (Test-Path -LiteralPath $taskInstaller) { throw 'Pacote não removido após sucesso.' }
  Write-Output 'OK: helper aguardou a saída, executou instalador simulado e reabriu a fixture.'
} finally { $env:FACA_FESTA_HELPER_TEST_TRACE = $taskPreviousTrace }

