import axios, { AxiosError, type InternalAxiosRequestConfig } from "axios";
import {
  apiActivityStore,
  createMutationKey,
  DUPLICATE_MUTATION_MESSAGE,
  isMutationMethod,
  MutationRequestGuard,
} from "../lib/api-activity";
import { useAuthStore, type AuthUser } from "../store/auth.store";

// Mirrors the backend's local default: SERVER_PORT falls back to 8081.
const DEFAULT_API_URL = "http://localhost:8082/api";
const envApiUrl = (import.meta.env.VITE_API_URL as string | undefined)?.trim();
const apiMode = (import.meta.env.VITE_API_MODE as string | undefined)?.trim().toLowerCase();
const useSameOriginProxy = import.meta.env.PROD && apiMode !== "direct";

if (import.meta.env.PROD && !useSameOriginProxy && !envApiUrl) {
  throw new Error("Thiếu VITE_API_URL cho bản dựng production");
}
if (import.meta.env.PROD && !useSameOriginProxy && envApiUrl && /(^|\/)localhost(?::\d+)?(\/|$)/i.test(envApiUrl)) {
  throw new Error("VITE_API_URL production không được trỏ tới localhost");
}

// Vercel uses its /api rewrite so refresh cookies remain first-party and CSP
// can stay restricted to connect-src 'self'. Direct mode is only for the
// standalone Docker frontend, whose nginx CSP allows the configured backend.
export const baseURL = useSameOriginProxy ? "/api" : envApiUrl || DEFAULT_API_URL;

const api = axios.create({
  baseURL,
  withCredentials: true,
  headers: { "X-Requested-With": "XMLHttpRequest" },
});

type RequestTracking = {
  finish: () => void;
};

const requestTracking = new WeakMap<InternalAxiosRequestConfig, RequestTracking>();
const mutationGuard = new MutationRequestGuard();

function startTracking(config: InternalAxiosRequestConfig): void {
  const mutation = isMutationMethod(config.method);
  const releaseMutation = mutation
    ? mutationGuard.acquire(
        createMutationKey({
          method: config.method,
          baseURL: config.baseURL,
          url: config.url,
          params: config.params,
          data: config.data,
        }),
      )
    : undefined;

  if (mutation && !releaseMutation) {
    throw new AxiosError(
      DUPLICATE_MUTATION_MESSAGE,
      "ERR_DUPLICATE_MUTATION",
      config,
    );
  }

  const finishActivity = apiActivityStore.begin(mutation);
  let finished = false;
  requestTracking.set(config, {
    finish: () => {
      if (finished) return;
      finished = true;
      releaseMutation?.();
      finishActivity();
      requestTracking.delete(config);
    },
  });
}

function finishTracking(config?: InternalAxiosRequestConfig): void {
  if (config) requestTracking.get(config)?.finish();
}

const PUBLIC_AUTH_PATHS = [
  "/auth/login",
  "/auth/register",
  "/auth/refresh",
  "/auth/verify-email",
  "/auth/resend-verification",
  "/auth/forgot-password",
  "/auth/reset-password",
];

function isPublicAuthUrl(url?: string): boolean {
  if (!url) return false;
  return PUBLIC_AUTH_PATHS.some((path) => url.includes(path));
}

export function resolveApiAssetUrl(value: string): string {
  if (!value.startsWith("/api/")) {
    return value;
  }
  const backendRoot = baseURL.replace(/\/api\/?$/i, "");
  return `${backendRoot}${value}`;
}

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;

  if (token && !isPublicAuthUrl(config.url)) {
    config.headers.Authorization = `Bearer ${token}`;
  } else {
    delete config.headers.Authorization;
  }

  startTracking(config);

  return config;
});

let refreshPromise: Promise<string> | null = null;

api.interceptors.response.use(
  (response) => {
    finishTracking(response.config);
    return response;
  },
  (error) => {
    finishTracking(error.config);
    const original = error.config as (typeof error.config & { _retried?: boolean }) | undefined;
    const isAuthRequest = isPublicAuthUrl(original?.url);

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
