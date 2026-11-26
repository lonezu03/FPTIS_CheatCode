import type { MusicBestBpm, MusicInstrument } from "@/api/music.api";
import { CHORD_CHANGE_PAIRS, FINGER_EXERCISES, findChord, STRUM_PATTERNS } from "./guitar-data";
import { FLUTE_SONGS } from "./flute-data";

export type RoutineStep = {
  id: string;
  title: string;
  minutes: number;
  exerciseKey: string;
  /** What to do, one short line per item. */
  how: string[];
  /** Suggested metronome tempo, when the step uses one. */
  bpm?: number;
  /** Link to the page section with the tool for this step. */
  link?: string;
};

export type Routine = { instrument: MusicInstrument; totalMinutes: number; steps: RoutineStep[] };

export const ROUTINE_LENGTHS = [15, 20] as const;
export type RoutineLength = (typeof ROUTINE_LENGTHS)[number];

/** Whole days since 1970-01-01 in local time, used to rotate exercises day by day. */
export function dayNumber(date: Date = new Date()): number {
  return Math.floor(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / 86_400_000);
}

/** Next tempo to try: last best + 5 (clean playing first), otherwise the starting tempo. */
export function suggestBpm(exerciseKey: string, best: MusicBestBpm[], start: number): number {
  // Records are grouped by (exerciseKey, instrument); our keys carry the instrument prefix.
  const instrument = exerciseKey.startsWith("flute-") ? "FLUTE" : "GUITAR";
  const record = best.find((item) => item.exerciseKey === exerciseKey && item.instrument === instrument);
  if (!record) return start;
  return Math.min(208, Math.max(40, record.bpm + 5));
}

const SPLITS: Record<RoutineLength, [number, number, number, number]> = {
  15: [2, 4, 5, 4],
  20: [3, 5, 6, 6],
};

function chordName(key: string) {
  return findChord(key)?.name.replace(" (đơn giản)", "") ?? key.toUpperCase();
}

export function buildRoutine(instrument: MusicInstrument, length: RoutineLength, day: number, best: MusicBestBpm[] = []): Routine {
  const [warm, technique, core, music] = SPLITS[length];
  const steps = instrument === "GUITAR" ? guitarSteps(warm, technique, core, music, day, best) : fluteSteps(warm, technique, core, music, day, best);
  return { instrument, totalMinutes: steps.reduce((sum, step) => sum + step.minutes, 0), steps };
}

function guitarSteps(warm: number, technique: number, core: number, music: number, day: number, best: MusicBestBpm[]): RoutineStep[] {
  const finger = FINGER_EXERCISES[day % FINGER_EXERCISES.length];
  // Beginners stay on the five easiest pairs for the first rotation days.
  const pair = CHORD_CHANGE_PAIRS[day % 6];
  const pattern = STRUM_PATTERNS[day % 3];
  return [
    {
      id: "warmup",
      title: "Khởi động",
      minutes: warm,
      exerciseKey: "guitar-warmup",
      how: ["Xoay cổ tay, mở nắm bàn tay 10 lần.", "Lên dây bằng máy lên dây.", "Bấm thử từng ngón ở ngăn 5, nghe dây kêu rõ."],
      link: "/music/tools",
    },
    {
      id: "finger",
      title: finger.name,
      minutes: technique,
      exerciseKey: finger.key,
      how: [finger.description, "Mỗi tiếng máy đếm nhịp là một nốt; dây rè thì chậm lại."],
      bpm: suggestBpm(finger.key, best, finger.startBpm),
      link: "/music/guitar?tab=fingers",
    },
    {
      id: "chords",
      title: `Đổi hợp âm ${chordName(pair[0])} ↔ ${chordName(pair[1])}`,
      minutes: core,
      exerciseKey: "guitar-chord-change",
      how: [
        "Đặt cả các ngón xuống cùng lúc, không đặt từng ngón.",
        "Quẹt 4 phách mỗi hợp âm, rồi 2 phách, rồi 1 phách.",
        "Cuối bước: thử “Đổi hợp âm 1 phút” để đo tiến bộ.",
      ],
      bpm: suggestBpm("guitar-chord-change", best, 50),
      link: "/music/guitar?tab=one-minute",
    },
    {
      id: "strum",
      title: `Tiết tấu: ${pattern.name}`,
      minutes: music,
      exerciseKey: "guitar-strumming",
      how: [pattern.description, `Áp vào vòng ${chordName(pair[0])} – ${chordName(pair[1])}, mỗi hợp âm 1 ô nhịp.`],
      bpm: suggestBpm("guitar-strumming", best, pattern.bpm),
      link: "/music/guitar?tab=strum",
    },
  ];
}

function fluteSteps(warm: number, technique: number, core: number, music: number, day: number, best: MusicBestBpm[]): RoutineStep[] {
  const song = FLUTE_SONGS[day % FLUTE_SONGS.length];
  return [
    {
      id: "warmup",
      title: "Khởi động hơi thở",
      minutes: warm,
      exerciseKey: "flute-warmup",
      how: ["Hít bụng 4 nhịp, giữ 2 nhịp, thở ra “xì” đều 8 nhịp. Lặp 5 lần.", "Thổi nốt Sol nhẹ để làm ấm sáo."],
    },
    {
      id: "long-tones",
      title: "Ngân dài",
      minutes: technique,
      exerciseKey: "flute-long-tones",
      how: ["Ngân từng nốt Đô → Si, giữ tiếng đều, không run.", "Đạt mục tiêu giây thì mục tiêu tự tăng 1 giây."],
      link: "/music/flute?tab=long-tones",
    },
    {
      id: "scale",
      title: "Thang âm lên xuống",
      minutes: core,
      exerciseKey: "flute-scale",
      how: ["Đô → Đô cao → Đô, mỗi tiếng máy đếm nhịp một nốt.", "Đổi ngón gọn, nhấc và đặt ngón cùng lúc."],
      bpm: suggestBpm("flute-scale", best, 60),
      link: "/music/flute?tab=scale",
    },
    {
      id: "song",
      title: `Bài: ${song.name}`,
      minutes: music,
      exerciseKey: "flute-song",
      how: [song.lines[0], "Thổi chậm từng câu, đúng nốt rồi mới nối câu."],
      bpm: suggestBpm("flute-song", best, 60),
      link: "/music/flute?tab=songs",
    },
  ];
}
