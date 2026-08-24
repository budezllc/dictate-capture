@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\install-dictate-capture.ps1"
if errorlevel 1 (
  echo Install failed.
  pause
  exit /b 1
)
echo.
echo Installed. Look for G and C next to the clock.
echo Remove it later from Settings, Apps, Installed apps.
pause
