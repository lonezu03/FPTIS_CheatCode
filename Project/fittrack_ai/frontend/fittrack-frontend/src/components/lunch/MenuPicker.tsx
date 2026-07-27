import { Check, Soup, UtensilsCrossed } from "lucide-react";

import type { LunchMenu, LunchSelectionType } from "@/api/lunch.api";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import ImagePreviewDialog from "@/components/common/ImagePreviewDialog";

type MenuPickerProps = {
  menu: LunchMenu;
  selectionType: LunchSelectionType;
  selectedItemIds: string[];
  disabled?: boolean;
  onTypeChange: (type: LunchSelectionType) => void;
  onItemsChange: (itemIds: string[]) => void;
};

export default function MenuPicker({
  menu,
  selectionType,
  selectedItemIds,
  disabled = false,
  onTypeChange,
  onItemsChange,
}: MenuPickerProps) {
  const requiredCount = selectionType === "COMBO" ? 2 : 1;
  const items = selectionType === "COMBO" ? menu.regularItems : menu.specialItems;

  const toggleItem = (itemId: string) => {
    if (disabled) {
      return;
    }

    if (selectedItemIds.includes(itemId)) {
      onItemsChange(selectedItemIds.filter((id) => id !== itemId));
      return;
    }

    if (selectionType === "SINGLE") {
      onItemsChange([itemId]);
      return;
    }

    if (selectedItemIds.length < requiredCount) {
      onItemsChange([...selectedItemIds, itemId]);
    }
  };

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-2 rounded-xl bg-slate-100 p-1" role="radiogroup" aria-label="Loại phần ăn">
        <Button
          type="button"
          variant="ghost"
          role="radio"
          aria-checked={selectionType === "COMBO"}
          className={cn(
            "h-auto min-h-12 justify-start px-3 py-2 text-left",
            selectionType === "COMBO" && "bg-white shadow-sm hover:bg-white"
          )}
          disabled={disabled || menu.regularItems.length < 2}
          onClick={() => {
            onTypeChange("COMBO");
            onItemsChange([]);
          }}
        >
          <UtensilsCrossed className="h-4 w-4" aria-hidden="true" />
          <span>
            <span className="block font-semibold">Cơm 2 món</span>
            <span className="block text-[11px] font-normal text-muted-foreground">Chọn đúng hai món</span>
          </span>
        </Button>

        <Button
          type="button"
          variant="ghost"
          role="radio"
          aria-checked={selectionType === "SINGLE"}
          className={cn(
            "h-auto min-h-12 justify-start px-3 py-2 text-left",
            selectionType === "SINGLE" && "bg-white shadow-sm hover:bg-white"
          )}
          disabled={disabled || menu.specialItems.length === 0}
          onClick={() => {
            onTypeChange("SINGLE");
            onItemsChange([]);
          }}
        >
          <Soup className="h-4 w-4" aria-hidden="true" />
          <span>
            <span className="block font-semibold">Món đơn</span>
            <span className="block text-[11px] font-normal text-muted-foreground">Chọn một món</span>
          </span>
        </Button>
      </div>

      <div className="flex items-center justify-between gap-3">
        <div>
          <h3 className="font-semibold">{selectionType === "COMBO" ? "Chọn món cho phần cơm" : "Chọn món đơn"}</h3>
          <p className="text-xs text-muted-foreground">
            {selectionType === "COMBO"
              ? "Nhấn lại món đã chọn để bỏ chọn."
              : "Món mới sẽ thay món đang chọn."}
          </p>
        </div>
        <span
          className={cn(
            "shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold",
            selectedItemIds.length === requiredCount
              ? "bg-emerald-100 text-emerald-700"
              : "bg-amber-100 text-amber-800"
          )}
          aria-live="polite"
        >
          {selectedItemIds.length}/{requiredCount} món
        </span>
      </div>

      {items.length === 0 ? (
        <div className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">
          Hôm nay không có món trong nhóm này.
        </div>
      ) : (
        <div className="grid gap-2 sm:grid-cols-2">
          {items.map((item) => {
            const selected = selectedItemIds.includes(item.id);
            const maxReached = selectionType === "COMBO" && selectedItemIds.length >= requiredCount && !selected;

            return (
              <div
                key={item.id}
                className={cn(
                  "group flex min-h-16 items-center gap-3 rounded-xl border bg-white p-2 text-left text-sm transition",
                  selected
                    ? "border-emerald-400 bg-emerald-50 text-emerald-950 shadow-sm"
                    : "border-slate-200 hover:border-slate-300 hover:bg-slate-50",
                  (disabled || maxReached) && "cursor-not-allowed opacity-50"
                )}
              >
                {item.imageUrl && (
                  <ImagePreviewDialog
                    src={item.imageUrl}
                    alt={item.name}
                    className="size-14 shrink-0"
                  />
                )}
                <button
                  type="button"
                  aria-pressed={selected}
                  disabled={disabled || maxReached}
                  onClick={() => toggleItem(item.id)}
                  className="flex min-w-0 flex-1 items-center gap-3 rounded-lg px-1 py-1 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400"
                >
                  <span
                    className={cn(
                      "flex h-5 w-5 shrink-0 items-center justify-center rounded-full border",
                      selected ? "border-emerald-600 bg-emerald-600 text-white" : "border-slate-300 bg-white"
                    )}
                  >
                    {selected && <Check className="h-3.5 w-3.5" strokeWidth={3} aria-hidden="true" />}
                  </span>
                  <span className="min-w-0">
                    <span className="block truncate font-medium">{item.name}</span>
                    <span className="mt-0.5 block text-[11px] text-muted-foreground">
                      {item.calories ? `${Math.round(item.calories)} kcal` : "Chưa cập nhật calo"}
                      {item.reviewCount > 0 ? ` · ★ ${item.averageRating} (${item.reviewCount})` : ""}
                    </span>
                  </span>
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
