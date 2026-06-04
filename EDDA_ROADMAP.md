# Edda: Whitespace Analysis & Feature Roadmap

**Last updated**: 2026-06-04
**Status**: Active development — Tiers 1-3 implemented

## Vision

Edda is the single app where you discover, read, track, journal, discuss, and own your entire reading life — with an AI companion, ambient soundscapes, and zero lock-in.

## Current Features (Shipped)

- EPUB/PDF/TXT/MOBI/AZW/FB2 format support
- Google Drive integration for importing books
- AI reading companion (LLM-powered)
- Ambient soundscapes
- Text-to-speech
- Dictionary lookup
- Highlights and bookmarks
- Reading statistics and session tracking
- Book discovery via Open Library/Google Books APIs
- Data export (Markdown, JSON, CSV, Obsidian, Notion)
- Cross-device sync
- Dark/light mode with Hive persistence
- Continuous scrolling
- Customizable font size and brightness
- Reading journal with quarter-star ratings, mood tags, pace, reviews
- Smart shelves with status tracking
- Reading goals, streaks, and achievements
- Social features, book clubs, and discovery
- AI reading tools (story recaps, character tracker, vocabulary builder)
- Import from Goodreads, StoryGraph, Kindle

## The Problem We're Solving

Modern readers use 3-5+ apps across their reading lifecycle:
- Discover: BookTok, Goodreads, StoryGraph, Reddit
- Acquire: Kindle, Libby, Kobo, bookstores
- Read: Kindle, Apple Books, Kobo, physical
- Track: StoryGraph, Goodreads, spreadsheets
- Journal: Notion, physical journals
- Review: Goodreads + StoryGraph (duplicated effort)
- Discuss: Discord, group chats, Fable, Bookclubs.com
- Export notes: Readwise ($8-12/mo intermediary)

No single app covers more than 2-3 of these stages well.

---

## Tier 1 — High Impact, Fills Major Gaps (COMPLETE)

### 1.1 Reading Journal & Rich Book Metadata
- [x] Basic highlights and bookmarks
- [x] Quarter-star ratings (0.25 increments)
- [x] Mood tags per book (adventurous, dark, emotional, hopeful, funny, tense, inspiring)
- [x] Pace tracking (slow, medium, fast)
- [x] Reading status: Want to Read, Currently Reading, Read, DNF, Re-reading
- [x] Format tracking: physical, ebook, audiobook, ARC
- [x] Progress-based notes (journal entries pinned to page/percentage)
- [x] Post-read review with private/public toggle
- [x] Quote collection with page/chapter references
- [x] Custom tags (user-defined: tropes, vibes, content warnings)
- [x] Re-read support (separate journal entries per read-through)

### 1.2 TBR & Library Management
- [x] Book discovery via APIs
- [x] Smart shelves: Want to Read, Currently Reading, Read, DNF + custom shelves
- [x] TBR priority levels (drag-to-reorder)
- [x] "Owned" tracking: physical, digital, audio vs. want to acquire
- [x] Series tracking (which books read, what's next)
- [x] Import from Goodreads (CSV) and StoryGraph

### 1.3 Reading Goals & Gamification
- [x] Reading session tracking with timer
- [x] Annual reading challenge (books/year) with ahead/behind pace
- [x] Reading streaks (consecutive days)
- [x] Badges/achievements (first book, 10-book milestone, genre explorer)
- [x] Daily/weekly reading time goals
- [x] Year-in-Review / Reading Wrap (shareable, Spotify Wrapped-style)

### 1.4 Structured Highlight & Note Export
- [x] Basic data export
- [x] Unlimited highlight/note export in Markdown, JSON, CSV
- [x] Per-book export with full metadata
- [x] Bulk export of entire highlight library
- [x] Direct sync to Obsidian (Markdown files with YAML frontmatter + wikilinks)
- [x] Direct sync to Notion (structured JSON export)
- [x] Daily highlight review (spaced repetition resurfacing)

---

## Tier 2 — Medium Impact, Strong Differentiators (COMPLETE)

### 2.1 Social & Community
- [x] Activity feed (friends' reading activity)
- [x] Follow other readers, browse public shelves
- [x] Buddy reads with shared progress
- [x] Friend recommendations with personal notes
- [x] Per-book privacy controls (public, friends-only, private)
- [x] Community-sourced content warnings (graphic/moderate/minor)

### 2.2 Book Club Hub
- [x] Create/join book clubs
- [x] Ranked-choice voting for next book (from members' TBR)
- [x] Reading schedule generator (chapters/week + reminders)
- [x] Chapter-gated discussion threads (spoiler-free)
- [x] AI-generated discussion questions per chapter
- [x] Shared progress dashboard
- [x] Meeting scheduling with RSVP

### 2.3 Smart Discovery & Recommendations
- [x] Mood-based discovery ("hopeful and fast-paced")
- [x] "Because you liked X" recs from reading history + mood/pace
- [x] Friend recommendations feed
- [x] AI reading advisor (conversational discovery)
- [x] Trending in your genres

---

## Tier 3 — Unique Differentiators (COMPLETE)

### 3.1 AI Reading Companion (Enhanced)
- [x] Basic AI companion
- [x] "Story So Far" recaps (spoiler-free, for any book)
- [x] Character tracker (AI-maintained character/relationship list)
- [x] Vocabulary builder (flashcard review of looked-up words)
- [x] Reading comprehension Q&A (up to current position)
- [x] AI-powered content warnings

### 3.2 Audiobook Position Sync
- [x] Manual audiobook tracking (listening time, chapter, notes)
- [x] Timestamp-to-text mapping
- [x] Unified progress bar (reading + listening)

### 3.3 Anti-Lock-In Positioning
- [x] Multi-format reading (6+ formats)
- [x] Data export
- [x] Import from Goodreads CSV, StoryGraph, Kindle My Clippings.txt
- [x] Open API for third-party integrations

---

## Competitive Landscape Summary

| Competitor | Strength | Weakness |
|---|---|---|
| Goodreads | 150M users, largest database | Outdated UI, no dark mode, no half-stars, review bombing |
| StoryGraph | Mood/pace tags, quarter-stars, deep stats, content warnings | Weak social, smaller database |
| Fable | Book clubs, social reading, celebrity curation | Low engagement, $70/yr, performance issues |
| Kindle | Best sync, X-Ray, Word Wise, massive catalog | DRM lock-in, highlight caps, poor library org |
| Google Books | Free upload, DRM-free option, Gemini AI | No shelves, highlight bugs, smaller catalog |
| Audible | Largest audiobook catalog, ownership model | DRM, no note export, storefront-heavy UX |
| Bookly | Timer + ambient sounds, streaks, infographics | 10-book free limit, can feel like homework |
| Readwise | Highlight aggregation, PKM sync, spaced repetition | $120/yr just to access your own highlights |
| Notion journals | Infinite customization | Manual entry, no barcode scan, offline-limited |

## Key Research Sources

- 2026 State of Reading Report (Everand/Fable)
- Reedsy: Goodreads vs StoryGraph comparison
- BookWise: StoryGraph features analysis
- TextMuncher: Kindle DRM/export analysis 2025
- Readwise user research
- Bookclubs.com feature analysis
- StoryGraph public roadmap
- Pratt IXD: Goodreads UX critique
- ARC Library feature set
- Kobo annotation export developments
