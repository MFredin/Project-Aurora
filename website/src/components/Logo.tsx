export function Logo({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 48 48"
      className={className}
      role="img"
      aria-label="Site mark"
    >
      <defs>
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
        r="14"
        fill="none"
        stroke="url(#logo-gradient)"
        strokeWidth="3"
      />
      <circle cx="24" cy="24" r="4" fill="url(#logo-gradient)" />
    </svg>
  );
}
