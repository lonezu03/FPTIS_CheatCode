import axios from "axios";

// Mirrors the backend's local default: SERVER_PORT falls back to 8081.
const DEFAULT_API_URL = "http://localhost:8081/api";
const envApiUrl = (import.meta.env.VITE_API_URL as string | undefined)?.trim();

const baseURL =
  import.meta.env.PROD && envApiUrl && /(^|\/)localhost(?::\d+)?(\/|$)/i.test(envApiUrl)
    ? DEFAULT_API_URL
    : envApiUrl || DEFAULT_API_URL;

const api = axios.create({
  baseURL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("fittrack-user");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }

    return Promise.reject(error);
  }
);

export default api;
