import { HandCoins } from "lucide-react";

import type { LunchOrder } from "@/api/lunch.api";
import DataPagination from "@/components/common/DataPagination";
import { PaymentStatusBadge, SelectionTypeBadge } from "@/components/lunch/LunchStatus";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { usePagination } from "@/hooks/usePagination";
import { formatCurrency } from "@/lib/format";
import { isUnpaid } from "./admin-lunch-utils";

/** Orders of the active menu: table on desktop, cards on mobile. */
export default function OrdersTable({
  orders,
  confirming,
  onConfirmExternal,
}: {
  orders: LunchOrder[];
  confirming: boolean;
  onConfirmExternal: (order: LunchOrder) => void;
}) {
  const pagination = usePagination(orders);
  return (
    <>
      <Card className="hidden md:block">
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Người nhận</TableHead>
                <TableHead>Phần ăn</TableHead>
                <TableHead>Đặt bởi / trả bởi</TableHead>
                <TableHead>Thanh toán</TableHead>
                <TableHead className="text-right">Thao tác</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {pagination.paginatedItems.map((order) => (
                <TableRow key={order.id}>
                  <TableCell>
                    <div>
                      <p className="font-medium">{order.beneficiary.fullName}</p>
                      <p className="text-xs text-muted-foreground">{formatCurrency(order.price)}</p>
                    </div>
                  </TableCell>
                  <TableCell className="max-w-[360px] whitespace-normal">
                    <div className="space-y-1">
                      <SelectionTypeBadge type={order.selectionType} />
                      <p className="font-medium">{order.displayText}</p>
                      {order.note && <p className="text-xs text-muted-foreground">Ghi chú: {order.note}</p>}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">
                      <p>{order.orderedBy.fullName}</p>
                      <p className="text-xs text-muted-foreground">
                        {order.payer ? `Quỹ: ${order.payer.fullName}` : "Chưa trừ quỹ"}
                      </p>
                    </div>
                  </TableCell>
                  <TableCell>
                    <PaymentStatusBadge status={order.paymentStatus} />
                  </TableCell>
                  <TableCell className="text-right">
                    {isUnpaid(order.paymentStatus) ? (
                      <Button
                        type="button"
                        size="sm"
                        variant="outline"
                        onClick={() => onConfirmExternal(order)}
                        disabled={confirming}
                      >
                        <HandCoins aria-hidden="true" />
                        Đã thu tiền
                      </Button>
                    ) : (
                      <span className="text-xs text-muted-foreground">Đã đối soát</span>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <div className="grid gap-3 md:hidden">
        {pagination.paginatedItems.map((order) => (
          <Card key={order.id} size="sm">
            <CardContent className="space-y-3">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h3 className="font-semibold">{order.beneficiary.fullName}</h3>
                  <p className="mt-1 font-medium">{order.displayText}</p>
                  {order.note && <p className="mt-1 text-xs text-muted-foreground">Ghi chú: {order.note}</p>}
                </div>
                <PaymentStatusBadge status={order.paymentStatus} />
              </div>
              <div className="rounded-lg bg-slate-50 px-3 py-2 text-xs text-muted-foreground">
                Đặt bởi {order.orderedBy.fullName} · {order.payer ? `trừ quỹ ${order.payer.fullName}` : "chưa trừ quỹ"}
              </div>
              {isUnpaid(order.paymentStatus) && (
                <Button
                  type="button"
                  className="w-full"
                  variant="outline"
                  onClick={() => onConfirmExternal(order)}
                  disabled={confirming}
                >
                  <HandCoins aria-hidden="true" />
                  Xác nhận đã thu {formatCurrency(order.price)}
                </Button>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
      <DataPagination
        page={pagination.page}
        pageSize={pagination.pageSize}
        totalItems={pagination.totalItems}
        totalPages={pagination.totalPages}
        onPageChange={pagination.setPage}
        onPageSizeChange={pagination.setPageSize}
      />
    </>
  );
}
