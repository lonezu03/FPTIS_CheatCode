import { describe, expect, it } from "vitest";

import type { FinanceAccount, FinanceCategory, FinanceTransaction } from "@/api/finance.api";
import {
  budgetLevel,
  buildTransactionPayload,
  endOfMonth,
  isFinanceQueryKey,
  isFinanceView,
  isTransactionDraft,
  isTransactionFormValid,
  recentCategoryIdsOf,
  recentTemplatesOf,
  resolveInitialFinanceView,
  sortAccountsByRecent,
  transactionFormFrom,
  transactionFormFromTemplate,
  type FinanceView,
  type TransactionForm,
} from "./finance-utils";

const account = (id: string, active = true): FinanceAccount =>
  ({ id, name: id, active, accountType: "BANK", currencyCode: "VND", openingBalance: 0, currentBalance: 0 }) as FinanceAccount;
const category = (id: string, transactionKind: "EXPENSE" | "INCOME" = "EXPENSE"): FinanceCategory =>
  ({ id, name: id, active: true, transactionKind, expenseNature: "ESSENTIAL_VARIABLE", parentId: null, systemCategory: false }) as FinanceCategory;
const transaction = (id: string, extra: Partial<FinanceTransaction> = {}): FinanceTransaction =>
  ({ id, type: "EXPENSE", status: "POSTED", amount: 50_000, accountId: "a1", categoryId: "c1", occurredAt: "2026-11-01T08:00:00", ...extra }) as FinanceTransaction;
const form = (extra: Partial<TransactionForm> = {}): TransactionForm => ({
  type: "EXPENSE",
  amount: "50000",
  accountId: "a1",
  destinationAccountId: "",
  categoryId: "c1",
  expenseNature: "ESSENTIAL_VARIABLE",
  occurredAt: "2026-11-25T08:30",
  merchant: "",
  note: "",
  ...extra,
});
const saved: FinanceView = { month: "2026-09", search: "cafe", type: "EXPENSE", account: "a1", category: "c1", tab: "budgets" };

describe("resolveInitialFinanceView", () => {
  it("uses the saved view when there is no link", () => {
    expect(resolveInitialFinanceView({ q: null, month: null }, saved, "2026-11")).toEqual(saved);
  });

  it("falls back to the current month and overview", () => {
    expect(resolveInitialFinanceView({ q: null, month: null }, null, "2026-11")).toEqual({
      month: "2026-11", search: "", type: "", account: "", category: "", tab: "overview",
    });
  });

  it("opens transactions for ?q= and clears other filters", () => {
    expect(resolveInitialFinanceView({ q: "phở", month: "2026-10" }, saved, "2026-11")).toEqual({
      month: "2026-10", search: "phở", type: "", account: "", category: "", tab: "transactions",
    });
  });

  it("ignores an invalid ?month=", () => {
    expect(resolveInitialFinanceView({ q: null, month: "2026-13" }, null, "2026-11").month).toBe("2026-11");
  });
});

describe("saved values", () => {
  it("validates a saved view", () => {
    expect(isFinanceView(saved)).toBe(true);
    expect(isFinanceView({ ...saved, tab: "unknown" })).toBe(false);
    expect(isFinanceView({ ...saved, month: "2026-1" })).toBe(false);
    expect(isFinanceView(null)).toBe(false);
  });

  it("validates a transaction draft", () => {
    expect(isTransactionDraft(form())).toBe(true);
    expect(isTransactionDraft(form({ occurredAt: "2026-11-25" }))).toBe(false);
    expect(isTransactionDraft({ ...form(), expenseNature: "OTHER" })).toBe(false);
  });
});

describe("transaction form", () => {
  it("builds a new form with the given time", () => {
    expect(transactionFormFrom(null, "2026-11-25T09:00")).toMatchObject({ type: "EXPENSE", amount: "", occurredAt: "2026-11-25T09:00" });
  });

  it("copies an existing transaction", () => {
    expect(transactionFormFrom(transaction("t1", { merchant: "Chợ" }))).toMatchObject({ amount: "50000", occurredAt: "2026-11-01T08:00", merchant: "Chợ" });
  });

  it("reuses a template with the current time and drops an archived account", () => {
    const result = transactionFormFromTemplate(transaction("t1"), [account("a1", false)], "2026-11-25T10:00");
    expect(result).toMatchObject({ accountId: "", occurredAt: "2026-11-25T10:00", categoryId: "c1" });
  });

  it("sends category and nature only for the matching type", () => {
    expect(buildTransactionPayload(form())).toMatchObject({ amount: 50_000, categoryId: "c1", expenseNature: "ESSENTIAL_VARIABLE", destinationAccountId: null });
    expect(buildTransactionPayload(form({ type: "INCOME" }))).toMatchObject({ expenseNature: null, categoryId: "c1" });
    expect(buildTransactionPayload(form({ type: "TRANSFER", destinationAccountId: "a2" }))).toMatchObject({ categoryId: null, expenseNature: null, destinationAccountId: "a2" });
  });

  it("checks amount, accounts and category", () => {
    const accounts = [account("a1"), account("a2")];
    const choices = [category("c1")];
    expect(isTransactionFormValid(form(), accounts, choices)).toBe(true);
    expect(isTransactionFormValid(form({ amount: "0" }), accounts, choices)).toBe(false);
    expect(isTransactionFormValid(form({ categoryId: "x" }), accounts, choices)).toBe(false);
    expect(isTransactionFormValid(form({ type: "TRANSFER", destinationAccountId: "a1" }), accounts, choices)).toBe(false);
    expect(isTransactionFormValid(form({ type: "TRANSFER", destinationAccountId: "a2" }), accounts, choices)).toBe(true);
  });
});

describe("recent items", () => {
  const items = [
    transaction("1", { categoryId: "c2" }),
    transaction("2", { categoryId: "c1", status: "VOID" }),
    transaction("3", { categoryId: "c2" }),
    transaction("4", { categoryId: "c3" }),
  ];

  it("lists distinct posted categories", () => {
    expect(recentCategoryIdsOf(items)).toEqual(["c2", "c3"]);
  });

  it("offers up to five posted templates", () => {
    expect(recentTemplatesOf(items).map((item) => item.id)).toEqual(["1", "3", "4"]);
  });

  it("puts recently used accounts first and hides archived ones", () => {
    const sorted = sortAccountsByRecent([account("a1"), account("a2"), account("a3", false), account("a4")], ["a4", "a2"]);
    expect(sorted.map((item) => item.id)).toEqual(["a4", "a2", "a1"]);
  });
});

describe("misc helpers", () => {
  it("finds the last day of a month", () => {
    expect(endOfMonth("2026-02")).toBe("2026-02-28");
    expect(endOfMonth("2028-02")).toBe("2028-02-29");
    expect(endOfMonth("2026-11")).toBe("2026-11-30");
  });

  it("grades budget usage", () => {
    expect(budgetLevel(79.9)).toBe("normal");
    expect(budgetLevel(80)).toBe("warning");
    expect(budgetLevel(100)).toBe("over");
  });

  it("matches finance query keys", () => {
    expect(isFinanceQueryKey(["finance-dashboard", "2026-11"])).toBe(true);
    expect(isFinanceQueryKey(["lunch"])).toBe(false);
  });
});
