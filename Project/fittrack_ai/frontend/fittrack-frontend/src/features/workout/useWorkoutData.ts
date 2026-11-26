import axios from "axios";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createWorkoutSession,
  deleteWorkoutSession,
  getExercises,
  getWeeklyWorkoutVolume,
  getWorkoutSessionsPage,
  replaceWorkoutSession,
} from "@/api/workout.api";
import { getWorkoutPlans } from "@/api/workout-plan.api";
import { completeTraining, getTrainingAppointment } from "@/api/training-program.api";
import { formatNumber, personalRecordLabel, type WorkoutSessionPayload } from "./workout-utils";

export type HistoryFilters = { from: string; to: string; exerciseId: string };

/** Mọi truy vấn của màn Buổi tập. */
export function useWorkoutPageQueries({
  appointmentId,
  page,
  pageSize,
  historyFilters,
}: {
  appointmentId: string | null;
  page: number;
  pageSize: number;
  historyFilters: HistoryFilters;
}) {
  const appointmentQuery = useQuery({
    queryKey: ["training-appointment", appointmentId],
    queryFn: () => getTrainingAppointment(appointmentId!),
    enabled: !!appointmentId,
  });
  const exercisesQuery = useQuery({ queryKey: ["exercises"], queryFn: getExercises });
  const plansQuery = useQuery({ queryKey: ["workout-plans"], queryFn: getWorkoutPlans });
  const sessionsQuery = useQuery({
    queryKey: ["workout-sessions", page, pageSize, historyFilters],
    queryFn: () => getWorkoutSessionsPage(page - 1, pageSize, {
      from: historyFilters.from || undefined,
      to: historyFilters.to || undefined,
      exerciseId: historyFilters.exerciseId || undefined,
    }),
    placeholderData: (previous) => previous,
  });
  const weeklyVolumeQuery = useQuery({
    queryKey: ["weekly-workout-volume"],
    queryFn: getWeeklyWorkoutVolume,
  });
  return { appointmentQuery, exercisesQuery, plansQuery, sessionsQuery, weeklyVolumeQuery };
}

/** Lưu mới, sửa, hoàn thành lịch tập và xóa buổi tập. */
export function useWorkoutMutations() {
  const queryClient = useQueryClient();

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

  const editMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: WorkoutSessionPayload }) => replaceWorkoutSession(id, payload),
    onSuccess: () => {
      toast.success("Đã cập nhật toàn bộ buổi tập");
      refreshWorkoutData();
    },
    onError: () => toast.error("Không thể cập nhật buổi tập"),
  });

  const appointmentMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: WorkoutSessionPayload }) => completeTraining(id, payload),
    onSuccess: () => {
      toast.success("Đã lưu buổi thực tế và hoàn thành lần tập trong lịch");
      refreshWorkoutData();
      queryClient.invalidateQueries({ queryKey: ["training-appointments"] });
      queryClient.invalidateQueries({ queryKey: ["training-cycles"] });
      queryClient.invalidateQueries({ queryKey: ["training-appointment"] });
    },
    onError: (error) => toast.error(axios.isAxiosError(error)
      ? error.response?.data?.message || "Không lưu được lịch tập"
      : "Không lưu được lịch tập"),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteWorkoutSession,
    onSuccess: () => {
      toast.success("Đã xóa buổi tập");
      refreshWorkoutData();
    },
    onError: () => toast.error("Không thể xóa buổi tập"),
  });

  return { createMutation, editMutation, appointmentMutation, deleteMutation };
}
