import type { Project } from "@/data/projects";
import { ProjectCard } from "@/components/ProjectCard";

export function ProjectGrid({ projects }: { projects: Project[] }) {
  if (projects.length === 0) {
    return <p className="text-ink-dim">Nothing published yet — check back soon.</p>;
  }

  if (projects.length <= 2) {
    return (
      <div className="flex flex-col gap-6">
        {projects.map((p) => (
          <ProjectCard key={p.slug} project={p} variant="spotlight" />
        ))}
      </div>
    );
  }

  return (
    <div className="grid grid-cols-[repeat(auto-fit,minmax(280px,min(360px,100%)))] gap-6">
      {projects.map((p) => (
        <ProjectCard key={p.slug} project={p} />
      ))}
    </div>
  );
}
