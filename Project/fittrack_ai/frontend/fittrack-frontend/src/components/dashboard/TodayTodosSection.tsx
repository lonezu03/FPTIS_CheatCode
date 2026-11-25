import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Circle, CircleCheck, ListTodo, Plus } from "lucide-react";
import { toast } from "sonner";
import { completeTodo, getTodos } from "@/api/todo.api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { getApiErrorMessage } from "@/lib/format";
import { cn } from "@/lib/utils";
import TodaySection from "./TodaySection";
import { doneTodayCount, isOverdue, nowMs, sortTodayTodos, timeLabel, todayKey } from "./today-utils";

const VISIBLE = 6;

export default function TodayTodosSection({ onAdd }: { onAdd: () => void }) {
  const queryClient = useQueryClient();
  // The "todos" prefix lets TodoPage invalidations refresh this list too.
  const query = useQuery({ queryKey: ["todos", "today-center"], queryFn: () => getTodos({ view: "TODAY" }) });
  const [pendingId, setPendingId] = useState<string | null>(null);
  const complete = useMutation({
    mutationFn: (id: string) => completeTodo(id),
    onMutate: (id) => setPendingId(id),
    onSuccess: (todo) => {
      toast.success(`Đã xong: ${todo.title}`);
      void queryClient.invalidateQueries({ queryKey: ["todos"] });
      void queryClient.invalidateQueries({ queryKey: ["calendar"] });
      void queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không đánh dấu được việc")),
    onSettled: () => setPendingId(null),
  });

  const now = nowMs();
  const todos = query.data ?? [];
  const open = sortTodayTodos(todos, now);
  const overdueCount = open.filter((todo) => isOverdue(todo, now)).length;
  const done = doneTodayCount(todos, todayKey());
  const state = query.isLoading ? "loading" : query.isError ? "error" : open.length === 0 ? "empty" : "ready";

  return (
    <TodaySection id="today-todos" title="Việc hôm nay" icon={ListTodo} iconClassName="bg-violet-100 text-violet-800 dark:bg-violet-950 dark:text-violet-200"
      state={state} errorText="Không tải được việc hôm nay." onRetry={() => void query.refetch()}
      link={{ to: "/todos", label: "Tất cả" }}
      meta={query.data && <span>{overdueCount > 0 && <b className="text-red-600">{overdueCount} quá hạn · </b>}Xong {done}</span>}
      empty={<div className="grid justify-items-center gap-2"><p>{done > 0 ? `Đã xong ${done} việc hôm nay. Tuyệt!` : "Không có việc đến hạn hôm nay."}</p><Button size="sm" variant="outline" onClick={onAdd}><Plus className="size-3.5" />Thêm việc</Button></div>}>
      <ul className="grid gap-1.5">
        {open.slice(0, VISIBLE).map((todo) => {
          const overdue = isOverdue(todo, now);
          const busy = pendingId === todo.id;
          const when = todo.dueAt ?? todo.startAt;
          return (
            <li key={todo.id} className={cn("flex items-center gap-2 rounded-xl border px-2 py-1.5", overdue && "border-red-200 bg-red-50/60 dark:border-red-900 dark:bg-red-950/30", busy && "opacity-60")}>
              <button type="button" disabled={busy || complete.isPending} onClick={() => complete.mutate(todo.id)}
                aria-label={`Hoàn thành ${todo.title}`}
                className="group grid size-9 shrink-0 place-items-center rounded-full text-emerald-700 hover:bg-emerald-50 disabled:cursor-wait dark:hover:bg-emerald-950">
                <Circle className="size-5 group-hover:hidden" />
                <CircleCheck className="hidden size-5 group-hover:block" />
              </button>
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium">{todo.title}</p>
                {when && <p className={cn("text-xs text-muted-foreground", overdue && "font-semibold text-red-600")}>
                  {overdue ? "Quá hạn " : todo.dueAt ? "Hạn " : "Bắt đầu "}{new Date(when).toLocaleDateString("vi-VN") === new Date(now).toLocaleDateString("vi-VN") ? timeLabel(when) : new Date(when).toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit" })}
                </p>}
              </div>
              {todo.priority === "HIGH" && <Badge variant="destructive" className="shrink-0">Cao</Badge>}
            </li>
          );
        })}
      </ul>
      {open.length > VISIBLE && <p className="text-xs text-muted-foreground">Còn {open.length - VISIBLE} việc khác.</p>}
    </TodaySection>
  );
}
