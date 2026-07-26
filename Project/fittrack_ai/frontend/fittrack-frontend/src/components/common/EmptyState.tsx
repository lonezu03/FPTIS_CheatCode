import { Inbox } from "lucide-react";

type EmptyStateProps = {
  title: string;
  description?: string;
};

export default function EmptyState({ title, description }: EmptyStateProps) {
  return (
    <div className="flex min-h-48 flex-col items-center justify-center rounded-2xl border border-dashed border-emerald-200 bg-gradient-to-b from-white to-emerald-50/45 p-6 text-center sm:p-10">
      <div className="mb-4 rounded-2xl bg-emerald-100 p-3 text-emerald-700 shadow-sm sm:p-4">
        <Inbox className="size-6 sm:size-7" />
      </div>

      <h3 className="text-base font-semibold tracking-tight sm:text-lg">{title}</h3>

      {description && <p className="mt-1.5 max-w-md text-sm leading-6 text-muted-foreground">{description}</p>}
    </div>
  );
}
