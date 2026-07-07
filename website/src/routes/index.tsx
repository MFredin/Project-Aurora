import { createFileRoute, Link } from "@tanstack/react-router";
import { useSuspenseQuery } from "@tanstack/react-query";
import { motion } from "framer-motion";
import { publishedProjectsQuery } from "@/lib/projects-queries";
import { ProjectCard } from "@/components/project-card";

export const Route = createFileRoute("/")({
  loader: ({ context }) => context.queryClient.ensureQueryData(publishedProjectsQuery()),
  component: Index,
  errorComponent: ({ error }) => (
    <div className="mx-auto max-w-2xl px-6 py-24 text-center text-text-secondary">
      {error.message}
    </div>
  ),
});

function Index() {
  const { data: projects } = useSuspenseQuery(publishedProjectsQuery());
  const featured = projects.filter((p) => p.featured).slice(0, 3);
  const showcase = featured.length > 0 ? featured : projects.slice(0, 3);

  return (
    <>
      {/* HERO */}
      <section className="relative overflow-hidden">
        <div className="aurora-glow" />
        <div className="relative mx-auto flex min-h-[min(88vh,760px)] max-w-6xl flex-col items-start justify-center gap-8 px-6 py-24">
          <motion.p
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-xs font-medium uppercase tracking-[0.35em] text-aurora-teal"
          >
            Aurora — Personal Index
          </motion.p>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.05 }}
            className="max-w-4xl text-6xl font-bold leading-[0.95] tracking-tight sm:text-7xl md:text-8xl"
          >
            <span className="block text-text-primary">Building at the</span>
            <span className="text-aurora block">edge of the aurora.</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.15 }}
            className="max-w-xl text-lg text-text-secondary"
          >
            A living index of software, design, and side quests — everything I've been shipping,
            sketching, and taking apart to figure out how it works.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.25 }}
            className="flex flex-wrap gap-3"
          >
            <Link
              to="/projects"
              className="bg-aurora inline-flex items-center gap-2 rounded-full px-6 py-3 text-sm font-semibold text-deep-space transition-transform hover:-translate-y-0.5"
            >
              View projects
              <span aria-hidden>→</span>
            </Link>
            <Link
              to="/contact"
              className="inline-flex items-center rounded-full border border-white/10 bg-surface/60 px-6 py-3 text-sm font-medium text-text-primary transition-colors hover:border-aurora-teal/40"
            >
              Get in touch
            </Link>
          </motion.div>
        </div>
      </section>

      {/* FEATURED */}
      {showcase.length > 0 && (
        <section className="mx-auto max-w-6xl px-6 py-20">
          <div className="mb-10 flex items-end justify-between gap-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.3em] text-aurora-teal">
                Selected work
              </p>
              <h2 className="mt-2 text-3xl font-bold tracking-tight sm:text-4xl">
                What I've been building
              </h2>
            </div>
            <Link
              to="/projects"
              className="hidden text-sm text-text-secondary underline-offset-4 hover:text-aurora-teal hover:underline sm:inline"
            >
              See all →
            </Link>
          </div>
          <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {showcase.map((p, i) => (
              <ProjectCard key={p.id} project={p} index={i} />
            ))}
          </div>
        </section>
      )}

      {projects.length === 0 && (
        <section className="mx-auto max-w-3xl px-6 pb-24 text-center">
          <div className="gradient-border rounded-2xl bg-surface/50 p-10">
            <p className="text-sm uppercase tracking-[0.3em] text-aurora-teal">Empty index</p>
            <p className="mt-3 text-text-secondary">
              No projects yet. Sign in and open{" "}
              <Link to="/admin" className="text-aurora-teal underline">
                the admin
              </Link>{" "}
              to add your first one.
            </p>
          </div>
        </section>
      )}
    </>
  );
}
