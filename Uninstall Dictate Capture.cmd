@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\uninstall-dictate-capture.ps1"
if errorlevel 1 (
  echo Uninstall failed.
  pause
  exit /b 1
)
echo.
echo Removed. You can also uninstall from Settings, Apps, Installed apps.
pause
