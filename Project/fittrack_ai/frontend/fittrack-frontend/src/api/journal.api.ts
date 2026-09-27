import api from "./axios";

export type JournalCategory = "OBSERVATION" | "SELF" | "MEMORY" | "IMAGINATION" | "REFLECTION" | "RELATIONSHIP" | "FUTURE" | "QUIRKY";
export type JournalDepth = "LIGHT" | "MEDIUM" | "DEEP";
export type JournalOrigin = "PROMPT" | "FREEFORM";
export type JournalMood = "VERY_LOW" | "LOW" | "NEUTRAL" | "GOOD" | "VERY_GOOD";
export type JournalPrompt = { id: string; content: string; category: JournalCategory; depth: JournalDepth; active: boolean };
export type JournalEntry = { id: string; entryDate: string; origin: JournalOrigin; prompt: JournalPrompt | null; title: string | null; body: string; mood: JournalMood | null; createdAt: string; updatedAt: string };
export type JournalToday = { date: string; prompt: JournalPrompt; answered: boolean; entry: JournalEntry | null };
export type JournalEntryInput = { origin: JournalOrigin; promptId?: string | null; entryDate?: string; title?: string; body: string; mood?: JournalMood | null };
export type JournalSettings = { reminderEnabled: boolean; reminderTime: string };
export type PageResponse<T> = { content: T[]; page: number; size: number; totalElements: number; totalPages: number; first: boolean; last: boolean };

export const getJournalToday = async () => (await api.get<JournalToday>("/journal/today")).data;
export const skipJournalPrompt = async () => (await api.post<JournalToday>("/journal/today/skip")).data;
export const getJournalEntries = async (params: Record<string, string | number | undefined>) => (await api.get<PageResponse<JournalEntry>>("/journal/entries", { params })).data;
export const createJournalEntry = async (payload: JournalEntryInput) => (await api.post<JournalEntry>("/journal/entries", payload)).data;
export const updateJournalEntry = async (id: string, payload: JournalEntryInput) => (await api.put<JournalEntry>(`/journal/entries/${id}`, payload)).data;
export const deleteJournalEntry = async (id: string) => { await api.delete(`/journal/entries/${id}`); };
export const getJournalPrompts = async (params: Record<string, string | number | undefined>) => (await api.get<PageResponse<JournalPrompt>>("/journal/prompts", { params })).data;
export const getJournalSettings = async () => (await api.get<JournalSettings>("/journal/settings")).data;
export const updateJournalSettings = async (payload: JournalSettings) => (await api.put<JournalSettings>("/journal/settings", payload)).data;

export const getAdminJournalPrompts = async (params: Record<string, string | number | boolean | undefined>) => (await api.get<PageResponse<JournalPrompt>>("/admin/journal/prompts", { params })).data;
export const createAdminJournalPrompt = async (payload: Omit<JournalPrompt, "id">) => (await api.post<JournalPrompt>("/admin/journal/prompts", payload)).data;
export const updateAdminJournalPrompt = async (id: string, payload: Omit<JournalPrompt, "id">) => (await api.put<JournalPrompt>(`/admin/journal/prompts/${id}`, payload)).data;
