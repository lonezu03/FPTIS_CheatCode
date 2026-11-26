import { cn } from "@/lib/utils";
import { scaleSequence } from "./flute-data";
import FluteFingering from "./FluteFingering";
import MetronomePanel from "./MetronomePanel";
import { QuickSaveBar, SectionCard } from "./MusicParts";
import { useMetronome } from "./useMetronome";

const SEQUENCE = scaleSequence();

/** Scale up and down, one note per click; the current note and its fingering follow the metronome. */
export default function ScaleDrill() {
  const metronome = useMetronome({ bpm: 60, beatsPerBar: 4 });
  const position = metronome.running && metronome.tick ? metronome.tick.index % SEQUENCE.length : -1;
  const current = SEQUENCE[Math.max(0, position)];

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
      <SectionCard title="Thang âm lên xuống" description="Mỗi tiếng máy đếm nhịp thổi một nốt. Đổi ngón gọn: nhấc và đặt các ngón cùng lúc.">
        <div className="flex flex-wrap gap-1.5">
          {SEQUENCE.map((note, index) => (
            <span
              key={`${note.key}-${index}`}
              className={cn(
                "min-w-11 rounded-lg px-2 py-1.5 text-center text-sm font-medium transition-colors duration-75",
                index === position ? "bg-emerald-500 text-white" : note.register === "high" ? "bg-amber-100 text-amber-900" : "bg-muted",
              )}
            >
              {note.solfege}
            </span>
          ))}
        </div>
        <div className="rounded-2xl border bg-muted/20 p-4 text-center">
          <p className="text-4xl font-semibold">{position >= 0 ? current.solfege : "Sẵn sàng"}</p>
          <p className="text-sm text-muted-foreground">{position >= 0 ? current.note : "Bấm Bắt đầu, nốt đầu là Đô"}</p>
          <div className="mt-2 flex justify-center">
            <FluteFingering note={current} />
          </div>
        </div>
        <p className="text-sm text-muted-foreground">Đô cao: cùng thế bấm như Đô nhưng thổi nhanh hơn, môi khép hẹp. Chưa lên được thì dừng ở Si rồi quay xuống.</p>
      </SectionCard>
      <SectionCard title="Máy đếm nhịp" description="Bắt đầu 60 BPM. Thổi sạch cả lượt lên xuống 2 lần thì tăng 5 BPM.">
        <MetronomePanel metronome={metronome} compact showSignature={false} />
        <QuickSaveBar instrument="FLUTE" exerciseKey="flute-scale" bpm={metronome.bpm} defaultMinutes={5} />
      </SectionCard>
    </div>
  );
}
