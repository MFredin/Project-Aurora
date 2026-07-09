import { site } from "@/data/site";
import { Container } from "@/components/Container";

export function SiteFooter() {
  return (
    <footer className="border-t border-line">
      <Container
        width="wide"
        className="flex flex-col gap-2 py-8 text-sm text-ink-faint sm:flex-row sm:items-center sm:justify-between"
      >
        <p>
          &copy; {new Date().getFullYear()} {site.name}
        </p>
        <a href={`mailto:${site.email}`} className="hover:text-ink-dim">
          {site.email}
        </a>
      </Container>
    </footer>
  );
}
