import { useEffect, useState } from "react";
import axios from "axios";
import { getTodayDashboard } from "../api/dashboard.api";
import { createMealLog, deleteMealLog, getFoods, getMealLogs, updateMealLog } from "../api/nutrition.api";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import PageHeader from "../components/PageHeader";
import MacroProgressCard from "../components/MacroProgressCard";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import TableLoading from "../components/common/TableLoading";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

type MealItemDraft = {
  foodId: string;
  quantity: number;
};

type EditingMealDraft = {
  id: string;
  mealType: string;
  logDate: string;
  items: MealItemDraft[];
};

export default function NutritionPage() {
  const queryClient = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);

  const [logDate, setLogDate] = useState(today);
  const [keyword, setKeyword] = useState("");
  const [searchKeyword, setSearchKeyword] = useState("");
  const [mealType, setMealType] = useState("LUNCH");

  const [items, setItems] = useState<MealItemDraft[]>([
    {
      foodId: "",
      quantity: 1,
    },
  ]);

  const [editingMeal, setEditingMeal] = useState<EditingMealDraft | null>(null);

  const foodsQuery = useQuery({
    queryKey: ["foods", searchKeyword],
    queryFn: () => getFoods(searchKeyword),
  });

  const mealLogsQuery = useQuery({
    queryKey: ["meal-logs", logDate],
    queryFn: () => getMealLogs(logDate),
  });

  const dashboardQuery = useQuery({
    queryKey: ["dashboard-today"],
    queryFn: getTodayDashboard,
  });

  const foods = foodsQuery.data ?? [];
  const logs = mealLogsQuery.data ?? [];
  const dashboard = dashboardQuery.data;

  useEffect(() => {
    if (foods.length > 0) {
      setItems((prev) =>
        prev.map((item) => ({
          ...item,
          foodId: item.foodId || foods[0].id,
        }))
      );
    }
  }, [foods]);

  const createMutation = useMutation({
    mutationFn: createMealLog,
    onSuccess: () => {
      toast.success("Meal saved");
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot save meal");
    },
  });

  const updateMutation = useMutation({
    mutationFn: (payload: EditingMealDraft) =>
      updateMealLog(payload.id, {
        mealType: payload.mealType,
        logDate: payload.logDate,
        items: payload.items,
      }),
    onSuccess: () => {
      toast.success("Meal updated");
      setEditingMeal(null);
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot update meal");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteMealLog,
    onSuccess: () => {
      toast.success("Meal deleted");
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot delete meal");
    },
  });

  const addItem = () => {
    setItems((prev) => [
      ...prev,
      {
        foodId: foods[0]?.id ?? "",
        quantity: 1,
      },
    ]);
  };

  const removeItem = (index: number) => {
    setItems((prev) => prev.filter((_, itemIndex) => itemIndex !== index));
  };

  const updateItem = (index: number, field: keyof MealItemDraft, value: string | number) => {
    setItems((prev) =>
      prev.map((item, itemIndex) =>
        itemIndex === index
          ? {
              ...item,
              [field]: value,
            }
          : item
      )
    );
  };

  const handleCreate = () => {
    createMutation.mutate({
      mealType,
      logDate,
      items,
    });
  };

  const handleDelete = (id: string) => {
    if (!window.confirm("Delete this meal log?")) {
      return;
    }

    deleteMutation.mutate(id);
  };

  const openEditMeal = (log: {
    id: string;
    mealType: string;
    logDate: string;
    items: {
      foodId: string;
      quantity: number;
    }[];
  }) => {
    setEditingMeal({
      id: log.id,
      mealType: log.mealType,
      logDate: log.logDate,
      items: log.items.map((item) => ({
        foodId: item.foodId,
        quantity: item.quantity,
      })),
    });
  };

  const addEditingItem = () => {
    if (!editingMeal) {
      return;
    }

    setEditingMeal({
      ...editingMeal,
      items: [
        ...editingMeal.items,
        {
          foodId: foods[0]?.id ?? "",
          quantity: 1,
        },
      ],
    });
  };

  const removeEditingItem = (index: number) => {
    if (!editingMeal) {
      return;
    }

    setEditingMeal({
      ...editingMeal,
      items: editingMeal.items.filter((_, itemIndex) => itemIndex !== index),
    });
  };

  const updateEditingItem = (index: number, field: keyof MealItemDraft, value: string | number) => {
    if (!editingMeal) {
      return;
    }

    setEditingMeal({
      ...editingMeal,
      items: editingMeal.items.map((item, itemIndex) =>
        itemIndex === index
          ? {
              ...item,
              [field]: value,
            }
          : item
      ),
    });
  };

  const totalCalories = logs.reduce((sum, log) => sum + log.totalCalories, 0);
  const totalProtein = logs.reduce((sum, log) => sum + log.totalProtein, 0);
  const totalCarbs = logs.reduce((sum, log) => sum + log.totalCarbs, 0);
  const totalFat = logs.reduce((sum, log) => sum + log.totalFat, 0);

  if (foodsQuery.isLoading || mealLogsQuery.isLoading || dashboardQuery.isLoading) {
    return <TableLoading />;
  }

  if (foodsQuery.isError || mealLogsQuery.isError || dashboardQuery.isError) {
    return <ErrorState title="Cannot load nutrition" message="Please try refreshing the page." />;
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Nutrition" description="Log meals with multiple foods and track daily macros." />

      {dashboard && (
        <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
          <MacroProgressCard
            title="Calories"
            current={dashboard.totalCalories}
            target={dashboard.targetCalories}
            unit="kcal"
            percent={dashboard.caloriesProgressPercent}
          />

          <MacroProgressCard
            title="Protein"
            current={dashboard.totalProtein}
            target={dashboard.targetProtein}
            unit="g"
            percent={dashboard.proteinProgressPercent}
          />

          <MacroProgressCard
            title="Carbs"
            current={dashboard.totalCarbs}
            target={dashboard.targetCarbs}
            unit="g"
            percent={dashboard.carbsProgressPercent}
          />

          <MacroProgressCard
            title="Fat"
            current={dashboard.totalFat}
            target={dashboard.targetFat}
            unit="g"
            percent={dashboard.fatProgressPercent}
          />
        </div>
      )}

      <div className="grid gap-4 md:gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Add Meal</CardTitle>
          </CardHeader>

          <CardContent className="space-y-3 sm:space-y-4">
            <div className="flex gap-2">
              <Input placeholder="Search food..." value={keyword} onChange={(event) => setKeyword(event.target.value)} />

              <Button onClick={() => setSearchKeyword(keyword)}>Search</Button>
            </div>

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

            <Input type="date" value={logDate} onChange={(event) => setLogDate(event.target.value)} />

            {foods.length === 0 ? (
              <EmptyState title="No foods found" description="Try another keyword or create food data in Foods." />
            ) : (
              <>
                <div className="space-y-3">
                  {items.map((item, index) => (
                    <div key={index} className="grid gap-3 rounded-xl border bg-slate-50 p-3 md:grid-cols-5">
                      <select
                        className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm md:col-span-3"
                        value={item.foodId}
                        onChange={(event) => updateItem(index, "foodId", event.target.value)}
                      >
                        {foods.map((food) => (
                          <option key={food.id} value={food.id}>
                            {food.name} / {food.unit}
                          </option>
                        ))}
                      </select>

                      <Input
                        type="number"
                        value={item.quantity}
                        onChange={(event) => updateItem(index, "quantity", Number(event.target.value))}
                        placeholder="Quantity"
                      />

                      <Button variant="destructive" size="sm" onClick={() => removeItem(index)} disabled={items.length === 1}>
                        Remove
                      </Button>
                    </div>
                  ))}
                </div>

                <div className="flex gap-3">
                  <Button variant="outline" onClick={addItem}>
                    Add Food
                  </Button>

                  <Button onClick={handleCreate} disabled={createMutation.isPending || foods.length === 0}>
                    {createMutation.isPending ? "Saving..." : "Save Meal"}
                  </Button>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Summary for {logDate}</CardTitle>
          </CardHeader>

          <CardContent className="space-y-2 sm:space-y-3">
            <MacroCard label="Calories" value={totalCalories.toFixed(0)} />
            <MacroCard label="Protein" value={`${totalProtein.toFixed(1)}g`} />
            <MacroCard label="Carbs" value={`${totalCarbs.toFixed(1)}g`} />
            <MacroCard label="Fat" value={`${totalFat.toFixed(1)}g`} />
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
                    <TableHead>Foods</TableHead>
                    <TableHead>Calories</TableHead>
                    <TableHead>Protein</TableHead>
                    <TableHead>Carbs</TableHead>
                    <TableHead>Fat</TableHead>
                    <TableHead>Action</TableHead>
                  </TableRow>
                </TableHeader>

                <TableBody>
                  {logs.map((log) => (
                    <TableRow key={log.id}>
                      <TableCell>{log.mealType}</TableCell>

                      <TableCell>
                        <div className="space-y-1">
                          {log.items.map((item) => (
                            <p key={item.id} className="text-sm">
                              {item.foodName} x {item.quantity}
                            </p>
                          ))}
                        </div>
                      </TableCell>

                      <TableCell>{log.totalCalories.toFixed(0)}</TableCell>
                      <TableCell>{log.totalProtein.toFixed(1)}g</TableCell>
                      <TableCell>{log.totalCarbs.toFixed(1)}g</TableCell>
                      <TableCell>{log.totalFat.toFixed(1)}g</TableCell>

                      <TableCell className="space-x-2">
                        <Button variant="outline" size="sm" onClick={() => openEditMeal(log)}>
                          Edit
                        </Button>

                        <Button variant="destructive" size="sm" onClick={() => handleDelete(log.id)}>
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
            <div className="space-y-3 sm:space-y-4">
              <Input
                type="date"
                value={editingMeal.logDate}
                onChange={(event) => setEditingMeal({ ...editingMeal, logDate: event.target.value })}
              />

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

              {editingMeal.items.map((item, index) => (
                <div key={index} className="grid gap-3 rounded-xl border bg-slate-50 p-3 md:grid-cols-5">
                  <select
                    className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm md:col-span-3"
                    value={item.foodId}
                    onChange={(event) => updateEditingItem(index, "foodId", event.target.value)}
                  >
                    {foods.map((food) => (
                      <option key={food.id} value={food.id}>
                        {food.name} / {food.unit}
                      </option>
                    ))}
                  </select>

                  <Input
                    type="number"
                    value={item.quantity}
                    onChange={(event) => updateEditingItem(index, "quantity", Number(event.target.value))}
                  />

                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => removeEditingItem(index)}
                    disabled={editingMeal.items.length === 1}
                  >
                    Remove
                  </Button>
                </div>
              ))}

              <Button variant="outline" onClick={addEditingItem}>
                Add Food
              </Button>

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

function MacroCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl bg-slate-100 p-3 sm:p-4">
      <p className="text-xs text-muted-foreground sm:text-sm">{label}</p>
      <p className="text-xl font-bold md:text-2xl">{value}</p>
    </div>
  );
}
