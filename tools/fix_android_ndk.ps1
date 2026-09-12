# إصلاح فشل بناء Android بسبب NDK
# شغّلي هذا الملف من داخل مجلد المشروع:
#   powershell -ExecutionPolicy Bypass -File tools\fix_android_ndk.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$appGradle = Join-Path $root "android\app\build.gradle.kts"
$props = Join-Path $root "android\gradle.properties"

if (-not (Test-Path $appGradle)) {
  Write-Host "لم يتم العثور على: $appGradle" -ForegroundColor Red
  exit 1
}

$content = Get-Content $appGradle -Raw
$content = [regex]::Replace($content, '(?m)^\s*ndkVersion\s*=\s*flutter\.ndkVersion\s*\r?\n', '')
Set-Content -Path $appGradle -Value $content -NoNewline

$propText = Get-Content $props -Raw
if ($propText -notmatch 'android\.builder\.sdkDownload\s*=\s*false') {
  Add-Content -Path $props -Value "`nandroid.builder.sdkDownload=false"
}

Write-Host "تم التعديل. الآن نفّذي:" -ForegroundColor Green
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run -d emulator-5554"
