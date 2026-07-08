import { Link, useParams } from "react-router-dom";
import { projects } from "@/data/projects";

const statusLabel = {
  "in-development": "In development",
  live: "Live",
} as const;

export function ProjectDetail() {
  const { slug } = useParams<{ slug: string }>();
  const project = projects.find((p) => p.slug === slug);

  if (!project) {
    return (
      <section className="mx-auto max-w-2xl px-6 py-24 text-center">
        <p className="text-ink-dim">No project found at "{slug}".</p>
        <Link to="/projects" className="mt-4 inline-block text-copper hover:underline">
          &larr; Back to projects
        </Link>
      </section>
    );
  }

  return (
    <section className="relative overflow-hidden">
      <div className="ambient-glow" />
      <div className="relative mx-auto max-w-2xl px-6 py-24">
        <Link to="/projects" className="text-sm text-ink-dim hover:text-ink">
          &larr; All projects
        </Link>

        <div className="mt-6 flex flex-wrap items-center gap-3">
          <h1 className="text-4xl font-bold tracking-tight text-ink sm:text-5xl">
            {project.title}
          </h1>
          <span className="rounded-full border border-line px-2.5 py-1 text-xs text-ink-faint">
            {statusLabel[project.status]}
          </span>
        </div>
        <p className="mt-3 text-lg text-ink-dim">{project.tagline}</p>

        <div className="mt-6 flex flex-wrap gap-2">
          {project.tech.map((t) => (
            <span
              key={t}
              className="rounded-full bg-surface px-3 py-1 text-xs text-ink-dim"
            >
              {t}
            </span>
          ))}
        </div>

        <p className="mt-10 text-base leading-relaxed text-ink-dim">
          {project.description}
        </p>

        {(project.liveUrl || project.repoUrl) && (
          <div className="mt-10 flex flex-wrap gap-3">
            {project.liveUrl && (
              <a
                href={project.liveUrl}
                target="_blank"
                rel="noreferrer"
                className="rounded-full bg-gradient-accent px-5 py-2.5 text-sm font-semibold text-bg"
              >
                View live
              </a>
            )}
            {project.repoUrl && (
              <a
                href={project.repoUrl}
                target="_blank"
                rel="noreferrer"
                className="rounded-full border border-line px-5 py-2.5 text-sm text-ink hover:border-copper/40"
              >
                Source
              </a>
            )}
          </div>
        )}
      </div>
    </section>
  );
}
