$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskCache = Join-Path $taskRoot '.dart_tool/winsparkle-0.9.4'
$taskZip = Join-Path $taskCache 'WinSparkle-0.9.4.zip'
$taskTool = Join-Path $taskCache 'WinSparkle-0.9.4/bin/winsparkle-tool.exe'
New-Item -ItemType Directory -Path $taskCache -Force | Out-Null
if (!(Test-Path -LiteralPath $taskZip)) {
  Invoke-WebRequest -Uri 'https://github.com/vslavik/winsparkle/releases/download/v0.9.4/WinSparkle-0.9.4.zip' -OutFile $taskZip -TimeoutSec 120
}
$taskStream = [IO.File]::OpenRead($taskZip)
$taskAlgorithm = [Security.Cryptography.SHA256]::Create()
try { $taskHash = [BitConverter]::ToString($taskAlgorithm.ComputeHash($taskStream)).Replace('-', '') }
finally { $taskStream.Dispose(); $taskAlgorithm.Dispose() }
if ($taskHash -ne '6037DF37FC263BD1650A1C4949681A9D40FFE991D01F35892A406CB5D103C976') {
  throw 'Download do WinSparkle não corresponde à versão fixada.'
}
if (!(Test-Path -LiteralPath $taskTool)) {
  [void][Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
  [IO.Compression.ZipFile]::ExtractToDirectory($taskZip, $taskCache)
}
$taskTool

