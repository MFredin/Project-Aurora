# Aurora Reader — Flutter Cross-Platform Rebuild

A complete cross-platform ebook reader with Aurora/Northern Lights dark theme, built with Flutter for iOS, Android, Windows, macOS, Linux, and Web.

## Architecture

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp + theme + routing
├── core/
│   ├── theme/                   # AuroraTheme design system
│   ├── database/                # Drift (SQLite) database
│   ├── router/                  # GoRouter navigation
│   └── constants/               # App-wide constants
├── models/                      # Data models (Drift tables + Freezed DTOs)
├── services/                    # Business logic services
│   ├── parser/                  # Ebook format parsers
│   ├── cloud/                   # Cloud storage (Dropbox, GDrive, OneDrive)
│   ├── sync/                    # Cross-platform sync (Firebase)
│   ├── ai/                      # Claude AI companion
│   ├── audio/                   # Ambient soundscapes + TTS
│   ├── discovery/               # Open Library book discovery
│   ├── export/                  # Data export (JSON/CSV/MD)
│   └── dictionary/              # Dictionary lookup
├── providers/                   # Riverpod state providers
├── screens/                     # Full-page screens
│   ├── library/                 # Library grid/list
│   ├── reader/                  # Book reader
│   ├── activity/                # Stats, achievements, streaks
│   ├── knowledge/               # Knowledge graph
│   ├── cloud/                   # Cloud file browser
│   ├── discover/                # Book discovery (Open Library)
│   ├── settings/                # App settings + export
│   └── onboarding/              # Welcome flow
└── widgets/                     # Reusable UI components
    ├── aurora_card.dart
    ├── aurora_button.dart
    ├── filter_chip_bar.dart
    └── book_cover.dart
```

## Porting from iOS (SwiftUI) to Flutter

| iOS (Swift) | Flutter (Dart) |
|---|---|
| SwiftUI Views | Flutter Widgets |
| @Observable + @MainActor | Riverpod providers |
| SwiftData @Model | Drift tables + DAOs |
| @Query | Drift watch queries (streams) |
| NavigationStack | GoRouter |
| .sheet() | showModalBottomSheet / Navigator.push |
| AuroraTheme (static enum) | ThemeData + AuroraColors extension |
| AVAudioEngine | just_audio + custom generators |
| AVSpeechSynthesizer | flutter_tts |
| NSUbiquitousKeyValueStore | Firebase Firestore (cross-platform) |
| ASWebAuthenticationSession | flutter_appauth |
| Keychain | flutter_secure_storage |
| UIReferenceLibraryViewController | Free Dictionary API |

## Getting Started

```bash
flutter pub get
flutter run                    # Run on connected device
flutter run -d chrome          # Run on web
flutter run -d windows         # Run on Windows
flutter run -d macos           # Run on macOS
flutter build apk              # Build Android APK
flutter build ios              # Build iOS IPA
flutter build windows          # Build Windows exe
```

## Platform Support

| Platform | Status |
|----------|--------|
| iOS | Primary target |
| Android | Primary target |
| Windows | Supported (installer available) |
| macOS | Supported |
| Linux | Supported |
| Web | Experimental |

## Windows Build & Install

### Quick Start (One Command)

Double-click **`install.bat`** — it will set up everything and build the app automatically.

### Manual Setup

```powershell
# 1. Set up dev environment (installs Flutter, VS Build Tools if needed)
.\scripts\setup_windows.ps1

# 2. Build the app
.\scripts\build_windows.ps1

# 3. Build the app + create installer
.\scripts\build_windows.ps1 -Installer

# 4. Or build an MSIX package (for Microsoft Store / sideloading)
.\scripts\build_msix.ps1
```

### Available Build Scripts

| Script | Purpose |
|--------|---------|
| `install.bat` | One-click setup + build (double-click to run) |
| `scripts/setup_windows.ps1` | Install prerequisites (Flutter SDK, VS Build Tools) |
| `scripts/build_windows.ps1` | Build Windows app + optional installer |
| `scripts/build_msix.ps1` | Build MSIX package for Store / sideloading |

### Installer Options

The build script supports three packaging methods (in order of preference):

1. **Inno Setup** (.exe installer) — traditional wizard-style installer
2. **NSIS** (.exe installer) — alternative installer with Modern UI
3. **Portable ZIP** — fallback if neither tool is installed
4. **MSIX** — modern Windows package format (separate script)

### Prerequisites

| Requirement | Installed By |
|-------------|--------------|
| Windows 10+ | — |
| Flutter SDK 3.16+ | `setup_windows.ps1` or `winget` |
| Visual Studio 2022 (C++ workload) | `setup_windows.ps1` or manual |
| Inno Setup 6 *(optional)* | `setup_windows.ps1 -InstallInnoSetup` |
