import { AlertTriangle, UserRound } from "lucide-react";

import type { LunchMenu, LunchPerson } from "@/api/lunch.api";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatCurrency } from "@/lib/format";
import LunchCart from "./LunchCart";
import { SummaryRow } from "./lunch-ui";
import { selectionTypeLabel } from "./lunch-utils";
import type { LunchOrderForm } from "./useLunchOrderForm";

function saveLabel(form: LunchOrderForm, isBusy: boolean) {
  if (isBusy) return "Đang lưu...";
  if (form.editingOrder) return "Lưu thay đổi";
  if (form.insufficientBalance && !form.beneficiaryUserId) return "Thêm phần vào giỏ (ghi nợ)";
  return form.beneficiaryUserId ? "Thêm phần đặt hộ vào giỏ" : "Thêm phần vào giỏ";
}

/** Thẻ "Phần đang tạo": tóm tắt giá, món, dinh dưỡng, cảnh báo quỹ và giỏ. */
export default function LunchOrderSummary({
  menu,
  form,
  people,
  canOrder,
  isBusy,
  onSave,
  onSubmitCart,
}: {
  menu: LunchMenu;
  form: LunchOrderForm;
  people: LunchPerson[];
  canOrder: boolean;
  isBusy: boolean;
  onSave: () => void;
  onSubmitCart: () => void;
}) {
  const { editingOrder, selectedItems, selectedNutrition, beneficiaryUserId } = form;
  const open = menu.acceptingOrders && canOrder;
  return (
    <Card className="h-fit lg:sticky lg:top-6">
      <CardHeader>
        <CardTitle>{editingOrder ? "Xác nhận chỉnh sửa" : "Phần đang tạo"}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2 rounded-xl bg-slate-50 p-3">
          <SummaryRow label="Người nhận" value={editingOrder?.beneficiary.fullName ?? form.selectedBeneficiary?.fullName ?? "Tôi"} />
          <SummaryRow label="Loại phần" value={selectionTypeLabel(form.selectionType)} />
          <SummaryRow label="Đơn giá cơ bản" value={formatCurrency(menu.price)} />
          <SummaryRow label="Món thêm" value={formatCurrency(form.extrasTotal)} />
          <SummaryRow label="Tổng phần này" value={formatCurrency(form.currentPortionTotal)} strong />
        </div>

        <div>
          <p className="mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">Món đã chọn</p>
          {selectedItems.length === 0 ? (
            <p className="rounded-xl border border-dashed p-3 text-sm text-muted-foreground">
              Chưa chọn món.
            </p>
          ) : (
            <ul className="space-y-2">
              {selectedItems.map((item, index) => (
                <li key={`${item.id}-${index}`} className="flex items-start gap-2 rounded-lg border bg-white px-3 py-2 text-sm">
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-slate-900 text-[11px] font-semibold text-white">
                    {index + 1}
                  </span>
                  <span className="font-medium">{item.name}</span>
                </li>
              ))}
            </ul>
          )}
        </div>

        {selectedItems.length > 0 && (
          <div className="grid grid-cols-2 gap-2 rounded-xl bg-emerald-50 p-3 text-xs sm:grid-cols-4">
            <SummaryRow label="Calo" value={`${Math.round(selectedNutrition.calories)} kcal`} />
            <SummaryRow label="Protein" value={`${selectedNutrition.protein.toFixed(1)}g`} />
            <SummaryRow label="Carb" value={`${selectedNutrition.carbs.toFixed(1)}g`} />
            <SummaryRow label="Fat" value={`${selectedNutrition.fat.toFixed(1)}g`} />
          </div>
        )}

        {form.insufficientBalance && !editingOrder && (
          <Alert className="border-amber-200 bg-amber-50 text-amber-900">
            <AlertTriangle />
            <AlertTitle>Quỹ hiện không đủ</AlertTitle>
            <AlertDescription className="text-amber-800">
              Bạn vẫn có thể tự đặt. Hệ thống sẽ dùng hết số dư còn lại và ghi phần thiếu vào công nợ của bạn.
            </AlertDescription>
          </Alert>
        )}

        {!!beneficiaryUserId && !editingOrder && (
          <Alert className="border-sky-200 bg-sky-50 text-sky-900">
            <UserRound />
            <AlertTitle>Chi phí tính cho người nhận</AlertTitle>
            <AlertDescription className="text-sky-800">
              {formatCurrency(form.currentPortionTotal)} sẽ được trừ từ quỹ của {form.selectedBeneficiary?.fullName ?? "người nhận"}; phần thiếu sẽ được ghi vào công nợ của người đó.
            </AlertDescription>
          </Alert>
        )}

        <div className="flex flex-col gap-2">
          <Button
            type="button"
            size="lg"
            className="w-full"
            onClick={onSave}
            disabled={!open || isBusy || !form.itemsReady}
          >
            {saveLabel(form, isBusy)}
          </Button>
          {editingOrder && (
            <Button type="button" variant="ghost" onClick={form.resetOrderForm} disabled={isBusy}>
              Bỏ chỉnh sửa
            </Button>
          )}
        </div>

        {!editingOrder && (
          <LunchCart
            menu={menu}
            people={people}
            portions={form.cartPortions}
            total={form.cartTotal}
            canSubmit={open}
            isBusy={isBusy}
            onRemove={form.removeCartPortion}
            onSubmit={onSubmitCart}
          />
        )}
      </CardContent>
    </Card>
  );
}
