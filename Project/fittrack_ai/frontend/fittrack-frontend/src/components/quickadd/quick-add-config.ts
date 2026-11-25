import type { ElementType } from "react";
import { BookHeart, ListTodo, Scale, Soup, WalletCards } from "lucide-react";
import { canUseFeature, type FeaturePermission } from "@/lib/feature-access";
import type { AuthUser } from "@/store/auth.store";

export type QuickAddTab = "todo" | "meal" | "finance" | "body" | "journal";

export type QuickAddTabConfig = {
  id: QuickAddTab;
  label: string;
  icon: ElementType;
  feature: FeaturePermission;
  /** Module page opened from the success toast. */
  path: string;
};

export const QUICK_ADD_TABS: QuickAddTabConfig[] = [
  { id: "todo", label: "Việc", icon: ListTodo, feature: "todoEnabled", path: "/todos" },
  { id: "meal", label: "Bữa ăn", icon: Soup, feature: "healthEnabled", path: "/nutrition" },
  { id: "finance", label: "Thu/chi", icon: WalletCards, feature: "financeEnabled", path: "/finance" },
  { id: "body", label: "Cân nặng", icon: Scale, feature: "healthEnabled", path: "/body" },
  { id: "journal", label: "Nhật ký", icon: BookHeart, feature: "journalEnabled", path: "/journal" },
];

/** Tabs the user may use. Visibility only; the API still enforces access. */
export function allowedQuickAddTabs(user: AuthUser | null): QuickAddTabConfig[] {
  return QUICK_ADD_TABS.filter((tab) => canUseFeature(user, tab.feature));
}

export const MEAL_TYPES = ["BREAKFAST", "LUNCH", "DINNER", "SNACK"] as const;
export type MealType = (typeof MEAL_TYPES)[number];
export const MAIN_MEAL_TYPES: MealType[] = ["BREAKFAST", "LUNCH", "DINNER"];
export const MEAL_LABELS: Record<MealType, string> = {
  BREAKFAST: "Bữa sáng",
  LUNCH: "Bữa trưa",
  DINNER: "Bữa tối",
  SNACK: "Bữa phụ",
};

export type MealUnit = "SERVING" | "GRAM";

/** Converts the typed amount to the serving multiplier the API stores. */
export function mealQuantity(amount: number, unit: MealUnit, servingSizeGrams?: number | null) {
  return unit === "GRAM" && servingSizeGrams ? amount / servingSizeGrams : amount;
}

/** Default meal for the current hour so most entries need no change. */
export function mealTypeForHour(hour: number): MealType {
  if (hour < 10) return "BREAKFAST";
  if (hour < 14) return "LUNCH";
  if (hour < 17) return "SNACK";
  return "DINNER";
}

/** Alt+N (Option+N on macOS). Uses `code` so keyboard layouts and dead keys do not matter. */
export function isQuickAddShortcut(event: Pick<KeyboardEvent, "altKey" | "ctrlKey" | "metaKey" | "shiftKey" | "code" | "repeat">) {
  return event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey && !event.repeat && event.code === "KeyN";
}
