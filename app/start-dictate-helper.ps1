param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("grokbot-capture.ps1", "cursor-capture.ps1")]
  [string]$ScriptName
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = Join-Path $here $ScriptName
if (-not (Test-Path -LiteralPath $script)) { exit 1 }

$running = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Name -match 'powershell' -and $_.CommandLine -and
    ($_.CommandLine -like "*$ScriptName*") -and
    ($_.CommandLine -notlike "*start-dictate-helper.ps1*")
  }
if ($running) { exit 0 }

Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $script
) | Out-Null
