import { describe, expect, it, vi } from "vitest";

import {
  ApiActivityStore,
  createMutationKey,
  isMutationMethod,
  MutationRequestGuard,
} from "./api-activity";

describe("ApiActivityStore", () => {
  it("theo dõi riêng request đọc và request ghi", () => {
    const store = new ApiActivityStore();
    const listener = vi.fn();
    store.subscribe(listener);

    const finishRead = store.begin(false);
    const finishWrite = store.begin(true);
    expect(store.getSnapshot()).toEqual({ pendingRequests: 2, pendingMutations: 1 });

    finishRead();
    finishRead();
    expect(store.getSnapshot()).toEqual({ pendingRequests: 1, pendingMutations: 1 });

    finishWrite();
    expect(store.getSnapshot()).toEqual({ pendingRequests: 0, pendingMutations: 0 });
    expect(listener).toHaveBeenCalledTimes(4);
  });
});

describe("MutationRequestGuard", () => {
  it("chặn cùng một mutation cho tới khi request trước hoàn tất", () => {
    const guard = new MutationRequestGuard();
    const release = guard.acquire("post:/orders:{portion:1}");

    expect(release).not.toBeNull();
    expect(guard.acquire("post:/orders:{portion:1}")).toBeNull();
    expect(guard.acquire("post:/orders:{portion:2}")).not.toBeNull();

    release?.();
    expect(guard.acquire("post:/orders:{portion:1}")).not.toBeNull();
  });

  it("tạo cùng khóa cho payload có thứ tự thuộc tính khác nhau", () => {
    const first = createMutationKey({ method: "POST", url: "/orders", data: { b: 2, a: 1 } });
    const second = createMutationKey({ method: "post", url: "/orders", data: { a: 1, b: 2 } });

    expect(first).toBe(second);
    expect(isMutationMethod("PATCH")).toBe(true);
    expect(isMutationMethod("GET")).toBe(false);
  });
});
