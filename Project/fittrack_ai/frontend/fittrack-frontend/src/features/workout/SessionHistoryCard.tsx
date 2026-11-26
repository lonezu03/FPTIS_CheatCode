import { useMemo } from "react";
import { Trash2 } from "lucide-react";

import type { WorkoutSession } from "@/api/workout.api";
import { Button } from "@/components/ui/button";
import { groupSessionSets, sessionVolume, setTypeLabels } from "./workout-utils";

/** Một buổi trong lịch sử, mở ra xem các set theo từng bài. */
export default function SessionHistoryCard({ session, onDelete, onEdit }: { session: WorkoutSession; onDelete: () => void; onEdit: () => void }) {
  const exerciseGroups = useMemo(() => groupSessionSets(session.sets), [session]);
  const volume = sessionVolume(session);

  return (
    <details className="rounded-2xl border bg-white p-4 open:shadow-sm">
      <summary className="flex cursor-pointer list-none flex-wrap items-center justify-between gap-3">
        <div>
          <p className="font-bold">{session.note || "Buổi tập"}</p>
          <p className="text-xs text-muted-foreground">{session.sessionDate} · {exerciseGroups.length} bài · {session.sets.length} set · {session.durationMinutes} phút</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">{Math.round(volume).toLocaleString("vi-VN")} kg</span>
          <Button variant="outline" size="sm" onClick={event => { event.preventDefault(); onEdit(); }}>Chỉnh sửa</Button>
          <Button variant="destructive" size="sm" onClick={(event) => { event.preventDefault(); onDelete(); }}><Trash2 />Xóa</Button>
        </div>
      </summary>
      <div className="mt-4 grid gap-3 md:grid-cols-2">
        {exerciseGroups.map((sets) => (
          <div key={`${sets[0].exerciseId}-${sets[0].exerciseOrder}`} className="rounded-xl bg-slate-50 p-3">
            <p className="font-semibold">{sets[0].exerciseName}</p>
            <div className="mt-2 space-y-1 text-sm text-muted-foreground">
              {sets.map((set) => (
                <p key={set.id}>Set {set.setNumber} · {setTypeLabels[set.setType ?? "NORMAL"]} · {set.weight} kg × {set.reps} · RIR {set.rir}</p>
              ))}
            </div>
          </div>
        ))}
      </div>
    </details>
  );
}
