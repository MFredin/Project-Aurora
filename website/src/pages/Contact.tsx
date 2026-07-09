import { site, socialLinks } from "@/data/site";
import { Container } from "@/components/Container";
import { PageHero } from "@/components/PageHero";

export function Contact() {
  return (
    <>
      <PageHero eyebrow="Contact" title="Let's talk." containerWidth="narrow" />
      <Container width="narrow" className="pb-16 sm:pb-20 lg:pb-24">
        <div className="divide-y divide-line overflow-hidden rounded-2xl border border-line bg-surface">
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
      </Container>
    </>
  );
}
