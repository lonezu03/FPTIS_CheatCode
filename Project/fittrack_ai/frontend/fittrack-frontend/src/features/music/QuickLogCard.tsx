import { useState, type FormEvent } from "react";
import { Save } from "lucide-react";

import type { MusicInstrument } from "@/api/music.api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toLocalDateInput } from "@/lib/format";
import { exerciseLabel, exercisesFor } from "./exercises";
import { toSessionInput, type SessionForm, type SessionFormErrors } from "./music-utils";
import { SectionCard, Segmented } from "./MusicParts";
import type { LogPrefill } from "./RoutineCard";
import { useLogMusicSession } from "./useMusicQueries";

const selectClass =
  "h-10 w-full rounded-xl border border-input bg-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/15";

function initialForm(prefill?: LogPrefill | null): SessionForm {
  const instrument = prefill?.instrument ?? "GUITAR";
  return {
    instrument,
    practicedOn: toLocalDateInput(),
    minutes: String(prefill?.minutes ?? 15),
    exerciseKey: prefill?.exerciseKey ?? exercisesFor(instrument)[1].key,
    bpm: prefill?.bpm ? String(prefill.bpm) : "",
    note: "",
  };
}

function FieldError({ id, message }: { id: string; message?: string }) {
  return message ? (
    <p id={id} className="text-xs text-destructive">
      {message}
    </p>
  ) : null;
}

/** One-click session log. Remount with a new `key` to apply a prefill from the routine. */
export default function QuickLogCard({ prefill }: { prefill?: LogPrefill | null }) {
  const [form, setForm] = useState<SessionForm>(() => initialForm(prefill));
  const [errors, setErrors] = useState<SessionFormErrors>({});
  const log = useLogMusicSession();
  const set = <K extends keyof SessionForm>(key: K, value: SessionForm[K]) => setForm((current) => ({ ...current, [key]: value }));

  const options = exercisesFor(form.instrument);
  // Keep a one-minute key from the guitar page selectable.
  const withCurrent = options.some((item) => item.key === form.exerciseKey) ? options : [{ key: form.exerciseKey, label: exerciseLabel(form.exerciseKey) }, ...options];

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const { input, errors: next } = toSessionInput(form);
    setErrors(next);
    if (!input) return;
    log.mutate(input, { onSuccess: () => setForm((current) => ({ ...current, note: "" })) });
  };

  return (
    <SectionCard title="Ghi nhanh buổi tập" description="Ghi lại để theo dõi chuỗi ngày và tiến bộ BPM.">
      <form className="grid gap-3" onSubmit={submit} noValidate>
        <Segmented
          label="Nhạc cụ"
          value={form.instrument}
          onChange={(value: MusicInstrument) => setForm((current) => ({ ...current, instrument: value, exerciseKey: exercisesFor(value)[1].key }))}
          options={[
            { value: "GUITAR", label: "Ghi-ta" },
            { value: "FLUTE", label: "Sáo trúc" },
          ]}
        />
        <div className="grid grid-cols-2 gap-3">
          <label className="grid gap-1.5 text-sm font-medium">
            Số phút
            <Input
              type="number"
              inputMode="numeric"
              min={1}
              max={600}
              value={form.minutes}
              aria-invalid={!!errors.minutes}
              aria-describedby="music-minutes-error"
              onChange={(event) => set("minutes", event.target.value)}
            />
            <FieldError id="music-minutes-error" message={errors.minutes} />
          </label>
          <label className="grid gap-1.5 text-sm font-medium">
            Ngày tập
            <Input type="date" value={form.practicedOn} max={toLocalDateInput()} aria-invalid={!!errors.practicedOn} onChange={(event) => set("practicedOn", event.target.value)} />
            <FieldError id="music-date-error" message={errors.practicedOn} />
          </label>
        </div>
        <label className="grid gap-1.5 text-sm font-medium">
          Bài tập
          <select className={selectClass} value={form.exerciseKey} onChange={(event) => set("exerciseKey", event.target.value)}>
            {withCurrent.map((item) => (
              <option key={item.key} value={item.key}>
                {item.label}
              </option>
            ))}
          </select>
          <FieldError id="music-exercise-error" message={errors.exerciseKey} />
        </label>
        <label className="grid gap-1.5 text-sm font-medium">
          <span>
            BPM đạt được <span className="font-normal text-muted-foreground">(không bắt buộc)</span>
          </span>
          <Input
            type="number"
            inputMode="numeric"
            min={20}
            max={300}
            placeholder="Ví dụ 60"
            value={form.bpm}
            aria-invalid={!!errors.bpm}
            aria-describedby="music-bpm-error"
            onChange={(event) => set("bpm", event.target.value)}
          />
          <FieldError id="music-bpm-error" message={errors.bpm} />
        </label>
        <label className="grid gap-1.5 text-sm font-medium">
          Ghi chú
          <textarea
            className="min-h-16 w-full rounded-xl border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/15"
            maxLength={500}
            placeholder="Chỗ nào còn khó? Ví dụ: đổi C sang G còn chậm"
            value={form.note}
            aria-invalid={!!errors.note}
            onChange={(event) => set("note", event.target.value)}
          />
          <FieldError id="music-note-error" message={errors.note} />
        </label>
        <Button type="submit" disabled={log.isPending}>
          <Save className="size-4" /> {log.isPending ? "Đang lưu…" : "Lưu buổi tập"}
        </Button>
      </form>
    </SectionCard>
  );
}
