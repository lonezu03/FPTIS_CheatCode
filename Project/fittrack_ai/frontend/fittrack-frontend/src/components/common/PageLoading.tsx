import { Skeleton } from "@/components/ui/skeleton";

export default function PageLoading() {
  return (
    <div className="space-y-4 md:space-y-6">
      <div className="space-y-1 md:space-y-2">
        <Skeleton className="h-6 w-40 md:h-8 md:w-48" />
        <Skeleton className="h-4 w-80 max-w-full" />
      </div>

      <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
        <Skeleton className="h-24 rounded-2xl md:h-32" />
        <Skeleton className="h-24 rounded-2xl md:h-32" />
        <Skeleton className="h-24 rounded-2xl md:h-32" />
        <Skeleton className="h-24 rounded-2xl md:h-32" />
      </div>

      <Skeleton className="h-56 rounded-2xl md:h-80" />
    </div>
  );
}
