import axios from "axios";
import { useAuthStore, type AuthUser } from "../store/auth.store";

// Mirrors the backend's local default: SERVER_PORT falls back to 8081.
const DEFAULT_API_URL = "http://localhost:8082/api";
const envApiUrl = (import.meta.env.VITE_API_URL as string | undefined)?.trim();

if (import.meta.env.PROD && !envApiUrl) {
  throw new Error("Thiếu VITE_API_URL cho bản dựng production");
}
if (import.meta.env.PROD && envApiUrl && /(^|\/)localhost(?::\d+)?(\/|$)/i.test(envApiUrl)) {
  throw new Error("VITE_API_URL production không được trỏ tới localhost");
}

export const baseURL = envApiUrl || DEFAULT_API_URL;

const api = axios.create({
  baseURL,
  withCredentials: true,
  headers: { "X-Requested-With": "XMLHttpRequest" },
});

export function resolveApiAssetUrl(value: string): string {
  if (!value.startsWith("/api/")) {
    return value;
  }
  const backendRoot = baseURL.replace(/\/api\/?$/i, "");
  return `${backendRoot}${value}`;
}

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

let refreshPromise: Promise<string> | null = null;

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const original = error.config as (typeof error.config & { _retried?: boolean }) | undefined;
    const isAuthRequest = original?.url?.includes("/auth/login") || original?.url?.includes("/auth/refresh");

    if (error.response?.status === 401 && original && !original._retried && !isAuthRequest) {
      original._retried = true;
      refreshPromise ??= axios
        .post(
          `${baseURL}/auth/refresh`,
          {},
          { withCredentials: true, headers: { "X-Requested-With": "XMLHttpRequest" } },
        )
        .then((response) => {
          const data = response.data as AuthUser & { token: string };
          useAuthStore.getState().setSession(data.token, data);
          return data.token;
        })
        .finally(() => {
          refreshPromise = null;
        });

      return refreshPromise
        .then((token) => {
          original.headers.Authorization = `Bearer ${token}`;
          return api(original);
        })
        .catch((refreshError) => {
          useAuthStore.getState().logout();
          if (window.location.pathname !== "/login") window.location.href = "/login";
          return Promise.reject(refreshError);
        });
    }

    if (error.response?.status === 401 && isAuthRequest) {
      useAuthStore.getState().logout();
    }

    return Promise.reject(error);
  }
);

export default api;
