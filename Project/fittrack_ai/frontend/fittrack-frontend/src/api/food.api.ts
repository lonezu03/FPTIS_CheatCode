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
  imageUrl: string | null;
  custom: boolean;
  active: boolean;
  approvalStatus: "PENDING" | "APPROVED" | "REJECTED";
  submittedById?: string | null;
  submittedByName?: string | null;
  adminNote?: string | null;
  fiber: number | null;
  sugar: number | null;
  sodium: number | null;
  potassium: number | null;
  calcium: number | null;
  iron: number | null;
  vitaminC: number | null;
  water: number | null;
  servingSizeGrams?: number | null;
  dataSourceType?: FoodSourceType;
  dataSourceName?: string | null;
  verified?: boolean;
};

export type FoodSourceType =
  | "VERIFIED_DATABASE"
  | "PRODUCT_LABEL"
  | "RECIPE_CALCULATED"
  | "COMMUNITY"
  | "ESTIMATED";

export type FoodPayload = {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber?: number | null;
  sugar?: number | null;
  sodium?: number | null;
  potassium?: number | null;
  calcium?: number | null;
  iron?: number | null;
  vitaminC?: number | null;
  water?: number | null;
  unit: string;
  servingSizeGrams?: number | null;
  dataSourceType?: FoodSourceType;
  dataSourceName?: string | null;
  verified?: boolean;
  imageUrl?: string | null;
};

export const getFoodsManagementApi = async (keyword?: string, includeInactive?: boolean): Promise<Food[]> => {
  const response = await api.get("/foods", {
    params: {
      ...(keyword ? { keyword } : {}),
      ...(includeInactive ? { includeInactive } : {}),
    },
  });

  return response.data;
};

export const createFoodApi = async (payload: FoodPayload): Promise<Food> => {
  const response = await api.post("/foods", payload);

  return response.data;
};

export const getFoodsManagementPageApi = async (
  keyword = "",
  includeInactive = false,
  page = 0,
  size = 20,
): Promise<PageResponse<Food>> => {
  const response = await api.get<PageResponse<Food>>("/foods/page", {
    params: { keyword, includeInactive, page, size },
  });
  return response.data;
};

export const suggestFoodApi = async (payload: FoodPayload): Promise<Food> => {
  const response = await api.post("/foods/suggestions", payload);
  return response.data;
};

export const reviewFoodApi = async (
  id: string,
  status: "APPROVED" | "REJECTED",
  note = "",
): Promise<Food> => {
  const response = await api.patch(`/foods/${id}/review`, { status, note });
  return response.data;
};

export const updateFoodApi = async (
  id: string,
  payload: FoodPayload
): Promise<Food> => {
  const response = await api.put(`/foods/${id}`, payload);

  return response.data;
};

export const archiveFoodApi = async (id: string): Promise<void> => {
  await api.delete(`/foods/${id}`);
};

export const restoreFoodApi = async (id: string): Promise<Food> => {
  const response = await api.patch(`/foods/${id}/restore`);

  return response.data;
};
