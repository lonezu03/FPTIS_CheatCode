import { Plus } from "lucide-react";

import type { FinanceAccount, FinanceDashboard, FinanceReport } from "@/api/finance.api";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Empty, InlineError, ReportLine } from "./FinanceParts";
import { accountTypeLabel, budgetLevel, formatDate, frequencyLabel, money, natureLabels } from "./finance-utils";

/** "Tổng quan" tab: accounts, top categories, natures, month report, budgets, upcoming. */
export default function OverviewTab({ data, activeAccounts, report, onReconcile, onAddAccount }: {
  data: FinanceDashboard;
  activeAccounts: FinanceAccount[];
  report: { data?: FinanceReport; isError: boolean; error: unknown };
  onReconcile: (account: FinanceAccount) => void;
  onAddAccount: () => void;
}) {
  return (
    <>
      <Card>
        <CardHeader><CardTitle>Tài khoản</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          {activeAccounts.length === 0 ? (
            <Empty text="Tạo tài khoản tiền đầu tiên để bắt đầu." />
          ) : (
            activeAccounts.map((account) => (
              <div key={account.id} className="flex min-w-0 flex-col gap-2 rounded-xl border p-3 sm:flex-row sm:items-center sm:justify-between">
                <div className="min-w-0 break-words">
                  <p className="font-semibold">{account.name}</p>
                  <p className="text-xs text-muted-foreground">{accountTypeLabel(account.accountType)}</p>
                </div>
                <p className="break-words font-bold">{money.format(account.currentBalance)}</p>
                <Button variant="outline" size="sm" onClick={() => onReconcile(account)}>Đối soát</Button>
              </div>
            ))
          )}
          <Button variant="outline" className="w-full" onClick={onAddAccount}>
            <Plus className="size-4" /> Thêm tài khoản
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>Tiền đi đâu?</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          {data.topCategories.length === 0 ? (
            <Empty text="Chưa có giao dịch chi tiêu trong tháng." />
          ) : (
            data.topCategories.map((item) => (
              <div key={item.categoryId}>
                <div className="mb-1 flex justify-between gap-3 text-sm">
                  <span>{item.categoryName}</span>
                  <strong>{money.format(item.amount)}</strong>
                </div>
                <Progress value={data.expense ? Math.min(100, (item.amount / data.expense) * 100) : 0} />
              </div>
            ))
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>5 nhóm tính chất khoản chi</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          {data.natureBreakdown.length === 0 ? (
            <Empty text="Chưa đủ dữ liệu phân loại." />
          ) : (
            data.natureBreakdown.map((item) => (
              <div key={item.expenseNature} className="flex items-center justify-between rounded-xl bg-muted/35 p-3">
                <span>{natureLabels[item.expenseNature]}</span>
                <span className="text-right">
                  <strong>{money.format(item.amount)}</strong>
                  <small className="ml-2 text-muted-foreground">
                    {item.percentOfIncome.toFixed(1)}% thu nhập
                  </small>
                </span>
              </div>
            ))
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>So với tháng trước</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          {report.isError ? (
            <InlineError error={report.error} fallback="Không tải được báo cáo tháng." />
          ) : (
            <>
              <ReportLine label="Thu nhập" value={report.data?.income ?? 0} />
              <ReportLine label="Chi tiêu" value={report.data?.expense ?? 0} />
              <ReportLine label="Tiết kiệm ròng" value={report.data?.netSaving ?? 0} />
              <ReportLine label="Chênh lệch chi tiêu" value={report.data?.expenseChange ?? 0} signed />
            </>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>Ngân sách cần chú ý</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          {data.budgets.length === 0 ? (
            <Empty text="Chưa đặt ngân sách cho tháng này." />
          ) : (
            [...data.budgets]
              .sort((left, right) => right.percent - left.percent)
              .slice(0, 4)
              .map((budget) => {
                const level = budgetLevel(budget.percent);
                return (
                  <div key={budget.id}>
                    <div className="mb-1 flex items-center justify-between gap-3 text-sm">
                      <span>{budget.categoryName}</span>
                      <strong className={level === "over" ? "text-rose-700" : level === "warning" ? "text-amber-700" : ""}>
                        {budget.percent.toFixed(0)}%
                      </strong>
                    </div>
                    <Progress value={Math.min(100, budget.percent)} />
                    <p className="mt-1 text-xs text-muted-foreground">
                      Còn {money.format(Math.max(0, budget.remaining))} · dự kiến {money.format(budget.projected)}
                    </p>
                  </div>
                );
              })
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>Sắp tới</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          {data.upcoming.length === 0 ? (
            <Empty text="Chưa có khoản định kỳ sắp đến hạn." />
          ) : (
            data.upcoming.slice(0, 5).map((item) => (
              <div key={item.id} className="flex items-center justify-between gap-3 rounded-xl border p-3">
                <div>
                  <p className="font-semibold">{item.name}</p>
                  <p className="text-xs text-muted-foreground">{formatDate(item.nextDueDate)} · {frequencyLabel(item.frequency)}</p>
                </div>
                <strong>{money.format(item.amount)}</strong>
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </>
  );
}
