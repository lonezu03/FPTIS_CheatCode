import { useState } from "react";

import { cn } from "@/lib/utils";
import { STRUM_ARROWS, STRUM_PATTERNS } from "./guitar-data";
import MetronomePanel from "./MetronomePanel";
import { QuickSaveBar, SectionCard } from "./MusicParts";
import { useMetronome } from "./useMetronome";

function countLabel(index: number, subdivision: number) {
  if (subdivision === 1) return String(index + 1);
  return index % 2 === 0 ? String(index / 2 + 1) : "và";
}

/** Strumming patterns; the current slot lights up with the metronome (eighth-note clicks). */
export default function StrummingPatterns() {
  const [key, setKey] = useState(STRUM_PATTERNS[0].key);
  const pattern = STRUM_PATTERNS.find((item) => item.key === key) ?? STRUM_PATTERNS[0];
  const metronome = useMetronome({ bpm: pattern.bpm, subdivision: pattern.subdivision, beatsPerBar: 4 });
  const slot = metronome.running && metronome.tick ? metronome.tick.index % pattern.slots.length : -1;

  const choose = (nextKey: string) => {
    const next = STRUM_PATTERNS.find((item) => item.key === nextKey);
    if (!next) return;
    setKey(next.key);
    metronome.setSubdivision(next.subdivision);
    metronome.setBpm(next.bpm);
    metronome.stop();
  };

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
      <SectionCard title="Tiết tấu quạt dây" description="Tay phải đưa lên xuống đều như con lắc, kể cả ở ô trống. ↓ quẹt xuống, ↑ quẹt lên, · đưa tay mà không chạm dây.">
        <div className="grid gap-2 sm:grid-cols-2">
          {STRUM_PATTERNS.map((item) => (
            <button
              key={item.key}
              type="button"
              aria-pressed={item.key === key}
              onClick={() => choose(item.key)}
              className={cn("rounded-2xl border p-3 text-left transition-colors", item.key === key ? "border-emerald-600 bg-emerald-50/60" : "hover:bg-muted/50")}
            >
              <p className="font-semibold">{item.name}</p>
              <p className="mt-1 font-mono text-lg tracking-widest">{item.slots.map((value) => STRUM_ARROWS[value]).join(" ")}</p>
            </button>
          ))}
        </div>
        <div className="rounded-2xl border bg-muted/20 p-4">
          <div className={cn("grid gap-1.5", pattern.subdivision === 2 ? "grid-cols-8" : "grid-cols-4")}>
            {pattern.slots.map((value, index) => (
              <div
                key={index}
                className={cn(
                  "flex flex-col items-center rounded-xl py-2 transition-colors duration-75",
                  slot === index ? "bg-emerald-500 text-white" : value === "-" ? "bg-transparent text-muted-foreground/60" : "bg-background",
                )}
              >
                <span className="text-2xl font-semibold leading-none sm:text-3xl">{STRUM_ARROWS[value]}</span>
                <span className={cn("mt-1 text-[11px]", slot === index ? "text-white/90" : "text-muted-foreground")}>{countLabel(index, pattern.subdivision)}</span>
              </div>
            ))}
          </div>
          <p className="mt-3 text-sm text-muted-foreground">{pattern.description}</p>
        </div>
      </SectionCard>
      <SectionCard title="Máy đếm nhịp" description={pattern.subdivision === 2 ? "Mỗi phách có 2 tiếng: phách chính và tiếng “và” nhỏ hơn." : "Mỗi tiếng là một lần quẹt xuống."}>
        <MetronomePanel metronome={metronome} compact showSignature={false} />
        <QuickSaveBar instrument="GUITAR" exerciseKey="guitar-strumming" bpm={metronome.bpm} defaultMinutes={5} />
      </SectionCard>
    </div>
  );
}
