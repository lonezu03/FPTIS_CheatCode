import type { MusicDay, MusicInstrument, MusicSessionInput } from "@/api/music.api";
import { EXERCISE_KEY_PATTERN } from "./exercises";

export type SessionForm = {
  instrument: MusicInstrument;
  practicedOn: string;
  minutes: string;
  exerciseKey: string;
  bpm: string;
  note: string;
};

export type SessionFormErrors = Partial<Record<keyof SessionForm, string>>;

/** Validates the quick-log form against the API contract and builds the request body. */
export function toSessionInput(form: SessionForm): { input: MusicSessionInput | null; errors: SessionFormErrors } {
  const errors: SessionFormErrors = {};
  const minutes = Number(form.minutes);
  if (!form.minutes.trim() || !Number.isInteger(minutes) || minutes < 1 || minutes > 600) errors.minutes = "Nhập số phút từ 1 đến 600.";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(form.practicedOn)) errors.practicedOn = "Chọn ngày tập.";
  if (!EXERCISE_KEY_PATTERN.test(form.exerciseKey)) errors.exerciseKey = "Chọn bài tập.";
  let bpm: number | null = null;
  if (form.bpm.trim()) {
    bpm = Number(form.bpm);
    if (!Number.isInteger(bpm) || bpm < 20 || bpm > 300) errors.bpm = "BPM từ 20 đến 300, hoặc để trống.";
  }
  const note = form.note.trim();
  if (note.length > 500) errors.note = "Ghi chú tối đa 500 ký tự.";
  if (Object.keys(errors).length) return { input: null, errors };
  return {
    input: { instrument: form.instrument, practicedOn: form.practicedOn, minutes, exerciseKey: form.exerciseKey, bpm, note: note || null },
    errors,
  };
}

/** "Đổi hợp âm 1 phút": the count only fits the BPM field when it is inside 20..300. */
export function oneMinuteResultBody(count: number): { bpm: number | null; note: string } {
  return { bpm: count >= 20 && count <= 300 ? count : null, note: `${count} lần đổi trong 1 phút` };
}

const WEEKDAY = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];

export function weekdayLabel(date: string): string {
  const [year, month, day] = date.split("-").map(Number);
  return WEEKDAY[new Date(year, month - 1, day).getDay()];
}

export type WeekBar = MusicDay & { total: number; label: string; guitarPct: number; flutePct: number };

/** Bars scaled to the busiest day (minimum scale 20 minutes so one short day is not a full bar). */
export function weekBars(days: MusicDay[]): { bars: WeekBar[]; max: number } {
  const max = Math.max(20, ...days.map((day) => day.guitarMinutes + day.fluteMinutes));
  const bars = days.map((day) => ({
    ...day,
    total: day.guitarMinutes + day.fluteMinutes,
    label: weekdayLabel(day.date),
    guitarPct: (day.guitarMinutes / max) * 100,
    flutePct: (day.fluteMinutes / max) * 100,
  }));
  return { bars, max };
}

export function formatMinutes(minutes: number): string {
  if (minutes < 60) return `${minutes} phút`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return rest ? `${hours} giờ ${rest} phút` : `${hours} giờ`;
}

export function formatClock(totalSeconds: number): string {
  const safe = Math.max(0, Math.ceil(totalSeconds));
  const minutes = Math.floor(safe / 60);
  const seconds = safe % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

/** Practice minutes from elapsed seconds: at least 1, rounded to the nearest minute. */
export function secondsToPracticeMinutes(seconds: number): number {
  return Math.min(600, Math.max(1, Math.round(seconds / 60)));
}

export function streakMessage(streak: number, todayMinutes: number): string {
  if (streak === 0) return todayMinutes > 0 ? "Bắt đầu chuỗi ngày tập!" : "Tập 5 phút hôm nay để bắt đầu chuỗi.";
  if (todayMinutes === 0) return "Tập hôm nay để giữ chuỗi.";
  if (streak < 7) return "Giữ nhịp mỗi ngày nhé.";
  return "Tuyệt vời, tay đã quen đàn rồi.";
}
