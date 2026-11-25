import { useState, type FormEvent } from "react";
import { useMutation } from "@tanstack/react-query";
import { createTodo, type TodoPriority } from "@/api/todo.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toLocalDateInput } from "@/lib/format";
import { cn } from "@/lib/utils";
import QuickField from "./QuickField";
import { invalidProps } from "./quick-field-styles";
import { useQuickAddFeedback } from "./use-quick-add-feedback";
import { hasErrors, validateTodo, type FieldErrors } from "./quick-add-validation";

const priorities: { value: TodoPriority; label: string }[] = [
  { value: "LOW", label: "Thấp" },
  { value: "MEDIUM", label: "Vừa" },
  { value: "HIGH", label: "Cao" },
];

function endOfDay(offsetDays: number) {
  const date = new Date();
  date.setDate(date.getDate() + offsetDays);
  return `${toLocalDateInput(date)}T23:59`;
}

export default function TodoQuickForm({ onDone }: { onDone: () => void }) {
  const [title, setTitle] = useState("");
  const [dueAt, setDueAt] = useState("");
  const [priority, setPriority] = useState<TodoPriority>("MEDIUM");
  const [errors, setErrors] = useState<FieldErrors<"title" | "dueAt">>({});
  const { succeed, fail } = useQuickAddFeedback();

  const mutation = useMutation({
    mutationFn: () => createTodo({
      title: title.trim(),
      priority,
      category: "PERSONAL",
      dueAt: dueAt ? `${dueAt}:00` : null,
    }),
    onSuccess: (todo) => {
      succeed(`Đã thêm việc "${todo.title}"`, "/todos", [["todos"], ["calendar"], ["schedule-calendar"], ["dashboard-today"]]);
      onDone();
    },
    onError: (error) => fail(error, "Không thêm được việc"),
  });

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const next = validateTodo({ title, dueAt }, new Date());
    setErrors(next);
    if (!hasErrors(next)) mutation.mutate();
  };

  return (
    <form className="grid gap-4" onSubmit={submit} noValidate>
      <QuickField id="qa-todo-title" label="Việc cần làm" error={errors.title}>
        <Input id="qa-todo-title" autoFocus maxLength={180} placeholder="Ví dụ: Gọi điện cho mẹ" value={title}
          onChange={(event) => setTitle(event.target.value)} {...invalidProps("qa-todo-title", errors.title)} />
      </QuickField>
      <QuickField id="qa-todo-due" label="Hạn" error={errors.dueAt} hint="Để trống nếu không có hạn.">
        <div className="flex flex-wrap gap-2">
          <Input id="qa-todo-due" type="datetime-local" className="min-w-0 flex-1 basis-48" value={dueAt}
            onChange={(event) => setDueAt(event.target.value)} {...invalidProps("qa-todo-due", errors.dueAt)} />
          <Button type="button" size="sm" variant="outline" className="h-10" onClick={() => setDueAt(endOfDay(0))}>Hôm nay</Button>
          <Button type="button" size="sm" variant="outline" className="h-10" onClick={() => setDueAt(endOfDay(1))}>Ngày mai</Button>
        </div>
      </QuickField>
      <fieldset className="grid gap-1.5">
        <legend className="mb-1.5 text-sm font-medium">Ưu tiên</legend>
        <div className="grid grid-cols-3 gap-2">
          {priorities.map((item) => (
            <Button key={item.value} type="button" size="sm" variant={priority === item.value ? "default" : "outline"}
              aria-pressed={priority === item.value} onClick={() => setPriority(item.value)}
              className={cn(priority === item.value && item.value === "HIGH" && "bg-red-600 hover:bg-red-600/90")}>
              {item.label}
            </Button>
          ))}
        </div>
      </fieldset>
      <Button type="submit" disabled={mutation.isPending}>{mutation.isPending ? "Đang lưu..." : "Thêm việc"}</Button>
    </form>
  );
}
