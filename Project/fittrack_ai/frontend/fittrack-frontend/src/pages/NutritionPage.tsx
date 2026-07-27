import { useState } from "react";
import axios from "axios";
import { getTodayDashboard } from "../api/dashboard.api";
import {
  createMealLog,
  deleteMealLog,
  getFoods,
  getMealLogs,
  updateMealLog,
  type MealLog,
} from "../api/nutrition.api";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toLocalDateInput } from "../lib/format";
import { LockKeyhole, Utensils } from "lucide-react";

import PageHeader from "../components/PageHeader";
import MacroProgressCard from "../components/MacroProgressCard";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import TableLoading from "../components/common/TableLoading";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
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

const mealTypeLabels: Record<string, string> = {
  BREAKFAST: "Bữa sáng",
  LUNCH: "Bữa trưa",
  DINNER: "Bữa tối",
  SNACK: "Ăn nhẹ",
};

const isAutomatedMeal = (log: MealLog) => log.readOnly || log.sourceType === "LUNCH_ORDER";

export default function NutritionPage() {
  const queryClient = useQueryClient();
  const today = toLocalDateInput();

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
  const defaultFoodId = foods[0]?.id ?? "";

  const createMutation = useMutation({
    mutationFn: createMealLog,
    onSuccess: () => {
      toast.success("Đã lưu bữa ăn");
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể lưu bữa ăn");
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
      toast.success("Đã cập nhật bữa ăn");
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
      toast.error(message || "Không thể cập nhật bữa ăn");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteMealLog,
    onSuccess: () => {
      toast.success("Đã xóa bữa ăn");
      queryClient.invalidateQueries({ queryKey: ["meal-logs"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-progress"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể xóa bữa ăn");
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
      items: items.map((item) => ({
        ...item,
        foodId: item.foodId || defaultFoodId,
      })),
    });
  };

  const handleDelete = (log: MealLog) => {
    if (isAutomatedMeal(log)) {
      toast.info("Bữa ăn này được đồng bộ từ đơn cơm. Hãy hủy hoặc chỉnh đơn tại trang Đặt cơm.");
      return;
    }

    if (!window.confirm("Bạn có chắc muốn xóa bữa ăn này?")) {
      return;
    }

    deleteMutation.mutate(log.id);
  };

  const openEditMeal = (log: MealLog) => {
    if (isAutomatedMeal(log)) {
      toast.info("Bữa ăn này được đồng bộ từ đơn cơm và không thể sửa tại đây.");
      return;
    }

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
    return <ErrorState title="Không thể tải dữ liệu dinh dưỡng" message="Vui lòng tải lại trang và thử lại." />;
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader
        title="Dinh dưỡng"
        description="Theo dõi năng lượng, dưỡng chất và các bữa ăn tự động từ đơn cơm."
      />

      {dashboard && (
        <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
          <MacroProgressCard
            title="Năng lượng"
            current={dashboard.totalCalories}
            target={dashboard.targetCalories}
            unit="kcal"
            percent={dashboard.caloriesProgressPercent}
          />

          <MacroProgressCard
            title="Chất đạm"
            current={dashboard.totalProtein}
            target={dashboard.targetProtein}
            unit="g"
            percent={dashboard.proteinProgressPercent}
          />

          <MacroProgressCard
            title="Tinh bột"
            current={dashboard.totalCarbs}
            target={dashboard.targetCarbs}
            unit="g"
            percent={dashboard.carbsProgressPercent}
          />

          <MacroProgressCard
            title="Chất béo"
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
            <CardTitle>Thêm bữa ăn thủ công</CardTitle>
          </CardHeader>

          <CardContent className="space-y-3 sm:space-y-4">
            <div className="flex gap-2">
              <Input
                placeholder="Tìm món ăn..."
                value={keyword}
                onChange={(event) => setKeyword(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") {
                    setSearchKeyword(keyword);
                  }
                }}
              />

              <Button onClick={() => setSearchKeyword(keyword)}>Tìm</Button>
            </div>

            <select
              className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              value={mealType}
              onChange={(event) => setMealType(event.target.value)}
            >
              <option value="BREAKFAST">Bữa sáng</option>
              <option value="LUNCH">Bữa trưa</option>
              <option value="DINNER">Bữa tối</option>
              <option value="SNACK">Ăn nhẹ</option>
            </select>

            <Input type="date" value={logDate} onChange={(event) => setLogDate(event.target.value)} />

            {foods.length === 0 ? (
              <EmptyState
                title="Không tìm thấy món ăn"
                description="Hãy thử từ khóa khác hoặc thêm dữ liệu món ăn trước."
              />
            ) : (
              <>
                <div className="space-y-3">
                  {items.map((item, index) => (
                    <div key={index} className="grid gap-3 rounded-xl border bg-slate-50 p-3 md:grid-cols-5">
                      <select
                        className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm md:col-span-3"
                        value={item.foodId || defaultFoodId}
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
                        min="0.1"
                        step="0.1"
                        value={item.quantity}
                        onChange={(event) => updateItem(index, "quantity", Number(event.target.value))}
                        placeholder="Số lượng"
                      />

                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => removeItem(index)}
                        disabled={items.length === 1}
                      >
                        Xóa
                      </Button>
                    </div>
                  ))}
                </div>

                <div className="flex gap-3">
                  <Button variant="outline" onClick={addItem}>
                    Thêm món
                  </Button>

                  <Button onClick={handleCreate} disabled={createMutation.isPending || foods.length === 0}>
                    {createMutation.isPending ? "Đang lưu..." : "Lưu bữa ăn"}
                  </Button>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Tổng hợp ngày {logDate}</CardTitle>
          </CardHeader>

          <CardContent className="space-y-2 sm:space-y-3">
            <MacroCard label="Năng lượng" value={`${totalCalories.toFixed(0)} kcal`} />
            <MacroCard label="Chất đạm" value={`${totalProtein.toFixed(1)}g`} />
            <MacroCard label="Tinh bột" value={`${totalCarbs.toFixed(1)}g`} />
            <MacroCard label="Chất béo" value={`${totalFat.toFixed(1)}g`} />
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="gap-2">
          <CardTitle>Nhật ký bữa ăn</CardTitle>
          <p className="text-sm text-muted-foreground">
            Bữa trưa từ đơn cơm được thêm tự động và chỉ có thể thay đổi tại trang Đặt cơm.
          </p>
        </CardHeader>

        <CardContent>
          {logs.length === 0 ? (
            <EmptyState
              title="Chưa có bữa ăn trong ngày"
              description="Thêm bữa ăn đầu tiên hoặc đặt cơm để bắt đầu theo dõi dinh dưỡng."
            />
          ) : (
            <div className="w-full overflow-x-auto">
              <Table className="min-w-[860px]">
                <TableHeader>
                  <TableRow>
                    <TableHead>Bữa ăn</TableHead>
                    <TableHead>Món ăn</TableHead>
                    <TableHead>Năng lượng</TableHead>
                    <TableHead>Chất đạm</TableHead>
                    <TableHead>Tinh bột</TableHead>
                    <TableHead>Chất béo</TableHead>
                    <TableHead className="text-right">Thao tác</TableHead>
                  </TableRow>
                </TableHeader>

                <TableBody>
                  {logs.map((log) => {
                    const automated = isAutomatedMeal(log);

                    return (
                      <TableRow key={log.id}>
                        <TableCell>
                          <div className="flex min-w-32 flex-col items-start gap-2">
                            <span className="font-medium">{mealTypeLabels[log.mealType] ?? log.mealType}</span>
                            {automated ? (
                              <Badge className="bg-emerald-100 text-emerald-800 hover:bg-emerald-100">
                                <Utensils />
                                Từ đơn cơm
                              </Badge>
                            ) : (
                              <Badge variant="outline">Nhập thủ công</Badge>
                            )}
                          </div>
                        </TableCell>

                        <TableCell>
                          <div className="space-y-1">
                            {log.items.map((item) => (
                              <p key={item.id} className="text-sm">
                                {item.foodName} × {item.quantity}
                              </p>
                            ))}
                          </div>
                        </TableCell>

                        <TableCell>{log.totalCalories.toFixed(0)} kcal</TableCell>
                        <TableCell>{log.totalProtein.toFixed(1)}g</TableCell>
                        <TableCell>{log.totalCarbs.toFixed(1)}g</TableCell>
                        <TableCell>{log.totalFat.toFixed(1)}g</TableCell>

                        <TableCell>
                          {automated ? (
                            <div className="flex items-center justify-end gap-1.5 text-xs text-muted-foreground">
                              <LockKeyhole className="size-3.5" />
                              Đồng bộ tự động
                            </div>
                          ) : (
                            <div className="flex justify-end gap-2">
                              <Button variant="outline" size="sm" onClick={() => openEditMeal(log)}>
                                Sửa
                              </Button>

                              <Button variant="destructive" size="sm" onClick={() => handleDelete(log)}>
                                Xóa
                              </Button>
                            </div>
                          )}
                        </TableCell>
                      </TableRow>
                    );
                  })}
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
            <DialogTitle>Chỉnh sửa bữa ăn</DialogTitle>
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
                <option value="BREAKFAST">Bữa sáng</option>
                <option value="LUNCH">Bữa trưa</option>
                <option value="DINNER">Bữa tối</option>
                <option value="SNACK">Ăn nhẹ</option>
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
                    min="0.1"
                    step="0.1"
                    value={item.quantity}
                    onChange={(event) => updateEditingItem(index, "quantity", Number(event.target.value))}
                  />

                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => removeEditingItem(index)}
                    disabled={editingMeal.items.length === 1}
                  >
                    Xóa
                  </Button>
                </div>
              ))}

              <Button variant="outline" onClick={addEditingItem}>
                Thêm món
              </Button>

              <Button className="w-full" onClick={() => updateMutation.mutate(editingMeal)} disabled={updateMutation.isPending}>
                {updateMutation.isPending ? "Đang lưu..." : "Lưu thay đổi"}
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
