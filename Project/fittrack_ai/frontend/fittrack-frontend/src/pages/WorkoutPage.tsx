import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import { useSearchParams } from "react-router-dom";
import {
  Activity,
  ArrowDown,
  ArrowUp,
  CalendarCheck2,
  CheckCircle2,
  Dumbbell,
  History,
  Lightbulb,
  Plus,
  Play,
  RefreshCw,
  Star,
  Timer,
  Trash2,
  TrendingUp,
  Trophy,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createWorkoutSession,
  replaceWorkoutSession,
  deleteWorkoutSession,
  getAlternativeExercises,
  getExercisePreferences,
  getExercises,
  getWeeklyWorkoutVolume,
  getWorkoutIntelligence,
  getWorkoutSessionsPage,
  setExercisePreference,
  type AlternativeExercise,
  type Exercise,
  type ExercisePreference,
  type WeeklyWorkoutVolume,
  type WorkoutIntelligence,
  type WorkoutSession,
  type WorkoutSetType,
} from "../api/workout.api";
import { getWorkoutPlans } from "../api/workout-plan.api";
import { toLocalDateInput } from "../lib/format";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import PageHeader from "../components/PageHeader";
import TableLoading from "../components/common/TableLoading";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import DataPagination from "../components/common/DataPagination";
import { useServerPagination } from "../hooks/useServerPagination";
import ExercisePicker from "../components/workouts/ExercisePicker";
import { useAuthStore } from "@/store/auth.store";
import { clearSessionDraft, readSessionDraft, writeSessionDraft } from "@/lib/sessionDraft";
import { maximumWorkoutSeconds, workoutElapsedSeconds } from "@/lib/workoutDraftTime";

type DraftSet = {
  key: string;
  setType: WorkoutSetType;
  weight: number;
  reps: number;
  rir: number;
  completed: boolean;
  restSeconds?: number;
};

type DraftExercise = {
  key: string;
  exerciseId: string;
  historicalExerciseName?: string;
  restSeconds: number;
  targetSets: number;
  minReps: number;
  maxReps: number;
  targetRir: number;
  coachingNote?: string;
  sets: DraftSet[];
};

type WorkoutSeed = {
  title: string;
  exercises: DraftExercise[];
  note?: string;
  elapsedSeconds?: number;
  sessionId?: string;
  sessionDate?: string;
  durationMinutes?: number;
};

const setTypeLabels: Record<WorkoutSetType, string> = {
  WARMUP: "Khởi động",
  NORMAL: "Chính",
  DROP: "Drop set",
  FAILURE: "Tới ngưỡng",
};

const draftKey = () => `${Date.now()}-${Math.random().toString(36).slice(2)}`;

function readWorkoutDraft(owner: string): WorkoutSeed | null {
  const draft = readSessionDraft<WorkoutSeed>(owner, "workout");
  if (!draft) return null;
  const valid = typeof draft.title === "string" && (draft.note == null || typeof draft.note === "string")
    && (draft.elapsedSeconds == null || (Number.isFinite(draft.elapsedSeconds) && draft.elapsedSeconds >= 0 && draft.elapsedSeconds <= maximumWorkoutSeconds))
    && Array.isArray(draft.exercises) && draft.exercises.length > 0 && draft.exercises.every(group =>
      typeof group.key === "string" && typeof group.exerciseId === "string" && Number.isFinite(group.restSeconds)
      && (group.historicalExerciseName == null || typeof group.historicalExerciseName === "string")
      && Array.isArray(group.sets) && group.sets.every(set => typeof set.key === "string" && typeof set.completed === "boolean"
        && Object.hasOwn(setTypeLabels, set.setType) && [set.weight, set.reps, set.rir].every(Number.isFinite)
        && (set.restSeconds == null || (Number.isFinite(set.restSeconds) && set.restSeconds >= 0 && set.restSeconds <= 1800))));
  if (!valid) { clearSessionDraft(owner, "workout"); return null; }
  return draft;
}

const makeSet = (overrides: Partial<DraftSet> = {}): DraftSet => ({
  key: draftKey(),
  setType: "NORMAL",
  weight: 0,
  reps: 10,
  rir: 2,
  completed: false,
  ...overrides,
});

const makeExercise = (
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

export default function WorkoutPage() {
  const owner = useAuthStore((state) => state.user?.userId ?? "");
  return <WorkoutWorkspace key={owner} owner={owner} />;
}

function WorkoutWorkspace({ owner }: { owner: string }) {
  const [searchParams] = useSearchParams();
  const [recoverable, setRecoverable] = useState(() => readWorkoutDraft(owner));
  const queryClient = useQueryClient();
  const workoutPager = useServerPagination(12);
  const [liveSeed, setLiveSeed] = useState<WorkoutSeed | null>(() => searchParams.get("action") === "new" && !recoverable ? { title: "Buổi tập tự do", exercises: [] } : null);
  const [selectedPlanDay, setSelectedPlanDay] = useState(searchParams.get("planDay") ?? "");
  const [autoStarted, setAutoStarted] = useState(false);
  const [historyFilters, setHistoryFilters] = useState({ from: "", to: "", exerciseId: "" });

  const exercisesQuery = useQuery({ queryKey: ["exercises"], queryFn: getExercises });
  const plansQuery = useQuery({ queryKey: ["workout-plans"], queryFn: getWorkoutPlans });
  const sessionsQuery = useQuery({
    queryKey: ["workout-sessions", workoutPager.page, workoutPager.pageSize, historyFilters],
    queryFn: () => getWorkoutSessionsPage(workoutPager.page - 1, workoutPager.pageSize, { from: historyFilters.from || undefined, to: historyFilters.to || undefined, exerciseId: historyFilters.exerciseId || undefined }),
    placeholderData: (previous) => previous,
  });
  const weeklyVolumeQuery = useQuery({
    queryKey: ["weekly-workout-volume"],
    queryFn: getWeeklyWorkoutVolume,
  });

  const exercises = exercisesQuery.data ?? [];
  const sessions = sessionsQuery.data?.content ?? [];
  const planDays = useMemo(
    () => (plansQuery.data ?? []).flatMap((plan) =>
      plan.days.map((day) => ({ plan, day })),
    ),
    [plansQuery.data],
  );

  const totalSets = sessions.reduce((total, session) => total + session.sets.filter(set => set.completed && set.setType !== 'WARMUP').length, 0);
  const totalVolume = sessions.reduce(
    (total, session) =>
      total + session.sets.filter(set => set.completed && set.setType !== 'WARMUP').reduce((subtotal, set) => subtotal + set.weight * set.reps, 0),
    0,
  );
  const totalMinutes = sessions.reduce(
    (total, session) => total + (session.durationMinutes ?? 0),
    0,
  );

  const refreshWorkoutData = () => {
    for (const key of [
      ["workout-sessions"],
      ["dashboard-today"],
      ["dashboard-progress"],
      ["weekly-report"],
      ["weekly-recommendations"],
      ["achievements"],
      ["weekly-workout-volume"],
    ]) {
      queryClient.invalidateQueries({ queryKey: key });
    }
  };

  const createMutation = useMutation({
    mutationFn: createWorkoutSession,
    onSuccess: (session) => {
      toast.success("Đã hoàn thành và lưu buổi tập");
      for (const record of session.newPersonalRecords ?? []) {
        toast.success(`🏆 PR mới · ${record.exerciseName}`, {
          description: `${personalRecordLabel(record.type)}: ${formatNumber(record.newValue)} ${record.unit}`,
        });
      }
      refreshWorkoutData();
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể lưu buổi tập");
    },
  });
  const editMutation = useMutation({ mutationFn: ({ id, payload }: { id: string; payload: Parameters<typeof createWorkoutSession>[0] }) => replaceWorkoutSession(id, payload), onSuccess: () => { toast.success('Đã cập nhật toàn bộ buổi tập'); refreshWorkoutData(); }, onError: () => toast.error('Không thể cập nhật buổi tập') });

  const deleteMutation = useMutation({
    mutationFn: deleteWorkoutSession,
    onSuccess: () => {
      toast.success("Đã xóa buổi tập");
      refreshWorkoutData();
    },
    onError: () => toast.error("Không thể xóa buổi tập"),
  });

  const startFreeWorkout = () => {
    if (recoverable && !window.confirm("Bắt đầu buổi mới sẽ thay thế bản nháp cũ trong tab này. Tiếp tục?")) return;
    if (!exercises[0]) {
      toast.error("Kho bài tập chưa có bài đã được duyệt");
      return;
    }
    setLiveSeed({ title: "Buổi tập tự do", exercises: [makeExercise(exercises[0].id)] });
  };

  const startPlanWorkout = () => {
    if (recoverable && !window.confirm("Bắt đầu theo giáo án sẽ thay thế bản nháp cũ trong tab này. Tiếp tục?")) return;
    const selected = planDays.find(({ plan, day }) => `${plan.id}:${day.id}` === selectedPlanDay);
    if (!selected) {
      toast.error("Hãy chọn một ngày trong giáo án");
      return;
    }
    setLiveSeed({
      title: `${selected.plan.name} · ${selected.day.name}`,
      exercises: selected.day.exercises.map((item) =>
        makeExercise(item.exerciseId, {
          targetSets: Math.max(1, item.targetSets || 1),
          minReps: item.minReps ?? Math.max(1, (item.targetReps ?? 10) - 2),
          maxReps: item.maxReps ?? item.targetReps ?? 10,
          restSeconds: item.restSeconds ?? 90,
          coachingNote: item.coachingNote ?? '',
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
    });
  };

  useEffect(() => {
    if (searchParams.get('planDay') && plansQuery.isSuccess && exercisesQuery.isSuccess && !autoStarted) {
      const timer = window.setTimeout(() => { setAutoStarted(true); if (!recoverable) startPlanWorkout(); }, 0);
      return () => window.clearTimeout(timer);
    }
    // The explicit navigation intent is consumed once; subsequent form edits must not restart it.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [plansQuery.isSuccess, exercisesQuery.isSuccess, autoStarted, recoverable, searchParams]);

  if (exercisesQuery.isLoading || sessionsQuery.isLoading || plansQuery.isLoading) {
    return <TableLoading />;
  }
  if (exercisesQuery.isError || sessionsQuery.isError || plansQuery.isError) {
    return <ErrorState title="Không thể tải dữ liệu luyện tập" message="Vui lòng tải lại trang." />;
  }

  return (
    <div className="space-y-5">
      <PageHeader
        title="Buổi tập"
        description="Bắt đầu workout, ghi từng set và xem thành tích lần tập trước ngay trong lúc tập."
      />
      {recoverable && !liveSeed && <Card><CardContent className="space-y-3 p-4"><p className="font-semibold">Bạn có buổi tập chưa lưu</p><p className="text-sm text-muted-foreground">{recoverable.title}. Bản nháp giữ trên thiết bị này tối đa 7 ngày và chưa được ghi vào lịch sử.</p><div className="flex flex-wrap gap-2"><Button onClick={() => setLiveSeed(recoverable)}>Tiếp tục buổi tập</Button><Button variant="outline" onClick={() => { clearSessionDraft(owner, "workout"); setRecoverable(null); }}>Bỏ bản nháp</Button></div></CardContent></Card>}

      <p className="text-sm text-muted-foreground">Thống kê của trang lịch sử đang xem; khối lượng chỉ tính hiệp chính đã hoàn thành, không gồm khởi động.</p>
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard icon={Activity} label="Buổi gần đây" value={sessions.length.toString()} tone="emerald" />
        <StatCard icon={Dumbbell} label="Tổng set" value={totalSets.toString()} />
        <StatCard icon={TrendingUp} label="Tổng volume" value={`${Math.round(totalVolume).toLocaleString("vi-VN")} kg`} tone="amber" />
        <StatCard icon={Timer} label="Thời lượng" value={`${totalMinutes} phút`} tone="sky" />
      </div>

      <Card className="overflow-hidden border-emerald-200 bg-gradient-to-br from-emerald-950 to-emerald-800 text-white">
        <CardContent className="grid gap-6 p-6 lg:grid-cols-[1.2fr_1fr] lg:items-center">
          <div>
            <p className="mb-2 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-200">Workout mode</p>
            <h2 className="text-2xl font-bold">Hôm nay bạn muốn tập gì?</h2>
            <p className="mt-2 max-w-xl text-sm text-emerald-100/80">
              Mỗi buổi có nhiều bài, mỗi bài có nhiều set. Đồng hồ nghỉ sẽ tự chạy sau khi hoàn thành set.
            </p>
            <Button className="mt-5 bg-white text-emerald-950 hover:bg-emerald-50" onClick={startFreeWorkout}>
              <Play /> Bắt đầu buổi tập tự do
            </Button>
            {workoutPager.page === 1 && !!sessions[0] && <Button className="mt-3 sm:ml-2" variant="secondary" onClick={() => {
              if (recoverable && !window.confirm("Dùng lại buổi gần đây sẽ thay thế bản nháp cũ trong tab này. Tiếp tục?")) return;
              const latest = sessions[0];
              const ids = [...new Set(latest.sets.map((set) => set.exerciseId))].filter((id) => exercises.some((exercise) => exercise.id === id));
              setLiveSeed({ title: "Tập lại buổi gần đây", exercises: ids.map((id) => makeExercise(id, { sets: latest.sets.filter((set) => set.exerciseId === id).map((set) => makeSet({ setType: set.setType, weight: set.weight, reps: set.reps, rir: set.rir })), restSeconds: latest.sets.find((set) => set.exerciseId === id)?.restSeconds ?? 90 })) });
            }}>Dùng lại bài và mức tạ gần đây</Button>}
          </div>
          <div className="rounded-2xl border border-white/15 bg-white/10 p-4 backdrop-blur">
            <label className="text-sm font-semibold" htmlFor="workout-plan-day">Hoặc tập theo giáo án</label>
            <select
              id="workout-plan-day"
              className="mt-2 h-11 w-full rounded-xl border border-white/20 bg-emerald-950/60 px-3 text-sm text-white"
              value={selectedPlanDay}
              onChange={(event) => setSelectedPlanDay(event.target.value)}
            >
              <option value="">Chọn giáo án và ngày tập</option>
              {planDays.map(({ plan, day }) => (
                <option key={`${plan.id}:${day.id}`} value={`${plan.id}:${day.id}`}>
                  {plan.name} · {day.name} ({day.exercises.length} bài)
                </option>
              ))}
            </select>
            <Button variant="secondary" className="mt-3 w-full" onClick={startPlanWorkout} disabled={!planDays.length}>
              <CalendarCheck2 /> Bắt đầu theo giáo án
            </Button>
          </div>
        </CardContent>
      </Card>

      <WeeklyVolumeCard
        loading={weeklyVolumeQuery.isLoading}
        data={weeklyVolumeQuery.data}
      />

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2"><History className="h-5 w-5 text-emerald-600" />Lịch sử gần đây</CardTitle>
          <p className="text-sm text-muted-foreground">Mỗi thẻ là một buổi tập hoàn chỉnh, bên trong được nhóm theo từng bài.</p>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="grid gap-3 sm:grid-cols-3"><label className="text-sm">Từ ngày<Input type="date" value={historyFilters.from} onChange={event => { workoutPager.setPage(1); setHistoryFilters(prev => ({ ...prev, from: event.target.value })); }} /></label><label className="text-sm">Đến ngày<Input type="date" value={historyFilters.to} onChange={event => { workoutPager.setPage(1); setHistoryFilters(prev => ({ ...prev, to: event.target.value })); }} /></label><label className="text-sm">Bài tập<select className="h-11 w-full rounded-xl border px-3" value={historyFilters.exerciseId} onChange={event => { workoutPager.setPage(1); setHistoryFilters(prev => ({ ...prev, exerciseId: event.target.value })); }}><option value="">Tất cả bài tập</option>{exercises.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label></div>
          {!sessions.length ? (
            <EmptyState kind="workout" title="Chưa có buổi tập" description="Bắt đầu workout đầu tiên để theo dõi tiến độ." />
          ) : (
            sessions.map((session) => (
              <SessionHistoryCard
                key={session.id}
                session={session}
                onEdit={() => {
                  if (recoverable && !window.confirm('Mở chỉnh sửa sẽ thay thế nháp buổi tập hiện tại. Tiếp tục?')) return;
                  const orders = [...new Set(session.sets.map(set => `${set.exerciseOrder ?? 1}:${set.exerciseId}`))];
                  setLiveSeed({ title: session.note ?? '', sessionId: session.id, sessionDate: session.sessionDate, durationMinutes: session.durationMinutes, exercises: orders.map(order => { const sets = session.sets.filter(set => `${set.exerciseOrder ?? 1}:${set.exerciseId}` === order); return makeExercise(sets[0].exerciseId, { historicalExerciseName: sets[0].exerciseName, restSeconds: sets[0].restSeconds ?? 90, sets: sets.map(set => makeSet(set)) }); }) });
                }}
                onDelete={() => {
                  if (window.confirm("Bạn có chắc muốn xóa toàn bộ buổi tập này?")) {
                    deleteMutation.mutate(session.id);
                  }
                }}
              />
            ))
          )}
          <DataPagination
            page={workoutPager.page}
            pageSize={workoutPager.pageSize}
            totalItems={sessionsQuery.data?.totalElements ?? 0}
            totalPages={Math.max(1, sessionsQuery.data?.totalPages ?? 1)}
            onPageChange={workoutPager.setPage}
            onPageSizeChange={workoutPager.setPageSize}
          />
        </CardContent>
      </Card>

      {liveSeed && (
        <LiveWorkoutDialog
          key={owner}
          owner={owner}
          seed={liveSeed}
          exercises={exercises}
          saving={createMutation.isPending || editMutation.isPending}
          onClose={() => { clearSessionDraft(owner, "workout"); setRecoverable(null); setLiveSeed(null); }}
          onFinish={async (payload) => {
            if (liveSeed.sessionId) await editMutation.mutateAsync({ id: liveSeed.sessionId, payload });
            else await createMutation.mutateAsync(payload);
            clearSessionDraft(owner, "workout");
            setRecoverable(null);
            setLiveSeed(null);
          }}
        />
      )}
    </div>
  );
}

function LiveWorkoutDialog({
  owner,
  seed,
  exercises,
  saving,
  onClose,
  onFinish,
}: {
  owner: string;
  seed: WorkoutSeed;
  exercises: Exercise[];
  saving: boolean;
  onClose: () => void;
  onFinish: (payload: Parameters<typeof createWorkoutSession>[0]) => Promise<void>;
}) {
  const [title, setTitle] = useState(seed.title);
  const [note, setNote] = useState(seed.note ?? "");
  const [sessionDate, setSessionDate] = useState(seed.sessionDate ?? toLocalDateInput());
  const [durationMinutes, setDurationMinutes] = useState(seed.durationMinutes ?? 1);
  const [groups, setGroups] = useState(seed.exercises.length ? seed.exercises : [makeExercise(exercises[0]?.id ?? "")]);
  const [startedAt] = useState(() => Date.now());
  const [elapsed, setElapsed] = useState(seed.elapsedSeconds ?? 0);
  const [restSeconds, setRestSeconds] = useState(0);
  const [restRunning, setRestRunning] = useState(false);
  const [intelligence, setIntelligence] = useState<Record<string, WorkoutIntelligence | null>>({});
  const [preferences, setPreferences] = useState<Record<string, ExercisePreference>>({});
  const [alternatives, setAlternatives] = useState<Record<string, AlternativeExercise[] | null>>({});
  const [announcedRecords] = useState(() => new Set<string>());

  useEffect(() => {
    const persist = () => writeSessionDraft(owner, "workout", { title, note, exercises: groups, sessionId: seed.sessionId, sessionDate, durationMinutes, elapsedSeconds: workoutElapsedSeconds(seed.elapsedSeconds ?? 0, startedAt, Date.now()) });
    persist();
    window.addEventListener("pagehide", persist);
    return () => window.removeEventListener("pagehide", persist);
  }, [owner, title, note, groups, startedAt, seed.elapsedSeconds, seed.sessionId, elapsed, sessionDate, durationMinutes]);

  useEffect(() => {
    const timer = window.setInterval(() => setElapsed(workoutElapsedSeconds(seed.elapsedSeconds ?? 0, startedAt, Date.now())), 1000);
    return () => window.clearInterval(timer);
  }, [startedAt, seed.elapsedSeconds]);

  useEffect(() => {
    if (!restRunning) return;
    const timer = window.setInterval(() => {
      setRestSeconds((value) => {
        if (value <= 1) {
          setRestRunning(false);
          return 0;
        }
        return value - 1;
      });
    }, 1000);
    return () => window.clearInterval(timer);
  }, [restRunning]);

  useEffect(() => {
    let cancelled = false;
    const missing = groups.filter((group) => {
      const key = intelligenceKey(group);
      return group.exerciseId && !(key in intelligence);
    });
    for (const group of missing) {
      const key = intelligenceKey(group);
      getWorkoutIntelligence(group.exerciseId, {
        targetSets: group.targetSets,
        minReps: group.minReps,
        maxReps: group.maxReps,
        targetRir: group.targetRir,
      })
        .then((result) => {
          if (!cancelled) setIntelligence((current) => ({ ...current, [key]: result }));
        })
        .catch(() => {
          if (!cancelled) setIntelligence((current) => ({ ...current, [key]: null }));
        });
    }
    return () => { cancelled = true; };
  }, [groups, intelligence]);

  useEffect(() => {
    let cancelled = false;
    getExercisePreferences()
      .then((values) => {
        if (!cancelled) {
          setPreferences(Object.fromEntries(values.map((value) => [value.exerciseId, value.preference])));
        }
      })
      .catch(() => undefined);
    return () => { cancelled = true; };
  }, []);

  const updateGroup = (groupKey: string, updater: (group: DraftExercise) => DraftExercise) => {
    setGroups((current) => current.map((group) => (group.key === groupKey ? updater(group) : group)));
  };

  const moveGroup = (index: number, direction: -1 | 1) => {
    setGroups((current) => {
      const target = index + direction;
      if (target < 0 || target >= current.length) return current;
      const next = [...current];
      [next[index], next[target]] = [next[target], next[index]];
      return next;
    });
  };

  const toggleSet = (groupKey: string, setKey: string) => {
    const group = groups.find((item) => item.key === groupKey);
    const target = group?.sets.find((item) => item.key === setKey);
    const willComplete = target ? !target.completed : false;
    updateGroup(groupKey, (item) => ({
      ...item,
      sets: item.sets.map((set) => (set.key === setKey ? { ...set, completed: !set.completed } : set)),
    }));
    if (willComplete && group && group.restSeconds > 0) {
      setRestSeconds(group.restSeconds);
      setRestRunning(true);
    }
    if (willComplete && group && target) {
      announcePotentialRecord(group, target);
    }
  };

  const announcePotentialRecord = (group: DraftExercise, set: DraftSet) => {
    const insight = intelligence[intelligenceKey(group)];
    if (!insight || set.setType === "WARMUP") return;
    const heaviest = insight.personalBests.find((value) => value.type === "HEAVIEST_WEIGHT")?.value ?? 0;
    const bestE1rm = insight.personalBests.find((value) => value.type === "ESTIMATED_1RM")?.value ?? 0;
    const estimated = set.weight > 0 && set.reps <= 30 ? set.weight * (1 + set.reps / 30) : 0;
    const candidates = [
      { type: "weight", won: set.weight > heaviest, text: `Mức tạ mới ${set.weight} kg` },
      { type: "e1rm", won: estimated > bestE1rm, text: `e1RM ước tính ${formatNumber(estimated)} kg` },
    ];
    for (const candidate of candidates) {
      const key = `${set.key}:${candidate.type}`;
      if (candidate.won && !announcedRecords.has(key)) {
        announcedRecords.add(key);
        toast.success("🏆 Có thể là PR mới", { description: candidate.text });
      }
    }
  };

  const applyProgression = (group: DraftExercise) => {
    const suggestion = intelligence[intelligenceKey(group)]?.progression;
    if (!suggestion || suggestion.suggestedWeight == null) return;
    updateGroup(group.key, (current) => ({
      ...current,
      sets: Array.from({ length: suggestion.suggestedSets }, (_, index) =>
        makeSet({
          weight: suggestion.suggestedWeight ?? 0,
          reps: suggestion.suggestedMinReps,
          rir: suggestion.targetRir,
          setType: current.sets[index]?.setType ?? "NORMAL",
        })),
    }));
    toast.success("Đã áp dụng mức đề xuất vào buổi tập");
  };

  const updatePreference = async (exerciseId: string, preference: ExercisePreference) => {
    const previousValue = preferences[exerciseId] ?? "NORMAL";
    setPreferences((current) => ({ ...current, [exerciseId]: preference }));
    try {
      await setExercisePreference(exerciseId, preference);
      toast.success("Đã lưu mức ưu tiên bài tập");
    } catch {
      setPreferences((current) => ({ ...current, [exerciseId]: previousValue }));
      toast.error("Không thể lưu mức ưu tiên");
    }
  };

  const loadAlternatives = async (group: DraftExercise) => {
    setAlternatives((current) => ({ ...current, [group.key]: null }));
    try {
      const values = await getAlternativeExercises(group.exerciseId);
      setAlternatives((current) => ({ ...current, [group.key]: values }));
      if (!values.length) toast.info("Chưa có bài thay thế phù hợp cùng nhóm cơ");
    } catch {
      setAlternatives((current) => {
        const next = { ...current };
        delete next[group.key];
        return next;
      });
      toast.error("Không thể tải bài thay thế");
    }
  };

  const finish = async () => {
    const completedSets = groups.flatMap((group, exerciseIndex) =>
      group.sets
        .filter((set) => set.completed)
        .map((set, setIndex) => ({
          exerciseId: group.exerciseId,
          exerciseOrder: exerciseIndex + 1,
          setNumber: setIndex + 1,
          setType: set.setType,
          weight: Number(set.weight),
          reps: Number(set.reps),
          rir: Number(set.rir),
          restSeconds: set.restSeconds ?? group.restSeconds,
          completed: true,
        })),
    );
    if (!completedSets.length) {
      toast.error("Hãy hoàn thành ít nhất một set trước khi kết thúc buổi tập");
      return;
    }
    await onFinish({
      sessionDate,
      note: [title.trim(), note.trim()].filter(Boolean).join(" · "),
      durationMinutes: seed.sessionId ? durationMinutes : Math.max(1, Math.ceil(elapsed / 60)),
      sets: completedSets,
    });
  };

  return (
    <Dialog open onOpenChange={(open) => {
      if (!open && window.confirm("Hủy buổi tập đang thực hiện? Dữ liệu chưa hoàn thành sẽ mất.")) onClose();
    }}>
      <DialogContent className="flex max-h-[96dvh] w-[calc(100vw-1rem)] max-w-6xl flex-col gap-0 overflow-hidden p-0 sm:w-[calc(100vw-2rem)]">
        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto px-4 pt-5 pb-4 sm:px-6 sm:pt-6">
        <DialogHeader>
          <DialogTitle className="flex flex-wrap items-center justify-between gap-3 pr-8">
            <span>{seed.sessionId ? 'Chỉnh sửa buổi tập' : 'Buổi tập trực tiếp'}</span>
            <span className="rounded-full bg-emerald-100 px-3 py-1 text-sm font-semibold text-emerald-800">
              <Timer className="mr-1 inline h-4 w-4" /> {formatClock(elapsed)}
            </span>
          </DialogTitle>
        </DialogHeader>
        {seed.sessionId && <div className="grid gap-3 sm:grid-cols-2"><label className="text-sm">Ngày tập<Input type="date" value={sessionDate} onChange={event => setSessionDate(event.target.value)} /></label><label className="text-sm">Thời lượng (phút)<Input type="number" min={1} max={600} value={durationMinutes} onChange={event => setDurationMinutes(Number(event.target.value))} /></label></div>}
        <p className="text-xs text-muted-foreground">Tự giữ bản nháp trên thiết bị này khi đóng hoặc tải lại trang (tối đa 7 ngày; xóa khi đăng xuất). Chỉ lưu lịch sử khi bạn hoàn thành buổi tập; hủy buổi sẽ xóa nháp.</p>

        {restRunning && (
          <div className="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-emerald-950 p-4 text-white shadow-lg">
            <div><p className="text-xs uppercase tracking-wider text-emerald-200">Đang nghỉ</p><p className="text-3xl font-black tabular-nums">{formatClock(restSeconds)}</p></div>
            <div className="flex gap-2">
              <Button variant="secondary" size="sm" onClick={() => setRestSeconds((value) => Math.max(0, value - 15))}>-15 giây</Button>
              <Button variant="secondary" size="sm" onClick={() => setRestSeconds((value) => value + 15)}>+15 giây</Button>
              <Button variant="secondary" size="sm" onClick={() => { setRestSeconds(0); setRestRunning(false); }}>Bỏ qua</Button>
            </div>
          </div>
        )}

        <details className="rounded-2xl border border-slate-200 bg-slate-50 p-3">
          <summary className="cursor-pointer text-sm font-semibold">Tên buổi tập và ghi chú</summary>
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <label className="text-sm font-medium">Tên buổi tập<Input className="mt-1" value={title} onChange={(event) => setTitle(event.target.value)} /></label>
            <label className="text-sm font-medium">Ghi chú<Input className="mt-1" value={note} onChange={(event) => setNote(event.target.value)} placeholder="Cảm nhận, mục tiêu hôm nay..." /></label>
          </div>
        </details>

        <div className="space-y-4">
          {groups.map((group, groupIndex) => {
            const exercise = exercises.find((item) => item.id === group.exerciseId);
            const insight = intelligence[intelligenceKey(group)];
            const last = insight?.previousPerformance;
            const alternativeState = alternatives[group.key];
            const alternativesOpened = Object.prototype.hasOwnProperty.call(alternatives, group.key);
            return (
              <Card key={group.key} className="border-slate-200">
                <CardHeader className="gap-3 pb-3">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div>
                      <CardTitle>{groupIndex + 1}. {exercise?.name ?? group.historicalExerciseName ?? "Bài tập"}</CardTitle>
                      {!exercise && group.historicalExerciseName && <p className="text-xs text-amber-700">Bài lịch sử đã lưu trữ; giữ nguyên hoặc chọn bài khác.</p>}
                      {group.coachingNote && <p className="text-sm text-emerald-700">{group.coachingNote}</p>}
                      <p className="mt-1 text-xs text-muted-foreground">
                        {last
                          ? `Lần gần nhất ${last.sessionDate}: ${last.sets.map((set) => `${set.weight}kg × ${set.reps}`).join(" · ")}`
                          : "Chưa có dữ liệu lần tập trước"}
                      </p>
                    </div>
                    <div className="flex gap-1">
                      <Button variant="outline" size="icon-sm" onClick={() => moveGroup(groupIndex, -1)} disabled={groupIndex === 0} aria-label="Đưa bài lên"><ArrowUp /></Button>
                      <Button variant="outline" size="icon-sm" onClick={() => moveGroup(groupIndex, 1)} disabled={groupIndex === groups.length - 1} aria-label="Đưa bài xuống"><ArrowDown /></Button>
                      <Button variant="destructive" size="icon-sm" onClick={() => setGroups((current) => current.filter((item) => item.key !== group.key))} disabled={groups.length === 1} aria-label="Xóa bài"><Trash2 /></Button>
                    </div>
                  </div>
                  <div className="grid gap-2 sm:grid-cols-[1fr_150px]">
                    <ExercisePicker
                      id={`live-exercise-${group.key}`}
                      exercises={exercises}
                      value={group.exerciseId}
                      missingValueLabel={group.historicalExerciseName}
                      onChange={(exerciseId) => {
                        updateGroup(group.key, (item) => ({ ...item, exerciseId, historicalExerciseName: undefined }));
                        setAlternatives((current) => {
                          const next = { ...current };
                          delete next[group.key];
                          return next;
                        });
                      }}
                    />
                    <label className="flex items-center gap-2 text-xs text-muted-foreground">
                      Nghỉ
                      <Input type="number" min={0} max={1800} value={group.restSeconds} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, restSeconds: Number(event.target.value), sets: item.sets.map(set => ({ ...set, restSeconds: Number(event.target.value) })) }))} />
                      giây
                    </label>
                  </div>
                  {seed.sessionId && new Set(group.sets.map(set => set.restSeconds ?? group.restSeconds)).size > 1 && <p className="text-xs text-muted-foreground">Các hiệp có thời gian nghỉ khác nhau, giữ nguyên khi lưu. Đổi ô Nghỉ sẽ áp dụng cho tất cả hiệp của bài này.</p>}
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
                              <Button type="button" size="sm" onClick={() => applyProgression(group)}>
                                Áp dụng {formatNumber(insight.progression.suggestedWeight)} kg · {insight.progression.suggestedSets} set
                              </Button>
                            )}
                          </div>
                          {!!insight.personalBests.length && (
                            <div className="flex flex-wrap gap-2">
                              {insight.personalBests.map((best) => (
                                <span key={best.type} className="rounded-full bg-white px-2.5 py-1 text-xs font-medium text-emerald-800 shadow-sm">
                                  <Trophy className="mr-1 inline h-3.5 w-3.5" />
                                  {personalRecordLabel(best.type)}: {formatNumber(best.value)} {best.type === "MAX_SESSION_VOLUME" ? "kg" : best.type === "MAX_REPS_AT_WEIGHT" ? "lần" : "kg"}
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
                        value={preferences[group.exerciseId] ?? "NORMAL"}
                        onChange={(event) => updatePreference(group.exerciseId, event.target.value as ExercisePreference)}
                      >
                        <option value="FAVORITE">★ Yêu thích</option>
                        <option value="NORMAL">Bình thường</option>
                        <option value="LESS">Ít ưu tiên</option>
                        <option value="EXCLUDED">Không đề xuất</option>
                      </select>
                      <Button type="button" variant="outline" size="sm" onClick={() => loadAlternatives(group)}>
                        <RefreshCw className={`h-4 w-4 ${alternativesOpened && alternativeState === null ? "animate-spin" : ""}`} />
                        Đổi bài tương đương
                      </Button>
                    </div>
                  </div>
                  {alternativesOpened && alternativeState !== null && (
                    <div className="rounded-2xl border bg-slate-50 p-3">
                      <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                        Cùng nhóm cơ {exercise?.muscleGroup ?? ""}
                      </p>
                      {alternativeState.length ? (
                        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                          {alternativeState.map((item) => (
                            <button
                              type="button"
                              key={item.exercise.id}
                              className="rounded-xl border bg-white p-3 text-left transition hover:border-emerald-400 hover:bg-emerald-50"
                              onClick={() => {
                                updateGroup(group.key, (current) => ({ ...current, exerciseId: item.exercise.id }));
                                setAlternatives((current) => {
                                  const next = { ...current };
                                  delete next[group.key];
                                  return next;
                                });
                              }}
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
                </CardHeader>
                <CardContent>
                  <div className="hidden grid-cols-[38px_1.2fr_0.8fr_0.8fr_0.7fr_42px] gap-2 px-1 pb-2 text-center text-xs font-semibold text-muted-foreground sm:grid">
                    <span>Set</span><span>Loại</span><span>Kg</span><span>Reps</span><span>RIR</span><span>Xong</span>
                  </div>
                  <div className="space-y-2">
                    {group.sets.map((set, setIndex) => (
                      <div key={set.key} className={`grid grid-cols-3 gap-2 rounded-xl border p-3 sm:grid-cols-[38px_1.2fr_0.8fr_0.8fr_0.7fr_42px] sm:border-0 sm:p-1 ${set.completed ? "border-emerald-300 bg-emerald-50" : "bg-slate-50"}`}>
                        <div className="flex items-center font-bold sm:justify-center"><span className="sm:hidden">Hiệp&nbsp;</span>{setIndex + 1}</div>
                        <select aria-label={`Hiệp ${setIndex + 1} loại hiệp`} className="col-span-2 h-10 min-w-0 rounded-lg border bg-white px-2 text-sm sm:col-span-1" value={set.setType} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, setType: event.target.value as WorkoutSetType } : value) }))}>
                          {Object.entries(setTypeLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
                        </select>
                        <label className="text-xs font-medium sm:contents"><span className="mb-1 block sm:hidden">Kg</span><Input aria-label={`Hiệp ${setIndex + 1} mức tạ kg`} type="number" min={0} step={0.5} value={set.weight} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, weight: Number(event.target.value) } : value) }))} /></label>
                        <label className="text-xs font-medium sm:contents"><span className="mb-1 block sm:hidden">Lần</span><Input aria-label={`Hiệp ${setIndex + 1} số lần`} type="number" min={1} max={500} value={set.reps} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, reps: Number(event.target.value) } : value) }))} /></label>
                        <label className="text-xs font-medium sm:contents"><span className="mb-1 block sm:hidden">RIR</span><Input aria-label={`Hiệp ${setIndex + 1} RIR`} type="number" min={0} max={10} value={set.rir} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, rir: Number(event.target.value) } : value) }))} /></label>
                        <Button type="button" className="col-span-3 w-full sm:col-span-1 sm:w-auto" variant={set.completed ? "default" : "outline"} onClick={() => toggleSet(group.key, set.key)} aria-label={`Hiệp ${setIndex + 1} ${set.completed ? "đã xong" : "đánh dấu xong"}`}><CheckCircle2 /><span className="sm:hidden">{set.completed ? "Đã xong" : "Xong hiệp"}</span></Button>
                      </div>
                    ))}
                  </div>
                  <div className="mt-3 flex flex-wrap gap-2">
                    <Button variant="outline" size="sm" onClick={() => updateGroup(group.key, (item) => ({ ...item, sets: [...item.sets, makeSet(item.sets.at(-1) ? { weight: item.sets.at(-1)!.weight, reps: item.sets.at(-1)!.reps, rir: item.sets.at(-1)!.rir } : {})] }))}><Plus />Thêm set</Button>
                    <Button variant="ghost" size="sm" onClick={() => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.length > 1 ? item.sets.slice(0, -1) : item.sets }))} disabled={group.sets.length === 1}><X />Bỏ set cuối</Button>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        <Button variant="outline" onClick={() => setGroups((current) => [...current, makeExercise(exercises[0]?.id ?? "")])} disabled={!exercises.length}>
          <Plus /> Thêm bài tập
        </Button>
        </div>
        <div className="flex shrink-0 flex-col-reverse gap-2 border-t bg-white p-4 sm:flex-row sm:justify-end sm:px-6">
          <Button variant="destructive" onClick={() => { if (window.confirm("Hủy buổi tập? Dữ liệu chưa lưu sẽ mất.")) onClose(); }}><X />Hủy buổi tập</Button>
          <Button onClick={finish} disabled={saving}><CheckCircle2 />{saving ? "Đang lưu..." : seed.sessionId ? "Lưu thay đổi" : "Hoàn thành buổi tập"}</Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function SessionHistoryCard({ session, onDelete, onEdit }: { session: WorkoutSession; onDelete: () => void; onEdit: () => void }) {
  const exerciseGroups = useMemo(() => {
    const groups = new Map<string, typeof session.sets>();
    for (const set of session.sets) {
      const key = `${set.exerciseOrder ?? 1}:${set.exerciseId}`;
      groups.set(key, [...(groups.get(key) ?? []), set]);
    }
    return [...groups.values()];
  }, [session]);
  const volume = session.sets.filter(set => set.completed && set.setType !== 'WARMUP').reduce((total, set) => total + set.weight * set.reps, 0);

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

function StatCard({ icon: Icon, label, value, tone = "slate" }: { icon: typeof Activity; label: string; value: string; tone?: "emerald" | "amber" | "sky" | "slate" }) {
  const tones = {
    emerald: "bg-emerald-100 text-emerald-700",
    amber: "bg-amber-100 text-amber-700",
    sky: "bg-sky-100 text-sky-700",
    slate: "bg-slate-100 text-slate-700",
  };
  return <Card><CardContent className="flex items-center gap-3 p-4"><div className={`rounded-xl p-2.5 ${tones[tone]}`}><Icon className="h-5 w-5" /></div><div><p className="text-xs font-medium text-muted-foreground">{label}</p><p className="text-xl font-bold">{value}</p></div></CardContent></Card>;
}

function WeeklyVolumeCard({ loading, data }: { loading: boolean; data?: WeeklyWorkoutVolume }) {
  if (loading) {
    return <Card><CardContent className="p-5 text-sm text-muted-foreground">Đang tổng hợp khối lượng tập tuần này...</CardContent></Card>;
  }
  if (!data) return null;
  const maxSets = Math.max(1, ...data.muscleGroups.map((item) => item.workingSets));
  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <CardTitle className="flex items-center gap-2"><TrendingUp className="h-5 w-5 text-emerald-600" />Khối lượng theo nhóm cơ</CardTitle>
            <p className="mt-1 text-sm text-muted-foreground">{data.weekStart} đến {data.weekEnd} · chỉ tính set chính đã hoàn thành.</p>
          </div>
          <div className="flex gap-2 text-sm">
            <span className="rounded-full bg-emerald-50 px-3 py-1 font-semibold text-emerald-700">{data.totalWorkingSets} set</span>
            <span className="rounded-full bg-slate-100 px-3 py-1 font-semibold text-slate-700">{formatNumber(data.totalVolume)} kg</span>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {!data.muscleGroups.length ? (
          <p className="rounded-xl bg-slate-50 p-4 text-sm text-muted-foreground">Chưa có set chính nào trong tuần này.</p>
        ) : (
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {data.muscleGroups.map((item) => (
              <div key={item.muscleGroup} className="rounded-2xl border p-3">
                <div className="flex items-center justify-between gap-2">
                  <p className="font-semibold">{item.muscleGroup}</p>
                  <span className={`text-xs font-semibold ${item.changeSets >= 0 ? "text-emerald-700" : "text-amber-700"}`}>
                    {item.changeSets >= 0 ? "+" : ""}{item.changeSets} set so với tuần trước
                  </span>
                </div>
                <div className="mt-2 h-2 overflow-hidden rounded-full bg-slate-100">
                  <div className="h-full rounded-full bg-emerald-500" style={{ width: `${Math.max(5, item.workingSets / maxSets * 100)}%` }} />
                </div>
                <p className="mt-2 text-xs text-muted-foreground">{item.workingSets} set · {formatNumber(item.totalVolume)} kg volume</p>
              </div>
            ))}
          </div>
        )}
        <p className="mt-3 text-xs text-muted-foreground">{data.disclaimer}</p>
      </CardContent>
    </Card>
  );
}

function intelligenceKey(group: DraftExercise) {
  return [group.exerciseId, group.targetSets, group.minReps, group.maxReps, group.targetRir].join(":");
}

function progressionActionLabel(action: WorkoutIntelligence["progression"]["action"]) {
  const labels: Record<WorkoutIntelligence["progression"]["action"], string> = {
    NO_DATA: "Mốc khởi đầu",
    INCREASE_WEIGHT: "Sẵn sàng tăng tạ",
    BUILD_REPS: "Tiếp tục tăng số lần lặp",
    DECREASE_OR_HOLD: "Giữ hoặc giảm nhẹ mức tạ",
  };
  return labels[action];
}

function personalRecordLabel(type: WorkoutIntelligence["personalBests"][number]["type"]) {
  const labels: Record<WorkoutIntelligence["personalBests"][number]["type"], string> = {
    HEAVIEST_WEIGHT: "Mức tạ cao nhất",
    MAX_REPS_AT_WEIGHT: "Số lần lặp cao nhất",
    ESTIMATED_1RM: "e1RM ước tính",
    MAX_SESSION_VOLUME: "Volume buổi cao nhất",
  };
  return labels[type];
}

function formatNumber(value: number) {
  return new Intl.NumberFormat("vi-VN", { maximumFractionDigits: 1 }).format(value);
}

function formatClock(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, "0");
  const seconds = Math.max(0, totalSeconds % 60).toString().padStart(2, "0");
  return `${minutes}:${seconds}`;
}
