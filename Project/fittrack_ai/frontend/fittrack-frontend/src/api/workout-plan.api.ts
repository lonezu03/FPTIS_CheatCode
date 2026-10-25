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
  restSeconds?: number | null;
  minReps?: number | null;
  maxReps?: number | null;
  coachingNote?: string | null;
};

export type WorkoutPlanDay = {
  id: string;
  name: string;
  dayOrder: number;
  exercises: WorkoutPlanExercise[];
};

export type WorkoutPlan = {
  version?: number;
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
export const getWorkoutPlanDetail = async (id: string): Promise<WorkoutPlan> => (await api.get(`/workout-plans/${id}`)).data;

export const getWorkoutPlansPage = async (
  page = 0,
  size = 12,
): Promise<PageResponse<WorkoutPlan>> => {
  const response = await api.get<PageResponse<WorkoutPlan>>("/workout-plans/page", {
    params: { page, size },
  });
  return response.data;
};

export type WorkoutPlanPayload = {
  version?: number;
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
      restSeconds?: number;
      minReps?: number;
      maxReps?: number;
      coachingNote?: string;
    }[];
  }[];
};

export const createWorkoutPlan = async (payload: WorkoutPlanPayload): Promise<WorkoutPlan> => {
  const response = await api.post("/workout-plans", payload);

  return response.data;
};

export const updateWorkoutPlan = async (id: string, payload: WorkoutPlanPayload): Promise<WorkoutPlan> => {
  const response = await api.put(`/workout-plans/${id}`, payload);
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
