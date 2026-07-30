import api from "./axios";

export type AuthResponse = {
  token: string;
  tokenType: string;
  userId: string;
  email: string;
  fullName: string;
  role: "USER" | "ADMIN";
  lunchEnabled: boolean;
  fitnessEnabled: boolean;
  healthEnabled: boolean;
  chatbotEnabled: boolean;
};

export type RegistrationResponse = {
  email: string;
  message: string;
  verificationRequired: boolean;
  emailSent: boolean;
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
}): Promise<RegistrationResponse> => {
  const response = await api.post("/auth/register", payload);

  return response.data;
};

export const verifyEmailApi = async (token: string): Promise<void> => {
  await api.post("/auth/verify-email", { token });
};

export const resendVerificationApi = async (email: string): Promise<void> => {
  await api.post("/auth/resend-verification", { email });
};

export const forgotPasswordApi = async (email: string): Promise<void> => {
  await api.post("/auth/forgot-password", { email });
};

export const resetPasswordApi = async (token: string, newPassword: string): Promise<void> => {
  await api.post("/auth/reset-password", { token, newPassword });
};
