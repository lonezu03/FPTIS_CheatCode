import { act, cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, expect, it, vi } from "vitest";
import { MemoryRouter } from "react-router-dom";
import JournalPage from "./JournalPage";
import * as journal from "@/api/journal.api";
import { useAuthStore, type AuthUser } from "@/store/auth.store";
import { readSessionDraft, writeSessionDraft } from "@/lib/sessionDraft";

vi.mock("@/api/journal.api", async (original) => ({
  ...await original<typeof import("@/api/journal.api")>(),
  getJournalLockStatus: vi.fn().mockResolvedValue({ lockEnabled: false }),
  getJournalSettings: vi.fn(),
  getJournalToday: vi.fn().mockResolvedValue({ prompt: { id: "prompt", content: "Câu hỏi hôm nay", category: "SELF", depth: "LIGHT" }, answered: false }),
  getJournalOnThisDay: vi.fn().mockResolvedValue([]),
  getJournalStats: vi.fn().mockResolvedValue({ writtenDays: 0, entryCount: 0, moodDays: [] }),
  getJournalEntries: vi.fn().mockResolvedValue({ content: [] }),
}));

afterEach(cleanup);

it("preserves prompt and entry drafts while privacy settings load, then permits recovery", async () => {
  sessionStorage.clear();
  useAuthStore.setState({ user: { userId: "journal-owner", journalEnabled: true } as AuthUser });
  writeSessionDraft("journal-owner", "journal-prompt:prompt", { body: "Bản nháp câu trả lời", mood: null });
  writeSessionDraft("journal-owner", "journal-entry:new", { body: "Bản nháp riêng tư", title: "Tiêu đề", mood: null, tagText: "" });
  let resolveSettings!: (settings: journal.JournalSettings) => void;
  vi.mocked(journal.getJournalSettings).mockImplementation(() => new Promise(resolve => { resolveSettings = resolve; }));
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(<QueryClientProvider client={client}><MemoryRouter initialEntries={["/journal?action=new"]}><JournalPage /></MemoryRouter></QueryClientProvider>);
  expect(await screen.findByText("Câu hỏi hôm nay")).toBeInTheDocument();
  expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  expect(readSessionDraft("journal-owner", "journal-prompt:prompt")).not.toBeNull();
  expect(readSessionDraft("journal-owner", "journal-entry:new")).not.toBeNull();
  await act(async () => { resolveSettings({ lockEnabled: false, reminderEnabled: false, reminderTime: "21:30", personalizedPromptsEnabled: false, aiFollowUpEnabled: false }); });
  const dialog = within(await screen.findByRole("dialog"));
  fireEvent.click(dialog.getByRole("button", { name: "Khôi phục nháp" }));
  expect(dialog.getByRole("textbox", { name: /Nội dung nhật ký/ })).toHaveValue("Bản nháp riêng tư");
  expect(readSessionDraft("journal-owner", "journal-prompt:prompt")).not.toBeNull();
});
