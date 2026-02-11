#Requires -Version 5.1
<#
.SYNOPSIS
    Aurora Reader — Windows Developer Environment Bootstrap
.DESCRIPTION
    One-command setup for building Aurora Reader on a fresh Windows machine.
    Installs Flutter SDK, enables Windows desktop, pulls dependencies, and
    optionally installs Inno Setup for creating installers.
.PARAMETER InstallInnoSetup
    Also install Inno Setup 6 via winget for building installers.
.PARAMETER FlutterPath
    Custom install path for Flutter SDK (default: C:\flutter).
.EXAMPLE
    .\setup_windows.ps1
    .\setup_windows.ps1 -InstallInnoSetup
#>

param(
    [switch]$InstallInnoSetup,
    [string]$FlutterPath = "C:\flutter"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

# ── Header ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║  Aurora Reader — Windows Dev Setup         ║" -ForegroundColor Magenta
Write-Host "  ║  Sets up everything needed to build & run  ║" -ForegroundColor Magenta
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ── 1. Check Windows version ────────────────────────────────────────────────

Write-Step "Checking Windows version..."
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -lt 10) {
    Write-Fail "Windows 10 or later is required (found: $osVersion)"
    exit 1
}
Write-Ok "Windows $($osVersion.Major).$($osVersion.Minor) (Build $($osVersion.Build))"

# ── 2. Check/Install Git ────────────────────────────────────────────────────

Write-Step "Checking Git..."
if (Test-Command "git") {
    $gitVersion = git --version
    Write-Ok "Git found: $gitVersion"
} else {
    Write-Warn "Git not found. Installing via winget..."
    if (Test-Command "winget") {
        winget install --id Git.Git --accept-package-agreements --accept-source-agreements
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                     [System.Environment]::GetEnvironmentVariable("Path", "User")
        Write-Ok "Git installed"
    } else {
        Write-Fail "winget not available. Please install Git manually: https://git-scm.com/download/win"
        exit 1
    }
}

# ── 3. Check/Install Visual Studio Build Tools ──────────────────────────────

Write-Step "Checking Visual Studio / Build Tools..."
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasVS = $false

if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath 2>$null
    if ($vsPath) {
        Write-Ok "Visual Studio with C++ desktop workload found: $vsPath"
        $hasVS = $true
    }
}

if (-not $hasVS) {
    Write-Warn "Visual Studio with C++ desktop workload not found."
    Write-Host "    Flutter Windows builds require Visual Studio 2022 with the" -ForegroundColor Yellow
    Write-Host '    "Desktop development with C++" workload.' -ForegroundColor Yellow
    Write-Host ""

    $response = Read-Host "    Install Visual Studio Build Tools now? (Y/n)"
    if ($response -ne 'n' -and $response -ne 'N') {
        if (Test-Command "winget") {
            Write-Host "    Installing Visual Studio Build Tools 2022..." -ForegroundColor Yellow
            winget install --id Microsoft.VisualStudio.2022.BuildTools `
                --override "--wait --passive --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended" `
                --accept-package-agreements --accept-source-agreements
            Write-Ok "Visual Studio Build Tools installed"
        } else {
            Write-Host "    Download manually: https://visualstudio.microsoft.com/visual-cpp-build-tools/" -ForegroundColor Yellow
        }
    }
}

# ── 4. Check/Install Flutter SDK ────────────────────────────────────────────

Write-Step "Checking Flutter SDK..."
if (Test-Command "flutter") {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter\s+(\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value }
    Write-Ok "Flutter already installed: $flutterVersion"
} else {
    Write-Host "    Flutter SDK not found. Installing..." -ForegroundColor Yellow

    if (Test-Command "winget") {
        # Prefer winget installation
        Write-Host "    Installing Flutter via winget..." -ForegroundColor Yellow
        winget install --id Google.Flutter --accept-package-agreements --accept-source-agreements

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                     [System.Environment]::GetEnvironmentVariable("Path", "User")
    } else {
        # Manual installation via git clone
        Write-Host "    Cloning Flutter SDK to $FlutterPath..." -ForegroundColor Yellow

        if (Test-Path $FlutterPath) {
            Write-Warn "$FlutterPath already exists. Skipping clone."
        } else {
            git clone https://github.com/flutter/flutter.git -b stable $FlutterPath
        }

        # Add to current session PATH
        $env:Path = "$FlutterPath\bin;" + $env:Path

        # Add to user PATH permanently
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -notlike "*$FlutterPath\bin*") {
            [System.Environment]::SetEnvironmentVariable(
                "Path",
                "$FlutterPath\bin;$userPath",
                "User"
            )
            Write-Ok "Added Flutter to user PATH"
        }
    }

    # Verify
    if (Test-Command "flutter") {
        Write-Ok "Flutter installed successfully"
    } else {
        Write-Fail "Flutter installation failed. Please install manually: https://docs.flutter.dev/get-started/install/windows"
        exit 1
    }
}

# ── 5. Enable Windows desktop ───────────────────────────────────────────────

Write-Step "Enabling Flutter Windows desktop support..."
flutter config --enable-windows-desktop
Write-Ok "Windows desktop enabled"

# ── 6. Run flutter doctor ───────────────────────────────────────────────────

Write-Step "Running Flutter doctor..."
flutter doctor

# ── 7. Install project dependencies ─────────────────────────────────────────

Write-Step "Installing project dependencies..."
$projectDir = Split-Path -Parent $PSScriptRoot
Set-Location $projectDir

if (Test-Path "pubspec.yaml") {
    flutter pub get
    Write-Ok "Dependencies installed"
} else {
    Write-Warn "pubspec.yaml not found in $projectDir — skipping pub get"
}

# ── 8. Optional: Inno Setup ─────────────────────────────────────────────────

if ($InstallInnoSetup) {
    Write-Step "Installing Inno Setup 6..."
    if (Test-Command "winget") {
        winget install --id JRSoftware.InnoSetup --accept-package-agreements --accept-source-agreements
        Write-Ok "Inno Setup 6 installed"
    } else {
        Write-Host "    Download manually: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║          Setup Complete!                   ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. cd $projectDir" -ForegroundColor Yellow
Write-Host "    2. flutter run -d windows" -ForegroundColor Yellow
Write-Host ""
Write-Host "  To build a release:" -ForegroundColor White
Write-Host "    .\scripts\build_windows.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "  To build an installer:" -ForegroundColor White
Write-Host "    .\scripts\build_windows.ps1 -Installer" -ForegroundColor Yellow
Write-Host ""
