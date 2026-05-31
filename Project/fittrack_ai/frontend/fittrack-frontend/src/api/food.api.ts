import api from "./axios";

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

export const getFoodsManagementApi = async (keyword?: string, includeInactive?: boolean): Promise<Food[]> => {
  const response = await api.get("/foods", {
    params: {
      ...(keyword ? { keyword } : {}),
      ...(includeInactive ? { includeInactive } : {}),
    },
  });

  return response.data;
};

export const createFoodApi = async (payload: {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  unit: string;
}): Promise<Food> => {
  const response = await api.post("/foods", payload);

  return response.data;
};

export const updateFoodApi = async (
  id: string,
  payload: {
    name: string;
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
    unit: string;
  }
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
