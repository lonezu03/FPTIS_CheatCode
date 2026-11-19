import { useEffect, useState, type PropsWithChildren } from "react";
import { RefreshCw, WifiOff } from "lucide-react";
import { refreshSessionApi } from "../api/auth.api";
import { SessionRefreshError } from "../api/session-refresh";
import { useAuthStore } from "../store/auth.store";
import { Button } from "@/components/ui/button";

export default function SessionBootstrap({ children }: PropsWithChildren) {
  const initialized = useAuthStore((state) => state.initialized);
  const [attempt, setAttempt] = useState(0);
  const [unreachable, setUnreachable] = useState(false);

  useEffect(() => {
    let active = true;
    refreshSessionApi()
      .then((session) => {
        if (!active) return;
        useAuthStore.getState().setSession(session.token, session);
        useAuthStore.getState().setInitialized(true);
      })
      .catch((error) => {
        if (!active) return;
        // The server could not be reached (cold start, 5xx, rate limit). Keep the
        // stored session and let the user retry instead of logging them out.
        if (error instanceof SessionRefreshError && !error.sessionInvalid && useAuthStore.getState().user) {
          setUnreachable(true);
          return;
        }
        useAuthStore.getState().logout();
        useAuthStore.getState().setInitialized(true);
      });
    return () => {
      active = false;
    };
  }, [attempt]);

  if (!initialized && unreachable) {
    return (
      <div className="grid min-h-screen place-items-center bg-background p-5">
        <section role="alert" className="w-full max-w-md rounded-3xl border bg-card p-7 text-center shadow-xl">
          <span className="mx-auto grid size-12 place-items-center rounded-2xl bg-amber-100 text-amber-700">
            <WifiOff className="size-6" />
          </span>
          <h1 className="mt-5 text-xl font-semibold tracking-tight">Chưa kết nối được máy chủ</h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">
            Máy chủ có thể đang khởi động lại. Phiên đăng nhập của bạn vẫn được giữ; hãy thử lại sau vài giây.
          </p>
          <div className="mt-6 grid gap-2">
            <Button
              onClick={() => {
                setUnreachable(false);
                setAttempt((value) => value + 1);
              }}
            >
              <RefreshCw className="size-4" />
              Thử lại
            </Button>
            <Button
              variant="ghost"
              onClick={() => {
                useAuthStore.getState().logout();
                useAuthStore.getState().setInitialized(true);
              }}
            >
              Đăng nhập lại
            </Button>
          </div>
        </section>
      </div>
    );
  }

  if (!initialized) {
    return <div className="grid min-h-screen place-items-center text-sm text-muted-foreground">Đang khôi phục phiên đăng nhập...</div>;
  }
  return children;
}
