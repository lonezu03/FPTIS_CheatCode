import api from "./axios";
import type { PageResponse } from "./pagination";

export type Food = {
  id: string;
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  unit: string;
  custom: boolean;
  active: boolean;
};

export type MealLog = {
  id: string;
  mealType: string;
  logDate: string;
  totalCalories: number;
  totalProtein: number;
  totalCarbs: number;
  totalFat: number;
  createdAt: string;
  sourceType: "MANUAL" | "LUNCH_ORDER";
  sourceId: string | null;
  readOnly: boolean;
  items: {
    id: string;
    foodId: string;
    foodName: string;
    quantity: number;
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
  }[];
};

export const getFoods = async (keyword?: string): Promise<Food[]> => {
  const response = await api.get("/nutrition/foods", {
    params: keyword ? { keyword } : {},
  });

  return response.data;
};

export const getMealLogs = async (date?: string): Promise<MealLog[]> => {
  const response = await api.get("/nutrition/meal-logs", {
    params: date ? { date } : {},
  });

  return response.data;
};

export const getMealLogsPage = async (
  date?: string,
  page = 0,
  size = 20,
): Promise<PageResponse<MealLog>> => {
  const response = await api.get<PageResponse<MealLog>>("/nutrition/meal-logs/page", {
    params: { ...(date ? { date } : {}), page, size },
  });
  return response.data;
};

export const createMealLog = async (payload: {
  mealType: string;
  logDate: string;
  items: {
    foodId: string;
    quantity: number;
  }[];
}): Promise<MealLog> => {
  const response = await api.post("/nutrition/meal-logs", payload);

  return response.data;
};

export const deleteMealLog = async (id: string): Promise<void> => {
  await api.delete(`/nutrition/meal-logs/${id}`);
};

export const updateMealLog = async (
  id: string,
  payload: {
    mealType: string;
    logDate: string;
    items: {
      foodId: string;
      quantity: number;
    }[];
  }
): Promise<MealLog> => {
  const response = await api.put(`/nutrition/meal-logs/${id}`, payload);

  return response.data;
};
