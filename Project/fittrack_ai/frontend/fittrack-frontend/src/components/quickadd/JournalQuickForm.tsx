import { useState, type FormEvent } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { LockKeyhole } from "lucide-react";
import { Link } from "react-router-dom";
import { createJournalEntry, getJournalLockStatus, type JournalMood } from "@/api/journal.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { toLocalDateInput } from "@/lib/format";
import { cn } from "@/lib/utils";
import QuickField from "./QuickField";
import { invalidProps, textareaClass } from "./quick-field-styles";
import { hasErrors, validateJournal, type FieldErrors } from "./quick-add-validation";
import { useQuickAddFeedback } from "./use-quick-add-feedback";

const moods: { value: JournalMood; icon: string; label: string }[] = [
  { value: "VERY_LOW", icon: "😞", label: "Rất tệ" },
  { value: "LOW", icon: "🙁", label: "Không ổn" },
  { value: "NEUTRAL", icon: "😐", label: "Bình thường" },
  { value: "GOOD", icon: "🙂", label: "Tốt" },
  { value: "VERY_GOOD", icon: "😄", label: "Rất tốt" },
];

function hasUnlockSession() {
  try {
    return Boolean(sessionStorage.getItem("fittrack-journal-unlock"));
  } catch {
    return false;
  }
}

export default function JournalQuickForm({ onDone }: { onDone: () => void }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [mood, setMood] = useState<JournalMood | null>(null);
  const [errors, setErrors] = useState<FieldErrors<"title" | "body">>({});
  const { succeed, fail } = useQuickAddFeedback();
  const lock = useQuery({ queryKey: ["journal-lock"], queryFn: getJournalLockStatus });

  const mutation = useMutation({
    mutationFn: () => createJournalEntry({
      origin: "FREEFORM",
      entryDate: toLocalDateInput(),
      title: title.trim() || undefined,
      body: body.trim(),
      mood,
    }),
    onSuccess: () => {
      succeed("Đã lưu trang nhật ký", "/journal", [
        ["journal-today"], ["journal-entries"], ["journal-stats"], ["journal-recent"], ["journal-tags"],
      ]);
      onDone();
    },
    onError: (error) => fail(error, "Không lưu được nhật ký"),
  });

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const next = validateJournal({ title, body });
    setErrors(next);
    if (!hasErrors(next)) mutation.mutate();
  };

  if (lock.isLoading) return <div className="grid gap-3" aria-busy="true"><Skeleton className="h-10" /><Skeleton className="h-28" /></div>;
  if (lock.isError) {
    return (
      <div role="alert" className="grid gap-3 text-sm">
        <p>Không kiểm tra được trạng thái khóa nhật ký.</p>
        <Button variant="outline" onClick={() => void lock.refetch()}>Thử lại</Button>
      </div>
    );
  }
  if (lock.data?.lockEnabled && !hasUnlockSession()) {
    return (
      <div className="grid justify-items-center gap-3 py-4 text-center text-sm">
        <LockKeyhole className="size-8 text-emerald-700" />
        <p>Nhật ký đang khóa. Mở khóa bằng PIN rồi viết tiếp.</p>
        <Button asChild variant="outline"><Link to="/journal" onClick={onDone}>Mở Nhật ký</Link></Button>
      </div>
    );
  }

  return (
    <form className="grid gap-4" onSubmit={submit} noValidate>
      <QuickField id="qa-journal-title" label="Tiêu đề" error={errors.title} hint="Không bắt buộc">
        <Input id="qa-journal-title" maxLength={200} value={title} onChange={(event) => setTitle(event.target.value)}
          {...invalidProps("qa-journal-title", errors.title)} />
      </QuickField>
      <QuickField id="qa-journal-body" label="Hôm nay thế nào?" error={errors.body}>
        <textarea id="qa-journal-body" autoFocus className={textareaClass} maxLength={20000} value={body}
          onChange={(event) => setBody(event.target.value)} {...invalidProps("qa-journal-body", errors.body)} />
      </QuickField>
      <fieldset>
        <legend className="mb-1.5 text-sm font-medium">Tâm trạng</legend>
        <div className="flex flex-wrap gap-1.5">
          {moods.map((item) => (
            <button key={item.value} type="button" title={item.label} aria-label={item.label} aria-pressed={mood === item.value}
              onClick={() => setMood(mood === item.value ? null : item.value)}
              className={cn("grid size-10 place-items-center rounded-xl border text-xl transition hover:bg-muted",
                mood === item.value && "border-emerald-500 bg-emerald-50 dark:bg-emerald-950/30")}>
              {item.icon}
            </button>
          ))}
        </div>
      </fieldset>
      <Button type="submit" disabled={mutation.isPending}>{mutation.isPending ? "Đang lưu..." : "Lưu nhật ký"}</Button>
    </form>
  );
}
