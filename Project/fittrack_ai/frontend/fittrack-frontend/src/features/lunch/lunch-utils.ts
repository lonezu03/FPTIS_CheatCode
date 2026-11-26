import type {
  LunchMenu,
  LunchMenuItem,
  LunchOrder,
  LunchOrderPortionInput,
  LunchPerson,
  LunchSelectionType,
  LunchTodayResponse,
} from "@/api/lunch.api";

export const NOTE_SUGGESTIONS = ["Cơm thêm", "Rau thêm"];

export const LUNCH_TABS = ["today", "history", "wallet", "payment"] as const;
export type LunchTab = (typeof LUNCH_TABS)[number];

export type CartPortion = LunchOrderPortionInput & {
  id: string;
};

export type LunchNutrition = { calories: number; protein: number; carbs: number; fat: number };

/** Tab đang mở theo `?tab=`; giá trị lạ quay về "today". */
export function resolveLunchTab(requested: string | null): LunchTab {
  return (LUNCH_TABS as readonly string[]).includes(requested ?? "") ? requested as LunchTab : "today";
}

export function createCartPortionId(): string {
  return typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export function createCartRequestId(): string {
  return typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `order_${Date.now()}_${Math.random().toString(36).slice(2, 12)}`;
}

/** Các menu hôm nay; backend cũ chỉ trả một `menu`. */
export function resolveAvailableMenus(today: LunchTodayResponse | undefined): LunchMenu[] {
  if (today?.menus?.length) return today.menus;
  return today?.menu ? [today.menu] : [];
}

/** Phần của tôi và phần tôi đặt hộ, bỏ trùng và bỏ phần đã hủy. */
export function collectTodayOrders(today: LunchTodayResponse | undefined): LunchOrder[] {
  const byId = new Map<string, LunchOrder>();
  const myOrders = today?.myMealOrders ?? (today?.myMealOrder ? [today.myMealOrder] : []);
  for (const order of myOrders) byId.set(order.id, order);
  for (const order of today?.ordersPlacedByMe ?? []) byId.set(order.id, order);
  return [...byId.values()].filter((order) => order.status.toUpperCase() !== "CANCELLED");
}

/** Món chính đã chọn theo đúng thứ tự chọn (một món có thể chọn hai lần). */
export function findMainItems(menu: LunchMenu | null, itemIds: string[]): LunchMenuItem[] {
  if (!menu) return [];
  const allItems = [...menu.regularItems, ...menu.specialItems];
  return itemIds
    .map((itemId) => allItems.find((item) => item.id === itemId))
    .filter((item): item is LunchMenuItem => Boolean(item));
}

export function findExtraItems(menu: LunchMenu | null, itemIds: string[]): LunchMenuItem[] {
  return itemIds
    .map((itemId) => (menu?.extraItems ?? []).find((item) => item.id === itemId))
    .filter((item): item is LunchMenuItem => Boolean(item));
}

export function sumNutrition(items: LunchMenuItem[]): LunchNutrition {
  return items.reduce(
    (total, item) => ({
      calories: total.calories + (item.calories ?? 0),
      protein: total.protein + (item.protein ?? 0),
      carbs: total.carbs + (item.carbs ?? 0),
      fat: total.fat + (item.fat ?? 0),
    }),
    { calories: 0, protein: 0, carbs: 0, fat: 0 },
  );
}

export function sumExtraPrice(items: LunchMenuItem[]): number {
  return items.reduce((total, item) => total + (item.unitPrice ?? 0), 0);
}

/** Giá một phần: giá menu cộng giá từng món thêm (món thêm lặp lại tính nhiều lần). */
export function portionTotal(menu: LunchMenu | null, portion: Pick<LunchOrderPortionInput, "extraItemIds">): number {
  return (menu?.price ?? 0) + (portion.extraItemIds ?? []).reduce(
    (total, itemId) => total + ((menu?.extraItems ?? []).find((item) => item.id === itemId)?.unitPrice ?? 0),
    0,
  );
}

export function requiredItemCount(selectionType: LunchSelectionType): number {
  return selectionType === "COMBO" ? 2 : 1;
}

export function selectionTypeLabel(selectionType: LunchSelectionType): string {
  return selectionType === "COMBO" ? "Cơm 2 món" : "Món đơn";
}

/** Lỗi chặn khi lưu phần đang tạo; `null` khi hợp lệ. */
export function portionValidationError({
  menu,
  today,
  selectionType,
  selectedCount,
}: {
  menu: LunchMenu | null;
  today: LunchTodayResponse | undefined;
  selectionType: LunchSelectionType;
  selectedCount: number;
}): string | null {
  if (!menu || !menu.acceptingOrders) return "Menu đã chốt hoặc chưa mở nhận đơn.";
  if (!today?.canOrder) return today?.blockReason || "Tài khoản hiện chưa thể đặt cơm.";
  if (selectedCount !== requiredItemCount(selectionType)) {
    return selectionType === "COMBO" ? "Vui lòng chọn đúng 2 món." : "Vui lòng chọn 1 món đơn.";
  }
  return null;
}

/** Bật/tắt một gợi ý ghi chú, các phần cách nhau bởi " + ". */
export function toggleNoteSuggestion(note: string, suggestion: string): string {
  const same = (part: string) => part.toLocaleLowerCase("vi-VN") === suggestion.toLocaleLowerCase("vi-VN");
  const currentParts = note
    .split("+")
    .map((part) => part.trim())
    .filter(Boolean);
  const nextParts = currentParts.some(same)
    ? currentParts.filter((part) => !same(part))
    : [...currentParts, suggestion];
  return nextParts.join(" + ");
}

export function noteHasSuggestion(note: string, suggestion: string): boolean {
  return note.toLocaleLowerCase("vi-VN").includes(suggestion.toLocaleLowerCase("vi-VN"));
}

/** Bỏ một lần chọn của món thêm (giảm số lượng đi 1). */
export function removeOneExtra(itemIds: string[], itemId: string): string[] {
  const index = itemIds.indexOf(itemId);
  return index < 0 ? itemIds : [...itemIds.slice(0, index), ...itemIds.slice(index + 1)];
}

/** Người nhận và danh sách món của một phần trong giỏ. */
export function describeCartPortion(menu: LunchMenu, people: LunchPerson[], portion: CartPortion) {
  const recipient = portion.beneficiaryUserId
    ? people.find((person) => person.id === portion.beneficiaryUserId)?.fullName ?? "Đồng nghiệp"
    : "Tôi";
  const dishes = portion.itemIds
    .map((itemId) => [...menu.regularItems, ...menu.specialItems].find((item) => item.id === itemId)?.name)
    .filter(Boolean)
    .concat((portion.extraItemIds ?? []).map((itemId) => menu.extraItems?.find((item) => item.id === itemId)?.name).filter(Boolean).map((name) => `${name} (thêm)`))
    .join(" + ");
  return { recipient, dishes };
}

export function getTransactionLabel(type: string): string {
  const normalized = type.toUpperCase();
  if (normalized.includes("DEBT_PAYMENT")) return "Thanh toán công nợ";
  if (normalized.includes("TOP") || normalized.includes("DEPOSIT")) return "Nạp quỹ";
  if (normalized.includes("REFUND")) return "Hoàn tiền phần ăn";
  if (normalized.includes("ORDER") || normalized.includes("MEAL") || normalized.includes("DEBIT")) return "Thanh toán phần ăn";
  if (normalized.includes("ADJUST")) return "Điều chỉnh quỹ";
  return "Giao dịch quỹ";
}
