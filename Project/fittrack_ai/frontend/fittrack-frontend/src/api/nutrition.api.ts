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
  barcode?: string | null;
  custom: boolean;
  active: boolean;
  servingSizeGrams?: number | null;
  dataSourceType?: "VERIFIED_DATABASE" | "PRODUCT_LABEL" | "RECIPE_CALCULATED" | "COMMUNITY" | "ESTIMATED";
  dataSourceName?: string | null;
  verified?: boolean;
};

export type FoodShortcut = { food: Food; favorite: boolean; useCount: number; lastUsedAt: string | null };
export type NutritionCollection = {
  id: string; name: string; description: string | null; type: "SAVED_MEAL" | "RECIPE";
  servings: number; totalCalories: number; totalProtein: number; totalCarbs: number; totalFat: number;
  items: { food: Food; amount: number; unit: ServingUnit; orderIndex: number }[];
};
export type NutritionConvenience = { recent: FoodShortcut[]; favorites: FoodShortcut[]; collections: NutritionCollection[] };

export type ServingUnit = "SERVING" | "GRAM" | "ML";
export type NutritionDayStatus = "COMPLETE" | "PARTIAL" | "UNLOGGED" | "FASTING";

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
    servingAmount?: number | null;
    servingUnit?: ServingUnit | null;
    gramsEquivalent?: number | null;
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
    servingAmount?: number;
    servingUnit?: ServingUnit;
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
      servingAmount?: number;
      servingUnit?: ServingUnit;
    }[];
  }
): Promise<MealLog> => {
  const response = await api.put(`/nutrition/meal-logs/${id}`, payload);

  return response.data;
};

export type NutritionTotals = {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
};

export type NutritionDiary = {
  date: string;
  status: NutritionDayStatus;
  statusExplicit: boolean;
  consumed: NutritionTotals;
  targets: NutritionTotals;
  remaining: NutritionTotals;
  waterMl: number;
  waterTargetMl: number;
  meals: MealLog[];
};

export const getNutritionDiary = async (date: string): Promise<NutritionDiary> => {
  const response = await api.get<NutritionDiary>("/nutrition/diary", { params: { date } });
  return response.data;
};

export const updateNutritionDayStatus = async (
  date: string,
  status: NutritionDayStatus,
): Promise<NutritionDiary> => {
  const response = await api.put<NutritionDiary>(`/nutrition/days/${date}/status`, { status });
  return response.data;
};

export const addWaterLog = async (amountMl: number, date: string): Promise<void> => {
  await api.post("/nutrition/water-logs", { amountMl, loggedAt: `${date}T12:00:00` });
};

export const getNutritionConvenience = async (): Promise<NutritionConvenience> =>
  (await api.get("/nutrition/convenience")).data;

export const setFoodFavorite = async (foodId: string, favorite: boolean): Promise<FoodShortcut> =>
  (await api.put(`/nutrition/foods/${foodId}/favorite`, { favorite })).data;

export const saveNutritionCollection = async (payload: {
  name: string; description?: string; type: "SAVED_MEAL" | "RECIPE"; servings: number;
  items: { foodId: string; amount: number; unit: ServingUnit }[];
}): Promise<NutritionCollection> => (await api.post("/nutrition/collections", payload)).data;

export const logNutritionCollection = async (id: string, payload: { mealType: string; logDate: string; servings: number }): Promise<MealLog> =>
  (await api.post(`/nutrition/collections/${id}/log`, payload)).data;

export const getFoodByBarcode = async (barcode: string): Promise<Food> =>
  (await api.get(`/foods/barcode/${encodeURIComponent(barcode)}`)).data;

export const analyzeFoodPhoto = async (imageData: string): Promise<{
  items: { name: string; estimatedGrams: number | null; calories: number | null; protein: number | null; carbs: number | null; fat: number | null }[];
  note: string; requiresConfirmation: boolean;
}> => (await api.post("/nutrition/photo-analysis", { imageData })).data;
