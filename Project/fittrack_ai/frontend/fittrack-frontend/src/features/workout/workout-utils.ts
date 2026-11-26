import type {
  createWorkoutSession,
  Exercise,
  WorkoutIntelligence,
  WorkoutSession,
  WorkoutSetResponse,
  WorkoutSetType,
} from "@/api/workout.api";
import type { WorkoutPlan, WorkoutPlanDay } from "@/api/workout-plan.api";
import type { TrainingAppointment } from "@/api/training-program.api";
import { clearSessionDraft, readSessionDraft } from "@/lib/sessionDraft";
import { maximumWorkoutSeconds } from "@/lib/workoutDraftTime";

export type DraftSet = {
  key: string;
  setType: WorkoutSetType;
  weight: number;
  reps: number;
  rir: number;
  completed: boolean;
  restSeconds?: number;
};

export type DraftExercise = {
  originalExerciseId?: string;
  replacementKind?: "MANUAL" | "ALTERNATIVE" | null;
  key: string;
  exerciseId: string;
  historicalExerciseName?: string;
  restSeconds: number;
  targetSets: number;
  minReps: number;
  maxReps: number;
  targetRir: number;
  coachingNote?: string;
  groupKey?: string | null;
  groupType?: string | null;
  groupRounds?: number | null;
  betweenExerciseRestSeconds?: number | null;
  betweenRoundRestSeconds?: number | null;
  sets: DraftSet[];
};

export type WorkoutSeed = {
  title: string;
  exercises: DraftExercise[];
  note?: string;
  elapsedSeconds?: number;
  sessionId?: string;
  sessionDate?: string;
  durationMinutes?: number;
  appointmentId?: string;
};

export type WorkoutSessionPayload = Parameters<typeof createWorkoutSession>[0];
export type PersonalBestType = WorkoutIntelligence["personalBests"][number]["type"];
export type ProgressionActionType = WorkoutIntelligence["progression"]["action"];

export const setTypeLabels: Record<WorkoutSetType, string> = {
  WARMUP: "Khởi động",
  NORMAL: "Chính",
  DROP: "Drop set",
  FAILURE: "Tới ngưỡng",
};

export const draftKey = () => `${Date.now()}-${Math.random().toString(36).slice(2)}`;

/** Đọc bản nháp buổi tập của tài khoản; bản nháp hỏng sẽ bị xóa. */
export function readWorkoutDraft(owner: string): WorkoutSeed | null {
  const draft = readSessionDraft<WorkoutSeed>(owner, "workout");
  if (!draft) return null;
  if (!isValidWorkoutDraft(draft)) {
    clearSessionDraft(owner, "workout");
    return null;
  }
  return draft;
}

export function isValidWorkoutDraft(draft: WorkoutSeed): boolean {
  return typeof draft.title === "string" && (draft.note == null || typeof draft.note === "string")
    && (draft.elapsedSeconds == null || (Number.isFinite(draft.elapsedSeconds) && draft.elapsedSeconds >= 0 && draft.elapsedSeconds <= maximumWorkoutSeconds))
    && Array.isArray(draft.exercises) && draft.exercises.length > 0 && draft.exercises.every(group =>
      typeof group.key === "string" && typeof group.exerciseId === "string" && Number.isFinite(group.restSeconds)
      && (group.historicalExerciseName == null || typeof group.historicalExerciseName === "string")
      && Array.isArray(group.sets) && group.sets.every(set => typeof set.key === "string" && typeof set.completed === "boolean"
        && Object.hasOwn(setTypeLabels, set.setType) && [set.weight, set.reps, set.rir].every(Number.isFinite)
        && (set.restSeconds == null || (Number.isFinite(set.restSeconds) && set.restSeconds >= 0 && set.restSeconds <= 1800))));
}

export const makeSet = (overrides: Partial<DraftSet> = {}): DraftSet => ({
  key: draftKey(),
  setType: "NORMAL",
  weight: 0,
  reps: 10,
  rir: 2,
  completed: false,
  ...overrides,
});

export const makeExercise = (
  exerciseId: string,
  overrides: Partial<Omit<DraftExercise, "key" | "exerciseId">> = {},
): DraftExercise => ({
  key: draftKey(),
  exerciseId,
  restSeconds: 90,
  targetSets: 3,
  minReps: 8,
  maxReps: 12,
  targetRir: 2,
  sets: Array.from({ length: 3 }, () => makeSet()),
  ...overrides,
});

/** Buổi tập từ một lần tập trong lịch (`?appointment=`). */
export function seedFromAppointment(appointment: TrainingAppointment): WorkoutSeed {
  return {
    title: appointment.title,
    appointmentId: appointment.id,
    exercises: appointment.day.exercises.map(item => makeExercise(item.exerciseId, {
      ...item,
      coachingNote: item.coachingNote ?? "",
      restSeconds: item.restSeconds ?? 90,
      minReps: item.minReps ?? item.targetReps,
      maxReps: item.maxReps ?? item.targetReps,
      sets: Array.from({ length: item.targetSets }, () => makeSet({ weight: item.targetWeight ?? 0, reps: item.targetReps, rir: item.targetRir })),
    })),
  };
}

/** Buổi tập theo một ngày trong giáo án. */
export function seedFromPlanDay(plan: WorkoutPlan, day: WorkoutPlanDay): WorkoutSeed {
  return {
    title: `${plan.name} · ${day.name}`,
    exercises: day.exercises.map((item) =>
      makeExercise(item.exerciseId, {
        targetSets: Math.max(1, item.targetSets || 1),
        minReps: item.minReps ?? Math.max(1, (item.targetReps ?? 10) - 2),
        maxReps: item.maxReps ?? item.targetReps ?? 10,
        restSeconds: item.restSeconds ?? 90,
        coachingNote: item.coachingNote ?? "",
        groupKey: item.groupKey,
        groupType: item.groupType,
        groupRounds: item.groupRounds,
        betweenExerciseRestSeconds: item.betweenExerciseRestSeconds,
        betweenRoundRestSeconds: item.betweenRoundRestSeconds,
        targetRir: item.targetRir ?? 2,
        sets: Array.from({ length: Math.max(1, item.targetSets || 1) }, () =>
          makeSet({
            weight: item.targetWeight ?? 0,
            reps: item.targetReps ?? 10,
            rir: item.targetRir ?? 2,
          }),
        ),
      }),
    ),
  };
}

/** Lặp lại bài và mức tạ của buổi gần nhất; bỏ bài không còn trong kho. */
export function seedFromLatestSession(latest: WorkoutSession, exercises: Exercise[]): WorkoutSeed {
  const ids = [...new Set(latest.sets.map((set) => set.exerciseId))].filter((id) => exercises.some((exercise) => exercise.id === id));
  return {
    title: "Tập lại buổi gần đây",
    exercises: ids.map((id) => makeExercise(id, {
      sets: latest.sets.filter((set) => set.exerciseId === id).map((set) => makeSet({ setType: set.setType, weight: set.weight, reps: set.reps, rir: set.rir })),
      restSeconds: latest.sets.find((set) => set.exerciseId === id)?.restSeconds ?? 90,
    })),
  };
}

const exerciseOrderKey = (set: WorkoutSetResponse) => `${set.exerciseOrder ?? 1}:${set.exerciseId}`;

/** Mở lại buổi đã lưu để chỉnh sửa toàn bộ. */
export function seedFromSession(session: WorkoutSession): WorkoutSeed {
  const orders = [...new Set(session.sets.map(exerciseOrderKey))];
  return {
    title: session.note ?? "",
    sessionId: session.id,
    sessionDate: session.sessionDate,
    durationMinutes: session.durationMinutes,
    exercises: orders.map(order => {
      const sets = session.sets.filter(set => exerciseOrderKey(set) === order);
      const first = sets[0];
      return makeExercise(first.exerciseId, {
        originalExerciseId: first.originalExerciseId ?? undefined,
        replacementKind: first.replacementKind,
        groupKey: first.groupKey,
        groupType: first.groupType,
        groupRounds: first.groupRounds,
        betweenExerciseRestSeconds: first.betweenExerciseRestSeconds,
        betweenRoundRestSeconds: first.betweenRoundRestSeconds,
        historicalExerciseName: first.exerciseName,
        restSeconds: first.restSeconds ?? 90,
        sets: sets.map(set => makeSet(set)),
      });
    }),
  };
}

/** Nhóm các set của một buổi theo thứ tự bài. */
export function groupSessionSets(sets: WorkoutSetResponse[]): WorkoutSetResponse[][] {
  const groups = new Map<string, WorkoutSetResponse[]>();
  for (const set of sets) {
    const key = exerciseOrderKey(set);
    groups.set(key, [...(groups.get(key) ?? []), set]);
  }
  return [...groups.values()];
}

const isWorkingSet = (set: WorkoutSetResponse) => set.completed && set.setType !== "WARMUP";

/** Volume chỉ tính set chính đã hoàn thành. */
export function sessionVolume(session: WorkoutSession): number {
  return session.sets.filter(isWorkingSet).reduce((total, set) => total + set.weight * set.reps, 0);
}

export function summarizeSessions(sessions: WorkoutSession[]) {
  return {
    totalSets: sessions.reduce((total, session) => total + session.sets.filter(isWorkingSet).length, 0),
    totalVolume: sessions.reduce((total, session) => total + sessionVolume(session), 0),
    totalMinutes: sessions.reduce((total, session) => total + (session.durationMinutes ?? 0), 0),
  };
}

export function intelligenceKey(group: Pick<DraftExercise, "exerciseId" | "targetSets" | "minReps" | "maxReps" | "targetRir">) {
  return [group.exerciseId, group.targetSets, group.minReps, group.maxReps, group.targetRir].join(":");
}

export function progressionActionLabel(action: ProgressionActionType) {
  const labels: Record<ProgressionActionType, string> = {
    NO_DATA: "Mốc khởi đầu",
    INCREASE_WEIGHT: "Sẵn sàng tăng tạ",
    BUILD_REPS: "Tiếp tục tăng số lần lặp",
    DECREASE_OR_HOLD: "Giữ hoặc giảm nhẹ mức tạ",
  };
  return labels[action];
}

export function personalRecordLabel(type: PersonalBestType) {
  const labels: Record<PersonalBestType, string> = {
    HEAVIEST_WEIGHT: "Mức tạ cao nhất",
    MAX_REPS_AT_WEIGHT: "Số lần lặp cao nhất",
    ESTIMATED_1RM: "e1RM ước tính",
    MAX_SESSION_VOLUME: "Volume buổi cao nhất",
  };
  return labels[type];
}

export function personalBestUnit(type: PersonalBestType) {
  return type === "MAX_REPS_AT_WEIGHT" ? "lần" : "kg";
}

export function formatNumber(value: number) {
  return new Intl.NumberFormat("vi-VN", { maximumFractionDigits: 1 }).format(value);
}

export function formatClock(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, "0");
  const seconds = Math.max(0, totalSeconds % 60).toString().padStart(2, "0");
  return `${minutes}:${seconds}`;
}

/** Đổi chỗ phần tử với phần tử kề bên; giữ nguyên nếu ra ngoài danh sách. */
export function moveItem<T>(items: T[], index: number, direction: -1 | 1): T[] {
  const target = index + direction;
  if (target < 0 || target >= items.length) return items;
  const next = [...items];
  [next[index], next[target]] = [next[target], next[index]];
  return next;
}

/** Thời gian nghỉ sau khi xong một set (superset/circuit dùng nghỉ giữa bài hoặc giữa vòng). */
export function restAfterSet(groups: DraftExercise[], group: DraftExercise): number {
  if (!group.groupKey) return group.restSeconds;
  const same = groups.filter(g => g.groupKey === group.groupKey);
  return same[same.length - 1]?.key === group.key
    ? group.betweenRoundRestSeconds ?? 90
    : group.betweenExerciseRestSeconds ?? 15;
}

/** Thông báo bài tiếp theo trong nhóm superset/circuit sau khi xong một set. */
export function supersetProgressMessage(
  groups: DraftExercise[],
  group: DraftExercise,
  setKey: string,
  exerciseName: (exerciseId: string) => string | undefined,
): string | null {
  if (!group.groupKey) return null;
  const members = groups.filter(g => g.groupKey === group.groupKey);
  const round = group.sets.findIndex(s => s.key === setKey);
  const order = members.indexOf(group);
  const next = members.slice(order + 1).find(g => g.sets[round] && !g.sets[round].completed)
    ?? members.find(g => g.sets[round + 1] && !g.sets[round + 1].completed);
  const nextRound = next && members.indexOf(next) > order ? round : round + 1;
  return next
    ? "Nhóm " + group.groupKey + " · tiếp theo: " + (exerciseName(next.exerciseId) ?? "Bài tiếp") + " · vòng " + (nextRound + 1)
    : "Đã đi hết các hiệp hiện có trong nhóm " + group.groupKey;
}

/** Các PR có thể đạt được của một set (mức tạ, e1RM Epley 1–30 lần). */
export function potentialRecords(insight: WorkoutIntelligence | null | undefined, set: DraftSet): { key: string; text: string }[] {
  if (!insight || set.setType === "WARMUP") return [];
  const heaviest = insight.personalBests.find((value) => value.type === "HEAVIEST_WEIGHT")?.value ?? 0;
  const bestE1rm = insight.personalBests.find((value) => value.type === "ESTIMATED_1RM")?.value ?? 0;
  const estimated = set.weight > 0 && set.reps <= 30 ? set.weight * (1 + set.reps / 30) : 0;
  const candidates = [
    { type: "weight", won: set.weight > heaviest, text: `Mức tạ mới ${set.weight} kg` },
    { type: "e1rm", won: estimated > bestE1rm, text: `e1RM ước tính ${formatNumber(estimated)} kg` },
  ];
  return candidates.filter(candidate => candidate.won).map(candidate => ({ key: `${set.key}:${candidate.type}`, text: candidate.text }));
}

/** Áp mức đề xuất: tạo lại danh sách set theo số set đề xuất, giữ loại set cũ. */
export function applyProgressionSets(group: DraftExercise, suggestion: WorkoutIntelligence["progression"]): DraftExercise {
  return {
    ...group,
    sets: Array.from({ length: suggestion.suggestedSets }, (_, index) =>
      makeSet({
        weight: suggestion.suggestedWeight ?? 0,
        reps: suggestion.suggestedMinReps,
        rir: suggestion.targetRir,
        setType: group.sets[index]?.setType ?? "NORMAL",
      })),
  };
}

export function updateSet(group: DraftExercise, setKey: string, patch: Partial<DraftSet>): DraftExercise {
  return { ...group, sets: group.sets.map((value) => value.key === setKey ? { ...value, ...patch } : value) };
}

export function toggleSetCompleted(group: DraftExercise, setKey: string): DraftExercise {
  return { ...group, sets: group.sets.map((set) => (set.key === setKey ? { ...set, completed: !set.completed } : set)) };
}

/** Thêm set mới, sao chép mức tạ/lần/RIR của set cuối. */
export function appendSet(group: DraftExercise): DraftExercise {
  const last = group.sets.at(-1);
  return { ...group, sets: [...group.sets, makeSet(last ? { weight: last.weight, reps: last.reps, rir: last.rir } : {})] };
}

export function removeLastSet(group: DraftExercise): DraftExercise {
  return { ...group, sets: group.sets.length > 1 ? group.sets.slice(0, -1) : group.sets };
}

/** Đổi thời gian nghỉ cho bài và mọi set của bài. */
export function setGroupRest(group: DraftExercise, restSeconds: number): DraftExercise {
  return { ...group, restSeconds, sets: group.sets.map(set => ({ ...set, restSeconds })) };
}

export function withoutKey<T>(record: Record<string, T>, key: string): Record<string, T> {
  const next = { ...record };
  delete next[key];
  return next;
}

/** Dữ liệu gửi API khi kết thúc buổi; `null` khi chưa có set nào hoàn thành. */
export function buildSessionPayload({
  groups,
  title,
  note,
  sessionDate,
  isEditing,
  durationMinutes,
  elapsedSeconds,
}: {
  groups: DraftExercise[];
  title: string;
  note: string;
  sessionDate: string;
  isEditing: boolean;
  durationMinutes: number;
  elapsedSeconds: number;
}): WorkoutSessionPayload | null {
  const completedSets = groups.flatMap((group, exerciseIndex) =>
    group.sets
      .filter((set) => set.completed)
      .map((set, setIndex) => ({
        exerciseId: group.exerciseId,
        originalExerciseId: group.originalExerciseId,
        replacementKind: group.replacementKind,
        exerciseOrder: exerciseIndex + 1,
        setNumber: setIndex + 1,
        setType: set.setType,
        weight: Number(set.weight),
        reps: Number(set.reps),
        rir: Number(set.rir),
        restSeconds: set.restSeconds ?? group.restSeconds,
        completed: true,
        groupKey: group.groupKey,
        groupType: group.groupType,
        groupRounds: group.groupRounds,
        betweenExerciseRestSeconds: group.betweenExerciseRestSeconds,
        betweenRoundRestSeconds: group.betweenRoundRestSeconds,
      })),
  );
  if (!completedSets.length) return null;
  return {
    sessionDate,
    note: [title.trim(), note.trim()].filter(Boolean).join(" · "),
    durationMinutes: isEditing ? durationMinutes : Math.max(1, Math.ceil(elapsedSeconds / 60)),
    sets: completedSets,
  };
}
