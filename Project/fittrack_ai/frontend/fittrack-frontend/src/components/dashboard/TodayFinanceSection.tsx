import { useQuery } from "@tanstack/react-query";
import { Plus, WalletCards } from "lucide-react";
import { getFinanceDashboard, getFinanceTransactions } from "@/api/finance.api";
import { Button } from "@/components/ui/button";
import { formatCurrency } from "@/lib/format";
import { cn } from "@/lib/utils";
import TodaySection from "./TodaySection";
import { budgetTone, postedExpenseTotal, todayKey, topBudgets } from "./today-utils";

const barTone = { ok: "bg-emerald-500", warning: "bg-amber-500", danger: "bg-red-500" } as const;

export default function TodayFinanceSection({ onAdd }: { onAdd: () => void }) {
  const today = todayKey();
  const month = today.slice(0, 7);
  // "finance-" keys are refreshed by every finance mutation (FinancePage and quick add).
  const dashboard = useQuery({ queryKey: ["finance-dashboard", month], queryFn: () => getFinanceDashboard(`${month}-01`) });
  const todayTx = useQuery({
    queryKey: ["finance-transactions-today", today],
    queryFn: () => getFinanceTransactions({ from: today, to: today, type: "EXPENSE", page: 0, size: 100 }),
  });

  const loading = dashboard.isLoading || todayTx.isLoading;
  const failed = dashboard.isError && todayTx.isError;
  const spentToday = postedExpenseTotal(todayTx.data?.content ?? []);
  const txCount = (todayTx.data?.content ?? []).filter((tx) => tx.status === "POSTED").length;
  const budgets = topBudgets(dashboard.data?.budgets ?? []);
  const retry = () => { void dashboard.refetch(); void todayTx.refetch(); };

  return (
    <TodaySection id="today-finance" title="Chi tiêu" icon={WalletCards} iconClassName="bg-sky-100 text-sky-800 dark:bg-sky-950 dark:text-sky-200"
      state={loading ? "loading" : failed ? "error" : "ready"} errorText="Không tải được thu chi." onRetry={retry}
      link={{ to: "/finance", label: "Thu chi" }}>
      <div className="grid grid-cols-2 gap-2">
        <div className="rounded-xl bg-muted/50 p-3">
          <p className="text-xs text-muted-foreground">Hôm nay</p>
          {todayTx.isError ? <p className="text-sm text-destructive">Lỗi tải</p> : (
            <>
              <p className="text-lg font-semibold tracking-tight">{formatCurrency(spentToday)}</p>
              <p className="text-xs text-muted-foreground">{txCount} khoản chi</p>
            </>
          )}
        </div>
        <div className="rounded-xl bg-muted/50 p-3">
          <p className="text-xs text-muted-foreground">Tháng này đã chi</p>
          {dashboard.isError || !dashboard.data ? <p className="text-sm text-destructive">Lỗi tải</p> : (
            <>
              <p className="text-lg font-semibold tracking-tight">{formatCurrency(dashboard.data.expense)}</p>
              <p className="text-xs text-muted-foreground">Còn linh hoạt {formatCurrency(dashboard.data.flexibleAvailable)}</p>
            </>
          )}
        </div>
      </div>
      {dashboard.data && (budgets.length > 0 ? (
        <ul className="grid gap-2" aria-label="Ngân sách tháng">
          {budgets.map((budget) => {
            const tone = budgetTone(budget.percent);
            return (
              <li key={budget.id} className="grid gap-1">
                <div className="flex items-center justify-between gap-2 text-xs">
                  <span className="truncate font-medium">{budget.categoryName}</span>
                  <span className={cn("shrink-0 text-muted-foreground", tone === "danger" && "font-semibold text-red-600", tone === "warning" && "font-semibold text-amber-700")}>
                    {tone === "danger" ? `Vượt ${formatCurrency(Math.abs(budget.remaining))}` : `Còn ${formatCurrency(budget.remaining)}`}
                  </span>
                </div>
                <div className="h-1.5 overflow-hidden rounded-full bg-muted" role="progressbar" aria-label={`Ngân sách ${budget.categoryName}`}
                  aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.min(100, Math.round(budget.percent))}>
                  <div className={cn("h-full rounded-full", barTone[tone])} style={{ width: `${Math.min(100, Math.max(0, budget.percent))}%` }} />
                </div>
              </li>
            );
          })}
        </ul>
      ) : <p className="text-xs text-muted-foreground">Chưa đặt ngân sách tháng này.</p>)}
      <Button size="sm" variant="outline" onClick={onAdd}><Plus className="size-3.5" />Ghi khoản chi</Button>
    </TodaySection>
  );
}
