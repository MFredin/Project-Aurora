import { Link, useParams } from "react-router-dom";
import { projects } from "@/data/projects";
import { Container } from "@/components/Container";
import { PageHero } from "@/components/PageHero";
import { Badge } from "@/components/Badge";
import { Button } from "@/components/Button";

const statusLabel = {
  "in-development": "In development",
  live: "Live",
} as const;

const statusVariant = {
  "in-development": "status-dev",
  live: "status-live",
} as const;

export function ProjectDetail() {
  const { slug } = useParams<{ slug: string }>();
  const project = projects.find((p) => p.slug === slug);

  if (!project) {
    return (
      <Container width="narrow" className="py-24 text-center">
        <p className="text-ink-dim">No project found at "{slug}".</p>
        <Link to="/projects" className="mt-4 inline-block text-copper hover:underline">
          &larr; Back to projects
        </Link>
      </Container>
    );
  }

  return (
    <>
      <PageHero
        beforeEyebrow={
          <Link to="/projects" className="text-sm text-ink-dim hover:text-ink">
            &larr; All projects
          </Link>
        }
        eyebrow="Project"
        title={<span className="text-gradient">{project.title}</span>}
        titleAdornment={
          <Badge variant={statusVariant[project.status]}>
            {statusLabel[project.status]}
          </Badge>
        }
        subhead={project.tagline}
        containerWidth="narrow"
      />
      <Container width="narrow" className="pb-16 sm:pb-20 lg:pb-24">
        <div className="flex flex-wrap gap-2">
          {project.tech.map((t) => (
            <Badge key={t}>{t}</Badge>
          ))}
        </div>

        <p className="mt-10 text-base leading-relaxed text-ink-dim">
          {project.description}
        </p>

        {(project.liveUrl || project.repoUrl) && (
          <div className="mt-10 flex flex-wrap gap-3">
            {project.liveUrl && (
              <Button href={project.liveUrl} variant="primary" size="sm">
                View live
              </Button>
            )}
            {project.repoUrl && (
              <Button href={project.repoUrl} variant="outline" size="sm">
                Source
              </Button>
            )}
          </div>
        )}
      </Container>
    </>
  );
}
