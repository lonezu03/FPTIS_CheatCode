import { useState } from "react";

import { cn } from "@/lib/utils";
import { FINGER_EXERCISES, fingerPatternTab } from "./guitar-data";
import MetronomePanel from "./MetronomePanel";
import { QuickSaveBar, SectionCard, Segmented } from "./MusicParts";
import { useMetronome } from "./useMetronome";

const START_FRET = 5;

/** Spider / finger independence with a tab that follows the metronome note by note. */
export default function FingerExercises() {
  const [key, setKey] = useState(FINGER_EXERCISES[0].key);
  const exercise = FINGER_EXERCISES.find((item) => item.key === key) ?? FINGER_EXERCISES[0];
  const metronome = useMetronome({ bpm: exercise.startBpm });
  const tab = fingerPatternTab(exercise.pattern, START_FRET);
  const perString = exercise.pattern.length;
  const upCount = perString * 6;
  // Up from string 6 to 1, then back down from 1 to 6 (reversed finger order).
  const position = metronome.running && metronome.tick ? metronome.tick.index % (upCount * 2) : -1;
  const goingUp = position < upCount;
  const rowIndex = position < 0 ? -1 : goingUp ? Math.floor(position / perString) : 5 - Math.floor((position - upCount) / perString);
  const noteIndex = position < 0 ? -1 : goingUp ? position % perString : perString - 1 - ((position - upCount) % perString);

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
      <SectionCard
        title={exercise.name}
        description={exercise.description}
        action={
          <Segmented
            label="Bài tập ngón"
            value={key}
            onChange={(value) => {
              setKey(value);
              const next = FINGER_EXERCISES.find((item) => item.key === value);
              if (next) metronome.setBpm(next.startBpm);
            }}
            options={FINGER_EXERCISES.map((item) => ({ value: item.key, label: item.name }))}
          />
        }
      >
        <ol className="list-decimal space-y-1 pl-5 text-sm leading-6">
          {exercise.steps.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
        <div className="overflow-x-auto rounded-2xl border bg-muted/20 p-3">
          <p className="mb-2 text-xs text-muted-foreground">Ngăn đàn cần bấm (ngón {exercise.pattern.join("-")}). Ô sáng = nốt đang tới theo máy đếm nhịp.</p>
          <table className="w-full min-w-[320px] border-separate border-spacing-1 text-center text-sm">
            <thead>
              <tr className="text-xs text-muted-foreground">
                <th className="w-20 text-left font-medium">Dây</th>
                {exercise.pattern.map((finger, index) => (
                  <th key={index} className="font-medium">
                    Ngón {finger}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {tab.map((row, index) => (
                <tr key={row.string}>
                  <td className="text-left text-xs text-muted-foreground">Dây {row.string}</td>
                  {row.frets.map((fret, column) => (
                    <td
                      key={column}
                      className={cn(
                        "rounded-lg py-1.5 font-semibold tabular-nums transition-colors duration-75",
                        rowIndex === index && noteIndex === column ? "bg-emerald-500 text-white" : "bg-background",
                      )}
                    >
                      {fret}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
          {metronome.running && <p className="mt-2 text-xs text-muted-foreground">{goingUp ? "Đang đi lên (dây 6 → 1)" : "Đang đi xuống (dây 1 → 6, ngón ngược lại)"}</p>}
        </div>
      </SectionCard>
      <SectionCard title="Máy đếm nhịp" description="Bắt đầu ở tốc độ chơi sạch. Sạch 3 lượt liên tiếp thì tăng 5 BPM.">
        <MetronomePanel metronome={metronome} compact showSignature={false} />
        <QuickSaveBar instrument="GUITAR" exerciseKey={exercise.key} bpm={metronome.bpm} defaultMinutes={5} />
      </SectionCard>
    </div>
  );
}
