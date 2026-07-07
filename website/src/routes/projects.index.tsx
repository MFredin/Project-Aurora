import { createFileRoute } from "@tanstack/react-router";
import { useSuspenseQuery } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { publishedProjectsQuery } from "@/lib/projects-queries";
import { ProjectCard } from "@/components/project-card";

export const Route = createFileRoute("/projects/")({
  head: () => ({
    meta: [
      { title: "Projects — Aurora" },
      {
        name: "description",
        content: "The full index of projects, filterable by tech and topic.",
      },
      { property: "og:title", content: "Projects — Aurora" },
      {
        property: "og:description",
        content: "The full index of projects, filterable by tech and topic.",
      },
    ],
  }),
  loader: ({ context }) => context.queryClient.ensureQueryData(publishedProjectsQuery()),
  component: ProjectsList,
});

function ProjectsList() {
  const { data: projects } = useSuspenseQuery(publishedProjectsQuery());
  const [active, setActive] = useState<string | null>(null);

  const tags = useMemo(() => {
    const set = new Set<string>();
    projects.forEach((p) => p.tech.forEach((t) => set.add(t)));
    return Array.from(set).sort();
  }, [projects]);

  const filtered = active ? projects.filter((p) => p.tech.includes(active)) : projects;

  return (
    <section className="mx-auto max-w-6xl px-6 pb-24 pt-16">
      <div className="mb-12 max-w-2xl">
        <p className="text-xs font-semibold uppercase tracking-[0.3em] text-aurora-teal">Index</p>
        <h1 className="mt-3 text-5xl font-bold tracking-tight sm:text-6xl">
          <span className="text-aurora">All projects</span>
        </h1>
        <p className="mt-4 text-lg text-text-secondary">
          {projects.length} {projects.length === 1 ? "entry" : "entries"} — production apps,
          prototypes, and the occasional take-apart-and-see.
        </p>
      </div>

      {tags.length > 0 && (
        <div className="mb-10 flex flex-wrap gap-2">
          <button
            onClick={() => setActive(null)}
            className={[
              "rounded-full px-3.5 py-1.5 text-xs font-medium uppercase tracking-wider transition-all",
              active === null
                ? "bg-aurora text-deep-space"
                : "border border-white/10 text-text-secondary hover:border-aurora-teal/40 hover:text-text-primary",
            ].join(" ")}
          >
            All
          </button>
          {tags.map((t) => (
            <button
              key={t}
              onClick={() => setActive(t === active ? null : t)}
              className={[
                "rounded-full px-3.5 py-1.5 text-xs font-medium uppercase tracking-wider transition-all",
                active === t
                  ? "bg-aurora text-deep-space"
                  : "border border-white/10 text-text-secondary hover:border-aurora-teal/40 hover:text-text-primary",
              ].join(" ")}
            >
              {t}
            </button>
          ))}
        </div>
      )}

      {filtered.length === 0 ? (
        <p className="py-24 text-center text-text-secondary">No projects match this filter.</p>
      ) : (
        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map((p, i) => (
            <ProjectCard key={p.id} project={p} index={i} />
          ))}
        </div>
      )}
    </section>
  );
}
