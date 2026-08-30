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
