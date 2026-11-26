import { useCallback, useEffect, useState } from "react";
import { ArrowLeftRight, RotateCcw, Save, Timer } from "lucide-react";

import type { MusicBestBpm } from "@/api/music.api";
import { Button } from "@/components/ui/button";
import { toLocalDateInput } from "@/lib/format";
import { cn } from "@/lib/utils";
import { ChordCard } from "./ChordLibrary";
import { CHORD_CHANGE_PAIRS, CHORDS, findChord, oneMinuteExerciseKey } from "./guitar-data";
import { formatClock, oneMinuteResultBody } from "./music-utils";
import { SectionCard } from "./MusicParts";
import { playDoneSignal, useCountdown } from "./useCountdown";
import { useLogMusicSession } from "./useMusicQueries";

const selectClass = "h-10 rounded-xl border border-input bg-background px-3 text-sm outline-none focus-visible:ring-3 focus-visible:ring-ring/15";
const shortName = (key: string) => findChord(key)?.name.replace(" (đơn giản)", "") ?? key;

/**
 * "One-minute changes" (Justin Guitar style): switch between two chords for 60 s,
 * count every clean change. The count is saved with exerciseKey guitar-one-minute-<a>-<b>.
 */
export default function OneMinuteChanges({ best }: { best: MusicBestBpm[] }) {
  const [a, setA] = useState("em");
  const [b, setB] = useState("am");
  const [count, setCount] = useState(0);
  const [phase, setPhase] = useState<"ready" | "running" | "done">("ready");
  const [saved, setSaved] = useState(false);
  const log = useLogMusicSession();
  const onDone = useCallback(() => {
    playDoneSignal();
    setPhase("done");
  }, []);
  const timer = useCountdown(onDone);
  const exerciseKey = oneMinuteExerciseKey(a, b);
  const record = best.find((item) => item.exerciseKey === exerciseKey && item.instrument === "GUITAR");

  const increment = useCallback(() => setCount((value) => value + 1), []);

  // Space bar counts a change while the minute runs.
  useEffect(() => {
    if (phase !== "running") return;
    const onKey = (event: KeyboardEvent) => {
      if (event.code !== "Space" || event.repeat) return;
      event.preventDefault();
      increment();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [phase, increment]);

  const start = () => {
    setCount(0);
    setSaved(false);
    setPhase("running");
    timer.start(60);
  };

  const reset = () => {
    timer.reset();
    setCount(0);
    setSaved(false);
    setPhase("ready");
  };

  const pick = (nextA: string, nextB: string) => {
    setA(nextA);
    setB(nextB);
    reset();
  };

  const save = () => {
    const body = oneMinuteResultBody(count);
    log.mutate({ instrument: "GUITAR", practicedOn: toLocalDateInput(), minutes: 1, exerciseKey, ...body }, { onSuccess: () => setSaved(true) });
  };

  const chordA = findChord(a)!;
  const chordB = findChord(b)!;

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
      <SectionCard title="Đổi hợp âm 1 phút" description="Bấm hợp âm thứ nhất, quẹt một lần, đổi sang hợp âm thứ hai, quẹt một lần — mỗi lần đổi sạch là +1.">
        <div className="flex flex-wrap items-end gap-2">
          <label className="grid gap-1 text-xs font-medium text-muted-foreground">
            Hợp âm 1
            <select className={selectClass} value={a} disabled={phase === "running"} onChange={(event) => pick(event.target.value, b === event.target.value ? a : b)}>
              {CHORDS.map((chord) => (
                <option key={chord.key} value={chord.key}>
                  {chord.name}
                </option>
              ))}
            </select>
          </label>
          <ArrowLeftRight className="mb-3 size-4 text-muted-foreground" />
          <label className="grid gap-1 text-xs font-medium text-muted-foreground">
            Hợp âm 2
            <select className={selectClass} value={b} disabled={phase === "running"} onChange={(event) => pick(a === event.target.value ? b : a, event.target.value)}>
              {CHORDS.map((chord) => (
                <option key={chord.key} value={chord.key}>
                  {chord.name}
                </option>
              ))}
            </select>
          </label>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {CHORD_CHANGE_PAIRS.slice(0, 8).map(([x, y]) => (
            <button
              key={`${x}-${y}`}
              type="button"
              disabled={phase === "running"}
              onClick={() => pick(x, y)}
              className={cn("rounded-full border px-2.5 py-1 text-xs font-medium", x === a && y === b ? "border-emerald-600 bg-emerald-50 text-emerald-800" : "text-muted-foreground hover:bg-muted")}
            >
              {shortName(x)} ↔ {shortName(y)}
            </button>
          ))}
        </div>
        <div className="grid grid-cols-2 gap-3 sm:max-w-md">
          <ChordCard chord={chordA} size={120} />
          <ChordCard chord={chordB} size={120} />
        </div>
      </SectionCard>

      <SectionCard title="Đồng hồ 60 giây" description={record ? `Kỷ lục ${shortName(a)} ↔ ${shortName(b)}: ${record.bpm} lần/phút` : "Chưa có kỷ lục cho cặp này."}>
        <div className="text-center">
          <p className="text-5xl font-semibold tabular-nums">{phase === "ready" ? "01:00" : formatClock(timer.remaining)}</p>
          <p className="mt-1 text-sm text-muted-foreground">
            Số lần đổi: <span className="text-2xl font-semibold text-foreground tabular-nums">{count}</span>
          </p>
        </div>
        {phase === "running" ? (
          <button
            type="button"
            onClick={increment}
            className="flex h-32 w-full select-none items-center justify-center rounded-3xl bg-emerald-600 text-2xl font-semibold text-white shadow-lg active:scale-[0.98] active:bg-emerald-700"
          >
            Đổi! +1
          </button>
        ) : phase === "done" ? (
          <div className="space-y-3 text-center">
            <p className="text-lg font-semibold">
              {count} lần đổi trong 1 phút{record && count > record.bpm ? " — kỷ lục mới!" : ""}
            </p>
            {count > 0 && count < 20 && <p className="text-xs text-muted-foreground">Dưới 20 lần: kết quả được lưu trong ghi chú (BPM chỉ nhận từ 20).</p>}
            <div className="flex justify-center gap-2">
              <Button type="button" onClick={save} disabled={saved || log.isPending || count === 0}>
                <Save className="size-4" /> {saved ? "Đã lưu" : "Lưu kết quả"}
              </Button>
              <Button type="button" variant="outline" onClick={start}>
                <RotateCcw className="size-4" /> Làm lại
              </Button>
            </div>
          </div>
        ) : (
          <Button type="button" size="lg" className="w-full" onClick={start}>
            <Timer className="size-4" /> Bắt đầu 1 phút
          </Button>
        )}
        <p className="text-xs leading-5 text-muted-foreground">Mẹo: bấm nút lớn hoặc phím cách mỗi lần đổi xong. Chỉ đếm khi dây kêu rõ. Tập 1 phút mỗi ngày, ghi lại để thấy con số tăng dần.</p>
      </SectionCard>
    </div>
  );
}
