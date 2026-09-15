import { useState, type ElementType, type ReactNode } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ArrowDownRight,
  ArrowLeftRight,
  ArrowUpRight,
  CircleAlert,
  Landmark,
  Pencil,
  Plus,
  Trash2,
  WalletCards,
} from "lucide-react";
import { toast } from "sonner";

import {
  archiveFinanceAccount,
  archiveFinanceCategory,
  archiveFinanceRecurring,
  confirmFinanceRecurring,
  createFinanceAccount,
  createFinanceCategory,
  createFinanceRecurring,
  createFinanceTransaction,
  deleteFinanceBudget,
  getFinanceAccounts,
  getFinanceBudgets,
  getFinanceCategories,
  getFinanceDashboard,
  getFinanceRecurring,
  getFinanceReport,
  getFinanceTransactions,
  saveFinanceBudget,
  snoozeFinanceRecurring,
  updateFinanceAccount,
  updateFinanceBudget,
  updateFinanceCategory,
  updateFinanceRecurring,
  updateFinanceTransaction,
  voidFinanceTransaction,
  type ExpenseNature,
  type FinanceAccount,
  type FinanceBudget,
  type FinanceCategory,
  type FinanceRecurring,
  type FinanceTransaction,
  type FinanceTransactionInput,
} from "@/api/finance.api";
import ErrorState from "@/components/common/ErrorState";
import PageLoading from "@/components/common/PageLoading";
import PageHeader from "@/components/PageHeader";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Progress } from "@/components/ui/progress";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { getApiErrorMessage } from "@/lib/format";

const money = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
  maximumFractionDigits: 0,
});

const expenseNatures: Array<{
  value: ExpenseNature;
  label: string;
  description: string;
}> = [
  {
    value: "FIXED_MANDATORY",
    label: "Bắt buộc cố định",
    description: "Tiền nhà, khoản vay hoặc nghĩa vụ có số tiền tương đối cố định.",
  },
  {
    value: "ESSENTIAL_VARIABLE",
    label: "Thiết yếu biến động",
    description: "Ăn uống, điện nước, đi lại hoặc sức khỏe cần thiết nhưng số tiền thay đổi.",
  },
  {
    value: "TRUE_EXPENSE",
    label: "Khoản phải chuẩn bị",
    description: "Chi phí ít xuất hiện nhưng có thể dự đoán như bảo hiểm, sửa xe hoặc học phí.",
  },
  {
    value: "SAVING",
    label: "Tiết kiệm / mục tiêu",
    description: "Tiền chủ động dành cho quỹ dự phòng hoặc mục tiêu tương lai.",
  },
  {
    value: "DISCRETIONARY",
    label: "Tùy ý / hưởng thụ",
    description: "Giải trí, mua sắm và các khoản có thể cắt giảm khi cần.",
  },
];

const natureLabels: Record<string, string> = Object.fromEntries([
  ...expenseNatures.map((item) => [item.value, item.label]),
  ["UNCLASSIFIED", "Chưa phân loại"],
]);

const monthNow = localDate().slice(0, 7);
const monthDate = (value: string) => `${value}-01`;

export default function FinancePage() {
  const queryClient = useQueryClient();
  const [month, setMonth] = useState(monthNow);
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [accountFilter, setAccountFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [transactionDialog, setTransactionDialog] = useState<FinanceTransaction | "new" | null>(null);
  const [accountDialog, setAccountDialog] = useState<FinanceAccount | "new" | null>(null);
  const [categoryDialog, setCategoryDialog] = useState<FinanceCategory | "new" | null>(null);
  const [budgetDialog, setBudgetDialog] = useState<FinanceBudget | "new" | null>(null);
  const [recurringDialog, setRecurringDialog] = useState<FinanceRecurring | "new" | null>(null);

  const selectedMonth = monthDate(month);
  const dashboard = useQuery({
    queryKey: ["finance-dashboard", month],
    queryFn: () => getFinanceDashboard(selectedMonth),
  });
  const accounts = useQuery({ queryKey: ["finance-accounts"], queryFn: getFinanceAccounts });
  const categories = useQuery({ queryKey: ["finance-categories"], queryFn: getFinanceCategories });
  const budgets = useQuery({
    queryKey: ["finance-budgets", month],
    queryFn: () => getFinanceBudgets(selectedMonth),
  });
  const recurring = useQuery({ queryKey: ["finance-recurring"], queryFn: getFinanceRecurring });
  const report = useQuery({
    queryKey: ["finance-report", month],
    queryFn: () => getFinanceReport(selectedMonth),
  });
  const transactions = useQuery({
    queryKey: [
      "finance-transactions",
      month,
      page,
      search,
      typeFilter,
      accountFilter,
      categoryFilter,
    ],
    queryFn: () =>
      getFinanceTransactions({
        from: selectedMonth,
        to: endOfMonth(month),
        page,
        size: 15,
        q: search || undefined,
        type: typeFilter || undefined,
        accountId: accountFilter || undefined,
        categoryId: categoryFilter || undefined,
      }),
  });

  const voidMutation = useFinanceAction(voidFinanceTransaction, "Đã hủy giao dịch");
  const deleteBudgetMutation = useFinanceAction(deleteFinanceBudget, "Đã xóa ngân sách");
  const confirmRecurringMutation = useFinanceAction(confirmFinanceRecurring, "Đã ghi nhận khoản định kỳ");
  const snoozeRecurringMutation = useFinanceAction(snoozeFinanceRecurring, "Sẽ nhắc lại vào ngày mai");
  const archiveRecurringMutation = useFinanceAction(archiveFinanceRecurring, "Đã ngừng khoản định kỳ");
  const archiveAccountMutation = useFinanceAction(archiveFinanceAccount, "Đã lưu trữ tài khoản");
  const archiveCategoryMutation = useFinanceAction(archiveFinanceCategory, "Đã lưu trữ danh mục");

  const refresh = () =>
    queryClient.invalidateQueries({
      predicate: (query) => String(query.queryKey[0]).startsWith("finance-"),
    });

  if (dashboard.isLoading || accounts.isLoading || categories.isLoading) {
    return <PageLoading />;
  }

  if (dashboard.isError || accounts.isError || categories.isError || !dashboard.data) {
    return (
      <ErrorState
        title="Không thể tải tài chính"
        message={getApiErrorMessage(
          dashboard.error || accounts.error || categories.error,
          "Vui lòng thử lại. Nếu lỗi tiếp diễn, hãy lưu mã yêu cầu để kiểm tra log.",
        )}
      />
    );
  }

  const data = dashboard.data;
  const accountList = accounts.data ?? [];
  const categoryList = categories.data ?? [];
  const activeAccounts = accountList.filter((item) => item.active);
  const activeExpenseCategories = categoryList.filter(
    (item) => item.active && item.transactionKind === "EXPENSE",
  );
  const recentCategoryIds = Array.from(new Set(
    (transactions.data?.content ?? [])
      .filter((item) => item.status === "POSTED" && item.categoryId)
      .map((item) => item.categoryId as string),
  )).slice(0, 5);

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader
          title="Tài chính cá nhân"
          description="Theo dõi tiền, chuẩn bị nghĩa vụ và biết phần còn có thể sử dụng. FitTrack không giữ hoặc chuyển tiền thật."
        />
        <div className="flex flex-wrap gap-2">
          <Input
            aria-label="Tháng tài chính"
            className="w-40"
            type="month"
            value={month}
            onChange={(event) => {
              setMonth(event.target.value);
              setPage(0);
            }}
          />
          <Button
            onClick={() => setTransactionDialog("new")}
            disabled={activeAccounts.length === 0 || activeExpenseCategories.length === 0}
          >
            <Plus className="size-4" /> Ghi giao dịch
          </Button>
        </div>
      </div>

      {activeAccounts.length === 0 && (
        <Card className="border-emerald-300 bg-emerald-50/60">
          <CardContent className="flex flex-col gap-4 p-5 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="font-semibold text-emerald-950">Bắt đầu bằng một tài khoản tiền</p>
              <p className="mt-1 text-sm text-emerald-900/75">
                Tạo tiền mặt, ngân hàng hoặc ví điện tử. Số dư đầu chỉ là điểm bắt đầu và không tính vào thu nhập.
              </p>
            </div>
            <Button onClick={() => setAccountDialog("new")}>
              <Plus className="size-4" /> Tạo tài khoản
            </Button>
          </CardContent>
        </Card>
      )}

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

      <Tabs defaultValue="overview" className="gap-4">
        <TabsList className="max-w-full justify-start overflow-x-auto">
          <TabsTrigger value="overview">Tổng quan</TabsTrigger>
          <TabsTrigger value="transactions">Giao dịch</TabsTrigger>
          <TabsTrigger value="budgets">Ngân sách</TabsTrigger>
          <TabsTrigger value="recurring">Định kỳ</TabsTrigger>
          <TabsTrigger value="settings">Thiết lập</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="grid gap-4 lg:grid-cols-2">
          <Card>
            <CardHeader><CardTitle>Tài khoản</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              {activeAccounts.length === 0 ? (
                <Empty text="Tạo tài khoản tiền đầu tiên để bắt đầu." />
              ) : (
                activeAccounts.map((account) => (
                  <div key={account.id} className="flex items-center justify-between rounded-xl border p-3">
                    <div>
                      <p className="font-semibold">{account.name}</p>
                      <p className="text-xs text-muted-foreground">{accountTypeLabel(account.accountType)}</p>
                    </div>
                    <p className="font-bold">{money.format(account.currentBalance)}</p>
                  </div>
                ))
              )}
              <Button variant="outline" className="w-full" onClick={() => setAccountDialog("new")}>
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
                  .map((budget) => (
                    <div key={budget.id}>
                      <div className="mb-1 flex items-center justify-between gap-3 text-sm">
                        <span>{budget.categoryName}</span>
                        <strong className={budget.percent >= 100 ? "text-rose-700" : budget.percent >= 80 ? "text-amber-700" : ""}>
                          {budget.percent.toFixed(0)}%
                        </strong>
                      </div>
                      <Progress value={Math.min(100, budget.percent)} />
                      <p className="mt-1 text-xs text-muted-foreground">
                        Còn {money.format(Math.max(0, budget.remaining))} · dự kiến {money.format(budget.projected)}
                      </p>
                    </div>
                  ))
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
        </TabsContent>

        <TabsContent value="transactions">
          <Card>
            <CardHeader>
              <div className="flex flex-col gap-3">
                <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                  <CardTitle>Lịch sử giao dịch</CardTitle>
                  <Button onClick={() => setTransactionDialog("new")} disabled={activeAccounts.length === 0}>
                    <Plus className="size-4" /> Ghi giao dịch
                  </Button>
                </div>
                <div className="grid gap-2 sm:grid-cols-2 xl:grid-cols-4">
                  <Input
                    placeholder="Tìm nơi chi, ghi chú..."
                    value={search}
                    onChange={(event) => {
                      setSearch(event.target.value);
                      setPage(0);
                    }}
                  />
                  <select
                    className="field"
                    aria-label="Lọc loại giao dịch"
                    value={typeFilter}
                    onChange={(event) => {
                      setTypeFilter(event.target.value);
                      setCategoryFilter("");
                      setPage(0);
                    }}
                  >
                    <option value="">Tất cả loại</option>
                    <option value="EXPENSE">Chi tiêu</option>
                    <option value="INCOME">Thu nhập</option>
                    <option value="TRANSFER">Chuyển khoản</option>
                  </select>
                  <select
                    className="field"
                    aria-label="Lọc tài khoản"
                    value={accountFilter}
                    onChange={(event) => {
                      setAccountFilter(event.target.value);
                      setPage(0);
                    }}
                  >
                    <option value="">Tất cả tài khoản</option>
                    {accountList.map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
                  </select>
                  <select
                    className="field"
                    aria-label="Lọc danh mục"
                    value={categoryFilter}
                    disabled={typeFilter === "TRANSFER"}
                    onChange={(event) => {
                      setCategoryFilter(event.target.value);
                      setPage(0);
                    }}
                  >
                    <option value="">Tất cả danh mục</option>
                    {categoryList
                      .filter((category) => !typeFilter || category.transactionKind === typeFilter)
                      .map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
                  </select>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {transactions.isError ? (
                <InlineError error={transactions.error} fallback="Không tải được lịch sử giao dịch." />
              ) : !transactions.data?.content.length ? (
                <Empty text="Không có giao dịch phù hợp." />
              ) : (
                <div className="space-y-2">
                  {transactions.data.content.map((transaction) => (
                    <TransactionRow
                      key={transaction.id}
                      transaction={transaction}
                      onEdit={() => setTransactionDialog(transaction)}
                      onVoid={() => {
                        if (window.confirm("Đưa giao dịch này vào trạng thái đã hủy?")) {
                          voidMutation.mutate(transaction.id);
                        }
                      }}
                    />
                  ))}
                </div>
              )}
              {(transactions.data?.totalPages ?? 0) > 1 && (
                <div className="mt-4 flex items-center justify-end gap-2">
                  <Button variant="outline" disabled={page === 0} onClick={() => setPage((value) => value - 1)}>
                    Trước
                  </Button>
                  <span className="text-sm">Trang {page + 1}/{transactions.data?.totalPages}</span>
                  <Button variant="outline" disabled={transactions.data?.last} onClick={() => setPage((value) => value + 1)}>
                    Sau
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="budgets">
          <Card>
            <CardHeader>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <CardTitle>Ngân sách theo danh mục</CardTitle>
                  <p className="mt-1 text-sm text-muted-foreground">Cảnh báo một lần khi chạm 80% và 100% hạn mức.</p>
                </div>
                <Button onClick={() => setBudgetDialog("new")}>
                  <Plus className="size-4" /> Thêm ngân sách
                </Button>
              </div>
            </CardHeader>
            <CardContent className="grid gap-3 md:grid-cols-2">
              {budgets.isError ? (
                <InlineError error={budgets.error} fallback="Không tải được ngân sách." />
              ) : !budgets.data?.length ? (
                <Empty text="Chưa đặt ngân sách cho tháng này." />
              ) : (
                budgets.data.map((budget) => (
                  <div
                    key={budget.id}
                    className={`rounded-xl border p-4 ${
                      budget.percent >= 100
                        ? "border-rose-300 bg-rose-50/50"
                        : budget.percent >= 80
                          ? "border-amber-300 bg-amber-50/50"
                          : ""
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <strong>{budget.categoryName}</strong>
                        {budget.percent >= 100 && <Badge className="ml-2 bg-rose-100 text-rose-700">Đã vượt hạn mức</Badge>}
                        {budget.percent >= 80 && budget.percent < 100 && <Badge className="ml-2 bg-amber-100 text-amber-800">Sắp hết</Badge>}
                      </div>
                      <div className="flex gap-1">
                        <Button size="icon-sm" variant="ghost" aria-label="Sửa ngân sách" onClick={() => setBudgetDialog(budget)}>
                          <Pencil className="size-4" />
                        </Button>
                        <Button
                          size="icon-sm"
                          variant="ghost"
                          aria-label="Xóa ngân sách"
                          onClick={() => window.confirm("Xóa ngân sách tháng này?") && deleteBudgetMutation.mutate(budget.id)}
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
                ))
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="recurring">
          <Card>
            <CardHeader>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <CardTitle>Khoản định kỳ sắp tới</CardTitle>
                  <p className="mt-1 text-sm text-muted-foreground">
                    Hệ thống chỉ nhắc. Giao dịch thật chỉ xuất hiện sau khi bạn xác nhận.
                  </p>
                </div>
                <Button onClick={() => setRecurringDialog("new")}>
                  <Plus className="size-4" /> Thêm khoản
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-3">
              {recurring.isError ? (
                <InlineError error={recurring.error} fallback="Không tải được khoản định kỳ." />
              ) : !recurring.data?.filter((item) => item.active).length ? (
                <Empty text="Chưa có khoản định kỳ." />
              ) : (
                recurring.data
                  .filter((item) => item.active)
                  .map((item) => (
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
                        <Button onClick={() => confirmRecurringMutation.mutate(item.id)}>
                          {confirmRecurringLabel(item.transactionType)}
                        </Button>
                        <Button variant="outline" onClick={() => setRecurringDialog(item)}>
                          <Pencil className="size-4" /> Sửa
                        </Button>
                        <Button variant="outline" onClick={() => snoozeRecurringMutation.mutate(item.id)}>
                          Nhắc lại ngày mai
                        </Button>
                        <Button
                          variant="outline"
                          onClick={() => window.confirm("Ngừng nhắc khoản định kỳ này?") && archiveRecurringMutation.mutate(item.id)}
                        >
                          Ngừng
                        </Button>
                      </div>
                    </div>
                  ))
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="settings" className="grid gap-4 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Tài khoản tiền</CardTitle>
                <Button size="sm" onClick={() => setAccountDialog("new")}><Plus className="size-4" /> Thêm</Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-2">
              {accountList.length === 0 ? <Empty text="Chưa có tài khoản tiền." /> : accountList.map((account) => (
                <div key={account.id} className={`flex items-center justify-between rounded-xl border p-3 ${account.active ? "" : "opacity-60"}`}>
                  <div>
                    <strong>{account.name}</strong>
                    <p className="text-xs text-muted-foreground">
                      {accountTypeLabel(account.accountType)} · số dư đầu {money.format(account.openingBalance)}
                      {!account.active ? " · Đã lưu trữ" : ""}
                    </p>
                  </div>
                  {account.active && (
                    <div className="flex gap-1">
                      <Button size="icon-sm" variant="ghost" aria-label="Sửa tài khoản" onClick={() => setAccountDialog(account)}>
                        <Pencil className="size-4" />
                      </Button>
                      <Button
                        size="icon-sm"
                        variant="ghost"
                        aria-label="Lưu trữ tài khoản"
                        onClick={() => window.confirm("Lưu trữ tài khoản này? Lịch sử vẫn được giữ lại.") && archiveAccountMutation.mutate(account.id)}
                      >
                        <Trash2 className="size-4 text-rose-600" />
                      </Button>
                    </div>
                  )}
                </div>
              ))}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Danh mục cá nhân</CardTitle>
                <Button size="sm" onClick={() => setCategoryDialog("new")}><Plus className="size-4" /> Thêm</Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-2">
              {categoryList.filter((item) => item.active).map((category) => (
                <div key={category.id} className="flex items-center justify-between rounded-xl border p-3">
                  <div>
                    <strong>{category.name}</strong>
                    <p className="text-xs text-muted-foreground">
                      {category.transactionKind === "INCOME" ? "Thu nhập" : natureLabels[category.expenseNature || "UNCLASSIFIED"]}
                      {category.parentId ? ` · danh mục con của ${categoryList.find((item) => item.id === category.parentId)?.name ?? "khác"}` : ""}
                    </p>
                  </div>
                  <div className="flex gap-1">
                    <Button size="icon-sm" variant="ghost" aria-label="Sửa danh mục" onClick={() => setCategoryDialog(category)}>
                      <Pencil className="size-4" />
                    </Button>
                    {!category.systemCategory && (
                      <Button
                        size="icon-sm"
                        variant="ghost"
                        aria-label="Lưu trữ danh mục"
                        onClick={() => window.confirm("Lưu trữ danh mục này? Dữ liệu cũ vẫn được giữ lại.") && archiveCategoryMutation.mutate(category.id)}
                      >
                        <Trash2 className="size-4 text-rose-600" />
                      </Button>
                    )}
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {transactionDialog && (
        <TransactionDialog
          initial={transactionDialog === "new" ? null : transactionDialog}
          accounts={accountList}
          categories={categoryList}
          recentCategoryIds={recentCategoryIds}
          onOpenChange={(open) => !open && setTransactionDialog(null)}
          onSaved={refresh}
        />
      )}
      {accountDialog && (
        <AccountDialog
          initial={accountDialog === "new" ? null : accountDialog}
          onOpenChange={(open) => !open && setAccountDialog(null)}
          onSaved={refresh}
        />
      )}
      {categoryDialog && (
        <CategoryDialog
          initial={categoryDialog === "new" ? null : categoryDialog}
          categories={categoryList}
          onOpenChange={(open) => !open && setCategoryDialog(null)}
          onSaved={refresh}
        />
      )}
      {budgetDialog && (
        <BudgetDialog
          initial={budgetDialog === "new" ? null : budgetDialog}
          month={selectedMonth}
          categories={categoryList}
          onOpenChange={(open) => !open && setBudgetDialog(null)}
          onSaved={refresh}
        />
      )}
      {recurringDialog && (
        <RecurringDialog
          initial={recurringDialog === "new" ? null : recurringDialog}
          accounts={accountList}
          categories={categoryList}
          onOpenChange={(open) => !open && setRecurringDialog(null)}
          onSaved={refresh}
        />
      )}
    </div>
  );
}

function TransactionRow({
  transaction,
  onEdit,
  onVoid,
}: {
  transaction: FinanceTransaction;
  onEdit: () => void;
  onVoid: () => void;
}) {
  const isVoid = transaction.status === "VOID";
  return (
    <div className={`flex flex-col gap-2 rounded-xl border p-3 sm:flex-row sm:items-center sm:justify-between ${isVoid ? "opacity-55" : ""}`}>
      <div className="flex min-w-0 items-center gap-3">
        <span className={`grid size-9 shrink-0 place-items-center rounded-xl ${transactionTone(transaction.type)}`}>
          {transaction.type === "TRANSFER" ? <ArrowLeftRight className="size-4" /> : transaction.type === "INCOME" ? <ArrowDownRight className="size-4" /> : <ArrowUpRight className="size-4" />}
        </span>
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <p className={isVoid ? "font-semibold line-through" : "font-semibold"}>
              {transaction.categoryName || `${transaction.accountName} → ${transaction.destinationAccountName}`}
            </p>
            {isVoid && <Badge variant="outline">Đã hủy</Badge>}
            {transaction.expenseNature && <Badge variant="outline">{natureLabels[transaction.expenseNature]}</Badge>}
          </div>
          <p className="truncate text-xs text-muted-foreground">
            {new Date(transaction.occurredAt).toLocaleString("vi-VN")}
            {transaction.merchant ? ` · ${transaction.merchant}` : ""}
            {transaction.note ? ` · ${transaction.note}` : ""}
          </p>
        </div>
      </div>
      <div className="flex items-center justify-between gap-3">
        <strong className={transaction.type === "INCOME" ? "text-emerald-700" : transaction.type === "EXPENSE" ? "text-rose-700" : ""}>
          {transaction.type === "INCOME" ? "+" : transaction.type === "EXPENSE" ? "−" : ""}{money.format(transaction.amount)}
        </strong>
        {!isVoid && (
          <div className="flex gap-1">
            <Button size="icon-sm" variant="ghost" aria-label="Sửa giao dịch" onClick={onEdit}>
              <Pencil className="size-4" />
            </Button>
            <Button size="icon-sm" variant="ghost" aria-label="Hủy giao dịch" onClick={onVoid}>
              <Trash2 className="size-4 text-rose-600" />
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}

function TransactionDialog({
  initial,
  accounts,
  categories,
  recentCategoryIds,
  onOpenChange,
  onSaved,
}: {
  initial: FinanceTransaction | null;
  accounts: FinanceAccount[];
  categories: FinanceCategory[];
  recentCategoryIds: string[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState({
    type: initial?.type ?? "EXPENSE",
    amount: initial ? String(initial.amount) : "",
    accountId: initial?.accountId ?? "",
    destinationAccountId: initial?.destinationAccountId ?? "",
    categoryId: initial?.categoryId ?? "",
    expenseNature: initial?.expenseNature ?? "ESSENTIAL_VARIABLE",
    occurredAt: initial ? initial.occurredAt.slice(0, 16) : localDateTime(),
    merchant: initial?.merchant ?? "",
    note: initial?.note ?? "",
  });
  const mutation = useMutation({
    mutationFn: () => {
      const payload: FinanceTransactionInput = {
        type: form.type,
        amount: Number(form.amount),
        accountId: form.accountId,
        destinationAccountId: form.type === "TRANSFER" ? form.destinationAccountId || null : null,
        categoryId: form.type === "TRANSFER" ? null : form.categoryId || null,
        expenseNature: form.type === "EXPENSE" ? form.expenseNature : null,
        occurredAt: form.occurredAt,
        merchant: form.merchant,
        note: form.note,
      };
      return initial
        ? updateFinanceTransaction(initial.id, payload)
        : createFinanceTransaction(payload);
    },
    onSuccess: () => {
      toast.success(initial ? "Đã cập nhật giao dịch" : "Đã ghi giao dịch");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu giao dịch.")),
  });
  const choices = categories.filter((category) => category.active && category.transactionKind === form.type);
  const recentChoices = recentCategoryIds
    .map((id) => choices.find((category) => category.id === id))
    .filter((category): category is FinanceCategory => Boolean(category));
  const valid = Number(form.amount) > 0 && Boolean(form.accountId) && Boolean(form.occurredAt)
    && (form.type === "TRANSFER" ? Boolean(form.destinationAccountId) : Boolean(form.categoryId));

  return (
    <Dialog open onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{initial ? "Sửa giao dịch" : "Ghi giao dịch nhanh"}</DialogTitle>
          <DialogDescription>Số tiền luôn là số dương; chọn đúng loại để báo cáo không bị sai.</DialogDescription>
        </DialogHeader>
        <form id="finance-transaction" className="grid gap-4 sm:grid-cols-2" onSubmit={(event) => { event.preventDefault(); mutation.mutate(); }}>
          <Field label="Số tiền (VND)" required className="sm:col-span-2">
            <Input autoFocus inputMode="numeric" min="1" type="number" value={form.amount} onChange={(event) => setForm({ ...form, amount: event.target.value })} />
          </Field>
          <Field label="Loại giao dịch" required>
            <select className="field" value={form.type} onChange={(event) => setForm({ ...form, type: event.target.value as FinanceTransactionInput["type"], categoryId: "", destinationAccountId: "" })}>
              <option value="EXPENSE">Chi tiêu</option>
              <option value="INCOME">Thu nhập</option>
              <option value="TRANSFER">Chuyển giữa tài khoản</option>
            </select>
          </Field>
          <Field label="Tài khoản nguồn / nhận thu nhập" required>
            <select className="field" value={form.accountId} onChange={(event) => setForm({ ...form, accountId: event.target.value, destinationAccountId: event.target.value === form.destinationAccountId ? "" : form.destinationAccountId })}>
              <option value="">Chọn tài khoản</option>
              {accounts.filter((account) => account.active).map((account) => <option key={account.id} value={account.id}>{account.name} · {money.format(account.currentBalance)}</option>)}
            </select>
          </Field>
          {form.type === "TRANSFER" ? (
            <Field label="Tài khoản nhận" required>
              <select className="field" value={form.destinationAccountId} onChange={(event) => setForm({ ...form, destinationAccountId: event.target.value })}>
                <option value="">Chọn tài khoản khác</option>
                {accounts.filter((account) => account.active && account.id !== form.accountId).map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
              </select>
            </Field>
          ) : (
            <Field label="Danh mục" required>
              <select className="field" value={form.categoryId} onChange={(event) => {
                const selected = choices.find((category) => category.id === event.target.value);
                setForm({ ...form, categoryId: event.target.value, expenseNature: selected?.expenseNature ?? form.expenseNature });
              }}>
                <option value="">Chọn danh mục</option>
                {choices.map((category) => <option key={category.id} value={category.id}>{category.name}{category.expenseNature ? ` · ${natureLabels[category.expenseNature]}` : ""}</option>)}
              </select>
            </Field>
          )}
          {form.type !== "TRANSFER" && recentChoices.length > 0 && (
            <Field label="Danh mục gần đây" className="sm:col-span-2">
              <div className="flex flex-wrap gap-2">
                {recentChoices.map((category) => (
                  <Button
                    key={category.id}
                    type="button"
                    size="sm"
                    variant={form.categoryId === category.id ? "default" : "outline"}
                    onClick={() => setForm({
                      ...form,
                      categoryId: category.id,
                      expenseNature: category.expenseNature ?? form.expenseNature,
                    })}
                  >
                    {category.name}
                  </Button>
                ))}
              </div>
            </Field>
          )}
          {form.type === "EXPENSE" && (
            <NatureField value={form.expenseNature} onChange={(expenseNature) => setForm({ ...form, expenseNature })} />
          )}
          <Field label="Thời điểm" required>
            <Input type="datetime-local" value={form.occurredAt} onChange={(event) => setForm({ ...form, occurredAt: event.target.value })} />
          </Field>
          <Field label="Nơi chi / nguồn thu">
            <Input placeholder="Ví dụ: siêu thị, công ty..." value={form.merchant} onChange={(event) => setForm({ ...form, merchant: event.target.value })} />
          </Field>
          <Field label="Ghi chú">
            <Input placeholder="Thông tin giúp bạn nhớ giao dịch" value={form.note} onChange={(event) => setForm({ ...form, note: event.target.value })} />
          </Field>
        </form>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>Hủy</Button>
          <Button form="finance-transaction" type="submit" disabled={mutation.isPending || !valid}>
            {mutation.isPending ? "Đang lưu..." : initial ? "Cập nhật" : "Lưu giao dịch"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function AccountDialog({ initial, onOpenChange, onSaved }: {
  initial: FinanceAccount | null;
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [type, setType] = useState(initial?.accountType ?? "BANK");
  const [balance, setBalance] = useState(String(initial?.openingBalance ?? 0));
  const mutation = useMutation({
    mutationFn: () => {
      const payload = { name, accountType: type, currencyCode: "VND", openingBalance: Number(balance) };
      return initial ? updateFinanceAccount(initial.id, payload) : createFinanceAccount(payload);
    },
    onSuccess: () => {
      toast.success(initial ? "Đã cập nhật tài khoản" : "Đã thêm tài khoản");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu tài khoản.")),
  });
  return (
    <SimpleDialog
      formId="finance-account"
      title={initial ? "Sửa tài khoản tiền" : "Thêm tài khoản tiền"}
      description="Số dư đầu chỉ là điểm bắt đầu, không được tính là thu nhập."
      submit={initial ? "Cập nhật" : "Tạo tài khoản"}
      pending={mutation.isPending}
      disabled={!name.trim() || balance === ""}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
    >
      <Field label="Tên tài khoản" required><Input value={name} onChange={(event) => setName(event.target.value)} placeholder="Ví dụ: MB Bank" /></Field>
      <Field label="Loại tài khoản" required>
        <select className="field" value={type} onChange={(event) => setType(event.target.value)}>
          <option value="CASH">Tiền mặt</option><option value="BANK">Ngân hàng</option><option value="EWALLET">Ví điện tử</option><option value="SAVINGS">Tiết kiệm</option><option value="OTHER">Khác</option>
        </select>
      </Field>
      <Field label="Số dư ban đầu (VND)" required><Input type="number" value={balance} onChange={(event) => setBalance(event.target.value)} /></Field>
      {initial && <Hint>Cập nhật số dư đầu sẽ tính lại số dư hiện tại dựa trên toàn bộ lịch sử giao dịch.</Hint>}
    </SimpleDialog>
  );
}

function CategoryDialog({ initial, categories, onOpenChange, onSaved }: {
  initial: FinanceCategory | null;
  categories: FinanceCategory[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(initial?.name ?? "");
  const [kind, setKind] = useState<"EXPENSE" | "INCOME">(initial?.transactionKind ?? "EXPENSE");
  const [nature, setNature] = useState<ExpenseNature>(initial?.expenseNature ?? "ESSENTIAL_VARIABLE");
  const [parentId, setParentId] = useState(initial?.parentId ?? "");
  const mutation = useMutation({
    mutationFn: () => {
      const payload = { name, transactionKind: kind, expenseNature: kind === "EXPENSE" ? nature : null, parentId: parentId || null };
      return initial ? updateFinanceCategory(initial.id, payload) : createFinanceCategory(payload);
    },
    onSuccess: () => {
      toast.success(initial ? "Đã cập nhật danh mục" : "Đã thêm danh mục");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu danh mục.")),
  });
  const parentChoices = categories.filter((category) => category.active && category.id !== initial?.id && category.transactionKind === kind && !category.parentId);
  return (
    <SimpleDialog
      formId="finance-category"
      title={initial ? "Sửa danh mục" : "Thêm danh mục"}
      description="Danh mục cho biết tiền đi đâu; tính chất cho biết khoản chi quan trọng đến mức nào."
      submit={initial ? "Cập nhật" : "Tạo danh mục"}
      pending={mutation.isPending}
      disabled={!name.trim()}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
    >
      <Field label="Tên danh mục" required><Input value={name} onChange={(event) => setName(event.target.value)} placeholder="Ví dụ: Cà phê" /></Field>
      <Field label="Loại" required>
        <select className="field" value={kind} onChange={(event) => { setKind(event.target.value as "EXPENSE" | "INCOME"); setParentId(""); }}>
          <option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option>
        </select>
      </Field>
      {kind === "EXPENSE" && <NatureField value={nature} onChange={setNature} />}
      <Field label="Danh mục cha (không bắt buộc)">
        <select className="field" value={parentId} onChange={(event) => setParentId(event.target.value)}>
          <option value="">Không có</option>
          {parentChoices.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
        </select>
      </Field>
    </SimpleDialog>
  );
}

function BudgetDialog({ initial, month, categories, onOpenChange, onSaved }: {
  initial: FinanceBudget | null;
  month: string;
  categories: FinanceCategory[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [categoryId, setCategoryId] = useState(initial?.categoryId ?? "");
  const [amount, setAmount] = useState(initial ? String(initial.amount) : "");
  const mutation = useMutation({
    mutationFn: () => {
      const payload = { categoryId, month, amount: Number(amount), rolloverEnabled: false };
      return initial ? updateFinanceBudget(initial.id, payload) : saveFinanceBudget(payload);
    },
    onSuccess: () => {
      toast.success("Đã lưu ngân sách");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu ngân sách.")),
  });
  return (
    <SimpleDialog
      formId="finance-budget"
      title={initial ? "Sửa ngân sách tháng" : "Đặt ngân sách tháng"}
      description="FitTrack cảnh báo một lần ở mức 80% và 100%, đồng thời dự báo khả năng vượt."
      submit="Lưu ngân sách"
      pending={mutation.isPending}
      disabled={!categoryId || Number(amount) <= 0}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
    >
      <Field label="Danh mục chi tiêu" required>
        <select className="field" value={categoryId} onChange={(event) => setCategoryId(event.target.value)}>
          <option value="">Chọn danh mục</option>
          {categories.filter((category) => category.active && category.transactionKind === "EXPENSE").map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
        </select>
      </Field>
      <Field label="Số tiền tối đa (VND)" required><Input type="number" min="1" value={amount} onChange={(event) => setAmount(event.target.value)} /></Field>
    </SimpleDialog>
  );
}

function RecurringDialog({ initial, accounts, categories, onOpenChange, onSaved }: {
  initial: FinanceRecurring | null;
  accounts: FinanceAccount[];
  categories: FinanceCategory[];
  onOpenChange: (open: boolean) => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState({
    name: initial?.name ?? "",
    transactionType: initial?.transactionType ?? "EXPENSE",
    accountId: initial?.accountId ?? "",
    destinationAccountId: initial?.destinationAccountId ?? "",
    categoryId: initial?.categoryId ?? "",
    expenseNature: initial?.expenseNature ?? "FIXED_MANDATORY",
    amount: initial ? String(initial.amount) : "",
    frequency: initial?.frequency ?? "MONTHLY",
    nextDueDate: initial?.nextDueDate ?? localDate(),
    remindDaysBefore: String(initial?.remindDaysBefore ?? 1),
  });
  const mutation = useMutation({
    mutationFn: () => {
      const payload = {
        name: form.name,
        transactionType: form.transactionType,
        accountId: form.accountId,
        destinationAccountId: form.transactionType === "TRANSFER" ? form.destinationAccountId || null : null,
        categoryId: form.transactionType === "TRANSFER" ? null : form.categoryId || null,
        expenseNature: form.transactionType === "EXPENSE" ? form.expenseNature : null,
        amount: Number(form.amount),
        frequency: form.frequency,
        nextDueDate: form.nextDueDate,
        remindDaysBefore: Number(form.remindDaysBefore),
      };
      return initial ? updateFinanceRecurring(initial.id, payload) : createFinanceRecurring(payload);
    },
    onSuccess: () => {
      toast.success(initial ? "Đã cập nhật khoản định kỳ" : "Đã tạo khoản định kỳ");
      onSaved();
      onOpenChange(false);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể lưu khoản định kỳ.")),
  });
  const choices = categories.filter((category) => category.active && category.transactionKind === form.transactionType);
  const valid = form.name.trim() && Number(form.amount) > 0 && form.accountId && form.nextDueDate
    && (form.transactionType === "TRANSFER" ? form.destinationAccountId : form.categoryId);

  return (
    <SimpleDialog
      formId="finance-recurring"
      title={initial ? "Sửa khoản định kỳ" : "Thêm khoản định kỳ"}
      description="FitTrack chỉ nhắc; giao dịch thật chỉ được tạo khi bạn xác nhận đã thanh toán hoặc đã nhận."
      submit={initial ? "Cập nhật" : "Tạo khoản định kỳ"}
      pending={mutation.isPending}
      disabled={!valid}
      onOpenChange={onOpenChange}
      onSubmit={() => mutation.mutate()}
      wide
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Tên khoản" required><Input value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} placeholder="Ví dụ: Tiền nhà" /></Field>
        <Field label="Số tiền (VND)" required><Input type="number" min="1" value={form.amount} onChange={(event) => setForm({ ...form, amount: event.target.value })} /></Field>
        <Field label="Loại" required>
          <select className="field" value={form.transactionType} onChange={(event) => setForm({ ...form, transactionType: event.target.value as FinanceRecurring["transactionType"], categoryId: "", destinationAccountId: "" })}>
            <option value="EXPENSE">Chi tiêu</option><option value="INCOME">Thu nhập</option><option value="TRANSFER">Chuyển khoản</option>
          </select>
        </Field>
        <Field label="Tài khoản" required>
          <select className="field" value={form.accountId} onChange={(event) => setForm({ ...form, accountId: event.target.value, destinationAccountId: event.target.value === form.destinationAccountId ? "" : form.destinationAccountId })}>
            <option value="">Chọn tài khoản</option>
            {accounts.filter((account) => account.active).map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
          </select>
        </Field>
        {form.transactionType === "TRANSFER" ? (
          <Field label="Tài khoản nhận" required>
            <select className="field" value={form.destinationAccountId} onChange={(event) => setForm({ ...form, destinationAccountId: event.target.value })}>
              <option value="">Chọn tài khoản khác</option>
              {accounts.filter((account) => account.active && account.id !== form.accountId).map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}
            </select>
          </Field>
        ) : (
          <Field label="Danh mục" required>
            <select className="field" value={form.categoryId} onChange={(event) => {
              const selected = choices.find((category) => category.id === event.target.value);
              setForm({ ...form, categoryId: event.target.value, expenseNature: selected?.expenseNature ?? form.expenseNature });
            }}>
              <option value="">Chọn danh mục</option>
              {choices.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
            </select>
          </Field>
        )}
        {form.transactionType === "EXPENSE" && <NatureField value={form.expenseNature} onChange={(expenseNature) => setForm({ ...form, expenseNature })} />}
        <Field label="Chu kỳ" required>
          <select className="field" value={form.frequency} onChange={(event) => setForm({ ...form, frequency: event.target.value as FinanceRecurring["frequency"] })}>
            <option value="WEEKLY">Hàng tuần</option><option value="MONTHLY">Hàng tháng</option><option value="YEARLY">Hàng năm</option>
          </select>
        </Field>
        <Field label="Ngày đến hạn kế tiếp" required><Input type="date" value={form.nextDueDate} onChange={(event) => setForm({ ...form, nextDueDate: event.target.value })} /></Field>
        <Field label="Nhắc trước (ngày)" required><Input type="number" min="0" max="30" value={form.remindDaysBefore} onChange={(event) => setForm({ ...form, remindDaysBefore: event.target.value })} /></Field>
      </div>
    </SimpleDialog>
  );
}

function NatureField({ value, onChange }: { value: ExpenseNature; onChange: (value: ExpenseNature) => void }) {
  const selected = expenseNatures.find((item) => item.value === value);
  return (
    <Field label="Tính chất khoản chi" required>
      <select className="field" value={value} onChange={(event) => onChange(event.target.value as ExpenseNature)}>
        {expenseNatures.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
      </select>
      <p className="text-xs leading-5 text-muted-foreground">{selected?.description}</p>
    </Field>
  );
}

function SimpleDialog({
  formId,
  title,
  description,
  submit,
  pending,
  disabled,
  onOpenChange,
  onSubmit,
  children,
  wide = false,
}: {
  formId: string;
  title: string;
  description: string;
  submit: string;
  pending: boolean;
  disabled: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: () => void;
  children: ReactNode;
  wide?: boolean;
}) {
  return (
    <Dialog open onOpenChange={onOpenChange}>
      <DialogContent className={`max-h-[90vh] overflow-y-auto ${wide ? "sm:max-w-2xl" : "sm:max-w-xl"}`}>
        <DialogHeader><DialogTitle>{title}</DialogTitle><DialogDescription>{description}</DialogDescription></DialogHeader>
        <form id={formId} className="space-y-4" onSubmit={(event) => { event.preventDefault(); onSubmit(); }}>{children}</form>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>Hủy</Button>
          <Button type="submit" form={formId} disabled={pending || disabled}>{pending ? "Đang lưu..." : submit}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function Field({ label, required, children, className = "" }: {
  label: string;
  required?: boolean;
  children: ReactNode;
  className?: string;
}) {
  return <div className={`space-y-2 ${className}`}><Label>{label}{required && <span className="text-rose-600"> *</span>}</Label>{children}</div>;
}

function Hint({ children }: { children: ReactNode }) {
  return <div className="flex gap-2 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-950"><CircleAlert className="mt-0.5 size-4 shrink-0" />{children}</div>;
}

function Metric({ title, value, detail, icon: Icon, tone }: {
  title: string;
  value: number;
  detail?: string;
  icon: ElementType;
  tone: string;
}) {
  return (
    <Card className="border-0 shadow-sm">
      <CardContent className="p-5">
        <div className="flex items-start justify-between gap-3">
          <div><p className="text-sm text-muted-foreground">{title}</p><p className="mt-2 text-2xl font-bold tracking-tight">{money.format(value)}</p>{detail && <p className="mt-1 text-xs text-muted-foreground">{detail}</p>}</div>
          <span className={`grid size-10 shrink-0 place-items-center rounded-xl ${tone}`}><Icon className="size-5" /></span>
        </div>
      </CardContent>
    </Card>
  );
}

function ReportLine({ label, value, signed = false }: { label: string; value: number; signed?: boolean }) {
  return <div className="flex justify-between rounded-xl bg-muted/35 p-3"><span>{label}</span><strong>{signed && value > 0 ? "+" : ""}{money.format(value)}</strong></div>;
}

function InlineError({ error, fallback }: { error: unknown; fallback: string }) {
  return <div className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700">{getApiErrorMessage(error, fallback)}</div>;
}

function Empty({ text }: { text: string }) {
  return <div className="rounded-xl border border-dashed p-6 text-center text-sm text-muted-foreground">{text}</div>;
}

function useFinanceAction(action: (id: string) => Promise<unknown>, success: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: action,
    onSuccess: () => {
      toast.success(success);
      queryClient.invalidateQueries({ predicate: (query) => String(query.queryKey[0]).startsWith("finance-") });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể hoàn tất thao tác.")),
  });
}

function transactionTone(value: FinanceTransaction["type"]) {
  if (value === "INCOME") return "bg-emerald-100 text-emerald-700";
  if (value === "EXPENSE") return "bg-rose-100 text-rose-700";
  return "bg-blue-100 text-blue-700";
}

function transactionTypeLabel(value: FinanceRecurring["transactionType"]) {
  return { EXPENSE: "Chi tiêu", INCOME: "Thu nhập", TRANSFER: "Chuyển khoản" }[value];
}

function confirmRecurringLabel(value: FinanceRecurring["transactionType"]) {
  return { EXPENSE: "Đã thanh toán", INCOME: "Đã nhận", TRANSFER: "Đã chuyển" }[value];
}

function accountTypeLabel(value: string) {
  return ({ CASH: "Tiền mặt", BANK: "Ngân hàng", EWALLET: "Ví điện tử", SAVINGS: "Tiết kiệm", OTHER: "Khác" } as Record<string, string>)[value] || value;
}

function frequencyLabel(value: string) {
  return ({ WEEKLY: "Hàng tuần", MONTHLY: "Hàng tháng", YEARLY: "Hàng năm" } as Record<string, string>)[value] || value;
}

function formatDate(value: string) {
  return new Date(`${value}T00:00:00`).toLocaleDateString("vi-VN");
}

function localDate() {
  const date = new Date(Date.now() - new Date().getTimezoneOffset() * 60_000);
  return date.toISOString().slice(0, 10);
}

function localDateTime() {
  const date = new Date(Date.now() - new Date().getTimezoneOffset() * 60_000);
  return date.toISOString().slice(0, 16);
}

function endOfMonth(value: string) {
  const [year, month] = value.split("-").map(Number);
  const day = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return `${value}-${String(day).padStart(2, "0")}`;
}
