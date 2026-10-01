# يشغّل وسيط الـ API ثم خادم فلاتر على كل واجهات الشبكة.
# من أي جهاز: http://<IP هذا الجهاز>:43123
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

function Resolve-SdkTool([string]$name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $fallback = Join-Path $env:USERPROFILE "Development\flutter\bin\$name.bat"
  if (Test-Path $fallback) { return $fallback }
  throw "$name was not found. Add the Flutter SDK bin folder to PATH."
}

$dart = Resolve-SdkTool "dart"
$flutter = Resolve-SdkTool "flutter"

$ip = Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -ne "WellKnown"
  } |
  Select-Object -First 1 -ExpandProperty IPAddress
if (-not $ip) { $ip = "127.0.0.1" }

foreach ($port in 43123, 43124) {
  $name = "Daftari web $port"
  $existing = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
  if ($existing) { continue }
  try {
    New-NetFirewallRule -DisplayName $name -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -Profile Private, Domain | Out-Null
  } catch {
    Write-Host "Firewall rule for port $port was not added. Allow it manually if other devices cannot connect."
  }
}

Write-Host ""
Write-Host "Open from this PC or any device on the network:"
Write-Host "  http://${ip}:43123"
Write-Host ""

$proxy = Start-Process -FilePath $dart -ArgumentList @("run", "tool/web_api_proxy.dart") -WorkingDirectory $root -PassThru -NoNewWindow
try {
  & $flutter run -d web-server --profile --no-web-resources-cdn --web-hostname 0.0.0.0 --web-port=43123 --web-launch-url="http://${ip}:43123"
} finally {
  if ($proxy -and -not $proxy.HasExited) {
    Stop-Process -Id $proxy.Id -Force
  }
}
