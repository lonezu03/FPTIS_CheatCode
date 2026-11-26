import { useState } from "react";
import { Square, Wind } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { cn } from "@/lib/utils";
import { FLUTE_LOW_NOTES, LONG_TONE_MIN, nextLongToneTarget } from "./flute-data";
import FluteFingering from "./FluteFingering";
import { QuickSaveBar, SectionCard } from "./MusicParts";
import { useStopwatch } from "./useCountdown";

const STORAGE_KEY = "ancai-music-long-tone-targets";

type Targets = Record<string, number>;

function loadTargets(): Targets {
  try {
    const parsed = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? "{}") as unknown;
    return parsed && typeof parsed === "object" ? (parsed as Targets) : {};
  } catch {
    return {};
  }
}

function saveTargets(targets: Targets) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(targets));
  } catch {
    // Private mode: targets simply restart next visit.
  }
}

/** Long tones: hold one note as long and steady as possible; the target grows after each success. */
export default function LongTones() {
  const [noteKey, setNoteKey] = useState("sol");
  const [targets, setTargets] = useState<Targets>(loadTargets);
  const [misses, setMisses] = useState(0);
  const [last, setLast] = useState<{ held: number; success: boolean } | null>(null);
  const [bestHeld, setBestHeld] = useState(0);
  const watch = useStopwatch();
  const note = FLUTE_LOW_NOTES.find((item) => item.key === noteKey) ?? FLUTE_LOW_NOTES[0];
  const target = targets[noteKey] ?? LONG_TONE_MIN + 2;

  const finish = () => {
    const held = watch.stop();
    const result = nextLongToneTarget(target, held, misses);
    const next = { ...targets, [noteKey]: result.target };
    setTargets(next);
    saveTargets(next);
    setMisses(result.missesInRow);
    setLast({ held, success: result.success });
    setBestHeld((value) => Math.max(value, held));
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
      <SectionCard title="Ngân dài" description="Bấm Bắt đầu khi thổi, bấm Hết hơi khi tiếng bắt đầu run hoặc yếu đi. Đạt mục tiêu thì lần sau mục tiêu tăng 1 giây.">
        <div className="flex flex-wrap gap-1.5" role="radiogroup" aria-label="Nốt ngân">
          {FLUTE_LOW_NOTES.map((item) => (
            <button
              key={item.key}
              type="button"
              role="radio"
              aria-checked={item.key === noteKey}
              disabled={watch.running}
              onClick={() => {
                setNoteKey(item.key);
                setLast(null);
                setMisses(0);
              }}
              className={cn("min-h-9 min-w-12 rounded-xl border px-3 text-sm font-medium", item.key === noteKey ? "border-emerald-600 bg-emerald-50 text-emerald-800" : "text-muted-foreground hover:bg-muted")}
            >
              {item.solfege}
              <span className="ml-1 text-[11px] text-muted-foreground">{targets[item.key] ?? LONG_TONE_MIN + 2}s</span>
            </button>
          ))}
        </div>
        <FluteFingering note={note} />
        <ul className="list-disc space-y-1 pl-5 text-sm leading-6 text-muted-foreground">
          <li>Hít bụng sâu, vai thả lỏng. Thổi đều như thổi nhẹ ngọn nến.</li>
          <li>Nghe tiếng: tròn, không xì hơi, không rung lên xuống.</li>
          <li>Nghỉ 2–3 nhịp thở giữa các lần để không chóng mặt.</li>
        </ul>
      </SectionCard>

      <SectionCard title={`Mục tiêu: ${target} giây`} description={`Nốt ${note.solfege} (${note.note})`}>
        <div className="text-center">
          <p className={cn("text-6xl font-semibold tabular-nums", watch.running && watch.seconds >= target && "text-emerald-600")}>{watch.seconds.toFixed(1).replace(".", ",")}</p>
          <p className="text-sm text-muted-foreground">giây</p>
        </div>
        <Progress value={Math.min(100, (watch.seconds / target) * 100)} aria-label="Tiến độ so với mục tiêu" />
        {watch.running ? (
          <Button type="button" size="lg" variant="outline" className="w-full" onClick={finish}>
            <Square className="size-4" /> Hết hơi
          </Button>
        ) : (
          <Button type="button" size="lg" className="w-full" onClick={watch.start}>
            <Wind className="size-4" /> Bắt đầu ngân
          </Button>
        )}
        {last && !watch.running && (
          <p className={cn("text-center text-sm font-medium", last.success ? "text-emerald-700" : "text-muted-foreground")} aria-live="polite">
            {last.success ? `Đạt! Giữ được ${last.held.toFixed(1)} giây. Mục tiêu mới ${target} giây.` : `Giữ được ${last.held.toFixed(1)} giây. Thử lại, lấy hơi sâu hơn.`}
          </p>
        )}
        <QuickSaveBar instrument="FLUTE" exerciseKey="flute-long-tones" defaultMinutes={5} note={bestHeld ? `Ngân dài nhất ${bestHeld.toFixed(1)} giây` : undefined} />
      </SectionCard>
    </div>
  );
}
