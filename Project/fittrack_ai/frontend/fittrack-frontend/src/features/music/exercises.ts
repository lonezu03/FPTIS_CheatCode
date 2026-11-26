import type { MusicInstrument } from "@/api/music.api";
import { findChord, parseOneMinuteKey } from "./guitar-data";

export type ExerciseInfo = { key: string; instrument: MusicInstrument; label: string; usesBpm: boolean };

export const EXERCISES: ExerciseInfo[] = [
  { key: "guitar-warmup", instrument: "GUITAR", label: "Khởi động tay", usesBpm: false },
  { key: "guitar-spider", instrument: "GUITAR", label: "Spider 1-2-3-4", usesBpm: true },
  { key: "guitar-finger-independence", instrument: "GUITAR", label: "Độc lập ngón", usesBpm: true },
  { key: "guitar-chord-change", instrument: "GUITAR", label: "Đổi hợp âm", usesBpm: true },
  { key: "guitar-strumming", instrument: "GUITAR", label: "Tiết tấu quạt dây", usesBpm: true },
  { key: "guitar-song", instrument: "GUITAR", label: "Đệm bài hát", usesBpm: true },
  { key: "flute-warmup", instrument: "FLUTE", label: "Khởi động hơi thở", usesBpm: false },
  { key: "flute-long-tones", instrument: "FLUTE", label: "Ngân dài", usesBpm: false },
  { key: "flute-scale", instrument: "FLUTE", label: "Thang âm lên xuống", usesBpm: true },
  { key: "flute-note-reading", instrument: "FLUTE", label: "Đọc nốt", usesBpm: false },
  { key: "flute-song", instrument: "FLUTE", label: "Thổi bài hát", usesBpm: true },
];

export const INSTRUMENT_LABEL: Record<MusicInstrument, string> = { GUITAR: "Ghi-ta", FLUTE: "Sáo trúc" };

export const EXERCISE_KEY_PATTERN = /^[a-z0-9-]+$/;

export function exercisesFor(instrument: MusicInstrument): ExerciseInfo[] {
  return EXERCISES.filter((exercise) => exercise.instrument === instrument);
}

export function exerciseLabel(key: string): string {
  const known = EXERCISES.find((exercise) => exercise.key === key);
  if (known) return known.label;
  const pair = parseOneMinuteKey(key);
  if (pair) {
    const [a, b] = pair.map((chordKey) => findChord(chordKey)?.name.replace(" (đơn giản)", "") ?? chordKey.toUpperCase());
    return `Đổi hợp âm 1 phút: ${a} ↔ ${b}`;
  }
  return key;
}

export function instrumentOfExercise(key: string): MusicInstrument | null {
  if (key.startsWith("guitar-")) return "GUITAR";
  if (key.startsWith("flute-")) return "FLUTE";
  return null;
}
