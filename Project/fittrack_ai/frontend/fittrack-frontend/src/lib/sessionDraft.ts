import { useAuthStore } from "@/store/auth.store";
import type { JournalMood } from "@/api/journal.api";

const prefix = "fittrack-session-draft:";
const lifetime = 12 * 60 * 60 * 1000;
const storageFor = (name: string) => name === "workout" ? localStorage : sessionStorage;

export function readSessionDraft<T>(owner: string, name: string): T | null {
  if (!owner || useAuthStore.getState().user?.userId !== owner) return null;
  try {
    const key = `${prefix}${owner}:${name}`;
    const storage = storageFor(name);
    const raw = storage.getItem(key);
    if (!raw) return null;
    const draft = JSON.parse(raw);
    if (draft.version !== 1 || !Number.isFinite(draft.savedAt) || Date.now() - draft.savedAt > (name === "workout" ? 7 * 24 * 60 * 60 * 1000 : lifetime)) {
      storage.removeItem(key);
      return null;
    }
    return draft.value as T;
  } catch { return null; }
}

const journalMoods = new Set(["VERY_LOW", "LOW", "NEUTRAL", "GOOD", "VERY_GOOD"]);
export type JournalTextDraft = { body: string; mood: JournalMood | null; title?: string; tagText?: string };
export function readJournalTextDraft(owner: string, name: string): JournalTextDraft | null {
  const draft = readSessionDraft<JournalTextDraft>(owner, name);
  if (draft == null) return null;
  const valid = typeof draft.body === "string" && draft.body.length <= 20000
    && (draft.mood === null || journalMoods.has(draft.mood))
    && (draft.title === undefined || (typeof draft.title === "string" && draft.title.length <= 255))
    && (draft.tagText === undefined || (typeof draft.tagText === "string" && draft.tagText.length <= 5000));
  if (!valid) { clearSessionDraft(owner, name); return null; }
  return draft;
}

export function writeSessionDraft(owner: string, name: string, value: unknown): boolean {
  if (!owner || useAuthStore.getState().user?.userId !== owner) return false;
  try {
    storageFor(name).setItem(`${prefix}${owner}:${name}`, JSON.stringify({ version: 1, savedAt: Date.now(), value }));
    return true;
  } catch { return false; }
}

export function clearSessionDraft(owner: string, name: string) {
  try { storageFor(name).removeItem(`${prefix}${owner}:${name}`); } catch { /* Storage may be unavailable. */ }
}

// Journal text stays in this tab only, and is removed when its account logs out
// or loses access. Never retain another account's writing on a shared device.
useAuthStore.subscribe((state, previous) => {
  if (previous.user && (state.user?.userId !== previous.user.userId || (!state.user.journalEnabled && state.user.role !== "ADMIN"))) {
    try {
      for (let index = sessionStorage.length - 1; index >= 0; index--) {
        const key = sessionStorage.key(index);
        if (key?.startsWith(`${prefix}${previous.user.userId}:`)) sessionStorage.removeItem(key);
      }
      if (state.user?.userId !== previous.user.userId) clearSessionDraft(previous.user.userId, "workout");
    } catch { /* Storage may be unavailable. */ }
  }
});
