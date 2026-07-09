type BadgeVariant = "neutral" | "status-dev" | "status-live";

interface BadgeProps {
  variant?: BadgeVariant;
  children: React.ReactNode;
  className?: string;
}

const variantClass: Record<BadgeVariant, string> = {
  neutral: "border-line bg-surface-hi text-ink-faint",
  "status-dev": "border-copper/20 bg-copper/10 text-copper",
  "status-live": "border-moss/20 bg-moss/10 text-moss",
};

export function Badge({ variant = "neutral", children, className = "" }: BadgeProps) {
  return (
    <span
      className={`rounded-full border px-2.5 py-1 text-xs ${variantClass[variant]} ${className}`}
    >
      {children}
    </span>
  );
}
