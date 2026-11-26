import { useMemo, useState } from "react";
import { Mic, MicOff } from "lucide-react";

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { nearestGuitarString, STRING_TARGETS } from "./guitar-data";
import { centsBetween, formatHz, tuneState, type TuneState } from "./music-theory";
import { Segmented } from "./MusicParts";
import { FLUTE_RANGE, GUITAR_RANGE, useTuner, type TunerReading } from "./useTuner";

export type TunerMode = "guitar" | "flute";


const STATE_TEXT: Record<TunerMode, Record<TuneState, string>> = {
  guitar: { "in-tune": "Chuẩn rồi!", close: "Gần đúng", low: "Thấp – vặn căng dây lên", high: "Cao – nới chùng dây xuống" },
  flute: { "in-tune": "Chuẩn rồi!", close: "Gần đúng", low: "Thấp hơn chuẩn – thổi nhanh hơn một chút", high: "Cao hơn chuẩn – thổi nhẹ lại" },
};

function CentsGauge({ cents, state }: { cents: number | null; state: TuneState | null }) {
  const clamped = cents === null ? 0 : Math.max(-50, Math.min(50, cents));
  return (
    <div className="space-y-1">
      <div className="relative h-10 rounded-xl bg-muted">
        <div className="absolute inset-y-0 left-1/2 w-[10%] -translate-x-1/2 rounded-lg bg-emerald-200/70" />
        <div className="absolute inset-y-1 left-1/2 w-px bg-emerald-700/40" />
        {cents !== null && (
          <div
            className={cn(
              "absolute inset-y-0.5 w-1.5 -translate-x-1/2 rounded-full transition-[left] duration-100",
              state === "in-tune" ? "bg-emerald-600" : state === "close" ? "bg-amber-500" : "bg-red-500",
            )}
            style={{ left: `${50 + clamped}%` }}
          />
        )}
      </div>
      <div className="flex justify-between text-[11px] text-muted-foreground">
        <span>−50</span>
        <span>0 cent</span>
        <span>+50</span>
      </div>
    </div>
  );
}

function ReadingView({ mode, reading, targetString }: { mode: TunerMode; reading: TunerReading | null; targetString: string }) {
  if (!reading) {
    return <p className="py-6 text-center text-sm text-muted-foreground">{mode === "guitar" ? "Gảy một dây buông và để ngân…" : "Thổi một nốt đều hơi…"}</p>;
  }
  let title: string;
  let subtitle: string;
  let cents: number;
  if (mode === "guitar") {
    const target = targetString === "auto" ? nearestGuitarString(reading.frequency) : STRING_TARGETS.find((item) => item.note === targetString)!;
    cents = centsBetween(reading.frequency, target.frequency);
    title = target.note;
    subtitle = `${target.label} · chuẩn ${formatHz(target.frequency)}`;
  } else {
    cents = reading.cents;
    title = reading.solfege;
    subtitle = `${reading.label} · chuẩn ${formatHz(reading.target)}`;
  }
  const state = tuneState(cents);
  const farOff = mode === "guitar" && Math.abs(cents) > 100;

  return (
    <div className="space-y-3">
      <div className="flex items-end justify-between gap-3">
        <div>
          <p className="text-4xl font-semibold tracking-tight">{title}</p>
          <p className="text-sm text-muted-foreground">{subtitle}</p>
        </div>
        <div className="text-right">
          <p className={cn("text-2xl font-semibold tabular-nums", state === "in-tune" ? "text-emerald-600" : state === "close" ? "text-amber-600" : "text-red-600")}>
            {cents > 0 ? "+" : ""}
            {Math.round(cents)}
          </p>
          <p className="text-xs text-muted-foreground">cent · nghe {formatHz(reading.frequency)}</p>
        </div>
      </div>
      <CentsGauge cents={cents} state={state} />
      <p className={cn("text-center font-medium", state === "in-tune" ? "text-emerald-700" : "text-foreground")} aria-live="polite">
        {farOff ? `Đang nghe ${reading.label} – xa dây ${title}. Kiểm tra lại dây đang gảy.` : STATE_TEXT[mode][state]}
      </p>
    </div>
  );
}

/** Microphone tuner. The microphone turns off when this panel unmounts. */
export default function TunerPanel({ initialMode = "guitar", allowModeSwitch = false }: { initialMode?: TunerMode; allowModeSwitch?: boolean }) {
  const [mode, setMode] = useState<TunerMode>(initialMode);
  const [targetString, setTargetString] = useState("auto");
  const range = useMemo(() => (mode === "guitar" ? GUITAR_RANGE : FLUTE_RANGE), [mode]);
  const tuner = useTuner(range);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" onClick={() => (tuner.listening ? tuner.stop() : void tuner.start())} disabled={tuner.status === "starting"} variant={tuner.listening ? "outline" : "default"}>
          {tuner.listening ? <MicOff className="size-4" /> : <Mic className="size-4" />}
          {tuner.status === "starting" ? "Đang mở micro…" : tuner.listening ? "Tắt micro" : "Bật micro"}
        </Button>
        {allowModeSwitch && (
          <Segmented
            label="Nhạc cụ"
            value={mode}
            onChange={setMode}
            options={[
              { value: "guitar", label: "Ghi-ta" },
              { value: "flute", label: "Sáo" },
            ]}
          />
        )}
        {tuner.listening && <span className="flex items-center gap-1.5 text-xs text-emerald-700"><span className="size-2 animate-pulse rounded-full bg-emerald-500" />Đang nghe</span>}
      </div>

      {mode === "guitar" && (
        <div className="flex flex-wrap gap-1.5" role="radiogroup" aria-label="Dây cần lên">
          {[{ note: "auto", short: "Tự động" }, ...STRING_TARGETS.map((item) => ({ note: item.note, short: `${item.string} · ${item.note}` }))].map((item) => (
            <button
              key={item.note}
              type="button"
              role="radio"
              aria-checked={targetString === item.note}
              onClick={() => setTargetString(item.note)}
              className={cn(
                "min-h-8 rounded-lg border px-2.5 text-xs font-medium",
                targetString === item.note ? "border-emerald-600 bg-emerald-50 text-emerald-800" : "text-muted-foreground hover:bg-muted",
              )}
            >
              {item.short}
            </button>
          ))}
        </div>
      )}

      {tuner.status === "error" && tuner.error ? (
        <Alert variant="destructive">
          <MicOff className="size-4" />
          <AlertTitle>Chưa dùng được micro</AlertTitle>
          <AlertDescription>{tuner.error}</AlertDescription>
        </Alert>
      ) : tuner.listening ? (
        <ReadingView mode={mode} reading={tuner.reading} targetString={targetString} />
      ) : (
        <p className="rounded-xl bg-muted/50 p-4 text-sm text-muted-foreground">
          Bấm <span className="font-medium text-foreground">Bật micro</span> và cho phép trình duyệt dùng micro. Âm thanh chỉ được phân tích trên máy bạn, không gửi đi đâu.
          {mode === "guitar" ? " Lên từ dây 6 (Mi trầm) tới dây 1 (Mi cao)." : " Sáo Đô chuẩn: Đô (C5) = 523,25 Hz."}
        </p>
      )}
    </div>
  );
}
