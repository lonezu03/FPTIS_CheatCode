import api from "./axios";

export type BodyMeasurement = {
  id: string;
  weight: number;
  waist: number;
  chest: number;
  arm: number;
  thigh: number;
  recordDate: string;
  createdAt: string;
};

export const getBodyMeasurements = async (): Promise<BodyMeasurement[]> => {
  const response = await api.get("/body-measurements");

  return response.data;
};

export const createBodyMeasurement = async (payload: {
  weight: number;
  waist: number;
  chest: number;
  arm: number;
  thigh: number;
  recordDate: string;
}): Promise<BodyMeasurement> => {
  const response = await api.post("/body-measurements", payload);

  return response.data;
};

export const deleteBodyMeasurement = async (id: string): Promise<void> => {
  await api.delete(`/body-measurements/${id}`);
};
