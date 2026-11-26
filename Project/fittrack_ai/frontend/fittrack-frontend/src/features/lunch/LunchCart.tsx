import { CirclePlus, ShoppingCart, Trash2 } from "lucide-react";

import type { LunchMenu, LunchPerson } from "@/api/lunch.api";
import { Button } from "@/components/ui/button";
import { formatCurrency } from "@/lib/format";
import { describeCartPortion, selectionTypeLabel, type CartPortion } from "./lunch-utils";

/** Giỏ đặt cơm: các phần chờ đặt và nút đặt tất cả. */
export default function LunchCart({
  menu,
  people,
  portions,
  total,
  canSubmit,
  isBusy,
  onRemove,
  onSubmit,
}: {
  menu: LunchMenu;
  people: LunchPerson[];
  portions: CartPortion[];
  total: number;
  canSubmit: boolean;
  isBusy: boolean;
  onRemove: (portionId: string) => void;
  onSubmit: () => void;
}) {
  return (
    <div className="space-y-3 rounded-xl border border-emerald-200 bg-emerald-50/50 p-3">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <ShoppingCart className="size-4 text-emerald-700" aria-hidden="true" />
          <p className="text-sm font-semibold">Giỏ đặt cơm</p>
        </div>
        <span className="rounded-full bg-white px-2 py-0.5 text-xs font-semibold text-emerald-800">
          {portions.length} phần
        </span>
      </div>

      {portions.length === 0 ? (
        <p className="rounded-lg border border-dashed border-emerald-200 bg-white/70 p-3 text-xs text-muted-foreground">
          Chưa có phần nào trong giỏ. Chọn món rồi bấm “Thêm phần vào giỏ”.
        </p>
      ) : (
        <ul className="space-y-2">
          {portions.map((portion, index) => {
            const { recipient, dishes } = describeCartPortion(menu, people, portion);
            return (
              <li key={portion.id} className="flex gap-2 rounded-lg border bg-white p-2.5">
                <span className="flex size-6 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-xs font-bold text-emerald-800">
                  {index + 1}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-xs font-semibold">{recipient} · {selectionTypeLabel(portion.selectionType)}</p>
                  <p className="mt-0.5 truncate text-xs text-muted-foreground">{dishes}</p>
                  {portion.note && <p className="mt-0.5 text-[11px] text-muted-foreground">Ghi chú: {portion.note}</p>}
                </div>
                <Button
                  type="button"
                  size="icon"
                  variant="ghost"
                  className="size-7 text-red-600 hover:text-red-700"
                  aria-label={`Bỏ phần ${index + 1} khỏi giỏ`}
                  onClick={() => onRemove(portion.id)}
                  disabled={isBusy}
                >
                  <Trash2 className="size-4" />
                </Button>
              </li>
            );
          })}
        </ul>
      )}

      <div className="flex items-center justify-between text-sm">
        <span className="text-muted-foreground">Tạm tính</span>
        <strong>{formatCurrency(total)}</strong>
      </div>
      <Button
        type="button"
        className="w-full"
        size="lg"
        onClick={onSubmit}
        disabled={portions.length === 0 || !canSubmit || isBusy}
      >
        <CirclePlus aria-hidden="true" />
        {isBusy ? "Đang gửi đơn..." : `Đặt ${portions.length} phần · ${formatCurrency(total)}`}
      </Button>
    </div>
  );
}
