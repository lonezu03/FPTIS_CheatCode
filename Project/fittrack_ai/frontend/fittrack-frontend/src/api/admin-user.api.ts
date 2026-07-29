import api from "./axios";

export type AdminUser = {
  id: string;
  email: string;
  fullName: string;
  role: "USER" | "ADMIN";
  active: boolean;
  createdAt: string;
};

export async function getAdminUsers(keyword = ""): Promise<AdminUser[]> {
  const response = await api.get<AdminUser[]>("/admin/users", {
    params: keyword.trim() ? { keyword: keyword.trim() } : {},
  });
  return response.data;
}

export async function updateAdminUser(
  id: string,
  payload: {
    fullName?: string;
    role?: "USER" | "ADMIN";
    active?: boolean;
  },
): Promise<AdminUser> {
  const response = await api.patch<AdminUser>(`/admin/users/${id}`, payload);
  return response.data;
}

export async function resetAdminUserPassword(id: string, newPassword: string): Promise<void> {
  await api.post(`/admin/users/${id}/reset-password`, { newPassword });
}
