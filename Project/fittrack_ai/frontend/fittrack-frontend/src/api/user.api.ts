import api from "./axios";

export type UserProfile = {
  id: string;
  email: string;
  fullName: string;
  gender: string;
  age: number;
  height: number;
  weight: number;
  goal: string;
  activityLevel: string;
  bmr: number;
  tdee: number;
  targetCalories: number;
  targetProtein: number;
  targetCarbs: number;
  targetFat: number;
};

export const getProfile = async (): Promise<UserProfile> => {
  const response = await api.get("/users/me");

  return response.data;
};

export const updateProfile = async (payload: Partial<UserProfile>): Promise<UserProfile> => {
  const response = await api.put("/users/me", payload);

  return response.data;
};
