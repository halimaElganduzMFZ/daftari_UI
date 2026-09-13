# إصلاح انهيار libflutter.so على ويندوز
# الصقي الأوامر في PowerShell داخل مجلد المشروع

$ErrorActionPreference = "Stop"
Set-Location "C:\Users\halima\Documents\Daftari_flutter\daftari_UI"

Write-Host "1) Pull latest fix..." -ForegroundColor Cyan
git pull

Write-Host "2) Remove broken NDK stub (critical)..." -ForegroundColor Cyan
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Android\sdk\ndk\28.2.13676358" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Android\sdk\ndk" -ErrorAction SilentlyContinue

Write-Host "3) Clean project caches..." -ForegroundColor Cyan
flutter clean
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\android\app\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches\transforms-3" -ErrorAction SilentlyContinue

Write-Host "4) Rebuild..." -ForegroundColor Cyan
flutter pub get
flutter run
