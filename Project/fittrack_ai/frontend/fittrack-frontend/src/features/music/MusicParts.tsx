import { useState, type ReactNode } from "react";
import { Save } from "lucide-react";

import type { MusicInstrument } from "@/api/music.api";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { toLocalDateInput } from "@/lib/format";
import { cn } from "@/lib/utils";
import { useLogMusicSession } from "./useMusicQueries";

/** Small segmented control (radio group semantics). */
export function Segmented<T extends string | number>({
  value,
  options,
  onChange,
  label,
  className,
}: {
  value: T;
  options: { value: T; label: ReactNode }[];
  onChange: (value: T) => void;
  label: string;
  className?: string;
}) {
  return (
    <div role="radiogroup" aria-label={label} className={cn("inline-flex flex-wrap rounded-xl border bg-muted/50 p-1", className)}>
      {options.map((option) => {
        const active = option.value === value;
        return (
          <button
            key={String(option.value)}
            type="button"
            role="radio"
            aria-checked={active}
            onClick={() => onChange(option.value)}
            className={cn(
              "min-h-8 rounded-lg px-3 text-sm font-medium transition-colors outline-none focus-visible:ring-2 focus-visible:ring-ring/40",
              active ? "bg-background text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground",
            )}
          >
            {option.label}
          </button>
        );
      })}
    </div>
  );
}

export function SectionCard({ title, description, action, children, className }: { title: string; description?: ReactNode; action?: ReactNode; children: ReactNode; className?: string }) {
  return (
    <Card className={className}>
      <CardHeader className="flex flex-row flex-wrap items-start justify-between gap-2">
        <div className="space-y-1">
          <CardTitle className="text-base">{title}</CardTitle>
          {description && <CardDescription>{description}</CardDescription>}
        </div>
        {action}
      </CardHeader>
      <CardContent className="space-y-4">{children}</CardContent>
    </Card>
  );
}

export function TipsList({ tips }: { tips: { title: string; text: string }[] }) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {tips.map((tip) => (
        <div key={tip.title} className="rounded-2xl border bg-card p-4">
          <p className="font-semibold">{tip.title}</p>
          <p className="mt-1 text-sm leading-6 text-muted-foreground">{tip.text}</p>
        </div>
      ))}
    </div>
  );
}

/** Inline "save this exercise" bar used under each exercise. */
export function QuickSaveBar({
  instrument,
  exerciseKey,
  defaultMinutes = 5,
  bpm,
  note,
  label = "Ghi buổi tập",
}: {
  instrument: MusicInstrument;
  exerciseKey: string;
  defaultMinutes?: number;
  /** Tempo reached; shown read-only and sent as `bpm`. */
  bpm?: number | null;
  note?: string;
  label?: string;
}) {
  const [minutes, setMinutes] = useState(String(defaultMinutes));
  const log = useLogMusicSession();
  const value = Number(minutes);
  const valid = Number.isInteger(value) && value >= 1 && value <= 600;

  return (
    <form
      className="flex flex-wrap items-end gap-2 rounded-2xl border border-dashed bg-muted/30 p-3"
      onSubmit={(event) => {
        event.preventDefault();
        if (!valid) return;
        log.mutate({ instrument, practicedOn: toLocalDateInput(), minutes: value, exerciseKey, bpm: bpm && bpm >= 20 && bpm <= 300 ? bpm : null, note: note || null });
      }}
    >
      <label className="grid gap-1 text-xs font-medium text-muted-foreground">
        Số phút
        <Input className="h-9 w-20" type="number" inputMode="numeric" min={1} max={600} value={minutes} aria-invalid={!valid} onChange={(event) => setMinutes(event.target.value)} />
      </label>
      {bpm ? <p className="pb-2 text-sm text-muted-foreground">Tốc độ: <span className="font-semibold text-foreground">{bpm} BPM</span></p> : null}
      <Button type="submit" size="sm" className="h-9" disabled={!valid || log.isPending}>
        <Save className="size-4" /> {log.isPending ? "Đang lưu…" : label}
      </Button>
    </form>
  );
}
