import { useMemo, useState } from "react";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  addWaterLog,
  createMealLog,
  deleteMealLog,
  getFoods,
  getNutritionDiary,
  updateMealLog,
  updateNutritionDayStatus,
  type Food,
  type MealLog,
  type NutritionDayStatus,
  type ServingUnit,
} from "../api/nutrition.api";
import { toLocalDateInput } from "../lib/format";

import PageHeader from "../components/PageHeader";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import PageLoading from "../components/common/PageLoading";
import FormField from "../components/common/FormField";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Check, ChevronLeft, ChevronRight, Droplets, LockKeyhole, Plus, Trash2, Utensils } from "lucide-react";

type MealDraftItem = {
  foodId: string;
  amount: number;
  unit: ServingUnit;
};

const mealTypes = ["BREAKFAST", "LUNCH", "DINNER", "SNACK"] as const;
const mealLabels: Record<string, string> = {
  BREAKFAST: "Bữa sáng",
  LUNCH: "Bữa trưa",
  DINNER: "Bữa tối",
  SNACK: "Ăn phụ",
};
const statusMeta: Record<NutritionDayStatus, { label: string; className: string; hint: string }> = {
  COMPLETE: { label: "Đã ghi đầy đủ", className: "bg-emerald-100 text-emerald-800", hint: "Ngày này được dùng cho báo cáo và khuyến nghị." },
  PARTIAL: { label: "Ghi chưa đầy đủ", className: "bg-amber-100 text-amber-800", hint: "Ngày này bị loại khỏi đánh giá lượng ăn." },
  UNLOGGED: { label: "Chưa ghi", className: "bg-slate-100 text-slate-700", hint: "Chưa có dữ liệu dinh dưỡng trong ngày." },
  FASTING: { label: "Ngày nhịn ăn", className: "bg-blue-100 text-blue-800", hint: "Ngày nhịn ăn có chủ đích được tính là đã xác nhận." },
};

export default function NutritionPage() {
  const queryClient = useQueryClient();
  const [date, setDate] = useState(toLocalDateInput());
  const [editor, setEditor] = useState<{ mealType: string; log?: MealLog } | null>(null);
  const [waterAmount, setWaterAmount] = useState(350);

  const diaryQuery = useQuery({
    queryKey: ["nutrition-diary", date],
    queryFn: () => getNutritionDiary(date),
  });
  const foodsQuery = useQuery({ queryKey: ["foods", "diary"], queryFn: () => getFoods() });

  const refresh = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ["nutrition-diary"] }),
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] }),
      queryClient.invalidateQueries({ queryKey: ["health-summary"] }),
      queryClient.invalidateQueries({ queryKey: ["weekly-report"] }),
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] }),
      queryClient.invalidateQueries({ queryKey: ["achievements"] }),
    ]);
  };

  const statusMutation = useMutation({
    mutationFn: (status: NutritionDayStatus) => updateNutritionDayStatus(date, status),
    onSuccess: refresh,
    onError: showMutationError("Không thể cập nhật trạng thái ngày"),
  });
  const waterMutation = useMutation({
    mutationFn: (amount: number) => addWaterLog(amount, date),
    onSuccess: async () => {
      toast.success("Đã ghi lượng nước");
      await refresh();
    },
    onError: showMutationError("Không thể ghi lượng nước"),
  });
  const deleteMutation = useMutation({
    mutationFn: deleteMealLog,
    onSuccess: async () => {
      toast.success("Đã xóa bữa ăn");
      await refresh();
    },
    onError: showMutationError("Không thể xóa bữa ăn"),
  });

  if (diaryQuery.isLoading || foodsQuery.isLoading) return <PageLoading />;
  if (diaryQuery.isError || foodsQuery.isError || !diaryQuery.data) {
    return <ErrorState title="Không thể tải nhật ký ăn uống" message="Vui lòng tải lại trang và thử lại." />;
  }

  const diary = diaryQuery.data;
  const status = statusMeta[diary.status];

  return (
    <div className="space-y-5">
      <PageHeader title="Nhật ký ăn uống" description="Ghi theo từng bữa và xác nhận chất lượng dữ liệu trước khi FitTrack đưa ra đánh giá." />

      <Card>
        <CardContent className="flex flex-col gap-4 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center justify-center gap-2">
            <Button variant="outline" size="icon" aria-label="Ngày trước" onClick={() => setDate(shiftDate(date, -1))}><ChevronLeft /></Button>
            <Input className="w-40" type="date" value={date} onChange={(event) => setDate(event.target.value)} />
            <Button variant="outline" size="icon" aria-label="Ngày sau" onClick={() => setDate(shiftDate(date, 1))}><ChevronRight /></Button>
          </div>
          <div className="text-center sm:text-right">
            <Badge className={status.className}>{status.label}</Badge>
            <p className="mt-1 text-xs text-muted-foreground">{status.hint}</p>
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <DiaryMacro title="Năng lượng" consumed={diary.consumed.calories} target={diary.targets.calories} remaining={diary.remaining.calories} unit="kcal" />
        <DiaryMacro title="Chất đạm" consumed={diary.consumed.protein} target={diary.targets.protein} remaining={diary.remaining.protein} unit="g" />
        <DiaryMacro title="Tinh bột" consumed={diary.consumed.carbs} target={diary.targets.carbs} remaining={diary.remaining.carbs} unit="g" />
        <DiaryMacro title="Chất béo" consumed={diary.consumed.fat} target={diary.targets.fat} remaining={diary.remaining.fat} unit="g" neutralOverage />
      </div>

      <Card className="border-sky-200 bg-sky-50/40">
        <CardContent className="grid gap-4 p-5 lg:grid-cols-[1fr_auto] lg:items-center">
          <div>
            <div className="flex items-center gap-2 font-semibold text-sky-950"><Droplets className="size-5" /> Nước hôm nay</div>
            <p className="mt-2 text-2xl font-black">{diary.waterMl} / {diary.waterTargetMl} ml</p>
            <div className="mt-2 h-2 overflow-hidden rounded-full bg-sky-100"><div className="h-full bg-sky-500" style={{ width: `${Math.min(100, diary.waterMl * 100 / Math.max(1, diary.waterTargetMl))}%` }} /></div>
          </div>
          <div className="flex flex-wrap gap-2">
            {[250, 350, 500].map((amount) => <Button key={amount} variant="outline" onClick={() => waterMutation.mutate(amount)}>+{amount}ml</Button>)}
            <Input className="w-28" type="number" min={1} max={10000} value={waterAmount} onChange={(event) => setWaterAmount(Number(event.target.value))} />
            <Button onClick={() => waterMutation.mutate(waterAmount)}>Ghi nước</Button>
          </div>
        </CardContent>
      </Card>

      <div className="grid gap-4 xl:grid-cols-2">
        {mealTypes.map((mealType) => (
          <MealSection
            key={mealType}
            mealType={mealType}
            logs={diary.meals.filter((meal) => meal.mealType === mealType)}
            onAdd={() => setEditor({ mealType })}
            onEdit={(log) => setEditor({ mealType, log })}
            onDelete={(log) => {
              if (window.confirm("Bạn có chắc muốn xóa bữa ăn này?")) deleteMutation.mutate(log.id);
            }}
          />
        ))}
      </div>

      <Card>
        <CardHeader><CardTitle>Xác nhận chất lượng dữ liệu ngày</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          <p className="text-sm text-muted-foreground">Chỉ chọn “Đã ghi đầy đủ” sau khi bạn đã ghi toàn bộ đồ ăn, thức uống có năng lượng trong ngày.</p>
          <div className="flex flex-wrap gap-2">
            <Button onClick={() => statusMutation.mutate("COMPLETE")} disabled={diary.meals.length === 0 || statusMutation.isPending}>Đã ghi đầy đủ</Button>
            <Button variant="outline" onClick={() => statusMutation.mutate("PARTIAL")} disabled={statusMutation.isPending}>Ghi chưa đầy đủ</Button>
            {diary.meals.length === 0 && <Button variant="outline" onClick={() => statusMutation.mutate("FASTING")} disabled={statusMutation.isPending}>Ngày nhịn ăn</Button>}
          </div>
        </CardContent>
      </Card>

      {editor && (
        <MealEditor
          key={`${editor.log?.id ?? editor.mealType}:${date}`}
          open
          mealType={editor.mealType}
          date={date}
          log={editor.log}
          foods={foodsQuery.data ?? []}
          onClose={() => setEditor(null)}
          onSaved={async () => { setEditor(null); await refresh(); }}
        />
      )}
    </div>
  );
}

function DiaryMacro({ title, consumed, target, remaining, unit, neutralOverage = false }: { title: string; consumed: number; target: number; remaining: number; unit: string; neutralOverage?: boolean }) {
  const percent = Math.min(100, consumed * 100 / Math.max(1, target));
  return (
    <Card><CardContent className="p-5">
      <p className="text-sm font-semibold text-muted-foreground">{title}</p>
      <p className="mt-2 text-2xl font-black">{round(consumed)} <span className="text-sm font-medium">/ {round(target)} {unit}</span></p>
      <div className="my-3 h-2 overflow-hidden rounded-full bg-slate-100"><div className="h-full bg-emerald-500" style={{ width: `${percent}%` }} /></div>
      <p className={`text-xs ${remaining < 0 && !neutralOverage ? "text-red-600" : "text-muted-foreground"}`}>
        {remaining >= 0 ? `Còn ${round(remaining)} ${unit}` : `+${round(Math.abs(remaining))} ${unit} so với mục tiêu`}
      </p>
    </CardContent></Card>
  );
}

function MealSection({ mealType, logs, onAdd, onEdit, onDelete }: { mealType: string; logs: MealLog[]; onAdd: () => void; onEdit: (log: MealLog) => void; onDelete: (log: MealLog) => void }) {
  const totals = logs.reduce((sum, log) => ({ calories: sum.calories + log.totalCalories, protein: sum.protein + log.totalProtein, carbs: sum.carbs + log.totalCarbs, fat: sum.fat + log.totalFat }), { calories: 0, protein: 0, carbs: 0, fat: 0 });
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between"><div><CardTitle>{mealLabels[mealType]}</CardTitle><p className="mt-1 text-xs text-muted-foreground">{round(totals.calories)} kcal · P {round(totals.protein)}g · C {round(totals.carbs)}g · F {round(totals.fat)}g</p></div><Button size="sm" variant="outline" onClick={onAdd}><Plus className="size-4" /> Ghi món</Button></CardHeader>
      <CardContent className="space-y-3">
        {logs.length === 0 ? <EmptyState title={`Chưa có ${mealLabels[mealType].toLowerCase()}`} description="Ghi một hoặc nhiều món trong cùng một lần." /> : logs.map((log) => (
          <div key={log.id} className="rounded-2xl border bg-slate-50/60 p-4">
            <div className="mb-3 flex items-center justify-between gap-2">
              {log.sourceType === "LUNCH_ORDER" ? <Badge className="bg-emerald-100 text-emerald-800"><Utensils className="size-3" /> Từ đơn cơm</Badge> : <Badge variant="outline">Nhập thủ công</Badge>}
              {log.readOnly ? <span className="flex items-center gap-1 text-xs text-muted-foreground"><LockKeyhole className="size-3" /> Đơn hàng giữ nguyên</span> : <div className="flex gap-1"><Button size="sm" variant="ghost" onClick={() => onEdit(log)}>Sửa</Button><Button size="icon" variant="ghost" onClick={() => onDelete(log)}><Trash2 className="size-4 text-red-600" /></Button></div>}
            </div>
            <div className="space-y-2">{log.items.map((item) => <div key={item.id} className="flex items-center justify-between gap-3 text-sm"><span>{item.foodName}</span><span className="text-muted-foreground">{item.servingAmount ?? item.quantity} {unitLabel(item.servingUnit)}</span></div>)}</div>
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

function MealEditor({ open, mealType, date, log, foods, onClose, onSaved }: { open: boolean; mealType: string; date: string; log?: MealLog; foods: Food[]; onClose: () => void; onSaved: () => Promise<void> }) {
  const [search, setSearch] = useState("");
  const [items, setItems] = useState<MealDraftItem[]>(() => log
    ? log.items.map((item) => ({
      foodId: item.foodId,
      amount: item.servingAmount ?? item.quantity,
      unit: item.servingUnit ?? "SERVING",
    }))
    : []);
  const filteredFoods = useMemo(() => foods.filter((food) => food.name.toLowerCase().includes(search.toLowerCase())).slice(0, 20), [foods, search]);
  const selectedFoodIds = useMemo(() => new Set(items.map((item) => item.foodId)), [items]);
  const mutation = useMutation({
    mutationFn: async () => {
      if (items.length === 0) throw new Error("EMPTY");
      const payload = { mealType, logDate: date, items: items.map((item) => ({ foodId: item.foodId, quantity: factor(item, foods), servingAmount: item.amount, servingUnit: item.unit })) };
      return log ? updateMealLog(log.id, payload) : createMealLog(payload);
    },
    onSuccess: async () => { toast.success(log ? "Đã cập nhật bữa ăn" : "Đã lưu bữa ăn"); await onSaved(); },
    onError: showMutationError("Không thể lưu bữa ăn"),
  });
  return (
    <Dialog open={open} onOpenChange={(value) => { if (!value) onClose(); }}>
      <DialogContent className="flex max-h-[min(90dvh,760px)] w-[calc(100vw-1rem)] max-w-3xl flex-col gap-0 overflow-hidden p-0 sm:w-full sm:max-w-3xl sm:p-0">
        <DialogHeader className="shrink-0 px-5 pt-5 pr-14 pb-4 sm:px-6 sm:pt-6 sm:pr-14">
          <DialogTitle>{log ? "Chỉnh sửa" : "Ghi món vào"} {mealLabels[mealType]?.toLowerCase()}</DialogTitle>
          <p className="text-xs text-muted-foreground">Tìm món, chọn nhiều món rồi điều chỉnh số lượng ở bên dưới.</p>
        </DialogHeader>

        <div className="shrink-0 border-y bg-muted/25 px-5 py-4 sm:px-6">
          <Input
            autoFocus
            placeholder="Tìm món ăn..."
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
          <div className="mt-3 grid max-h-[min(36dvh,16rem)] grid-cols-[repeat(auto-fit,minmax(min(100%,240px),1fr))] gap-2 overflow-y-auto overflow-x-hidden pr-1">
            {filteredFoods.length === 0 ? (
              <p className="col-span-full rounded-xl border border-dashed p-4 text-center text-sm text-muted-foreground">
                Không tìm thấy món phù hợp.
              </p>
            ) : filteredFoods.map((food) => {
              const selected = selectedFoodIds.has(food.id);
              return (
                <Button
                  key={food.id}
                  type="button"
                  variant={selected ? "secondary" : "outline"}
                  className="h-auto min-h-10 min-w-0 justify-start overflow-hidden rounded-xl px-3 py-2 text-left"
                  disabled={selected}
                  title={`${food.name} · ${food.unit}`}
                  onClick={() => setItems((current) => [...current, { foodId: food.id, amount: 1, unit: "SERVING" }])}
                >
                  {selected ? <Check className="size-4 shrink-0" /> : <Plus className="size-4 shrink-0" />}
                  <span className="min-w-0 truncate">{food.name} · {food.unit}</span>
                </Button>
              );
            })}
          </div>
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto px-5 py-4 sm:px-6">
          {items.length === 0 ? (
            <div className="rounded-2xl border border-dashed bg-slate-50/60 p-5 text-center">
              <p className="font-medium">Chưa chọn món nào</p>
              <p className="mt-1 text-xs text-muted-foreground">Chọn một hoặc nhiều món ở danh sách phía trên.</p>
            </div>
          ) : (
            <div className="space-y-3">{items.map((item, index) => {
              const food = foods.find((candidate) => candidate.id === item.foodId);
              return (
                <div key={`${item.foodId}-${index}`} className="min-w-0 rounded-2xl border p-4">
                  <div className="min-w-0">
                    <p className="truncate font-semibold" title={food?.name}>{food?.name}</p>
                    <p className="text-xs text-muted-foreground">{food?.verified ? "✓ Dữ liệu đã xác minh" : "~ Dữ liệu tham khảo"}</p>
                  </div>
                  <div className="mt-3 grid min-w-0 grid-cols-[minmax(72px,0.8fr)_minmax(110px,1.2fr)_auto] items-end gap-2 sm:gap-3">
                    <FormField label="Số lượng">
                      <Input type="number" min={0.01} step={0.1} value={item.amount} onChange={(event) => setItems((current) => current.map((value, position) => position === index ? { ...value, amount: Number(event.target.value) } : value))} />
                    </FormField>
                    <FormField label="Đơn vị">
                      <select className="h-10 min-w-0 w-full rounded-md border bg-background px-3 text-sm" value={item.unit} onChange={(event) => setItems((current) => current.map((value, position) => position === index ? { ...value, unit: event.target.value as ServingUnit } : value))}>
                        <option value="SERVING">Khẩu phần</option>
                        {food?.servingSizeGrams ? <><option value="GRAM">Gram</option><option value="ML">ml</option></> : null}
                      </select>
                    </FormField>
                    <Button className="shrink-0" type="button" size="icon" variant="ghost" aria-label={`Xóa ${food?.name ?? "món"}`} onClick={() => setItems((current) => current.filter((_, position) => position !== index))}>
                      <Trash2 className="size-4 text-red-600" />
                    </Button>
                  </div>
                </div>
              );
            })}</div>
          )}
        </div>

        <div className="flex shrink-0 flex-col-reverse gap-2 border-t bg-background px-5 py-4 sm:flex-row sm:justify-end sm:px-6">
          <Button className="w-full sm:w-auto" variant="outline" onClick={onClose}>Hủy</Button>
          <Button className="w-full sm:w-auto" disabled={mutation.isPending || items.length === 0} onClick={() => mutation.mutate()}>
            {mutation.isPending ? "Đang lưu..." : `Lưu ${items.length} món`}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function factor(item: MealDraftItem, foods: Food[]) {
  if (item.unit === "SERVING") return item.amount;
  const size = foods.find((food) => food.id === item.foodId)?.servingSizeGrams;
  return size ? item.amount / size : item.amount;
}
function shiftDate(value: string, days: number) { const date = new Date(`${value}T12:00:00`); date.setDate(date.getDate() + days); return toLocalDateInput(date); }
function unitLabel(unit?: ServingUnit | null) { return unit === "GRAM" ? "g" : unit === "ML" ? "ml" : "khẩu phần"; }
function round(value: number) { return Math.round(value * 10) / 10; }
function showMutationError(fallback: string) { return (error: unknown) => { const message = axios.isAxiosError(error) ? error.response?.data?.message : error instanceof Error && error.message !== "EMPTY" ? error.message : undefined; toast.error(message || fallback); }; }
