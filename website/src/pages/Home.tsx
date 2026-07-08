import { Link } from "react-router-dom";
import { site } from "@/data/site";
import { projects } from "@/data/projects";
import { ProjectCard } from "@/components/ProjectCard";

export function Home() {
  const recent = projects.slice(0, 3);

  return (
    <>
      <section className="relative overflow-hidden">
        <div className="ambient-glow" />
        <div className="relative mx-auto flex min-h-[70vh] max-w-5xl flex-col justify-center gap-6 px-6 py-24">
          <p className="eyebrow text-ink-faint">{site.role}</p>
          <h1 className="max-w-3xl text-5xl font-extrabold leading-[1.05] tracking-tight text-gradient sm:text-6xl md:text-7xl">
            {site.name}
          </h1>
          <p className="max-w-xl text-lg text-ink-dim">
            A running index of the software I'm building — what's shipped,
            what's in progress, and what's still taking shape.
          </p>
          <div className="flex flex-wrap gap-3 pt-2">
            <Link
              to="/projects"
              className="rounded-full bg-gradient-accent px-6 py-3 text-sm font-semibold text-bg transition-transform hover:-translate-y-0.5"
            >
              View projects
            </Link>
            <Link
              to="/contact"
              className="rounded-full border border-line px-6 py-3 text-sm font-medium text-ink transition-colors hover:border-copper/40"
            >
              Get in touch
            </Link>
          </div>
        </div>
      </section>

      {recent.length > 0 && (
        <section className="mx-auto max-w-5xl px-6 pb-24">
          <div className="mb-8 flex items-end justify-between gap-4">
            <h2 className="text-2xl font-bold tracking-tight text-ink">
              Recent work
            </h2>
            <Link
              to="/projects"
              className="text-sm text-ink-dim hover:text-ink"
            >
              See all &rarr;
            </Link>
          </div>
          <div className="grid grid-cols-[repeat(auto-fit,minmax(280px,min(360px,100%)))] gap-6">
            {recent.map((p) => (
              <ProjectCard key={p.slug} project={p} />
            ))}
          </div>
        </section>
      )}
    </>
  );
}
