import { useState } from "react";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import PageHeader from "../components/PageHeader";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import TableLoading from "../components/common/TableLoading";

import {
  createExerciseApi,
  deleteExerciseApi,
  getExercisesApi,
  updateExerciseApi,
  type Exercise,
} from "../api/exercise.api";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

type ExerciseDraft = {
  name: string;
  muscleGroup: string;
  equipment: string;
  description: string;
};

const emptyDraft: ExerciseDraft = {
  name: "",
  muscleGroup: "",
  equipment: "",
  description: "",
};

export default function ExercisesPage() {
  const queryClient = useQueryClient();

  const [keyword, setKeyword] = useState("");
  const [searchKeyword, setSearchKeyword] = useState("");

  const [draft, setDraft] = useState<ExerciseDraft>({
    name: "Dumbbell Bench Press",
    muscleGroup: "Chest",
    equipment: "Dumbbell",
    description: "Press dumbbells while lying on bench or floor.",
  });

  const [editingExercise, setEditingExercise] = useState<Exercise | null>(null);

  const exercisesQuery = useQuery({
    queryKey: ["exercises-management", searchKeyword],
    queryFn: () => getExercisesApi(searchKeyword),
  });

  const exercises = exercisesQuery.data ?? [];

  const createMutation = useMutation({
    mutationFn: createExerciseApi,
    onSuccess: () => {
      toast.success("Exercise created");
      setDraft(emptyDraft);
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot create exercise");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: Exercise) =>
      updateExerciseApi(payload.id, {
        name: payload.name,
        muscleGroup: payload.muscleGroup,
        equipment: payload.equipment,
        description: payload.description,
      }),
    onSuccess: () => {
      toast.success("Exercise updated");
      setEditingExercise(null);
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot update exercise");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteExerciseApi,
    onSuccess: () => {
      toast.success("Exercise deleted");
      queryClient.invalidateQueries({ queryKey: ["exercises-management"] });
      queryClient.invalidateQueries({ queryKey: ["exercises"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot delete exercise. It may already be used in workout data.");
    },
  });

  const handleCreate = () => {
    if (!draft.name.trim()) {
      toast.error("Exercise name is required");
      return;
    }

    createMutation.mutate(draft);
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Delete this exercise?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  if (exercisesQuery.isError) {
    return <ErrorState title="Cannot load exercises" message="Please try refreshing the page." />;
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Exercises" description="Create and manage exercises used in workout sessions and plans." />

      <Card>
        <CardHeader>
          <CardTitle>Create Exercise</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-2">
          <Input value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} placeholder="Exercise name" />

          <Input
            value={draft.muscleGroup}
            onChange={(event) => setDraft({ ...draft, muscleGroup: event.target.value })}
            placeholder="Muscle group"
          />

          <Input
            value={draft.equipment}
            onChange={(event) => setDraft({ ...draft, equipment: event.target.value })}
            placeholder="Equipment"
          />

          <Input
            value={draft.description}
            onChange={(event) => setDraft({ ...draft, description: event.target.value })}
            placeholder="Description"
          />

          <Button className="md:col-span-2" onClick={handleCreate} disabled={createMutation.isPending}>
            {createMutation.isPending ? "Creating..." : "Create Exercise"}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Exercise Library</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Input value={keyword} onChange={(event) => setKeyword(event.target.value)} placeholder="Search exercise..." />

            <Button onClick={() => setSearchKeyword(keyword)}>Search</Button>
          </div>

          {exercisesQuery.isLoading ? (
            <TableLoading />
          ) : exercises.length === 0 ? (
            <EmptyState title="No exercises found" description="Create a custom exercise or try another keyword." />
          ) : (
            <div className="w-full overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Muscle</TableHead>
                    <TableHead>Equipment</TableHead>
                    <TableHead>Custom</TableHead>
                    <TableHead>Action</TableHead>
                  </TableRow>
                </TableHeader>

                <TableBody>
                  {exercises.map((exercise) => (
                    <TableRow key={exercise.id}>
                      <TableCell className="font-medium">{exercise.name}</TableCell>
                      <TableCell>{exercise.muscleGroup}</TableCell>
                      <TableCell>{exercise.equipment}</TableCell>
                      <TableCell>{exercise.custom ? "Yes" : "No"}</TableCell>
                      <TableCell className="space-x-2">
                        <Button variant="outline" size="sm" onClick={() => setEditingExercise(exercise)}>
                          Edit
                        </Button>

                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => handleDelete(exercise.id)}
                          disabled={deleteMutation.isPending}
                        >
                          Delete
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog
        open={!!editingExercise}
        onOpenChange={(open) => {
          if (!open) {
            setEditingExercise(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Exercise</DialogTitle>
          </DialogHeader>

          {editingExercise && (
            <div className="space-y-4">
              <Input
                value={editingExercise.name}
                onChange={(event) => setEditingExercise({ ...editingExercise, name: event.target.value })}
                placeholder="Name"
              />

              <Input
                value={editingExercise.muscleGroup}
                onChange={(event) => setEditingExercise({ ...editingExercise, muscleGroup: event.target.value })}
                placeholder="Muscle group"
              />

              <Input
                value={editingExercise.equipment}
                onChange={(event) => setEditingExercise({ ...editingExercise, equipment: event.target.value })}
                placeholder="Equipment"
              />

              <Input
                value={editingExercise.description}
                onChange={(event) => setEditingExercise({ ...editingExercise, description: event.target.value })}
                placeholder="Description"
              />

              <Button className="w-full" onClick={() => updateMutation.mutate(editingExercise)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
