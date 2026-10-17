$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskVs = Join-Path ${env:ProgramFiles} 'Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat'
$taskEnvironment = & cmd.exe /c "`"$taskVs`" >nul && set"
foreach ($taskEntry in $taskEnvironment) {
  if ($taskEntry -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable($matches[1],$matches[2],'Process') }
}
$taskOutput = Join-Path $taskRoot '.codex_tmp/native-tests'
New-Item -ItemType Directory -Force -Path $taskOutput | Out-Null
& cl.exe /nologo /EHsc /std:c++17 /utf-8 /O2 /DUNICODE /D_UNICODE /DFACA_FESTA_HELPER_TEST "$(Join-Path $taskRoot 'windows/runner/update_helper.cpp')" "/Fo$taskOutput/helper.obj" "/Fe$taskOutput/helper.exe" /link /SUBSYSTEM:WINDOWS bcrypt.lib shell32.lib user32.lib
if ($LASTEXITCODE -ne 0) { throw 'Helper test compile failed' }
$taskSparkle = Join-Path $taskRoot '.dart_tool/winsparkle-0.9.4/WinSparkle-0.9.4'
& cl.exe /nologo /EHsc /std:c++17 /utf-8 /O2 /DUNICODE /D_UNICODE "/I$taskSparkle/include" "$(Join-Path $PSScriptRoot 'desktop_update_smoke.cpp')" "/Fo$taskOutput/smoke.obj" "/Fe$taskOutput/smoke.exe" /link /LIBPATH:"$taskSparkle/x64/Release" WinSparkle.lib bcrypt.lib
if ($LASTEXITCODE -ne 0) { throw 'WinSparkle smoke compile failed' }
Copy-Item -LiteralPath (Join-Path $taskSparkle 'x64/Release/WinSparkle.dll') -Destination $taskOutput
Write-Output $taskOutput
