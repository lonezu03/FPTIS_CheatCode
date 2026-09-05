import { useState } from "react";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { toLocalDateInput } from "../lib/format";

import { getExercises, type Exercise } from "../api/workout.api";
import {
  createWorkoutPlan,
  deleteWorkoutPlan,
  generateSessionFromPlan,
  getWorkoutPlansPage,
  type WorkoutPlan,
} from "../api/workout-plan.api";

import PageHeader from "../components/PageHeader";
import TableLoading from "../components/common/TableLoading";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import DataPagination from "../components/common/DataPagination";
import { useServerPagination } from "../hooks/useServerPagination";
import FormField from "../components/common/FormField";
import ExercisePicker from "../components/workouts/ExercisePicker";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableRow } from "@/components/ui/table";

type PlanExerciseDraft = {
  exerciseId: string;
  exerciseOrder: number;
  targetSets: number;
  targetReps: number;
  targetWeight: number;
  targetRir: number;
};

type PlanDayDraft = {
  name: string;
  dayOrder: number;
  exercises: PlanExerciseDraft[];
};

export default function WorkoutPlansPage() {
  const queryClient = useQueryClient();

  const today = toLocalDateInput();

  const [name, setName] = useState("Giáo án tăng cơ tại nhà");
  const [description, setDescription] = useState("Giáo án 3 ngày với tạ đơn, vòng treo và xà đơn");

  const [draftDays, setDraftDays] = useState<PlanDayDraft[]>([
    {
      name: "Ngày tập đẩy",
      dayOrder: 1,
      exercises: [
        {
          exerciseId: "",
          exerciseOrder: 1,
          targetSets: 3,
          targetReps: 10,
          targetWeight: 9,
          targetRir: 2,
        },
      ],
    },
  ]);

  const exercisesQuery = useQuery({
    queryKey: ["exercises"],
    queryFn: getExercises,
  });
  const planPager = useServerPagination(12);

  const plansQuery = useQuery({
    queryKey: ["workout-plans", planPager.page, planPager.pageSize],
    queryFn: () => getWorkoutPlansPage(planPager.page - 1, planPager.pageSize),
    placeholderData: (previous) => previous,
  });

  const exercises = exercisesQuery.data ?? [];
  const plans = plansQuery.data?.content ?? [];
  const planPagination = {
    ...planPager,
    paginatedItems: plans,
    totalItems: plansQuery.data?.totalElements ?? 0,
    totalPages: Math.max(1, plansQuery.data?.totalPages ?? 1),
  };
  const defaultExerciseId = exercises[0]?.id ?? "";

  const createMutation = useMutation({
    mutationFn: createWorkoutPlan,
    onSuccess: () => {
      toast.success("Đã tạo giáo án");
      queryClient.invalidateQueries({ queryKey: ["workout-plans"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể tạo giáo án");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteWorkoutPlan,
    onSuccess: () => {
      toast.success("Đã xóa giáo án");
      queryClient.invalidateQueries({ queryKey: ["workout-plans"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể xóa giáo án");
    },
  });

  const generateMutation = useMutation({
    mutationFn: (payload: { planId: string; dayId: string; note: string }) =>
      generateSessionFromPlan(payload.planId, {
        dayId: payload.dayId,
        sessionDate: today,
        note: payload.note,
      }),
    onSuccess: () => {
      toast.success("Đã tạo buổi tập từ giáo án");
      queryClient.invalidateQueries({ queryKey: ["workout-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể tạo buổi tập");
    },
  });

  const addDay = () => {
    setDraftDays((prev) => [
      ...prev,
      {
          name: `Ngày ${prev.length + 1}`,
        dayOrder: prev.length + 1,
        exercises: [
          {
            exerciseId: exercises[0]?.id ?? "",
            exerciseOrder: 1,
            targetSets: 3,
            targetReps: 10,
            targetWeight: 0,
            targetRir: 2,
          },
        ],
      },
    ]);
  };

  const updateDay = (index: number, field: "name" | "dayOrder", value: string | number) => {
    setDraftDays((prev) =>
      prev.map((day, dayIndex) =>
        dayIndex === index
          ? {
              ...day,
              [field]: value,
            }
          : day
      )
    );
  };

  const removeDay = (index: number) => {
    setDraftDays((prev) => prev.filter((_, dayIndex) => dayIndex !== index));
  };

  const addExerciseToDay = (dayIndex: number) => {
    setDraftDays((prev) =>
      prev.map((day, index) => {
        if (index !== dayIndex) {
          return day;
        }

        return {
          ...day,
          exercises: [
            ...day.exercises,
            {
              exerciseId: exercises[0]?.id ?? "",
              exerciseOrder: day.exercises.length + 1,
              targetSets: 3,
              targetReps: 10,
              targetWeight: 0,
              targetRir: 2,
            },
          ],
        };
      })
    );
  };

  const removeExerciseFromDay = (dayIndex: number, exerciseIndex: number) => {
    setDraftDays((prev) =>
      prev.map((day, index) => {
        if (index !== dayIndex) {
          return day;
        }

        return {
          ...day,
          exercises: day.exercises.filter((_, currentExerciseIndex) => currentExerciseIndex !== exerciseIndex),
        };
      })
    );
  };

  const updateDayExercise = (
    dayIndex: number,
    exerciseIndex: number,
    field: keyof PlanExerciseDraft,
    value: string | number
  ) => {
    setDraftDays((prev) =>
      prev.map((day, index) => {
        if (index !== dayIndex) {
          return day;
        }

        return {
          ...day,
          exercises: day.exercises.map((exercise, currentExerciseIndex) =>
            currentExerciseIndex === exerciseIndex
              ? {
                  ...exercise,
                  [field]: value,
                }
              : exercise
          ),
        };
      })
    );
  };

  const handleCreate = () => {
    createMutation.mutate({
      name,
      description,
      days: draftDays.map((day) => ({
        name: day.name,
        dayOrder: day.dayOrder,
        exercises: day.exercises.map((exercise, index) => ({
          exerciseId: exercise.exerciseId || defaultExerciseId,
          exerciseOrder: index + 1,
          targetSets: exercise.targetSets,
          targetReps: exercise.targetReps,
          targetWeight: exercise.targetWeight,
          targetRir: exercise.targetRir,
        })),
      })),
    });
  };

  if (exercisesQuery.isLoading || plansQuery.isLoading) {
    return <TableLoading />;
  }

  if (exercisesQuery.isError || plansQuery.isError) {
    return <ErrorState title="Không thể tải giáo án" message="Vui lòng tải lại trang." />;
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader
        title="Giáo án"
        description="Tạo giáo án dùng lại và khởi tạo nhanh các buổi tập."
      />

      <Card>
        <CardHeader>
            <CardTitle>Tạo giáo án</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Tên giáo án" htmlFor="plan-name" hint="Tên ngắn gọn để bạn dễ tìm và sử dụng lại." required>
              <Input id="plan-name" value={name} onChange={(event) => setName(event.target.value)} placeholder="Ví dụ: Tăng cơ tại nhà" />
            </FormField>
            <FormField label="Mô tả mục tiêu" htmlFor="plan-description" hint="Ghi mục tiêu, số ngày và dụng cụ cần thiết.">
              <Input id="plan-description" value={description} onChange={(event) => setDescription(event.target.value)} placeholder="Ví dụ: 3 ngày/tuần với tạ đơn" />
            </FormField>
          </div>

          <div className="space-y-4">
            {draftDays.map((day, dayIndex) => (
              <div key={dayIndex} className="space-y-4 rounded-2xl border bg-slate-50 p-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-semibold">Ngày {dayIndex + 1}</h3>

                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => removeDay(dayIndex)}
                    disabled={draftDays.length === 1}
                  >
                    Xóa ngày
                  </Button>
                </div>

                <div className="grid gap-4 md:grid-cols-3">
                  <FormField label="Tên ngày tập" htmlFor={`plan-day-name-${dayIndex}`} hint="Ví dụ: Ngày đẩy, Chân & mông." className="md:col-span-2" required>
                    <Input
                      id={`plan-day-name-${dayIndex}`}
                      value={day.name}
                      onChange={(event) => updateDay(dayIndex, "name", event.target.value)}
                      placeholder="Tên ngày tập"
                    />
                  </FormField>
                  <FormField label="Thứ tự ngày" htmlFor={`plan-day-order-${dayIndex}`} hint="Vị trí ngày trong giáo án." required>
                    <Input
                      id={`plan-day-order-${dayIndex}`}
                      type="number"
                      min={1}
                      value={day.dayOrder}
                      onChange={(event) => updateDay(dayIndex, "dayOrder", Number(event.target.value))}
                    />
                  </FormField>
                </div>

                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-semibold">Danh sách bài tập</p>
                      <p className="text-xs text-muted-foreground">Thiết lập khối lượng mục tiêu cho từng bài.</p>
                    </div>

                    <Button variant="outline" size="sm" onClick={() => addExerciseToDay(dayIndex)}>
                    Thêm bài tập
                    </Button>
                  </div>

                  {day.exercises.map((exercise, exerciseIndex) => (
                    <div key={exerciseIndex} className="grid gap-3 rounded-xl border bg-white p-4 md:grid-cols-12">
                      <FormField
                        label="Bài tập"
                        htmlFor={`plan-exercise-${dayIndex}-${exerciseIndex}`}
                        hint="Tìm theo tên rồi lọc thêm bằng nhóm cơ chính hoặc dụng cụ."
                        className="md:col-span-4"
                        required
                      >
                        <ExercisePicker
                          id={`plan-exercise-${dayIndex}-${exerciseIndex}`}
                          exercises={exercises}
                          value={exercise.exerciseId || defaultExerciseId}
                          onChange={(exerciseId) =>
                            updateDayExercise(dayIndex, exerciseIndex, "exerciseId", exerciseId)
                          }
                        />
                      </FormField>

                      <ExercisePreview
                        exercise={exercises.find(
                          (item) => item.id === (exercise.exerciseId || defaultExerciseId)
                        )}
                      />

                      <FormField label="Số hiệp" htmlFor={`plan-sets-${dayIndex}-${exerciseIndex}`} hint="Số lượt thực hiện." className="md:col-span-2" required>
                        <Input
                          id={`plan-sets-${dayIndex}-${exerciseIndex}`}
                          type="number"
                          min={1}
                          max={20}
                          value={exercise.targetSets}
                          onChange={(event) =>
                            updateDayExercise(dayIndex, exerciseIndex, "targetSets", Number(event.target.value))
                          }
                        />
                      </FormField>

                      <FormField label="Lần lặp/hiệp" htmlFor={`plan-reps-${dayIndex}-${exerciseIndex}`} unit="reps" className="md:col-span-2" required>
                        <Input
                          id={`plan-reps-${dayIndex}-${exerciseIndex}`}
                          type="number"
                          min={1}
                          max={100}
                          value={exercise.targetReps}
                          onChange={(event) =>
                            updateDayExercise(dayIndex, exerciseIndex, "targetReps", Number(event.target.value))
                          }
                        />
                      </FormField>

                      <FormField label="Mức tạ" htmlFor={`plan-weight-${dayIndex}-${exerciseIndex}`} unit="kg" className="md:col-span-2">
                        <Input
                          id={`plan-weight-${dayIndex}-${exerciseIndex}`}
                          type="number"
                          min={0}
                          step={0.5}
                          value={exercise.targetWeight}
                          onChange={(event) =>
                            updateDayExercise(dayIndex, exerciseIndex, "targetWeight", Number(event.target.value))
                          }
                        />
                      </FormField>

                      <FormField label="RIR" htmlFor={`plan-rir-${dayIndex}-${exerciseIndex}`} hint="Số lần còn có thể lặp." className="md:col-span-2">
                        <Input
                          id={`plan-rir-${dayIndex}-${exerciseIndex}`}
                          type="number"
                          min={0}
                          max={10}
                          value={exercise.targetRir}
                          onChange={(event) =>
                            updateDayExercise(dayIndex, exerciseIndex, "targetRir", Number(event.target.value))
                          }
                        />
                      </FormField>

                      <Button
                        variant="destructive"
                        size="sm"
                        className="md:col-span-2 md:self-end"
                        onClick={() => removeExerciseFromDay(dayIndex, exerciseIndex)}
                        disabled={day.exercises.length === 1}
                      >
                        Xóa
                      </Button>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>

          <div className="flex gap-3">
            <Button variant="outline" onClick={addDay}>
              Thêm ngày
            </Button>

            <Button onClick={handleCreate} disabled={createMutation.isPending || exercises.length === 0}>
              {createMutation.isPending ? "Đang tạo..." : "Tạo giáo án"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {plans.length === 0 ? (
        <EmptyState title="Chưa có giáo án" description="Tạo giáo án dùng lại để bắt đầu buổi tập nhanh hơn." />
      ) : (
        <div className="space-y-4">
          <div className="grid gap-4 md:gap-6 lg:grid-cols-2">
            {planPagination.paginatedItems.map((plan) => (
              <PlanCard
                key={plan.id}
                plan={plan}
                isDeleting={deleteMutation.isPending}
                isGenerating={generateMutation.isPending}
                onDelete={() => {
                  if (!window.confirm("Bạn có chắc muốn xóa giáo án này?")) {
                    return;
                  }

                  deleteMutation.mutate(plan.id);
                }}
                onGenerate={(dayId, dayName) =>
                  generateMutation.mutate({
                    planId: plan.id,
                    dayId,
                    note: `${plan.name} - ${dayName}`,
                  })
                }
              />
            ))}
          </div>
          <DataPagination
            page={planPagination.page}
            pageSize={planPagination.pageSize}
            totalItems={planPagination.totalItems}
            totalPages={planPagination.totalPages}
            onPageChange={planPagination.setPage}
            onPageSizeChange={planPagination.setPageSize}
          />
        </div>
      )}
    </div>
  );
}

function PlanCard({
  plan,
  isDeleting,
  isGenerating,
  onDelete,
  onGenerate,
}: {
  plan: WorkoutPlan;
  isDeleting: boolean;
  isGenerating: boolean;
  onDelete: () => void;
  onGenerate: (dayId: string, dayName: string) => void;
}) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-start justify-between gap-4">
          <div>
            <CardTitle>{plan.name}</CardTitle>
            <p className="mt-1 text-sm text-muted-foreground">{plan.description}</p>
          </div>

          <Button variant="destructive" size="sm" onClick={onDelete} disabled={isDeleting}>
            Xóa
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {plan.days.map((day) => (
          <div key={day.id} className="rounded-xl border p-4">
            <div className="mb-3 flex items-center justify-between gap-3">
              <h3 className="font-semibold">
                Ngày {day.dayOrder}: {day.name}
              </h3>

              <Button size="sm" onClick={() => onGenerate(day.id, day.name)} disabled={isGenerating}>
                Tạo buổi tập
              </Button>
            </div>

            <div className="w-full overflow-x-auto">
              <Table>
                <TableBody>
                  {day.exercises.map((exercise) => (
                    <TableRow key={exercise.id}>
                      <TableCell className="min-w-[260px]">
                        <div className="flex items-start gap-3">
                          {exercise.imageUrl && (
                            <img
                              src={exercise.imageUrl}
                              alt={exercise.exerciseName}
                              className="size-12 shrink-0 rounded-lg border object-cover"
                              loading="lazy"
                            />
                          )}
                          <div className="min-w-0">
                            <p className="font-medium">{exercise.exerciseName}</p>
                            {exercise.description && (
                              <p className="mt-1 line-clamp-2 text-xs leading-5 text-muted-foreground">
                                {exercise.description}
                              </p>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{exercise.muscleGroup}</TableCell>
                      <TableCell>{exercise.equipment || "Không dụng cụ"}</TableCell>
                    <TableCell>{exercise.targetSets} hiệp</TableCell>
                    <TableCell>{exercise.targetReps} lần</TableCell>
                      <TableCell>{exercise.targetWeight}kg</TableCell>
                      <TableCell>RIR {exercise.targetRir}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

function ExercisePreview({ exercise }: { exercise?: Exercise }) {
  if (!exercise) {
    return (
      <div className="rounded-xl border border-dashed p-3 text-sm text-muted-foreground md:col-span-8">
        Chọn một bài tập để xem nhóm cơ, dụng cụ và hướng dẫn thực hiện.
      </div>
    );
  }

  return (
    <div className="grid min-w-0 gap-3 rounded-xl border bg-slate-50 p-3 sm:grid-cols-[6rem_minmax(0,1fr)] md:col-span-8">
      <div className="flex aspect-square w-24 shrink-0 items-center justify-center overflow-hidden rounded-xl border bg-white">
        {exercise.imageUrl ? (
          <a
            href={exercise.imageUrl}
            target="_blank"
            rel="noreferrer"
            className="block size-full"
            title="Mở ảnh bài tập"
          >
            <img
              src={exercise.imageUrl}
              alt={exercise.name}
              className="size-full object-cover transition-transform hover:scale-105"
              loading="lazy"
            />
          </a>
        ) : (
          <div className="px-2 text-center text-xs leading-5 text-muted-foreground">
            <span className="block text-2xl" aria-hidden="true">🖼️</span>
            Chưa có ảnh
          </div>
        )}
      </div>
      <div className="min-w-0 space-y-2">
        <p className="truncate text-sm font-semibold">{exercise.name}</p>
        <div className="flex flex-wrap gap-2 text-xs">
          <span className="rounded-full bg-emerald-100 px-2.5 py-1 font-medium text-emerald-800">
            Nhóm cơ: {exercise.muscleGroup || "Chưa cập nhật"}
          </span>
          <span className="rounded-full bg-slate-200 px-2.5 py-1 font-medium text-slate-700">
            Dụng cụ: {exercise.equipment || "Không dụng cụ"}
          </span>
        </div>
        <p className="text-sm leading-5 text-muted-foreground">
          {exercise.description || "Bài tập này chưa có mô tả hoặc ghi chú hướng dẫn."}
        </p>
        {!exercise.imageUrl && (
          <p className="text-xs text-amber-700">
            Có thể bổ sung ảnh cho bài tập này tại Kho bài tập.
          </p>
        )}
      </div>
    </div>
  );
}
