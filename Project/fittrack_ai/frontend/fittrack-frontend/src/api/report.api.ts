import api from "./axios";

export type DailyNutritionSummary = {
  date: string;
  dataStatus: "COMPLETE" | "PARTIAL" | "UNLOGGED" | "FASTING";
  dataIncluded: boolean;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  targetCalories: number;
  targetProtein: number;
  caloriesCompliancePercent: number;
  proteinCompliancePercent: number;
};

export type WeeklyReport = {
  fromDate: string;
  toDate: string;
  periodDays: number;
  completeNutritionDays: number;
  partialNutritionDays: number;
  unloggedNutritionDays: number;
  nutritionConfidencePercent: number;
  nutritionDataSufficient: boolean;
  averageCalories: number;
  averageProtein: number;
  averageCarbs: number;
  averageFat: number;
  targetCalories: number;
  targetProtein: number;
  targetCarbs: number;
  targetFat: number;
  totalMeals: number;
  totalWorkouts: number;
  workoutDays: number;
  startWeight: number | null;
  endWeight: number | null;
  weightChange: number | null;
  startWaist: number | null;
  endWaist: number | null;
  waistChange: number | null;
  caloriesCompliancePercent: number;
  proteinCompliancePercent: number;
  insights: string[];
  dailyNutrition: DailyNutritionSummary[];
};

export const getWeeklyReport = async (params?: { fromDate?: string; toDate?: string }): Promise<WeeklyReport> => {
  const response = await api.get("/reports/weekly", {
    params,
  });

  return response.data;
};
