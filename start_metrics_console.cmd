@echo off
setlocal
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File "%~dp0start_metrics_console.ps1"
if errorlevel 1 pause
