import { Link } from "react-router-dom";

export function NotFound() {
  return (
    <section className="mx-auto flex max-w-2xl flex-col items-start px-6 py-24">
      <h1 className="text-4xl font-bold tracking-tight text-ink">Not found</h1>
      <p className="mt-3 text-ink-dim">That page doesn't exist.</p>
      <Link to="/" className="mt-6 text-copper hover:underline">
        &larr; Back home
      </Link>
    </section>
  );
}
