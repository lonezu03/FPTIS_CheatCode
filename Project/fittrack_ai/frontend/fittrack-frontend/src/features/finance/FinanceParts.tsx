import type { ElementType, ReactNode } from "react";
import { CircleAlert } from "lucide-react";

import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { getApiErrorMessage } from "@/lib/format";
import { money } from "./finance-utils";

export function Field({ label, required, children, className = "" }: {
  label: string;
  required?: boolean;
  children: ReactNode;
  className?: string;
}) {
  return <div className={`space-y-2 ${className}`}><Label>{label}{required && <span className="text-rose-600"> *</span>}</Label>{children}</div>;
}

export function Hint({ children }: { children: ReactNode }) {
  return <div className="flex gap-2 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-950"><CircleAlert className="mt-0.5 size-4 shrink-0" />{children}</div>;
}

export function Metric({ title, value, detail, icon: Icon, tone }: {
  title: string;
  value: number;
  detail?: string;
  icon: ElementType;
  tone: string;
}) {
  return (
    <Card className="border-0 shadow-sm">
      <CardContent className="p-5">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0 break-words"><p className="text-sm text-muted-foreground">{title}</p><p className="mt-2 text-xl font-bold tracking-tight sm:text-2xl">{money.format(value)}</p>{detail && <p className="mt-1 text-xs text-muted-foreground">{detail}</p>}</div>
          <span className={`grid size-10 shrink-0 place-items-center rounded-xl ${tone}`}><Icon className="size-5" /></span>
        </div>
      </CardContent>
    </Card>
  );
}

export function ReportLine({ label, value, signed = false }: { label: string; value: number; signed?: boolean }) {
  return <div className="flex flex-wrap justify-between gap-x-3 gap-y-1 rounded-xl bg-muted/35 p-3"><span>{label}</span><strong className="break-words">{signed && value > 0 ? "+" : ""}{money.format(value)}</strong></div>;
}

export function InlineError({ error, fallback }: { error: unknown; fallback: string }) {
  return <div className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700">{getApiErrorMessage(error, fallback)}</div>;
}

export function Empty({ text }: { text: string }) {
  return <div className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">{text}</div>;
}

/** Placeholder rows while a list loads. */
export function ListSkeleton({ rows = 3, className = "space-y-2", itemClassName = "h-16" }: {
  rows?: number;
  className?: string;
  itemClassName?: string;
}) {
  return (
    <div role="status" aria-label="Đang tải" className={className}>
      {Array.from({ length: rows }).map((_, index) => (
        <Skeleton key={index} className={`w-full rounded-xl ${itemClassName}`} />
      ))}
    </div>
  );
}
