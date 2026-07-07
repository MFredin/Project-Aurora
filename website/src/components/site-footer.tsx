export function SiteFooter() {
  return (
    <footer className="mt-24 border-t border-white/5 py-10">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-2 px-6 text-xs text-text-tertiary sm:flex-row">
        <p>© {new Date().getFullYear()} Aurora. Built under the northern lights.</p>
        <p className="uppercase tracking-[0.2em]">Personal · projects · index</p>
      </div>
    </footer>
  );
}
