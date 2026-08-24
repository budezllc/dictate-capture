# Writes two shortcuts in the current user's Startup folder.
# Those start hidden PowerShell helpers at sign-in. They do not take admin rights.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$starter = Join-Path $here "start-dictate-helper.ps1"
$startup = [Environment]::GetFolderPath("Startup")

function Write-StartupCmd([string]$scriptName, [string]$cmdName) {
  $cmdPath = Join-Path $startup $cmdName
  $line = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$starter`" -ScriptName $scriptName"
  Set-Content -Path $cmdPath -Value $line -Encoding ASCII
  Write-Host "Wrote $cmdPath"
}

Write-StartupCmd "grokbot-capture.ps1" "dictate-grokbot-capture.cmd"
Write-StartupCmd "cursor-capture.ps1" "dictate-cursor-capture.cmd"

& (Join-Path $here "install-dictate-capture-desktop.ps1")
& (Join-Path $here "start-dictate-helper.ps1") -ScriptName "grokbot-capture.ps1"
& (Join-Path $here "start-dictate-helper.ps1") -ScriptName "cursor-capture.ps1"

Write-Host "Both helpers start at logon. Ctrl+D is Grok Bot, Ctrl+M is Cursor."
Write-Host "Desktop shortcuts: Dictate Grok, Dictate Cursor, Dictate both."
Write-Host "Remove those two .cmd files from the Startup folder to uninstall, or run uninstall-dictate-capture-autostart.ps1"
