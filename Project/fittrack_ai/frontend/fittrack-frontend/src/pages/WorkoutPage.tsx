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

export default function WorkoutPage() {
  const queryClient = useQueryClient();

  const [exerciseId, setExerciseId] = useState("");
  const [weight, setWeight] = useState(9);
  const [reps, setReps] = useState(10);
  const [rir, setRir] = useState(2);
  const [durationMinutes, setDurationMinutes] = useState(60);
  const [note, setNote] = useState("Workout from frontend");
  const [editingWorkout, setEditingWorkout] = useState<{
    id: string;
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
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot delete workout");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: {
      id: string;
      note: string;
      durationMinutes: number;
      weight: number;
      reps: number;
      rir: number;
    }) =>
      updateWorkoutSession(payload.id, {
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
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot update workout");
    },
  });

  const handleCreate = () => {
    createMutation.mutate({
      sessionDate: new Date().toISOString().slice(0, 10),
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
    session: { id: string; note: string; durationMinutes: number },
    set: { weight: number; reps: number; rir: number }
  ) => {
    setEditingWorkout({
      id: session.id,
      note: session.note,
      durationMinutes: session.durationMinutes,
      weight: set.weight,
      reps: set.reps,
      rir: set.rir,
    });
  };

  if (exercisesQuery.isLoading || sessionsQuery.isLoading) {
    return <div>Loading workouts...</div>;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Workout</h1>
        <p className="text-muted-foreground">Log your training sessions and track progressive overload.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Create Workout Session</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-6">
          <select className="rounded-md border px-3 py-2 md:col-span-2" value={exerciseId} onChange={(event) => setExerciseId(event.target.value)}>
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
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Workout History</CardTitle>
        </CardHeader>

        <CardContent>
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
