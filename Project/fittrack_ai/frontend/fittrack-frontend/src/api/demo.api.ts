import api from "./axios";

export type DemoSeedResponse = {
  message: string;
  foodsCreated: number;
  exercisesCreated: number;
  mealLogsCreated: number;
  workoutSessionsCreated: number;
  bodyMeasurementsCreated: number;
};

export const seedDemoData = async (): Promise<DemoSeedResponse> => {
  const response = await api.post("/demo/seed");
  return response.data;
};
