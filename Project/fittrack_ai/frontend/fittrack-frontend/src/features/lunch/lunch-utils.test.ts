import { describe, expect, it } from "vitest";

import type { LunchMenu, LunchMenuItem, LunchOrder, LunchTodayResponse } from "@/api/lunch.api";
import {
  collectTodayOrders,
  describeCartPortion,
  findMainItems,
  getTransactionLabel,
  portionTotal,
  portionValidationError,
  removeOneExtra,
  resolveAvailableMenus,
  resolveLunchTab,
  sumNutrition,
  toggleNoteSuggestion,
} from "./lunch-utils";

const item = (id: string, overrides: Partial<LunchMenuItem> = {}): LunchMenuItem => ({
  id, name: `Món ${id}`, type: "REGULAR", sortOrder: 1, averageRating: 0, reviewCount: 0, ...overrides,
});
const menu = (overrides: Partial<LunchMenu> = {}): LunchMenu => ({
  id: "m1", menuDate: "2026-11-26", orderLabel: "Cơm trưa", vendorName: "Quán A", cutoffAt: "2026-11-26T10:30:00",
  price: 35000, status: "OPEN", acceptingOrders: true, summarized: false, canReplace: true,
  regularItems: [item("a", { calories: 300, protein: 20 }), item("b", { calories: 200, fat: 5 })],
  specialItems: [item("s", { type: "SPECIAL" })],
  extraItems: [item("tra", { type: "EXTRA", name: "Trà đào", unitPrice: 45000 })],
  totalOrders: 0, unpaidOrders: 0, ...overrides,
});
const order = (id: string, status = "ACTIVE") => ({ id, status } as LunchOrder);
const today = (overrides: Partial<LunchTodayResponse> = {}): LunchTodayResponse => ({
  menu: menu(), walletBalance: 0, outstandingDebt: 0, canOrder: true, blockReason: null, myMealOrder: null, ordersPlacedByMe: [], ...overrides,
});

describe("lunch-utils", () => {
  it("tab lạ quay về Hôm nay", () => {
    expect(resolveLunchTab("wallet")).toBe("wallet");
    expect(resolveLunchTab("x")).toBe("today");
    expect(resolveLunchTab(null)).toBe("today");
  });

  it("dùng danh sách menus, nếu không có thì dùng menu đơn", () => {
    expect(resolveAvailableMenus(today({ menus: [menu({ id: "m2" })] })).map(m => m.id)).toEqual(["m2"]);
    expect(resolveAvailableMenus(today()).map(m => m.id)).toEqual(["m1"]);
    expect(resolveAvailableMenus(undefined)).toEqual([]);
  });

  it("gộp phần của tôi và phần đặt hộ, bỏ trùng và phần đã hủy", () => {
    const orders = collectTodayOrders(today({ myMealOrders: [order("1"), order("2", "cancelled")], ordersPlacedByMe: [order("1"), order("3")] }));
    expect(orders.map(o => o.id)).toEqual(["1", "3"]);
    expect(collectTodayOrders(today({ myMealOrder: order("9") })).map(o => o.id)).toEqual(["9"]);
  });

  it("món chọn giữ thứ tự, cho phép trùng; tính dinh dưỡng", () => {
    const items = findMainItems(menu(), ["a", "a", "x"]);
    expect(items.map(i => i.id)).toEqual(["a", "a"]);
    expect(sumNutrition(items)).toEqual({ calories: 600, protein: 40, carbs: 0, fat: 0 });
    expect(findMainItems(null, ["a"])).toEqual([]);
  });

  it("giá phần cộng từng món thêm, kể cả món lặp lại", () => {
    expect(portionTotal(menu(), { extraItemIds: ["tra", "tra"] })).toBe(125000);
    expect(portionTotal(null, {})).toBe(0);
  });

  it("kiểm tra phần trước khi lưu", () => {
    const base = { menu: menu(), today: today(), selectionType: "COMBO" as const, selectedCount: 2 };
    expect(portionValidationError(base)).toBeNull();
    expect(portionValidationError({ ...base, menu: menu({ acceptingOrders: false }) })).toBe("Menu đã chốt hoặc chưa mở nhận đơn.");
    expect(portionValidationError({ ...base, today: today({ canOrder: false, blockReason: "Đang nợ" }) })).toBe("Đang nợ");
    expect(portionValidationError({ ...base, selectedCount: 1 })).toBe("Vui lòng chọn đúng 2 món.");
    expect(portionValidationError({ ...base, selectionType: "SINGLE", selectedCount: 2 })).toBe("Vui lòng chọn 1 món đơn.");
  });

  it("bật/tắt gợi ý ghi chú không phân biệt hoa thường", () => {
    expect(toggleNoteSuggestion("ít hành", "Cơm thêm")).toBe("ít hành + Cơm thêm");
    expect(toggleNoteSuggestion("ít hành + cơm thêm", "Cơm thêm")).toBe("ít hành");
  });

  it("bớt một món thêm", () => {
    expect(removeOneExtra(["tra", "x", "tra"], "tra")).toEqual(["x", "tra"]);
    expect(removeOneExtra(["x"], "tra")).toEqual(["x"]);
  });

  it("mô tả phần trong giỏ", () => {
    const people = [{ id: "u2", fullName: "Lan", email: "" }];
    expect(describeCartPortion(menu(), people, { id: "p", selectionType: "COMBO", itemIds: ["a", "b"], extraItemIds: ["tra"], note: "", beneficiaryUserId: "u2" }))
      .toEqual({ recipient: "Lan", dishes: "Món a + Món b + Trà đào (thêm)" });
    expect(describeCartPortion(menu(), [], { id: "p", selectionType: "SINGLE", itemIds: ["s"], note: "", beneficiaryUserId: "u9" }).recipient).toBe("Đồng nghiệp");
  });

  it("nhãn giao dịch quỹ", () => {
    expect(getTransactionLabel("debt_payment")).toBe("Thanh toán công nợ");
    expect(getTransactionLabel("TOP_UP")).toBe("Nạp quỹ");
    expect(getTransactionLabel("ORDER_REFUND")).toBe("Hoàn tiền phần ăn");
    expect(getTransactionLabel("MEAL_DEBIT")).toBe("Thanh toán phần ăn");
    expect(getTransactionLabel("MANUAL_ADJUST")).toBe("Điều chỉnh quỹ");
    expect(getTransactionLabel("OTHER")).toBe("Giao dịch quỹ");
  });
});
