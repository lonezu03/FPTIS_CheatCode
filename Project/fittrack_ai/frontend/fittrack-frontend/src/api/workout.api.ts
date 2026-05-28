import api from "./axios";

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
  weight: number;
  reps: number;
  rir: number;
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

export const createWorkoutSession = async (payload: {
  sessionDate: string;
  note: string;
  durationMinutes: number;
  sets: {
    exerciseId: string;
    setNumber: number;
    weight: number;
    reps: number;
    rir: number;
  }[];
}): Promise<WorkoutSession> => {
  const response = await api.post("/workouts/sessions", payload);

  return response.data;
};

export const deleteWorkoutSession = async (id: string): Promise<void> => {
  await api.delete(`/workouts/sessions/${id}`);
};

export const updateWorkoutSession = async (
  id: string,
  payload: {
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
