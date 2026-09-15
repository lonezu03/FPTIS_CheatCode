import type { AuthUser } from "@/store/auth.store";

export type FeaturePermission =
  | "lunchEnabled"
  | "fitnessEnabled"
  | "healthEnabled"
  | "chatbotEnabled"
  | "todoEnabled"
  | "scheduleEnabled"
  | "quoteEnabled"
  | "financeEnabled";

export function canUseFeature(user: AuthUser | null, feature: FeaturePermission) {
  return user?.role === "ADMIN" || user?.[feature] === true;
}
