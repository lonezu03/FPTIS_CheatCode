import { centsBetween, noteToFrequency } from "./music-theory";

/** Beginner guitar data: standard tuning, open chords, finger exercises, strumming patterns. */

/** Standard tuning from string 6 (low E) to string 1 (high E). */
export const GUITAR_STRINGS = [
  { string: 6, note: "E2", label: "Mi trầm (dây 6)" },
  { string: 5, note: "A2", label: "La (dây 5)" },
  { string: 4, note: "D3", label: "Rê (dây 4)" },
  { string: 3, note: "G3", label: "Sol (dây 3)" },
  { string: 2, note: "B3", label: "Si (dây 2)" },
  { string: 1, note: "E4", label: "Mi cao (dây 1)" },
] as const;

export const STRING_TARGETS = GUITAR_STRINGS.map((item) => ({ ...item, frequency: noteToFrequency(item.note)! }));

/** Nearest guitar string to a frequency (by cents), for the tuner's "auto" mode. */
export function nearestGuitarString(frequency: number) {
  return STRING_TARGETS.reduce((best, item) =>
    Math.abs(centsBetween(frequency, item.frequency)) < Math.abs(centsBetween(frequency, best.frequency)) ? item : best,
  );
}

/** MIDI numbers of the open strings, string 6 → 1. */
export const STANDARD_TUNING_MIDI = [40, 45, 50, 55, 59, 64] as const;

export type ChordQuality = "major" | "minor" | "dominant7";

export type Chord = {
  /** Lowercase key used in exercise keys, e.g. "am". */
  key: string;
  name: string;
  /** Root pitch class (0 = C). */
  root: number;
  quality: ChordQuality;
  /** Fret per string 6 → 1: -1 muted, 0 open, n fret. */
  frets: readonly [number, number, number, number, number, number];
  /** Left-hand finger per string 6 → 1: 0 none, 1 index … 4 pinky. */
  fingers: readonly [number, number, number, number, number, number];
  /** One finger pressing several strings (string numbers, high → low). */
  barre?: { fret: number; fromString: number; toString: number; finger: number };
  level: 1 | 2 | 3;
  tip: string;
};

export const CHORDS: Chord[] = [
  { key: "em", name: "Em", root: 4, quality: "minor", frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0], level: 1, tip: "Dễ nhất: hai ngón, quẹt cả 6 dây." },
  { key: "am", name: "Am", root: 9, quality: "minor", frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0], level: 1, tip: "Không quẹt dây 6. Giống hình E dời xuống một dây." },
  { key: "e", name: "E", root: 4, quality: "major", frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0], level: 1, tip: "Thêm ngón 1 vào Em là thành E." },
  { key: "c", name: "C", root: 0, quality: "major", frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0], level: 1, tip: "Cong ngón để dây 3 và dây 1 vẫn kêu." },
  { key: "g", name: "G", root: 7, quality: "major", frets: [3, 2, 0, 0, 0, 3], fingers: [2, 1, 0, 0, 0, 3], level: 1, tip: "Ba ngón trải rộng; quẹt cả 6 dây." },
  { key: "d", name: "D", root: 2, quality: "major", frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2], level: 1, tip: "Chỉ quẹt 4 dây cao (từ dây 4)." },
  { key: "a", name: "A", root: 9, quality: "major", frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0], level: 2, tip: "Ba ngón xếp sát nhau trên ngăn 2; dây 1 để buông." },
  { key: "dm", name: "Dm", root: 2, quality: "minor", frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1], level: 2, tip: "Quẹt từ dây 4. Ngón 1 ở ngăn 1 dây 1." },
  {
    key: "f",
    name: "F (đơn giản)",
    root: 5,
    quality: "major",
    frets: [-1, -1, 3, 2, 1, 1],
    fingers: [0, 0, 3, 2, 1, 1],
    barre: { fret: 1, fromString: 1, toString: 2, finger: 1 },
    level: 3,
    tip: "Ngón 1 chặn 2 dây cao ở ngăn 1, chỉ quẹt 4 dây. Bản đầy đủ học sau.",
  },
  { key: "e7", name: "E7", root: 4, quality: "dominant7", frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0], level: 1, tip: "Bỏ ngón 3 khỏi hợp âm E." },
  { key: "a7", name: "A7", root: 9, quality: "dominant7", frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 2, 0, 3, 0], level: 1, tip: "Hai ngón; dây 3 để buông." },
  { key: "d7", name: "D7", root: 2, quality: "dominant7", frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3], level: 2, tip: "Hình tam giác ngược của D. Quẹt từ dây 4." },
];

export const CHORD_INTERVALS: Record<ChordQuality, number[]> = {
  major: [0, 4, 7],
  minor: [0, 3, 7],
  dominant7: [0, 4, 7, 10],
};

export function findChord(key: string): Chord | undefined {
  return CHORDS.find((chord) => chord.key === key);
}

/** Pitch classes actually sounded by a chord shape in standard tuning. */
export function chordPitchClasses(chord: Pick<Chord, "frets">): number[] {
  return chord.frets.flatMap((fret, index) => (fret < 0 ? [] : [(STANDARD_TUNING_MIDI[index] + fret) % 12]));
}

/** Lowest sounded string number (6..1), the first string to strum from. */
export function lowestPlayedString(chord: Pick<Chord, "frets">): number {
  const index = chord.frets.findIndex((fret) => fret >= 0);
  return 6 - index;
}

/** Suggested chord pairs for "đổi hợp âm 1 phút", easiest first. */
export const CHORD_CHANGE_PAIRS: [string, string][] = [
  ["em", "am"],
  ["am", "e"],
  ["c", "am"],
  ["g", "em"],
  ["d", "a"],
  ["g", "c"],
  ["c", "g"],
  ["g", "d"],
  ["a", "d"],
  ["e", "a"],
  ["d", "em"],
  ["am", "dm"],
  ["c", "f"],
];

export function oneMinuteExerciseKey(a: string, b: string): string {
  return `guitar-one-minute-${a}-${b}`;
}

/** Parses "guitar-one-minute-am-e" → ["am","e"]. */
export function parseOneMinuteKey(key: string): [string, string] | null {
  const match = /^guitar-one-minute-([a-z0-9]+)-([a-z0-9]+)$/.exec(key);
  return match ? [match[1], match[2]] : null;
}

/** One strum per eighth note in a 4/4 bar: D = down, U = up, "-" = hand moves without hitting. */
export type StrumSlot = "D" | "U" | "-";

export type StrumPattern = {
  key: string;
  name: string;
  slots: StrumSlot[];
  /** Strums per beat: 1 = quarter notes, 2 = eighth notes. */
  subdivision: 1 | 2;
  bpm: number;
  description: string;
};

export const STRUM_PATTERNS: StrumPattern[] = [
  { key: "quarter", name: "Bốn phách xuống", slots: ["D", "D", "D", "D"], subdivision: 1, bpm: 60, description: "Mỗi phách quẹt xuống một lần. Bắt đầu từ đây." },
  { key: "down-up", name: "Xuống – lên đều", slots: ["D", "U", "D", "U", "D", "U", "D", "U"], subdivision: 2, bpm: 60, description: "Tay luôn đưa lên xuống đều như con lắc." },
  { key: "basic", name: "Điệu cơ bản ↓ ↓↑ ↑↓↑", slots: ["D", "-", "D", "U", "-", "U", "D", "U"], subdivision: 2, bpm: 60, description: "Ở ô trống tay vẫn đưa xuống nhưng không chạm dây." },
  { key: "ballad", name: "Ballad ↓ ↓↑ ↓↑ ↓↑", slots: ["D", "-", "D", "U", "D", "U", "D", "U"], subdivision: 2, bpm: 70, description: "Nhấn nhẹ phách 1, các nhịp sau quẹt nhẹ." },
];

export const STRUM_ARROWS: Record<StrumSlot, string> = { D: "↓", U: "↑", "-": "·" };

export type FingerExercise = {
  key: string;
  name: string;
  description: string;
  /** Finger order played on every string. */
  pattern: number[];
  startBpm: number;
  steps: string[];
};

export const FINGER_EXERCISES: FingerExercise[] = [
  {
    key: "guitar-spider",
    name: "Spider 1-2-3-4",
    description: "Mỗi ngón một ngăn, đi từ dây 6 tới dây 1 rồi quay lại.",
    pattern: [1, 2, 3, 4],
    startBpm: 60,
    steps: [
      "Đặt ngón 1 ở ngăn 5 dây 6 (ngăn 5 hẹp hơn, dễ với hơn ngăn 1).",
      "Bấm lần lượt ngăn 5-6-7-8 bằng ngón 1-2-3-4, mỗi tiếng máy đếm nhịp là một nốt.",
      "Xong dây 6 chuyển sang dây 5, cứ thế tới dây 1; sau đó đi ngược 4-3-2-1.",
      "Giữ ngón đã bấm nằm yên trên phím khi bấm ngón tiếp theo nếu có thể.",
    ],
  },
  {
    key: "guitar-finger-independence",
    name: "Độc lập ngón 1-3-2-4",
    description: "Đổi thứ tự ngón để các ngón không kéo nhau.",
    pattern: [1, 3, 2, 4],
    startBpm: 50,
    steps: [
      "Cùng vị trí ngăn 5–8. Thứ tự: 1-3-2-4 trên mỗi dây.",
      "Khi trơn tru thử tiếp 1-2-4-3, rồi 1-4-3-2.",
      "Chậm và sạch quan trọng hơn nhanh: dây nào rè thì giảm 10 BPM.",
    ],
  },
];

/** Tab text for one pass of a finger pattern starting at `startFret`, strings 6 → 1. */
export function fingerPatternTab(pattern: number[], startFret = 5): { string: number; frets: number[] }[] {
  return [6, 5, 4, 3, 2, 1].map((string) => ({ string, frets: pattern.map((finger) => startFret + finger - 1) }));
}

export const GUITAR_TIPS: { title: string; text: string }[] = [
  { title: "Tư thế tay trái", text: "Ngón cái đặt sau cần đàn, ngang ngón giữa. Đầu ngón bấm sát phím đàn (thanh kim loại), cong ngón như cầm quả trứng." },
  { title: "Đau đầu ngón là bình thường", text: "1–3 tuần đầu đầu ngón sẽ rát rồi chai lại. Đau nhói ở cổ tay hoặc khớp thì dừng và nghỉ." },
  { title: "Ít mà đều", text: "15 phút mỗi ngày tốt hơn 2 tiếng mỗi cuối tuần. Ngón tay nhớ qua lặp lại hằng ngày." },
  { title: "Chậm để nhanh", text: "Tập theo máy đếm nhịp ở tốc độ chơi sạch được. Sạch 3 lần liên tiếp mới tăng 5 BPM." },
  { title: "Thả lỏng", text: "Bấm vừa đủ để dây kêu rõ. Vai, cổ tay, tay phải đều thả lỏng; nghỉ 1 phút khi thấy căng." },
  { title: "Lên dây mỗi lần tập", text: "Đàn lệch dây làm hợp âm nghe sai dù bấm đúng. Dùng máy lên dây trước khi tập." },
];
