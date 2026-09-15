import api from "./axios";

export type FinanceAccount = {
  id: string; name: string; accountType: string; currencyCode: string;
  openingBalance: number; currentBalance: number; active: boolean;
};
export type FinanceCategory = {
  id: string; name: string; transactionKind: "EXPENSE" | "INCOME";
  expenseNature: ExpenseNature | null; parentId: string | null; icon: string | null;
  active: boolean; systemCategory: boolean;
};
export type ExpenseNature = "FIXED_MANDATORY" | "ESSENTIAL_VARIABLE" | "TRUE_EXPENSE" | "SAVING" | "DISCRETIONARY";
export type FinanceTransaction = {
  id: string; type: "EXPENSE" | "INCOME" | "TRANSFER"; amount: number; occurredAt: string;
  accountId: string; accountName: string; destinationAccountId: string | null;
  destinationAccountName: string | null; categoryId: string | null; categoryName: string | null;
  expenseNature: ExpenseNature | null; merchant: string | null; note: string | null; status: "POSTED" | "VOID";
};
export type FinanceBudget = {
  id: string; categoryId: string; categoryName: string; month: string; amount: number;
  spent: number; remaining: number; percent: number; projected: number;
  projectedOver: boolean; rolloverEnabled: boolean;
};
export type FinanceRecurring = {
  id: string; name: string; transactionType: "EXPENSE" | "INCOME" | "TRANSFER";
  accountId: string; accountName: string; destinationAccountId: string | null;
  categoryId: string | null; categoryName: string | null; expenseNature: ExpenseNature | null;
  amount: number; frequency: "WEEKLY" | "MONTHLY" | "YEARLY"; nextDueDate: string;
  remindDaysBefore: number; active: boolean;
};
export type CategoryTotal = { categoryId: string; categoryName: string; expenseNature: ExpenseNature | null; amount: number };
export type NatureTotal = { expenseNature: ExpenseNature | "UNCLASSIFIED"; amount: number; percentOfIncome: number };
export type FinanceDashboard = {
  month: string; totalBalance: number; income: number; expense: number; netSaving: number; savingRate: number;
  mandatoryCommitted: number; mandatoryPaid: number; mandatoryRemaining: number; savingCommitted: number;
  trueExpensePreparation: number; flexibleAvailable: number; accounts: FinanceAccount[]; budgets: FinanceBudget[]; upcoming: FinanceRecurring[];
  topCategories: CategoryTotal[]; natureBreakdown: NatureTotal[]; insight: string;
};
export type FinanceReport = {
  month: string; income: number; expense: number; netSaving: number; savingRate: number;
  previousExpense: number; expenseChange: number; categories: CategoryTotal[]; natureBreakdown: NatureTotal[];
};
export type PageResponse<T> = { content: T[]; page: number; size: number; totalElements: number; totalPages: number; first: boolean; last: boolean };

export type FinanceAccountInput = {
  name: string;
  accountType: string;
  currencyCode: string;
  openingBalance: number;
};

export type FinanceCategoryInput = {
  name: string;
  transactionKind: "EXPENSE" | "INCOME";
  expenseNature: ExpenseNature | null;
  parentId?: string | null;
  icon?: string;
};

export type FinanceTransactionInput = {
  type: "EXPENSE" | "INCOME" | "TRANSFER";
  amount: number;
  accountId: string;
  destinationAccountId: string | null;
  categoryId: string | null;
  expenseNature: ExpenseNature | null;
  occurredAt: string;
  merchant: string;
  note: string;
};

export type FinanceRecurringInput = {
  name: string;
  transactionType: "EXPENSE" | "INCOME" | "TRANSFER";
  accountId: string;
  destinationAccountId: string | null;
  categoryId: string | null;
  expenseNature: ExpenseNature | null;
  amount: number;
  frequency: "WEEKLY" | "MONTHLY" | "YEARLY";
  nextDueDate: string;
  remindDaysBefore: number;
};

export const getFinanceDashboard = async (month: string) => (await api.get<FinanceDashboard>("/finance/dashboard", { params: { month } })).data;
export const getFinanceReport = async (month: string) => (await api.get<FinanceReport>("/finance/reports/monthly", { params: { month } })).data;
export const getFinanceAccounts = async () => (await api.get<FinanceAccount[]>("/finance/accounts")).data;
export const createFinanceAccount = async (payload: FinanceAccountInput) => (await api.post<FinanceAccount>("/finance/accounts", payload)).data;
export const updateFinanceAccount = async (id: string, payload: FinanceAccountInput) => (await api.put<FinanceAccount>(`/finance/accounts/${id}`, payload)).data;
export const archiveFinanceAccount = async (id: string) => { await api.delete(`/finance/accounts/${id}`); };
export const getFinanceCategories = async () => (await api.get<FinanceCategory[]>("/finance/categories")).data;
export const createFinanceCategory = async (payload: FinanceCategoryInput) => (await api.post<FinanceCategory>("/finance/categories", payload)).data;
export const updateFinanceCategory = async (id: string, payload: FinanceCategoryInput) => (await api.put<FinanceCategory>(`/finance/categories/${id}`, payload)).data;
export const archiveFinanceCategory = async (id: string) => { await api.delete(`/finance/categories/${id}`); };
export const getFinanceTransactions = async (params: Record<string, string | number | undefined>) => (await api.get<PageResponse<FinanceTransaction>>("/finance/transactions", { params })).data;
export const createFinanceTransaction = async (payload: FinanceTransactionInput) => (await api.post<FinanceTransaction>("/finance/transactions", payload)).data;
export const updateFinanceTransaction = async (id: string, payload: FinanceTransactionInput) => (await api.put<FinanceTransaction>(`/finance/transactions/${id}`, payload)).data;
export const voidFinanceTransaction = async (id: string) => { await api.delete(`/finance/transactions/${id}`); };
export const getFinanceBudgets = async (month: string) => (await api.get<FinanceBudget[]>("/finance/budgets", { params: { month } })).data;
export const saveFinanceBudget = async (payload: { categoryId: string; month: string; amount: number; rolloverEnabled: boolean }) => (await api.post<FinanceBudget>("/finance/budgets", payload)).data;
export const updateFinanceBudget = async (id: string, payload: { categoryId: string; month: string; amount: number; rolloverEnabled: boolean }) => (await api.put<FinanceBudget>(`/finance/budgets/${id}`, payload)).data;
export const deleteFinanceBudget = async (id: string) => { await api.delete(`/finance/budgets/${id}`); };
export const getFinanceRecurring = async () => (await api.get<FinanceRecurring[]>("/finance/recurring")).data;
export const createFinanceRecurring = async (payload: FinanceRecurringInput) => (await api.post<FinanceRecurring>("/finance/recurring", payload)).data;
export const updateFinanceRecurring = async (id: string, payload: FinanceRecurringInput) => (await api.put<FinanceRecurring>(`/finance/recurring/${id}`, payload)).data;
export const archiveFinanceRecurring = async (id: string) => { await api.delete(`/finance/recurring/${id}`); };
export const confirmFinanceRecurring = async (id: string) => (await api.post<FinanceTransaction>(`/finance/recurring/${id}/confirm`)).data;
export const snoozeFinanceRecurring = async (id: string) => (await api.post<FinanceRecurring>(`/finance/recurring/${id}/snooze`)).data;
