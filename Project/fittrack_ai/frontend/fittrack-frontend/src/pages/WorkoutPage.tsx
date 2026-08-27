import { Fragment, useMemo, useState } from "react";
import axios from "axios";
import {
  Activity,
  CalendarCheck2,
  Dumbbell,
  Timer,
  TrendingUp,
} from "lucide-react";
import {
  createWorkoutSession,
  deleteWorkoutSession,
  getExercises,
  getWorkoutSessionsPage,
  updateWorkoutSession,
} from "../api/workout.api";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toLocalDateInput } from "../lib/format";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import PageHeader from "../components/PageHeader";
import TableLoading from "../components/common/TableLoading";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import DataPagination from "../components/common/DataPagination";
import { useServerPagination } from "../hooks/useServerPagination";
import FormField from "../components/common/FormField";

export default function WorkoutPage() {
  const queryClient = useQueryClient();
  const today = toLocalDateInput();

  const [sessionDate, setSessionDate] = useState(today);
  const [exerciseId, setExerciseId] = useState("");
  const [weight, setWeight] = useState(9);
  const [reps, setReps] = useState(10);
  const [rir, setRir] = useState(2);
  const [durationMinutes, setDurationMinutes] = useState(60);
  const [note, setNote] = useState("");
  const [editingWorkout, setEditingWorkout] = useState<{
    id: string;
    sessionDate: string;
    note: string;
    durationMinutes: number;
    weight: number;
    reps: number;
    rir: number;
  } | null>(null);

  const exercisesQuery = useQuery({
    queryKey: ["exercises"],
    queryFn: getExercises,
  });
  const workoutPager = useServerPagination(20);

  const sessionsQuery = useQuery({
    queryKey: ["workout-sessions", workoutPager.page, workoutPager.pageSize],
    queryFn: () => getWorkoutSessionsPage(workoutPager.page - 1, workoutPager.pageSize),
    placeholderData: (previous) => previous,
  });

  const exercises = exercisesQuery.data ?? [];
  const sessions = sessionsQuery.data?.content ?? [];
  const groupedSessions = useMemo(() => {
    const groups = new Map<string, typeof sessions>();
    for (const session of sessions) {
      const current = groups.get(session.sessionDate) ?? [];
      current.push(session);
      groups.set(session.sessionDate, current);
    }
    return [...groups.entries()];
  }, [sessions]);
  const workoutPagination = {
    ...workoutPager,
    paginatedItems: sessions,
    totalItems: sessionsQuery.data?.totalElements ?? 0,
    totalPages: Math.max(1, sessionsQuery.data?.totalPages ?? 1),
  };
  const selectedExerciseId = exerciseId || exercises[0]?.id || "";
  const totalSessions = sessions.length;
  const totalSets = sessions.reduce((total, session) => total + session.sets.length, 0);
  const totalVolume = sessions.reduce(
    (total, session) => total + session.sets.reduce((sessionTotal, set) => sessionTotal + (set.weight ?? 0) * (set.reps ?? 0), 0),
    0,
  );
  const totalMinutes = sessions.reduce((total, session) => total + (session.durationMinutes ?? 0), 0);

  const createMutation = useMutation({
    mutationFn: createWorkoutSession,
    onSuccess: () => {
      toast.success("Đã lưu buổi tập");
      queryClient.invalidateQueries({ queryKey: ["workout-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
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
      queryClient.invalidateQueries({ queryKey: ["workout-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể xóa buổi tập");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: {
      id: string;
      sessionDate: string;
      note: string;
      durationMinutes: number;
      weight: number;
      reps: number;
      rir: number;
    }) =>
      updateWorkoutSession(payload.id, {
        sessionDate: payload.sessionDate,
        note: payload.note,
        durationMinutes: payload.durationMinutes,
        weight: payload.weight,
        reps: payload.reps,
        rir: payload.rir,
      }),
    onSuccess: () => {
      toast.success("Đã cập nhật buổi tập");
      setEditingWorkout(null);
      queryClient.invalidateQueries({ queryKey: ["workout-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể cập nhật buổi tập");
    },
  });

  const handleCreate = () => {
    createMutation.mutate({
      sessionDate,
      note,
      durationMinutes,
      sets: [
        {
          exerciseId: selectedExerciseId,
          setNumber: 1,
          weight,
          reps,
          rir,
        },
      ],
    });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Bạn có chắc muốn xóa buổi tập này?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  const openEditWorkout = (
    session: { id: string; sessionDate: string; note: string; durationMinutes: number },
    set: { weight: number; reps: number; rir: number }
  ) => {
    setEditingWorkout({
      id: session.id,
      sessionDate: session.sessionDate,
      note: session.note,
      durationMinutes: session.durationMinutes,
      weight: set.weight,
      reps: set.reps,
      rir: set.rir,
    });
  };

  if (exercisesQuery.isLoading || sessionsQuery.isLoading) {
    return <TableLoading />;
  }

  if (exercisesQuery.isError || sessionsQuery.isError) {
    return <ErrorState title="Không thể tải buổi tập" message="Vui lòng tải lại trang." />;
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Buổi tập" description="Ghi lại buổi tập và theo dõi tiến bộ theo thời gian." />

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Card className="border-emerald-200 bg-emerald-50/70">
          <CardContent className="flex items-center gap-3 p-4">
            <div className="rounded-xl bg-emerald-600 p-2.5 text-white"><Activity className="h-5 w-5" aria-hidden="true" /></div>
            <div><p className="text-xs font-medium text-emerald-800/70">Buổi tập</p><p className="text-2xl font-bold text-emerald-950">{totalSessions}</p></div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="flex items-center gap-3 p-4">
            <div className="rounded-xl bg-slate-100 p-2.5 text-slate-700"><Dumbbell className="h-5 w-5" aria-hidden="true" /></div>
            <div><p className="text-xs font-medium text-muted-foreground">Tổng set</p><p className="text-2xl font-bold">{totalSets}</p></div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="flex items-center gap-3 p-4">
            <div className="rounded-xl bg-amber-100 p-2.5 text-amber-700"><TrendingUp className="h-5 w-5" aria-hidden="true" /></div>
            <div><p className="text-xs font-medium text-muted-foreground">Khối lượng</p><p className="text-2xl font-bold">{Math.round(totalVolume).toLocaleString("vi-VN")} kg</p></div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="flex items-center gap-3 p-4">
            <div className="rounded-xl bg-sky-100 p-2.5 text-sky-700"><Timer className="h-5 w-5" aria-hidden="true" /></div>
            <div><p className="text-xs font-medium text-muted-foreground">Thời lượng</p><p className="text-2xl font-bold">{totalMinutes}<span className="ml-1 text-sm font-medium text-muted-foreground">phút</span></p></div>
          </CardContent>
        </Card>
      </div>

      <Card className="border-emerald-200/70 shadow-sm">
        <CardHeader>
          <CardTitle className="flex items-center gap-2"><CalendarCheck2 className="h-5 w-5 text-emerald-600" aria-hidden="true" />Tạo buổi tập</CardTitle>
          <p className="text-sm text-muted-foreground">Bắt đầu bằng một bài tập, sau đó ghi lại mức tạ và cảm nhận để lần sau dễ tăng tiến.</p>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-12">
          {exercises.length === 0 ? (
            <div className="md:col-span-12">
              <EmptyState
                title="Chưa có bài tập"
                description="Hãy thêm bài tập trong kho trước khi tạo buổi tập."
              />
            </div>
          ) : (
            <>
              <FormField label="Ngày tập" htmlFor="workout-date" className="md:col-span-3" required>
                <Input id="workout-date" type="date" value={sessionDate} onChange={(event) => setSessionDate(event.target.value)} />
              </FormField>
              <FormField label="Bài tập" htmlFor="workout-exercise" hint="Chọn động tác đã thực hiện." className="md:col-span-5" required>
                <select
                  id="workout-exercise"
                  className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  value={selectedExerciseId}
                  onChange={(event) => setExerciseId(event.target.value)}
                >
                  {exercises.map((exercise) => (
                    <option key={exercise.id} value={exercise.id}>
                      {exercise.name}
                    </option>
                  ))}
                </select>
              </FormField>
              <FormField label="Thời lượng" htmlFor="workout-duration" unit="phút" className="md:col-span-4">
                <Input id="workout-duration" type="number" min={1} max={600} value={durationMinutes} onChange={(event) => setDurationMinutes(Number(event.target.value))} />
              </FormField>
              <FormField label="Mức tạ" htmlFor="workout-weight" unit="kg" hint="Nhập 0 nếu dùng trọng lượng cơ thể." className="md:col-span-3">
                <Input id="workout-weight" type="number" min={0} step={0.5} value={weight} onChange={(event) => setWeight(Number(event.target.value))} />
              </FormField>
              <FormField label="Số lần lặp" htmlFor="workout-reps" unit="reps" className="md:col-span-3" required>
                <Input id="workout-reps" type="number" min={1} max={500} value={reps} onChange={(event) => setReps(Number(event.target.value))} />
              </FormField>
              <FormField label="RIR" htmlFor="workout-rir" hint="Số lần bạn còn có thể lặp trước khi kiệt sức; 0 là sát ngưỡng." className="md:col-span-3">
                <Input id="workout-rir" type="number" min={0} max={10} value={rir} onChange={(event) => setRir(Number(event.target.value))} />
              </FormField>
              <FormField label="Ghi chú" htmlFor="workout-note" hint="Ví dụ: tập vai buổi sáng, cảm giác mức tạ vừa sức." className="md:col-span-12">
                <Input id="workout-note" value={note} onChange={(event) => setNote(event.target.value)} />
              </FormField>

              <Button className="md:col-span-12" onClick={handleCreate} disabled={createMutation.isPending}>
                {createMutation.isPending ? "Đang lưu..." : "Lưu buổi tập"}
              </Button>
            </>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Lịch sử buổi tập</CardTitle>
          <p className="text-sm text-muted-foreground">Các buổi tập được nhóm theo ngày để bạn nhìn nhanh nhịp luyện tập và vẫn có thể sửa từng set.</p>
        </CardHeader>

        <CardContent>
          {sessions.length === 0 ? (
            <EmptyState
              title="Chưa có buổi tập"
              description="Tạo buổi tập đầu tiên để bắt đầu theo dõi tiến độ."
            />
          ) : (
            <div className="w-full overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Ngày</TableHead>
                  <TableHead>Bài tập</TableHead>
                  <TableHead>Mức tạ</TableHead>
                  <TableHead>Lần lặp</TableHead>
                  <TableHead>RIR</TableHead>
                  <TableHead>Ghi chú</TableHead>
                  <TableHead>Thao tác</TableHead>
                </TableRow>
              </TableHeader>

              <TableBody>
                {groupedSessions.map(([date, daySessions]) => (
                  <Fragment key={date}>
                    <TableRow className="bg-emerald-50/70 hover:bg-emerald-50/70">
                      <TableCell colSpan={7}>
                        <div className="flex flex-wrap items-center justify-between gap-2">
                          <span className="font-semibold text-emerald-950">{date}</span>
                          <span className="text-xs text-emerald-800/70">{daySessions.length} buổi · {daySessions.reduce((total, session) => total + session.sets.length, 0)} set</span>
                        </div>
                      </TableCell>
                    </TableRow>
                    {daySessions.flatMap((session) => session.sets.map((set) => (
                      <TableRow key={set.id}>
                        <TableCell>{session.sessionDate}</TableCell>
                        <TableCell>{set.exerciseName}</TableCell>
                        <TableCell>{set.weight} kg</TableCell>
                        <TableCell>{set.reps}</TableCell>
                        <TableCell>{set.rir}</TableCell>
                        <TableCell>{session.note}</TableCell>
                        <TableCell className="space-x-2">
                          <Button variant="outline" size="sm" onClick={() => openEditWorkout(session, set)}>Sửa</Button>
                          <Button variant="destructive" size="sm" onClick={() => handleDelete(session.id)} disabled={deleteMutation.isPending}>Xóa</Button>
                        </TableCell>
                      </TableRow>
                    )))}
                  </Fragment>
                ))}
              </TableBody>
            </Table>
            <DataPagination
              page={workoutPagination.page}
              pageSize={workoutPagination.pageSize}
              totalItems={workoutPagination.totalItems}
              totalPages={workoutPagination.totalPages}
              onPageChange={workoutPagination.setPage}
              onPageSizeChange={workoutPagination.setPageSize}
            />
          </div>
          )}
        </CardContent>
      </Card>

      <Dialog
        open={!!editingWorkout}
        onOpenChange={(open) => {
          if (!open) {
            setEditingWorkout(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Sửa buổi tập</DialogTitle>
          </DialogHeader>

          {editingWorkout && (
            <div className="space-y-4">
              <Input
                type="date"
                value={editingWorkout.sessionDate}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, sessionDate: event.target.value })}
              />

              <Input
                value={editingWorkout.note}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, note: event.target.value })}
                placeholder="Ghi chú"
              />

              <Input
                type="number"
                value={editingWorkout.durationMinutes}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, durationMinutes: Number(event.target.value) })}
                placeholder="Thời lượng (phút)"
              />

              <Input
                type="number"
                value={editingWorkout.weight}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, weight: Number(event.target.value) })}
                placeholder="Mức tạ"
              />

              <Input
                type="number"
                value={editingWorkout.reps}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, reps: Number(event.target.value) })}
                placeholder="Số lần lặp"
              />

              <Input
                type="number"
                value={editingWorkout.rir}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, rir: Number(event.target.value) })}
                placeholder="RIR"
              />

              <Button className="w-full" onClick={() => updateMutation.mutate(editingWorkout)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Đang lưu..." : "Lưu thay đổi"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
