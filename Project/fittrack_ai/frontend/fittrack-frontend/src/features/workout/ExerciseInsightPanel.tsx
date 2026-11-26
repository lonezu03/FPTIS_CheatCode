import { Lightbulb, RefreshCw, Star, Trophy } from "lucide-react";

import type { AlternativeExercise, Exercise, ExercisePreference, WorkoutIntelligence } from "@/api/workout.api";
import { Button } from "@/components/ui/button";
import {
  formatNumber,
  personalBestUnit,
  personalRecordLabel,
  progressionActionLabel,
  type DraftExercise,
} from "./workout-utils";

/** Gợi ý mức tạ, mức ưu tiên và danh sách bài thay thế của một bài. */
export default function ExerciseInsightPanel({
  group,
  exercise,
  exercises,
  insight,
  preference,
  editingSession,
  alternativesOpened,
  alternativeState,
  alternativeEquipment,
  onApplyProgression,
  onPreferenceChange,
  onLoadAlternatives,
  onEquipmentChange,
  onPickAlternative,
}: {
  group: DraftExercise;
  exercise?: Exercise;
  exercises: Exercise[];
  insight: WorkoutIntelligence | null | undefined;
  preference: ExercisePreference;
  editingSession: boolean;
  alternativesOpened: boolean;
  alternativeState: AlternativeExercise[] | null | undefined;
  alternativeEquipment: string;
  onApplyProgression: () => void;
  onPreferenceChange: (preference: ExercisePreference) => void;
  onLoadAlternatives: () => void;
  onEquipmentChange: (equipment: string) => void;
  onPickAlternative: (item: AlternativeExercise) => void;
}) {
  const equipmentOptions = [...new Set(exercises.filter(x => x.muscleGroup === exercise?.muscleGroup).map(x => x.equipment))].sort();
  return (
    <details className="rounded-2xl border border-emerald-100 bg-emerald-50/30 p-3">
      <summary className="cursor-pointer text-sm font-semibold text-emerald-900">Gợi ý mức tạ, mức ưu tiên và bài thay thế</summary>
      <div className="mt-3 grid gap-3 lg:grid-cols-[1fr_auto]">
        <div className="rounded-2xl border border-emerald-100 bg-emerald-50/70 p-3">
          {insight === undefined ? (
            <p className="text-sm text-muted-foreground">Đang phân tích lần tập trước...</p>
          ) : insight === null ? (
            <p className="text-sm text-muted-foreground">Chưa thể tải đề xuất. Bạn vẫn có thể tập và lưu bình thường.</p>
          ) : (
            <div className="space-y-2">
              <div className="flex flex-wrap items-start justify-between gap-2">
                <div>
                  <p className="flex items-center gap-1.5 text-sm font-bold text-emerald-950">
                    <Lightbulb className="h-4 w-4" /> {progressionActionLabel(insight.progression.action)}
                  </p>
                  <p className="mt-1 text-xs text-emerald-900/75">{insight.progression.explanation}</p>
                </div>
                {insight.progression.suggestedWeight != null && (
                  <Button type="button" size="sm" onClick={onApplyProgression}>
                    Áp dụng {formatNumber(insight.progression.suggestedWeight)} kg · {insight.progression.suggestedSets} set
                  </Button>
                )}
              </div>
              {!!insight.personalBests.length && (
                <div className="flex flex-wrap gap-2">
                  {insight.personalBests.map((best) => (
                    <span key={best.type} className="rounded-full bg-white px-2.5 py-1 text-xs font-medium text-emerald-800 shadow-sm">
                      <Trophy className="mr-1 inline h-3.5 w-3.5" />
                      {personalRecordLabel(best.type)}: {formatNumber(best.value)} {personalBestUnit(best.type)}
                    </span>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
        <div className="flex flex-wrap items-center gap-2 lg:max-w-[330px] lg:justify-end">
          <label className="sr-only" htmlFor={`preference-${group.key}`}>Mức ưu tiên bài tập</label>
          <select
            id={`preference-${group.key}`}
            className="h-9 rounded-xl border bg-white px-3 text-sm"
            value={preference}
            onChange={(event) => onPreferenceChange(event.target.value as ExercisePreference)}
          >
            <option value="FAVORITE">★ Yêu thích</option>
            <option value="NORMAL">Bình thường</option>
            <option value="LESS">Ít ưu tiên</option>
            <option value="EXCLUDED">Không đề xuất</option>
          </select>
          <Button disabled={editingSession || group.sets.every(s => s.completed)} type="button" variant="outline" size="sm" onClick={onLoadAlternatives}>
            <RefreshCw className={`h-4 w-4 ${alternativesOpened && alternativeState === null ? "animate-spin" : ""}`} />
            Đổi bài tương đương
          </Button>
        </div>
      </div>
      {alternativesOpened && alternativeState && (
        <div className="rounded-2xl border bg-slate-50 p-3">
          <label className="mb-3 block text-sm">Lọc dụng cụ<select className="mt-1 w-full rounded-xl border p-2" value={alternativeEquipment} onChange={e => onEquipmentChange(e.target.value)}><option value="">Tất cả dụng cụ</option>{equipmentOptions.map(value => <option key={value} value={value}>{value}</option>)}</select></label>
          <p className="mb-3 text-sm text-amber-800">Bài mới bắt đầu từ 0 kg, nhớ chọn lại mức tạ.</p>
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
            Cùng nhóm cơ {exercise?.muscleGroup ?? ""}
          </p>
          {alternativeState.length ? (
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
              {alternativeState.filter(item => !alternativeEquipment || item.exercise.equipment === alternativeEquipment).map((item) => (
                <button
                  type="button"
                  key={item.exercise.id}
                  className="rounded-xl border bg-white p-3 text-left transition hover:border-emerald-400 hover:bg-emerald-50"
                  onClick={() => onPickAlternative(item)}
                >
                  <span className="flex items-center gap-1 font-semibold">
                    {item.preference === "FAVORITE" && <Star className="h-4 w-4 fill-amber-400 text-amber-500" />}
                    {item.exercise.name}
                  </span>
                  <span className="mt-1 block text-xs text-muted-foreground">
                    {item.exercise.equipment}{item.sameEquipment ? " · Cùng dụng cụ" : ""}
                  </span>
                </button>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">Chưa có bài thay thế phù hợp đã được duyệt.</p>
          )}
        </div>
      )}
    </details>
  );
}
