$startup = [Environment]::GetFolderPath("Startup")
@(
  "dictate-grokbot-capture.cmd",
  "dictate-cursor-capture.cmd"
) | ForEach-Object {
  $p = Join-Path $startup $_
  if (Test-Path -LiteralPath $p) {
    Remove-Item -LiteralPath $p -Force
    Write-Host "Removed $p"
  }
}
Write-Host "Autostart removed. Close the hidden PowerShell helpers if you also want them stopped now."
