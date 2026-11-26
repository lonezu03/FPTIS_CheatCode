import api from "./axios";
import type { PageResponse } from "./pagination";

export type MusicInstrument = "GUITAR" | "FLUTE";

export type MusicSession = {
  id: string;
  instrument: MusicInstrument;
  /** YYYY-MM-DD */
  practicedOn: string;
  minutes: number;
  exerciseKey: string;
  bpm: number | null;
  note: string | null;
  createdAt: string;
};

export type MusicSessionInput = {
  instrument: MusicInstrument;
  practicedOn: string;
  /** 1..600 */
  minutes: number;
  /** [a-z0-9-] */
  exerciseKey: string;
  /** 20..300 */
  bpm?: number | null;
  /** ≤ 500 ký tự */
  note?: string | null;
};

export type MusicSessionFilters = {
  from?: string;
  to?: string;
  instrument?: MusicInstrument;
  page?: number;
  size?: number;
};

export type MusicDay = { date: string; guitarMinutes: number; fluteMinutes: number };

export type MusicBestBpm = { exerciseKey: string; instrument: MusicInstrument; bpm: number; practicedOn: string };

export type MusicSummary = {
  streakDays: number;
  todayMinutes: number;
  weekMinutes: number;
  weekByDay: MusicDay[];
  totalMinutesByInstrument: Record<MusicInstrument, number>;
  sessionsCount: number;
  bestBpmByExercise: MusicBestBpm[];
};

export const createMusicSession = async (body: MusicSessionInput): Promise<MusicSession> =>
  (await api.post("/music/sessions", body)).data;

export const getMusicSessions = async (filters: MusicSessionFilters = {}): Promise<PageResponse<MusicSession>> =>
  (await api.get("/music/sessions", { params: filters })).data;

export const deleteMusicSession = async (id: string): Promise<void> => {
  await api.delete(`/music/sessions/${id}`);
};

export const getMusicSummary = async (): Promise<MusicSummary> => (await api.get("/music/summary")).data;
