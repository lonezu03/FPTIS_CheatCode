import type { LunchOrder } from "@/api/lunch.api";
import EmptyState from "@/components/common/EmptyState";
import LunchOrderCard from "@/components/lunch/LunchOrderCard";

/** Các phần hôm nay của tôi và phần tôi đặt hộ. */
export default function LunchTodayOrders({
  orders,
  canModify,
  busy,
  onEdit,
  onDelete,
}: {
  orders: LunchOrder[];
  canModify: boolean;
  busy: boolean;
  onEdit: (order: LunchOrder) => void;
  onDelete: (order: LunchOrder) => void;
}) {
  return (
    <section className="space-y-3" aria-labelledby="today-orders-heading">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 id="today-orders-heading" className="text-lg font-semibold">
            Các phần bạn phụ trách hôm nay
          </h2>
          <p className="text-xs text-muted-foreground">Gồm phần của bạn và các phần đặt hộ.</p>
        </div>
        <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold">{orders.length} phần</span>
      </div>

      {orders.length === 0 ? (
        <EmptyState kind="food" title="Bạn chưa đặt phần ăn nào hôm nay" />
      ) : (
        <div className="grid gap-3 lg:grid-cols-2">
          {orders.map((order) => (
            <LunchOrderCard
              key={order.id}
              order={order}
              canModify={canModify}
              busy={busy}
              onEdit={onEdit}
              onDelete={onDelete}
            />
          ))}
        </div>
      )}
    </section>
  );
}
