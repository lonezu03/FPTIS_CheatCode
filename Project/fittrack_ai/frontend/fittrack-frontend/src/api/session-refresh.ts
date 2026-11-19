import { isAxiosError } from "axios";

/**
 * Refresh-token handling shared by the startup bootstrap and the 401 interceptor.
 *
 * The backend rotates the refresh cookie on every use (single use, no grace
 * period), so two concurrent refreshes from different tabs make the slower one
 * fail with 401 and used to log the user out. Transient failures (network,
 * Render cold start 5xx, 408, 429 rate limit) also used to log the user out and
 * wipe the menu. This module:
 *  - serialises refreshes across tabs with the Web Locks API when available,
 *  - coalesces concurrent refreshes inside one tab,
 *  - retries transient failures with a short backoff, and
 *  - reports whether the session is really invalid (only then log out).
 */
export class SessionRefreshError extends Error {
  readonly sessionInvalid: boolean;

  constructor(sessionInvalid: boolean, cause: unknown) {
    super(
      sessionInvalid
        ? "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        : "Không kết nối được máy chủ để gia hạn phiên. Dữ liệu của bạn vẫn được giữ, vui lòng thử lại sau giây lát.",
      { cause },
    );
    this.name = "SessionRefreshError";
    this.sessionInvalid = sessionInvalid;
  }
}

/** 400 (no cookie), 401 and 403 mean the refresh cookie is missing, used, expired or revoked. */
export function isInvalidSessionError(error: unknown): boolean {
  if (!isAxiosError(error)) return false;
  const status = error.response?.status;
  return status === 400 || status === 401 || status === 403;
}

function retryDelayMs(error: unknown, attempt: number): number {
  const base = attempt === 0 ? 1_000 : 3_000;
  if (isAxiosError(error) && error.response?.status === 429) {
    const retryAfter = Number(error.response.headers?.["retry-after"]);
    if (Number.isFinite(retryAfter) && retryAfter > 0) return Math.min(retryAfter * 1_000, 10_000);
  }
  return base;
}

type RefresherOptions<T> = {
  post: () => Promise<T>;
  /** Number of retries after the first attempt for transient failures. */
  retries?: number;
  sleep?: (ms: number) => Promise<void>;
  lock?: <R>(task: () => Promise<R>) => Promise<R>;
};

const defaultSleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

export function browserRefreshLock<R>(task: () => Promise<R>): Promise<R> {
  const locks = typeof navigator !== "undefined" ? navigator.locks : undefined;
  if (!locks?.request) return task();
  return locks.request("fittrack-auth-refresh", { mode: "exclusive" }, task);
}

export function createSessionRefresher<T>({ post, retries = 2, sleep = defaultSleep, lock = browserRefreshLock }: RefresherOptions<T>) {
  let inFlight: Promise<T> | null = null;

  const attempt = async (): Promise<T> => {
    for (let index = 0; ; index++) {
      try {
        return await post();
      } catch (error) {
        if (isInvalidSessionError(error)) throw new SessionRefreshError(true, error);
        if (index >= retries) throw new SessionRefreshError(false, error);
        await sleep(retryDelayMs(error, index));
      }
    }
  };

  return function refreshSession(): Promise<T> {
    inFlight ??= lock(attempt).finally(() => {
      inFlight = null;
    });
    return inFlight;
  };
}
