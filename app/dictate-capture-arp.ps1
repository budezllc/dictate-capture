# Shared install/uninstall helpers. No machine home paths. Per-user only (no admin).
$DictateCaptureVersion = "1.0.0"
$DictateCaptureDisplayName = "Dictate Capture"
$DictateCapturePublisher = "budez LLC"
$DictateCaptureHelpLink = "https://github.com/budezllc/dictate-capture"
$DictateCaptureUninstallKeyName = "DictateCapture"

function Get-DictateCaptureInstallDir {
  if ($env:DICTATE_CAPTURE_INSTALL_DIR) { return $env:DICTATE_CAPTURE_INSTALL_DIR }
  Join-Path $env:LOCALAPPDATA "DictateCapture"
}

function Get-DictateCaptureUninstallRegPath {
  if ($env:DICTATE_CAPTURE_UNINSTALL_KEY) { return $env:DICTATE_CAPTURE_UNINSTALL_KEY }
  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$DictateCaptureUninstallKeyName"
}

function Get-DictateCaptureFileNames {
  @(
    "grokbot-capture.ps1",
    "cursor-capture.ps1",
    "start-dictate-helper.ps1",
    "install-dictate-capture-autostart.ps1",
    "install-dictate-capture-desktop.ps1",
    "uninstall-dictate-capture-autostart.ps1",
    "uninstall-dictate-capture.ps1",
    "dictate-capture-arp.ps1"
  )
}

function Copy-DictateCaptureFiles {
  param(
    [Parameter(Mandatory = $true)][string]$From,
    [Parameter(Mandatory = $true)][string]$To
  )
  New-Item -ItemType Directory -Force -Path $To | Out-Null
  foreach ($name in Get-DictateCaptureFileNames) {
    $src = Join-Path $From $name
    if (-not (Test-Path -LiteralPath $src)) { continue }
    Copy-Item -LiteralPath $src -Destination (Join-Path $To $name) -Force
  }
  $readme = Join-Path $From "README.md"
  if (-not (Test-Path -LiteralPath $readme)) {
    $readme = Join-Path (Split-Path -Parent $From) "README.md"
  }
  if (Test-Path -LiteralPath $readme) {
    Copy-Item -LiteralPath $readme -Destination (Join-Path $To "README.md") -Force
  }
  Get-ChildItem -LiteralPath $To -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in ".ps1", ".cmd", ".md" } |
    Unblock-File -ErrorAction SilentlyContinue
}

function Register-DictateCaptureArp {
  param(
    [Parameter(Mandatory = $true)][string]$InstallDir
  )
  $key = Get-DictateCaptureUninstallRegPath
  $uninstall = Join-Path $InstallDir "uninstall-dictate-capture.ps1"
  $uninstallCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$uninstall`""
  New-Item -Path $key -Force | Out-Null
  New-ItemProperty -Path $key -Name "DisplayName" -Value $DictateCaptureDisplayName -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "Publisher" -Value $DictateCapturePublisher -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "DisplayVersion" -Value $DictateCaptureVersion -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "HelpLink" -Value $DictateCaptureHelpLink -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "InstallLocation" -Value $InstallDir -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "UninstallString" -Value $uninstallCmd -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "QuietUninstallString" -Value $uninstallCmd -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $key -Name "NoModify" -Value 1 -PropertyType DWord -Force | Out-Null
  New-ItemProperty -Path $key -Name "NoRepair" -Value 1 -PropertyType DWord -Force | Out-Null
}

function Unregister-DictateCaptureArp {
  $key = Get-DictateCaptureUninstallRegPath
  if (Test-Path -LiteralPath $key) {
    Remove-Item -LiteralPath $key -Recurse -Force
  }
}

function Stop-DictateCaptureHelpers {
  $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
      $_.Name -match 'powershell' -and $_.CommandLine -and
      (
        $_.CommandLine -like "*grokbot-capture.ps1*" -or
        $_.CommandLine -like "*cursor-capture.ps1*"
      ) -and
      ($_.CommandLine -notlike "*start-dictate-helper.ps1*") -and
      ($_.CommandLine -notlike "*uninstall-dictate-capture.ps1*")
    }
  foreach ($p in @($procs)) {
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
  }
}

function Remove-DictateCaptureDesktopCmds {
  $desktop = [Environment]::GetFolderPath("Desktop")
  @(
    "Dictate Grok.cmd",
    "Dictate Cursor.cmd",
    "Dictate both.cmd"
  ) | ForEach-Object {
    $p = Join-Path $desktop $_
    if (Test-Path -LiteralPath $p) {
      Remove-Item -LiteralPath $p -Force
    }
  }
}

function Remove-DictateCaptureInstallDir {
  param([Parameter(Mandatory = $true)][string]$InstallDir)
  $expected = Join-Path $env:LOCALAPPDATA "DictateCapture"
  $left = [IO.Path]::GetFullPath($InstallDir)
  $right = [IO.Path]::GetFullPath($expected)
  if ($left -ne $right) { return }
  Start-Process -FilePath "cmd.exe" -WindowStyle Hidden -ArgumentList @(
    "/c", "timeout /t 1 /nobreak >nul & rmdir /s /q `"$left`""
  ) | Out-Null
}
