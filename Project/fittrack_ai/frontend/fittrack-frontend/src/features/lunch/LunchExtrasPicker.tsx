import type { LunchMenuItem } from "@/api/lunch.api";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { formatCurrency } from "@/lib/format";

/** Chọn số lượng món thêm/đồ uống cho phần đang tạo. */
export default function LunchExtrasPicker({
  items,
  selectedIds,
  canAdd,
  busy,
  onAdd,
  onRemove,
}: {
  items: LunchMenuItem[];
  selectedIds: string[];
  canAdd: boolean;
  busy: boolean;
  onAdd: (itemId: string) => void;
  onRemove: (itemId: string) => void;
}) {
  return (
    <div className="space-y-2 rounded-xl border border-sky-200 bg-sky-50/60 p-3">
      <div>
        <Label>Món thêm / đồ uống</Label>
        <p className="mt-1 text-xs text-muted-foreground">Chọn số lượng tùy ý; giá sẽ cộng vào từng phần ăn.</p>
      </div>
      <div className="grid gap-2 sm:grid-cols-2">
        {items.map((item) => {
          const count = selectedIds.filter((id) => id === item.id).length;
          return (
            <div key={item.id} className="flex items-center justify-between gap-2 rounded-lg border bg-white px-3 py-2 text-sm">
              <div className="min-w-0"><p className="truncate font-medium">{item.name}</p><p className="text-xs text-muted-foreground">{formatCurrency(item.unitPrice ?? 0)}</p></div>
              <div className="flex items-center gap-1">
                <Button type="button" size="icon" variant="outline" className="size-7" disabled={!count || busy} onClick={() => onRemove(item.id)}>−</Button>
                <span className="w-5 text-center text-xs font-semibold">{count}</span>
                <Button type="button" size="icon" variant="outline" className="size-7" disabled={!canAdd || busy} onClick={() => onAdd(item.id)}>+</Button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
