import { projects } from "@/data/projects";
import { ProjectCard } from "@/components/ProjectCard";

export function Projects() {
  return (
    <section className="mx-auto max-w-5xl px-6 py-20">
      <p className="text-xs font-semibold uppercase tracking-[0.3em] text-ink-faint">
        Projects
      </p>
      <h1 className="mt-3 text-4xl font-bold tracking-tight text-ink sm:text-5xl">
        Everything I'm building
      </h1>

      {projects.length > 0 ? (
        <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {projects.map((p) => (
            <ProjectCard key={p.slug} project={p} />
          ))}
        </div>
      ) : (
        <p className="mt-12 text-ink-dim">Nothing published yet — check back soon.</p>
      )}
    </section>
  );
}
