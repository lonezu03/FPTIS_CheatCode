import { Pencil, Plus, Trash2 } from "lucide-react";

import type { FinanceBudget } from "@/api/finance.api";
import { useConfirm } from "@/components/common/ConfirmDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Empty, InlineError, ListSkeleton } from "./FinanceParts";
import { budgetLevel, money } from "./finance-utils";

/** "Ngân sách" tab: monthly limits per category with 80% / 100% warnings. */
export default function BudgetsTab({ budgets, onAdd, onEdit, onDelete }: {
  budgets: { data?: FinanceBudget[]; isLoading: boolean; isError: boolean; error: unknown };
  onAdd: () => void;
  onEdit: (budget: FinanceBudget) => void;
  onDelete: (id: string) => void;
}) {
  const confirm = useConfirm();
  return (
    <Card>
      <CardHeader>
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle>Ngân sách theo danh mục</CardTitle>
            <p className="mt-1 text-sm text-muted-foreground">Cảnh báo một lần khi chạm 80% và 100% hạn mức.</p>
          </div>
          <Button onClick={onAdd}>
            <Plus className="size-4" /> Thêm ngân sách
          </Button>
        </div>
      </CardHeader>
      <CardContent className="grid gap-3 md:grid-cols-2">
        {budgets.isError ? (
          <InlineError error={budgets.error} fallback="Không tải được ngân sách." />
        ) : budgets.isLoading ? (
          <ListSkeleton rows={2} className="grid gap-3 md:col-span-2 md:grid-cols-2" itemClassName="h-28" />
        ) : !budgets.data?.length ? (
          <Empty text="Chưa đặt ngân sách cho tháng này." />
        ) : (
          budgets.data.map((budget) => {
            const level = budgetLevel(budget.percent);
            return (
              <div
                key={budget.id}
                className={`rounded-xl border p-4 ${
                  level === "over"
                    ? "border-rose-300 bg-rose-50/50"
                    : level === "warning"
                      ? "border-amber-300 bg-amber-50/50"
                      : ""
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <strong>{budget.categoryName}</strong>
                    {level === "over" && <Badge className="ml-2 bg-rose-100 text-rose-700">Đã vượt hạn mức</Badge>}
                    {level === "warning" && <Badge className="ml-2 bg-amber-100 text-amber-800">Sắp hết</Badge>}
                  </div>
                  <div className="flex gap-1">
                    <Button size="icon-sm" variant="ghost" aria-label="Sửa ngân sách" onClick={() => onEdit(budget)}>
                      <Pencil className="size-4" />
                    </Button>
                    <Button
                      size="icon-sm"
                      variant="ghost"
                      aria-label="Xóa ngân sách"
                      onClick={async () => { if (await confirm({ title: "Xóa ngân sách?", description: `Ngân sách ${budget.categoryName} của tháng này sẽ bị xóa.`, confirmText: "Xóa", destructive: true })) onDelete(budget.id); }}
                    >
                      <Trash2 className="size-4 text-rose-600" />
                    </Button>
                  </div>
                </div>
                <p className="mt-1 text-sm">{money.format(budget.spent)} / {money.format(budget.amount)}</p>
                <Progress className="mt-3" value={Math.min(100, budget.percent)} />
                <p className="mt-2 text-xs text-muted-foreground">
                  Còn {money.format(Math.max(0, budget.remaining))} · dự kiến cuối tháng {money.format(budget.projected)} {budget.projectedOver ? "⚠" : ""}
                </p>
              </div>
            );
          })
        )}
      </CardContent>
    </Card>
  );
}
