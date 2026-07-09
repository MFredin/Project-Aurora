import { useEffect, useState } from "react";
import { NavLink, useLocation } from "react-router-dom";
import { site } from "@/data/site";
import { Logo } from "@/components/Logo";
import { Container } from "@/components/Container";

const links = [
  { to: "/", label: "Home", end: true },
  { to: "/projects", label: "Projects" },
  { to: "/log", label: "Log" },
  { to: "/about", label: "About" },
  { to: "/contact", label: "Contact" },
];

const linkClass = ({ isActive }: { isActive: boolean }) =>
  `rounded-full px-3 py-1.5 text-sm transition-colors ${
    isActive ? "text-ink" : "text-ink-dim hover:text-ink"
  }`;

export function SiteHeader() {
  const [open, setOpen] = useState(false);
  const location = useLocation();

  useEffect(() => {
    setOpen(false);
  }, [location.pathname]);

  return (
    <header className="sticky top-0 z-20 border-b border-line/80 bg-bg/80 backdrop-blur">
      <Container width="wide" className="flex items-center justify-between py-4">
        <NavLink
          to="/"
          onClick={() => setOpen(false)}
          className="flex items-center gap-2.5 text-sm font-semibold tracking-tight text-ink"
        >
          <Logo className="h-7 w-7" />
          {site.name}
        </NavLink>

        <nav className="hidden items-center gap-1 sm:flex">
          {links.map((link) => (
            <NavLink key={link.to} to={link.to} end={link.end} className={linkClass}>
              {link.label}
            </NavLink>
          ))}
        </nav>

        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          aria-expanded={open}
          aria-label={open ? "Close menu" : "Open menu"}
          className="flex h-9 w-9 items-center justify-center rounded-full text-ink-dim transition-colors hover:text-ink sm:hidden"
        >
          {open ? (
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          ) : (
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <path d="M4 7h16M4 12h16M4 17h16" />
            </svg>
          )}
        </button>
      </Container>

      {open && (
        <nav className="border-t border-line/80 px-6 py-3 sm:hidden">
          <div className="flex flex-col gap-1">
            {links.map((link) => (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                onClick={() => setOpen(false)}
                className={({ isActive }) =>
                  `rounded-full px-3 py-2.5 text-base transition-colors ${
                    isActive ? "text-ink" : "text-ink-dim hover:text-ink"
                  }`
                }
              >
                {link.label}
              </NavLink>
            ))}
          </div>
        </nav>
      )}
    </header>
  );
}
