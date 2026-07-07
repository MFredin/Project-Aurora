# Personal Projects Site — "Aurora" Aesthetic

A personal website showcasing your projects, styled after the Project-Aurora / EDDA mockup: dark deep-space canvas, vivid aurora-gradient accents, SF Pro type. Projects are stored in Lovable Cloud so you can add and edit them without code changes.

## Design system

Ported directly from `mockup.html` into `src/styles.css` as design tokens (oklch equivalents of the hex values):

- **Backgrounds**: `--deep-space #0a0a1f`, `--cosmos #12122e`, `--surface #1a1a38`, `--surface-elev #222244`
- **Aurora accents**: green `#2ede8f`, teal `#26c7d1`, blue `#4078f2`, purple `#944cf2`, pink `#d940a6`, warm `#f27340`
- **Text**: primary `#ededf7`, secondary `#9e9eb8`, tertiary `#666684`
- **Signature gradient**: `linear-gradient(135deg, aurora-green → teal → blue → purple → pink)` used on the wordmark, section rules, active nav, hover glows
- **Font**: SF Pro Display / system stack for body + headings; a lighter tracking-wide treatment for hero and section labels
- **Motion**: subtle aurora glow on hover, gentle parallax/gradient shimmer on hero, framer-motion fade-up on scroll

## Sitemap

- `/` — Hero + featured projects preview
- `/projects` — Full grid of all projects, filterable by tag/tech
- `/projects/$slug` — Detail page: cover image, description, tech stack, links (live/GitHub)
- `/about` — Bio, background, skills
- `/contact` — Email + social links (simple, no form for now)
- `/auth` — Sign-in (email/password) — only you
- `/_authenticated/admin` — Project CRUD (list, create, edit, delete, reorder)

Each public route gets its own `head()` with unique title, description, og:title/description. `/projects/$slug` derives og:image from the project's cover.

## Content model (Lovable Cloud)

Table `public.projects`:

- `id uuid pk`, `slug text unique`, `title text`, `tagline text`, `description text` (markdown), `cover_url text`, `tech text[]`, `live_url text`, `repo_url text`, `featured boolean`, `sort_order int`, `published boolean`, `created_at`, `updated_at`

Table `public.user_roles` with `app_role` enum (`admin`, `user`) and `has_role()` security-definer function — so only you (with the `admin` role) can write.

RLS:

- `SELECT` to `anon` + `authenticated` where `published = true` (public gallery)
- `SELECT` to `authenticated` where `has_role(auth.uid(),'admin')` (owner sees drafts too — needed so the admin dashboard can list unpublished rows)
- `INSERT/UPDATE/DELETE` to `authenticated` gated by `has_role(auth.uid(),'admin')`
- Explicit GRANTs for `anon`, `authenticated`, `service_role`

Storage bucket `project-covers` (public read) for cover images, uploadable from the admin UI.

## Data fetching

- Public list/detail: TanStack Query `queryOptions` + loader `ensureQueryData` using a server publishable client (respects the public RLS policy). Loader also feeds `head()` for per-project OG metadata.
- Admin list/mutations: `createServerFn` with `requireSupabaseAuth` middleware; role check via `has_role` inside the handler.

## Pages — composition

**Home (`/`)**

- Full-viewport hero: giant wordmark with the aurora gradient sweep, one-line tagline, "View projects" + "Contact" CTAs
- Featured projects strip (3 cards) pulled from `featured = true`
- Subtle animated aurora glow behind hero

**Projects (`/projects`)**

- Section label with gradient underline
- Tag filter chips (derived from `tech` arrays)
- Responsive card grid: cover image, title, tagline, tech pills; hover raises the card and blooms an aurora shadow

**Project detail (`/projects/$slug`)**

- Full-width cover
- Title, tagline, tech pills
- Markdown description
- Sticky sidebar (desktop) with Live / GitHub / back-to-projects links

**About (`/about`)** — long-form bio + skills grid, aurora accents on headers.

**Contact (`/contact`)** — email + social links as large tappable rows with aurora hover.

**Admin (`/_authenticated/admin`)** — table of all projects, create/edit form (title, slug, tagline, markdown description, tech tags input, cover upload, featured/published toggles, sort order), delete confirmation.

## Auth

- Email/password only (you're the sole admin)
- `/auth` public route with sign-in form
- One-time seed migration inserts your `admin` role for a specified user id (I'll ask for the email when we're ready to seed, or you sign up first and I grant the role via SQL)

## Technical notes

- TanStack Start file-based routes under `src/routes/` — no `src/pages/`
- Design tokens live in `src/styles.css` under `@theme inline` (Tailwind v4)
- Aurora gradient exposed as a reusable utility (`@utility text-aurora`, `@utility bg-aurora`)
- All colors go through semantic tokens — no hardcoded hex in components
- framer-motion for hero + card animations
- No Google/Apple OAuth in v1; can add later

## Out of scope for v1

- Blog / writing section
- Contact form with email delivery
- Analytics
- Auto-pulling repos from GitHub (you asked for editable-via-Cloud instead)

## Build order

1. Enable Lovable Cloud, create `projects` table + `user_roles` + `has_role` + RLS + GRANTs + storage bucket
2. Design tokens + aurora utilities in `src/styles.css`, update `__root.tsx` metadata
3. Public routes: home, projects list, project detail, about, contact — with seed content so the site looks alive immediately
4. Auth route + `_authenticated` layout (integration-managed)
5. Admin CRUD (list + form + cover upload)
6. Motion polish + per-route OG metadata + favicon
