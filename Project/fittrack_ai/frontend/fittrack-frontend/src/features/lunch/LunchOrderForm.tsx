import { ShoppingCart, UserRound } from "lucide-react";

import type { LunchMenu, LunchPerson } from "@/api/lunch.api";
import MenuPicker from "@/components/lunch/MenuPicker";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import LunchExtrasPicker from "./LunchExtrasPicker";
import { NOTE_SUGGESTIONS, noteHasSuggestion } from "./lunch-utils";
import type { LunchOrderForm as LunchOrderFormState } from "./useLunchOrderForm";

/** Thẻ "Tạo phần ăn": người nhận, món, món thêm và ghi chú. */
export default function LunchOrderForm({
  menu,
  form,
  people,
  peopleLoading,
  canOrder,
  isBusy,
}: {
  menu: LunchMenu;
  form: LunchOrderFormState;
  people: LunchPerson[];
  peopleLoading: boolean;
  canOrder: boolean;
  isBusy: boolean;
}) {
  const open = menu.acceptingOrders && canOrder;
  const { editingOrder, note } = form;
  return (
    <Card>
      <CardHeader>
        <CardTitle>{editingOrder ? `Sửa phần của ${editingOrder.beneficiary.fullName}` : "Tạo phần ăn"}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-5">
        {!editingOrder && (
          <Alert className="border-emerald-200 bg-emerald-50/70 text-emerald-950">
            <ShoppingCart />
            <AlertTitle>Mỗi phần cơm chọn đúng 2 món</AlertTitle>
            <AlertDescription>
              Thêm từng phần vào giỏ, sau đó đặt tất cả cùng lúc. Bạn có thể tạo nhiều phần cho mình hoặc đặt hộ đồng nghiệp.
            </AlertDescription>
          </Alert>
        )}
        {!editingOrder && (
          <div className="space-y-2">
            <Label htmlFor="lunch-beneficiary">Người nhận phần ăn</Label>
            <div className="relative">
              <UserRound
                className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
                aria-hidden="true"
              />
              <select
                id="lunch-beneficiary"
                value={form.beneficiaryUserId}
                onChange={(event) => form.setBeneficiaryUserId(event.target.value)}
                disabled={!open || peopleLoading}
                className="h-10 w-full appearance-none rounded-lg border border-input bg-background py-2 pl-9 pr-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50"
              >
                <option value="">Tôi — đặt cho bản thân</option>
                {people.map((person) => (
                  <option key={person.id} value={person.id}>
                    {person.fullName} — đặt hộ
                  </option>
                ))}
              </select>
            </div>
            <p className="text-xs text-muted-foreground">
              Chi phí sẽ được trừ từ quỹ của người nhận; nếu quỹ không đủ, hệ thống ghi công nợ cho người nhận.
            </p>
          </div>
        )}

        <MenuPicker
          menu={menu}
          selectionType={form.selectionType}
          selectedItemIds={form.selectedItemIds}
          disabled={!open || isBusy}
          onTypeChange={form.setSelectionType}
          onItemsChange={form.setSelectedItemIds}
        />

        {(menu.extraItems?.length ?? 0) > 0 && (
          <LunchExtrasPicker
            items={menu.extraItems ?? []}
            selectedIds={form.selectedExtraItemIds}
            canAdd={open}
            busy={isBusy}
            onAdd={form.addExtra}
            onRemove={form.removeExtra}
          />
        )}

        <div className="space-y-2">
          <Label htmlFor="lunch-note">Ghi chú cho quán</Label>
          <div className="flex flex-wrap gap-2">
            {NOTE_SUGGESTIONS.map((suggestion) => {
              const selected = noteHasSuggestion(note, suggestion);
              return (
                <Button
                  key={suggestion}
                  type="button"
                  size="sm"
                  variant={selected ? "secondary" : "outline"}
                  onClick={() => form.toggleNoteSuggestion(suggestion)}
                  disabled={!open}
                >
                  {selected ? "✓ " : "+ "}
                  {suggestion}
                </Button>
              );
            })}
          </div>
          <textarea
            id="lunch-note"
            value={note}
            onChange={(event) => form.setNote(event.target.value)}
            maxLength={300}
            rows={3}
            disabled={!open}
            placeholder="Ví dụ: ít cơm, không lấy hành..."
            className="w-full resize-y rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50"
          />
          <p className="text-right text-[11px] text-muted-foreground">{note.length}/300</p>
        </div>
      </CardContent>
    </Card>
  );
}
