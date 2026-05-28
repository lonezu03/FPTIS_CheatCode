import { Inbox } from "lucide-react";

type EmptyStateProps = {
  title: string;
  description?: string;
};

export default function EmptyState({ title, description }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed bg-white p-10 text-center">
      <div className="mb-4 rounded-full bg-slate-100 p-4">
        <Inbox className="h-8 w-8 text-slate-500" />
      </div>

      <h3 className="text-lg font-semibold">{title}</h3>

      {description && <p className="mt-2 max-w-md text-sm text-muted-foreground">{description}</p>}
    </div>
  );
}
