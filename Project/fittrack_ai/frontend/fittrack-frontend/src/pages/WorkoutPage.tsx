import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import {
  Activity,
  ArrowDown,
  ArrowUp,
  CalendarCheck2,
  CheckCircle2,
  Dumbbell,
  History,
  Plus,
  Play,
  Timer,
  Trash2,
  TrendingUp,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createWorkoutSession,
  deleteWorkoutSession,
  getExercises,
  getPreviousWorkoutPerformance,
  getWorkoutSessionsPage,
  type Exercise,
  type PreviousWorkoutPerformance,
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

type DraftSet = {
  key: string;
  setType: WorkoutSetType;
  weight: number;
  reps: number;
  rir: number;
  completed: boolean;
};

type DraftExercise = {
  key: string;
  exerciseId: string;
  restSeconds: number;
  sets: DraftSet[];
};

type WorkoutSeed = {
  title: string;
  exercises: DraftExercise[];
};

const setTypeLabels: Record<WorkoutSetType, string> = {
  WARMUP: "Khởi động",
  NORMAL: "Chính",
  DROP: "Drop set",
  FAILURE: "Tới ngưỡng",
};

const draftKey = () => `${Date.now()}-${Math.random().toString(36).slice(2)}`;

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
  sets: [makeSet()],
  ...overrides,
});

export default function WorkoutPage() {
  const queryClient = useQueryClient();
  const workoutPager = useServerPagination(12);
  const [liveSeed, setLiveSeed] = useState<WorkoutSeed | null>(null);
  const [selectedPlanDay, setSelectedPlanDay] = useState("");

  const exercisesQuery = useQuery({ queryKey: ["exercises"], queryFn: getExercises });
  const plansQuery = useQuery({ queryKey: ["workout-plans"], queryFn: getWorkoutPlans });
  const sessionsQuery = useQuery({
    queryKey: ["workout-sessions", workoutPager.page, workoutPager.pageSize],
    queryFn: () => getWorkoutSessionsPage(workoutPager.page - 1, workoutPager.pageSize),
    placeholderData: (previous) => previous,
  });

  const exercises = exercisesQuery.data ?? [];
  const sessions = sessionsQuery.data?.content ?? [];
  const planDays = useMemo(
    () => (plansQuery.data ?? []).flatMap((plan) =>
      plan.days.map((day) => ({ plan, day })),
    ),
    [plansQuery.data],
  );

  const totalSets = sessions.reduce((total, session) => total + session.sets.length, 0);
  const totalVolume = sessions.reduce(
    (total, session) =>
      total + session.sets.reduce((subtotal, set) => subtotal + set.weight * set.reps, 0),
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
    ]) {
      queryClient.invalidateQueries({ queryKey: key });
    }
  };

  const createMutation = useMutation({
    mutationFn: createWorkoutSession,
    onSuccess: () => {
      toast.success("Đã hoàn thành và lưu buổi tập");
      refreshWorkoutData();
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể lưu buổi tập");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteWorkoutSession,
    onSuccess: () => {
      toast.success("Đã xóa buổi tập");
      refreshWorkoutData();
    },
    onError: () => toast.error("Không thể xóa buổi tập"),
  });

  const startFreeWorkout = () => {
    if (!exercises[0]) {
      toast.error("Kho bài tập chưa có bài đã được duyệt");
      return;
    }
    setLiveSeed({ title: "Buổi tập tự do", exercises: [makeExercise(exercises[0].id)] });
  };

  const startPlanWorkout = () => {
    const selected = planDays.find(({ plan, day }) => `${plan.id}:${day.id}` === selectedPlanDay);
    if (!selected) {
      toast.error("Hãy chọn một ngày trong giáo án");
      return;
    }
    setLiveSeed({
      title: `${selected.plan.name} · ${selected.day.name}`,
      exercises: selected.day.exercises.map((item) =>
        makeExercise(item.exerciseId, {
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

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2"><History className="h-5 w-5 text-emerald-600" />Lịch sử gần đây</CardTitle>
          <p className="text-sm text-muted-foreground">Mỗi thẻ là một buổi tập hoàn chỉnh, bên trong được nhóm theo từng bài.</p>
        </CardHeader>
        <CardContent className="space-y-3">
          {!sessions.length ? (
            <EmptyState title="Chưa có buổi tập" description="Bắt đầu workout đầu tiên để theo dõi tiến độ." />
          ) : (
            sessions.map((session) => (
              <SessionHistoryCard
                key={session.id}
                session={session}
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
          seed={liveSeed}
          exercises={exercises}
          saving={createMutation.isPending}
          onClose={() => setLiveSeed(null)}
          onFinish={async (payload) => {
            await createMutation.mutateAsync(payload);
            setLiveSeed(null);
          }}
        />
      )}
    </div>
  );
}

function LiveWorkoutDialog({
  seed,
  exercises,
  saving,
  onClose,
  onFinish,
}: {
  seed: WorkoutSeed;
  exercises: Exercise[];
  saving: boolean;
  onClose: () => void;
  onFinish: (payload: Parameters<typeof createWorkoutSession>[0]) => Promise<void>;
}) {
  const [title, setTitle] = useState(seed.title);
  const [note, setNote] = useState("");
  const [groups, setGroups] = useState(seed.exercises.length ? seed.exercises : [makeExercise(exercises[0]?.id ?? "")]);
  const [startedAt] = useState(() => Date.now());
  const [elapsed, setElapsed] = useState(0);
  const [restSeconds, setRestSeconds] = useState(0);
  const [restRunning, setRestRunning] = useState(false);
  const [previous, setPrevious] = useState<Record<string, PreviousWorkoutPerformance | null>>({});

  useEffect(() => {
    const timer = window.setInterval(() => setElapsed(Math.floor((Date.now() - startedAt) / 1000)), 1000);
    return () => window.clearInterval(timer);
  }, [startedAt]);

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
    const missing = [...new Set(groups.map((group) => group.exerciseId))].filter(
      (id) => id && !(id in previous),
    );
    for (const exerciseId of missing) {
      getPreviousWorkoutPerformance(exerciseId)
        .then((result) => {
          if (!cancelled) setPrevious((current) => ({ ...current, [exerciseId]: result }));
        })
        .catch(() => {
          if (!cancelled) setPrevious((current) => ({ ...current, [exerciseId]: null }));
        });
    }
    return () => { cancelled = true; };
  }, [groups, previous]);

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
          restSeconds: group.restSeconds,
          completed: true,
        })),
    );
    if (!completedSets.length) {
      toast.error("Hãy hoàn thành ít nhất một set trước khi kết thúc buổi tập");
      return;
    }
    await onFinish({
      sessionDate: toLocalDateInput(),
      note: [title.trim(), note.trim()].filter(Boolean).join(" · "),
      durationMinutes: Math.max(1, Math.ceil(elapsed / 60)),
      sets: completedSets,
    });
  };

  return (
    <Dialog open onOpenChange={(open) => {
      if (!open && window.confirm("Hủy buổi tập đang thực hiện? Dữ liệu chưa hoàn thành sẽ mất.")) onClose();
    }}>
      <DialogContent className="max-h-[96vh] overflow-y-auto sm:max-w-6xl">
        <DialogHeader>
          <DialogTitle className="flex flex-wrap items-center justify-between gap-3 pr-8">
            <span>Workout mode</span>
            <span className="rounded-full bg-emerald-100 px-3 py-1 text-sm font-semibold text-emerald-800">
              <Timer className="mr-1 inline h-4 w-4" /> {formatClock(elapsed)}
            </span>
          </DialogTitle>
        </DialogHeader>

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

        <div className="grid gap-3 sm:grid-cols-2">
          <label className="text-sm font-medium">Tên buổi tập<Input className="mt-1" value={title} onChange={(event) => setTitle(event.target.value)} /></label>
          <label className="text-sm font-medium">Ghi chú<Input className="mt-1" value={note} onChange={(event) => setNote(event.target.value)} placeholder="Cảm nhận, mục tiêu hôm nay..." /></label>
        </div>

        <div className="space-y-4">
          {groups.map((group, groupIndex) => {
            const exercise = exercises.find((item) => item.id === group.exerciseId);
            const last = previous[group.exerciseId];
            return (
              <Card key={group.key} className="border-slate-200">
                <CardHeader className="gap-3 pb-3">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div>
                      <CardTitle>{groupIndex + 1}. {exercise?.name ?? "Bài tập"}</CardTitle>
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
                      onChange={(exerciseId) =>
                        updateGroup(group.key, (item) => ({ ...item, exerciseId }))
                      }
                    />
                    <label className="flex items-center gap-2 text-xs text-muted-foreground">
                      Nghỉ
                      <Input type="number" min={0} max={1800} value={group.restSeconds} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, restSeconds: Number(event.target.value) }))} />
                      giây
                    </label>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-[38px_1.2fr_0.8fr_0.8fr_0.7fr_42px] gap-2 px-1 pb-2 text-center text-xs font-semibold text-muted-foreground">
                    <span>Set</span><span>Loại</span><span>Kg</span><span>Reps</span><span>RIR</span><span>Xong</span>
                  </div>
                  <div className="space-y-2">
                    {group.sets.map((set, setIndex) => (
                      <div key={set.key} className={`grid grid-cols-[38px_1.2fr_0.8fr_0.8fr_0.7fr_42px] gap-2 rounded-xl p-1 ${set.completed ? "bg-emerald-50" : "bg-slate-50"}`}>
                        <div className="flex items-center justify-center font-bold">{setIndex + 1}</div>
                        <select className="h-10 min-w-0 rounded-lg border bg-white px-2 text-sm" value={set.setType} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, setType: event.target.value as WorkoutSetType } : value) }))}>
                          {Object.entries(setTypeLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
                        </select>
                        <Input type="number" min={0} step={0.5} value={set.weight} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, weight: Number(event.target.value) } : value) }))} />
                        <Input type="number" min={1} max={500} value={set.reps} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, reps: Number(event.target.value) } : value) }))} />
                        <Input type="number" min={0} max={10} value={set.rir} onChange={(event) => updateGroup(group.key, (item) => ({ ...item, sets: item.sets.map((value) => value.key === set.key ? { ...value, rir: Number(event.target.value) } : value) }))} />
                        <Button type="button" size="icon" variant={set.completed ? "default" : "outline"} onClick={() => toggleSet(group.key, set.key)} aria-label="Hoàn thành set"><CheckCircle2 /></Button>
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
        <div className="flex flex-col-reverse gap-2 border-t pt-4 sm:flex-row sm:justify-end">
          <Button variant="destructive" onClick={() => { if (window.confirm("Hủy buổi tập? Dữ liệu chưa lưu sẽ mất.")) onClose(); }}><X />Hủy buổi tập</Button>
          <Button onClick={finish} disabled={saving}><CheckCircle2 />{saving ? "Đang lưu..." : "Hoàn thành buổi tập"}</Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function SessionHistoryCard({ session, onDelete }: { session: WorkoutSession; onDelete: () => void }) {
  const exerciseGroups = useMemo(() => {
    const groups = new Map<string, typeof session.sets>();
    for (const set of session.sets) {
      const key = `${set.exerciseOrder ?? 1}:${set.exerciseId}`;
      groups.set(key, [...(groups.get(key) ?? []), set]);
    }
    return [...groups.values()];
  }, [session]);
  const volume = session.sets.reduce((total, set) => total + set.weight * set.reps, 0);

  return (
    <details className="rounded-2xl border bg-white p-4 open:shadow-sm">
      <summary className="flex cursor-pointer list-none flex-wrap items-center justify-between gap-3">
        <div>
          <p className="font-bold">{session.note || "Buổi tập"}</p>
          <p className="text-xs text-muted-foreground">{session.sessionDate} · {exerciseGroups.length} bài · {session.sets.length} set · {session.durationMinutes} phút</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">{Math.round(volume).toLocaleString("vi-VN")} kg</span>
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

function formatClock(totalSeconds: number) {
  const minutes = Math.floor(totalSeconds / 60).toString().padStart(2, "0");
  const seconds = Math.max(0, totalSeconds % 60).toString().padStart(2, "0");
  return `${minutes}:${seconds}`;
}
