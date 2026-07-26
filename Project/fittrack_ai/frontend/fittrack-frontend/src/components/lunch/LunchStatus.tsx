import { useEffect, useState } from "react";
import { AlertCircle, CheckCircle2, Clock3, LockKeyhole, UtensilsCrossed } from "lucide-react";

import type { LunchPaymentStatus, LunchSelectionType } from "@/api/lunch.api";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { formatDateTime, getCutoffDistance } from "@/lib/format";

export function PaymentStatusBadge({ status }: { status: LunchPaymentStatus }) {
  const normalized = status.toUpperCase();

  if (normalized.includes("EXTERNAL")) {
    return (
      <Badge className="border-emerald-200 bg-emerald-50 text-emerald-700" variant="outline">
        <CheckCircle2 aria-hidden="true" />
        Đã thu bên ngoài
      </Badge>
    );
  }

  if (normalized.includes("FUND") || normalized.includes("WALLET")) {
    return (
      <Badge className="border-sky-200 bg-sky-50 text-sky-700" variant="outline">
        <CheckCircle2 aria-hidden="true" />
        Đã trừ quỹ
      </Badge>
    );
  }

  return (
    <Badge className="border-amber-200 bg-amber-50 text-amber-800" variant="outline">
      <AlertCircle aria-hidden="true" />
      Chưa thanh toán
    </Badge>
  );
}

export function MenuStatusBadge({
  status,
  acceptingOrders,
}: {
  status: string;
  acceptingOrders: boolean;
}) {
  if (acceptingOrders) {
    return (
      <Badge className="border-emerald-200 bg-emerald-50 text-emerald-700" variant="outline">
        <CheckCircle2 aria-hidden="true" />
        Đang nhận đơn
      </Badge>
    );
  }

  return (
    <Badge className="border-slate-200 bg-slate-100 text-slate-700" variant="outline">
      <LockKeyhole aria-hidden="true" />
      {status.toUpperCase().includes("CLOSE") ? "Đã chốt" : status}
    </Badge>
  );
}

export function SelectionTypeBadge({ type }: { type: LunchSelectionType }) {
  return (
    <Badge variant="secondary">
      <UtensilsCrossed aria-hidden="true" />
      {type === "COMBO" ? "Cơm 2 món" : "Món đơn"}
    </Badge>
  );
}

export function CutoffStatus({
  cutoffAt,
  acceptingOrders,
  className,
}: {
  cutoffAt: string;
  acceptingOrders: boolean;
  className?: string;
}) {
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  const distance = getCutoffDistance(cutoffAt, now);
  const closed = !acceptingOrders || distance.closed;

  return (
    <div
      className={cn(
        "flex items-center gap-2 rounded-xl border px-3 py-2 text-sm",
        closed
          ? "border-slate-200 bg-slate-50 text-slate-700"
          : "border-orange-200 bg-orange-50 text-orange-800",
        className
      )}
    >
      {closed ? <LockKeyhole className="h-4 w-4" aria-hidden="true" /> : <Clock3 className="h-4 w-4" aria-hidden="true" />}
      <div>
        <p className="font-medium">{closed ? "Đã ngừng nhận đơn" : distance.label}</p>
        <p className="text-xs opacity-80">Chốt lúc {formatDateTime(cutoffAt)}</p>
      </div>
    </div>
  );
}

export function LunchMetric({
  label,
  value,
  hint,
  tone = "default",
}: {
  label: string;
  value: string | number;
  hint?: string;
  tone?: "default" | "success" | "warning";
}) {
  return (
    <div
      className={cn(
        "rounded-xl border p-3 sm:p-4",
        tone === "success" && "border-emerald-200 bg-emerald-50/70",
        tone === "warning" && "border-amber-200 bg-amber-50/70",
        tone === "default" && "bg-card"
      )}
    >
      <p className="text-xs font-medium text-muted-foreground">{label}</p>
      <p className="mt-1 text-xl font-bold tracking-tight">{value}</p>
      {hint && <p className="mt-1 text-xs text-muted-foreground">{hint}</p>}
    </div>
  );
}
