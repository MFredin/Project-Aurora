# Aurora Reader — Manual QA Checklist v4.0.0

> For internal testing on physical iPhone. Test each item and mark [x] when verified.

---

## 1. First Launch & Onboarding

- [ ] App launches without crash on cold start
- [ ] Welcome onboarding appears on first launch (4 pages)
- [ ] Swipe between onboarding pages works smoothly
- [ ] "Skip" button dismisses onboarding
- [ ] "Get Started" on page 4 dismisses and shows main app
- [ ] Onboarding does NOT reappear after completing it
- [ ] Aurora theme (dark background, teal/green accents) visible throughout

## 2. Tab Bar Navigation

- [ ] 5 tabs visible: Library, Activity, Knowledge, Cloud, Settings
- [ ] Tab icons display correctly with SF Symbols
- [ ] Active tab highlighted with aurora teal
- [ ] Tab switching is instant (no lag)
- [ ] Tab state preserved when switching between tabs

## 3. Library Tab

### 3a. Empty State
- [ ] Empty library shows import prompt
- [ ] Import button is visible and tappable

### 3b. File Import
- [ ] Tap import opens system file picker
- [ ] EPUB files can be selected and imported
- [ ] TXT files can be selected and imported
- [ ] PDF files can be selected (stub parser creates placeholder chapters)
- [ ] Book appears in library grid after import
- [ ] Cover art gradient generates for books without covers
- [ ] File size displays correctly

### 3c. Library Grid/List
- [ ] Grid view displays book covers properly
- [ ] Toggle to list view works
- [ ] Sort options function (date, title, author)
- [ ] Search bar filters books by title
- [ ] Long-press or swipe shows delete option
- [ ] Delete removes book and all associated data

### 3d. Performance: Library
- [ ] Library loads instantly with <10 books
- [ ] Scrolling is smooth at 60fps
- [ ] Cover images load without visible delay
- [ ] Memory stays stable (no growth on repeated opens)

## 4. Reader (open a book)

### 4a. Book Loading
- [ ] EPUB book opens and displays chapter content
- [ ] Chapter title shown at top
- [ ] Text renders with correct font/size from preferences
- [ ] Loading indicator appears while parsing
- [ ] Error view shows if file is corrupted/missing

### 4b. Navigation
- [ ] Swipe left → next chapter
- [ ] Swipe right → previous chapter
- [ ] Tap center → toggle toolbar
- [ ] Progress bar shows correct position
- [ ] "Chapter X of Y" text is accurate
- [ ] Table of Contents sheet opens and lists all chapters
- [ ] Tapping a chapter in TOC navigates to it
- [ ] Haptic feedback on page turn
- [ ] Haptic on chapter completion

### 4c. Reading Position
- [ ] Close and reopen book → returns to same chapter
- [ ] Scroll position within chapter is approximately restored
- [ ] Progress percentage updates correctly
- [ ] Last opened date updates in library

### 4d. Bookmarks
- [ ] Add Bookmark sheet opens with themed UI
- [ ] Can enter bookmark title
- [ ] Bookmark saves and appears in bookmark list
- [ ] Can delete bookmarks via swipe
- [ ] Bookmarks show text snippet

### 4e. Highlights & Annotations
- [ ] Select text → highlight action bar appears
- [ ] Can choose highlight color (6 aurora colors)
- [ ] Tapping "Highlight" saves the highlight
- [ ] "Add Note" opens note input sheet
- [ ] Notes save correctly with highlight
- [ ] Annotations list shows all highlights for the book
- [ ] Tapping annotation navigates to correct chapter

### 4f. Dictionary Lookup
- [ ] "Define" button appears in highlight action bar
- [ ] Tapping "Define" opens system dictionary for the word
- [ ] Works with single-word and multi-word selections (uses first word)
- [ ] Dictionary view has dark themed navigation

### 4g. Text-to-Speech
- [ ] "Read Aloud" in menu starts TTS
- [ ] "Read" quick action button starts TTS
- [ ] TTS control panel appears at bottom
- [ ] Play/Pause toggles correctly
- [ ] Stop button stops and dismisses controls
- [ ] Progress bar advances during speech
- [ ] Rate control changes speech speed
- [ ] Voice picker shows available system voices
- [ ] TTS stops when leaving reader
- [ ] TTS works with ambient audio simultaneously

### 4h. Reading Modes
- [ ] Reading Mode selector opens with 5 modes
- [ ] Standard mode: default text rendering
- [ ] Bionic mode: first letters of words bolded
- [ ] Speed mode: RSVP word-by-word display
- [ ] Focus mode: breathing timer with text
- [ ] Accessibility: OpenDyslexic font applied
- [ ] Mode persists during the reading session

### 4i. AI Companion
- [ ] AI Companion sheet opens
- [ ] Without API key: shows configuration prompt
- [ ] With API key: can send messages
- [ ] Summary, explain, quiz buttons work
- [ ] Responses render properly

### 4j. Ambient Audio
- [ ] Ambient control sheet opens
- [ ] Soundscape grid shows 10 options
- [ ] Selecting a soundscape starts audio playback
- [ ] Audio plays in background (ambient category)
- [ ] Volume slider adjusts volume
- [ ] Switching soundscapes crossfades
- [ ] Stop button stops audio
- [ ] Audio stops when leaving reader
- [ ] Each soundscape produces distinct sound character:
  - [ ] Gentle Rain: soft patter with droplets
  - [ ] Thunderstorm: deeper noise with rumbles
  - [ ] Fireplace: crackle sounds
  - [ ] Ocean Waves: rhythmic amplitude modulation
  - [ ] Forest Birds: chirps on noise floor
  - [ ] Cafe: low murmur
  - [ ] Enchanted Forest: wind with chimes
  - [ ] Space: deep drones
  - [ ] Library: very quiet with occasional sounds
  - [ ] Snowfall: very soft noise

### 4k. Reader Settings
- [ ] Settings sheet opens with themed UI
- [ ] Font family picker shows available fonts
- [ ] Font size slider changes text size live
- [ ] Line spacing slider works
- [ ] Theme picker (Light, Sepia, Dark, Midnight) changes colors
- [ ] Text preview shows changes in real-time

### 4l. Performance: Reader
- [ ] Chapter text renders in <1 second
- [ ] Scrolling is smooth at 60fps
- [ ] Chapter switching is instant
- [ ] TTS doesn't cause UI jank
- [ ] Ambient audio doesn't cause UI jank
- [ ] Memory stable during long reading sessions

## 5. Activity Tab

- [ ] Activity view loads with reading statistics
- [ ] Reading streak shows current/longest
- [ ] Session history displays
- [ ] Achievements link opens achievements view
- [ ] Achievement cards show progress bars
- [ ] Unlocked achievements display differently
- [ ] Friends link shows friend profiles
- [ ] Performance: smooth scrolling

## 6. Knowledge Tab

- [ ] Knowledge graph view loads
- [ ] Concept nodes display
- [ ] Node connections visible
- [ ] Tapping a node shows details
- [ ] Aurora theme consistent

## 7. Cloud Tab

- [ ] Cloud library view loads
- [ ] Provider buttons shown (Dropbox, Google Drive, Proton)
- [ ] Tapping Dropbox initiates OAuth flow
- [ ] Tapping Google Drive initiates OAuth flow
- [ ] Proton Drive shows clear "requires SDK" message
- [ ] After auth: file browser shows cloud files
- [ ] Files filtered to ebook formats
- [ ] Download button works
- [ ] Error handling for network failures

## 8. Settings Tab

### 8a. Library Stats
- [ ] Total books count correct
- [ ] Highlights count correct
- [ ] Vocabulary words count correct
- [ ] Format category breakdown accurate

### 8b. iCloud Sync
- [ ] Sync toggle works
- [ ] "Sync Now" button triggers sync
- [ ] Last synced timestamp updates
- [ ] Sync status icon changes (idle/syncing/error)

### 8c. Features
- [ ] Vocabulary Builder link opens word list
- [ ] Book Clubs link opens clubs view
- [ ] GoodReads/Discover link opens discovery view

### 8d. AI Configuration
- [ ] API key field shows/hides
- [ ] Save button stores key in Keychain
- [ ] Validation check runs after save
- [ ] Status shows Connected/Invalid/Unknown

### 8e. Smart Import
- [ ] Enrich Metadata button works
- [ ] Shows progress during enrichment
- [ ] Success alert shows count of enriched books
- [ ] Fetch Missing Covers button works
- [ ] Shows progress during fetch
- [ ] Success alert shows count of covers found

### 8f. Data Export
- [ ] Export Data link opens export view
- [ ] Can select export content type
- [ ] Can select format (JSON/CSV/Markdown)
- [ ] Export button generates file
- [ ] Share sheet opens with generated file
- [ ] JSON exports are valid JSON
- [ ] CSV exports have correct columns
- [ ] Markdown exports are readable

### 8g. Cloud Storage Status
- [ ] Each provider shows connection status
- [ ] Connected providers show green "Connected"

### 8h. Default Reader Settings
- [ ] Current font and size displayed
- [ ] Link to full settings works

### 8i. About
- [ ] Version shows 4.0.0
- [ ] App name "Aurora Reader" displayed

## 9. GoodReads / Book Discovery

- [ ] Auto-authenticates on view load (no API key needed)
- [ ] Search bar visible and functional
- [ ] Search returns results from Open Library
- [ ] Book rows show title, author, rating stars
- [ ] Cover images load from Open Library
- [ ] "+" button adds to shelf
- [ ] Shelves section shows 3 default shelves
- [ ] Shelf tabs toggle correctly
- [ ] Trending section displays placeholder books

## 10. Cross-Cutting Concerns

### 10a. Theme Consistency
- [ ] ALL screens use dark background (AuroraTheme.deepSpace)
- [ ] No white/light flashes during navigation
- [ ] Text colors are aurora-themed (no system .primary/.secondary)
- [ ] Accent colors are consistently teal/green/purple

### 10b. Accessibility
- [ ] VoiceOver reads all interactive elements
- [ ] Dynamic Type respects system font size
- [ ] All buttons have accessible labels
- [ ] Color contrast meets WCAG AA

### 10c. Performance
- [ ] Cold launch to Library: <2 seconds
- [ ] Tab switching: <100ms
- [ ] Book open (EPUB): <3 seconds
- [ ] Memory usage stable: <150MB baseline
- [ ] No visible frame drops during scrolling
- [ ] Battery drain normal during ambient audio

### 10d. Edge Cases
- [ ] Import very large EPUB (>10MB) — no crash
- [ ] Import corrupted/invalid file — error shown
- [ ] Rapidly switch between tabs — no crash
- [ ] Open reader, kill app, reopen — position preserved
- [ ] No internet — app functions offline (except cloud/API)
- [ ] Low storage — graceful error on import

---

## Test Summary

| Section | Total Items | Passed | Failed | Notes |
|---------|------------|--------|--------|-------|
| Onboarding | 7 | | | |
| Tab Navigation | 5 | | | |
| Library | 15 | | | |
| Reader | ~55 | | | |
| Activity | 8 | | | |
| Knowledge | 5 | | | |
| Cloud | 9 | | | |
| Settings | 22 | | | |
| Discovery | 9 | | | |
| Cross-Cutting | 14 | | | |
| **TOTAL** | **~149** | | | |
