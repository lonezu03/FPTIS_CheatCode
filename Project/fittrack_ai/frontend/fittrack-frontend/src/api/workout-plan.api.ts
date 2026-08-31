import api from "./axios";
import type { WorkoutSession } from "./workout.api";
import type { PageResponse } from "./pagination";

export type WorkoutPlanExercise = {
  id: string;
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
  equipment: string | null;
  description: string | null;
  imageUrl: string | null;
  exerciseOrder: number;
  targetSets: number;
  targetReps: number;
  targetWeight: number;
  targetRir: number;
};

export type WorkoutPlanDay = {
  id: string;
  name: string;
  dayOrder: number;
  exercises: WorkoutPlanExercise[];
};

export type WorkoutPlan = {
  id: string;
  name: string;
  description: string;
  createdAt: string;
  days: WorkoutPlanDay[];
};

export const getWorkoutPlans = async (): Promise<WorkoutPlan[]> => {
  const response = await api.get("/workout-plans");

  return response.data;
};

export const getWorkoutPlansPage = async (
  page = 0,
  size = 12,
): Promise<PageResponse<WorkoutPlan>> => {
  const response = await api.get<PageResponse<WorkoutPlan>>("/workout-plans/page", {
    params: { page, size },
  });
  return response.data;
};

export const createWorkoutPlan = async (payload: {
  name: string;
  description: string;
  days: {
    name: string;
    dayOrder: number;
    exercises: {
      exerciseId: string;
      exerciseOrder: number;
      targetSets: number;
      targetReps: number;
      targetWeight: number;
      targetRir: number;
    }[];
  }[];
}): Promise<WorkoutPlan> => {
  const response = await api.post("/workout-plans", payload);

  return response.data;
};

export const deleteWorkoutPlan = async (id: string): Promise<void> => {
  await api.delete(`/workout-plans/${id}`);
};

export const generateSessionFromPlan = async (
  planId: string,
  payload: {
    dayId: string;
    sessionDate: string;
    note: string;
  }
): Promise<WorkoutSession> => {
  const response = await api.post(`/workout-plans/${planId}/generate-session`, payload);

  return response.data;
};
