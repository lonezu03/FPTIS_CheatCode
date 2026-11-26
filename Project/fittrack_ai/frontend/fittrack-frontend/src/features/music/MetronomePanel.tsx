import { Hand, Minus, Pause, Play, Plus } from "lucide-react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { BEATS_PER_BAR_OPTIONS, MAX_BPM, MIN_BPM } from "./metronome-engine";
import { Segmented } from "./MusicParts";
import type { MetronomeControls } from "./useMetronome";

function tempoName(bpm: number) {
  if (bpm < 60) return "Rất chậm";
  if (bpm < 76) return "Chậm";
  if (bpm < 108) return "Vừa";
  if (bpm < 140) return "Nhanh";
  return "Rất nhanh";
}

/** Metronome controls + beat lights. Pass `compact` inside exercises. */
export default function MetronomePanel({ metronome, compact = false, showSignature = true }: { metronome: MetronomeControls; compact?: boolean; showSignature?: boolean }) {
  const { bpm, setBpm, beatsPerBar, setBeatsPerBar, running, toggle, tick, tap, error, accent, setAccent } = metronome;

  return (
    <div className={cn("space-y-4", compact && "space-y-3")}>
      <div className="flex flex-wrap items-center gap-3">
        <Button type="button" size={compact ? "default" : "lg"} onClick={toggle} aria-pressed={running} className="min-w-28">
          {running ? <Pause className="size-4" /> : <Play className="size-4" />}
          {running ? "Dừng" : "Bắt đầu"}
        </Button>
        <div className="flex items-center gap-1">
          <Button type="button" variant="outline" size="icon-sm" aria-label="Giảm 5 BPM" onClick={() => setBpm(bpm - 5)}>
            <Minus className="size-4" />
          </Button>
          <div className="min-w-20 text-center" aria-live="polite">
            <span className={cn("font-semibold tabular-nums", compact ? "text-2xl" : "text-3xl")}>{bpm}</span>
            <span className="ml-1 text-xs text-muted-foreground">BPM</span>
          </div>
          <Button type="button" variant="outline" size="icon-sm" aria-label="Tăng 5 BPM" onClick={() => setBpm(bpm + 5)}>
            <Plus className="size-4" />
          </Button>
        </div>
        <Button type="button" variant="outline" size="sm" onClick={tap} title="Gõ đều theo nhịp ít nhất 2 lần">
          <Hand className="size-4" /> Gõ nhịp
        </Button>
        <span className="text-sm text-muted-foreground">{tempoName(bpm)}</span>
      </div>

      <input
        type="range"
        min={MIN_BPM}
        max={MAX_BPM}
        value={bpm}
        aria-label="Tốc độ (BPM)"
        onChange={(event) => setBpm(Number(event.target.value))}
        className="w-full accent-emerald-600"
      />

      <div className="flex flex-wrap items-center gap-3">
        {showSignature && (
          <Segmented
            label="Số phách mỗi ô nhịp"
            value={beatsPerBar}
            onChange={setBeatsPerBar}
            options={BEATS_PER_BAR_OPTIONS.map((beats) => ({ value: beats, label: `${beats}/4` }))}
          />
        )}
        <label className="flex items-center gap-2 text-sm text-muted-foreground">
          <input type="checkbox" checked={accent} onChange={(event) => setAccent(event.target.checked)} className="size-4 accent-emerald-600" />
          Nhấn phách 1
        </label>
      </div>

      <div className="flex gap-2" aria-hidden>
        {Array.from({ length: beatsPerBar }, (_, beat) => {
          const active = running && tick?.beat === beat;
          return (
            <span
              key={beat}
              className={cn(
                "h-3 flex-1 rounded-full transition-colors duration-75",
                active ? (beat === 0 && accent ? "bg-amber-500" : "bg-emerald-500") : "bg-muted",
              )}
            />
          );
        })}
      </div>
      {error && <p className="text-sm text-destructive">{error}</p>}
    </div>
  );
}
