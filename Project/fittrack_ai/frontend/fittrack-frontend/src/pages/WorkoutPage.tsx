import { useEffect, useState } from "react";
import axios from "axios";
import {
  createWorkoutSession,
  deleteWorkoutSession,
  getExercises,
  getWorkoutSessions,
  updateWorkoutSession,
} from "../api/workout.api";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import PageHeader from "../components/PageHeader";
import TableLoading from "../components/common/TableLoading";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";

export default function WorkoutPage() {
  const queryClient = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);

  const [sessionDate, setSessionDate] = useState(today);
  const [exerciseId, setExerciseId] = useState("");
  const [weight, setWeight] = useState(9);
  const [reps, setReps] = useState(10);
  const [rir, setRir] = useState(2);
  const [durationMinutes, setDurationMinutes] = useState(60);
  const [note, setNote] = useState("Workout from frontend");
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

  const sessionsQuery = useQuery({
    queryKey: ["workout-sessions"],
    queryFn: getWorkoutSessions,
  });

  const exercises = exercisesQuery.data ?? [];
  const sessions = sessionsQuery.data ?? [];

  useEffect(() => {
    if (!exerciseId && exercises.length > 0) {
      setExerciseId(exercises[0].id);
    }
  }, [exercises, exerciseId]);

  const createMutation = useMutation({
    mutationFn: createWorkoutSession,
    onSuccess: () => {
      toast.success("Workout saved");
      queryClient.invalidateQueries({ queryKey: ["workout-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot save workout");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteWorkoutSession,
    onSuccess: () => {
      toast.success("Workout deleted");
      queryClient.invalidateQueries({ queryKey: ["workout-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot delete workout");
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
      toast.success("Workout updated");
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
      toast.error(message || "Cannot update workout");
    },
  });

  const handleCreate = () => {
    createMutation.mutate({
      sessionDate,
      note,
      durationMinutes,
      sets: [
        {
          exerciseId,
          setNumber: 1,
          weight,
          reps,
          rir,
        },
      ],
    });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Delete this workout session?")) {
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
    return <ErrorState title="Cannot load workouts" message="Please try refreshing the page." />;
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Workout" description="Log your training sessions and track progressive overload." />

      <Card>
        <CardHeader>
          <CardTitle>Create Workout Session</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-6">
          {exercises.length === 0 ? (
            <div className="md:col-span-6">
              <EmptyState
                title="No exercises found"
                description="Please seed exercises in backend before creating workout sessions."
              />
            </div>
          ) : (
            <>
              <Input type="date" value={sessionDate} onChange={(event) => setSessionDate(event.target.value)} />

              <select
                className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm md:col-span-2"
                value={exerciseId}
                onChange={(event) => setExerciseId(event.target.value)}
              >
                {exercises.map((exercise) => (
                  <option key={exercise.id} value={exercise.id}>
                    {exercise.name}
                  </option>
                ))}
              </select>

              <Input type="number" value={weight} onChange={(event) => setWeight(Number(event.target.value))} placeholder="Weight" />

              <Input type="number" value={reps} onChange={(event) => setReps(Number(event.target.value))} placeholder="Reps" />

              <Input type="number" value={rir} onChange={(event) => setRir(Number(event.target.value))} placeholder="RIR" />

              <Input
                type="number"
                value={durationMinutes}
                onChange={(event) => setDurationMinutes(Number(event.target.value))}
                placeholder="Duration"
              />

              <Input className="md:col-span-5" value={note} onChange={(event) => setNote(event.target.value)} placeholder="Note" />

              <Button onClick={handleCreate} disabled={createMutation.isPending}>
                {createMutation.isPending ? "Saving..." : "Save"}
              </Button>
            </>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Workout History</CardTitle>
        </CardHeader>

        <CardContent>
          {sessions.length === 0 ? (
            <EmptyState
              title="No workout sessions yet"
              description="Create your first workout session to start tracking progress."
            />
          ) : (
            <div className="w-full overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Exercise</TableHead>
                  <TableHead>Weight</TableHead>
                  <TableHead>Reps</TableHead>
                  <TableHead>RIR</TableHead>
                  <TableHead>Note</TableHead>
                  <TableHead>Action</TableHead>
                </TableRow>
              </TableHeader>

              <TableBody>
                {sessions.flatMap((session) =>
                  session.sets.map((set) => (
                    <TableRow key={set.id}>
                      <TableCell>{session.sessionDate}</TableCell>
                      <TableCell>{set.exerciseName}</TableCell>
                      <TableCell>{set.weight} kg</TableCell>
                      <TableCell>{set.reps}</TableCell>
                      <TableCell>{set.rir}</TableCell>
                      <TableCell>{session.note}</TableCell>
                      <TableCell className="space-x-2">
                        <Button variant="outline" size="sm" onClick={() => openEditWorkout(session, set)}>
                          Edit
                        </Button>
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => handleDelete(session.id)}
                          disabled={deleteMutation.isPending}
                        >
                          Delete
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
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
            <DialogTitle>Edit Workout</DialogTitle>
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
                placeholder="Note"
              />

              <Input
                type="number"
                value={editingWorkout.durationMinutes}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, durationMinutes: Number(event.target.value) })}
                placeholder="Duration"
              />

              <Input
                type="number"
                value={editingWorkout.weight}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, weight: Number(event.target.value) })}
                placeholder="Weight"
              />

              <Input
                type="number"
                value={editingWorkout.reps}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, reps: Number(event.target.value) })}
                placeholder="Reps"
              />

              <Input
                type="number"
                value={editingWorkout.rir}
                onChange={(event) => setEditingWorkout({ ...editingWorkout, rir: Number(event.target.value) })}
                placeholder="RIR"
              />

              <Button className="w-full" onClick={() => updateMutation.mutate(editingWorkout)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
