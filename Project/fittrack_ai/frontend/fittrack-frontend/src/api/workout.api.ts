import api from "./axios";
import type { PageResponse } from "./pagination";

export type Exercise = {
  id: string;
  name: string;
  muscleGroup: string;
  equipment: string;
  description: string;
};

export type WorkoutSetResponse = {
  id: string;
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
  setNumber: number;
  exerciseOrder: number;
  setType: WorkoutSetType;
  weight: number;
  reps: number;
  rir: number;
  restSeconds: number;
  completed: boolean;
};

export type WorkoutSetType = "WARMUP" | "NORMAL" | "DROP" | "FAILURE";

export type PreviousWorkoutPerformance = {
  exerciseId: string;
  exerciseName: string;
  sessionDate: string;
  sets: WorkoutSetResponse[];
};

export type WorkoutSession = {
  id: string;
  sessionDate: string;
  note: string;
  durationMinutes: number;
  createdAt: string;
  sets: WorkoutSetResponse[];
};

export const getExercises = async (): Promise<Exercise[]> => {
  const response = await api.get("/exercises");

  return response.data;
};

export const getWorkoutSessions = async (): Promise<WorkoutSession[]> => {
  const response = await api.get("/workouts/sessions");

  return response.data;
};

export const getWorkoutSessionsPage = async (
  page = 0,
  size = 20,
): Promise<PageResponse<WorkoutSession>> => {
  const response = await api.get<PageResponse<WorkoutSession>>("/workouts/sessions/page", {
    params: { page, size },
  });
  return response.data;
};

export const createWorkoutSession = async (payload: {
  sessionDate: string;
  note: string;
  durationMinutes: number;
  sets: {
    exerciseId: string;
    setNumber: number;
    exerciseOrder: number;
    setType: WorkoutSetType;
    weight: number;
    reps: number;
    rir: number;
    restSeconds: number;
    completed: boolean;
  }[];
}): Promise<WorkoutSession> => {
  const response = await api.post("/workouts/sessions", payload);

  return response.data;
};

export const getPreviousWorkoutPerformance = async (
  exerciseId: string,
): Promise<PreviousWorkoutPerformance | null> => {
  const response = await api.get<PreviousWorkoutPerformance | undefined>(
    "/workouts/previous-performance",
    { params: { exerciseId } },
  );
  return response.data ?? null;
};

export const deleteWorkoutSession = async (id: string): Promise<void> => {
  await api.delete(`/workouts/sessions/${id}`);
};

export const updateWorkoutSession = async (
  id: string,
  payload: {
    sessionDate: string;
    note: string;
    durationMinutes: number;
    weight: number;
    reps: number;
    rir: number;
  }
): Promise<WorkoutSession> => {
  const response = await api.put(`/workouts/sessions/${id}`, payload);

  return response.data;
};
