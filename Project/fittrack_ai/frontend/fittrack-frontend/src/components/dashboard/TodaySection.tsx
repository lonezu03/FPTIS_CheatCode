import type { ElementType, ReactNode } from "react";
import { AlertCircle, ArrowRight, RotateCw } from "lucide-react";
import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

type SectionState = "loading" | "error" | "empty" | "ready";

/**
 * Card shell shared by the "Hôm nay" sections. Each section owns its queries,
 * so one failing endpoint never hides the others.
 */
export default function TodaySection({ id, title, icon: Icon, iconClassName, meta, link, state, skeletonRows = 3, errorText, onRetry, empty, children, className }: {
  id: string;
  title: string;
  icon: ElementType;
  iconClassName?: string;
  meta?: ReactNode;
  link?: { to: string; label: string };
  state: SectionState;
  skeletonRows?: number;
  errorText?: string;
  onRetry?: () => void;
  empty?: ReactNode;
  children?: ReactNode;
  className?: string;
}) {
  const headingId = `${id}-title`;
  return (
    <Card role="region" className={cn("min-w-0", className)} aria-labelledby={headingId} data-testid={id}>
      <CardHeader className="flex flex-row items-center justify-between gap-3 space-y-0 pb-2">
        <CardTitle id={headingId} role="heading" aria-level={2} className="flex min-w-0 items-center gap-2 text-base">
          <span className={cn("grid size-8 shrink-0 place-items-center rounded-lg bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200", iconClassName)}>
            <Icon className="size-4" />
          </span>
          <span className="truncate">{title}</span>
        </CardTitle>
        <div className="flex shrink-0 items-center gap-2 text-xs text-muted-foreground">
          {meta}
          {link && (
            <Link to={link.to} className="inline-flex items-center gap-0.5 font-semibold text-emerald-700 hover:text-emerald-800 dark:text-emerald-300">
              {link.label}<ArrowRight className="size-3.5" />
            </Link>
          )}
        </div>
      </CardHeader>
      <CardContent className="grid gap-2">
        {state === "loading" && (
          <div className="grid gap-2" role="status" aria-label={`Đang tải ${title.toLowerCase()}`}>
            {Array.from({ length: skeletonRows }, (_, index) => <Skeleton key={index} className="h-11 w-full rounded-xl" />)}
          </div>
        )}
        {state === "error" && (
          <div role="alert" className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-destructive/30 bg-destructive/5 p-3 text-sm">
            <span className="flex items-center gap-2 text-destructive"><AlertCircle className="size-4" />{errorText ?? "Không tải được dữ liệu."}</span>
            {onRetry && <Button size="sm" variant="outline" onClick={onRetry}><RotateCw className="size-3.5" />Thử lại</Button>}
          </div>
        )}
        {state === "empty" && <div className="rounded-xl border border-dashed p-4 text-center text-sm text-muted-foreground">{empty}</div>}
        {state === "ready" && children}
      </CardContent>
    </Card>
  );
}
