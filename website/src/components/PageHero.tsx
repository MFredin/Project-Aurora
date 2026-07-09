import { Container } from "@/components/Container";

interface PageHeroProps {
  beforeEyebrow?: React.ReactNode;
  eyebrow: string;
  title: React.ReactNode;
  titleAdornment?: React.ReactNode;
  subhead?: React.ReactNode;
  glow?: boolean;
  size?: "md" | "lg";
  containerWidth?: "wide" | "narrow";
  actions?: React.ReactNode;
  className?: string;
}

const titleClass: Record<NonNullable<PageHeroProps["size"]>, string> = {
  md: "font-display text-display-sm sm:text-display-md font-semibold tracking-tight",
  lg: "font-display text-display-md sm:text-display-lg font-semibold tracking-tight",
};

export function PageHero({
  beforeEyebrow,
  eyebrow,
  title,
  titleAdornment,
  subhead,
  glow = false,
  size = "md",
  containerWidth = "narrow",
  actions,
  className = "",
}: PageHeroProps) {
  return (
    <section className={`relative overflow-hidden ${className}`}>
      {glow && <div className="ambient-glow" />}
      <Container width={containerWidth} className="relative py-16 sm:py-20 lg:py-24">
        {beforeEyebrow && <div className="mb-6">{beforeEyebrow}</div>}
        <p className="eyebrow text-ink-faint">{eyebrow}</p>
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <h1 className={titleClass[size]}>{title}</h1>
          {titleAdornment}
        </div>
        {subhead && <div className="mt-4 text-lg text-ink-dim">{subhead}</div>}
        {actions && <div className="mt-6 flex flex-wrap gap-3">{actions}</div>}
      </Container>
    </section>
  );
}
