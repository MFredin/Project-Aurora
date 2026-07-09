import { Link } from "react-router-dom";

type ButtonVariant = "primary" | "outline";
type ButtonSize = "md" | "sm";

interface ButtonBaseProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  className?: string;
  children: React.ReactNode;
}

type ButtonProps =
  | (ButtonBaseProps & { to: string; href?: never })
  | (ButtonBaseProps & { href: string; to?: never });

const sizeClass: Record<ButtonSize, string> = {
  md: "px-6 py-3",
  sm: "px-5 py-2.5",
};

const variantClass: Record<ButtonVariant, string> = {
  primary: "bg-gradient-accent text-bg hover:-translate-y-0.5",
  outline: "border border-line text-ink hover:border-copper/40",
};

export function Button({ variant = "primary", size = "md", className = "", children, ...props }: ButtonProps) {
  const classes = `inline-flex items-center justify-center rounded-full text-sm font-semibold transition-all duration-150 active:scale-[0.97] ${variantClass[variant]} ${sizeClass[size]} ${className}`;

  if ("to" in props && props.to) {
    return (
      <Link to={props.to} className={classes}>
        {children}
      </Link>
    );
  }

  return (
    <a
      href={(props as { href: string }).href}
      target="_blank"
      rel="noreferrer"
      className={classes}
    >
      {children}
    </a>
  );
}
