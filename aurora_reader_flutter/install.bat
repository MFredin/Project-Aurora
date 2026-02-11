@echo off
:: ============================================================================
:: Aurora Reader — One-Click Windows Setup & Build
:: ============================================================================
:: Double-click this file to set up your dev environment and build the app.
:: Requires: Windows 10+, Internet connection
:: ============================================================================

title Aurora Reader — Setup ^& Build
color 0B

echo.
echo   ========================================
echo     Aurora Reader - Windows Setup ^& Build
echo   ========================================
echo.
echo   This script will:
echo     1. Check/install prerequisites (Flutter, Visual Studio)
echo     2. Install project dependencies
echo     3. Build the Windows application
echo     4. Create a portable ZIP or installer
echo.

pause

:: Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] PowerShell is required but not found.
    echo         Windows 10 and later include PowerShell by default.
    pause
    exit /b 1
)

echo.
echo [1/3] Setting up development environment...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\setup_windows.ps1"
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Setup failed. Check the output above for details.
    pause
    exit /b 1
)

echo.
echo [2/3] Building Aurora Reader...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\build_windows.ps1" -Installer
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Build failed. Check the output above for details.
    pause
    exit /b 1
)

echo.
echo [3/3] Done!
echo.
echo   Your built app is in: %~dp0build\windows\x64\runner\Release\
echo   Installer (if created): %~dp0dist\
echo.
echo   To run the app directly:
echo     build\windows\x64\runner\Release\aurora_reader.exe
echo.

pause
