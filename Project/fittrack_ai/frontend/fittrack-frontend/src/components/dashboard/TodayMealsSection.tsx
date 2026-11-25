import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, Plus, Soup } from "lucide-react";
import { toast } from "sonner";
import { getNutritionDiary, updateNutritionDayStatus } from "@/api/nutrition.api";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { MAIN_MEAL_TYPES, MEAL_LABELS, type MealType } from "@/components/quickadd/quick-add-config";
import { getApiErrorMessage } from "@/lib/format";
import TodaySection from "./TodaySection";
import { hasMeal, mealCalories, todayKey } from "./today-utils";

export default function TodayMealsSection({ onLog }: { onLog: (mealType: MealType) => void }) {
  const queryClient = useQueryClient();
  const today = todayKey();
  // Same key as NutritionPage so both screens share one cache entry.
  const query = useQuery({ queryKey: ["nutrition-diary", today], queryFn: () => getNutritionDiary(today) });
  const confirm = useMutation({
    mutationFn: () => updateNutritionDayStatus(today, "COMPLETE"),
    onSuccess: (diary) => {
      queryClient.setQueryData(["nutrition-diary", today], diary);
      void queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      void queryClient.invalidateQueries({ queryKey: ["weekly-report"] });
      toast.success("Đã chốt ngày ăn đủ bữa");
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không chốt được ngày")),
  });

  const diary = query.data;
  const meals = diary?.meals ?? [];
  const missing = MAIN_MEAL_TYPES.filter((type) => !hasMeal(meals, type));
  const snackCalories = mealCalories(meals, "SNACK");
  const target = diary?.targets.calories ?? 0;
  const consumed = diary?.consumed.calories ?? 0;
  const percent = target > 0 ? Math.min(100, Math.round((consumed / target) * 100)) : 0;
  const canConfirm = diary && missing.length === 0 && diary.status !== "COMPLETE" && diary.status !== "FASTING";

  return (
    <TodaySection id="today-meals" title="Bữa ăn hôm nay" icon={Soup}
      state={query.isLoading ? "loading" : query.isError || !diary ? "error" : "ready"}
      errorText="Không tải được nhật ký ăn uống." onRetry={() => void query.refetch()}
      link={{ to: "/nutrition", label: "Nhật ký" }}
      meta={diary && <span>{missing.length > 0 ? `Thiếu ${missing.length} bữa` : "Đủ 3 bữa"}</span>}>
      {diary && (
        <>
          <ul className="grid gap-1.5">
            {MAIN_MEAL_TYPES.map((type) => {
              const logged = hasMeal(meals, type);
              return (
                <li key={type} className="flex min-h-12 items-center gap-2 rounded-xl border px-3 py-1.5">
                  {logged ? <CheckCircle2 className="size-5 shrink-0 text-emerald-600" /> : <span className="size-5 shrink-0 rounded-full border-2 border-dashed border-muted-foreground/40" />}
                  <div className="min-w-0 flex-1">
                    <p className="font-medium">{MEAL_LABELS[type]}</p>
                    <p className="text-xs text-muted-foreground">{logged ? `${Math.round(mealCalories(meals, type))} kcal` : "Chưa ghi"}</p>
                  </div>
                  <Button size="sm" variant={logged ? "ghost" : "outline"} onClick={() => onLog(type)}
                    aria-label={`${logged ? "Ghi thêm" : "Ghi"} ${MEAL_LABELS[type].toLowerCase()}`}>
                    <Plus className="size-3.5" />{logged ? "Thêm" : "Ghi"}
                  </Button>
                </li>
              );
            })}
          </ul>
          <div className="grid gap-1.5 pt-1">
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <span>{Math.round(consumed)} / {Math.round(target)} kcal{snackCalories > 0 ? ` · bữa phụ ${Math.round(snackCalories)} kcal` : ""}</span>
              <span>{percent}%</span>
            </div>
            <Progress value={percent} aria-label="Năng lượng đã nạp" />
          </div>
          {canConfirm && (
            <Button size="sm" variant="secondary" disabled={confirm.isPending} onClick={() => confirm.mutate()}>
              {confirm.isPending ? "Đang lưu..." : "Chốt: hôm nay đã ghi đủ"}
            </Button>
          )}
        </>
      )}
    </TodaySection>
  );
}
