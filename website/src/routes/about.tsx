import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/about")({
  head: () => ({
    meta: [
      { title: "About — Aurora" },
      {
        name: "description",
        content:
          "About the person behind the projects — background, focus areas, and how to get in touch.",
      },
      { property: "og:title", content: "About — Aurora" },
      {
        property: "og:description",
        content: "About the person behind the projects.",
      },
    ],
  }),
  component: About,
});

const focus = [
  {
    label: "Product engineering",
    body: "End-to-end web and mobile apps — from the first sketch to the deploy that finally sticks.",
  },
  {
    label: "Interface design",
    body: "Interfaces that feel physical and calm. Typography, motion, and the small stuff that adds up.",
  },
  {
    label: "Systems & tools",
    body: "Internal tools, developer experience, and the plumbing that makes everything else possible.",
  },
];

function About() {
  return (
    <section className="relative overflow-hidden">
      <div className="aurora-glow" />
      <div className="relative mx-auto max-w-4xl px-6 pb-24 pt-20">
        <p className="text-xs font-semibold uppercase tracking-[0.3em] text-aurora-teal">About</p>
        <h1 className="mt-3 text-5xl font-bold tracking-tight sm:text-6xl">
          <span className="text-aurora">Hey — I'm the person</span>{" "}
          <span className="text-text-primary">behind this index.</span>
        </h1>

        <div className="mt-10 space-y-6 text-lg leading-relaxed text-text-secondary">
          <p>
            I build software for the web and for pocket-sized screens. Aurora is where I collect
            what I've shipped, what I've prototyped, and the occasional experiment that never quite
            made it out of the garage.
          </p>
          <p>
            The through-line: interfaces that feel considered, systems that hold up under real use,
            and design that respects the person on the other side of the screen.
          </p>
        </div>

        <div className="mt-16 grid gap-6 sm:grid-cols-3">
          {focus.map((f) => (
            <div key={f.label} className="gradient-border rounded-2xl bg-surface/60 p-6">
              <p className="text-sm font-semibold text-aurora-teal">{f.label}</p>
              <p className="mt-3 text-sm text-text-secondary">{f.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
