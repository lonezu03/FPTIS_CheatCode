import { CalendarDays, MessageSquareText, Pencil, Trash2, UserRound } from "lucide-react";

import type { LunchOrder } from "@/api/lunch.api";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency, formatShortDate } from "@/lib/format";
import { PaymentStatusBadge, SelectionTypeBadge } from "./LunchStatus";
import ImagePreviewDialog from "@/components/common/ImagePreviewDialog";

type LunchOrderCardProps = {
  order: LunchOrder;
  canModify?: boolean;
  busy?: boolean;
  onEdit?: (order: LunchOrder) => void;
  onDelete?: (order: LunchOrder) => void;
  onReview?: (order: LunchOrder) => void;
};

export default function LunchOrderCard({
  order,
  canModify = false,
  busy = false,
  onEdit,
  onDelete,
  onReview,
}: LunchOrderCardProps) {
  const payerName = order.payer?.fullName;
  const orderedForAnotherPerson = order.orderedBy.id !== order.beneficiary.id;

  return (
    <Card size="sm" className={order.status.toUpperCase() === "CANCELLED" ? "opacity-60" : ""}>
      <CardContent className="space-y-3">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0">
            <div className="flex flex-wrap items-center gap-2">
              <h3 className="truncate font-semibold">{order.beneficiary.fullName}</h3>
              <SelectionTypeBadge type={order.selectionType} />
            </div>
            <p className="mt-1 font-medium text-slate-800">{order.displayText}</p>
            {order.note && <p className="mt-1 text-xs text-muted-foreground">Ghi chú: {order.note}</p>}
          </div>
          <PaymentStatusBadge status={order.paymentStatus} />
        </div>

        <div className="grid gap-2 text-xs text-muted-foreground sm:grid-cols-3">
          <span className="flex items-center gap-1.5">
            <CalendarDays className="h-3.5 w-3.5" aria-hidden="true" />
            {formatShortDate(order.menuDate)}
          </span>
          <span className="flex items-center gap-1.5">
            <UserRound className="h-3.5 w-3.5" aria-hidden="true" />
            {orderedForAnotherPerson ? `Đặt bởi ${order.orderedBy.fullName}` : "Tự đặt"}
          </span>
          <span className="font-semibold text-foreground">{formatCurrency(order.price)}</span>
        </div>

        {order.items.some((item) => item.imageUrl) && (
          <div className="flex gap-2 overflow-x-auto">
            {order.items.filter((item) => item.imageUrl).map((item, index) => (
              <ImagePreviewDialog
                key={`${item.id}-${index}`}
                src={item.imageUrl}
                alt={item.name}
                className="h-16 w-24 shrink-0"
              />
            ))}
          </div>
        )}

        {orderedForAnotherPerson && (
          <p className="rounded-lg bg-sky-50 px-2.5 py-2 text-xs text-sky-800">
            {payerName === order.beneficiary.fullName
              ? "Chi phí được tính vào quỹ hoặc công nợ của người nhận."
              : `Đơn cũ: quỹ được trừ từ tài khoản của ${payerName ?? "người đặt"}.`}
          </p>
        )}

        {canModify && (onEdit || onDelete) && (
          <div className="flex gap-2 border-t pt-3">
            {onEdit && (
              <Button type="button" variant="outline" size="sm" onClick={() => onEdit(order)} disabled={busy}>
                <Pencil aria-hidden="true" />
                Sửa món
              </Button>
            )}
            {onDelete && (
              <Button type="button" variant="destructive" size="sm" onClick={() => onDelete(order)} disabled={busy}>
                <Trash2 aria-hidden="true" />
                Hủy phần
              </Button>
            )}
          </div>
        )}

        {onReview && order.status.toUpperCase() === "ACTIVE" && (
          <div className="border-t pt-3">
            <Button type="button" variant="outline" size="sm" onClick={() => onReview(order)}>
              <MessageSquareText aria-hidden="true" />
              {order.reviews?.length ? "Sửa đánh giá" : "Đánh giá món"}
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
