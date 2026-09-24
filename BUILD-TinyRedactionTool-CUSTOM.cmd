@echo off
setlocal
cd /d "%~dp0"
title TinyRedactionTool v2.2.0 - Secure Custom Builder
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-TinyRedactionTool-Custom.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo Build failed with exit code %RC%.
) else (
  echo Final v2.2.0 build finished successfully.
)
echo.
pause
exit /b %RC%
