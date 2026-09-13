$ErrorActionPreference = "Stop"
Set-Location "C:\Users\halima\Documents\Daftari_flutter\daftari_UI"
$f = ".\android\app\build.gradle.kts"
if (-not (Test-Path $f)) { throw "File not found: $f" }

$c = Get-Content $f -Raw
$c = $c -replace 'compileSdk\s*=\s*[^\r\n]+', 'compileSdk = 34'
$c = $c -replace 'targetSdk\s*=\s*[^\r\n]+', 'targetSdk = 34'
# remove any ndkVersion line if present
$c = [regex]::Replace($c, '(?m)^\s*ndkVersion\s*=.*\r?\n', '')
Set-Content -Path $f -Value $c -Encoding UTF8

Write-Host "==== verify ====" -ForegroundColor Green
Select-String -Path $f -Pattern "compileSdk|targetSdk|ndkVersion"

$props = ".\android\gradle.properties"
$p = @()
if (Test-Path $props) { $p = Get-Content $props | Where-Object { $_ -notmatch 'sdkDownload' } }
$p += "android.builder.sdkDownload=false"
$p | Set-Content $props -Encoding UTF8

Write-Host "Done. Now run:" -ForegroundColor Cyan
Write-Host "flutter clean; flutter pub get; flutter run -d emulator-5554"
