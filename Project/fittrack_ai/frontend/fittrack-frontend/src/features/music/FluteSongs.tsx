import { useState } from "react";

import { cn } from "@/lib/utils";
import { FLUTE_LOW_NOTES, FLUTE_SONGS } from "./flute-data";
import FluteFingering from "./FluteFingering";
import MetronomePanel from "./MetronomePanel";
import { QuickSaveBar, SectionCard } from "./MusicParts";
import { useMetronome } from "./useMetronome";

const bySolfege = new Map(FLUTE_LOW_NOTES.map((note) => [note.solfege, note]));

/** Short public-domain tunes inside Đô–La; tap a note to see its fingering. */
export default function FluteSongs() {
  const [songKey, setSongKey] = useState(FLUTE_SONGS[0].key);
  const [noteKey, setNoteKey] = useState("do");
  const metronome = useMetronome({ bpm: 60 });
  const song = FLUTE_SONGS.find((item) => item.key === songKey) ?? FLUTE_SONGS[0];
  const shown = FLUTE_LOW_NOTES.find((note) => note.key === noteKey) ?? FLUTE_LOW_NOTES[0];

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
      <SectionCard title="Bài dễ cho người mới" description="Mỗi nốt một phách, “–” là ngân thêm một phách, “|” là ngắt ô nhịp. Chạm vào nốt để xem thế bấm.">
        <div className="flex flex-wrap gap-2">
          {FLUTE_SONGS.map((item) => (
            <button
              key={item.key}
              type="button"
              aria-pressed={item.key === songKey}
              onClick={() => setSongKey(item.key)}
              className={cn("rounded-full border px-3 py-1.5 text-sm font-medium", item.key === songKey ? "border-emerald-600 bg-emerald-50 text-emerald-800" : "text-muted-foreground hover:bg-muted")}
            >
              {item.name}
            </button>
          ))}
        </div>
        <div className="space-y-2">
          {song.lines.map((line, lineIndex) => (
            <div key={lineIndex} className="flex flex-wrap gap-1">
              {line.split(/\s+/).map((token, index) => {
                const note = bySolfege.get(token);
                return note ? (
                  <button
                    key={index}
                    type="button"
                    onClick={() => setNoteKey(note.key)}
                    className={cn("min-w-10 rounded-lg px-2 py-1 text-sm font-medium", note.key === noteKey ? "bg-emerald-600 text-white" : "bg-muted hover:bg-muted/70")}
                  >
                    {token}
                  </button>
                ) : (
                  <span key={index} className="px-1 py-1 text-sm text-muted-foreground">
                    {token}
                  </span>
                );
              })}
            </div>
          ))}
        </div>
        <div className="rounded-2xl border bg-muted/20 p-3">
          <p className="text-sm font-medium">
            Thế bấm {shown.solfege} ({shown.note})
          </p>
          <FluteFingering note={shown} compact />
        </div>
      </SectionCard>
      <SectionCard title="Giữ nhịp" description="Thổi chậm theo máy đếm nhịp; đúng nốt trước, nhanh sau.">
        <MetronomePanel metronome={metronome} compact />
        <QuickSaveBar instrument="FLUTE" exerciseKey="flute-song" bpm={metronome.bpm} defaultMinutes={5} note={`Bài ${song.name}`} />
      </SectionCard>
    </div>
  );
}
