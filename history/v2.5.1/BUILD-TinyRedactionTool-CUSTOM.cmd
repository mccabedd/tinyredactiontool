@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-TinyRedactionTool-Custom.ps1"
if errorlevel 1 pause
