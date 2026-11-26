import ErrorState from "@/components/common/ErrorState";
import PageLoading from "@/components/common/PageLoading";
import BalanceReconciliationDialog from "@/components/finance/BalanceReconciliationDialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { getApiErrorMessage } from "@/lib/format";
import AccountDialog from "@/features/finance/AccountDialog";
import BudgetDialog from "@/features/finance/BudgetDialog";
import BudgetsTab from "@/features/finance/BudgetsTab";
import CategoryDialog from "@/features/finance/CategoryDialog";
import { FinanceHeader, FinanceOnboarding, FinanceSummary } from "@/features/finance/FinanceSummary";
import OverviewTab from "@/features/finance/OverviewTab";
import RecurringDialog from "@/features/finance/RecurringDialog";
import RecurringTab from "@/features/finance/RecurringTab";
import SettingsTab from "@/features/finance/SettingsTab";
import TransactionDialog from "@/features/finance/TransactionDialog";
import TransactionsTab from "@/features/finance/TransactionsTab";
import { recentCategoryIdsOf, recentTemplatesOf } from "@/features/finance/finance-utils";
import { useFinanceActions, useFinanceData, useFinanceRefresh } from "@/features/finance/useFinanceQueries";
import { useFinanceDialogs, useFinanceView } from "@/features/finance/useFinanceView";

export default function FinancePage() {
  const view = useFinanceView();
  const dialogs = useFinanceDialogs();
  const { selectedMonth, dashboard, accounts, categories, budgets, recurring, report, transactions } = useFinanceData(view.month, view);
  const actions = useFinanceActions();
  const refresh = useFinanceRefresh();

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
  const hasExpenseCategory = categoryList.some((item) => item.active && item.transactionKind === "EXPENSE");
  const transactionItems = transactions.data?.content ?? [];
  const closeWhen = (clear: () => void) => (open: boolean) => { if (!open) clear(); };

  return (
    <div className="space-y-6">
      <FinanceHeader
        month={view.month}
        canCreate={activeAccounts.length > 0 && hasExpenseCategory}
        onMonthChange={view.changeMonth}
        onReconcile={() => view.setTab("settings")}
        onNewTransaction={() => dialogs.setTransaction("new")}
      />

      {activeAccounts.length === 0 && <FinanceOnboarding onCreateAccount={() => dialogs.setAccount("new")} />}

      <FinanceSummary data={data} />

      <Tabs value={view.tab} onValueChange={view.setTab} className="gap-4">
        <TabsList className="flex w-full max-w-full justify-start overflow-x-auto [&>button]:shrink-0">
          <TabsTrigger value="overview">Tổng quan</TabsTrigger>
          <TabsTrigger value="transactions">Giao dịch</TabsTrigger>
          <TabsTrigger value="budgets">Ngân sách</TabsTrigger>
          <TabsTrigger value="recurring">Định kỳ</TabsTrigger>
          <TabsTrigger value="settings">Thiết lập</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="grid gap-4 lg:grid-cols-2">
          <OverviewTab
            data={data}
            activeAccounts={activeAccounts}
            report={report}
            onReconcile={dialogs.setReconcile}
            onAddAccount={() => dialogs.setAccount("new")}
          />
        </TabsContent>

        <TabsContent value="transactions">
          <TransactionsTab
            view={view}
            transactions={transactions}
            accounts={accountList}
            categories={categoryList}
            canCreate={activeAccounts.length > 0}
            onNew={() => dialogs.setTransaction("new")}
            onEdit={dialogs.setTransaction}
            onVoid={(id) => actions.voidTransaction.mutate(id)}
          />
        </TabsContent>

        <TabsContent value="budgets">
          <BudgetsTab
            budgets={budgets}
            onAdd={() => dialogs.setBudget("new")}
            onEdit={dialogs.setBudget}
            onDelete={(id) => actions.deleteBudget.mutate(id)}
          />
        </TabsContent>

        <TabsContent value="recurring">
          <RecurringTab
            recurring={recurring}
            onAdd={() => dialogs.setRecurring("new")}
            onEdit={dialogs.setRecurring}
            onConfirmPaid={(id) => actions.confirmRecurring.mutate(id)}
            onSnooze={(id) => actions.snoozeRecurring.mutate(id)}
            onArchive={(id) => actions.archiveRecurring.mutate(id)}
          />
        </TabsContent>

        <TabsContent value="settings" className="grid gap-4 lg:grid-cols-2">
          <SettingsTab
            accounts={accountList}
            categories={categoryList}
            onAddAccount={() => dialogs.setAccount("new")}
            onEditAccount={dialogs.setAccount}
            onReconcile={dialogs.setReconcile}
            onArchiveAccount={(id) => actions.archiveAccount.mutate(id)}
            onAddCategory={() => dialogs.setCategory("new")}
            onEditCategory={dialogs.setCategory}
            onArchiveCategory={(id) => actions.archiveCategory.mutate(id)}
          />
        </TabsContent>
      </Tabs>

      {dialogs.transaction && (
        <TransactionDialog
          initial={dialogs.transaction === "new" ? null : dialogs.transaction}
          accounts={accountList}
          categories={categoryList}
          recentCategoryIds={recentCategoryIdsOf(transactionItems)}
          templates={recentTemplatesOf(transactionItems)}
          onOpenChange={closeWhen(() => dialogs.setTransaction(null))}
          onSaved={refresh}
        />
      )}
      {dialogs.account && (
        <AccountDialog
          initial={dialogs.account === "new" ? null : dialogs.account}
          onOpenChange={closeWhen(() => dialogs.setAccount(null))}
          onSaved={refresh}
        />
      )}
      {dialogs.reconcile && <BalanceReconciliationDialog key={dialogs.reconcile.id} account={dialogs.reconcile} onClose={() => dialogs.setReconcile(null)} />}
      {dialogs.category && (
        <CategoryDialog
          initial={dialogs.category === "new" ? null : dialogs.category}
          categories={categoryList}
          onOpenChange={closeWhen(() => dialogs.setCategory(null))}
          onSaved={refresh}
        />
      )}
      {dialogs.budget && (
        <BudgetDialog
          initial={dialogs.budget === "new" ? null : dialogs.budget}
          month={selectedMonth}
          categories={categoryList}
          onOpenChange={closeWhen(() => dialogs.setBudget(null))}
          onSaved={refresh}
        />
      )}
      {dialogs.recurring && (
        <RecurringDialog
          initial={dialogs.recurring === "new" ? null : dialogs.recurring}
          accounts={accountList}
          categories={categoryList}
          onOpenChange={closeWhen(() => dialogs.setRecurring(null))}
          onSaved={refresh}
        />
      )}
    </div>
  );
}
