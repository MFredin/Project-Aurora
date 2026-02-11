; ============================================================================
; Aurora Reader — Inno Setup Installer Script
; ============================================================================
; Produces: AuroraReader-{version}-Setup.exe
;
; Build with:
;   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" aurora_reader_setup.iss
;
; Or from the build script:
;   .\scripts\build_windows.ps1 -Installer
; ============================================================================

; These can be overridden from the command line via /D flags
#ifndef AppVersion
  #define AppVersion "4.0.0"
#endif

#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

#define AppName        "Aurora Reader"
#define AppExeName     "aurora_reader.exe"
#define AppPublisher   "Aurora Reader Team"
#define AppURL         "https://github.com/MFredin/Project-Aurora"
#define AppCopyright   "Copyright (c) 2024-2026 Aurora Reader Team"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=
OutputDir={#OutputDir}
OutputBaseFilename=AuroraReader-{#AppVersion}-Setup
SetupIconFile=
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
VersionInfoVersion={#AppVersion}.0
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} Setup
VersionInfoCopyright={#AppCopyright}
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}
MinVersion=10.0

; Appearance
WizardImageFile=
WizardSmallImageFile=
DisableWelcomePage=no
DisableDirPage=auto
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "fileassoc_epub"; Description: "Associate .epub files with {#AppName}"; GroupDescription: "File Associations:"; Flags: unchecked
Name: "fileassoc_pdf"; Description: "Associate .pdf files with {#AppName}"; GroupDescription: "File Associations:"; Flags: unchecked

[Files]
; Main executable and all supporting DLLs/assets from the Flutter build
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
; File associations (optional)
Root: HKA; Subkey: "Software\Classes\.epub\OpenWithProgids"; ValueType: string; ValueName: "AuroraReader.epub"; ValueData: ""; Flags: uninsdeletevalue; Tasks: fileassoc_epub
Root: HKA; Subkey: "Software\Classes\AuroraReader.epub"; ValueType: string; ValueName: ""; ValueData: "EPUB Ebook"; Flags: uninsdeletekey; Tasks: fileassoc_epub
Root: HKA; Subkey: "Software\Classes\AuroraReader.epub\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExeName},0"; Tasks: fileassoc_epub
Root: HKA; Subkey: "Software\Classes\AuroraReader.epub\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: fileassoc_epub

Root: HKA; Subkey: "Software\Classes\.pdf\OpenWithProgids"; ValueType: string; ValueName: "AuroraReader.pdf"; ValueData: ""; Flags: uninsdeletevalue; Tasks: fileassoc_pdf
Root: HKA; Subkey: "Software\Classes\AuroraReader.pdf"; ValueType: string; ValueName: ""; ValueData: "PDF Document"; Flags: uninsdeletekey; Tasks: fileassoc_pdf
Root: HKA; Subkey: "Software\Classes\AuroraReader.pdf\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExeName},0"; Tasks: fileassoc_pdf
Root: HKA; Subkey: "Software\Classes\AuroraReader.pdf\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: fileassoc_pdf

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Check for Visual C++ Redistributable on install
function NeedsVCRedist: Boolean;
var
  Version: String;
begin
  Result := True;
  if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
    Result := False;
  if RegQueryStringValue(HKLM, 'SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
    Result := False;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Notify Windows shell of file association changes
    // SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, 0, 0)
  end;
end;

function InitializeSetup: Boolean;
begin
  Result := True;
  if NeedsVCRedist then
  begin
    if MsgBox('Aurora Reader requires the Microsoft Visual C++ Redistributable.' + #13#10 +
              'It appears to be missing. The app may not launch correctly.' + #13#10#13#10 +
              'Continue with installation anyway?',
              mbConfirmation, MB_YESNO) = IDNO then
      Result := False;
  end;
end;
