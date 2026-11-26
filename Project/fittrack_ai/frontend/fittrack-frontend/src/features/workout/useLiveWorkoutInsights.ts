import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import { useMutation, useQueries, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  getAlternativeExercises,
  getExercisePreferences,
  getWorkoutIntelligence,
  setExercisePreference,
  type AlternativeExercise,
  type ExercisePreference,
  type ExercisePreferenceResponse,
  type WorkoutIntelligence,
} from "@/api/workout.api";
import { intelligenceKey, withoutKey, type DraftExercise } from "./workout-utils";

/** `undefined`: đang tải; `null`: tải lỗi. */
export type IntelligenceMap = Record<string, WorkoutIntelligence | null | undefined>;

/**
 * Gợi ý tiến độ/PR cho từng bài trong buổi. Mỗi lần mở buổi tập sẽ tải mới
 * (gcTime 0) và không thử lại khi lỗi, như trước khi chuyển sang TanStack Query.
 */
export function useWorkoutIntelligence(groups: DraftExercise[]): IntelligenceMap {
  const targets = useMemo(() => {
    const unique = new Map<string, DraftExercise>();
    for (const group of groups) {
      if (group.exerciseId && !unique.has(intelligenceKey(group))) unique.set(intelligenceKey(group), group);
    }
    return [...unique.entries()];
  }, [groups]);

  const results = useQueries({
    queries: targets.map(([key, group]) => ({
      queryKey: ["workout-intelligence", key],
      queryFn: () => getWorkoutIntelligence(group.exerciseId, {
        targetSets: group.targetSets,
        minReps: group.minReps,
        maxReps: group.maxReps,
        targetRir: group.targetRir,
      }),
      retry: false,
      staleTime: Infinity,
      gcTime: 0,
    })),
  });

  const map: IntelligenceMap = {};
  targets.forEach(([key], index) => {
    const result = results[index];
    map[key] = result?.isError ? null : result?.data;
  });
  return map;
}

const preferencesKey = ["exercise-preferences"];

/** Mức ưu tiên bài tập, cập nhật lạc quan và hoàn tác khi lưu lỗi. */
export function useExercisePreferences() {
  const queryClient = useQueryClient();
  const query = useQuery({
    queryKey: preferencesKey,
    queryFn: getExercisePreferences,
    staleTime: 0,
    retry: false,
  });
  const preferences = useMemo<Record<string, ExercisePreference>>(
    () => Object.fromEntries((query.data ?? []).map((value) => [value.exerciseId, value.preference])),
    [query.data],
  );

  const writeCache = (exerciseId: string, preference: ExercisePreference) => {
    queryClient.setQueryData<ExercisePreferenceResponse[]>(preferencesKey, (current = []) => [
      ...current.filter((value) => value.exerciseId !== exerciseId),
      { exerciseId, preference },
    ]);
  };

  const mutation = useMutation({
    mutationFn: ({ exerciseId, preference }: { exerciseId: string; preference: ExercisePreference }) =>
      setExercisePreference(exerciseId, preference),
    onMutate: ({ exerciseId, preference }) => {
      const current = queryClient.getQueryData<ExercisePreferenceResponse[]>(preferencesKey) ?? [];
      const previous = current.find((value) => value.exerciseId === exerciseId)?.preference ?? "NORMAL";
      writeCache(exerciseId, preference);
      return { previous };
    },
    onSuccess: () => toast.success("Đã lưu mức ưu tiên bài tập"),
    onError: (_error, { exerciseId }, context) => {
      writeCache(exerciseId, context?.previous ?? "NORMAL");
      toast.error("Không thể lưu mức ưu tiên");
    },
  });

  const updatePreference = (exerciseId: string, preference: ExercisePreference) =>
    mutation.mutate({ exerciseId, preference });

  return { preferences, updatePreference };
}

/** Bài thay thế cùng nhóm cơ; tải khi người dùng bấm "Đổi bài tương đương". */
export function useExerciseAlternatives() {
  const [alternatives, setAlternatives] = useState<Record<string, AlternativeExercise[] | null>>({});
  const [equipment, setEquipment] = useState("");

  const loadAlternatives = async (group: DraftExercise, filter = equipment) => {
    setAlternatives((current) => ({ ...current, [group.key]: null }));
    try {
      const values = await getAlternativeExercises(group.exerciseId, filter);
      setAlternatives((current) => ({ ...current, [group.key]: values }));
      if (!values.length) toast.info("Chưa có bài thay thế phù hợp cùng nhóm cơ");
    } catch {
      setAlternatives((current) => withoutKey(current, group.key));
      toast.error("Không thể tải bài thay thế");
    }
  };

  const closeAlternatives = (groupKey: string) => setAlternatives((current) => withoutKey(current, groupKey));

  return { alternatives, equipment, setEquipment, loadAlternatives, closeAlternatives };
}

/** Đồng hồ nghỉ giữa các set. */
export function useRestTimer() {
  const [restSeconds, setRestSeconds] = useState(0);
  const [restRunning, setRestRunning] = useState(false);

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

  return {
    restSeconds,
    restRunning,
    startRest: (seconds: number) => { setRestSeconds(seconds); setRestRunning(true); },
    adjustRest: (delta: number) => setRestSeconds((value) => Math.max(0, value + delta)),
    skipRest: () => { setRestSeconds(0); setRestRunning(false); },
  };
}
