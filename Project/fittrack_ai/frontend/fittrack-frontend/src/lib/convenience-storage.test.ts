import { beforeEach, describe, expect, it, vi } from "vitest";
import { readConvenience, writeConvenience } from "./convenience-storage";

const valid = (value: unknown): value is { amount: number } => Boolean(value && typeof value === "object" && "amount" in value && typeof value.amount === "number");

describe("optional owner-scoped convenience storage", () => {
  beforeEach(() => { localStorage.clear(); vi.restoreAllMocks(); });
  it("keeps drafts isolated and expires them after seven days", () => {
    writeConvenience("fittrack:finance-draft:alice", { amount: 35000 });
    expect(readConvenience("fittrack:finance-draft:bob", valid)).toBeNull();
    expect(readConvenience("fittrack:finance-draft:alice", valid)).toEqual({ amount: 35000 });
    vi.spyOn(Date, "now").mockReturnValue(Date.now() + 8 * 86400000);
    expect(readConvenience("fittrack:finance-draft:alice", valid)).toBeNull();
  });
  it("ignores malformed drafts and tolerates unavailable storage", () => {
    localStorage.setItem("fittrack:finance-draft:alice", '{"amount":"invalid"}');
    expect(readConvenience("fittrack:finance-draft:alice", valid)).toBeNull();
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => { throw new Error("quota"); });
    expect(() => writeConvenience("fittrack:finance-draft:alice", { amount: 1 })).not.toThrow();
  });
});
