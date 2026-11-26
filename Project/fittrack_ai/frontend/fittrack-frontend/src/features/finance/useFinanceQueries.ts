import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import {
  archiveFinanceAccount,
  archiveFinanceCategory,
  archiveFinanceRecurring,
  confirmFinanceRecurring,
  deleteFinanceBudget,
  getFinanceAccounts,
  getFinanceBudgets,
  getFinanceCategories,
  getFinanceDashboard,
  getFinanceRecurring,
  getFinanceReport,
  getFinanceTransactions,
  snoozeFinanceRecurring,
  voidFinanceTransaction,
} from "@/api/finance.api";
import { getApiErrorMessage } from "@/lib/format";
import { TRANSACTION_PAGE_SIZE, endOfMonth, isFinanceQueryKey, monthDate } from "./finance-utils";

type TransactionFilters = {
  page: number;
  search: string;
  typeFilter: string;
  accountFilter: string;
  categoryFilter: string;
};

/** Every finance read used by the screen. Query keys are shared with quick add and the dashboard. */
export function useFinanceData(month: string, filters: TransactionFilters) {
  const { page, search, typeFilter, accountFilter, categoryFilter } = filters;
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
    queryKey: ["finance-transactions", month, page, search, typeFilter, accountFilter, categoryFilter],
    queryFn: () =>
      getFinanceTransactions({
        from: selectedMonth,
        to: endOfMonth(month),
        page,
        size: TRANSACTION_PAGE_SIZE,
        q: search || undefined,
        type: typeFilter || undefined,
        accountId: accountFilter || undefined,
        categoryId: categoryFilter || undefined,
      }),
  });
  return { selectedMonth, dashboard, accounts, categories, budgets, recurring, report, transactions };
}

/** Refreshes every "finance-" query (dashboard widgets included). */
export function useFinanceRefresh() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ predicate: (query) => isFinanceQueryKey(query.queryKey) });
}

function useFinanceAction(action: (id: string) => Promise<unknown>, success: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: action,
    onSuccess: () => {
      toast.success(success);
      queryClient.invalidateQueries({ predicate: (query) => isFinanceQueryKey(query.queryKey) });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể hoàn tất thao tác.")),
  });
}

/** One-click row actions (void, delete, archive, confirm, snooze). */
export function useFinanceActions() {
  return {
    voidTransaction: useFinanceAction(voidFinanceTransaction, "Đã hủy giao dịch"),
    deleteBudget: useFinanceAction(deleteFinanceBudget, "Đã xóa ngân sách"),
    confirmRecurring: useFinanceAction(confirmFinanceRecurring, "Đã ghi nhận khoản định kỳ"),
    snoozeRecurring: useFinanceAction(snoozeFinanceRecurring, "Sẽ nhắc lại vào ngày mai"),
    archiveRecurring: useFinanceAction(archiveFinanceRecurring, "Đã ngừng khoản định kỳ"),
    archiveAccount: useFinanceAction(archiveFinanceAccount, "Đã lưu trữ tài khoản"),
    archiveCategory: useFinanceAction(archiveFinanceCategory, "Đã lưu trữ danh mục"),
  };
}

export type FinanceActions = ReturnType<typeof useFinanceActions>;
