import type { LunchMenu } from "@/api/lunch.api";
import { MenuStatusBadge } from "@/components/lunch/LunchStatus";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatCurrency } from "@/lib/format";

/** Chọn một trong nhiều menu hôm nay (theo quán/điều phối viên). */
export default function LunchMenuChooser({
  menus,
  selectedMenuId,
  disabled,
  onSelect,
}: {
  menus: LunchMenu[];
  selectedMenuId?: string;
  disabled: boolean;
  onSelect: (menuId: string) => void;
}) {
  return (
    <Card className="border-emerald-200 bg-emerald-50/50">
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Chọn bộ menu / điều phối viên</CardTitle>
        <p className="text-sm text-muted-foreground">Có nhiều menu cho hôm nay. Chọn quán hoặc admin điều phối trước khi đặt.</p>
      </CardHeader>
      <CardContent className="grid gap-2 md:grid-cols-2">
        {menus.map((candidate) => (
          <button
            key={candidate.id}
            type="button"
            onClick={() => onSelect(candidate.id)}
            className={`rounded-xl border bg-white p-3 text-left transition hover:border-emerald-400 ${candidate.id === selectedMenuId ? "border-emerald-600 ring-2 ring-emerald-200" : "border-slate-200"}`}
            disabled={disabled}
          >
            <div className="flex items-center justify-between gap-2">
              <span className="font-semibold">{candidate.orderLabel}</span>
              <MenuStatusBadge status={candidate.status} acceptingOrders={candidate.acceptingOrders} />
            </div>
            <p className="mt-1 text-xs text-muted-foreground">{candidate.vendorName} · {candidate.coordinator?.fullName ?? "Điều phối viên"}</p>
            <p className="mt-1 text-sm font-medium text-emerald-800">{formatCurrency(candidate.price)}/phần</p>
          </button>
        ))}
      </CardContent>
    </Card>
  );
}
