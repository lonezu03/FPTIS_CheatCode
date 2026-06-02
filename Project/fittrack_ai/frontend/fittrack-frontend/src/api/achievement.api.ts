import api from "./axios";

export type Achievement = {
  code: string;
  title: string;
  description: string;
  unlocked: boolean;
  progress: number;
  target: number;
};

export type AchievementSummary = {
  mealLoggingStreak: number;
  workoutStreak: number;
  proteinHitDaysThisWeek: number;
  bodyTrackingDaysThisWeek: number;
  achievements: Achievement[];
};

export const getAchievementSummary = async (): Promise<AchievementSummary> => {
  const response = await api.get("/achievements/summary");

  return response.data;
};
