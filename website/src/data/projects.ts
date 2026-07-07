export type ProjectStatus = "in-development" | "live";

export interface Project {
  slug: string;
  title: string;
  tagline: string;
  description: string;
  tech: string[];
  status: ProjectStatus;
  liveUrl?: string;
  repoUrl?: string;
}

// Add new projects here — each one gets a card on /projects and its own
// page at /projects/:slug automatically.
export const projects: Project[] = [
  {
    slug: "aurora-reader",
    title: "AuroraReader",
    tagline: "A cross-platform ebook reader with a Northern Lights theme.",
    description:
      "A calm, cross-platform reader for EPUB and PDF books, built with " +
      "Flutter and Swift. Handles book import and reading progress, " +
      "ambient soundscapes and text-to-speech while you read, and syncs " +
      "your library across devices. Runs on iOS, Android, Windows, and " +
      "the web from a single codebase.",
    tech: ["Flutter", "Dart", "Swift", "SwiftUI", "Riverpod", "SQLite"],
    status: "in-development",
  },
];
