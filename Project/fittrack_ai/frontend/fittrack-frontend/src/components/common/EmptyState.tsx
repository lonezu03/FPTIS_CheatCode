import { Inbox } from "lucide-react";

type EmptyStateProps = {
  title: string;
  description?: string;
};

export default function EmptyState({ title, description }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed bg-white p-5 text-center sm:p-10">
      <div className="mb-3 rounded-full bg-slate-100 p-3 sm:mb-4 sm:p-4">
        <Inbox className="h-6 w-6 text-slate-500 sm:h-8 sm:w-8" />
      </div>

      <h3 className="text-base font-semibold sm:text-lg">{title}</h3>

      {description && <p className="mt-1 max-w-md text-xs text-muted-foreground sm:mt-2 sm:text-sm">{description}</p>}
    </div>
  );
}
