import { Volume2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import ChordDiagram from "./ChordDiagram";
import { playStrum } from "./audio-synth";
import { CHORDS, STANDARD_TUNING_MIDI, type Chord } from "./guitar-data";

const LEVELS: { level: Chord["level"]; title: string; hint: string }[] = [
  { level: 1, title: "Học trước", hint: "Ít ngón, dễ bấm" },
  { level: 2, title: "Tiếp theo", hint: "Ngón xếp sát hoặc bỏ dây trầm" },
  { level: 3, title: "Khi đã quen", hint: "Có chặn nhiều dây" },
];

function strumMidi(chord: Chord) {
  return chord.frets.flatMap((fret, index) => (fret < 0 ? [] : [STANDARD_TUNING_MIDI[index] + fret]));
}

export function ChordCard({ chord, size = 132 }: { chord: Chord; size?: number }) {
  return (
    <div className="flex flex-col items-center rounded-2xl border bg-card p-3 text-center">
      <div className="flex w-full items-center justify-between">
        <span className="text-lg font-semibold">{chord.name}</span>
        <Button type="button" variant="ghost" size="icon-sm" aria-label={`Nghe hợp âm ${chord.name}`} onClick={() => playStrum(strumMidi(chord))}>
          <Volume2 className="size-4" />
        </Button>
      </div>
      <ChordDiagram chord={chord} size={size} />
      <p className="mt-1 text-xs leading-5 text-muted-foreground">{chord.tip}</p>
    </div>
  );
}

export default function ChordLibrary() {
  return (
    <div className="space-y-6">
      <div className="rounded-2xl bg-muted/40 p-4 text-sm leading-6 text-muted-foreground">
        Cách đọc: dây 6 (Mi trầm) bên trái, dây 1 bên phải, thanh đậm trên cùng là đầu cần. Số trong chấm là ngón tay trái:
        <span className="font-medium text-foreground"> 1 trỏ · 2 giữa · 3 áp út · 4 út</span>. <span className="font-medium text-foreground">○</span> dây buông,{" "}
        <span className="font-medium text-red-600">×</span> không đánh dây đó.
      </div>
      {LEVELS.map((group) => (
        <section key={group.level} className="space-y-3">
          <h3 className="font-semibold">
            {group.title} <span className="text-sm font-normal text-muted-foreground">· {group.hint}</span>
          </h3>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
            {CHORDS.filter((chord) => chord.level === group.level).map((chord) => (
              <ChordCard key={chord.key} chord={chord} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
