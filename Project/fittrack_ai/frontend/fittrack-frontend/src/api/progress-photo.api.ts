import api from "./axios";

export type ProgressPhoto = { id: string; imageUrl: string; takenDate: string; pose: "FRONT" | "SIDE" | "BACK" | "OTHER"; note: string | null; weight: number | null; createdAt: string };

export const getProgressPhotos = async (): Promise<ProgressPhoto[]> => (await api.get("/progress-photos")).data;
export const createProgressPhoto = async (payload: { imageUrl: string; takenDate: string; pose: string; note?: string; weight?: number }): Promise<ProgressPhoto> => (await api.post("/progress-photos", payload)).data;
export const deleteProgressPhoto = async (id: string): Promise<void> => { await api.delete(`/progress-photos/${id}`); };
