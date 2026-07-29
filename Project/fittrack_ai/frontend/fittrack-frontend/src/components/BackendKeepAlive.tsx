import { useEffect } from "react";
import api from "@/api/axios";

const configuredMinutes = Number(import.meta.env.VITE_KEEP_ALIVE_MINUTES ?? 10);
const keepAliveMinutes = Number.isFinite(configuredMinutes)
  ? Math.min(Math.max(configuredMinutes, 5), 14)
  : 10;

export default function BackendKeepAlive() {
  useEffect(() => {
    const timer = window.setInterval(() => {
      void api.get("/health", { timeout: 15_000 }).catch(() => {
        // The next normal API request will retry and wake a sleeping Render instance.
      });
    }, keepAliveMinutes * 60 * 1000);

    return () => window.clearInterval(timer);
  }, []);

  return null;
}
