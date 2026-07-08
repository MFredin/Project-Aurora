import { projects } from "@/data/projects";
import { ProjectCard } from "@/components/ProjectCard";

export function Projects() {
  return (
    <section className="relative overflow-hidden">
      <div className="ambient-glow" />
      <div className="relative mx-auto max-w-5xl px-6 py-24">
        <p className="eyebrow text-ink-faint">Projects</p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight text-ink sm:text-5xl">
          Everything I'm building
        </h1>

        {projects.length > 0 ? (
          <div className="mt-12 grid grid-cols-[repeat(auto-fit,minmax(280px,min(360px,100%)))] gap-6">
            {projects.map((p) => (
              <ProjectCard key={p.slug} project={p} />
            ))}
          </div>
        ) : (
          <p className="mt-12 text-ink-dim">Nothing published yet — check back soon.</p>
        )}
      </div>
    </section>
  );
}
