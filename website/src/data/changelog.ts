export interface ChangelogEntry {
  date: string; // ISO date (YYYY-MM-DD)
  title: string;
  body: string;
}

// Newest first. Add an entry here whenever something worth noting ships.
export const changelog: ChangelogEntry[] = [
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
