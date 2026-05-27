import { useEffect, useState } from "react";
import { createMealLog, deleteMealLog, getFoods, getMealLogs, type Food, type MealLog } from "../api/nutrition.api";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export default function NutritionPage() {
  const [foods, setFoods] = useState<Food[]>([]);
  const [logs, setLogs] = useState<MealLog[]>([]);
  const [keyword, setKeyword] = useState("");
  const [foodId, setFoodId] = useState("");
  const [quantity, setQuantity] = useState(1);
  const [mealType, setMealType] = useState("LUNCH");

  const today = new Date().toISOString().slice(0, 10);

  const loadFoods = async () => {
    const data = await getFoods(keyword);
    setFoods(data);

    if (!foodId && data.length > 0) {
      setFoodId(data[0].id);
    }
  };

  const loadLogs = async () => {
    setLogs(await getMealLogs(today));
  };

  const load = async () => {
    await Promise.all([loadFoods(), loadLogs()]);
  };

  useEffect(() => {
    load();
  }, []);

  const handleSearch = async () => {
    await loadFoods();
  };

  const handleCreate = async () => {
    try {
      await createMealLog({
        mealType,
        logDate: today,
        items: [{ foodId, quantity }],
      });

      toast.success("Meal saved");
      await loadLogs();
    } catch (error) {
      const message =
        typeof error === "object" && error && "response" in error
          ? (error as { response?: { data?: { message?: string } } }).response?.data?.message
          : undefined;
      toast.error(message || "Cannot save meal");
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm("Delete this meal log?")) {
      return;
    }

    try {
      await deleteMealLog(id);
      toast.success("Meal log deleted");
      await loadLogs();
    } catch (error) {
      const message =
        typeof error === "object" && error && "response" in error
          ? (error as { response?: { data?: { message?: string } } }).response?.data?.message
          : undefined;
      toast.error(message || "Cannot delete meal log");
    }
  };

  const totalCalories = logs.reduce((sum, log) => sum + log.totalCalories, 0);
  const totalProtein = logs.reduce((sum, log) => sum + log.totalProtein, 0);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Nutrition</h1>
        <p className="text-muted-foreground">Log meals and track calories, protein, carbs and fat.</p>
      </div>

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

            <select className="w-full rounded-md border px-3 py-2" value={foodId} onChange={(event) => setFoodId(event.target.value)}>
              {foods.map((food) => (
                <option key={food.id} value={food.id}>
                  {food.name} / {food.unit}
                </option>
              ))}
            </select>

            <select
              className="w-full rounded-md border px-3 py-2"
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

            <Button className="w-full" onClick={handleCreate}>
              Save Meal
            </Button>
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
                    <TableCell>
                      <Button variant="destructive" size="sm" onClick={() => handleDelete(log.id)}>
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
