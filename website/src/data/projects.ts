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
    slug: "edda",
    title: "Edda",
    tagline: "Mystical ebook reader — read in the shadows of the stave.",
    description:
      "Edda is a mystical ebook reader for EPUB and PDF, built on Flutter " +
      "with Riverpod and Firebase. Beyond the reading experience, it " +
      "includes a reading journal for ratings, moods, and pace; social " +
      "features and book clubs; and a multi-provider AI companion across " +
      "OpenAI, Gemini, and Anthropic. It imports libraries from Goodreads, " +
      "StoryGraph, and Kindle, exports highlights to Obsidian and Notion, " +
      "and keeps audiobook playback in sync with your place in the text.",
    tech: ["Flutter", "Dart", "Riverpod", "Firebase", "Drift", "Hive"],
    status: "in-development",
  },
];
