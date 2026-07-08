import { NavLink } from "react-router-dom";
import { site } from "@/data/site";

const links = [
  { to: "/", label: "Home", end: true },
  { to: "/projects", label: "Projects" },
  { to: "/log", label: "Log" },
  { to: "/about", label: "About" },
  { to: "/contact", label: "Contact" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-20 border-b border-line/80 bg-bg/85 backdrop-blur">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
        <NavLink to="/" className="text-sm font-semibold tracking-tight text-ink">
          {site.name}
        </NavLink>
        <nav className="flex items-center gap-1">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.end}
              className={({ isActive }) =>
                `rounded-full px-3 py-1.5 text-sm transition-colors ${
                  isActive
                    ? "text-ink"
                    : "text-ink-dim hover:text-ink"
                }`
              }
            >
              {link.label}
            </NavLink>
          ))}
        </nav>
      </div>
    </header>
  );
}
