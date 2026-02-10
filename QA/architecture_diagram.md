# Aurora Reader — Architecture Diagram

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AuroraReaderApp                           │
│                 (SwiftData ModelContainer)                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              ContentView (TabView)                   │    │
│  │                                                     │    │
│  │  ┌─────┐ ┌────────┐ ┌─────────┐ ┌─────┐ ┌────────┐│    │
│  │  │Libr.│ │Activity │ │Knowledge│ │Cloud│ │Settings││    │
│  │  └──┬──┘ └───┬────┘ └────┬────┘ └──┬──┘ └───┬────┘│    │
│  └─────┼────────┼──────────┼─────────┼────────┼──────┘    │
│        │        │          │         │        │            │
└────────┼────────┼──────────┼─────────┼────────┼────────────┘
         │        │          │         │        │
         ▼        ▼          ▼         ▼        ▼
```

## Navigation Flow

```
ContentView
├── Tab 1: Library ──────────────────────────────────────────
│   ├── LibraryView (grid/list toggle)
│   │   ├── BookGridCell / BookListRow
│   │   ├── FileImporter (.epub, .pdf, .txt, +8 more)
│   │   └── [fullScreenCover] ReaderView ◄──── CORE READER
│   │       ├── [sheet] TableOfContentsView
│   │       ├── [sheet] ReaderSettingsSheet
│   │       ├── [sheet] AddBookmarkSheet
│   │       ├── [sheet] ReaderSearchView
│   │       ├── [sheet] AnnotationsListView
│   │       ├── [sheet] AICompanionView
│   │       ├── [sheet] ReadingModeSelector
│   │       ├── [sheet] AmbientControlView
│   │       ├── [sheet] FormattingSheetView
│   │       ├── [sheet] DictionaryView
│   │       ├── [overlay] TTSControlView
│   │       └── [overlay] HighlightActionBar
│   │
├── Tab 2: Activity ─────────────────────────────────────────
│   ├── ActivityView
│   │   ├── [link] AchievementsView
│   │   └── [link] FriendsView
│   │
├── Tab 3: Knowledge ────────────────────────────────────────
│   ├── KnowledgeGraphView
│   │
├── Tab 4: Cloud ────────────────────────────────────────────
│   ├── CloudLibraryView
│   │   ├── ConnectProvidersView (Dropbox, GDrive, Proton)
│   │   ├── ProviderSelectionView
│   │   └── FileBrowserView
│   │
└── Tab 5: Settings ─────────────────────────────────────────
    ├── SettingsView
    │   ├── [link] VocabularyListView
    │   ├── [link] BookClubView
    │   ├── [link] GoodReadsView
    │   ├── [link] DataExportView
    │   ├── [link] ReaderSettingsSheet
    │   └── Claude AI key configuration
    │
    + WelcomeView (shown on first launch, before tabs)
```

## Data Model Graph

```
                        ┌──────────────┐
                        │     Book     │
                        │──────────────│
                        │ id           │
                        │ title        │
                        │ author       │
                        │ isbn         │
                        │ coverData    │
                        │ fileURL      │
                        │ format       │
                        │ dateAdded    │
                        │ fileSize     │
                        └──────┬───────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼────┐  ┌───────▼─────┐  ┌──────▼──────┐
    │ReadingProgress│  │  Bookmark   │  │  Highlight  │
    │──────────────│  │─────────────│  │─────────────│
    │ chapter      │  │ title       │  │ text        │
    │ page         │  │ chapter     │  │ note        │
    │ scrollOffset │  │ page        │  │ color       │
    │ totalPages   │  │ textSnippet │  │ chapterIdx  │
    │ progress%    │  │ dateCreated │  │ tags[]      │
    │ totalSeconds │  │ color       │  │ rangeStart  │
    └──────────────┘  └─────────────┘  └─────────────┘

    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ReadingSession│  │ReadingStreak │  │ Achievement  │
    │──────────────│  │──────────────│  │──────────────│
    │ startTime    │  │ currentStreak│  │ type         │
    │ endTime      │  │ longestStreak│  │ title        │
    │ duration     │  │ lastReadDate │  │ isUnlocked   │
    │ pagesRead    │  │ totalDays    │  │ progress     │
    └──────────────┘  └──────────────┘  └──────────────┘

    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │FriendProfile │  │KnowledgeNode │  │VocabularyEntry│
    │──────────────│  │──────────────│  │──────────────│
    │ username     │  │ concept      │  │ word         │
    │ displayName  │  │ definition   │  │ definition   │
    │ booksRead    │  │ relatedNodes │  │ context      │
    │ currentStreak│  │ sourceBooks  │  │ mastery      │
    └──────────────┘  └──────────────┘  └──────────────┘

    ┌──────────────┐  ┌──────────────┐
    │   BookClub   │──│ClubDiscussion│
    │──────────────│  │──────────────│
    │ name         │  │ title        │
    │ bookTitle    │  │ content      │
    │ memberCount  │  │ author       │
    │ isJoined     │  │ replies      │
    └──────────────┘  └──────────────┘

    ┌──────────────┐
    │UserPreferences│
    │──────────────│
    │ fontSize     │
    │ fontFamily   │
    │ lineSpacing  │
    │ theme        │
    │ scrollMode   │
    └──────────────┘
```

## Service Layer

```
┌─────────────────────── SERVICES (all @MainActor @Observable .shared) ───────────────────┐
│                                                                                          │
│  ┌──── PARSING ────┐  ┌──── CLOUD ─────┐  ┌──── AI ──────┐  ┌──── MEDIA ─────┐        │
│  │ BookParserSvc    │  │ CloudStorage   │  │ ClaudeAPI    │  │ AmbientSvc     │        │
│  │ ├ EPUBParser    │  │  Manager       │  │ Client       │  │ (AVAudioEngine)│        │
│  │ ├ PDFParser     │  │ ├ DropboxSvc   │  │              │  │                │        │
│  │ ├ PlainTxtParse │  │ ├ GoogleDrvSvc │  │ AICompanion  │  │ TTSSvc         │        │
│  │ ├ MOBIParser    │  │ └ ProtonDrvSvc │  │   Service    │  │ (AVSpeech)     │        │
│  │ ├ FB2Parser     │  │                │  │              │  │                │        │
│  │ ├ RTFParser     │  │ SyncService    │  │              │  │ DictionaryLkp  │        │
│  │ ├ HTMLParser    │  │ (iCloud KVS)   │  │              │  │ (UIRefLibrary) │        │
│  │ ├ DjVuParser    │  │                │  │              │  │                │        │
│  │ └ CBZParser     │  │                │  │              │  │                │        │
│  └─────────────────┘  └────────────────┘  └──────────────┘  └────────────────┘        │
│                                                                                          │
│  ┌──── DATA ───────┐  ┌──── DISCOVERY ─┐  ┌──── IMPORT ──┐  ┌──── UTILITY ───┐        │
│  │ ReadingStatsSvc  │  │ GoodReadsSvc   │  │ BookImportSvc│  │ AuroraTheme    │        │
│  │                  │  │ (Open Library) │  │              │  │ BrandAssets    │        │
│  │ DataExportSvc    │  │                │  │              │  │ KeychainHelper │        │
│  │ (JSON/CSV/MD)    │  │ MetadataSvc    │  │              │  │ ImageCache     │        │
│  │                  │  │                │  │              │  │ ZIPExtractor   │        │
│  │ KnowledgeGraph   │  │ CoverArtSvc   │  │              │  │                │        │
│  │   Service        │  │                │  │              │  │                │        │
│  │                  │  │ SearchService  │  │              │  │                │        │
│  └─────────────────┘  └────────────────┘  └──────────────┘  └────────────────┘        │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
User opens book
       │
       ▼
BookParserService.parse(fileURL)  ──────────────────────────── async/nonisolated
       │
       ▼
ReaderViewModel.loadBook()
       │
       ├──► chapters: [BookChapter]
       ├──► restore ReadingProgress (chapter + scrollOffset)
       └──► start ReadingSession
              │
       ┌──────┤ USER READS ├──────┐
       │      │              │     │
       ▼      ▼              ▼     ▼
   Swipe   Highlight      TTS   Ambient
   Chapter  Text          Speak  Soundscape
       │      │              │     │
       ▼      ▼              ▼     ▼
   save    insert        AVSpeech  AVAudio
   Progress Highlight    Synth     Engine
       │      │              │     │
       └──────┴──────┬───────┴─────┘
                     │
                     ▼
              modelContext.save()
                     │
                     ▼
              SyncService.syncBookData()  ──── NSUbiquitousKeyValueStore
```
