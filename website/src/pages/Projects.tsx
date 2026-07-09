import { projects } from "@/data/projects";
import { Container } from "@/components/Container";
import { PageHero } from "@/components/PageHero";
import { ProjectGrid } from "@/components/ProjectGrid";

export function Projects() {
  return (
    <>
      <PageHero eyebrow="Projects" title="Everything I'm building" glow containerWidth="wide" />
      <Container width="wide" className="pb-16 sm:pb-20 lg:pb-24">
        <ProjectGrid projects={projects} />
      </Container>
    </>
  );
}
