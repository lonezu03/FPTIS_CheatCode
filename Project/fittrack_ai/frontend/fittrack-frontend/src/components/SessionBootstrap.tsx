import { useEffect, type PropsWithChildren } from "react";
import { refreshSessionApi } from "../api/auth.api";
import { useAuthStore } from "../store/auth.store";

export default function SessionBootstrap({ children }: PropsWithChildren) {
  const initialized = useAuthStore((state) => state.initialized);

  useEffect(() => {
    let active = true;
    refreshSessionApi()
      .then((session) => {
        if (!active) return;
        useAuthStore.getState().setSession(session.token, session);
      })
      .catch(() => {
        if (active) useAuthStore.getState().logout();
      })
      .finally(() => {
        if (active) useAuthStore.getState().setInitialized(true);
      });
    return () => {
      active = false;
    };
  }, []);

  if (!initialized) {
    return <div className="grid min-h-screen place-items-center text-sm text-muted-foreground">Đang khôi phục phiên đăng nhập...</div>;
  }
  return children;
}
