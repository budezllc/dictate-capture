# Full uninstall: stop helpers, login start, desktop shortcuts, Apps entry, install folder.
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here "dictate-capture-arp.ps1")

Stop-DictateCaptureHelpers
& (Join-Path $here "uninstall-dictate-capture-autostart.ps1")
Remove-DictateCaptureDesktopCmds
$dest = $null
$reg = Get-DictateCaptureUninstallRegPath
if (Test-Path -LiteralPath $reg) {
  $dest = (Get-ItemProperty -LiteralPath $reg -ErrorAction SilentlyContinue).InstallLocation
}
Unregister-DictateCaptureArp
if (-not $dest) { $dest = Get-DictateCaptureInstallDir }
Remove-DictateCaptureInstallDir -InstallDir $dest
Write-Host "Removed $DictateCaptureDisplayName from this user account."
