#Requires -Version 5.1
<#
.SYNOPSIS
    Aurora Reader — Windows Build Script
.DESCRIPTION
    Builds the Aurora Reader Flutter app for Windows and optionally
    creates an installer using Inno Setup or NSIS.
.PARAMETER Clean
    Run flutter clean before building.
.PARAMETER Release
    Build in release mode (default). Use -Debug for debug builds.
.PARAMETER Debug
    Build in debug mode.
.PARAMETER Installer
    After building, package into an installer (requires Inno Setup or NSIS).
.PARAMETER SkipDeps
    Skip running flutter pub get.
.EXAMPLE
    .\build_windows.ps1
    .\build_windows.ps1 -Clean -Installer
    .\build_windows.ps1 -Debug
#>

param(
    [switch]$Clean,
    [switch]$Release = $true,
    [switch]$Debug,
    [switch]$Installer,
    [switch]$SkipDeps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Configuration ────────────────────────────────────────────────────────────

$AppName        = "Aurora Reader"
$AppVersion     = "4.0.0"
$AppPublisher   = "Aurora Reader Team"
$ProjectRoot    = Split-Path -Parent $PSScriptRoot  # one level up from scripts/
$BuildDir       = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$InstallerDir   = Join-Path $ProjectRoot "windows\installer"
$OutputDir      = Join-Path $ProjectRoot "dist"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step($msg) {
    Write-Host "`n==> $msg" -ForegroundColor Cyan
}

function Write-Ok($msg) {
    Write-Host "    [OK] $msg" -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host "    [WARN] $msg" -ForegroundColor Yellow
}

function Write-Fail($msg) {
    Write-Host "    [FAIL] $msg" -ForegroundColor Red
}

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# ── Pre-flight checks ───────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║       Aurora Reader — Build Tool      ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

Write-Step "Checking prerequisites..."

# Flutter SDK
if (-not (Test-Command "flutter")) {
    Write-Fail "Flutter SDK not found in PATH."
    Write-Host "    Install Flutter: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    Write-Host "    Then run: flutter config --enable-windows-desktop" -ForegroundColor Yellow
    exit 1
}
Write-Ok "Flutter SDK found"

# Flutter version
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter\s+(\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
Write-Ok "Flutter version: $flutterVersion"

# Windows desktop enabled
$flutterConfig = flutter config 2>&1
if ($flutterConfig -notmatch "enable-windows-desktop.*true") {
    Write-Warn "Windows desktop not enabled. Enabling now..."
    flutter config --enable-windows-desktop
}
Write-Ok "Windows desktop enabled"

# Visual Studio (required for Windows builds)
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -property installationPath 2>$null
    if ($vsPath) {
        Write-Ok "Visual Studio found: $vsPath"
    } else {
        Write-Warn "Visual Studio installation not detected via vswhere."
    }
} else {
    Write-Warn "vswhere not found — ensure Visual Studio 2022 with C++ desktop workload is installed."
}

# ── Build ────────────────────────────────────────────────────────────────────

Set-Location $ProjectRoot

if ($Clean) {
    Write-Step "Cleaning previous build..."
    flutter clean
    Write-Ok "Clean complete"
}

if (-not $SkipDeps) {
    Write-Step "Fetching dependencies..."
    flutter pub get
    Write-Ok "Dependencies fetched"
}

$buildMode = if ($Debug) { "debug" } else { "release" }
Write-Step "Building Windows app ($buildMode)..."

if ($Debug) {
    flutter build windows --debug
} else {
    flutter build windows --release
}

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Verify output
if ($Debug) {
    $BuildDir = $BuildDir -replace "Release$", "Debug"
}

$exePath = Join-Path $BuildDir "aurora_reader.exe"
if (-not (Test-Path $exePath)) {
    # Flutter may name it differently based on pubspec
    $exePath = Get-ChildItem $BuildDir -Filter "*.exe" | Select-Object -First 1 -ExpandProperty FullName
}

if (-not $exePath -or -not (Test-Path $exePath)) {
    Write-Fail "Cannot find built executable in $BuildDir"
    exit 1
}

$exeSize = [math]::Round((Get-Item $exePath).Length / 1MB, 1)
Write-Ok "Build complete: $exePath ($exeSize MB)"

# ── Create Installer (optional) ─────────────────────────────────────────────

if ($Installer) {
    Write-Step "Creating installer..."

    # Create output directory
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir | Out-Null
    }

    $innoSetup = $null
    $nsisPath = $null

    # Check for Inno Setup
    $innoLocations = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 5\ISCC.exe"
    )
    foreach ($loc in $innoLocations) {
        if (Test-Path $loc) { $innoSetup = $loc; break }
    }

    # Check for NSIS
    $nsisLocations = @(
        "${env:ProgramFiles(x86)}\NSIS\makensis.exe",
        "${env:ProgramFiles}\NSIS\makensis.exe"
    )
    foreach ($loc in $nsisLocations) {
        if (Test-Path $loc) { $nsisPath = $loc; break }
    }

    if ($innoSetup) {
        Write-Ok "Using Inno Setup: $innoSetup"
        $issFile = Join-Path $InstallerDir "aurora_reader_setup.iss"

        if (-not (Test-Path $issFile)) {
            Write-Fail "Inno Setup script not found: $issFile"
            exit 1
        }

        & $innoSetup `
            "/DAppVersion=$AppVersion" `
            "/DBuildDir=$BuildDir" `
            "/DOutputDir=$OutputDir" `
            $issFile

        if ($LASTEXITCODE -eq 0) {
            $installerExe = Get-ChildItem $OutputDir -Filter "AuroraReader-*-Setup.exe" |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1
            if ($installerExe) {
                $instSize = [math]::Round($installerExe.Length / 1MB, 1)
                Write-Ok "Installer created: $($installerExe.FullName) ($instSize MB)"
            }
        } else {
            Write-Fail "Inno Setup compilation failed"
        }
    }
    elseif ($nsisPath) {
        Write-Ok "Using NSIS: $nsisPath"
        $nsiFile = Join-Path $InstallerDir "aurora_reader_setup.nsi"

        if (-not (Test-Path $nsiFile)) {
            Write-Fail "NSIS script not found: $nsiFile"
            exit 1
        }

        & $nsisPath `
            "/DAPP_VERSION=$AppVersion" `
            "/DBUILD_DIR=$BuildDir" `
            "/DOUTPUT_DIR=$OutputDir" `
            $nsiFile

        if ($LASTEXITCODE -eq 0) {
            Write-Ok "NSIS installer created in $OutputDir"
        } else {
            Write-Fail "NSIS compilation failed"
        }
    }
    else {
        Write-Warn "Neither Inno Setup nor NSIS found."
        Write-Host "    Creating portable ZIP instead..." -ForegroundColor Yellow

        $zipName = "AuroraReader-$AppVersion-Windows-Portable.zip"
        $zipPath = Join-Path $OutputDir $zipName

        Compress-Archive -Path "$BuildDir\*" -DestinationPath $zipPath -Force
        $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
        Write-Ok "Portable ZIP created: $zipPath ($zipSize MB)"
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║          Build Successful!            ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  App:     $exePath" -ForegroundColor White
Write-Host "  Mode:    $buildMode" -ForegroundColor White
Write-Host "  Version: $AppVersion" -ForegroundColor White
Write-Host ""
Write-Host "  To run: " -NoNewline
Write-Host "& `"$exePath`"" -ForegroundColor Yellow
Write-Host ""
