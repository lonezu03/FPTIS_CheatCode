import { useState } from "react";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import PageHeader from "../components/PageHeader";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import TableLoading from "../components/common/TableLoading";

import {
  archiveFoodApi,
  createFoodApi,
  getFoodsManagementApi,
  restoreFoodApi,
  updateFoodApi,
  type Food,
} from "../api/food.api";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

type FoodDraft = {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  unit: string;
};

const emptyDraft: FoodDraft = {
  name: "",
  calories: 0,
  protein: 0,
  carbs: 0,
  fat: 0,
  unit: "100g",
};

export default function FoodsPage() {
  const queryClient = useQueryClient();

  const [keyword, setKeyword] = useState("");
  const [searchKeyword, setSearchKeyword] = useState("");
  const [includeInactive, setIncludeInactive] = useState(true);

  const [draft, setDraft] = useState<FoodDraft>({
    name: "Greek Yogurt",
    calories: 59,
    protein: 10,
    carbs: 3.6,
    fat: 0.4,
    unit: "100g",
  });

  const [editingFood, setEditingFood] = useState<Food | null>(null);

  const foodsQuery = useQuery({
    queryKey: ["foods-management", searchKeyword, includeInactive],
    queryFn: () => getFoodsManagementApi(searchKeyword, includeInactive),
  });

  const foods = foodsQuery.data ?? [];

  const createMutation = useMutation({
    mutationFn: createFoodApi,
    onSuccess: () => {
      toast.success("Food created");
      setDraft(emptyDraft);
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot create food");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: Food) =>
      updateFoodApi(payload.id, {
        name: payload.name,
        calories: payload.calories,
        protein: payload.protein,
        carbs: payload.carbs,
        fat: payload.fat,
        unit: payload.unit,
      }),
    onSuccess: () => {
      toast.success("Food updated");
      setEditingFood(null);
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot update food");
    },
  });

  const archiveMutation = useMutation({
    mutationFn: archiveFoodApi,
    onSuccess: () => {
      toast.success("Food archived");
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot archive food");
    },
  });

  const restoreMutation = useMutation({
    mutationFn: restoreFoodApi,
    onSuccess: () => {
      toast.success("Food restored");
      queryClient.invalidateQueries({ queryKey: ["foods-management"] });
      queryClient.invalidateQueries({ queryKey: ["foods"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot restore food");
    },
  });

  const handleCreate = () => {
    if (!draft.name.trim()) {
      toast.error("Food name is required");
      return;
    }

    createMutation.mutate(draft);
  };

  if (foodsQuery.isError) {
    return <ErrorState title="Cannot load foods" message="Please try refreshing the page." />;
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Foods" description="Create and manage food items used for meal logging." />

      <Card>
        <CardHeader>
          <CardTitle>Create Food</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-3">
          <Input value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} placeholder="Food name" />

          <Input value={draft.unit} onChange={(event) => setDraft({ ...draft, unit: event.target.value })} placeholder="Unit, e.g. 100g" />

          <Input
            type="number"
            value={draft.calories}
            onChange={(event) => setDraft({ ...draft, calories: Number(event.target.value) })}
            placeholder="Calories"
          />

          <Input
            type="number"
            value={draft.protein}
            onChange={(event) => setDraft({ ...draft, protein: Number(event.target.value) })}
            placeholder="Protein"
          />

          <Input
            type="number"
            value={draft.carbs}
            onChange={(event) => setDraft({ ...draft, carbs: Number(event.target.value) })}
            placeholder="Carbs"
          />

          <Input
            type="number"
            value={draft.fat}
            onChange={(event) => setDraft({ ...draft, fat: Number(event.target.value) })}
            placeholder="Fat"
          />

          <Button className="md:col-span-3" onClick={handleCreate} disabled={createMutation.isPending}>
            {createMutation.isPending ? "Creating..." : "Create Food"}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Food Library</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          <div className="flex flex-col gap-3 md:flex-row md:items-center">
            <div className="flex flex-1 gap-2">
              <Input value={keyword} onChange={(event) => setKeyword(event.target.value)} placeholder="Search food..." />

              <Button onClick={() => setSearchKeyword(keyword)}>Search</Button>
            </div>

            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={includeInactive}
                onChange={(event) => setIncludeInactive(event.target.checked)}
              />
              Show archived
            </label>
          </div>

          {foodsQuery.isLoading ? (
            <TableLoading />
          ) : foods.length === 0 ? (
            <EmptyState title="No foods found" description="Create a food item or try another keyword." />
          ) : (
            <div className="w-full overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Unit</TableHead>
                    <TableHead>Calories</TableHead>
                    <TableHead>Protein</TableHead>
                    <TableHead>Carbs</TableHead>
                    <TableHead>Fat</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Action</TableHead>
                  </TableRow>
                </TableHeader>

                <TableBody>
                  {foods.map((food) => (
                    <TableRow key={food.id} className={!food.active ? "opacity-50" : ""}>
                      <TableCell className="font-medium">{food.name}</TableCell>
                      <TableCell>{food.unit}</TableCell>
                      <TableCell>{food.calories}</TableCell>
                      <TableCell>{food.protein}g</TableCell>
                      <TableCell>{food.carbs}g</TableCell>
                      <TableCell>{food.fat}g</TableCell>

                      <TableCell>
                        {food.active ? (
                          <span className="rounded-full bg-green-100 px-2 py-1 text-xs text-green-700">Active</span>
                        ) : (
                          <span className="rounded-full bg-slate-100 px-2 py-1 text-xs text-slate-600">Archived</span>
                        )}
                      </TableCell>

                      <TableCell className="space-x-2">
                        <Button variant="outline" size="sm" onClick={() => setEditingFood(food)} disabled={!food.active}>
                          Edit
                        </Button>

                        {food.active ? (
                          <Button
                            variant="destructive"
                            size="sm"
                            onClick={() => archiveMutation.mutate(food.id)}
                            disabled={archiveMutation.isPending}
                          >
                            Archive
                          </Button>
                        ) : (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => restoreMutation.mutate(food.id)}
                            disabled={restoreMutation.isPending}
                          >
                            Restore
                          </Button>
                        )}
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
        open={!!editingFood}
        onOpenChange={(open) => {
          if (!open) {
            setEditingFood(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Food</DialogTitle>
          </DialogHeader>

          {editingFood && (
            <div className="space-y-4">
              <Input value={editingFood.name} onChange={(event) => setEditingFood({ ...editingFood, name: event.target.value })} placeholder="Name" />

              <Input value={editingFood.unit} onChange={(event) => setEditingFood({ ...editingFood, unit: event.target.value })} placeholder="Unit" />

              <Input
                type="number"
                value={editingFood.calories}
                onChange={(event) => setEditingFood({ ...editingFood, calories: Number(event.target.value) })}
                placeholder="Calories"
              />

              <Input
                type="number"
                value={editingFood.protein}
                onChange={(event) => setEditingFood({ ...editingFood, protein: Number(event.target.value) })}
                placeholder="Protein"
              />

              <Input
                type="number"
                value={editingFood.carbs}
                onChange={(event) => setEditingFood({ ...editingFood, carbs: Number(event.target.value) })}
                placeholder="Carbs"
              />

              <Input
                type="number"
                value={editingFood.fat}
                onChange={(event) => setEditingFood({ ...editingFood, fat: Number(event.target.value) })}
                placeholder="Fat"
              />

              <Button className="w-full" onClick={() => updateMutation.mutate(editingFood)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
