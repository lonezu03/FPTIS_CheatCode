import api from "./axios";
import type { PageResponse } from "./pagination";

export type AdminUser = {
  id: string;
  email: string;
  fullName: string;
  role: "USER" | "ADMIN";
  active: boolean;
  emailVerified: boolean;
  lunchEnabled: boolean;
  fitnessEnabled: boolean;
  healthEnabled: boolean;
  chatbotEnabled: boolean;
  todoEnabled: boolean;
  scheduleEnabled: boolean;
  createdAt: string;
};

export async function getAdminUsers(keyword = ""): Promise<AdminUser[]> {
  const response = await api.get<AdminUser[]>("/admin/users", {
    params: keyword.trim() ? { keyword: keyword.trim() } : {},
  });
  return response.data;
}

export async function getAdminUsersPage(
  keyword = "",
  page = 0,
  size = 20,
): Promise<PageResponse<AdminUser>> {
  const response = await api.get<PageResponse<AdminUser>>("/admin/users/page", {
    params: { keyword: keyword.trim(), page, size },
  });
  return response.data;
}

export async function updateAdminUser(
  id: string,
  payload: {
    fullName?: string;
    role?: "USER" | "ADMIN";
    active?: boolean;
    lunchEnabled?: boolean;
    fitnessEnabled?: boolean;
    healthEnabled?: boolean;
    chatbotEnabled?: boolean;
    todoEnabled?: boolean;
    scheduleEnabled?: boolean;
  },
): Promise<AdminUser> {
  const response = await api.patch<AdminUser>(`/admin/users/${id}`, payload);
  return response.data;
}

export async function resetAdminUserPassword(id: string, newPassword: string): Promise<void> {
  await api.post(`/admin/users/${id}/reset-password`, { newPassword });
}

export async function deleteLockedAdminUser(id: string): Promise<void> {
  await api.delete(`/admin/users/${id}`);
}
