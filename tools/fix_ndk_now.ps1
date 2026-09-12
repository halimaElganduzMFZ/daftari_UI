# أصلحي مشكلة NDK محلياً فوراً (بدون انتظار GitHub)
# انسخي كل الأوامر والصقيها في PowerShell داخل مجلد المشروع

$proj = "C:\Users\halima\Documents\Daftari_flutter\daftari_UI"
Set-Location $proj

$appGradle = ".\android\app\build.gradle.kts"
$props = ".\android\gradle.properties"

Write-Host "===== قبل التعديل =====" -ForegroundColor Yellow
Select-String -Path $appGradle -Pattern "ndkVersion" -SimpleMatch
Get-Content $appGradle

# 1) احذف أي سطر ndkVersion
$lines = Get-Content $appGradle | Where-Object { $_ -notmatch '^\s*ndkVersion\s*=' }
$lines | Set-Content $appGradle -Encoding UTF8

# 2) عطّل تنزيل SDK/NDK التلقائي
$propLines = Get-Content $props
$propLines = $propLines | Where-Object { $_ -notmatch 'sdkDownload' }
$propLines += "android.builder.sdkDownload=false"
$propLines | Set-Content $props -Encoding UTF8

Write-Host "===== بعد التعديل =====" -ForegroundColor Green
Select-String -Path $appGradle -Pattern "ndkVersion" -SimpleMatch
if (-not (Select-String -Path $appGradle -Pattern "ndkVersion" -SimpleMatch)) {
  Write-Host "تم حذف ndkVersion بنجاح" -ForegroundColor Green
} else {
  Write-Host "ما زال ndkVersion موجوداً!" -ForegroundColor Red
}
Get-Content $props | Select-String "sdkDownload"

Write-Host "الآن نفّذي:" -ForegroundColor Cyan
Write-Host "flutter clean; flutter pub get; flutter run -d emulator-5554"
