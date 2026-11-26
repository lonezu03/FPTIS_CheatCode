import { Info, Volume2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { playTone } from "./audio-synth";
import { FLUTE_NOTES, type FluteNote } from "./flute-data";
import FluteFingering from "./FluteFingering";
import { formatHz, noteToFrequency } from "./music-theory";

export function FluteNoteCard({ note }: { note: FluteNote }) {
  const frequency = noteToFrequency(note.note)!;
  return (
    <div className="rounded-2xl border bg-card p-3">
      <div className="flex items-center justify-between gap-2">
        <div>
          <p className="text-lg font-semibold">{note.solfege}</p>
          <p className="text-xs text-muted-foreground">
            {note.note} · {formatHz(frequency)}
          </p>
        </div>
        <Button type="button" variant="ghost" size="icon-sm" aria-label={`Nghe nốt ${note.solfege}`} onClick={() => playTone(frequency)}>
          <Volume2 className="size-4" />
        </Button>
      </div>
      <FluteFingering note={note} compact />
    </div>
  );
}

export function FluteConventionNote() {
  return (
    <div className="flex gap-3 rounded-2xl border border-amber-200 bg-amber-50/70 p-4 text-sm leading-6 text-amber-950">
      <Info className="mt-0.5 size-4 shrink-0" />
      <p>
        Lỗ đánh số 1 → 6 tính từ phía lỗ thổi. <span className="font-semibold">Chấm đen = bịt lỗ</span>, trắng = mở. Đây là thế bấm phổ biến của sáo Đô 6 lỗ; mỗi
        người làm sáo có thể khác một chút (nhất là Fa, Si và quãng cao), nên hãy so với sáo của bạn và dùng máy lên dây để kiểm tra. Nốt chuẩn: Đô (C5) = 523,25 Hz.
      </p>
    </div>
  );
}

/** Fingering chart for the 14 notes of a C5 flute. */
export default function FluteChart() {
  const low = FLUTE_NOTES.filter((note) => note.register === "low");
  const high = FLUTE_NOTES.filter((note) => note.register === "high");
  return (
    <div className="space-y-6">
      <FluteConventionNote />
      <section className="space-y-3">
        <h3 className="font-semibold">
          Quãng trầm <span className="text-sm font-normal text-muted-foreground">· thổi nhẹ, hơi chậm</span>
        </h3>
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {low.map((note) => (
            <FluteNoteCard key={note.key} note={note} />
          ))}
        </div>
      </section>
      <section className="space-y-3">
        <h3 className="font-semibold">
          Quãng cao <span className="text-sm font-normal text-muted-foreground">· cùng thế bấm, hơi nhanh hơn, môi khép hẹp</span>
        </h3>
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {high.map((note) => (
            <FluteNoteCard key={note.key} note={note} />
          ))}
        </div>
      </section>
    </div>
  );
}
