import { ArrowDown, ArrowUp, Trash2 } from "lucide-react";

import type { AlternativeExercise, Exercise, ExercisePreference, WorkoutIntelligence } from "@/api/workout.api";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import ExercisePicker from "@/components/workouts/ExercisePicker";
import WorkoutGroupFields from "@/components/workouts/WorkoutGroupFields";
import ExerciseInsightPanel from "./ExerciseInsightPanel";
import SetEditor from "./SetEditor";
import { setGroupRest, type DraftExercise } from "./workout-utils";

/** Một bài trong buổi tập trực tiếp: chọn bài, nghỉ, nhóm, gợi ý và các set. */
export default function LiveExerciseCard({
  group,
  index,
  total,
  exercises,
  editingSession,
  insight,
  preference,
  alternativesOpened,
  alternativeState,
  alternativeEquipment,
  onUpdate,
  onMove,
  onRemove,
  onChangeExercise,
  onToggleSet,
  onApplyProgression,
  onPreferenceChange,
  onLoadAlternatives,
  onEquipmentChange,
  onPickAlternative,
}: {
  group: DraftExercise;
  index: number;
  total: number;
  exercises: Exercise[];
  editingSession: boolean;
  insight: WorkoutIntelligence | null | undefined;
  preference: ExercisePreference;
  alternativesOpened: boolean;
  alternativeState: AlternativeExercise[] | null | undefined;
  alternativeEquipment: string;
  onUpdate: (updater: (group: DraftExercise) => DraftExercise) => void;
  onMove: (direction: -1 | 1) => void;
  onRemove: () => void;
  onChangeExercise: (exerciseId: string) => void;
  onToggleSet: (setKey: string) => void;
  onApplyProgression: () => void;
  onPreferenceChange: (preference: ExercisePreference) => void;
  onLoadAlternatives: () => void;
  onEquipmentChange: (equipment: string) => void;
  onPickAlternative: (item: AlternativeExercise) => void;
}) {
  const exercise = exercises.find((item) => item.id === group.exerciseId);
  const last = insight?.previousPerformance;
  return (
    <Card className="border-slate-200">
      <CardHeader className="gap-3 pb-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div>
            <CardTitle>{index + 1}. {exercise?.name ?? group.historicalExerciseName ?? "Bài tập"}</CardTitle>
            {!exercise && group.historicalExerciseName && <p className="text-xs text-amber-700">Bài lịch sử đã lưu trữ; giữ nguyên hoặc chọn bài khác.</p>}
            {group.coachingNote && <p className="text-sm text-emerald-700">{group.coachingNote}</p>}
            <p className="mt-1 text-xs text-muted-foreground">
              {last
                ? `Lần gần nhất ${last.sessionDate}: ${last.sets.map((set) => `${set.weight}kg × ${set.reps}`).join(" · ")}`
                : "Chưa có dữ liệu lần tập trước"}
            </p>
          </div>
          <div className="flex gap-1">
            <Button variant="outline" size="icon-sm" onClick={() => onMove(-1)} disabled={index === 0} aria-label="Đưa bài lên"><ArrowUp /></Button>
            <Button variant="outline" size="icon-sm" onClick={() => onMove(1)} disabled={index === total - 1} aria-label="Đưa bài xuống"><ArrowDown /></Button>
            <Button variant="destructive" size="icon-sm" onClick={onRemove} disabled={total === 1} aria-label="Xóa bài"><Trash2 /></Button>
          </div>
        </div>
        <div className="grid gap-2 sm:grid-cols-[1fr_150px]">
          <ExercisePicker
            id={`live-exercise-${group.key}`}
            exercises={exercises}
            value={group.exerciseId}
            missingValueLabel={group.historicalExerciseName}
            onChange={onChangeExercise}
          />
          <label className="flex items-center gap-2 text-xs text-muted-foreground">
            Nghỉ
            <Input type="number" min={0} max={1800} value={group.restSeconds} onChange={(event) => onUpdate((item) => setGroupRest(item, Number(event.target.value)))} />
            giây
          </label>
        </div>
        {editingSession && new Set(group.sets.map(set => set.restSeconds ?? group.restSeconds)).size > 1 && <p className="text-xs text-muted-foreground">Đổi ô Nghỉ sẽ áp dụng cho mọi hiệp của bài này.</p>}
        <WorkoutGroupFields value={group} onChange={fields => onUpdate(item => ({ ...item, ...fields }))} />
        <ExerciseInsightPanel
          group={group}
          exercise={exercise}
          exercises={exercises}
          insight={insight}
          preference={preference}
          editingSession={editingSession}
          alternativesOpened={alternativesOpened}
          alternativeState={alternativeState}
          alternativeEquipment={alternativeEquipment}
          onApplyProgression={onApplyProgression}
          onPreferenceChange={onPreferenceChange}
          onLoadAlternatives={onLoadAlternatives}
          onEquipmentChange={onEquipmentChange}
          onPickAlternative={onPickAlternative}
        />
      </CardHeader>
      <CardContent>
        <SetEditor group={group} onUpdate={onUpdate} onToggleSet={onToggleSet} />
      </CardContent>
    </Card>
  );
}
