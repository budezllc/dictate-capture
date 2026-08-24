$ErrorActionPreference = "Stop"
$testsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent $testsDir
$app = Join-Path $repo "app"
$fail = 0
function Assert-True($cond, $msg) {
  if ($cond) { Write-Host "ok  $msg" }
  else { Write-Host "FAIL $msg"; $script:fail++ }
}

$grok = Get-Content -Raw (Join-Path $app "grokbot-capture.ps1")
$cur = Get-Content -Raw (Join-Path $app "cursor-capture.ps1")
Assert-True ($grok -match 'grokbot-crops') "grokbot crop temp folder is grokbot-crops"
Assert-True ($grok -match 'const int VK_D = 0x44') "grokbot still Ctrl+D"
Assert-True ($grok -match 'public static class SwallowD') "grokbot hook type unchanged"
Assert-True ($cur -match 'const int VK_M = 0x4D') "cursor helper swallows extra M"
Assert-True ($cur -match 'KeyDown 0x4D') "cursor chord is Ctrl+M"
Assert-True ($cur -notmatch 'KeyDown 0x44') "cursor timer does not use D"
Assert-True ($cur -match 'public static class CursorSwallowM') "cursor types are unique"
Assert-True ($cur -match 'public static class CursorMouseBox') "cursor mouse hook is unique"
Assert-True ($cur -match 'Global\\CursorCaptureHelper') "cursor has its own mutex"
Assert-True ($cur -match 'cursor-crops') "cursor crops go to a separate temp folder"
Assert-True ($cur -match 'if \(!_pass\) \{') "cursor tracks injected quick-key Ctrl+M"
Assert-True ($cur -match 'if \(_seenM\) return') "cursor swallows only extra M"
Assert-True ($cur -notmatch 'EatAllD') "cursor does not eat the first M"
Assert-True ($cur -match '\[CursorMouseBox\]::Arm = \[bool\]\(\$talk -or \$chord\)') "cursor arms the gold box on Ctrl+M hold like Grok"
Assert-True ($cur -match 'if \(\$script:pendingFile\) \{ Flush-Paste \}') "cursor pastes the crop on release"
Assert-True ($grok -notmatch 'SendWait\("\{ENTER\}"\)') "grok does not press Enter"
Assert-True ($cur -notmatch 'SendWait\("\{ENTER\}"\)') "cursor does not press Enter"
Assert-True ($grok -match 'NotifyIcon') "grok has a tray icon"
Assert-True ($cur -match 'NotifyIcon') "cursor has a tray icon"
Assert-True ($grok -match 'Grok capture - click to quit') "grok tray tooltip says click to quit"
Assert-True ($cur -match 'Cursor capture - click to quit') "cursor tray tooltip says click to quit"
Assert-True ($grok -notmatch 'GrokQuitChip') "grok has no on-screen quit chip"
Assert-True ($cur -notmatch 'CursorQuitChip') "cursor has no on-screen quit chip"
Assert-True ($cur -notmatch 'Invoke-CursorVoiceToggle') "cursor does not click the mic"
Assert-True ($cur -match 'skipped="grok-bot"') "cursor will not press Enter into Grok Bot"
Assert-True ($grok -notmatch 'skipped="not-grok-bot"') "grok does not skip paste based on front window"
Assert-True ($cur -notmatch 'skipped="not-cursor"') "cursor does not skip paste when dictation takes focus"
Assert-True ($grok -match '\[MouseBox\]::Boxing -or \$script:boxing') "grok waits for the gold box to finish"
Assert-True ($cur -match '\[CursorMouseBox\]::Boxing -or \$script:boxing') "cursor waits for the gold box to finish"
Assert-True ($grok -match 'Global\\GrokBotCaptureHelper') "grokbot has its own mutex"
Assert-True ($grok -match 'info.vk != VK_D') "grok hook ignores keys other than Ctrl and D"
Assert-True ($cur -match 'info.vk != VK_M') "cursor hook ignores keys other than Ctrl and M"
Assert-True ($grok -match 'SetFileDropList') "grok pastes crop as a file drop"
Assert-True ($cur -match 'SetFileDropList') "cursor pastes crop as a file drop"
Assert-True ($grok -notmatch 'Restore-ClipboardData') "grok does not restore clipboard over the crop"
Assert-True ($cur -notmatch 'Restore-ClipboardData') "cursor does not restore clipboard over the crop"
Assert-True ($grok -match 'Filter "rect-\*\.png"') "grok deletes leftover crop pngs"
Assert-True ($cur -match 'Filter "rect-\*\.png"') "cursor deletes leftover crop pngs"
Assert-True ($grok -notmatch 'function Focus-Compose') "grok has no Focus-Compose"
Assert-True ($cur -notmatch 'function Focus-Compose') "cursor has no Focus-Compose"
Assert-True ($grok -notmatch 'function Replay-TalkChord') "grok has no Replay-TalkChord"
Assert-True ($cur -notmatch 'function Replay-TalkChord') "cursor has no Replay-TalkChord"

$install = Get-Content -Raw (Join-Path $app "install-dictate-capture-autostart.ps1")
$helper = Get-Content -Raw (Join-Path $app "start-dictate-helper.ps1")
$uninstall = Get-Content -Raw (Join-Path $app "uninstall-dictate-capture-autostart.ps1")
$desktop = Get-Content -Raw (Join-Path $app "install-dictate-capture-desktop.ps1")
$readme = Get-Content -Raw (Join-Path $repo "README.md")
Assert-True ($install -match 'grokbot-capture.ps1' -and $install -match 'cursor-capture.ps1') "installer starts both helpers"
Assert-True ($install -match 'install-dictate-capture-desktop.ps1') "autostart installer also writes desktop shortcuts"
Assert-True ($install -notmatch 'Users\\') "installer has no machine home path"
Assert-True ($desktop -match 'GetFolderPath\("Desktop"\)') "desktop installer uses the Desktop folder"
Assert-True ($desktop -match 'Dictate Grok.cmd' -and $desktop -match 'Dictate Cursor.cmd' -and $desktop -match 'Dictate both.cmd') "desktop installer writes Grok, Cursor, and both"
Assert-True ($desktop -notmatch 'Users\\') "desktop installer has no machine home path"
Assert-True ($helper -match 'ValidateSet\("grokbot-capture.ps1", "cursor-capture.ps1"\)') "starter only launches the two capture scripts"
Assert-True ($helper -match 'CommandLine -like "\*\$ScriptName\*"') "starter skips a script that is already running"
Assert-True ($uninstall -match 'dictate-grokbot-capture.cmd' -and $uninstall -match 'dictate-cursor-capture.cmd') "uninstall removes both Startup cmds"
Assert-True ($readme -notmatch 'Users\\') "README has no machine home path"
Assert-True ($readme -match 'install-dictate-capture.ps1') "README documents the Apps installer"
Assert-True ($readme -match 'uninstall-dictate-capture-autostart.ps1') "README documents autostart uninstall"
Assert-True ($readme -match '## Install') "README has install steps for new machines"
Assert-True ($readme -match 'git clone') "README shows how to clone"
Assert-True ($readme -match 'Unblock-File') "README shows how to unblock a ZIP download"
Assert-True ($readme -match 'shell:startup') "README shows the Startup folder for one-app install"
Assert-True ($readme -match 'If it does not work') "README has a short if-it-fails note"
Assert-True ($readme -match 'hidden') "README says helpers can start hidden at login"
Assert-True ($readme -match 'Leftover pictures') "README says leftover crops are cleared on next start"
Assert-True ($readme -match 'Dictate both') "README documents desktop restart shortcuts"
Assert-True ($readme -match 'Add or remove programs') "README says it shows in Add or remove programs"
Assert-True ($readme -match 'Install Dictate Capture') "README tells noobs to double-click the install cmd"
Assert-True ($readme -match 'install-dictate-capture-desktop.ps1') "README says how to recreate desktop shortcuts"
Assert-True ($readme -match 'install-dictate-capture-autostart.ps1') "README documents autostart install from a moved folder"
Assert-True ($readme -match '## Stream Deck') "README has a Stream Deck section"
Assert-True ($readme -match 'Dictate Grok.streamDeckAction' -and $readme -match 'Dictate Cursor.streamDeckAction') "README names both Stream Deck buttons"
Assert-True ($readme -match 'user-attachments/assets/') "README embeds the demo with a GitHub video URL"
Assert-True ($readme -match 'dictate-capture-demo.mp4') "README points at the demo mp4"
Assert-True (-not (Test-Path -LiteralPath (Join-Path $repo "GrokFileDrop.cs"))) "GrokFileDrop.cs is gone"
Assert-True (-not (Test-Path -LiteralPath (Join-Path $repo "grokbot-capture.ps1"))) "helpers are not loose at the repo root"
Assert-True (Test-Path -LiteralPath (Join-Path $app "grokbot-capture.ps1")) "helpers live in app"
Assert-True (Test-Path -LiteralPath (Join-Path $repo "Install Dictate Capture.cmd")) "install cmd stays at repo root"

$product = Get-Content -Raw (Join-Path $app "install-dictate-capture.ps1")
$fullUninstall = Get-Content -Raw (Join-Path $app "uninstall-dictate-capture.ps1")
$arp = Get-Content -Raw (Join-Path $app "dictate-capture-arp.ps1")
$installCmd = Get-Content -Raw (Join-Path $repo "Install Dictate Capture.cmd")
$uninstallCmd = Get-Content -Raw (Join-Path $repo "Uninstall Dictate Capture.cmd")
Assert-True ($product -match 'Register-DictateCaptureArp' -and $product -match 'Copy-DictateCaptureFiles') "product installer copies files and registers Apps"
Assert-True ($product -match 'Stop-DictateCaptureHelpers') "product installer restarts helpers from the install copy"
Assert-True ($product -notmatch 'Users\\') "product installer has no machine home path"
Assert-True ($fullUninstall -match 'Stop-DictateCaptureHelpers' -and $fullUninstall -match 'Unregister-DictateCaptureArp') "Apps uninstall stops helpers and removes the Apps entry"
Assert-True ($fullUninstall -match 'Remove-DictateCaptureDesktopCmds' -and $fullUninstall -match 'Remove-DictateCaptureInstallDir') "Apps uninstall removes desktop shortcuts and the install folder"
Assert-True ($fullUninstall -notmatch 'Users\\') "Apps uninstall has no machine home path"
Assert-True ($arp -match 'CurrentVersion\\Uninstall\\\$DictateCaptureUninstallKeyName') "ARP key is the standard per-user Uninstall key"
Assert-True ($arp -match 'NoModify' -and $arp -match 'UninstallString') "ARP entry has UninstallString and hides Modify"
Assert-True ($arp -match 'GetFullPath\(\$InstallDir\)' -and $arp -match 'rmdir') "install-folder delete only runs for LocalAppData DictateCapture"
Assert-True ($arp -notmatch 'Users\\') "ARP helper has no machine home path"
Assert-True ($installCmd -match 'app\\install-dictate-capture.ps1') "install cmd launches the product installer in app"
Assert-True ($uninstallCmd -match 'app\\uninstall-dictate-capture.ps1') "uninstall cmd launches the product uninstaller in app"

. (Join-Path $app "dictate-capture-arp.ps1")
$oldUninstallKey = $env:DICTATE_CAPTURE_UNINSTALL_KEY
$tmpInstall = Join-Path $env:TEMP ("dictate-capture-test-" + [guid]::NewGuid().ToString("n"))
$env:DICTATE_CAPTURE_UNINSTALL_KEY = "HKCU:\Software\DictateCaptureTestUninstall"
try {
  if (Test-Path -LiteralPath $env:DICTATE_CAPTURE_UNINSTALL_KEY) {
    Remove-Item -LiteralPath $env:DICTATE_CAPTURE_UNINSTALL_KEY -Recurse -Force
  }
  Copy-DictateCaptureFiles -From $app -To $tmpInstall
  Assert-True (Test-Path -LiteralPath (Join-Path $tmpInstall "grokbot-capture.ps1")) "copy includes Grok helper"
  Assert-True (Test-Path -LiteralPath (Join-Path $tmpInstall "cursor-capture.ps1")) "copy includes Cursor helper"
  Assert-True (Test-Path -LiteralPath (Join-Path $tmpInstall "uninstall-dictate-capture.ps1")) "copy includes Apps uninstaller"
  Register-DictateCaptureArp -InstallDir $tmpInstall
  $arpProps = Get-ItemProperty -LiteralPath $env:DICTATE_CAPTURE_UNINSTALL_KEY
  Assert-True ($arpProps.DisplayName -eq "Dictate Capture") "ARP DisplayName is Dictate Capture"
  Assert-True ($arpProps.UninstallString -like "*uninstall-dictate-capture.ps1*") "ARP UninstallString runs the uninstaller"
  Assert-True ($arpProps.InstallLocation -eq $tmpInstall) "ARP InstallLocation is the copy folder"
  Assert-True ($arpProps.NoModify -eq 1) "ARP hides Modify"
  Unregister-DictateCaptureArp
  Assert-True (-not (Test-Path -LiteralPath $env:DICTATE_CAPTURE_UNINSTALL_KEY)) "ARP unregister deletes the test key"
  Remove-DictateCaptureInstallDir -InstallDir $tmpInstall
  Assert-True (Test-Path -LiteralPath $tmpInstall) "folder delete refuses paths that are not LocalAppData DictateCapture"
}
finally {
  if ($oldUninstallKey) { $env:DICTATE_CAPTURE_UNINSTALL_KEY = $oldUninstallKey }
  else { Remove-Item Env:DICTATE_CAPTURE_UNINSTALL_KEY -ErrorAction SilentlyContinue }
  if (Test-Path -LiteralPath "HKCU:\Software\DictateCaptureTestUninstall") {
    Remove-Item -LiteralPath "HKCU:\Software\DictateCaptureTestUninstall" -Recurse -Force
  }
  if (Test-Path -LiteralPath $tmpInstall) {
    Remove-Item -LiteralPath $tmpInstall -Recurse -Force
  }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Get-StreamDeckActionJson([string]$zipPath) {
  $z = [IO.Compression.ZipFile]::OpenRead($zipPath)
  try {
    $e = $z.Entries | Where-Object { $_.FullName -like '*manifest.json' -and $_.Length -gt 2000 } | Select-Object -First 1
    $sr = New-Object IO.StreamReader($e.Open())
    try { $sr.ReadToEnd() } finally { $sr.Dispose() }
  }
  finally { $z.Dispose() }
}
$sdDir = Join-Path $repo "streamdeck"
$sdGrok = Join-Path $sdDir "Dictate Grok.streamDeckAction"
$sdCur = Join-Path $sdDir "Dictate Cursor.streamDeckAction"
Assert-True (Test-Path -LiteralPath $sdGrok) "Stream Deck Grok button is in streamdeck"
Assert-True (Test-Path -LiteralPath $sdCur) "Stream Deck Cursor button is in streamdeck"
$sdGrokJson = Get-StreamDeckActionJson $sdGrok
$sdCurJson = Get-StreamDeckActionJson $sdCur
Assert-True ($sdGrokJson -notmatch 'Users\\') "Grok Stream Deck button has no machine home path"
Assert-True ($sdCurJson -notmatch 'Users\\') "Cursor Stream Deck button has no machine home path"
Assert-True ($sdGrokJson -match 'KeyCtrl": true' -and $sdGrokJson -match 'VKeyCode": 68') "Grok Stream Deck button sends Ctrl+D"
Assert-True ($sdCurJson -match 'KeyCtrl": true' -and $sdCurJson -match 'VKeyCode": 77') "Cursor Stream Deck button sends Ctrl+M"
Assert-True ($sdGrokJson -match 'Grok Bot') "Grok Stream Deck button opens Grok Bot"
Assert-True ($sdCurJson -match '"app_name": "Cursor"') "Cursor Stream Deck button opens Cursor"

$demo = Join-Path $repo "docs\dictate-capture-demo.mp4"
Assert-True (Test-Path -LiteralPath $demo) "demo video is in docs"
$fs = [IO.File]::OpenRead($demo)
try {
  $hdr = New-Object byte[] 12
  [void]$fs.Read($hdr, 0, 12)
}
finally { $fs.Dispose() }
Assert-True ([Text.Encoding]::ASCII.GetString($hdr).Contains("ftyp")) "demo video is an mp4"

$total = 106
$passed = $total - $fail
if ($fail -gt 0) { Write-Host "$fail failed, $passed passed"; exit 1 }
Write-Host "$passed passed"
exit 0
