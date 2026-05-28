import { useEffect, useState } from "react";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import { getExercises } from "../api/workout.api";
import {
  createWorkoutPlan,
  deleteWorkoutPlan,
  generateSessionFromPlan,
  getWorkoutPlans,
  type WorkoutPlan,
} from "../api/workout-plan.api";

import PageHeader from "../components/PageHeader";
import TableLoading from "../components/common/TableLoading";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";

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

  const today = new Date().toISOString().slice(0, 10);

  const [name, setName] = useState("Home Dumbbell Hypertrophy");
  const [description, setDescription] = useState("3-day workout plan using dumbbells, rings and pull-up bar");

  const [draftDays, setDraftDays] = useState<PlanDayDraft[]>([
    {
      name: "Push Day",
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

  const plansQuery = useQuery({
    queryKey: ["workout-plans"],
    queryFn: getWorkoutPlans,
  });

  const exercises = exercisesQuery.data ?? [];
  const plans = plansQuery.data ?? [];

  useEffect(() => {
    if (exercises.length > 0) {
      setDraftDays((prev) =>
        prev.map((day) => ({
          ...day,
          exercises: day.exercises.map((exercise) => ({
            ...exercise,
            exerciseId: exercise.exerciseId || exercises[0].id,
          })),
        }))
      );
    }
  }, [exercises]);

  const createMutation = useMutation({
    mutationFn: createWorkoutPlan,
    onSuccess: () => {
      toast.success("Workout plan created");
      queryClient.invalidateQueries({ queryKey: ["workout-plans"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot create workout plan");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteWorkoutPlan,
    onSuccess: () => {
      toast.success("Workout plan deleted");
      queryClient.invalidateQueries({ queryKey: ["workout-plans"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot delete workout plan");
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
      toast.success("Workout session generated");
      queryClient.invalidateQueries({ queryKey: ["workout-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot generate session");
    },
  });

  const addDay = () => {
    setDraftDays((prev) => [
      ...prev,
      {
        name: `Day ${prev.length + 1}`,
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
          exerciseId: exercise.exerciseId,
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
    return <ErrorState title="Cannot load workout plans" message="Please try refreshing the page." />;
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Workout Plans"
        description="Create reusable training plans and generate workout sessions from them."
      />

      <Card>
        <CardHeader>
          <CardTitle>Create Workout Plan</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <Input value={name} onChange={(event) => setName(event.target.value)} placeholder="Plan name" />

            <Input value={description} onChange={(event) => setDescription(event.target.value)} placeholder="Description" />
          </div>

          <div className="space-y-4">
            {draftDays.map((day, dayIndex) => (
              <div key={dayIndex} className="space-y-4 rounded-2xl border bg-slate-50 p-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-semibold">Day {dayIndex + 1}</h3>

                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => removeDay(dayIndex)}
                    disabled={draftDays.length === 1}
                  >
                    Remove Day
                  </Button>
                </div>

                <div className="grid gap-4 md:grid-cols-3">
                  <Input
                    value={day.name}
                    onChange={(event) => updateDay(dayIndex, "name", event.target.value)}
                    placeholder="Day name"
                  />

                  <Input
                    type="number"
                    value={day.dayOrder}
                    onChange={(event) => updateDay(dayIndex, "dayOrder", Number(event.target.value))}
                    placeholder="Day order"
                  />
                </div>

                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium text-muted-foreground">Exercises</p>

                    <Button variant="outline" size="sm" onClick={() => addExerciseToDay(dayIndex)}>
                      Add Exercise
                    </Button>
                  </div>

                  {day.exercises.map((exercise, exerciseIndex) => (
                    <div key={exerciseIndex} className="grid gap-3 rounded-xl border bg-white p-3 md:grid-cols-7">
                      <select
                        className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm md:col-span-2"
                        value={exercise.exerciseId}
                        onChange={(event) =>
                          updateDayExercise(dayIndex, exerciseIndex, "exerciseId", event.target.value)
                        }
                      >
                        {exercises.map((item) => (
                          <option key={item.id} value={item.id}>
                            {item.name}
                          </option>
                        ))}
                      </select>

                      <Input
                        type="number"
                        value={exercise.targetSets}
                        onChange={(event) =>
                          updateDayExercise(dayIndex, exerciseIndex, "targetSets", Number(event.target.value))
                        }
                        placeholder="Sets"
                      />

                      <Input
                        type="number"
                        value={exercise.targetReps}
                        onChange={(event) =>
                          updateDayExercise(dayIndex, exerciseIndex, "targetReps", Number(event.target.value))
                        }
                        placeholder="Reps"
                      />

                      <Input
                        type="number"
                        value={exercise.targetWeight}
                        onChange={(event) =>
                          updateDayExercise(dayIndex, exerciseIndex, "targetWeight", Number(event.target.value))
                        }
                        placeholder="Weight"
                      />

                      <Input
                        type="number"
                        value={exercise.targetRir}
                        onChange={(event) =>
                          updateDayExercise(dayIndex, exerciseIndex, "targetRir", Number(event.target.value))
                        }
                        placeholder="RIR"
                      />

                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => removeExerciseFromDay(dayIndex, exerciseIndex)}
                        disabled={day.exercises.length === 1}
                      >
                        Remove
                      </Button>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>

          <div className="flex gap-3">
            <Button variant="outline" onClick={addDay}>
              Add Day
            </Button>

            <Button onClick={handleCreate} disabled={createMutation.isPending || exercises.length === 0}>
              {createMutation.isPending ? "Creating..." : "Create Plan"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {plans.length === 0 ? (
        <EmptyState title="No workout plans yet" description="Create a reusable workout plan to generate sessions faster." />
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          {plans.map((plan) => (
            <PlanCard
              key={plan.id}
              plan={plan}
              isDeleting={deleteMutation.isPending}
              isGenerating={generateMutation.isPending}
              onDelete={() => {
                if (!window.confirm("Delete this workout plan?")) {
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
            Delete
          </Button>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {plan.days.map((day) => (
          <div key={day.id} className="rounded-xl border p-4">
            <div className="mb-3 flex items-center justify-between gap-3">
              <h3 className="font-semibold">
                Day {day.dayOrder}: {day.name}
              </h3>

              <Button size="sm" onClick={() => onGenerate(day.id, day.name)} disabled={isGenerating}>
                Generate Session
              </Button>
            </div>

            <div className="w-full overflow-x-auto">
              <Table>
                <TableBody>
                  {day.exercises.map((exercise) => (
                    <TableRow key={exercise.id}>
                      <TableCell className="font-medium">{exercise.exerciseName}</TableCell>
                      <TableCell>{exercise.muscleGroup}</TableCell>
                      <TableCell>{exercise.targetSets} sets</TableCell>
                      <TableCell>{exercise.targetReps} reps</TableCell>
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
