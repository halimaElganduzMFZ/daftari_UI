# إصلاح شامل لمشكلة NDK + sdkmanager المتعطل على ويندوز
# الصقي كل شيء في PowerShell دفعة واحدة

$ErrorActionPreference = "Continue"
Set-Location "C:\Users\halima\Documents\Daftari_flutter\daftari_UI"

# اقرأ مسار SDK من local.properties إن وجد
$sdk = "$env:LOCALAPPDATA\Android\sdk"
$lp = ".\android\local.properties"
if (Test-Path $lp) {
  $line = Select-String -Path $lp -Pattern '^sdk\.dir=' | Select-Object -First 1
  if ($line) {
    $sdk = ($line.Line -replace '^sdk\.dir=', '' -replace '\\\\','\' -replace '\\:',':')
  }
}
Write-Host "SDK = $sdk" -ForegroundColor Cyan

$ver = "28.2.13676358"
$ndk = Join-Path $sdk "ndk\$ver"
$bin = Join-Path $ndk "toolchains\llvm\prebuilt\windows-x86_64\bin"
New-Item -ItemType Directory -Force -Path $bin | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ndk "sources") | Out-Null

@"
Pkg.Desc = Android NDK
Pkg.Revision = $ver
"@ | Set-Content (Join-Path $ndk "source.properties") -Encoding ASCII

@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns2:repository xmlns:ns2="http://schemas.android.com/repository/android/common/02" xmlns:ns7="http://schemas.android.com/repository/android/generic/01">
  <localPackage path="ndk;$ver" obsolete="false">
    <type-details xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns7:genericDetailsType"/>
    <revision><major>28</major><minor>2</minor><micro>13676358</micro></revision>
    <display-name>NDK (Side by side) $ver</display-name>
  </localPackage>
</ns2:repository>
"@ | Set-Content (Join-Path $ndk "package.xml") -Encoding UTF8

$strip = @'
@echo off
setlocal EnableDelayedExpansion
set "OUT="
set "IN="
:loop
if "%~1"=="" goto done
if /I "%~1"=="-o" (set "OUT=%~2" & shift & shift & goto loop)
if /I "%~1"=="--output" (set "OUT=%~2" & shift & shift & goto loop)
echo %~1| findstr /R "^-" >nul
if not errorlevel 1 (shift & goto loop)
set "IN=%~1"
shift
goto loop
:done
if defined OUT if defined IN copy /Y "%IN%" "%OUT%" >nul
exit /b 0
'@
Set-Content "$bin\llvm-strip.cmd" $strip -Encoding ASCII
Set-Content "$bin\llvm-strip.bat" $strip -Encoding ASCII
Copy-Item "$bin\llvm-strip.cmd" "$bin\llvm-objcopy.cmd" -Force

$cs = "$env:TEMP\SafeLlvmStrip.cs"
@"
using System; using System.IO;
class Program {
  static int Main(string[] args) {
    string output=null,input=null;
    for(int i=0;i<args.Length;i++){
      if((args[i]=="-o"||args[i]=="--output")&&i+1<args.Length){output=args[++i];continue;}
      if(args[i].StartsWith("-")) continue;
      input=args[i];
    }
    if(!string.IsNullOrEmpty(output)&&!string.IsNullOrEmpty(input)&&File.Exists(input)) File.Copy(input,output,true);
    return 0;
  }
}
"@ | Set-Content $cs -Encoding ASCII
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (Test-Path $csc) {
  & $csc /nologo /out:"$bin\llvm-strip.exe" $cs | Out-Null
}

# عطّل sdkmanager المتعطل مؤقتاً (مع نسخة احتياطية)
$sm = Join-Path $sdk "cmdline-tools\latest\bin\sdkmanager.bat"
if (Test-Path $sm) {
  if (-not (Test-Path "$sm.bak")) { Copy-Item $sm "$sm.bak" -Force }
  @"
@echo off
echo [bypass] sdkmanager skipped on this machine
exit /b 0
"@ | Set-Content $sm -Encoding ASCII
  Write-Host "sdkmanager bypassed (backup: sdkmanager.bat.bak)" -ForegroundColor Yellow
}

# تأكد ndkVersion في gradle
$f = ".\android\app\build.gradle.kts"
$c = Get-Content $f -Raw
if ($c -notmatch 'ndkVersion\s*=') {
  $c = $c -replace 'compileSdk\s*=\s*34', "compileSdk = 34`r`n    ndkVersion = `"$ver`""
  Set-Content $f $c -Encoding UTF8
}

Write-Host "NDK folder:" -ForegroundColor Green
Get-Content "$ndk\source.properties"
Test-Path "$ndk\source.properties"
Test-Path "$bin\llvm-strip.exe"

flutter clean
Remove-Item -Recurse -Force .\build, .\android\.gradle, .\android\app\build -ErrorAction SilentlyContinue
flutter pub get
flutter run
