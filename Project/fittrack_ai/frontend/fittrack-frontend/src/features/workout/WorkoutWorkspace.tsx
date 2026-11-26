import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { toast } from "sonner";

import type { WorkoutSession } from "@/api/workout.api";
import { useConfirm } from "@/components/common/ConfirmDialog";
import ErrorState from "@/components/common/ErrorState";
import TableLoading from "@/components/common/TableLoading";
import PageHeader from "@/components/PageHeader";
import { Button } from "@/components/ui/button";
import { useServerPagination } from "@/hooks/useServerPagination";
import { clearSessionDraft } from "@/lib/sessionDraft";
import LiveWorkoutDialog from "./LiveWorkoutDialog";
import RecoverableDraftCard from "./RecoverableDraftCard";
import { useWorkoutMutations, useWorkoutPageQueries, type HistoryFilters } from "./useWorkoutData";
import WeeklyVolumeCard from "./WeeklyVolumeCard";
import WorkoutHistorySection from "./WorkoutHistorySection";
import WorkoutStartCard from "./WorkoutStartCard";
import WorkoutStatCards from "./WorkoutStatCards";
import {
  makeExercise,
  readWorkoutDraft,
  seedFromAppointment,
  seedFromLatestSession,
  seedFromPlanDay,
  seedFromSession,
  type WorkoutSeed,
} from "./workout-utils";

/** Màn Buổi tập của một tài khoản: bắt đầu buổi, khối lượng tuần, lịch sử. */
export default function WorkoutWorkspace({ owner }: { owner: string }) {
  const confirm = useConfirm();
  const [searchParams] = useSearchParams();
  const [recoverable, setRecoverable] = useState(() => readWorkoutDraft(owner));
  const workoutPager = useServerPagination(12);
  const [liveSeed, setLiveSeed] = useState<WorkoutSeed | null>(() => searchParams.get("action") === "new" && !recoverable ? { title: "Buổi tập tự do", exercises: [] } : null);
  const [selectedPlanDay, setSelectedPlanDay] = useState(searchParams.get("planDay") ?? "");
  const [autoStarted, setAutoStarted] = useState(false);
  const [historyFilters, setHistoryFilters] = useState<HistoryFilters>({ from: "", to: "", exerciseId: "" });
  const { appointmentQuery, exercisesQuery, plansQuery, sessionsQuery, weeklyVolumeQuery } = useWorkoutPageQueries({
    appointmentId: searchParams.get("appointment"),
    page: workoutPager.page,
    pageSize: workoutPager.pageSize,
    historyFilters,
  });
  const { createMutation, editMutation, appointmentMutation, deleteMutation } = useWorkoutMutations();

  useEffect(() => {
    const appointment = appointmentQuery.data;
    if (!appointment || autoStarted) return;
    const timer = window.setTimeout(() => {
      setAutoStarted(true);
      if (appointment.completedSessionId) {
        toast.info("Lần tập này đã hoàn thành");
        return;
      }
      setLiveSeed(seedFromAppointment(appointment));
    }, 0);
    return () => window.clearTimeout(timer);
  }, [appointmentQuery.data, autoStarted]);

  const exercises = exercisesQuery.data ?? [];
  const sessions = sessionsQuery.data?.content ?? [];
  const planDays = useMemo(
    () => (plansQuery.data ?? []).flatMap((plan) => plan.days.map((day) => ({ plan, day }))),
    [plansQuery.data],
  );

  /** Hỏi trước khi thay bản nháp đang có; không có bản nháp thì cho qua. */
  const confirmReplaceDraft = async (title: string) =>
    !recoverable || await confirm({ title, description: "Bản nháp buổi tập cũ trong tab này sẽ bị thay thế.", confirmText: "Thay bản nháp", destructive: true });

  const startFreeWorkout = async () => {
    if (!(await confirmReplaceDraft("Bắt đầu buổi tập mới?"))) return;
    if (!exercises[0]) {
      toast.error("Kho bài tập chưa có bài đã được duyệt");
      return;
    }
    setLiveSeed({ title: "Buổi tập tự do", exercises: [makeExercise(exercises[0].id)] });
  };

  const startPlanWorkout = async () => {
    if (!(await confirmReplaceDraft("Bắt đầu theo giáo án?"))) return;
    const selected = planDays.find(({ plan, day }) => `${plan.id}:${day.id}` === selectedPlanDay);
    if (!selected) {
      toast.error("Hãy chọn một ngày trong giáo án");
      return;
    }
    setLiveSeed(seedFromPlanDay(selected.plan, selected.day));
  };

  const reuseLatest = async () => {
    if (!(await confirmReplaceDraft("Dùng lại buổi gần đây?"))) return;
    setLiveSeed(seedFromLatestSession(sessions[0], exercises));
  };

  const editSession = async (session: WorkoutSession) => {
    if (!(await confirmReplaceDraft("Sửa buổi tập này?"))) return;
    setLiveSeed(seedFromSession(session));
  };

  const deleteSession = async (session: WorkoutSession) => {
    const ok = await confirm({
      title: "Xóa buổi tập?",
      description: `Buổi tập ngày ${session.sessionDate} và toàn bộ hiệp đã ghi sẽ bị xóa.`,
      confirmText: "Xóa",
      destructive: true,
    });
    if (ok) deleteMutation.mutate(session.id);
  };

  useEffect(() => {
    if (searchParams.get("planDay") && plansQuery.isSuccess && exercisesQuery.isSuccess && !autoStarted) {
      const timer = window.setTimeout(() => { setAutoStarted(true); if (!recoverable) startPlanWorkout(); }, 0);
      return () => window.clearTimeout(timer);
    }
    // The explicit navigation intent is consumed once; subsequent form edits must not restart it.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [plansQuery.isSuccess, exercisesQuery.isSuccess, autoStarted, recoverable, searchParams]);

  const closeLiveWorkout = () => {
    clearSessionDraft(owner, "workout");
    setRecoverable(null);
    setLiveSeed(null);
  };

  if (exercisesQuery.isLoading || sessionsQuery.isLoading || plansQuery.isLoading || appointmentQuery.isLoading) {
    return <TableLoading />;
  }
  if (exercisesQuery.isError || sessionsQuery.isError || plansQuery.isError) {
    return <ErrorState title="Không thể tải dữ liệu luyện tập" message="Vui lòng tải lại trang." />;
  }
  if (appointmentQuery.isError) {
    return (
      <div className="space-y-3">
        <ErrorState title="Không mở được lịch tập" message="Kiểm tra quyền luyện tập/thời khóa biểu hoặc tải lại. Buổi tập chưa được ghi vào lịch sử." />
        <Button onClick={() => appointmentQuery.refetch()}>Thử lại</Button>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <PageHeader title="Buổi tập" />
      {recoverable && !liveSeed && (
        <RecoverableDraftCard
          title={recoverable.title}
          onResume={() => setLiveSeed(recoverable)}
          onDiscard={() => { clearSessionDraft(owner, "workout"); setRecoverable(null); }}
        />
      )}
      <WorkoutStatCards sessions={sessions} />

      <WorkoutStartCard
        canReuseLatest={workoutPager.page === 1 && !!sessions[0]}
        planDays={planDays}
        selectedPlanDay={selectedPlanDay}
        onSelectPlanDay={setSelectedPlanDay}
        onStartFree={startFreeWorkout}
        onReuseLatest={reuseLatest}
        onStartPlan={startPlanWorkout}
      />

      <WeeklyVolumeCard loading={weeklyVolumeQuery.isLoading} data={weeklyVolumeQuery.data} />

      <WorkoutHistorySection
        filters={historyFilters}
        onFilterChange={(patch) => { workoutPager.setPage(1); setHistoryFilters(prev => ({ ...prev, ...patch })); }}
        exercises={exercises}
        sessions={sessions}
        page={workoutPager.page}
        pageSize={workoutPager.pageSize}
        totalItems={sessionsQuery.data?.totalElements ?? 0}
        totalPages={Math.max(1, sessionsQuery.data?.totalPages ?? 1)}
        onPageChange={workoutPager.setPage}
        onPageSizeChange={workoutPager.setPageSize}
        onEdit={editSession}
        onDelete={deleteSession}
      />

      {liveSeed && (
        <LiveWorkoutDialog
          key={owner}
          owner={owner}
          seed={liveSeed}
          exercises={exercises}
          saving={createMutation.isPending || editMutation.isPending || appointmentMutation.isPending}
          onClose={closeLiveWorkout}
          onFinish={async (payload) => {
            if (liveSeed.sessionId) await editMutation.mutateAsync({ id: liveSeed.sessionId, payload });
            else if (liveSeed.appointmentId) await appointmentMutation.mutateAsync({ id: liveSeed.appointmentId, payload });
            else await createMutation.mutateAsync(payload);
            closeLiveWorkout();
          }}
        />
      )}
    </div>
  );
}
