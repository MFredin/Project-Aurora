import { Link } from "react-router-dom";
import type { Project } from "@/data/projects";

const statusLabel: Record<Project["status"], string> = {
  "in-development": "In development",
  live: "Live",
};

export function ProjectCard({ project }: { project: Project }) {
  return (
    <Link
      to={`/projects/${project.slug}`}
      className="group flex flex-col gap-4 rounded-2xl border border-line bg-surface p-6 transition-colors hover:border-copper/40 hover:bg-surface-hi"
    >
      <div className="flex items-start justify-between gap-3">
        <h3 className="text-lg font-semibold text-ink group-hover:text-gradient">
          {project.title}
        </h3>
        <span className="shrink-0 rounded-full border border-line px-2.5 py-1 text-xs text-ink-faint">
          {statusLabel[project.status]}
        </span>
      </div>
      <p className="text-sm leading-relaxed text-ink-dim">{project.tagline}</p>
      <div className="mt-auto flex flex-wrap gap-2 pt-2">
        {project.tech.slice(0, 4).map((t) => (
          <span
            key={t}
            className="rounded-full bg-bg px-2.5 py-1 text-xs text-ink-faint"
          >
            {t}
          </span>
        ))}
      </div>
    </Link>
  );
}
