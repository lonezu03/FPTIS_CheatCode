import api from "./axios";

export type RecommendationItem = {
  type: string;
  severity: "LOW" | "MEDIUM" | "HIGH";
  title: string;
  message: string;
  action: string;
};

export type WeeklyRecommendation = {
  fromDate: string;
  toDate: string;
  summary: string;
  nutritionDataSufficient: boolean;
  completeNutritionDays: number;
  periodDays: number;
  nutritionConfidencePercent: number;
  recommendations: RecommendationItem[];
};

export const getWeeklyRecommendations = async (params?: {
  fromDate?: string;
  toDate?: string;
}): Promise<WeeklyRecommendation> => {
  const response = await api.get("/recommendations/weekly", {
    params,
  });

  return response.data;
};

export type WeeklyCoachCheckIn = {
  id: string; weekStart: string; weekEnd: string; status: "PENDING" | "ACCEPTED" | "IGNORED";
  weightChange: number | null; completeDays: number;
  workoutDays: number; confidencePercent: number; dataSufficient: boolean;
  currentCalories: number; proposedCalories: number; currentProtein: number; proposedProtein: number;
  rationale: string; canApply: boolean; decidedAt: string | null;
};

export const getCurrentWeeklyCheckIn = async (): Promise<WeeklyCoachCheckIn> =>
  (await api.get("/recommendations/check-ins/current")).data;

export const decideWeeklyCheckIn = async (id: string, decision: "ACCEPT" | "IGNORE"): Promise<WeeklyCoachCheckIn> =>
  (await api.post(`/recommendations/check-ins/${id}/decision`, { decision })).data;
