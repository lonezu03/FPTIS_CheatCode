import { CheckCircle2, Plus, X } from "lucide-react";

import type { WorkoutSetType } from "@/api/workout.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  appendSet,
  removeLastSet,
  setTypeLabels,
  updateSet,
  type DraftExercise,
} from "./workout-utils";

/** Bảng nhập set (loại, kg, lần, RIR, xong) của một bài trong buổi tập. */
export default function SetEditor({
  group,
  onUpdate,
  onToggleSet,
}: {
  group: DraftExercise;
  onUpdate: (updater: (group: DraftExercise) => DraftExercise) => void;
  onToggleSet: (setKey: string) => void;
}) {
  return (
    <>
      <div className="hidden grid-cols-[38px_1.2fr_0.8fr_0.8fr_0.7fr_42px] gap-2 px-1 pb-2 text-center text-xs font-semibold text-muted-foreground sm:grid">
        <span>Set</span><span>Loại</span><span>Kg</span><span>Reps</span><span>RIR</span><span>Xong</span>
      </div>
      <div className="space-y-2">
        {group.sets.map((set, setIndex) => (
          <div key={set.key} className={`grid grid-cols-3 gap-2 rounded-xl border p-3 sm:grid-cols-[38px_1.2fr_0.8fr_0.8fr_0.7fr_42px] sm:border-0 sm:p-1 ${set.completed ? "border-emerald-300 bg-emerald-50" : "bg-slate-50"}`}>
            <div className="flex items-center font-bold sm:justify-center"><span className="sm:hidden">Hiệp&nbsp;</span>{setIndex + 1}</div>
            <select aria-label={`Hiệp ${setIndex + 1} loại hiệp`} className="col-span-2 h-10 min-w-0 rounded-lg border bg-white px-2 text-sm sm:col-span-1" value={set.setType} onChange={(event) => onUpdate((item) => updateSet(item, set.key, { setType: event.target.value as WorkoutSetType }))}>
              {Object.entries(setTypeLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
            </select>
            <label className="text-xs font-medium sm:contents"><span className="mb-1 block sm:hidden">Kg</span><Input aria-label={`Hiệp ${setIndex + 1} mức tạ kg`} type="number" min={0} step={0.5} value={set.weight} onChange={(event) => onUpdate((item) => updateSet(item, set.key, { weight: Number(event.target.value) }))} /></label>
            <label className="text-xs font-medium sm:contents"><span className="mb-1 block sm:hidden">Lần</span><Input aria-label={`Hiệp ${setIndex + 1} số lần`} type="number" min={1} max={500} value={set.reps} onChange={(event) => onUpdate((item) => updateSet(item, set.key, { reps: Number(event.target.value) }))} /></label>
            <label className="text-xs font-medium sm:contents"><span className="mb-1 block sm:hidden">RIR</span><Input aria-label={`Hiệp ${setIndex + 1} RIR`} type="number" min={0} max={10} value={set.rir} onChange={(event) => onUpdate((item) => updateSet(item, set.key, { rir: Number(event.target.value) }))} /></label>
            <Button type="button" className="col-span-3 w-full sm:col-span-1 sm:w-auto" variant={set.completed ? "default" : "outline"} onClick={() => onToggleSet(set.key)} aria-label={`Hiệp ${setIndex + 1} ${set.completed ? "đã xong" : "đánh dấu xong"}`}><CheckCircle2 /><span className="sm:hidden">{set.completed ? "Đã xong" : "Xong hiệp"}</span></Button>
          </div>
        ))}
      </div>
      <div className="mt-3 flex flex-wrap gap-2">
        <Button variant="outline" size="sm" onClick={() => onUpdate(appendSet)}><Plus />Thêm set</Button>
        <Button variant="ghost" size="sm" onClick={() => onUpdate(removeLastSet)} disabled={group.sets.length === 1}><X />Bỏ set cuối</Button>
      </div>
    </>
  );
}
