import { cleanup, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import FinancePage from "./FinancePage";
import {
  getFinanceAccounts,
  getFinanceBudgets,
  getFinanceCategories,
  getFinanceDashboard,
  getFinanceRecurring,
  getFinanceReport,
  getFinanceTransactions,
  type FinanceDashboard,
} from "@/api/finance.api";

vi.mock("@/store/auth.store", () => ({ useAuthStore: (select: (state: unknown) => unknown) => select({ user: { userId: "me" } }) }));
vi.mock("@/api/finance.api", () => ({
  getFinanceDashboard: vi.fn(),
  getFinanceAccounts: vi.fn(),
  getFinanceCategories: vi.fn(),
  getFinanceBudgets: vi.fn(),
  getFinanceRecurring: vi.fn(),
  getFinanceReport: vi.fn(),
  getFinanceTransactions: vi.fn(),
  voidFinanceTransaction: vi.fn(),
  deleteFinanceBudget: vi.fn(),
  confirmFinanceRecurring: vi.fn(),
  snoozeFinanceRecurring: vi.fn(),
  archiveFinanceRecurring: vi.fn(),
  archiveFinanceAccount: vi.fn(),
  archiveFinanceCategory: vi.fn(),
  analyzeFinanceReceipt: vi.fn(),
  createFinanceTransaction: vi.fn(),
  updateFinanceTransaction: vi.fn(),
}));

const dashboard = {
  month: "2026-10-01", totalBalance: 1_000_000, income: 0, expense: 0, netSaving: 0, savingRate: 0,
  mandatoryCommitted: 0, mandatoryPaid: 0, mandatoryRemaining: 0, savingCommitted: 0, trueExpensePreparation: 0,
  flexibleAvailable: 0, accounts: [], budgets: [], upcoming: [], topCategories: [], natureBreakdown: [], insight: "Ổn định.",
} as FinanceDashboard;
const emptyPage = { content: [], page: 0, size: 15, totalElements: 0, totalPages: 0, first: true, last: true };

function mount(url: string) {
  return render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>
      <MemoryRouter initialEntries={[url]}>
        <FinancePage />
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

afterEach(cleanup);
beforeEach(() => {
  vi.clearAllMocks();
  localStorage.clear();
  vi.mocked(getFinanceDashboard).mockResolvedValue(dashboard);
  vi.mocked(getFinanceAccounts).mockResolvedValue([
    { id: "a1", name: "Tiền mặt", accountType: "CASH", currencyCode: "VND", openingBalance: 0, currentBalance: 1_000_000, active: true },
  ]);
  vi.mocked(getFinanceCategories).mockResolvedValue([
    { id: "c1", name: "Ăn uống", transactionKind: "EXPENSE", expenseNature: "ESSENTIAL_VARIABLE", parentId: null, icon: null, active: true, systemCategory: false },
  ]);
  vi.mocked(getFinanceBudgets).mockResolvedValue([]);
  vi.mocked(getFinanceRecurring).mockResolvedValue([]);
  vi.mocked(getFinanceReport).mockRejectedValue(new Error("offline"));
  vi.mocked(getFinanceTransactions).mockResolvedValue(emptyPage);
});

describe("FinancePage", () => {
  it("opens matching transactions from a quick-search link", async () => {
    mount("/finance?q=phở&month=2026-10");
    expect(await screen.findByRole("tab", { name: "Giao dịch", selected: true })).toBeInTheDocument();
    expect(screen.getByPlaceholderText("Tìm nơi chi, ghi chú...")).toHaveValue("phở");
    expect(screen.getByLabelText("Tháng tài chính")).toHaveValue("2026-10");
    await waitFor(() => expect(getFinanceTransactions).toHaveBeenCalledWith(expect.objectContaining({
      from: "2026-10-01", to: "2026-10-31", q: "phở", page: 0, size: 15,
    })));
    expect(await screen.findByText("Không có giao dịch phù hợp.")).toBeInTheDocument();
  });

  it("opens the new transaction dialog for ?action=new", async () => {
    mount("/finance?action=new");
    expect(await screen.findByRole("dialog", { name: "Ghi giao dịch nhanh" })).toBeInTheDocument();
  });

  it("shows a skeleton while transactions load", async () => {
    vi.mocked(getFinanceTransactions).mockReturnValue(new Promise(() => {}));
    mount("/finance?q=x");
    expect(await screen.findByRole("status", { name: "Đang tải" })).toBeInTheDocument();
    expect(screen.queryByText("Không có giao dịch phù hợp.")).toBeNull();
  });
});
