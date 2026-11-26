import type { MealLog, ServingUnit } from "@/api/nutrition.api";
import type { PageResponse } from "@/api/pagination";
import { collectPages, csvDate, type CsvColumn } from "@/lib/csv";

export const MEAL_ORDER = ["BREAKFAST", "LUNCH", "DINNER", "SNACK"] as const;
export const MEAL_LABELS: Record<string, string> = {
  BREAKFAST: "Bữa sáng",
  LUNCH: "Bữa trưa",
  DINNER: "Bữa tối",
  SNACK: "Ăn phụ",
};

/** Export limits: at most one year per file and 30 pages × 100 meal logs read. */
export const NUTRITION_EXPORT_MAX_DAYS = 366;
export const NUTRITION_EXPORT_PAGE_SIZE = 100;
export const NUTRITION_EXPORT_MAX_PAGES = 30;

/** Number of days from `from` to `to`, both included (0 when the range is reversed or invalid). */
export function daysInRange(from: string, to: string): number {
  const start = Date.parse(`${from}T00:00:00Z`);
  const end = Date.parse(`${to}T00:00:00Z`);
  if (!Number.isFinite(start) || !Number.isFinite(end) || end < start) return 0;
  return Math.round((end - start) / 86_400_000) + 1;
}

/** Error text for an export range, or null when it can be exported. */
export function exportRangeError(from: string, to: string): string | null {
  if (!from || !to) return "Chọn đủ ngày bắt đầu và ngày kết thúc.";
  const days = daysInRange(from, to);
  if (days === 0) return "Ngày bắt đầu phải trước hoặc bằng ngày kết thúc.";
  if (days > NUTRITION_EXPORT_MAX_DAYS) return `Mỗi lần xuất tối đa ${NUTRITION_EXPORT_MAX_DAYS} ngày.`;
  return null;
}

/**
 * Reads the meal-log pages (newest first) until it passes `from`, keeping logs in [from, to].
 * Result is ordered by date, then breakfast → snack, then creation time.
 */
export async function collectMealLogsInRange(
  fetchPage: (page: number) => Promise<PageResponse<MealLog>>,
  from: string,
  to: string,
  maxPages = NUTRITION_EXPORT_MAX_PAGES,
): Promise<{ logs: MealLog[]; truncated: boolean }> {
  const { items, truncated } = await collectPages(fetchPage, {
    maxPages,
    stop: (page) => page[page.length - 1].logDate < from,
  });
  const logs = items
    .filter((log) => log.logDate >= from && log.logDate <= to)
    .sort((a, b) => a.logDate.localeCompare(b.logDate)
      || mealRank(a.mealType) - mealRank(b.mealType)
      || a.createdAt.localeCompare(b.createdAt));
  return { logs, truncated };
}

const mealRank = (type: string) => {
  const index = (MEAL_ORDER as readonly string[]).indexOf(type);
  return index < 0 ? MEAL_ORDER.length : index;
};

export type MealItemRow = { log: MealLog; item: MealLog["items"][number] };

/** One CSV row per food item. */
export function mealItemRows(logs: MealLog[]): MealItemRow[] {
  return logs.flatMap((log) => log.items.map((item) => ({ log, item })));
}

const unitLabel = (unit?: ServingUnit | null) => (unit === "GRAM" ? "g" : unit === "ML" ? "ml" : "khẩu phần");
const oneDecimal = (value: number) => Math.round(value * 10) / 10;

export const mealItemCsvColumns: CsvColumn<MealItemRow>[] = [
  { header: "Ngày", value: ({ log }) => csvDate(log.logDate) },
  { header: "Bữa", value: ({ log }) => MEAL_LABELS[log.mealType] ?? log.mealType },
  { header: "Món", value: ({ item }) => item.foodName },
  { header: "Số lượng", value: ({ item }) => item.servingAmount ?? item.quantity },
  { header: "Đơn vị", value: ({ item }) => unitLabel(item.servingUnit) },
  { header: "Năng lượng (kcal)", value: ({ item }) => Math.round(item.calories) },
  { header: "Đạm (g)", value: ({ item }) => oneDecimal(item.protein) },
  { header: "Tinh bột (g)", value: ({ item }) => oneDecimal(item.carbs) },
  { header: "Chất béo (g)", value: ({ item }) => oneDecimal(item.fat) },
  { header: "Nguồn", value: ({ log }) => (log.sourceType === "LUNCH_ORDER" ? "Đơn cơm" : "Thủ công") },
];

/**
 * Meals of one type that can be copied to another day. Lunch-order meals are skipped:
 * the lunch module logs them itself, so copying would count them twice.
 */
export function copyableMeals(meals: MealLog[], mealType: string): MealLog[] {
  return meals.filter((meal) => meal.mealType === mealType && meal.sourceType !== "LUNCH_ORDER" && !meal.readOnly && meal.items.length > 0);
}

export type MealLogPayload = {
  mealType: string;
  logDate: string;
  items: { foodId: string; quantity: number; servingAmount?: number; servingUnit?: ServingUnit }[];
};

/** Create payloads that repeat each meal (same foods and portions) on `logDate`. */
export function mealCopyPayloads(meals: MealLog[], logDate: string): MealLogPayload[] {
  return meals.map((meal) => ({
    mealType: meal.mealType,
    logDate,
    items: meal.items.map((item) => ({
      foodId: item.foodId,
      quantity: item.quantity,
      ...(item.servingAmount != null && item.servingUnit ? { servingAmount: item.servingAmount, servingUnit: item.servingUnit } : {}),
    })),
  }));
}
