import type { LunchOrder } from "@/api/lunch.api";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

/** Xác nhận hủy một phần ăn hôm nay. */
export default function LunchDeleteOrderDialog({
  target,
  pending,
  onClose,
  onConfirm,
}: {
  target: LunchOrder | null;
  pending: boolean;
  onClose: () => void;
  onConfirm: (order: LunchOrder) => void;
}) {
  return (
    <Dialog open={!!target} onOpenChange={(open) => !open && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Hủy phần ăn?</DialogTitle>
          <DialogDescription>
            {target
              ? `Phần “${target.displayText}” của ${target.beneficiary.fullName} sẽ bị hủy.`
              : "Phần ăn sẽ bị hủy."}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Giữ lại
          </Button>
          <Button
            type="button"
            variant="destructive"
            onClick={() => target && onConfirm(target)}
            disabled={!target || pending}
          >
            {pending ? "Đang hủy..." : "Xác nhận hủy"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
