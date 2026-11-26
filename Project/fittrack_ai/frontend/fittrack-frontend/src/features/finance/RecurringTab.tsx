import { Pencil, Plus } from "lucide-react";

import type { FinanceRecurring } from "@/api/finance.api";
import { useConfirm } from "@/components/common/ConfirmDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Empty, InlineError, ListSkeleton } from "./FinanceParts";
import { confirmRecurringLabel, formatDate, frequencyLabel, money, natureLabels, transactionTypeLabel } from "./finance-utils";

/** "Định kỳ" tab: reminders only; a real transaction is posted after the owner confirms. */
export default function RecurringTab({ recurring, onAdd, onEdit, onConfirmPaid, onSnooze, onArchive }: {
  recurring: { data?: FinanceRecurring[]; isLoading: boolean; isError: boolean; error: unknown };
  onAdd: () => void;
  onEdit: (item: FinanceRecurring) => void;
  onConfirmPaid: (id: string) => void;
  onSnooze: (id: string) => void;
  onArchive: (id: string) => void;
}) {
  const confirm = useConfirm();
  const active = recurring.data?.filter((item) => item.active) ?? [];
  return (
    <Card>
      <CardHeader>
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle>Khoản định kỳ sắp tới</CardTitle>
            <p className="mt-1 text-sm text-muted-foreground">
              Hệ thống chỉ nhắc. Giao dịch thật chỉ xuất hiện sau khi bạn xác nhận.
            </p>
          </div>
          <Button onClick={onAdd}>
            <Plus className="size-4" /> Thêm khoản
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        {recurring.isError ? (
          <InlineError error={recurring.error} fallback="Không tải được khoản định kỳ." />
        ) : recurring.isLoading ? (
          <ListSkeleton rows={3} itemClassName="h-24" className="space-y-3" />
        ) : !active.length ? (
          <Empty text="Chưa có khoản định kỳ." />
        ) : (
          active.map((item) => (
            <div key={item.id} className="flex flex-col gap-3 rounded-xl border p-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="font-semibold">{item.name}</p>
                <p className="text-sm text-muted-foreground">
                  {money.format(item.amount)} · hạn {formatDate(item.nextDueDate)} · {frequencyLabel(item.frequency)}
                </p>
                <div className="mt-2 flex flex-wrap gap-2">
                  <Badge variant="outline">{transactionTypeLabel(item.transactionType)}</Badge>
                  {item.expenseNature && <Badge variant="outline">{natureLabels[item.expenseNature]}</Badge>}
                </div>
              </div>
              <div className="flex flex-wrap gap-2">
                <Button onClick={() => onConfirmPaid(item.id)}>
                  {confirmRecurringLabel(item.transactionType)}
                </Button>
                <Button variant="outline" onClick={() => onEdit(item)}>
                  <Pencil className="size-4" /> Sửa
                </Button>
                <Button variant="outline" onClick={() => onSnooze(item.id)}>
                  Nhắc lại ngày mai
                </Button>
                <Button
                  variant="outline"
                  onClick={async () => { if (await confirm({ title: "Ngừng nhắc khoản định kỳ?", description: `"${item.name}" sẽ không còn được nhắc.`, confirmText: "Ngừng nhắc" })) onArchive(item.id); }}
                >
                  Ngừng
                </Button>
              </div>
            </div>
          ))
        )}
      </CardContent>
    </Card>
  );
}
