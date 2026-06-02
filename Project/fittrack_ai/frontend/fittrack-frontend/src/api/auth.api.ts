import api from "./axios";

export type AuthResponse = {
  token: string;
  tokenType: string;
  userId: string;
  email: string;
  fullName: string;
};

export const loginApi = async (email: string, password: string): Promise<AuthResponse> => {
  const response = await api.post("/auth/login", { email, password });

  return response.data;
};

export const registerApi = async (payload: {
  email: string;
  password: string;
  fullName: string;
  height?: number;
  weight?: number;
  goal?: string;
}): Promise<AuthResponse> => {
  const response = await api.post("/auth/register", payload);

  return response.data;
};
