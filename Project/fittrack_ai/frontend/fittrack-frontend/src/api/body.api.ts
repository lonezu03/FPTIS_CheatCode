import api from "./axios";
import type { PageResponse } from "./pagination";

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

export const getBodyMeasurementsPage = async (
  page = 0,
  size = 20,
): Promise<PageResponse<BodyMeasurement>> => {
  const response = await api.get<PageResponse<BodyMeasurement>>("/body-measurements/page", {
    params: { page, size },
  });
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

export const updateBodyMeasurement = async (
  id: string,
  payload: {
    weight: number;
    waist: number;
    chest: number;
    arm: number;
    thigh: number;
    recordDate: string;
  }
): Promise<BodyMeasurement> => {
  const response = await api.put(`/body-measurements/${id}`, payload);

  return response.data;
};
