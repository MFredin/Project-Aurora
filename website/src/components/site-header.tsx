import { Link, useRouterState } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

const nav = [
  { to: "/", label: "Home" },
  { to: "/projects", label: "Projects" },
  { to: "/about", label: "About" },
  { to: "/contact", label: "Contact" },
] as const;

export function SiteHeader() {
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const [signedIn, setSignedIn] = useState(false);

  useEffect(() => {
    let mounted = true;
    supabase.auth.getSession().then(({ data }) => {
      if (mounted) setSignedIn(!!data.session);
    });
    const { data: sub } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === "SIGNED_IN" || event === "SIGNED_OUT" || event === "USER_UPDATED") {
        setSignedIn(!!session);
      }
    });
    return () => {
      mounted = false;
      sub.subscription.unsubscribe();
    };
  }, []);

  return (
    <header className="sticky top-0 z-40 border-b border-white/5 bg-background/70 backdrop-blur-xl">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
        <Link to="/" className="group flex items-center gap-2">
          <span className="text-aurora text-xl font-bold tracking-tight">Aurora</span>
          <span className="hidden text-xs uppercase tracking-[0.2em] text-text-tertiary sm:inline">
            / projects
          </span>
        </Link>

        <nav className="flex items-center gap-1 text-sm">
          {nav.map((item) => {
            const active = item.to === "/" ? pathname === "/" : pathname.startsWith(item.to);
            return (
              <Link
                key={item.to}
                to={item.to}
                className={[
                  "relative rounded-full px-3 py-1.5 transition-colors",
                  active ? "text-text-primary" : "text-text-secondary hover:text-text-primary",
                ].join(" ")}
              >
                {active && <span className="bg-aurora-soft absolute inset-0 rounded-full" />}
                <span className="relative">{item.label}</span>
              </Link>
            );
          })}
          {signedIn && (
            <Link
              to="/admin"
              className="ml-2 rounded-full border border-white/10 px-3 py-1.5 text-text-secondary transition-colors hover:border-aurora-teal/40 hover:text-text-primary"
            >
              Admin
            </Link>
          )}
        </nav>
      </div>
    </header>
  );
}
