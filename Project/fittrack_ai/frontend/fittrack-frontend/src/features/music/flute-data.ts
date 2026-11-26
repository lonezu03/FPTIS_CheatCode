import { noteToFrequency } from "./music-theory";

/**
 * Fingerings for a 6-hole Vietnamese bamboo flute in C ("sáo Đô", lowest note C5).
 * Holes are numbered 1 → 6 from the mouth-hole end; `true` = covered.
 * Convention used: Đô covers all six holes and each next note opens one more hole
 * from the far end (hole 6 first). The upper octave uses the same fingerings with
 * faster, narrower air. Makers differ, so the UI asks users to compare.
 */
export type FluteNote = {
  key: string;
  solfege: string;
  note: string;
  register: "low" | "high";
  covered: readonly [boolean, boolean, boolean, boolean, boolean, boolean];
};

const SCALE: { key: string; solfege: string; pitch: string; open: number }[] = [
  { key: "do", solfege: "Đô", pitch: "C", open: 0 },
  { key: "re", solfege: "Rê", pitch: "D", open: 1 },
  { key: "mi", solfege: "Mi", pitch: "E", open: 2 },
  { key: "fa", solfege: "Fa", pitch: "F", open: 3 },
  { key: "sol", solfege: "Sol", pitch: "G", open: 4 },
  { key: "la", solfege: "La", pitch: "A", open: 5 },
  { key: "si", solfege: "Si", pitch: "B", open: 6 },
];

/** Holes covered when the last `open` holes (from hole 6 upwards) are open. */
export function coveredHoles(open: number): FluteNote["covered"] {
  const holes = [1, 2, 3, 4, 5, 6].map((hole) => hole <= 6 - open);
  return holes as unknown as FluteNote["covered"];
}

export const FLUTE_NOTES: FluteNote[] = [
  ...SCALE.map((step) => ({ key: step.key, solfege: step.solfege, note: `${step.pitch}5`, register: "low" as const, covered: coveredHoles(step.open) })),
  ...SCALE.map((step) => ({
    key: `${step.key}-cao`,
    solfege: `${step.solfege} cao`,
    note: `${step.pitch}6`,
    register: "high" as const,
    covered: coveredHoles(step.open),
  })),
];

export const FLUTE_LOW_NOTES = FLUTE_NOTES.filter((note) => note.register === "low");

/** Reference pitch of the flute's lowest note. */
export const FLUTE_BASE_NOTE = "C5";
export const FLUTE_BASE_HZ = noteToFrequency(FLUTE_BASE_NOTE) ?? 523.25;

export function findFluteNote(key: string): FluteNote | undefined {
  return FLUTE_NOTES.find((note) => note.key === key);
}

/** Scale drill: Đô → Đô cao → Đô, one note per beat. */
export function scaleSequence(withHighDo = true): FluteNote[] {
  const up = [...FLUTE_LOW_NOTES, ...(withHighDo ? [FLUTE_NOTES.find((note) => note.key === "do-cao")!] : [])];
  return [...up, ...up.slice(0, -1).reverse()];
}

/** Long-tone target: +1 s after a held note reaches the target, −1 s after two misses in a row. */
export const LONG_TONE_MIN = 4;
export const LONG_TONE_MAX = 30;

export function nextLongToneTarget(target: number, heldSeconds: number, missesInRow = 0): { target: number; success: boolean; missesInRow: number } {
  if (heldSeconds >= target) {
    return { target: Math.min(LONG_TONE_MAX, target + 1), success: true, missesInRow: 0 };
  }
  const misses = missesInRow + 1;
  if (misses >= 2) return { target: Math.max(LONG_TONE_MIN, target - 1), success: false, missesInRow: 0 };
  return { target, success: false, missesInRow: misses };
}

/** Random next note for the reading drill, never the same as the previous one. */
export function pickNextNote(pool: FluteNote[], previousKey: string | null, random: () => number = Math.random): FluteNote {
  const candidates = pool.length > 1 ? pool.filter((note) => note.key !== previousKey) : pool;
  return candidates[Math.min(candidates.length - 1, Math.floor(random() * candidates.length))];
}

/** Beginner songs that stay inside Đô–La (no low Sol, which a C5 flute cannot play). */
export const FLUTE_SONGS: { key: string; name: string; lines: string[] }[] = [
  {
    key: "twinkle",
    name: "Ngôi sao lấp lánh",
    lines: ["Đô Đô Sol Sol La La Sol –", "Fa Fa Mi Mi Rê Rê Đô –", "Sol Sol Fa Fa Mi Mi Rê –", "Sol Sol Fa Fa Mi Mi Rê –", "Đô Đô Sol Sol La La Sol –", "Fa Fa Mi Mi Rê Rê Đô –"],
  },
  {
    key: "ode-to-joy",
    name: "Khúc hoan ca (Beethoven)",
    lines: ["Mi Mi Fa Sol | Sol Fa Mi Rê", "Đô Đô Rê Mi | Mi – Rê Rê –", "Mi Mi Fa Sol | Sol Fa Mi Rê", "Đô Đô Rê Mi | Rê – Đô Đô –"],
  },
  {
    key: "mary",
    name: "Mary có chú cừu non",
    lines: ["Mi Rê Đô Rê | Mi Mi Mi –", "Rê Rê Rê – | Mi Sol Sol –", "Mi Rê Đô Rê | Mi Mi Mi Mi", "Rê Rê Mi Rê | Đô – – –"],
  },
];

export const FLUTE_TIPS: { title: string; text: string }[] = [
  { title: "Lấy hơi bằng bụng", text: "Hít vào bụng phình ra, thổi ra đều như thổi nhẹ ngọn nến cho nghiêng mà không tắt." },
  { title: "Bịt kín lỗ bằng bụng ngón", text: "Dùng phần thịt đầu ngón, không dùng đầu móng. Tiếng xì hoặc rè thường do hở lỗ." },
  { title: "Nốt trầm thổi nhẹ", text: "Đô, Rê trầm cần hơi chậm, môi mở rộng. Thổi mạnh quá sẽ nhảy lên quãng tám." },
  { title: "Quãng cao: hơi nhanh, môi hẹp", text: "Cùng thế bấm, khép môi hẹp lại và đẩy hơi nhanh hơn — không cần thổi to hơn." },
  { title: "Ngân dài mỗi ngày", text: "Ngân dài là bài tập quan trọng nhất cho tiếng sáo tròn và ổn định." },
  { title: "Nghỉ khi chóng mặt", text: "Thổi lâu dễ choáng do thở nhiều. Nghỉ vài nhịp thở bình thường rồi tập tiếp." },
];
