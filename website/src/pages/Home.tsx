import { site } from "@/data/site";
import { projects } from "@/data/projects";
import { Container } from "@/components/Container";
import { Button } from "@/components/Button";
import { ProjectGrid } from "@/components/ProjectGrid";
import { Link } from "react-router-dom";

export function Home() {
  const recent = projects.slice(0, 3);

  return (
    <>
      <section className="relative overflow-hidden">
        <div className="ambient-glow" />
        <Container
          width="wide"
          className="relative flex min-h-[70vh] flex-col justify-center gap-6 py-16 sm:py-20 lg:py-24"
        >
          <p className="eyebrow text-ink-faint">{site.role}</p>
          <h1 className="font-display max-w-3xl text-display-md font-semibold tracking-tight text-gradient sm:text-display-lg lg:text-display-xl">
            {site.name}
          </h1>
          <p className="max-w-xl text-lg text-ink-dim">
            A running index of the software I'm building — what's shipped,
            what's in progress, and what's still taking shape.
          </p>
          <div className="flex flex-wrap gap-3 pt-2">
            <Button to="/projects" variant="primary">
              View projects
            </Button>
            <Button to="/contact" variant="outline">
              Get in touch
            </Button>
          </div>
        </Container>
      </section>

      {recent.length > 0 && (
        <section>
          <Container width="wide" className="pb-16 sm:pb-20 lg:pb-24">
            <div className="mb-8 flex items-end justify-between gap-4">
              <h2 className="font-display text-2xl font-semibold tracking-tight text-ink">
                Recent work
              </h2>
              <Link to="/projects" className="text-sm text-ink-dim hover:text-ink">
                See all &rarr;
              </Link>
            </div>
            <ProjectGrid projects={recent} />
          </Container>
        </section>
      )}
    </>
  );
}
