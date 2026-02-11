#Requires -Version 5.1
<#
.SYNOPSIS
    Aurora Reader — MSIX Package Builder
.DESCRIPTION
    Builds an MSIX package for distribution via the Microsoft Store
    or sideloading. MSIX is the modern Windows app package format.
.PARAMETER Certificate
    Path to a .pfx code signing certificate. If not provided, a
    self-signed certificate is generated for testing.
.PARAMETER CertPassword
    Password for the .pfx certificate.
.EXAMPLE
    .\build_msix.ps1
    .\build_msix.ps1 -Certificate ".\cert.pfx" -CertPassword "secret"
#>

param(
    [string]$Certificate,
    [string]$CertPassword
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "    [FAIL] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  ╔════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║    Aurora Reader — MSIX Package Build   ║" -ForegroundColor Magenta
Write-Host "  ╚════════════════════════════════════════╝" -ForegroundColor Magenta

# ── Check msix package in pubspec ────────────────────────────────────────────

Write-Step "Checking msix dependency..."
Set-Location $ProjectRoot

$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -notmatch "msix:") {
    Write-Host "    Adding msix configuration to pubspec.yaml..." -ForegroundColor Yellow

    $msixConfig = @"

msix_config:
  display_name: Aurora Reader
  publisher_display_name: Aurora Reader Team
  identity_name: com.aurorareader.app
  msix_version: 4.0.0.0
  logo_path: assets/icons/app_icon.png
  capabilities: internetClient, documentsLibrary
  languages: en-us
  file_extensions: .epub, .pdf, .txt, .mobi, .fb2
"@

    Add-Content "pubspec.yaml" $msixConfig
    Write-Ok "MSIX config added to pubspec.yaml"
}

# ── Check for msix dart package ──────────────────────────────────────────────

Write-Step "Ensuring msix package is available..."
$devDeps = flutter pub deps 2>&1 | Select-String "msix"
if (-not $devDeps) {
    flutter pub add --dev msix
    Write-Ok "msix package added"
} else {
    Write-Ok "msix package already present"
}

# ── Build the Windows app first ──────────────────────────────────────────────

Write-Step "Building Windows release..."
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Flutter build failed"
    exit 1
}
Write-Ok "Windows build complete"

# ── Create MSIX package ─────────────────────────────────────────────────────

Write-Step "Creating MSIX package..."

$msixArgs = @()
if ($Certificate) {
    $msixArgs += "--certificate-path"
    $msixArgs += $Certificate
    if ($CertPassword) {
        $msixArgs += "--certificate-password"
        $msixArgs += $CertPassword
    }
}

flutter pub run msix:create @msixArgs

if ($LASTEXITCODE -eq 0) {
    $msixFile = Get-ChildItem "$ProjectRoot\build" -Filter "*.msix" -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($msixFile) {
        $size = [math]::Round($msixFile.Length / 1MB, 1)
        Write-Ok "MSIX package created: $($msixFile.FullName) ($size MB)"

        # Copy to dist folder
        $distDir = Join-Path $ProjectRoot "dist"
        if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
        Copy-Item $msixFile.FullName $distDir
        Write-Ok "Copied to: $distDir\$($msixFile.Name)"
    }
} else {
    Write-Fail "MSIX creation failed"
    exit 1
}

Write-Host ""
Write-Host "  ╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║       MSIX Package Ready!               ║" -ForegroundColor Green
Write-Host "  ╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  To install on a Windows device:" -ForegroundColor White
Write-Host "    Double-click the .msix file" -ForegroundColor Yellow
Write-Host ""
Write-Host "  For Store submission:" -ForegroundColor White
Write-Host "    Upload to Partner Center: https://partner.microsoft.com" -ForegroundColor Yellow
Write-Host ""
