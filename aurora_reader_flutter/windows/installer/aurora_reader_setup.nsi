; ============================================================================
; Aurora Reader — NSIS Installer Script
; ============================================================================
; Alternative to Inno Setup for users who prefer NSIS.
;
; Build with:
;   makensis /DAPP_VERSION=4.0.0 aurora_reader_setup.nsi
;
; Requires: NSIS 3.x — https://nsis.sourceforge.io/
; ============================================================================

!ifndef APP_VERSION
  !define APP_VERSION "4.0.0"
!endif

!ifndef BUILD_DIR
  !define BUILD_DIR "..\..\build\windows\x64\runner\Release"
!endif

!ifndef OUTPUT_DIR
  !define OUTPUT_DIR "..\..\dist"
!endif

!define APP_NAME        "Aurora Reader"
!define APP_PUBLISHER   "Aurora Reader Team"
!define APP_URL         "https://github.com/MFredin/Project-Aurora"
!define APP_EXE         "aurora_reader.exe"
!define UNINSTALL_KEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

; ── Metadata ─────────────────────────────────────────────────────────────────

Name "${APP_NAME} ${APP_VERSION}"
OutFile "${OUTPUT_DIR}\AuroraReader-${APP_VERSION}-Setup.exe"
InstallDir "$LOCALAPPDATA\${APP_NAME}"
InstallDirRegKey HKCU "${UNINSTALL_KEY}" "InstallLocation"
RequestExecutionLevel user
Unicode True

; ── Modern UI ────────────────────────────────────────────────────────────────

!include "MUI2.nsh"
!include "FileFunc.nsh"

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APP_NAME}"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ── Version Info ─────────────────────────────────────────────────────────────

VIProductVersion "${APP_VERSION}.0"
VIAddVersionKey "ProductName"     "${APP_NAME}"
VIAddVersionKey "CompanyName"     "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_NAME} Setup"
VIAddVersionKey "FileVersion"     "${APP_VERSION}"
VIAddVersionKey "ProductVersion"  "${APP_VERSION}"
VIAddVersionKey "LegalCopyright"  "Copyright (c) 2024-2026 ${APP_PUBLISHER}"

; ── Install Section ──────────────────────────────────────────────────────────

Section "Install"
  SetOutPath "$INSTDIR"

  ; Copy all files from the Flutter build output
  File /r "${BUILD_DIR}\*.*"

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Start menu shortcut
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"

  ; Desktop shortcut
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"

  ; Registry entries for Add/Remove Programs
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName"     "${APP_NAME}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion"  "${APP_VERSION}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher"        "${APP_PUBLISHER}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "URLInfoAbout"     "${APP_URL}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation"  "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString"  "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon"      "$INSTDIR\${APP_EXE}"
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1

  ; Calculate and store installed size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" $0

  ; File associations (EPUB)
  WriteRegStr HKCU "Software\Classes\.epub\OpenWithProgids" "AuroraReader.epub" ""
  WriteRegStr HKCU "Software\Classes\AuroraReader.epub" "" "EPUB Ebook"
  WriteRegStr HKCU "Software\Classes\AuroraReader.epub\DefaultIcon" "" "$INSTDIR\${APP_EXE},0"
  WriteRegStr HKCU "Software\Classes\AuroraReader.epub\shell\open\command" "" '"$INSTDIR\${APP_EXE}" "%1"'

SectionEnd

; ── Uninstall Section ────────────────────────────────────────────────────────

Section "Uninstall"
  ; Remove all installed files
  RMDir /r "$INSTDIR"

  ; Remove shortcuts
  Delete "$DESKTOP\${APP_NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APP_NAME}"

  ; Remove registry entries
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  DeleteRegKey HKCU "Software\Classes\AuroraReader.epub"
  DeleteRegValue HKCU "Software\Classes\.epub\OpenWithProgids" "AuroraReader.epub"

SectionEnd
