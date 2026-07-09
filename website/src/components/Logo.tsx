export function Logo({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 48 48"
      className={className}
      role="img"
      aria-label="Site mark"
    >
      <defs>
        {/* Stops mirror --gradient-accent's colors/offsets (index.css) — SVG
            gradients can't consume a CSS linear-gradient() string, so this
            stays a parallel definition. Keep the two in sync by hand. */}
        <linearGradient id="logo-gradient" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="var(--color-copper)" />
          <stop offset="55%" stopColor="var(--color-clay)" />
          <stop offset="100%" stopColor="var(--color-moss)" />
        </linearGradient>
      </defs>
      <rect width="48" height="48" rx="12" fill="var(--color-surface)" />
      <circle
        cx="24"
        cy="24"
        r="17"
        fill="none"
        stroke="url(#logo-gradient)"
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeDasharray="98 9"
        strokeDashoffset="27"
      />
      <g
        fill="none"
        stroke="url(#logo-gradient)"
        strokeWidth="3.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M24 12 L17 19 L24 26 L31 19 Z" />
        <path d="M24 26 L17 35" />
        <path d="M24 26 L31 35" />
      </g>
    </svg>
  );
}
