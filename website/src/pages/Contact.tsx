import { site, socialLinks } from "@/data/site";

export function Contact() {
  return (
    <section className="mx-auto max-w-2xl px-6 py-24">
      <p className="eyebrow text-ink-faint">Contact</p>
      <h1 className="mt-3 text-4xl font-bold tracking-tight text-ink sm:text-5xl">
        Let's talk.
      </h1>

      <div className="mt-10 divide-y divide-line overflow-hidden rounded-2xl border border-line bg-surface">
        <a
          href={`mailto:${site.email}`}
          className="group flex items-center justify-between gap-4 px-6 py-5 transition-colors hover:bg-surface-hi"
        >
          <div>
            <p className="eyebrow text-ink-faint">Email</p>
            <p className="mt-1 text-lg text-ink group-hover:text-copper">
              {site.email}
            </p>
          </div>
          <span className="text-xl text-ink-faint transition-transform group-hover:translate-x-1 group-hover:text-copper">
            &rarr;
          </span>
        </a>

        {socialLinks.map((link) =>
          link.placeholder ? (
            <div
              key={link.label}
              className="flex items-center justify-between gap-4 px-6 py-5"
            >
              <div>
                <p className="eyebrow text-ink-faint/60">{link.label}</p>
                <p className="mt-1 text-lg text-ink-dim">Not linked yet</p>
              </div>
            </div>
          ) : (
            <a
              key={link.label}
              href={link.href}
              target="_blank"
              rel="noreferrer"
              className="group flex items-center justify-between gap-4 px-6 py-5 transition-colors hover:bg-surface-hi"
            >
              <div>
                <p className="eyebrow text-ink-faint">{link.label}</p>
                <p className="mt-1 text-lg text-ink group-hover:text-copper">
                  {link.href}
                </p>
              </div>
              <span className="text-xl text-ink-faint transition-transform group-hover:translate-x-1 group-hover:text-copper">
                &rarr;
              </span>
            </a>
          ),
        )}
      </div>
    </section>
  );
}
