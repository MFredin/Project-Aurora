import { changelog } from "@/data/changelog";

function formatDate(iso: string) {
  return new Date(`${iso}T00:00:00`).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export function Log() {
  return (
    <section className="mx-auto max-w-2xl px-6 py-24">
      <p className="eyebrow text-ink-faint">Log</p>
      <h1 className="mt-3 text-4xl font-bold tracking-tight text-ink sm:text-5xl">
        Building in the open.
      </h1>
      <p className="mt-4 text-lg text-ink-dim">
        A running record of what's shipped, changed, or shifted along the
        way.
      </p>

      <ol className="mt-12 divide-y divide-line border-t border-line">
        {changelog.map((entry) => (
          <li key={`${entry.date}-${entry.title}`} className="py-8">
            <p className="eyebrow text-ink-faint">{formatDate(entry.date)}</p>
            <h2 className="mt-2 text-xl font-semibold text-ink">
              {entry.title}
            </h2>
            <p className="mt-2 leading-relaxed text-ink-dim">{entry.body}</p>
          </li>
        ))}
      </ol>
    </section>
  );
}
