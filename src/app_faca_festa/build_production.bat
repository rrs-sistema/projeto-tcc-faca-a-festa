@echo off
setlocal
cd /d "%~dp0"
python "%~dp0build_production.py" %*
exit /b %ERRORLEVEL%
