import { Link } from "react-router-dom";
import type { Project } from "@/data/projects";
import { Badge } from "@/components/Badge";
import { Button } from "@/components/Button";

const statusLabel: Record<Project["status"], string> = {
  "in-development": "In development",
  live: "Live",
};

const statusVariant: Record<Project["status"], "status-dev" | "status-live"> = {
  "in-development": "status-dev",
  live: "status-live",
};

interface ProjectCardProps {
  project: Project;
  variant?: "grid" | "spotlight";
}

export function ProjectCard({ project, variant = "grid" }: ProjectCardProps) {
  if (variant === "spotlight") {
    return (
      <div className="rounded-2xl border border-line bg-surface p-10 transition-colors hover:border-copper/40 sm:p-12">
        <div className="flex flex-wrap items-center gap-3">
          <h3 className="font-display text-display-sm font-semibold tracking-tight text-gradient">
            {project.title}
          </h3>
          <Badge variant={statusVariant[project.status]}>
            {statusLabel[project.status]}
          </Badge>
        </div>
        <p className="mt-3 text-lg text-ink-dim">{project.tagline}</p>
        <p className="mt-6 max-w-2xl leading-relaxed text-ink-dim">
          {project.description}
        </p>
        <div className="mt-6 flex flex-wrap gap-2">
          {project.tech.map((t) => (
            <Badge key={t}>{t}</Badge>
          ))}
        </div>
        <Button to={`/projects/${project.slug}`} variant="outline" size="sm" className="mt-8">
          View project
        </Button>
      </div>
    );
  }

  return (
    <Link
      to={`/projects/${project.slug}`}
      className="group flex flex-col gap-4 rounded-2xl border border-line bg-surface p-6 transition-colors hover:border-copper/40 hover:bg-surface-hi"
    >
      <div className="flex items-start justify-between gap-3">
        <h3 className="text-lg font-semibold text-ink group-hover:text-gradient">
          {project.title}
        </h3>
        <Badge variant={statusVariant[project.status]} className="shrink-0">
          {statusLabel[project.status]}
        </Badge>
      </div>
      <p className="text-sm leading-relaxed text-ink-dim">{project.tagline}</p>
      <div className="mt-auto flex flex-wrap gap-2 pt-2">
        {project.tech.slice(0, 4).map((t) => (
          <Badge key={t}>{t}</Badge>
        ))}
      </div>
    </Link>
  );
}
