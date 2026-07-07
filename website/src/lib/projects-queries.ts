import { queryOptions } from "@tanstack/react-query";
import { getPublishedProjects, getProjectBySlug } from "./projects.functions";

export const publishedProjectsQuery = () =>
  queryOptions({
    queryKey: ["projects", "published"],
    queryFn: () => getPublishedProjects(),
  });

export const projectBySlugQuery = (slug: string) =>
  queryOptions({
    queryKey: ["projects", "slug", slug],
    queryFn: () => getProjectBySlug({ data: { slug } }),
  });
