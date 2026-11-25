import type { FinanceBudget, FinanceTransaction } from "@/api/finance.api";
import type { MealLog } from "@/api/nutrition.api";
import type { Todo } from "@/api/todo.api";
import { toLocalDateInput } from "@/lib/format";

export function todayKey(date = new Date()) {
  return toLocalDateInput(date);
}

export function nextDayKey(day: string) {
  const date = new Date(`${day}T12:00:00`);
  date.setDate(date.getDate() + 1);
  return toLocalDateInput(date);
}

export function isActiveTodo(todo: Pick<Todo, "status">) {
  return todo.status === "OPEN" || todo.status === "IN_PROGRESS";
}

export function isOverdue(todo: Pick<Todo, "status" | "dueAt">, now: number) {
  return isActiveTodo(todo) && Boolean(todo.dueAt) && new Date(todo.dueAt!).getTime() < now;
}

/** Open todos for today: overdue first, then by due/start time, then high priority. */
export function sortTodayTodos(todos: Todo[], now: number) {
  const rank = { HIGH: 0, MEDIUM: 1, LOW: 2 } as const;
  const time = (todo: Todo) => {
    const value = todo.dueAt ?? todo.startAt;
    return value ? new Date(value).getTime() : Number.MAX_SAFE_INTEGER;
  };
  return todos.filter(isActiveTodo).sort((a, b) =>
    Number(isOverdue(b, now)) - Number(isOverdue(a, now))
    || time(a) - time(b)
    || rank[a.priority] - rank[b.priority]);
}

export function doneTodayCount(todos: Todo[], today: string) {
  return todos.filter((todo) => todo.status === "DONE" && todo.completedAt && toLocalDateInput(new Date(todo.completedAt)) === today).length;
}

export function mealCalories(meals: MealLog[], mealType: string) {
  return meals.filter((meal) => meal.mealType === mealType).reduce((sum, meal) => sum + (meal.totalCalories ?? 0), 0);
}

export function hasMeal(meals: MealLog[], mealType: string) {
  return meals.some((meal) => meal.mealType === mealType);
}

/** Sum of posted expenses; voided transactions never count. */
export function postedExpenseTotal(transactions: Pick<FinanceTransaction, "type" | "status" | "amount">[]) {
  return transactions
    .filter((transaction) => transaction.type === "EXPENSE" && transaction.status === "POSTED")
    .reduce((sum, transaction) => sum + Number(transaction.amount), 0);
}

/** Budgets that need attention first (highest usage). */
export function topBudgets(budgets: FinanceBudget[], limit = 3) {
  return [...budgets].sort((a, b) => b.percent - a.percent).slice(0, limit);
}

export function budgetTone(percent: number) {
  if (percent >= 100) return "danger" as const;
  if (percent >= 80) return "warning" as const;
  return "ok" as const;
}

export function timeLabel(value: string | null | undefined) {
  if (!value) return "";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "" : date.toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" });
}

export function nowMs() {
  return Date.now();
}
