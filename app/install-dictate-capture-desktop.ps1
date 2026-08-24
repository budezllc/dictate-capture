# Writes desktop shortcuts. Double-click after you quit a tray icon. No reboot.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$starter = Join-Path $here "start-dictate-helper.ps1"
$desktop = [Environment]::GetFolderPath("Desktop")

function Write-DesktopCmd([string]$cmdName, [string]$body) {
  $cmdPath = Join-Path $desktop $cmdName
  Set-Content -Path $cmdPath -Value $body -Encoding ASCII
  Write-Host "Wrote $cmdPath"
}

$startOne = {
  param([string]$scriptName)
  "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$starter`" -ScriptName $scriptName"
}

Write-DesktopCmd "Dictate Grok.cmd" (& $startOne "grokbot-capture.ps1")
Write-DesktopCmd "Dictate Cursor.cmd" (& $startOne "cursor-capture.ps1")
Write-DesktopCmd "Dictate both.cmd" @"
powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$starter" -ScriptName grokbot-capture.ps1
powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$starter" -ScriptName cursor-capture.ps1
"@

Write-Host "Desktop: Dictate Grok, Dictate Cursor, Dictate both. Double-click after you quit a tray icon."
