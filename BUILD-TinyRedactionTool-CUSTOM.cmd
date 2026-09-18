@echo off
setlocal
cd /d "%~dp0"
title TinyRedactionTool - Secure Custom FFmpeg Builder v2.1.0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-TinyRedactionTool-Custom.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo Build failed with exit code %RC%.
) else (
  echo Build finished successfully.
)
echo.
pause
exit /b %RC%
