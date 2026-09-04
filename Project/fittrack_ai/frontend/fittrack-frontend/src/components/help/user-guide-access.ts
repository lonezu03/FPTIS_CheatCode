import { canUseFeature } from "@/lib/feature-access";
import type { AuthUser } from "@/store/auth.store";

export function getAvailableGuideModuleIds(user: AuthUser | null, isAdmin: boolean) {
  const ids = ["overview"];
  if (canUseFeature(user, "lunchEnabled")) ids.push("lunch");
  if (canUseFeature(user, "todoEnabled")) ids.push("todos");
  if (canUseFeature(user, "scheduleEnabled")) ids.push("schedule");
  if (canUseFeature(user, "fitnessEnabled")) ids.push("fitness");
  if (canUseFeature(user, "healthEnabled")) ids.push("health");
  if (canUseFeature(user, "chatbotEnabled")) ids.push("assistant");
  ids.push("notifications", "profile");
  if (isAdmin) ids.push("admin");
  return ids;
}
