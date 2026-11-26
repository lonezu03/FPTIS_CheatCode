import { CalendarDays, ClipboardList, RefreshCw } from "lucide-react";

import type { LunchMenu, LunchOrder } from "@/api/lunch.api";
import { LunchMetric, MenuStatusBadge } from "@/components/lunch/LunchStatus";
import { Button } from "@/components/ui/button";
import { formatDate } from "@/lib/format";
import { AdminEmptyState, AdminListSkeleton, AdminQueryError } from "./AdminLunchParts";
import OrdersTable from "./OrdersTable";
import { countOrderPayments } from "./admin-lunch-utils";

/** "Đơn hôm nay" tab: payment counters and the order list of the active menu. */
export default function OrdersTab({ menu, menusLoading, ordersQuery, orders, confirming, onConfirmExternal }: {
  menu: LunchMenu | null;
  menusLoading: boolean;
  ordersQuery: { isLoading: boolean; isFetching: boolean; isError: boolean; error: unknown; refetch: () => unknown };
  orders: LunchOrder[];
  confirming: boolean;
  onConfirmExternal: (order: LunchOrder) => void;
}) {
  if (!menu) {
    // While menus load there is no menu yet: show placeholders instead of "Chưa chọn menu".
    if (menusLoading) return <AdminListSkeleton />;
    return (
      <AdminEmptyState
        icon={CalendarDays}
        title="Chưa chọn menu"
        description="Nhập menu mới hoặc chọn một menu trong khoảng ngày phía trên."
      />
    );
  }

  const counts = countOrderPayments(orders);
  return (
    <>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-semibold">{menu.orderLabel}</h2>
            <MenuStatusBadge status={menu.status} acceptingOrders={menu.acceptingOrders} />
          </div>
          <p className="mt-1 text-sm text-muted-foreground">
            {formatDate(menu.menuDate)} · {menu.vendorName}
          </p>
        </div>
        <Button type="button" variant="outline" onClick={() => void ordersQuery.refetch()} disabled={ordersQuery.isFetching}>
          <RefreshCw className={ordersQuery.isFetching ? "animate-spin" : ""} aria-hidden="true" />
          Cập nhật đơn
        </Button>
      </div>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <LunchMetric label="Tổng số phần" value={counts.total} />
        <LunchMetric label="Đã trừ quỹ" value={counts.fund} tone="success" />
        <LunchMetric label="Đã thu bên ngoài" value={counts.external} />
        <LunchMetric label="Chưa thanh toán" value={counts.unpaid} tone={counts.unpaid > 0 ? "warning" : "default"} />
      </div>

      {ordersQuery.isLoading ? (
        <AdminListSkeleton />
      ) : ordersQuery.isError ? (
        <AdminQueryError
          title="Không tải được danh sách đơn"
          error={ordersQuery.error}
          onRetry={() => void ordersQuery.refetch()}
        />
      ) : orders.length === 0 ? (
        <AdminEmptyState
          icon={ClipboardList}
          title="Chưa có ai đặt"
          description="Danh sách sẽ tự cập nhật khi nhân viên bắt đầu chọn món."
        />
      ) : (
        <OrdersTable
          orders={orders}
          confirming={confirming}
          onConfirmExternal={onConfirmExternal}
        />
      )}
    </>
  );
}
