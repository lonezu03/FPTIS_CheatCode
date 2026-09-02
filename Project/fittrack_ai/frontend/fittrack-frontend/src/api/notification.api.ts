import api from "./axios";

export type MailStatus = {
  enabled: boolean;
  configured: boolean;
  provider: "smtp" | "brevo" | string;
  host: string;
  port: number;
  maskedSender: string;
  message: string;
};

export async function broadcastNotification(payload: {
  title: string;
  message: string;
  sendToAll: boolean;
  recipientUserIds: string[];
}): Promise<{ message: string; recipientCount: number }> {
  const response = await api.post("/admin/notifications/broadcast", payload);
  return response.data;
}

export async function getMailStatus(): Promise<MailStatus> {
  const response = await api.get<MailStatus>("/admin/notifications/mail-status");
  return response.data;
}

export async function sendTestEmail(): Promise<{ message: string; recipient: string }> {
  const response = await api.post("/admin/notifications/test-email");
  return response.data;
}

export type ModuleAccessRequestResult = {
  message: string;
  notifiedAdminCount: number;
  alreadyRequested: boolean;
  alreadyGranted: boolean;
};

export async function requestFitnessModuleAccess(): Promise<ModuleAccessRequestResult> {
  const response = await api.post<ModuleAccessRequestResult>(
    "/notifications/access-requests/fitness",
  );
  return response.data;
}
