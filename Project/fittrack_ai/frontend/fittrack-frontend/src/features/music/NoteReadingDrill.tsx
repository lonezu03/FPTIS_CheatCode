import { useCallback, useMemo, useRef, useState } from "react";
import { Check, Eye, EyeOff, Mic, MicOff, SkipForward } from "lucide-react";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { FLUTE_LOW_NOTES, FLUTE_NOTES, pickNextNote, type FluteNote } from "./flute-data";
import FluteFingering from "./FluteFingering";
import { noteToMidi } from "./music-theory";
import { QuickSaveBar, SectionCard, Segmented } from "./MusicParts";
import { FLUTE_RANGE, useTuner, type TunerReading } from "./useTuner";

/** A note counts as played after this long on the right pitch. */
const HOLD_MS = 350;
const TOLERANCE_CENTS = 40;

type Pool = "low" | "all";

/** Shows a random note name; the user plays it. With the microphone on, the app checks the pitch. */
export default function NoteReadingDrill() {
  const [poolKey, setPoolKey] = useState<Pool>("low");
  const pool = useMemo(() => (poolKey === "low" ? FLUTE_LOW_NOTES : FLUTE_NOTES), [poolKey]);
  const [current, setCurrent] = useState<FluteNote>(() => pickNextNote(FLUTE_LOW_NOTES, null));
  const [score, setScore] = useState({ correct: 0, total: 0 });
  const [showHint, setShowHint] = useState(false);
  const [flash, setFlash] = useState(false);
  const matchSince = useRef<number | null>(null);
  const currentRef = useRef(current);

  const advance = useCallback(
    (correct: boolean) => {
      setScore((value) => ({ correct: value.correct + (correct ? 1 : 0), total: value.total + 1 }));
      const next = pickNextNote(pool, currentRef.current.key);
      currentRef.current = next;
      matchSince.current = null;
      setCurrent(next);
      if (correct) {
        setFlash(true);
        window.setTimeout(() => setFlash(false), 400);
      }
    },
    [pool],
  );

  // Called from the tuner's analysis timer, not during render.
  const onReading = useCallback(
    (reading: TunerReading | null) => {
      const targetMidi = noteToMidi(currentRef.current.note);
      // Low-register drill accepts either octave: a beginner often overblows.
      const ok =
        reading !== null &&
        targetMidi !== null &&
        Math.abs(reading.cents) <= TOLERANCE_CENTS &&
        (reading.midi === targetMidi || (poolKey === "low" && reading.midi === targetMidi + 12));
      if (!ok) {
        matchSince.current = null;
        return;
      }
      const now = performance.now();
      matchSince.current ??= now;
      if (now - matchSince.current >= HOLD_MS) advance(true);
    },
    [advance, poolKey],
  );

  const tuner = useTuner(FLUTE_RANGE, onReading);

  const changePool = (value: Pool) => {
    setPoolKey(value);
    const next = pickNextNote(value === "low" ? FLUTE_LOW_NOTES : FLUTE_NOTES, null);
    currentRef.current = next;
    setCurrent(next);
    setScore({ correct: 0, total: 0 });
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
      <SectionCard
        title="Đọc nốt"
        description="Nhìn tên nốt, nhớ thế bấm rồi thổi. Bật micro để app tự chấm; không có micro thì tự bấm Đúng."
        action={
          <Segmented
            label="Phạm vi nốt"
            value={poolKey}
            onChange={changePool}
            options={[
              { value: "low", label: "Quãng trầm" },
              { value: "all", label: "Cả quãng cao" },
            ]}
          />
        }
      >
        <div className={cn("rounded-3xl border p-6 text-center transition-colors", flash ? "border-emerald-500 bg-emerald-50" : "bg-muted/20")}>
          <p className="text-sm text-muted-foreground">Thổi nốt</p>
          <p className="text-6xl font-semibold tracking-tight" aria-live="polite">
            {current.solfege}
          </p>
          <p className="mt-1 text-sm text-muted-foreground">{current.note}</p>
          <div className={cn("mt-3 flex justify-center", !showHint && "invisible")} aria-hidden={!showHint}>
            <FluteFingering note={current} />
          </div>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button type="button" variant="outline" onClick={() => setShowHint((value) => !value)}>
            {showHint ? <EyeOff className="size-4" /> : <Eye className="size-4" />} {showHint ? "Ẩn thế bấm" : "Gợi ý thế bấm"}
          </Button>
          <Button type="button" onClick={() => advance(true)}>
            <Check className="size-4" /> Đúng rồi
          </Button>
          <Button type="button" variant="ghost" onClick={() => advance(false)}>
            <SkipForward className="size-4" /> Bỏ qua
          </Button>
        </div>
      </SectionCard>

      <SectionCard title={`Điểm: ${score.correct}/${score.total}`} description="Micro chỉ nghe trên máy bạn và tắt khi rời trang.">
        <Button type="button" variant={tuner.listening ? "outline" : "default"} disabled={tuner.status === "starting"} onClick={() => (tuner.listening ? tuner.stop() : void tuner.start())}>
          {tuner.listening ? <MicOff className="size-4" /> : <Mic className="size-4" />}
          {tuner.status === "starting" ? "Đang mở micro…" : tuner.listening ? "Tắt tự chấm" : "Bật micro để tự chấm"}
        </Button>
        {tuner.error && (
          <Alert variant="destructive">
            <AlertDescription>{tuner.error}</AlertDescription>
          </Alert>
        )}
        {tuner.listening && (
          <p className="rounded-xl bg-muted/50 p-3 text-sm">
            Đang nghe:{" "}
            <span className="font-semibold">{tuner.reading ? `${tuner.reading.solfege} (${tuner.reading.label}) ${tuner.reading.cents > 0 ? "+" : ""}${Math.round(tuner.reading.cents)} cent` : "—"}</span>
          </p>
        )}
        <QuickSaveBar instrument="FLUTE" exerciseKey="flute-note-reading" defaultMinutes={5} note={score.total ? `Đúng ${score.correct}/${score.total} nốt` : undefined} />
      </SectionCard>
    </div>
  );
}
