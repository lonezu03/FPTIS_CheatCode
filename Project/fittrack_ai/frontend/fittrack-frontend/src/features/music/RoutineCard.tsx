import { useCallback, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Check, ExternalLink, Pause, Play, SkipForward, Timer } from "lucide-react";
import { toast } from "sonner";

import type { MusicBestBpm, MusicInstrument } from "@/api/music.api";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { formatClock } from "./music-utils";
import { SectionCard, Segmented } from "./MusicParts";
import { buildRoutine, dayNumber, ROUTINE_LENGTHS, type RoutineLength, type RoutineStep } from "./routines";
import { playDoneSignal, useCountdown } from "./useCountdown";

export type LogPrefill = { instrument: MusicInstrument; minutes: number; exerciseKey: string; bpm: number | null };

/** Today's guided routine: one timer per step, then log the whole session in one click. */
export default function RoutineCard({ best, onLog }: { best: MusicBestBpm[]; onLog: (prefill: LogPrefill) => void }) {
  const [instrument, setInstrument] = useState<MusicInstrument>("GUITAR");
  const [length, setLength] = useState<RoutineLength>(15);
  const [day] = useState(() => dayNumber());
  const routine = useMemo(() => buildRoutine(instrument, length, day, best), [instrument, length, day, best]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [practiced, setPracticed] = useState<Record<string, number>>({});

  const stepIndex = routine.steps.findIndex((step) => step.id === activeId);

  const finishStep = useCallback(
    (step: RoutineStep, seconds: number) => {
      setPracticed((current) => ({ ...current, [step.id]: Math.max(current[step.id] ?? 0, seconds) }));
      const next = routine.steps[routine.steps.indexOf(step) + 1];
      setActiveId(next?.id ?? null);
      return next;
    },
    [routine],
  );

  const onDone = useCallback(() => {
    const step = routine.steps[stepIndex];
    if (!step) return;
    playDoneSignal();
    const next = finishStep(step, step.minutes * 60);
    toast.success(next ? `Xong “${step.title}”. Tiếp: ${next.title}` : "Hoàn thành bài tập hôm nay!");
  }, [routine, stepIndex, finishStep]);

  const timer = useCountdown(onDone);

  const reset = () => {
    timer.reset();
    setActiveId(null);
    setPracticed({});
  };

  const practicedSeconds = Object.values(practiced).reduce((sum, value) => sum + value, 0) + (timer.running || timer.remaining > 0 ? timer.elapsed : 0);
  const practicedMinutes = Math.round(practicedSeconds / 60);
  const doneCount = routine.steps.filter((step) => (practiced[step.id] ?? 0) >= step.minutes * 60).length;
  const core = routine.steps[2];

  return (
    <SectionCard
      title="Bài tập hôm nay"
      description="Khởi động → kỹ thuật → bài chính → chơi nhạc. Bấm Bắt đầu ở từng bước, hết giờ sẽ có tiếng báo."
      action={
        <div className="flex flex-wrap gap-2">
          <Segmented
            label="Nhạc cụ"
            value={instrument}
            onChange={(value) => {
              setInstrument(value);
              reset();
            }}
            options={[
              { value: "GUITAR", label: "Ghi-ta" },
              { value: "FLUTE", label: "Sáo" },
            ]}
          />
          <Segmented
            label="Thời lượng"
            value={length}
            onChange={(value) => {
              setLength(value);
              reset();
            }}
            options={ROUTINE_LENGTHS.map((minutes) => ({ value: minutes, label: `${minutes} phút` }))}
          />
        </div>
      }
    >
      <ol className="space-y-3">
        {routine.steps.map((step, index) => {
          const active = step.id === activeId;
          const done = (practiced[step.id] ?? 0) >= step.minutes * 60;
          const timing = active && (timer.running || timer.remaining > 0);
          return (
            <li
              key={step.id}
              className={cn("rounded-2xl border p-4 transition-colors", active ? "border-emerald-500 bg-emerald-50/50" : done ? "bg-muted/30" : "bg-card")}
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="flex min-w-0 gap-3">
                  <span
                    className={cn(
                      "flex size-7 shrink-0 items-center justify-center rounded-full text-sm font-semibold",
                      done ? "bg-emerald-600 text-white" : "bg-muted text-muted-foreground",
                    )}
                  >
                    {done ? <Check className="size-4" /> : index + 1}
                  </span>
                  <div className="min-w-0">
                    <p className="font-semibold">
                      {step.title} <span className="font-normal text-muted-foreground">· {step.minutes} phút</span>
                    </p>
                    <ul className="mt-1 list-disc space-y-0.5 pl-4 text-sm text-muted-foreground">
                      {step.how.map((line) => (
                        <li key={line}>{line}</li>
                      ))}
                    </ul>
                    <div className="mt-2 flex flex-wrap items-center gap-3 text-sm">
                      {step.bpm && <span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs font-medium text-amber-900">Gợi ý {step.bpm} BPM</span>}
                      {step.link && (
                        <Link to={step.link} className="inline-flex items-center gap-1 text-xs font-medium text-emerald-700 hover:underline">
                          Mở công cụ <ExternalLink className="size-3" />
                        </Link>
                      )}
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {timing ? (
                    <>
                      <span className="min-w-16 text-right text-xl font-semibold tabular-nums" aria-live="off">
                        {formatClock(timer.remaining)}
                      </span>
                      <Button type="button" size="icon-sm" variant="outline" aria-label={timer.running ? "Tạm dừng" : "Tiếp tục"} onClick={timer.running ? timer.pause : timer.resume}>
                        {timer.running ? <Pause className="size-4" /> : <Play className="size-4" />}
                      </Button>
                      <Button
                        type="button"
                        size="icon-sm"
                        variant="ghost"
                        aria-label="Xong bước này"
                        onClick={() => {
                          const elapsed = timer.elapsed;
                          timer.reset();
                          finishStep(step, step.minutes * 60 > elapsed + 5 ? elapsed : step.minutes * 60);
                        }}
                      >
                        <SkipForward className="size-4" />
                      </Button>
                    </>
                  ) : (
                    <Button
                      type="button"
                      size="sm"
                      variant={active || (!activeId && index === doneCount) ? "default" : "outline"}
                      onClick={() => {
                        setActiveId(step.id);
                        timer.start(step.minutes * 60);
                      }}
                    >
                      <Timer className="size-4" /> {done ? "Tập lại" : "Bắt đầu"}
                    </Button>
                  )}
                </div>
              </div>
            </li>
          );
        })}
      </ol>
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-muted/40 p-3">
        <p className="text-sm">
          Đã tập <span className="font-semibold">{practicedMinutes} / {routine.totalMinutes} phút</span> · {doneCount}/{routine.steps.length} bước
        </p>
        <Button
          type="button"
          onClick={() =>
            onLog({
              instrument,
              minutes: Math.min(600, Math.max(1, practicedMinutes || routine.totalMinutes)),
              exerciseKey: core.exerciseKey,
              bpm: core.bpm ?? null,
            })
          }
        >
          Ghi buổi tập
        </Button>
      </div>
    </SectionCard>
  );
}
