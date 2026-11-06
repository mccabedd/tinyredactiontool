@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BUILD-v2.5.1.ps1"
if errorlevel 1 pause
