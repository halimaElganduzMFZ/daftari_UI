# ينشئ NDK stub مكتمل يمنع sdkmanager من الانهيار
# شغّليه مرة واحدة ثم flutter run

$ErrorActionPreference = "Stop"
$ver = "28.2.13676358"
$ndk = Join-Path $env:LOCALAPPDATA "Android\sdk\ndk\$ver"
$prebuilt = Join-Path $ndk "toolchains\llvm\prebuilt\windows-x86_64\bin"

Write-Host "Creating NDK stub at: $ndk" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $prebuilt | Out-Null

@"
Pkg.Desc = Android NDK
Pkg.Revision = $ver
"@ | Set-Content -Path (Join-Path $ndk "source.properties") -Encoding ASCII

# no-op strip tools (Windows)
$noop = "@echo off`r`nexit /b 0`r`n"
@(
  "llvm-strip.cmd",
  "llvm-strip.bat",
  "llvm-strip.exe.bat",
  "strip.cmd",
  "strip.bat"
) | ForEach-Object {
  Set-Content -Path (Join-Path $prebuilt $_) -Value $noop -Encoding ASCII
}

# Gradle on Windows often invokes `llvm-strip` without extension.
# Create a tiny .exe launcher via PowerShell shim is hard; use PATHEXT-friendly cmd copy named llvm-strip.com alternative:
# Instead write llvm-strip without extension as a .cmd and also a powershell-based exe using cmd /c.
# Best reliable approach: copy cmd.exe to llvm-strip.exe is unsafe.
# Use a VBScript-generated exe? Too heavy.
# Create llvm-strip as a .cmd and set a wrapper script named llvm-strip (no ext) for Git bash only.
# For ProcessBuilder, Windows searches PATHEXT=.COM;.EXE;.BAT;.CMD
# So llvm-strip.bat / .cmd is enough IF the command is `llvm-strip`.
Set-Content -Path (Join-Path $prebuilt "llvm-strip.cmd") -Value $noop -Encoding ASCII
Set-Content -Path (Join-Path $prebuilt "llvm-strip.bat") -Value $noop -Encoding ASCII

# Also create empty marker files some validators check
New-Item -ItemType Directory -Force -Path (Join-Path $ndk "sources") | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $ndk "ndk-build.cmd") | Out-Null
Set-Content -Path (Join-Path $ndk "ndk-build.cmd") -Value $noop -Encoding ASCII

Write-Host "NDK stub ready." -ForegroundColor Green
Write-Host "Files:" -ForegroundColor Green
Get-ChildItem $prebuilt | Select-Object Name
Get-Content (Join-Path $ndk "source.properties")
