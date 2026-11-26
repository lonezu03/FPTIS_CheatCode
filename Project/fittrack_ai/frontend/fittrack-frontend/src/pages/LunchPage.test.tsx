import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";

import LunchPage from "./LunchPage";
import { getLunchOrderHistory, getLunchPeople, getTodayLunch, type LunchMenu } from "@/api/lunch.api";

vi.mock("sonner", () => ({ toast: { success: vi.fn(), info: vi.fn(), error: vi.fn() } }));
vi.mock("@/api/lunch.api", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/api/lunch.api")>()),
  getTodayLunch: vi.fn(), getLunchPeople: vi.fn(), getLunchOrderHistory: vi.fn(), getLunchWalletTransactions: vi.fn(),
  createLunchOrderBatch: vi.fn(), updateLunchOrder: vi.fn(), deleteLunchOrder: vi.fn(),
}));

const menu = {
  id: "m1", menuDate: "2026-11-26", orderLabel: "Cơm trưa thứ Năm", vendorName: "Quán A", cutoffAt: "2099-11-26T10:30:00",
  price: 35000, status: "OPEN", acceptingOrders: true, summarized: false, canReplace: true,
  regularItems: [], specialItems: [], extraItems: [], totalOrders: 0, unpaidOrders: 0,
} as LunchMenu;

function show(path = "/lunch") {
  render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })}>
      <MemoryRouter initialEntries={[path]}><LunchPage /></MemoryRouter>
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  vi.mocked(getTodayLunch).mockResolvedValue({ menu, walletBalance: 0, outstandingDebt: 0, canOrder: true, blockReason: null, myMealOrder: null, ordersPlacedByMe: [] });
  vi.mocked(getLunchPeople).mockResolvedValue([]);
  vi.mocked(getLunchOrderHistory).mockResolvedValue([]);
});
afterEach(() => { cleanup(); vi.clearAllMocks(); });

describe("LunchPage", () => {
  it("hiển thị menu hôm nay và trạng thái chưa đặt phần", async () => {
    show();
    expect(await screen.findByText("Cơm trưa thứ Năm")).toBeInTheDocument();
    expect(await screen.findByText("Bạn chưa đặt phần ăn nào hôm nay")).toBeInTheDocument();
    expect(getLunchOrderHistory).not.toHaveBeenCalled();
  });

  it("?tab=history chỉ tải lịch sử khi mở tab", async () => {
    show("/lunch?tab=history");
    expect(await screen.findByText("Chưa có lịch sử")).toBeInTheDocument();
    expect(getLunchOrderHistory).toHaveBeenCalledTimes(1);
  });
});
