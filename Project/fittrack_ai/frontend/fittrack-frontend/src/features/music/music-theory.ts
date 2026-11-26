/** Note and frequency math (12-tone equal temperament, A4 = 440 Hz). */

export const A4_HZ = 440;
export const A4_MIDI = 69;

export const NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"] as const;
export type NoteName = (typeof NOTE_NAMES)[number];

/** Vietnamese solfège for each pitch class (sharps written with #). */
export const SOLFEGE: Record<NoteName, string> = {
  C: "Đô",
  "C#": "Đô#",
  D: "Rê",
  "D#": "Rê#",
  E: "Mi",
  F: "Fa",
  "F#": "Fa#",
  G: "Sol",
  "G#": "Sol#",
  A: "La",
  "A#": "La#",
  B: "Si",
};

export function midiToFrequency(midi: number): number {
  return A4_HZ * 2 ** ((midi - A4_MIDI) / 12);
}

/** Fractional MIDI number of a frequency. */
export function frequencyToMidi(frequency: number): number {
  return A4_MIDI + 12 * Math.log2(frequency / A4_HZ);
}

export function midiToName(midi: number): { name: NoteName; octave: number; label: string; solfege: string } {
  const rounded = Math.round(midi);
  const name = NOTE_NAMES[((rounded % 12) + 12) % 12];
  const octave = Math.floor(rounded / 12) - 1;
  return { name, octave, label: `${name}${octave}`, solfege: SOLFEGE[name] };
}

/** "C5" → 72, "F#3" → 54. Returns null for anything else. */
export function noteToMidi(note: string): number | null {
  const match = /^([A-G])(#?)(-?\d)$/.exec(note.trim());
  if (!match) return null;
  const index = NOTE_NAMES.indexOf(`${match[1]}${match[2]}` as NoteName);
  if (index < 0) return null;
  return (Number(match[3]) + 1) * 12 + index;
}

export function noteToFrequency(note: string): number | null {
  const midi = noteToMidi(note);
  return midi === null ? null : midiToFrequency(midi);
}

/** Cents from `target` to `frequency` (positive = sharp / cao hơn). */
export function centsBetween(frequency: number, target: number): number {
  return 1200 * Math.log2(frequency / target);
}

export type NearestNote = {
  midi: number;
  name: NoteName;
  octave: number;
  label: string;
  solfege: string;
  /** Exact frequency of the nearest note. */
  target: number;
  cents: number;
};

export function nearestNote(frequency: number): NearestNote {
  const midi = Math.round(frequencyToMidi(frequency));
  const target = midiToFrequency(midi);
  return { midi, ...midiToName(midi), target, cents: centsBetween(frequency, target) };
}

/** Cents considered "in tune" for a beginner. */
export const IN_TUNE_CENTS = 5;
export const CLOSE_CENTS = 20;

export type TuneState = "in-tune" | "close" | "low" | "high";

export function tuneState(cents: number): TuneState {
  const abs = Math.abs(cents);
  if (abs <= IN_TUNE_CENTS) return "in-tune";
  if (abs <= CLOSE_CENTS) return "close";
  return cents < 0 ? "low" : "high";
}

export function formatHz(frequency: number): string {
  return `${frequency.toFixed(2).replace(".", ",")} Hz`;
}
