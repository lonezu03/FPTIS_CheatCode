import { AxiosError, AxiosHeaders, type AxiosResponse } from "axios";
import { describe, expect, it, vi } from "vitest";
import { createSessionRefresher, isInvalidSessionError, SessionRefreshError } from "./session-refresh";

const httpError = (status: number, headers: Record<string, string> = {}) =>
  new AxiosError("fail", "ERR", undefined, undefined, {
    status,
    statusText: "",
    headers,
    config: { headers: new AxiosHeaders() },
    data: {},
  } as AxiosResponse);

const noSleep = () => Promise.resolve();
const noLock = <R,>(task: () => Promise<R>) => task();

describe("createSessionRefresher", () => {
  it("retries transient failures and then succeeds without ending the session", async () => {
    const post = vi.fn().mockRejectedValueOnce(httpError(503)).mockRejectedValueOnce(new AxiosError("Network Error")).mockResolvedValue("ok");
    const refresh = createSessionRefresher({ post, sleep: noSleep, lock: noLock });
    await expect(refresh()).resolves.toBe("ok");
    expect(post).toHaveBeenCalledTimes(3);
  });

  it("reports a transient failure (not an invalid session) after retries are exhausted", async () => {
    const post = vi.fn().mockRejectedValue(httpError(429));
    const refresh = createSessionRefresher({ post, sleep: noSleep, lock: noLock });
    const error = await refresh().catch((e: unknown) => e);
    expect(error).toBeInstanceOf(SessionRefreshError);
    expect((error as SessionRefreshError).sessionInvalid).toBe(false);
    expect(post).toHaveBeenCalledTimes(3);
  });

  it("stops immediately and marks the session invalid on 401", async () => {
    const post = vi.fn().mockRejectedValue(httpError(401));
    const refresh = createSessionRefresher({ post, sleep: noSleep, lock: noLock });
    const error = (await refresh().catch((e: unknown) => e)) as SessionRefreshError;
    expect(error.sessionInvalid).toBe(true);
    expect(post).toHaveBeenCalledTimes(1);
  });

  it("coalesces concurrent refreshes into one request", async () => {
    let resolve!: (value: string) => void;
    const post = vi.fn(() => new Promise<string>((r) => (resolve = r)));
    const refresh = createSessionRefresher({ post, sleep: noSleep, lock: noLock });
    const first = refresh();
    const second = refresh();
    await Promise.resolve();
    resolve("token");
    await expect(Promise.all([first, second])).resolves.toEqual(["token", "token"]);
    expect(post).toHaveBeenCalledTimes(1);
  });

  it("runs refreshes inside the cross-tab lock", async () => {
    const order: string[] = [];
    const lock = async <R,>(task: () => Promise<R>) => {
      order.push("lock");
      const result = await task();
      order.push("unlock");
      return result;
    };
    const refresh = createSessionRefresher({ post: async () => (order.push("post"), "ok"), sleep: noSleep, lock });
    await refresh();
    expect(order).toEqual(["lock", "post", "unlock"]);
  });

  it("honours Retry-After for rate limits, capped at 10 seconds", async () => {
    const sleep = vi.fn(noSleep);
    const post = vi.fn().mockRejectedValueOnce(httpError(429, { "retry-after": "60" })).mockResolvedValue("ok");
    await createSessionRefresher({ post, sleep, lock: noLock })();
    expect(sleep).toHaveBeenCalledWith(10_000);
  });
});

describe("isInvalidSessionError", () => {
  it("treats only 400/401/403 as an invalid session", () => {
    expect([400, 401, 403].map((s) => isInvalidSessionError(httpError(s)))).toEqual([true, true, true]);
    expect([408, 429, 500, 502, 503].map((s) => isInvalidSessionError(httpError(s)))).toEqual([false, false, false, false, false]);
    expect(isInvalidSessionError(new AxiosError("Network Error"))).toBe(false);
  });
});
