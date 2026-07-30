import api from "./axios";

export async function broadcastNotification(payload: {
  title: string;
  message: string;
  sendToAll: boolean;
  recipientUserIds: string[];
}): Promise<{ message: string; recipientCount: number }> {
  const response = await api.post("/admin/notifications/broadcast", payload);
  return response.data;
}
