import { PageHero } from "@/components/PageHero";
import { Button } from "@/components/Button";

export function NotFound() {
  return (
    <PageHero
      eyebrow="404"
      title="Not found"
      subhead="That page doesn't exist."
      containerWidth="narrow"
      actions={
        <Button to="/" variant="outline">
          &larr; Back home
        </Button>
      }
    />
  );
}
