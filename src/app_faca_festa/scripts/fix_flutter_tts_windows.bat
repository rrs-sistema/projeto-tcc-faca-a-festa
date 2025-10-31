@echo off
setlocal enabledelayedexpansion
set TARGET=build\windows\flutter\ephemeral\.plugin_symlinks\flutter_tts\windows\CMakeLists.txt

echo Verificando flutter_tts...

if not exist "%TARGET%" (
  echo Arquivo do flutter_tts ainda não existe. Aguarde a geracao inicial.
  echo Execute primeiro: flutter pub get
  exit /b
)

echo Corrigindo CMakeLists do flutter_tts...
powershell -Command "(Get-Content '%TARGET%') -replace 'find_program\(NUGET_EXE.*', '# find_program(NUGET_EXE desativado pelo script Rivaldo)' | Set-Content '%TARGET%'"
powershell -Command "(Get-Content '%TARGET%') -replace 'message\(FATAL_ERROR.*', '# message(FATAL_ERROR desativado pelo script Rivaldo)' | Set-Content '%TARGET%'"

echo ✅ Correção concluída com sucesso!
endlocal
