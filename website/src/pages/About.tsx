import { Link } from "react-router-dom";
import { site } from "@/data/site";

export function About() {
  return (
    <section className="mx-auto max-w-2xl px-6 py-24">
      <p className="eyebrow text-ink-faint">About</p>
      <h1 className="mt-3 text-4xl font-bold tracking-tight text-ink sm:text-5xl">
        {site.name}
      </h1>
      <p className="mt-6 text-lg leading-relaxed text-ink-dim">
        Bio coming soon. In the meantime, the{" "}
        <Link to="/projects" className="text-copper hover:underline">
          projects page
        </Link>{" "}
        is the best picture of what I'm working on.
      </p>
    </section>
  );
}
