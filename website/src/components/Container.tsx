interface ContainerProps {
  width?: "wide" | "narrow";
  className?: string;
  children: React.ReactNode;
}

export function Container({ width = "wide", className = "", children }: ContainerProps) {
  const maxWidth = width === "wide" ? "max-w-5xl" : "max-w-2xl";
  return (
    <div className={`mx-auto ${maxWidth} px-6 sm:px-8 ${className}`}>{children}</div>
  );
}
