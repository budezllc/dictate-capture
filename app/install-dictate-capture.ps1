# Per-user product install. Shows up in Settings > Apps (Add or remove programs).
# Copies files under LocalAppData, login start, desktop shortcuts, tray helpers. No admin.
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here "dictate-capture-arp.ps1")

$dest = Get-DictateCaptureInstallDir
Copy-DictateCaptureFiles -From $here -To $dest
Register-DictateCaptureArp -InstallDir $dest
Stop-DictateCaptureHelpers
& (Join-Path $dest "install-dictate-capture-autostart.ps1")
Write-Host "Installed $DictateCaptureDisplayName $DictateCaptureVersion. Remove it from Apps, or run Uninstall Dictate Capture.cmd."
