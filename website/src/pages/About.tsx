import { Link } from "react-router-dom";
import { site } from "@/data/site";
import { projects } from "@/data/projects";
import { Container } from "@/components/Container";
import { PageHero } from "@/components/PageHero";
import { Badge } from "@/components/Badge";

const statusLabel = {
  "in-development": "In development",
  live: "Live",
} as const;

const statusVariant = {
  "in-development": "status-dev",
  live: "status-live",
} as const;

export function About() {
  const current = projects[0];

  return (
    <>
      <PageHero eyebrow="About" title={site.name} containerWidth="narrow" />
      <Container width="narrow" className="pb-16 sm:pb-20 lg:pb-24">
        <p className="text-lg leading-relaxed text-ink-dim">
          Bio coming soon. In the meantime, the{" "}
          <Link to="/projects" className="text-copper hover:underline">
            projects page
          </Link>{" "}
          is the best picture of what I'm working on.
        </p>

        {current && (
          <Link
            to={`/projects/${current.slug}`}
            className="group mt-8 flex items-center justify-between gap-4 rounded-2xl border border-line bg-surface p-6 transition-colors hover:border-copper/40 hover:bg-surface-hi"
          >
            <div>
              <p className="eyebrow text-ink-faint">Currently building</p>
              <p className="mt-2 text-lg font-semibold text-ink group-hover:text-gradient">
                {current.title}
              </p>
              <p className="mt-1 text-sm text-ink-dim">{current.tagline}</p>
            </div>
            <Badge variant={statusVariant[current.status]}>
              {statusLabel[current.status]}
            </Badge>
          </Link>
        )}
      </Container>
    </>
  );
}
