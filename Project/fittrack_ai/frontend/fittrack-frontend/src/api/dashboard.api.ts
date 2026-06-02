import api from "./axios";

export type DashboardToday = {
  totalCalories: number;
  totalProtein: number;
  totalCarbs: number;
  totalFat: number;
  targetCalories: number;
  targetProtein: number;
  targetCarbs: number;
  targetFat: number;
  caloriesProgressPercent: number;
  proteinProgressPercent: number;
  carbsProgressPercent: number;
  fatProgressPercent: number;
  mealCount: number;
  workoutCount: number;
  latestWorkoutNote: string | null;
};

export type ProgressPoint = {
  date: string;
  weight: number | null;
  waist: number | null;
  calories: number;
  protein: number;
  workoutCount: number;
};

export const getTodayDashboard = async (): Promise<DashboardToday> => {
  const response = await api.get("/dashboard/today");

  return response.data;
};

export const getProgressDashboard = async (): Promise<{ points: ProgressPoint[] }> => {
  const response = await api.get("/dashboard/progress");

  return response.data;
};
