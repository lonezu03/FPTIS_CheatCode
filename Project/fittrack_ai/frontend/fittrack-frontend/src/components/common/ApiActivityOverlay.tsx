import { LoaderCircle } from "lucide-react";
import { useSyncExternalStore } from "react";

import { apiActivityStore } from "@/lib/api-activity";

export default function ApiActivityOverlay() {
  const activity = useSyncExternalStore(
    apiActivityStore.subscribe,
    apiActivityStore.getSnapshot,
    apiActivityStore.getSnapshot,
  );

  if (activity.pendingRequests === 0) return null;

  return (
    <>
      <div
        className="pointer-events-none fixed inset-x-0 top-0 z-[120] h-1 overflow-hidden bg-emerald-100"
        aria-hidden="true"
      >
        <div className="h-full w-2/3 animate-pulse rounded-r-full bg-emerald-600" />
      </div>

      {activity.pendingMutations > 0 ? (
        <div
          className="fixed inset-0 z-[110] flex items-center justify-center bg-slate-950/20 px-4 backdrop-blur-[1px]"
          role="status"
          aria-live="polite"
          aria-busy="true"
          aria-label="Đang xử lý yêu cầu"
        >
          <div className="flex max-w-sm items-center gap-3 rounded-2xl border border-emerald-100 bg-white px-5 py-4 shadow-2xl">
            <LoaderCircle className="size-6 shrink-0 animate-spin text-emerald-700" aria-hidden="true" />
            <div>
              <p className="font-semibold text-slate-900">Đang xử lý...</p>
              <p className="mt-0.5 text-sm text-slate-600">
                Vui lòng chờ API phản hồi và không gửi lại thao tác.
              </p>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
