import api from "./axios";
import type { PageResponse } from "./pagination";

export type QuoteStatus = "ACTIVE" | "ARCHIVED";
export type QuoteSourceType =
  | "BOOK"
  | "ARTICLE"
  | "VIDEO"
  | "PODCAST"
  | "SONG"
  | "MOVIE"
  | "CONVERSATION"
  | "SOCIAL_POST"
  | "OTHER";

export type FavoriteQuote = {
  id: string;
  content: string;
  author: string | null;
  sourceType: QuoteSourceType | null;
  sourceTitle: string | null;
  sourceUrl: string | null;
  sourceLocation: string | null;
  personalNote: string | null;
  includeInDaily: boolean;
  status: QuoteStatus;
  language: string | null;
  tags: string[];
  createdAt: string;
  updatedAt: string;
  archivedAt: string | null;
};

export type QuotePayload = {
  content: string;
  author?: string;
  sourceType?: QuoteSourceType;
  sourceTitle?: string;
  sourceUrl?: string;
  sourceLocation?: string;
  personalNote?: string;
  includeInDaily: boolean;
  language?: string;
  tags: string[];
  allowDuplicate?: boolean;
};

export type DailyQuote = {
  displayDate: string;
  quote: FavoriteQuote | null;
};

export type QuoteDetail = {
  quote: FavoriteQuote;
  displayedDates: string[];
};

export type QuoteHistoryItem = {
  id: string;
  displayDate: string;
  cycleNumber: number;
  quote: FavoriteQuote;
};

export async function getQuotes(params: {
  q?: string;
  tag?: string;
  status?: QuoteStatus;
  page?: number;
  size?: number;
}): Promise<PageResponse<FavoriteQuote>> {
  const { data } = await api.get<PageResponse<FavoriteQuote>>("/quotes", { params });
  return data;
}

export async function getQuote(id: string): Promise<QuoteDetail> {
  const { data } = await api.get<QuoteDetail>(`/quotes/${id}`);
  return data;
}

export async function createQuote(payload: QuotePayload): Promise<FavoriteQuote> {
  const { data } = await api.post<FavoriteQuote>("/quotes", payload);
  return data;
}

export async function updateQuote(id: string, payload: QuotePayload): Promise<FavoriteQuote> {
  const { data } = await api.put<FavoriteQuote>(`/quotes/${id}`, payload);
  return data;
}

export async function checkQuoteDuplicate(
  content: string,
  excludedId?: string,
): Promise<{ duplicate: boolean; existingQuote: FavoriteQuote | null }> {
  const { data } = await api.post<{ duplicate: boolean; existingQuote: FavoriteQuote | null }>(
    "/quotes/check-duplicate",
    { content, excludedId },
  );
  return data;
}

export async function archiveQuote(id: string): Promise<FavoriteQuote> {
  const { data } = await api.post<FavoriteQuote>(`/quotes/${id}/archive`);
  return data;
}

export async function restoreQuote(id: string): Promise<FavoriteQuote> {
  const { data } = await api.post<FavoriteQuote>(`/quotes/${id}/restore`);
  return data;
}

export async function deleteQuote(id: string): Promise<void> {
  await api.delete(`/quotes/${id}`);
}

export async function getTodayQuote(): Promise<DailyQuote> {
  const { data } = await api.get<DailyQuote>("/quotes/today");
  return data;
}

export async function getQuoteHistory(page = 0, size = 30): Promise<PageResponse<QuoteHistoryItem>> {
  const { data } = await api.get<PageResponse<QuoteHistoryItem>>("/quotes/history", {
    params: { page, size },
  });
  return data;
}

export async function getQuoteTags(): Promise<string[]> {
  const { data } = await api.get<string[]>("/quote-tags");
  return data;
}
