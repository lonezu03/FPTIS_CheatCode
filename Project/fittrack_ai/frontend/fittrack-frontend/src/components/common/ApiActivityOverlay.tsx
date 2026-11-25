import { LoaderCircle } from "lucide-react";
import { useSyncExternalStore } from "react";

import { apiActivityStore } from "@/lib/api-activity";

export default function ApiActivityOverlay() {
  const activity = useSyncExternalStore(
    apiActivityStore.subscribe,
    apiActivityStore.getSnapshot,
    apiActivityStore.getSnapshot,
  );

  // Reads (including silent background refreshes) show no global indicator; each page
  // has its own loading state. Only saves block the screen.
  if (activity.pendingMutations === 0) return null;

  return (
    <>
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
                Đợ 1 chúc 
              </p>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
