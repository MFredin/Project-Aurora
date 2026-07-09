import { changelog } from "@/data/changelog";
import { Container } from "@/components/Container";
import { PageHero } from "@/components/PageHero";

function formatDate(iso: string) {
  return new Date(`${iso}T00:00:00`).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export function Log() {
  return (
    <>
      <PageHero
        eyebrow="Log"
        title="Building in the open."
        subhead="A running record of what's shipped, changed, or shifted along the way."
        containerWidth="narrow"
      />
      <Container width="narrow" className="pb-16 sm:pb-20 lg:pb-24">
        <ol className="divide-y divide-line border-t border-line">
          {changelog.map((entry) => (
            <li key={`${entry.date}-${entry.title}`} className="py-8">
              <p className="eyebrow text-ink-faint">{formatDate(entry.date)}</p>
              <h2 className="font-display mt-2 text-xl font-semibold text-ink">
                {entry.title}
              </h2>
              <p className="mt-2 leading-relaxed text-ink-dim">{entry.body}</p>
            </li>
          ))}
        </ol>
      </Container>
    </>
  );
}
