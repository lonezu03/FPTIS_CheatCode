import { useEffect, useState } from "react";
import {
  createWorkoutSession,
  deleteWorkoutSession,
  getExercises,
  getWorkoutSessions,
  type Exercise,
  type WorkoutSession,
} from "../api/workout.api";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export default function WorkoutPage() {
  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [sessions, setSessions] = useState<WorkoutSession[]>([]);

  const [exerciseId, setExerciseId] = useState("");
  const [weight, setWeight] = useState(9);
  const [reps, setReps] = useState(10);
  const [rir, setRir] = useState(2);
  const [durationMinutes, setDurationMinutes] = useState(60);
  const [note, setNote] = useState("Workout from frontend");

  const load = async () => {
    const [exerciseData, sessionData] = await Promise.all([getExercises(), getWorkoutSessions()]);

    setExercises(exerciseData);
    setSessions(sessionData);

    if (!exerciseId && exerciseData.length > 0) {
      setExerciseId(exerciseData[0].id);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const handleCreate = async () => {
    try {
      await createWorkoutSession({
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

      toast.success("Workout saved");
      await load();
    } catch (error) {
      const message =
        typeof error === "object" && error && "response" in error
          ? (error as { response?: { data?: { message?: string } } }).response?.data?.message
          : undefined;
      toast.error(message || "Cannot save workout");
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Delete this workout session?")) {
      return;
    }

    try {
      await deleteWorkoutSession(id);
      toast.success("Workout deleted");
      await load();
    } catch (error) {
      const message =
        typeof error === "object" && error && "response" in error
          ? (error as { response?: { data?: { message?: string } } }).response?.data?.message
          : undefined;
      toast.error(message || "Cannot delete workout");
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Workout</h1>
        <p className="text-muted-foreground">Create workout sessions and review training history.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Create Session</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-3">
          <select className="rounded-md border px-3 py-2 md:col-span-3" value={exerciseId} onChange={(event) => setExerciseId(event.target.value)}>
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
            placeholder="Duration minutes"
          />

          <Input value={note} onChange={(event) => setNote(event.target.value)} placeholder="Note" className="md:col-span-2" />

          <Button onClick={handleCreate} className="md:col-span-3">
            Save Workout
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>History</CardTitle>
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
                    <TableCell>{set.weight}kg</TableCell>
                    <TableCell>{set.reps}</TableCell>
                    <TableCell>{set.rir}</TableCell>
                    <TableCell>{session.note}</TableCell>
                    <TableCell>
                      <Button variant="destructive" size="sm" onClick={() => handleDelete(session.id)}>
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
    </div>
  );
}
