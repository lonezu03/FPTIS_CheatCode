import type {
  ExpenseNature,
  FinanceAccount,
  FinanceCategory,
  FinanceRecurring,
  FinanceTransaction,
  FinanceTransactionInput,
} from "@/api/finance.api";

export const money = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
  maximumFractionDigits: 0,
});

export const expenseNatures: Array<{
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

export const natureLabels: Record<string, string> = Object.fromEntries([
  ...expenseNatures.map((item) => [item.value, item.label]),
  ["UNCLASSIFIED", "Chưa phân loại"],
]);

export const FINANCE_TABS = ["overview", "transactions", "budgets", "recurring", "settings"] as const;
export const TRANSACTION_PAGE_SIZE = 15;
const MONTH_PATTERN = /^\d{4}-(0[1-9]|1[0-2])$/;
const DATE_TIME_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/;

export function isMonthValue(value: string | null | undefined): value is string {
  return typeof value === "string" && MONTH_PATTERN.test(value);
}

export function isDateTimeValue(value: string | null | undefined): value is string {
  return typeof value === "string" && DATE_TIME_PATTERN.test(value);
}

// ---- Saved view (filters + tab) -------------------------------------------------

export type FinanceView = { month: string; search: string; type: string; account: string; category: string; tab: string };

export function isFinanceView(value: unknown): value is FinanceView {
  if (!value || typeof value !== "object") return false;
  const view = value as FinanceView;
  return isMonthValue(view.month)
    && typeof view.search === "string"
    && ["", "EXPENSE", "INCOME", "TRANSFER"].includes(view.type)
    && typeof view.account === "string"
    && typeof view.category === "string"
    && (FINANCE_TABS as readonly string[]).includes(view.tab);
}

/**
 * Initial filters: a quick-search link (`?q=…&month=…`) wins over the saved view and
 * opens the matching transactions with every other filter cleared.
 */
export function resolveInitialFinanceView(
  link: { q: string | null; month: string | null },
  preferences: FinanceView | null,
  currentMonth: string,
): FinanceView {
  const linkedSearch = link.q;
  return {
    month: isMonthValue(link.month) ? link.month : preferences?.month ?? currentMonth,
    search: linkedSearch ?? preferences?.search ?? "",
    type: linkedSearch ? "" : preferences?.type ?? "",
    account: linkedSearch ? "" : preferences?.account ?? "",
    category: linkedSearch ? "" : preferences?.category ?? "",
    tab: linkedSearch ? "transactions" : preferences?.tab ?? "overview",
  };
}

// ---- Transaction form -------------------------------------------------------------

export type TransactionForm = {
  type: FinanceTransactionInput["type"];
  amount: string;
  accountId: string;
  destinationAccountId: string;
  categoryId: string;
  expenseNature: ExpenseNature;
  occurredAt: string;
  merchant: string;
  note: string;
};

export function isTransactionDraft(value: unknown): value is TransactionForm {
  if (!value || typeof value !== "object") return false;
  const draft = value as TransactionForm;
  return ["EXPENSE", "INCOME", "TRANSFER"].includes(draft.type)
    && ["amount", "accountId", "destinationAccountId", "categoryId", "occurredAt", "merchant", "note"]
      .every((key) => typeof draft[key as keyof TransactionForm] === "string")
    && expenseNatures.some((nature) => nature.value === draft.expenseNature)
    && isDateTimeValue(draft.occurredAt);
}

export function transactionFormFrom(initial: FinanceTransaction | null, now = localDateTime()): TransactionForm {
  return {
    type: initial?.type ?? "EXPENSE",
    amount: initial ? String(initial.amount) : "",
    accountId: initial?.accountId ?? "",
    destinationAccountId: initial?.destinationAccountId ?? "",
    categoryId: initial?.categoryId ?? "",
    expenseNature: initial?.expenseNature ?? "ESSENTIAL_VARIABLE",
    occurredAt: initial ? initial.occurredAt.slice(0, 16) : now,
    merchant: initial?.merchant ?? "",
    note: initial?.note ?? "",
  };
}

/** Reuse a recent transaction as a new one: keep its values but use the current time. */
export function transactionFormFromTemplate(
  template: FinanceTransaction,
  accounts: FinanceAccount[],
  now = localDateTime(),
): TransactionForm {
  return {
    type: template.type,
    amount: String(template.amount),
    accountId: accounts.some((account) => account.active && account.id === template.accountId) ? template.accountId : "",
    destinationAccountId: template.destinationAccountId ?? "",
    categoryId: template.categoryId ?? "",
    expenseNature: template.expenseNature ?? "ESSENTIAL_VARIABLE",
    occurredAt: now,
    merchant: template.merchant ?? "",
    note: template.note ?? "",
  };
}

export function hasDraftContent(form: TransactionForm): boolean {
  return Boolean(form.amount || form.merchant || form.note);
}

export function buildTransactionPayload(form: TransactionForm): FinanceTransactionInput {
  return {
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
}

/** Active categories that match the transaction type. */
export function categoryChoices(categories: FinanceCategory[], type: string): FinanceCategory[] {
  return categories.filter((category) => category.active && category.transactionKind === type);
}

export function isTransactionFormValid(
  form: TransactionForm,
  accounts: FinanceAccount[],
  choices: FinanceCategory[],
): boolean {
  const isActive = (id: string) => accounts.some((account) => account.active && account.id === id);
  return Number.isFinite(Number(form.amount))
    && Number(form.amount) > 0
    && isActive(form.accountId)
    && Boolean(form.occurredAt)
    && (form.type === "TRANSFER"
      ? form.destinationAccountId !== form.accountId && isActive(form.destinationAccountId)
      : choices.some((category) => category.id === form.categoryId));
}

/** Active accounts, the most recently used ones first (stable order otherwise). */
export function sortAccountsByRecent(accounts: FinanceAccount[], recentAccountIds: string[]): FinanceAccount[] {
  const rank = (id: string) => {
    const index = recentAccountIds.indexOf(id);
    return index < 0 ? Infinity : index;
  };
  return accounts.filter((account) => account.active).sort((left, right) => rank(left.id) - rank(right.id));
}

/** Up to five distinct categories used by posted transactions, newest first. */
export function recentCategoryIdsOf(transactions: FinanceTransaction[]): string[] {
  return Array.from(new Set(
    transactions
      .filter((item) => item.status === "POSTED" && item.categoryId)
      .map((item) => item.categoryId as string),
  )).slice(0, 5);
}

/** Up to five posted transactions offered as "reuse" templates. */
export function recentTemplatesOf(transactions: FinanceTransaction[]): FinanceTransaction[] {
  return transactions.filter((transaction) => transaction.status === "POSTED").slice(0, 5);
}

export type BudgetLevel = "over" | "warning" | "normal";

export function budgetLevel(percent: number): BudgetLevel {
  if (percent >= 100) return "over";
  if (percent >= 80) return "warning";
  return "normal";
}

export function isFinanceQueryKey(key: readonly unknown[]): boolean {
  return String(key[0]).startsWith("finance-");
}

// ---- Labels -------------------------------------------------------------------------

export function transactionTone(value: FinanceTransaction["type"]) {
  if (value === "INCOME") return "bg-emerald-100 text-emerald-700";
  if (value === "EXPENSE") return "bg-rose-100 text-rose-700";
  return "bg-blue-100 text-blue-700";
}

export function transactionTypeLabel(value: FinanceRecurring["transactionType"]) {
  return { EXPENSE: "Chi tiêu", INCOME: "Thu nhập", TRANSFER: "Chuyển khoản" }[value];
}

export function confirmRecurringLabel(value: FinanceRecurring["transactionType"]) {
  return { EXPENSE: "Đã thanh toán", INCOME: "Đã nhận", TRANSFER: "Đã chuyển" }[value];
}

export function accountTypeLabel(value: string) {
  return ({ CASH: "Tiền mặt", BANK: "Ngân hàng", EWALLET: "Ví điện tử", SAVINGS: "Tiết kiệm", OTHER: "Khác" } as Record<string, string>)[value] || value;
}

export function frequencyLabel(value: string) {
  return ({ WEEKLY: "Hàng tuần", MONTHLY: "Hàng tháng", YEARLY: "Hàng năm" } as Record<string, string>)[value] || value;
}

// ---- Dates --------------------------------------------------------------------------

export function formatDate(value: string) {
  return new Date(`${value}T00:00:00`).toLocaleDateString("vi-VN");
}

export function localDate() {
  const date = new Date(Date.now() - new Date().getTimezoneOffset() * 60_000);
  return date.toISOString().slice(0, 10);
}

export function localDateTime() {
  const date = new Date(Date.now() - new Date().getTimezoneOffset() * 60_000);
  return date.toISOString().slice(0, 16);
}

export const monthDate = (value: string) => `${value}-01`;

export function endOfMonth(value: string) {
  const [year, month] = value.split("-").map(Number);
  const day = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return `${value}-${String(day).padStart(2, "0")}`;
}

/** Month shown when nothing else is chosen (computed once, like the original page). */
export const monthNow = localDate().slice(0, 7);
