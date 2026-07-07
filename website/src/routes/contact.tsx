import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/contact")({
  head: () => ({
    meta: [
      { title: "Contact — Aurora" },
      {
        name: "description",
        content: "Ways to get in touch — email and the usual social links.",
      },
      { property: "og:title", content: "Contact — Aurora" },
      {
        property: "og:description",
        content: "Ways to get in touch.",
      },
    ],
  }),
  component: Contact,
});

const links = [
  { label: "Email", value: "hello@example.com", href: "mailto:hello@example.com" },
  { label: "GitHub", value: "github.com/yourhandle", href: "https://github.com/" },
  { label: "LinkedIn", value: "linkedin.com/in/yourhandle", href: "https://linkedin.com/" },
  { label: "X / Twitter", value: "@yourhandle", href: "https://x.com/" },
];

function Contact() {
  return (
    <section className="relative overflow-hidden">
      <div className="aurora-glow" />
      <div className="relative mx-auto max-w-3xl px-6 pb-24 pt-20">
        <p className="text-xs font-semibold uppercase tracking-[0.3em] text-aurora-teal">Contact</p>
        <h1 className="mt-3 text-5xl font-bold tracking-tight sm:text-6xl">
          <span className="text-text-primary">Let's</span>{" "}
          <span className="text-aurora">talk.</span>
        </h1>
        <p className="mt-4 max-w-xl text-lg text-text-secondary">
          Best way to reach me is email. I usually reply within a day or two.
        </p>

        <div className="mt-12 divide-y divide-white/5 overflow-hidden rounded-2xl border border-white/10 bg-surface/60">
          {links.map((l) => (
            <a
              key={l.label}
              href={l.href}
              target={l.href.startsWith("http") ? "_blank" : undefined}
              rel={l.href.startsWith("http") ? "noreferrer" : undefined}
              className="group flex items-center justify-between gap-4 px-6 py-5 transition-colors hover:bg-surface-elev"
            >
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.25em] text-text-tertiary">
                  {l.label}
                </p>
                <p className="mt-1 text-lg text-text-primary group-hover:text-aurora-teal">
                  {l.value}
                </p>
              </div>
              <span
                aria-hidden
                className="text-2xl text-text-tertiary transition-transform group-hover:translate-x-1 group-hover:text-aurora-teal"
              >
                →
              </span>
            </a>
          ))}
        </div>
      </div>
    </section>
  );
}
