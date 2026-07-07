import { Link } from "@tanstack/react-router";
import { motion } from "framer-motion";
import type { Project } from "@/lib/projects.functions";

const GRADIENTS = [
  "linear-gradient(135deg, var(--aurora-purple), var(--aurora-blue))",
  "linear-gradient(135deg, var(--aurora-pink), var(--aurora-purple))",
  "linear-gradient(135deg, var(--aurora-teal), var(--aurora-green))",
  "linear-gradient(135deg, var(--aurora-blue), var(--aurora-teal))",
  "linear-gradient(135deg, var(--aurora-warm), var(--aurora-pink))",
  "linear-gradient(135deg, var(--aurora-green), var(--aurora-teal))",
];

function pickGradient(seed: string) {
  let hash = 0;
  for (let i = 0; i < seed.length; i++) hash = (hash * 31 + seed.charCodeAt(i)) | 0;
  return GRADIENTS[Math.abs(hash) % GRADIENTS.length];
}

export function ProjectCard({ project, index = 0 }: { project: Project; index?: number }) {
  const fallback = pickGradient(project.slug);
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.5, delay: Math.min(index * 0.05, 0.3) }}
    >
      <Link to="/projects/$slug" params={{ slug: project.slug }} className="group block">
        <div
          className="relative aspect-[4/3] overflow-hidden rounded-2xl border border-white/5 transition-transform duration-500 group-hover:-translate-y-1 group-hover:shadow-aurora"
          style={{ background: project.cover_url ? undefined : fallback }}
        >
          {project.cover_url && (
            <img
              src={project.cover_url}
              alt={project.title}
              className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
              loading="lazy"
            />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-deep-space/90 via-deep-space/20 to-transparent" />
          {project.featured && (
            <span className="bg-aurora absolute right-3 top-3 rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-deep-space">
              Featured
            </span>
          )}
        </div>
        <div className="mt-4 space-y-2">
          <h3 className="text-lg font-semibold text-text-primary transition-colors group-hover:text-aurora-teal">
            {project.title}
          </h3>
          {project.tagline && (
            <p className="line-clamp-2 text-sm text-text-secondary">{project.tagline}</p>
          )}
          {project.tech.length > 0 && (
            <div className="flex flex-wrap gap-1.5 pt-1">
              {project.tech.slice(0, 4).map((t) => (
                <span
                  key={t}
                  className="rounded-full border border-white/10 bg-surface px-2 py-0.5 text-[10px] uppercase tracking-wider text-text-tertiary"
                >
                  {t}
                </span>
              ))}
            </div>
          )}
        </div>
      </Link>
    </motion.div>
  );
}
