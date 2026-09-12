# يصلح فشل sdkmanager + NDK على Windows فوراً
# شغّليه من PowerShell:
#   cd C:\Users\halima\Documents\Daftari_flutter\daftari_UI
#   powershell -ExecutionPolicy Bypass -File .\tools\fix_ndk_windows.ps1

$ErrorActionPreference = "Stop"

$proj = Split-Path -Parent $PSScriptRoot
Set-Location $proj

$ndkVersion = "28.2.13676358"
$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\sdk"
$ndkRoot = Join-Path $sdkRoot "ndk\$ndkVersion"
$sourceProps = Join-Path $ndkRoot "source.properties"

Write-Host "Project: $proj"
Write-Host "SDK:     $sdkRoot"
Write-Host "NDK stub: $ndkRoot"

# 1) احذف ndkVersion من Gradle إن وُجد
$appGradle = ".\android\app\build.gradle.kts"
if (Test-Path $appGradle) {
  $content = Get-Content $appGradle
  $filtered = $content | Where-Object { $_ -notmatch '^\s*ndkVersion\s*=' }
  $filtered | Set-Content $appGradle -Encoding UTF8
  Write-Host "Cleaned ndkVersion from app/build.gradle.kts"
}

# 2) عطّل تنزيل SDK التلقائي
$props = ".\android\gradle.properties"
$propContent = @()
if (Test-Path $props) {
  $propContent = Get-Content $props | Where-Object { $_ -notmatch 'sdkDownload' }
}
$propContent += "android.builder.sdkDownload=false"
$propContent | Set-Content $props -Encoding UTF8
Write-Host "Set android.builder.sdkDownload=false"

# 3) أنشئ NDK stub حتى لا يستدعي Gradle sdkmanager المعطوب
New-Item -ItemType Directory -Force -Path $ndkRoot | Out-Null
@"
Pkg.Desc = Android NDK
Pkg.Revision = $ndkVersion
"@ | Set-Content $sourceProps -Encoding ASCII

Write-Host "Created NDK stub source.properties" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT:" -ForegroundColor Cyan
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run -d emulator-5554"
