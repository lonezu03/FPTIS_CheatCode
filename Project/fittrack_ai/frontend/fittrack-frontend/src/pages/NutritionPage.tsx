import { useEffect, useState } from "react";
import axios from "axios";
import { createMealLog, deleteMealLog, getFoods, getMealLogs, updateMealLog } from "../api/nutrition.api";
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

export default function NutritionPage() {
  const queryClient = useQueryClient();

  const today = new Date().toISOString().slice(0, 10);

  const [keyword, setKeyword] = useState("");
  const [searchKeyword, setSearchKeyword] = useState("");
  const [foodId, setFoodId] = useState("");
  const [quantity, setQuantity] = useState(1);
  const [mealType, setMealType] = useState("LUNCH");
  const [editingMeal, setEditingMeal] = useState<{
    id: string;
    mealType: string;
    quantity: number;
  } | null>(null);

  const foodsQuery = useQuery({
    queryKey: ["foods", searchKeyword],
    queryFn: () => getFoods(searchKeyword),
  });

  const mealLogsQuery = useQuery({
    queryKey: ["meal-logs", today],
    queryFn: () => getMealLogs(today),
  });

  const foods = foodsQuery.data ?? [];
  const logs = mealLogsQuery.data ?? [];

  useEffect(() => {
    if (!foodId && foods.length > 0) {
      setFoodId(foods[0].id);
    }
  }, [foods, foodId]);

  const createMutation = useMutation({
    mutationFn: createMealLog,
    onSuccess: () => {
      toast.success("Meal saved");
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot save meal");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteMealLog,
    onSuccess: () => {
      toast.success("Meal deleted");
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot delete meal");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: { id: string; mealType: string; quantity: number }) =>
      updateMealLog(payload.id, {
        mealType: payload.mealType,
        quantity: payload.quantity,
      }),
    onSuccess: () => {
      toast.success("Meal updated");
      setEditingMeal(null);
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot update meal");
    },
  });

  const handleSearch = () => {
    setSearchKeyword(keyword);
  };

  const handleCreate = () => {
    createMutation.mutate({
      mealType,
      logDate: today,
      items: [{ foodId, quantity }],
    });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Delete this meal log?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  const totalCalories = logs.reduce((sum, log) => sum + log.totalCalories, 0);
  const totalProtein = logs.reduce((sum, log) => sum + log.totalProtein, 0);

  if (foodsQuery.isLoading || mealLogsQuery.isLoading) {
    return <TableLoading />;
  }

  if (foodsQuery.isError || mealLogsQuery.isError) {
    return <ErrorState title="Cannot load nutrition" message="Please try refreshing the page." />;
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Nutrition" description="Log meals and track calories, protein, carbs and fat." />

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Add Meal</CardTitle>
          </CardHeader>

          <CardContent className="space-y-4">
            <div className="flex gap-2">
              <Input placeholder="Search food..." value={keyword} onChange={(event) => setKeyword(event.target.value)} />
              <Button onClick={handleSearch}>Search</Button>
            </div>

            {foods.length === 0 ? (
              <EmptyState title="No foods found" description="Try another keyword or seed food data in backend." />
            ) : (
              <>
                <select
                  className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  value={foodId}
                  onChange={(event) => setFoodId(event.target.value)}
                >
                  {foods.map((food) => (
                    <option key={food.id} value={food.id}>
                      {food.name} / {food.unit}
                    </option>
                  ))}
                </select>

                <select
                  className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  value={mealType}
                  onChange={(event) => setMealType(event.target.value)}
                >
                  <option value="BREAKFAST">Breakfast</option>
                  <option value="LUNCH">Lunch</option>
                  <option value="DINNER">Dinner</option>
                  <option value="SNACK">Snack</option>
                </select>

                <Input
                  type="number"
                  value={quantity}
                  onChange={(event) => setQuantity(Number(event.target.value))}
                  placeholder="Quantity"
                />

                <Button className="w-full" onClick={handleCreate} disabled={createMutation.isPending}>
                  {createMutation.isPending ? "Saving..." : "Save Meal"}
                </Button>
              </>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Today Summary</CardTitle>
          </CardHeader>

          <CardContent className="grid grid-cols-2 gap-4">
            <div className="rounded-xl bg-slate-100 p-4">
              <p className="text-sm text-muted-foreground">Calories</p>
              <p className="text-3xl font-bold">{totalCalories.toFixed(0)}</p>
            </div>

            <div className="rounded-xl bg-slate-100 p-4">
              <p className="text-sm text-muted-foreground">Protein</p>
              <p className="text-3xl font-bold">{totalProtein.toFixed(1)}g</p>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Meal Logs</CardTitle>
        </CardHeader>

        <CardContent>
          {logs.length === 0 ? (
            <EmptyState title="No meals logged today" description="Add your first meal to track today's nutrition." />
          ) : (
            <div className="w-full overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Meal</TableHead>
                  <TableHead>Food</TableHead>
                  <TableHead>Quantity</TableHead>
                  <TableHead>Calories</TableHead>
                  <TableHead>Protein</TableHead>
                  <TableHead>Action</TableHead>
                </TableRow>
              </TableHeader>

              <TableBody>
                {logs.flatMap((log) =>
                  log.items.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>{log.mealType}</TableCell>
                      <TableCell>{item.foodName}</TableCell>
                      <TableCell>{item.quantity}</TableCell>
                      <TableCell>{item.calories.toFixed(0)}</TableCell>
                      <TableCell>{item.protein.toFixed(1)}g</TableCell>
                      <TableCell className="space-x-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() =>
                            setEditingMeal({
                              id: log.id,
                              mealType: log.mealType,
                              quantity: item.quantity,
                            })
                          }
                        >
                          Edit
                        </Button>
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => handleDelete(log.id)}
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
        open={!!editingMeal}
        onOpenChange={(open) => {
          if (!open) {
            setEditingMeal(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Meal</DialogTitle>
          </DialogHeader>

          {editingMeal && (
            <div className="space-y-4">
              <select
                className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                value={editingMeal.mealType}
                onChange={(event) => setEditingMeal({ ...editingMeal, mealType: event.target.value })}
              >
                <option value="BREAKFAST">Breakfast</option>
                <option value="LUNCH">Lunch</option>
                <option value="DINNER">Dinner</option>
                <option value="SNACK">Snack</option>
              </select>

              <Input
                type="number"
                value={editingMeal.quantity}
                onChange={(event) => setEditingMeal({ ...editingMeal, quantity: Number(event.target.value) })}
                placeholder="Quantity"
              />

              <Button className="w-full" onClick={() => updateMutation.mutate(editingMeal)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
