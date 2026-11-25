import { useEffect, useState, type FormEvent } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Check, Search } from "lucide-react";
import { createMealLog, getNutritionConvenience, searchNutritionFoods, type Food } from "@/api/nutrition.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { toLocalDateInput } from "@/lib/format";
import { cn } from "@/lib/utils";
import QuickField from "./QuickField";
import { invalidProps, selectClass } from "./quick-field-styles";
import { MEAL_LABELS, MEAL_TYPES, mealQuantity, mealTypeForHour, type MealType, type MealUnit } from "./quick-add-config";
import { hasErrors, parseDecimal, validateMeal, type FieldErrors } from "./quick-add-validation";
import { useQuickAddFeedback } from "./use-quick-add-feedback";

type Unit = MealUnit;

function useDebounced<T>(value: T, delay: number) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = window.setTimeout(() => setDebounced(value), delay);
    return () => window.clearTimeout(timer);
  }, [value, delay]);
  return debounced;
}

export default function MealQuickForm({ onDone, initialMealType }: { onDone: () => void; initialMealType?: MealType }) {
  const [mealType, setMealType] = useState<MealType>(() => initialMealType ?? mealTypeForHour(new Date().getHours()));
  const [keyword, setKeyword] = useState("");
  const [food, setFood] = useState<Food | null>(null);
  const [amount, setAmount] = useState("1");
  const [unit, setUnit] = useState<Unit>("SERVING");
  const [errors, setErrors] = useState<FieldErrors<"food" | "amount">>({});
  const { succeed, fail } = useQuickAddFeedback();
  const search = useDebounced(keyword.trim(), 300);

  const convenience = useQuery({ queryKey: ["nutrition-convenience"], queryFn: getNutritionConvenience, staleTime: 60_000 });
  const results = useQuery({
    queryKey: ["foods", "search", search, 0],
    queryFn: () => searchNutritionFoods(search, 0),
    enabled: search.length > 0,
    staleTime: 60_000,
  });

  const shortcuts = [...(convenience.data?.favoriteFoods ?? []), ...(convenience.data?.recentFoods ?? [])]
    .filter((item, index, all) => all.findIndex((other) => other.food.id === item.food.id) === index)
    .slice(0, 6)
    .map((item) => item.food);
  const options = search ? (results.data?.content ?? []).slice(0, 6) : shortcuts;
  const optionsLoading = search ? results.isLoading : convenience.isLoading;

  const parsedAmount = parseDecimal(amount);
  const quantity = food && parsedAmount && Number.isFinite(parsedAmount) ? mealQuantity(parsedAmount, unit, food.servingSizeGrams) : null;
  const estimatedCalories = food && quantity ? Math.round(food.calories * quantity) : null;

  const today = toLocalDateInput();
  const mutation = useMutation({
    mutationFn: () => createMealLog({
      mealType,
      logDate: today,
      items: [{ foodId: food!.id, quantity: quantity!, servingAmount: parsedAmount!, servingUnit: unit }],
    }),
    onSuccess: () => {
      succeed(`Đã ghi ${food!.name} vào ${MEAL_LABELS[mealType].toLowerCase()}`, "/nutrition", [
        ["nutrition-diary"], ["dashboard-today"], ["health-summary"], ["weekly-report"],
        ["weekly-recommendations"], ["achievements"], ["nutrition-convenience"], ["dashboard-progress"],
      ]);
      onDone();
    },
    onError: (error) => fail(error, "Không ghi được bữa ăn"),
  });

  const pick = (next: Food) => {
    setFood(next);
    setErrors((current) => ({ ...current, food: undefined }));
    if (!next.servingSizeGrams && unit === "GRAM") {
      setUnit("SERVING");
      setAmount("1");
    }
  };

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const next = validateMeal({ foodId: food?.id ?? null, amount, unit, servingSizeGrams: food?.servingSizeGrams });
    setErrors(next);
    if (!hasErrors(next)) mutation.mutate();
  };

  return (
    <form className="grid gap-4" onSubmit={submit} noValidate>
      <QuickField id="qa-meal-type" label="Bữa">
        <select id="qa-meal-type" className={selectClass} value={mealType} onChange={(event) => setMealType(event.target.value as MealType)}>
          {MEAL_TYPES.map((type) => <option key={type} value={type}>{MEAL_LABELS[type]}</option>)}
        </select>
      </QuickField>
      <QuickField id="qa-meal-search" label="Món" error={errors.food}>
        <div className="relative">
          <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input id="qa-meal-search" autoFocus className="pl-9" placeholder="Tìm món: phở, cơm gà..." value={keyword}
            onChange={(event) => setKeyword(event.target.value)} {...invalidProps("qa-meal-search", errors.food)} />
        </div>
        <div className="grid gap-1.5" role="listbox" aria-label={search ? "Kết quả tìm món" : "Món gần đây"}>
          {!search && options.length > 0 && <p className="text-xs text-muted-foreground">Gần đây và yêu thích</p>}
          {optionsLoading && search && [0, 1, 2].map((index) => <Skeleton key={index} className="h-10 w-full" />)}
          {search && results.isError && <p className="text-xs text-destructive">Không tìm được món. Thử lại sau.</p>}
          {search && !results.isLoading && !results.isError && options.length === 0 && (
            <p className="text-xs text-muted-foreground">Không thấy món phù hợp. Thêm món mới tại Nhật ký ăn uống.</p>
          )}
          {options.map((option) => {
            const selected = food?.id === option.id;
            return (
              <button key={option.id} type="button" role="option" aria-selected={selected} onClick={() => pick(option)}
                className={cn("flex min-h-10 items-center justify-between gap-2 rounded-xl border px-3 py-2 text-left text-sm transition hover:border-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/30",
                  selected && "border-emerald-500 bg-emerald-50 dark:bg-emerald-950/30")}>
                <span className="min-w-0 truncate font-medium">{option.name}</span>
                <span className="flex shrink-0 items-center gap-1 text-xs text-muted-foreground">
                  {Math.round(option.calories)} kcal/{option.unit || "khẩu phần"}
                  {selected && <Check className="size-4 text-emerald-600" />}
                </span>
              </button>
            );
          })}
        </div>
      </QuickField>
      <div className="grid grid-cols-[minmax(0,1fr)_9rem] gap-2">
        <QuickField id="qa-meal-amount" label="Lượng" error={errors.amount}>
          <Input id="qa-meal-amount" inputMode="decimal" value={amount} onChange={(event) => setAmount(event.target.value)}
            {...invalidProps("qa-meal-amount", errors.amount)} />
        </QuickField>
        <QuickField id="qa-meal-unit" label="Đơn vị">
          <select id="qa-meal-unit" className={selectClass} value={unit} onChange={(event) => setUnit(event.target.value as Unit)}>
            <option value="SERVING">Khẩu phần</option>
            <option value="GRAM" disabled={Boolean(food) && !food?.servingSizeGrams}>Gram</option>
          </select>
        </QuickField>
      </div>
      {estimatedCalories !== null && <p className="text-sm text-muted-foreground">Khoảng <b className="text-foreground">{estimatedCalories} kcal</b></p>}
      <Button type="submit" disabled={mutation.isPending}>{mutation.isPending ? "Đang lưu..." : "Ghi bữa ăn"}</Button>
    </form>
  );
}
