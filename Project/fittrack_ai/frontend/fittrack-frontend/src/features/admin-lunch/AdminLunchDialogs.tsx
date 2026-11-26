import { AlertTriangle, Trash2 } from "lucide-react";

import type { LunchMenu, LunchOrder } from "@/api/lunch.api";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { formatCurrency, formatDate } from "@/lib/format";
import type { MenuAction } from "./admin-lunch-utils";

// These dialogs stay open with a pending label until the request finishes,
// so they are kept as dialogs rather than the fire-and-close useConfirm().

/** Close ("Chốt nhận đơn") or reopen the active menu. */
export function MenuStatusDialog({ target, pending, onCancel, onConfirm }: {
  target: MenuAction | null;
  pending: boolean;
  onCancel: () => void;
  onConfirm: (target: MenuAction) => void;
}) {
  return (
    <Dialog open={!!target} onOpenChange={(open) => !open && onCancel()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{target?.action === "close" ? "Chốt nhận đơn?" : "Mở lại menu?"}</DialogTitle>
          <DialogDescription>
            {target?.action === "close"
              ? "Nhân viên sẽ không thể tạo, sửa hoặc hủy phần ăn sau khi chốt."
              : "Nhân viên sẽ có thể tiếp tục thay đổi đơn nếu menu chưa được tổng hợp."}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onCancel} disabled={pending}>
            Quay lại
          </Button>
          <Button
            type="button"
            onClick={() => target && onConfirm(target)}
            disabled={!target || pending}
          >
            {pending
              ? "Đang xử lý..."
              : target?.action === "close"
                ? "Chốt nhận đơn"
                : "Mở lại"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

/** Delete an imported menu that has no orders yet. */
export function DeleteMenuDialog({ target, pending, onCancel, onConfirm }: {
  target: LunchMenu | null;
  pending: boolean;
  onCancel: () => void;
  onConfirm: (menuId: string) => void;
}) {
  return (
    <Dialog open={!!target} onOpenChange={(open) => !open && onCancel()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Xóa menu đã import?</DialogTitle>
          <DialogDescription>
            {target
              ? `Menu “${target.orderLabel}” ngày ${formatDate(target.menuDate)} sẽ bị xóa. Bạn chỉ nên làm việc này khi chưa có ai đặt phần.`
              : "Menu sẽ bị xóa nếu chưa phát sinh phần ăn."}
          </DialogDescription>
        </DialogHeader>
        <Alert className="border-amber-200 bg-amber-50 text-amber-900">
          <AlertTriangle />
          <AlertDescription>
            Nếu menu đã có đơn, hệ thống sẽ từ chối xóa để bảo vệ lịch sử công nợ và dinh dưỡng.
          </AlertDescription>
        </Alert>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={onCancel}
            disabled={pending}
          >
            Giữ lại menu
          </Button>
          <Button
            type="button"
            variant="destructive"
            onClick={() => target && onConfirm(target.id)}
            disabled={!target || pending}
          >
            <Trash2 aria-hidden="true" />
            {pending ? "Đang xóa..." : "Xóa menu"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

/** Record that an unpaid order was paid outside the fund. */
export function ConfirmPaymentDialog({ target, pending, onCancel, onConfirm }: {
  target: LunchOrder | null;
  pending: boolean;
  onCancel: () => void;
  onConfirm: (orderId: string) => void;
}) {
  return (
    <Dialog open={!!target} onOpenChange={(open) => !open && onCancel()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Xác nhận đã thu tiền?</DialogTitle>
          <DialogDescription>
            {target
              ? `Ghi nhận đã nhận ${formatCurrency(target.price)} bên ngoài từ ${target.beneficiary.fullName}.`
              : "Đơn sẽ được chuyển sang trạng thái đã thanh toán bên ngoài."}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={onCancel}
            disabled={pending}
          >
            Chưa nhận
          </Button>
          <Button
            type="button"
            onClick={() => target && onConfirm(target.id)}
            disabled={!target || pending}
          >
            {pending ? "Đang xác nhận..." : "Đã nhận đủ tiền"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
