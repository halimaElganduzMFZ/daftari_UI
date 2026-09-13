# ينشئ NDK محلي صالحاً لتجاوز تعطل sdkmanager
# الأهم: llvm-strip ينسخ الملف ولا يفرّغه (حتى لا يختفي libflutter.so)

$ErrorActionPreference = "Stop"
$ver = "28.2.13676358"
$ndk = Join-Path $env:LOCALAPPDATA "Android\sdk\ndk\$ver"
$bin = Join-Path $ndk "toolchains\llvm\prebuilt\windows-x86_64\bin"

Write-Host "Creating NDK at $ndk" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $bin | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ndk "sources") | Out-Null

@"
Pkg.Desc = Android NDK
Pkg.Revision = $ver
"@ | Set-Content (Join-Path $ndk "source.properties") -Encoding ASCII

# سكربت strip آمن: ينسخ المدخل إلى المخرج عند وجود -o
$stripCmd = @'
@echo off
setlocal EnableDelayedExpansion
set "OUT="
set "IN="
:loop
if "%~1"=="" goto finish
if /I "%~1"=="-o" (
  set "OUT=%~2"
  shift
  shift
  goto loop
)
if /I "%~1"=="--output" (
  set "OUT=%~2"
  shift
  shift
  goto loop
)
echo %~1| findstr /R "^-" >nul
if not errorlevel 1 (
  shift
  goto loop
)
set "IN=%~1"
shift
goto loop
:finish
if defined OUT if defined IN (
  copy /Y "%IN%" "%OUT%" >nul
)
exit /b 0
'@

Set-Content (Join-Path $bin "llvm-strip.cmd") -Value $stripCmd -Encoding ASCII
Set-Content (Join-Path $bin "llvm-strip.bat") -Value $stripCmd -Encoding ASCII
Copy-Item (Join-Path $bin "llvm-strip.cmd") (Join-Path $bin "llvm-objcopy.cmd") -Force
Copy-Item (Join-Path $bin "llvm-strip.cmd") (Join-Path $bin "strip.cmd") -Force

# llvm-strip.exe ينسخ -o إن وُجد
$cs = Join-Path $env:TEMP "SafeLlvmStrip.cs"
@"
using System;
using System.IO;
class Program {
  static int Main(string[] args) {
    string output = null, input = null;
    for (int i = 0; i < args.Length; i++) {
      if ((args[i] == "-o" || args[i] == "--output") && i + 1 < args.Length) {
        output = args[++i];
        continue;
      }
      if (args[i].StartsWith("-")) continue;
      input = args[i];
    }
    if (!string.IsNullOrEmpty(output) && !string.IsNullOrEmpty(input) && File.Exists(input)) {
      File.Copy(input, output, true);
    }
    return 0;
  }
}
"@ | Set-Content $cs -Encoding ASCII

$cscCandidates = @(
  "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
  "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
$csc = $cscCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($csc) {
  & $csc /nologo /out:(Join-Path $bin "llvm-strip.exe") $cs
  Copy-Item (Join-Path $bin "llvm-strip.exe") (Join-Path $bin "llvm-objcopy.exe") -Force
  Write-Host "Created llvm-strip.exe (copy-safe)" -ForegroundColor Green
} else {
  Write-Host "csc not found; using .cmd stubs only" -ForegroundColor Yellow
}

Write-Host "NDK ready:" -ForegroundColor Green
Get-Content (Join-Path $ndk "source.properties")
Get-ChildItem $bin | Format-Table Name, Length
