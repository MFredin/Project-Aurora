export interface ChangelogEntry {
  date: string; // ISO date (YYYY-MM-DD)
  title: string;
  body: string;
}

// Newest first. Add an entry here whenever something worth noting ships.
export const changelog: ChangelogEntry[] = [
  {
    date: "2026-06-06",
    title: "A pass for trust before beta",
    body: "Went through the whole app addressing trust and clarity issues ahead of a public beta — tightening up permissions, error states, and anything that could confuse a first-time reader.",
  },
  {
    date: "2026-06-04",
    title: "The full Tier 1–3 feature set",
    body: "Rounded out Edda's core feature set: a reading journal with ratings, mood tags, and pace tracking, social features and book clubs, cross-format import from Goodreads, StoryGraph, and Kindle, and highlight export to Obsidian and Notion.",
  },
  {
    date: "2026-05-30",
    title: "Signed in, backed up",
    body: "Wired up Firebase authentication and Google Drive-backed cloud storage, so an account and a library can now follow you across devices.",
  },
  {
    date: "2026-05-30",
    title: "Choose your AI companion",
    body: "Added a multi-provider AI reading companion, with a choice of OpenAI, Gemini, or Anthropic models for discussing and exploring what you're reading.",
  },
  {
    date: "2026-05-29",
    title: "Stave & Shadow",
    body: "Replaced the Runestone look with a new Stave & Shadow aesthetic and carried it across the whole app, then iterated the mark itself — from a stave arch, to a runic knot 'E', to a bind rune combining Ehwaz and Dagaz — before finally dropping the wordmark from the library header in favor of the mark alone.",
  },
  {
    date: "2026-05-29",
    title: "Aurora Reader becomes Edda",
    body: "Renamed the app from Aurora Reader to Edda, with new logo and icons — the first step in a broader rebrand toward a more mystical, Norse-inflected identity.",
  },
  {
    date: "2026-05-29",
    title: "Progress that survives a refresh",
    body: "Added Hive-backed persistence for AuroraReader's web build — books, reading progress, and sessions now survive a page refresh instead of resetting.",
  },
  {
    date: "2026-05-29",
    title: "Reading, wired end-to-end",
    body: "Connected book import, the reader itself, and progress tracking into one working flow, rather than separate pieces.",
  },
  {
    date: "2026-05-28",
    title: "A web alpha, live",
    body: "Brought AuroraReader to the browser: a responsive layout, PWA support, and platform-safe services, deployed via a new GitHub Pages pipeline.",
  },
  {
    date: "2026-02-11",
    title: "Going cross-platform",
    body: "Rebuilt AuroraReader on Flutter for device-agnostic deployment, and added a Windows build pipeline with installer and MSIX packaging.",
  },
  {
    date: "2026-02-10",
    title: "Standing up QA",
    body: "Built out a proper QA environment — stability and performance testing — ahead of pushing further platform work.",
  },
  {
    date: "2026-02-09",
    title: "Every reading feature, at once",
    body: "Shipped the original iOS app's full production feature set in one push: cloud OAuth, book discovery, iCloud sync, ambient audio, text-to-speech, a dictionary, and data export.",
  },
  {
    date: "2026-02-09",
    title: "An AI reading companion",
    body: "Added Claude-powered highlights, search, a knowledge graph, ambient immersion, and book clubs on top of the core reader.",
  },
  {
    date: "2026-02-09",
    title: "The first build",
    body: "Started AuroraReader as a native iOS app with multi-format support, then gave it the Aurora / Northern Lights redesign across 11 supported formats.",
  },
];
