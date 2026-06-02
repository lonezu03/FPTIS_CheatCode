import api from "./axios";

export type Exercise = {
  id: string;
  name: string;
  muscleGroup: string;
  equipment: string;
  description: string;
  custom: boolean;
  active: boolean;
};

export const getExercisesApi = async (keyword?: string, includeInactive?: boolean): Promise<Exercise[]> => {
  const response = await api.get("/exercises", {
    params: {
      ...(keyword ? { keyword } : {}),
      ...(includeInactive ? { includeInactive } : {}),
    },
  });

  return response.data;
};

export const createExerciseApi = async (payload: {
  name: string;
  muscleGroup: string;
  equipment: string;
  description: string;
}): Promise<Exercise> => {
  const response = await api.post("/exercises", payload);

  return response.data;
};

export const updateExerciseApi = async (
  id: string,
  payload: {
    name: string;
    muscleGroup: string;
    equipment: string;
    description: string;
  }
): Promise<Exercise> => {
  const response = await api.put(`/exercises/${id}`, payload);

  return response.data;
};

export const deleteExerciseApi = async (id: string): Promise<void> => {
  await api.delete(`/exercises/${id}`);
};

export const restoreExerciseApi = async (id: string): Promise<Exercise> => {
  const response = await api.patch(`/exercises/${id}/restore`);

  return response.data;
};
