import EmptyStateArtwork, { type EmptyStateArtworkKind } from "../visuals/EmptyStateArtwork";

type EmptyStateProps = {
  title: string;
  description?: string;
  kind?: EmptyStateArtworkKind;
};

export default function EmptyState({ title, description, kind = "generic" }: EmptyStateProps) {
  return (
    <div className="relative flex min-h-56 flex-col items-center justify-center overflow-hidden rounded-3xl border border-dashed border-emerald-200 bg-gradient-to-b from-white via-white to-emerald-50/70 p-6 text-center sm:p-10">
      <div className="pointer-events-none absolute -left-12 -top-16 size-36 rounded-full bg-emerald-100/50 blur-2xl" />
      <div className="pointer-events-none absolute -bottom-16 -right-10 size-32 rounded-full bg-amber-100/45 blur-2xl" />
      <EmptyStateArtwork kind={kind} />

      <h3 className="text-base font-semibold tracking-tight sm:text-lg">{title}</h3>

      {description && <p className="mt-1.5 max-w-md text-sm leading-6 text-muted-foreground">{description}</p>}
    </div>
  );
}
