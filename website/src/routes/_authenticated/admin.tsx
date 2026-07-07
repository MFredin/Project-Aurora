import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import {
  deleteProject,
  getIsAdmin,
  listAllProjects,
  upsertProject,
  type Project,
} from "@/lib/projects.functions";

export const Route = createFileRoute("/_authenticated/admin")({
  head: () => ({
    meta: [{ title: "Admin — Aurora" }, { name: "robots", content: "noindex" }],
  }),
  component: Admin,
});

function Admin() {
  const qc = useQueryClient();
  const isAdminFn = useServerFn(getIsAdmin);
  const listFn = useServerFn(listAllProjects);
  const upsertFn = useServerFn(upsertProject);
  const deleteFn = useServerFn(deleteProject);

  const adminQ = useQuery({
    queryKey: ["is-admin"],
    queryFn: () => isAdminFn(),
  });

  const projectsQ = useQuery({
    queryKey: ["admin", "projects"],
    queryFn: () => listFn(),
    enabled: adminQ.data?.isAdmin === true,
  });

  const [editing, setEditing] = useState<Project | null>(null);
  const [creating, setCreating] = useState(false);

  type UpsertPayload = {
    id?: string;
    slug: string;
    title: string;
    tagline: string;
    description: string;
    cover_url?: string;
    tech: string[];
    live_url?: string;
    repo_url?: string;
    featured: boolean;
    sort_order: number;
    published: boolean;
  };
  const upsertM = useMutation({
    mutationFn: (payload: UpsertPayload) => upsertFn({ data: payload }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "projects"] });
      qc.invalidateQueries({ queryKey: ["projects"] });
      setEditing(null);
      setCreating(false);
    },
  });

  const deleteM = useMutation({
    mutationFn: (id: string) => deleteFn({ data: { id } }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "projects"] });
      qc.invalidateQueries({ queryKey: ["projects"] });
    },
  });

  if (adminQ.isLoading) {
    return <div className="mx-auto max-w-5xl px-6 py-16 text-text-secondary">Loading…</div>;
  }

  if (!adminQ.data?.isAdmin) {
    return (
      <div className="mx-auto max-w-2xl px-6 py-24 text-center">
        <p className="text-xs uppercase tracking-[0.3em] text-aurora-teal">Access</p>
        <h1 className="mt-3 text-3xl font-bold">Not an admin yet</h1>
        <p className="mt-4 text-text-secondary">
          You're signed in, but this account doesn't have the admin role yet. Your user id:
        </p>
        <code className="mt-4 inline-block rounded-lg border border-white/10 bg-surface px-3 py-2 text-xs text-aurora-teal">
          {adminQ.data?.userId}
        </code>
        <p className="mt-4 text-sm text-text-tertiary">
          Ask the site owner to grant you the admin role, or grant it via the Cloud database.
        </p>
        <SignOutButton />
      </div>
    );
  }

  const openCreate = () => {
    setEditing(null);
    setCreating(true);
  };

  return (
    <section className="mx-auto max-w-5xl px-6 py-16">
      <div className="mb-10 flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-aurora-teal">Admin</p>
          <h1 className="mt-2 text-4xl font-bold tracking-tight">Projects</h1>
        </div>
        <div className="flex gap-2">
          <button
            onClick={openCreate}
            className="bg-aurora rounded-full px-4 py-2 text-sm font-semibold text-deep-space"
          >
            + New project
          </button>
          <SignOutButton />
        </div>
      </div>

      {(creating || editing) && (
        <ProjectForm
          initial={editing}
          saving={upsertM.isPending}
          error={upsertM.error instanceof Error ? upsertM.error.message : null}
          onCancel={() => {
            setEditing(null);
            setCreating(false);
          }}
          onSave={(payload) => upsertM.mutate(payload)}
        />
      )}

      <div className="mt-6 space-y-2">
        {projectsQ.data?.map((p) => (
          <div
            key={p.id}
            className="flex items-center justify-between gap-4 rounded-xl border border-white/10 bg-surface/60 px-4 py-3"
          >
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <p className="truncate font-medium text-text-primary">{p.title}</p>
                {p.featured && (
                  <span className="rounded-full bg-aurora-purple/20 px-2 py-0.5 text-[10px] uppercase tracking-wider text-aurora-purple">
                    Featured
                  </span>
                )}
                {!p.published && (
                  <span className="rounded-full bg-white/10 px-2 py-0.5 text-[10px] uppercase tracking-wider text-text-tertiary">
                    Draft
                  </span>
                )}
              </div>
              <p className="truncate text-xs text-text-tertiary">/{p.slug}</p>
            </div>
            <div className="flex items-center gap-2">
              <Link
                to="/projects/$slug"
                params={{ slug: p.slug }}
                className="rounded-full border border-white/10 px-3 py-1 text-xs text-text-secondary hover:border-aurora-teal/40"
              >
                View
              </Link>
              <button
                onClick={() => {
                  setCreating(false);
                  setEditing(p);
                }}
                className="rounded-full border border-white/10 px-3 py-1 text-xs text-text-secondary hover:border-aurora-teal/40"
              >
                Edit
              </button>
              <button
                onClick={() => {
                  if (confirm(`Delete "${p.title}"?`)) deleteM.mutate(p.id);
                }}
                className="rounded-full border border-destructive/40 px-3 py-1 text-xs text-destructive-foreground hover:bg-destructive/20"
              >
                Delete
              </button>
            </div>
          </div>
        ))}
        {projectsQ.data?.length === 0 && (
          <p className="py-16 text-center text-sm text-text-secondary">
            No projects yet. Create the first one.
          </p>
        )}
      </div>
    </section>
  );
}

function SignOutButton() {
  return (
    <button
      onClick={async () => {
        await supabase.auth.signOut();
        window.location.href = "/";
      }}
      className="rounded-full border border-white/10 px-4 py-2 text-sm text-text-secondary hover:border-aurora-teal/40"
    >
      Sign out
    </button>
  );
}

function ProjectForm({
  initial,
  saving,
  error,
  onCancel,
  onSave,
}: {
  initial: Project | null;
  saving: boolean;
  error: string | null;
  onCancel: () => void;
  onSave: (p: {
    id?: string;
    slug: string;
    title: string;
    tagline: string;
    description: string;
    cover_url?: string;
    tech: string[];
    live_url?: string;
    repo_url?: string;
    featured: boolean;
    sort_order: number;
    published: boolean;
  }) => void;
}) {
  const [state, setState] = useState({
    slug: initial?.slug ?? "",
    title: initial?.title ?? "",
    tagline: initial?.tagline ?? "",
    description: initial?.description ?? "",
    cover_url: initial?.cover_url ?? "",
    techInput: (initial?.tech ?? []).join(", "),
    live_url: initial?.live_url ?? "",
    repo_url: initial?.repo_url ?? "",
    featured: initial?.featured ?? false,
    sort_order: initial?.sort_order ?? 0,
    published: initial?.published ?? true,
  });

  useEffect(() => {
    setState({
      slug: initial?.slug ?? "",
      title: initial?.title ?? "",
      tagline: initial?.tagline ?? "",
      description: initial?.description ?? "",
      cover_url: initial?.cover_url ?? "",
      techInput: (initial?.tech ?? []).join(", "),
      live_url: initial?.live_url ?? "",
      repo_url: initial?.repo_url ?? "",
      featured: initial?.featured ?? false,
      sort_order: initial?.sort_order ?? 0,
      published: initial?.published ?? true,
    });
  }, [initial]);

  function submit(e: React.FormEvent) {
    e.preventDefault();
    onSave({
      id: initial?.id,
      slug: state.slug.trim(),
      title: state.title.trim(),
      tagline: state.tagline,
      description: state.description,
      cover_url: state.cover_url.trim() || undefined,
      tech: state.techInput
        .split(",")
        .map((t) => t.trim())
        .filter(Boolean),
      live_url: state.live_url.trim() || undefined,
      repo_url: state.repo_url.trim() || undefined,
      featured: state.featured,
      sort_order: state.sort_order,
      published: state.published,
    });
  }

  const inputCls =
    "w-full rounded-lg border border-white/10 bg-deep-space px-3 py-2 text-sm text-text-primary placeholder:text-text-tertiary focus:border-aurora-teal/60 focus:outline-none";

  return (
    <form
      onSubmit={submit}
      className="gradient-border mb-6 space-y-4 rounded-2xl bg-surface/70 p-6"
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Title">
          <input
            required
            className={inputCls}
            value={state.title}
            onChange={(e) => setState((s) => ({ ...s, title: e.target.value }))}
          />
        </Field>
        <Field label="Slug (url)">
          <input
            required
            className={inputCls}
            value={state.slug}
            onChange={(e) =>
              setState((s) => ({
                ...s,
                slug: e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, "-"),
              }))
            }
          />
        </Field>
      </div>
      <Field label="Tagline">
        <input
          className={inputCls}
          value={state.tagline}
          onChange={(e) => setState((s) => ({ ...s, tagline: e.target.value }))}
        />
      </Field>
      <Field label="Description (markdown)">
        <textarea
          rows={6}
          className={inputCls}
          value={state.description}
          onChange={(e) => setState((s) => ({ ...s, description: e.target.value }))}
        />
      </Field>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Cover image URL">
          <input
            className={inputCls}
            value={state.cover_url}
            onChange={(e) => setState((s) => ({ ...s, cover_url: e.target.value }))}
            placeholder="https://…"
          />
        </Field>
        <Field label="Tech (comma-separated)">
          <input
            className={inputCls}
            value={state.techInput}
            onChange={(e) => setState((s) => ({ ...s, techInput: e.target.value }))}
            placeholder="React, Postgres, Swift"
          />
        </Field>
        <Field label="Live URL">
          <input
            className={inputCls}
            value={state.live_url}
            onChange={(e) => setState((s) => ({ ...s, live_url: e.target.value }))}
          />
        </Field>
        <Field label="Repo URL">
          <input
            className={inputCls}
            value={state.repo_url}
            onChange={(e) => setState((s) => ({ ...s, repo_url: e.target.value }))}
          />
        </Field>
        <Field label="Sort order">
          <input
            type="number"
            className={inputCls}
            value={state.sort_order}
            onChange={(e) => setState((s) => ({ ...s, sort_order: Number(e.target.value) }))}
          />
        </Field>
      </div>

      <div className="flex flex-wrap gap-4 pt-2">
        <Toggle
          label="Featured"
          checked={state.featured}
          onChange={(v) => setState((s) => ({ ...s, featured: v }))}
        />
        <Toggle
          label="Published"
          checked={state.published}
          onChange={(v) => setState((s) => ({ ...s, published: v }))}
        />
      </div>

      {error && (
        <p className="rounded-lg border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive-foreground">
          {error}
        </p>
      )}

      <div className="flex gap-2 pt-2">
        <button
          type="submit"
          disabled={saving}
          className="bg-aurora rounded-full px-5 py-2 text-sm font-semibold text-deep-space disabled:opacity-60"
        >
          {saving ? "Saving…" : initial ? "Save changes" : "Create"}
        </button>
        <button
          type="button"
          onClick={onCancel}
          className="rounded-full border border-white/10 px-5 py-2 text-sm text-text-secondary"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs uppercase tracking-wider text-text-tertiary">
        {label}
      </span>
      {children}
    </label>
  );
}

function Toggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label className="inline-flex cursor-pointer items-center gap-2">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="h-4 w-4 accent-aurora-teal"
      />
      <span className="text-sm text-text-secondary">{label}</span>
    </label>
  );
}
