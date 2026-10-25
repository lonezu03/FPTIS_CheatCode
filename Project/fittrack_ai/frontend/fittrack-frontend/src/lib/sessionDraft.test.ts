// @vitest-environment jsdom
import { beforeEach, describe, expect, it, vi } from "vitest";
import { clearSessionDraft, readJournalTextDraft, readSessionDraft, writeSessionDraft } from "./sessionDraft";
import { useAuthStore, type AuthUser } from "@/store/auth.store";

const user = { userId: "owner", journalEnabled: true } as AuthUser;
beforeEach(() => {
  sessionStorage.clear();
  localStorage.clear();
  useAuthStore.setState({ user });
  vi.useRealTimers();
});

describe("tab-scoped drafts", () => {
  it("rejects corrupted sensitive draft fields", () => {
    for (const draft of [{ body: {}, mood: null }, { body: "text", mood: "INVALID" }, { body: "text", mood: null, title: [] }, { body: "text", mood: null, tagText: {} }]) {
      writeSessionDraft("owner", "journal-entry:new", draft);
      expect(readJournalTextDraft("owner", "journal-entry:new")).toBeNull();
    }
  });
  it("isolates owners and removes drafts on logout", () => {
    expect(writeSessionDraft("owner", "journal-entry:new", { body: "private" })).toBe(true);
    expect(writeSessionDraft("other", "journal-entry:new", { body: "wrong" })).toBe(false);
    expect(readSessionDraft("other", "journal-entry:new")).toBeNull();
    useAuthStore.getState().logout();
    expect(readSessionDraft("owner", "journal-entry:new")).toBeNull();
  });
  it("expires drafts after twelve hours and supports explicit discard", () => {
    vi.useFakeTimers();
    writeSessionDraft("owner", "journal-entry:new", { title: "draft" });
    expect(readSessionDraft("owner", "journal-entry:new")).toEqual({ title: "draft" });
    vi.advanceTimersByTime(12 * 60 * 60 * 1000 + 1);
    expect(readSessionDraft("owner", "journal-entry:new")).toBeNull();
    writeSessionDraft("owner", "workout", {});
    clearSessionDraft("owner", "workout");
    expect(readSessionDraft("owner", "workout")).toBeNull();
  });
  it("clears sensitive drafts when journal access is revoked", () => {
    writeSessionDraft("owner", "journal-entry:new", { body: "private" });
    useAuthStore.setState({ user: { ...user, journalEnabled: false } });
    expect(readSessionDraft("owner", "journal-entry:new")).toBeNull();
  });
  it("keeps workout drafts after a tab closes but expires them after seven days", () => {
    vi.useFakeTimers();
    writeSessionDraft("owner", "workout", { title: "draft" });
    sessionStorage.clear();
    expect(readSessionDraft("owner", "workout")).toEqual({ title: "draft" });
    vi.advanceTimersByTime(7 * 24 * 60 * 60 * 1000 + 1);
    expect(readSessionDraft("owner", "workout")).toBeNull();
  });
});
