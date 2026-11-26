import { AlertTriangle, BellRing, CalendarDays, ClipboardList, Copy, LockKeyhole, Pencil, RotateCcw, Trash2 } from "lucide-react";

import type { LunchMenu, LunchSummary } from "@/api/lunch.api";
import EmptyState from "@/components/common/EmptyState";
import { LunchMetric, MenuStatusBadge } from "@/components/lunch/LunchStatus";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { formatCurrency, formatDate, formatDateTime } from "@/lib/format";
import { AdminEmptyState } from "./AdminLunchParts";
import { summaryButtonLabel } from "./admin-lunch-utils";

/** Status, actions and the vendor summary of the active menu. */
export default function ActiveMenuPanel({
  menu,
  summary,
  loading,
  summarizing,
  changingStatus,
  notifying,
  deleting,
  onSummarize,
  onClose,
  onReopen,
  onEdit,
  onDelete,
  onNotify,
  onCopy,
}: {
  menu: LunchMenu | null;
  summary: LunchSummary | null;
  loading: boolean;
  summarizing: boolean;
  changingStatus: boolean;
  notifying: boolean;
  deleting: boolean;
  onSummarize: () => void;
  onClose: () => void;
  onReopen: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onNotify: () => void;
  onCopy: (text: string) => Promise<void>;
}) {
  if (loading) {
    return <Skeleton className="h-64 rounded-xl" />;
  }

  if (!menu) {
    return (
      <AdminEmptyState
        icon={CalendarDays}
        title="Chưa có menu để tổng hợp"
        description="Nhập menu mới ở phía trên hoặc chọn một ngày đã có menu."
      />
    );
  }

  const canReplaceMenu = menu.canReplace === true;

  return (
    <Card>
      <CardHeader>
        <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <CardTitle>{menu.orderLabel}</CardTitle>
              <MenuStatusBadge status={menu.status} acceptingOrders={menu.acceptingOrders} />
            </div>
            <p className="mt-1 text-sm text-muted-foreground">
              {formatDate(menu.menuDate)} · {menu.vendorName} · chốt {formatDateTime(menu.cutoffAt)}
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={onEdit}
              disabled={deleting || !canReplaceMenu}
              title={canReplaceMenu ? "Sửa toàn bộ menu trước khi có đơn." : "Menu đã có đơn hoặc đã tổng hợp nên không thể thay thế."}
            >
              <Pencil aria-hidden="true" />
              Sửa menu
            </Button>
            <Button
              type="button"
              variant="outline"
              className="border-red-200 text-red-700 hover:bg-red-50 hover:text-red-800"
              onClick={onDelete}
              disabled={deleting || !canReplaceMenu}
              title={canReplaceMenu ? "Chỉ xóa được menu chưa có đơn." : "Menu đã có đơn hoặc đã tổng hợp nên không thể xóa."}
            >
              <Trash2 aria-hidden="true" />
              Xóa menu
            </Button>
            <Button
              type="button"
              variant="outline"
              onClick={onNotify}
              disabled={notifying}
            >
              <BellRing aria-hidden="true" />
              {notifying ? "Đang gửi email..." : "Thông báo menu"}
            </Button>
            {menu.acceptingOrders ? (
              <Button type="button" variant="outline" onClick={onClose} disabled={changingStatus || summarizing}>
                <LockKeyhole aria-hidden="true" />
                Chốt nhận đơn
              </Button>
            ) : !menu.summarized ? (
              <Button type="button" variant="outline" onClick={onReopen} disabled={changingStatus || summarizing}>
                <RotateCcw aria-hidden="true" />
                Mở lại
              </Button>
            ) : null}
            <Button type="button" onClick={onSummarize} disabled={summarizing || changingStatus}>
              <ClipboardList aria-hidden="true" />
              {summaryButtonLabel(summarizing, menu.summarized, Boolean(summary))}
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-5">
        <div className="grid gap-3 sm:grid-cols-3">
          <LunchMetric label="Số phần đã đặt" value={menu.totalOrders} />
          <LunchMetric label="Chưa thanh toán" value={menu.unpaidOrders} tone={menu.unpaidOrders > 0 ? "warning" : "default"} />
          <LunchMetric label="Doanh số dự kiến" value={formatCurrency(menu.totalOrders * menu.price)} />
        </div>

        {!summary ? (
          <div className="rounded-xl border border-dashed bg-slate-50 p-5 text-center">
            <ClipboardList className="mx-auto h-7 w-7 text-slate-400" aria-hidden="true" />
            <h3 className="mt-2 font-semibold">Chưa tạo bản tổng hợp</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              “Chốt & tổng hợp” sẽ đóng menu và tạo nội dung sẵn để gửi cho quán.
            </p>
          </div>
        ) : (
          <SummaryDetails summary={summary} onCopy={onCopy} />
        )}
      </CardContent>
    </Card>
  );
}

function SummaryDetails({ summary, onCopy }: { summary: LunchSummary; onCopy: (text: string) => Promise<void> }) {
  return (
    <div className="space-y-4">
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <LunchMetric label="Tổng phần" value={summary.totalOrders} />
        <LunchMetric label="Trừ quỹ" value={summary.paidFundOrders} tone="success" />
        <LunchMetric label="Thu bên ngoài" value={summary.paidExternalOrders} />
        <LunchMetric label="Chưa trả" value={summary.unpaidOrders} tone={summary.unpaidOrders > 0 ? "warning" : "default"} />
        <LunchMetric label="Tổng tiền" value={formatCurrency(summary.totalAmount)} />
      </div>

      {summary.unpaidOrders > 0 && (
        <Alert className="border-amber-200 bg-amber-50 text-amber-900">
          <AlertTriangle />
          <AlertTitle>Còn {summary.unpaidOrders} phần chưa thanh toán</AlertTitle>
          <AlertDescription className="text-amber-800">
            Danh sách món vẫn được tổng hợp đầy đủ. Hãy đối soát ở tab “Đơn hôm nay”.
          </AlertDescription>
        </Alert>
      )}

      <div className="grid gap-4 lg:grid-cols-[minmax(0,1.4fr)_minmax(250px,0.6fr)]">
        <div className="space-y-2">
          <div className="flex items-center justify-between gap-3">
            <Label htmlFor="lunch-summary-text">Nội dung gửi quán</Label>
            <Button type="button" variant="outline" size="sm" onClick={() => void onCopy(summary.orderText)}>
              <Copy aria-hidden="true" />
              Sao chép
            </Button>
          </div>
          <textarea
            id="lunch-summary-text"
            readOnly
            value={summary.orderText}
            rows={Math.min(Math.max(summary.totalOrders + 2, 8), 18)}
            onFocus={(event) => event.currentTarget.select()}
            className="w-full resize-y rounded-lg border border-input bg-slate-950 px-3 py-3 font-mono text-sm leading-6 text-slate-50 outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
          />
        </div>
        <div>
          <p className="mb-2 text-sm font-medium">Thống kê từng món</p>
          {summary.dishCounts.length === 0 ? (
            <EmptyState kind="food" title="Chưa có món nào được đặt" />
          ) : (
            <div className="space-y-2">
              {summary.dishCounts.map((dish) => (
                <div key={dish.dishName} className="flex items-center justify-between gap-3 rounded-lg bg-slate-50 px-3 py-2 text-sm">
                  <span className="font-medium">{dish.dishName}</span>
                  <Badge variant="secondary">{dish.count}</Badge>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
