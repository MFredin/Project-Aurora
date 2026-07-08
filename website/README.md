# Personal website

Martin Fredin's personal site — a project index. Vite + React + TypeScript +
Tailwind CSS, no backend. Project content lives in `src/data/projects.ts`;
site-wide info (name, email, social links) lives in `src/data/site.ts`.

## Develop

```sh
npm install
npm run dev
```

## Build

```sh
npm run build
```

Outputs static files to `dist/`. Deployed by
`.github/workflows/deploy-web.yml` to GitHub Pages at `/Project-Aurora/site/`,
alongside the AuroraReader web build at `/Project-Aurora/`.

## Adding a project

Add an entry to the `projects` array in `src/data/projects.ts` — it
automatically gets a card on `/projects` and a page at `/projects/:slug`.
