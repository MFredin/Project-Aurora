import { createFileRoute, Link, notFound } from "@tanstack/react-router";
import { useSuspenseQuery } from "@tanstack/react-query";
import ReactMarkdown from "react-markdown";
import { projectBySlugQuery } from "@/lib/projects-queries";

export const Route = createFileRoute("/projects/$slug")({
  loader: async ({ params, context }) => {
    const p = await context.queryClient.ensureQueryData(projectBySlugQuery(params.slug));
    if (!p) throw notFound();
    return null;
  },
  head: ({ loaderData, params }) => {
    if (!loaderData && params) {
      // notFound() case
      return {
        meta: [{ title: "Project not found — Aurora" }, { name: "robots", content: "noindex" }],
      };
    }
    // We rely on the component's query cache for title; keep generic meta here
    // and let the component render richer meta via head hints if needed.
    return { meta: [] };
  },
  component: ProjectDetail,
  notFoundComponent: () => (
    <div className="mx-auto max-w-2xl px-6 py-24 text-center">
      <p className="text-aurora text-6xl font-bold">Not found</p>
      <p className="mt-4 text-text-secondary">This project doesn't exist or was unpublished.</p>
      <Link
        to="/projects"
        className="mt-6 inline-block rounded-full border border-white/10 px-5 py-2 text-sm text-text-primary hover:border-aurora-teal/40"
      >
        ← Back to projects
      </Link>
    </div>
  ),
});

function ProjectDetail() {
  const { slug } = Route.useParams();
  const { data: project } = useSuspenseQuery(projectBySlugQuery(slug));
  if (!project) return null;

  return (
    <article className="relative">
      {/* Cover */}
      <div className="relative h-[46vh] min-h-[320px] w-full overflow-hidden">
        <div className="aurora-glow" />
        {project.cover_url ? (
          <img
            src={project.cover_url}
            alt={project.title}
            className="relative h-full w-full object-cover"
          />
        ) : (
          <div className="bg-aurora relative h-full w-full opacity-70" />
        )}
        <div className="absolute inset-x-0 bottom-0 h-2/3 bg-gradient-to-t from-background via-background/70 to-transparent" />
      </div>

      <div className="mx-auto -mt-32 max-w-4xl px-6 pb-24">
        <Link
          to="/projects"
          className="mb-8 inline-flex items-center gap-2 text-sm text-text-secondary hover:text-aurora-teal"
        >
          <span aria-hidden>←</span> All projects
        </Link>

        <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-surface/70 p-8 backdrop-blur-xl sm:p-12">
          {project.featured && (
            <span className="bg-aurora absolute right-6 top-6 rounded-full px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-deep-space">
              Featured
            </span>
          )}
          <h1 className="max-w-3xl text-4xl font-bold leading-tight tracking-tight sm:text-6xl">
            {project.title}
          </h1>
          {project.tagline && (
            <p className="mt-4 max-w-2xl text-xl text-text-secondary">{project.tagline}</p>
          )}

          {project.tech.length > 0 && (
            <div className="mt-6 flex flex-wrap gap-2">
              {project.tech.map((t) => (
                <span
                  key={t}
                  className="rounded-full border border-white/10 bg-surface-elev px-3 py-1 text-xs uppercase tracking-wider text-text-secondary"
                >
                  {t}
                </span>
              ))}
            </div>
          )}

          {(project.live_url || project.repo_url) && (
            <div className="mt-8 flex flex-wrap gap-3">
              {project.live_url && (
                <a
                  href={project.live_url}
                  target="_blank"
                  rel="noreferrer"
                  className="bg-aurora inline-flex items-center gap-2 rounded-full px-5 py-2.5 text-sm font-semibold text-deep-space"
                >
                  Live site ↗
                </a>
              )}
              {project.repo_url && (
                <a
                  href={project.repo_url}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-surface px-5 py-2.5 text-sm font-medium text-text-primary hover:border-aurora-teal/40"
                >
                  Source ↗
                </a>
              )}
            </div>
          )}

          {project.description && (
            <div className="prose prose-invert prose-headings:text-text-primary prose-p:text-text-secondary prose-a:text-aurora-teal prose-strong:text-text-primary mt-10 max-w-none text-text-secondary leading-relaxed">
              <ReactMarkdown>{project.description}</ReactMarkdown>
            </div>
          )}
        </div>
      </div>
    </article>
  );
}
