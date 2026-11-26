import { describe, expect, it } from "vitest";

import type { MealLog } from "@/api/nutrition.api";
import { buildCsv } from "@/lib/csv";
import { collectMealLogsInRange, copyableMeals, daysInRange, exportRangeError, mealCopyPayloads, mealItemCsvColumns, mealItemRows } from "./nutrition-utils";

const item = (overrides: Partial<MealLog["items"][number]> = {}): MealLog["items"][number] => ({
  id: "i1", foodId: "pho", foodName: "Phở bò", quantity: 1, servingAmount: 1, servingUnit: "SERVING",
  calories: 450.4, protein: 25.26, carbs: 60, fat: 12, ...overrides,
});
const meal = (overrides: Partial<MealLog> = {}): MealLog => ({
  id: "m1", mealType: "BREAKFAST", logDate: "2026-11-25", totalCalories: 450, totalProtein: 25, totalCarbs: 60, totalFat: 12,
  createdAt: "2026-11-25T07:00:00", sourceType: "MANUAL", sourceId: null, readOnly: false, items: [item()], ...overrides,
});
const page = (content: MealLog[], last: boolean) => ({ content, last, page: 0, size: 100, totalElements: 0, totalPages: 0, first: false });

describe("khoảng ngày xuất", () => {
  it("đếm cả hai đầu và kiểm tra giới hạn", () => {
    expect(daysInRange("2026-11-01", "2026-11-30")).toBe(30);
    expect(daysInRange("2026-11-02", "2026-11-01")).toBe(0);
    expect(exportRangeError("2026-11-02", "2026-11-01")).toMatch(/trước hoặc bằng/);
    expect(exportRangeError("2025-01-01", "2026-11-01")).toMatch(/tối đa 366 ngày/);
    expect(exportRangeError("2026-01-01", "2026-12-31")).toBeNull();
  });
});

describe("collectMealLogsInRange", () => {
  it("dừng khi đã qua ngày bắt đầu và sắp theo ngày, bữa", async () => {
    const pages = [
      page([meal({ id: "a", logDate: "2026-11-27" }), meal({ id: "b", logDate: "2026-11-26", mealType: "DINNER" }), meal({ id: "c", logDate: "2026-11-26" })], false),
      page([meal({ id: "d", logDate: "2026-11-24" })], false),
      page([meal({ id: "never" })], true),
    ];
    const requested: number[] = [];
    const result = await collectMealLogsInRange(async (index) => { requested.push(index); return pages[index]; }, "2026-11-25", "2026-11-26");
    expect(requested).toEqual([0, 1]);
    expect(result).toEqual({ logs: [expect.objectContaining({ id: "c" }), expect.objectContaining({ id: "b" })], truncated: false });
  });

  it("báo bị cắt khi chạm giới hạn trang", async () => {
    const result = await collectMealLogsInRange(async () => page([meal()], false), "2026-11-01", "2026-11-30", 2);
    expect(result.truncated).toBe(true);
    expect(result.logs).toHaveLength(2);
  });
});

describe("CSV nhật ký ăn", () => {
  it("mỗi món một dòng, làm tròn dinh dưỡng", () => {
    const csv = buildCsv(mealItemRows([meal({ items: [item(), item({ id: "i2", foodName: "Trà đá", servingAmount: 200, servingUnit: "ML", calories: 0, protein: 0, carbs: 0, fat: 0 })] })]), mealItemCsvColumns);
    expect(csv.split("\r\n")[1]).toBe('25/11/2026;Bữa sáng;Phở bò;1;khẩu phần;450;"25,3";60;12;Thủ công');
    expect(csv.split("\r\n")[2]).toBe("25/11/2026;Bữa sáng;Trà đá;200;ml;0;0;0;0;Thủ công");
  });
});

describe("ghi lại bữa giống hôm qua", () => {
  it("chỉ chép bữa cùng loại, bỏ bữa từ đơn cơm", () => {
    const meals = [meal(), meal({ id: "lunch", mealType: "LUNCH" }), meal({ id: "order", sourceType: "LUNCH_ORDER", readOnly: true }), meal({ id: "empty", items: [] })];
    expect(copyableMeals(meals, "BREAKFAST").map((value) => value.id)).toEqual(["m1"]);
  });

  it("giữ món và khẩu phần, đổi sang ngày mới", () => {
    const payloads = mealCopyPayloads([meal({ items: [item(), item({ foodId: "rice", quantity: 1.5, servingAmount: 150, servingUnit: "GRAM" }), item({ foodId: "old", quantity: 2, servingAmount: null, servingUnit: null })] })], "2026-11-26");
    expect(payloads).toEqual([{
      mealType: "BREAKFAST",
      logDate: "2026-11-26",
      items: [
        { foodId: "pho", quantity: 1, servingAmount: 1, servingUnit: "SERVING" },
        { foodId: "rice", quantity: 1.5, servingAmount: 150, servingUnit: "GRAM" },
        { foodId: "old", quantity: 2 },
      ],
    }]);
  });
});
