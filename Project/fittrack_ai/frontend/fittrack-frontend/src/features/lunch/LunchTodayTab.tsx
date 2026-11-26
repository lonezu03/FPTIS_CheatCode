import { AlertTriangle, CalendarDays } from "lucide-react";

import type { LunchOrder, LunchPerson, LunchTodayResponse } from "@/api/lunch.api";
import { CutoffStatus, LunchMetric, MenuStatusBadge } from "@/components/lunch/LunchStatus";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency, formatDate } from "@/lib/format";
import LunchMenuChooser from "./LunchMenuChooser";
import LunchOrderForm from "./LunchOrderForm";
import LunchOrderSummary from "./LunchOrderSummary";
import LunchTodayOrders from "./LunchTodayOrders";
import type { LunchOrderForm as LunchOrderFormState } from "./useLunchOrderForm";

/** Tab "Hôm nay": chọn menu, tạo phần, giỏ và các phần đã đặt. */
export default function LunchTodayTab({
  today,
  todayOrders,
  form,
  people,
  peopleLoading,
  isBusy,
  ordersBusy,
  onSave,
  onSubmitCart,
  onDeleteOrder,
}: {
  today: LunchTodayResponse;
  todayOrders: LunchOrder[];
  form: LunchOrderFormState;
  people: LunchPerson[];
  peopleLoading: boolean;
  isBusy: boolean;
  ordersBusy: boolean;
  onSave: () => void;
  onSubmitCart: () => void;
  onDeleteOrder: (order: LunchOrder) => void;
}) {
  const { menu, availableMenus } = form;
  return (
    <>
      {!today.canOrder && (
        <Alert className="border-red-200 bg-red-50 text-red-900" variant="destructive">
          <AlertTriangle />
          <AlertTitle>Hiện chưa thể đặt phần mới</AlertTitle>
          <AlertDescription>
            {today.blockReason || "Vui lòng thanh toán công nợ với admin trước khi đặt phần mới."}
          </AlertDescription>
        </Alert>
      )}

      {availableMenus.length > 1 && (
        <LunchMenuChooser
          menus={availableMenus}
          selectedMenuId={menu?.id}
          disabled={isBusy || form.cartPortions.length > 0}
          onSelect={form.selectMenu}
        />
      )}

      <div className="grid gap-3 sm:grid-cols-3">
        <LunchMetric
          label={today.walletBalance < 0 ? "Số dư ròng (đang nợ)" : "Số dư quỹ của bạn"}
          value={formatCurrency(today.walletBalance)}
          hint={menu ? `Giá hôm nay: ${formatCurrency(menu.price)}` : "Chưa có menu hôm nay"}
          tone={menu && today.walletBalance < menu.price ? "warning" : "success"}
        />
        <LunchMetric
          label="Phần bạn đã đặt"
          value={todayOrders.length}
          hint={todayOrders.length > 0 ? "Bạn có thể đặt thêm phần nếu cần" : "Bạn chưa đặt phần nào"}
        />
        <LunchMetric
          label="Công nợ hiện tại"
          value={formatCurrency(today.outstandingDebt)}
          hint="có thể thanh toán bằng QR"
          tone={today.outstandingDebt > 0 ? "warning" : "default"}
        />
      </div>

      {!menu ? (
        <Card>
          <CardContent className="flex min-h-56 flex-col items-center justify-center gap-3 text-center">
            <div className="rounded-full bg-slate-100 p-4">
              <CalendarDays className="h-7 w-7 text-slate-500" aria-hidden="true" />
            </div>
            <div>
              <h2 className="font-semibold">Chưa có menu hôm nay</h2>
              <p className="mt-1 max-w-md text-sm text-muted-foreground">
                Admin chưa đăng menu. Bạn có thể quay lại sau hoặc kiểm tra lịch sử đặt cơm.
              </p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <>
          <Card className="border-orange-200 bg-gradient-to-br from-orange-50 via-white to-emerald-50">
            <CardContent className="grid gap-4 py-1 lg:grid-cols-[1fr_auto] lg:items-center">
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <MenuStatusBadge status={menu.status} acceptingOrders={menu.acceptingOrders} />
                  <span className="text-xs font-medium text-muted-foreground">{formatDate(menu.menuDate)}</span>
                </div>
                <h2 className="mt-2 text-xl font-bold tracking-tight sm:text-2xl">{menu.orderLabel}</h2>
                <p className="mt-1 text-sm text-muted-foreground">
                  {menu.vendorName} · {formatCurrency(menu.price)}/phần
                </p>
              </div>
              <CutoffStatus cutoffAt={menu.cutoffAt} acceptingOrders={menu.acceptingOrders} />
            </CardContent>
          </Card>

          <div className="grid gap-4 lg:grid-cols-[minmax(0,1.6fr)_minmax(280px,0.8fr)] lg:gap-6">
            <LunchOrderForm menu={menu} form={form} people={people} peopleLoading={peopleLoading} canOrder={today.canOrder} isBusy={isBusy} />
            <LunchOrderSummary menu={menu} form={form} people={people} canOrder={today.canOrder} isBusy={isBusy} onSave={onSave} onSubmitCart={onSubmitCart} />
          </div>

          <LunchTodayOrders
            orders={todayOrders}
            canModify={menu.acceptingOrders}
            busy={ordersBusy}
            onEdit={form.startEditing}
            onDelete={onDeleteOrder}
          />
        </>
      )}
    </>
  );
}
