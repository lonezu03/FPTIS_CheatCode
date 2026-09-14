import api from "./axios";

export type HealthConnectDay = { date: string; steps: number; latestWeightKg: number | null; averageHeartRate: number | null; exerciseSessions: number; lastSyncedAt: string | null };
export const getHealthConnectDay = async (date?: string): Promise<HealthConnectDay> =>
  (await api.get("/health-connect/day", { params: date ? { date } : {} })).data;
