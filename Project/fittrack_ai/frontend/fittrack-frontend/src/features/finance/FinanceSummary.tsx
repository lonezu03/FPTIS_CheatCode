import { ArrowDownRight, ArrowUpRight, Landmark, Plus, WalletCards } from "lucide-react";

import type { FinanceDashboard } from "@/api/finance.api";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Metric } from "./FinanceParts";
import { money } from "./finance-utils";

/** Title row: reconcile shortcut, month picker and "new transaction". */
export function FinanceHeader({ month, canCreate, onMonthChange, onReconcile, onNewTransaction }: {
  month: string;
  canCreate: boolean;
  onMonthChange: (value: string) => void;
  onReconcile: () => void;
  onNewTransaction: () => void;
}) {
  return (
    <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <PageHeader
        title="Tài chính cá nhân"
      />
      <div className="flex flex-wrap gap-2">
        <Button variant="outline" onClick={onReconcile}>Đối soát số dư ví</Button>
        <Input
          aria-label="Tháng tài chính"
          className="w-40"
          type="month"
          value={month}
          onChange={(event) => onMonthChange(event.target.value)}
        />
        <Button onClick={onNewTransaction} disabled={!canCreate}>
          <Plus className="size-4" /> Ghi giao dịch
        </Button>
      </div>
    </div>
  );
}

/** Shown until the first money account exists. */
export function FinanceOnboarding({ onCreateAccount }: { onCreateAccount: () => void }) {
  return (
    <Card className="border-emerald-300 bg-emerald-50/60">
      <CardContent className="flex flex-col gap-4 p-5 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="font-semibold text-emerald-950">Bắt đầu bằng một tài khoản tiền</p>
          <p className="mt-1 text-sm text-emerald-900/75">
            Tạo tiền mặt, ngân hàng hoặc ví điện tử. Số dư đầu chỉ là điểm bắt đầu và không tính vào thu nhập.
          </p>
        </div>
        <Button onClick={onCreateAccount}>
          <Plus className="size-4" /> Tạo tài khoản
        </Button>
      </CardContent>
    </Card>
  );
}

/** Month metrics and insight card. */
export function FinanceSummary({ data }: { data: FinanceDashboard }) {
  return (
    <>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Metric
          title="Thu nhập"
          value={data.income}
          icon={ArrowDownRight}
          tone="bg-emerald-50 text-emerald-800"
        />
        <Metric
          title="Chi tiêu"
          value={data.expense}
          icon={ArrowUpRight}
          tone="bg-rose-50 text-rose-800"
        />
        <Metric
          title="Chi bắt buộc dự kiến"
          value={data.mandatoryCommitted}
          detail={`Đã trả ${money.format(data.mandatoryPaid)} · còn ${money.format(data.mandatoryRemaining)}`}
          icon={Landmark}
          tone="bg-amber-50 text-amber-900"
        />
        <Metric
          title="Tiền linh hoạt"
          value={data.flexibleAvailable}
          detail={`Tiết kiệm ${money.format(data.savingCommitted)} · chuẩn bị ${money.format(data.trueExpensePreparation)}`}
          icon={WalletCards}
          tone="bg-blue-50 text-blue-900"
        />
      </div>

      <Card className="border-emerald-200 bg-emerald-50/50">
        <CardContent className="flex flex-col gap-2 p-5 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="font-semibold text-emerald-950">Góc nhìn tháng này</p>
            <p className="mt-1 text-sm leading-6 text-emerald-950/75">{data.insight}</p>
          </div>
          <div className="shrink-0 rounded-xl border border-emerald-200 bg-white px-4 py-3 text-right">
            <p className="text-xs text-muted-foreground">Tổng số dư hiện tại</p>
            <p className="font-bold text-emerald-800">{money.format(data.totalBalance)}</p>
          </div>
        </CardContent>
      </Card>
    </>
  );
}
