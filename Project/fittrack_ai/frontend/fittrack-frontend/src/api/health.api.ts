import api from "./axios";

export type NutrientMetric = {
  key: string;
  label: string;
  average: number;
  target: number;
  unit: string;
  progressPercent: number;
  status: "LOW" | "GOOD" | "HIGH";
};

export type HealthSummary = {
  periodDays: number;
  trackedNutritionDays: number;
  generatedAt: string;
  overallScore: number;
  bmi: number;
  bmiCategory: string;
  currentWeight?: number | null;
  weightChange?: number | null;
  mealCount: number;
  workoutSessions: number;
  workoutMinutes: number;
  activeDays: number;
  nutrients: NutrientMetric[];
  insights: string[];
  disclaimer: string;
};

export type HealthReminder = {
  id: string;
  type: string;
  title: string;
  message?: string | null;
  reminderTime: string;
  daysOfWeek: string[];
  enabled: boolean;
  lastTriggeredDate?: string | null;
  createdAt: string;
};

export type ReminderInput = Omit<HealthReminder, "id" | "lastTriggeredDate" | "createdAt">;

export async function getHealthSummary(days = 30): Promise<HealthSummary> {
  const response = await api.get("/health-management/summary", { params: { days } });
  return response.data;
}

export async function getHealthReminders(): Promise<HealthReminder[]> {
  const response = await api.get("/reminders");
  return response.data;
}

export async function createHealthReminder(payload: ReminderInput): Promise<HealthReminder> {
  const response = await api.post("/reminders", payload);
  return response.data;
}

export async function deleteHealthReminder(id: string): Promise<void> {
  await api.delete(`/reminders/${id}`);
}
