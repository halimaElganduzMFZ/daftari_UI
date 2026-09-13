# إنشاء NDK stub يمنع انهيار sdkmanager وفشل llvm-strip
$ErrorActionPreference = "Stop"
$ver = "28.2.13676358"
$ndk = Join-Path $env:LOCALAPPDATA "Android\sdk\ndk\$ver"
$bin = Join-Path $ndk "toolchains\llvm\prebuilt\windows-x86_64\bin"

Write-Host "Creating NDK stub: $ndk" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $bin | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ndk "sources") | Out-Null

@"
Pkg.Desc = Android NDK
Pkg.Revision = $ver
"@ | Set-Content (Join-Path $ndk "source.properties") -Encoding ASCII

$noopBat = "@echo off`r`nexit /b 0`r`n"
Set-Content (Join-Path $bin "llvm-strip.cmd") -Value $noopBat -Encoding ASCII
Set-Content (Join-Path $bin "llvm-strip.bat") -Value $noopBat -Encoding ASCII
Set-Content (Join-Path $ndk "ndk-build.cmd") -Value $noopBat -Encoding ASCII

# أنشئ llvm-strip.exe حقيقي بسيط (exit 0) عبر .NET
$exe = Join-Path $bin "llvm-strip.exe"
$src = Join-Path $env:TEMP "llvm_strip_stub.cs"
@"
using System;
class Program { static int Main(string[] args) { return 0; } }
"@ | Set-Content $src -Encoding ASCII

$csc = @(
  "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
  "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($csc) {
  & $csc /nologo /out:$exe $src
  Write-Host "Created llvm-strip.exe" -ForegroundColor Green
} else {
  Write-Host "csc.exe not found; bat/cmd stubs only" -ForegroundColor Yellow
}

Write-Host "Done. Verify:" -ForegroundColor Green
Get-Content (Join-Path $ndk "source.properties")
Get-ChildItem $bin | Format-Table Name, Length
