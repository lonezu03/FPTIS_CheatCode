import { act, renderHook } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { useServerPagination } from "./useServerPagination";

describe("useServerPagination", () => {
  it("chặn trang âm và trở về trang đầu khi đổi kích thước", () => {
    const { result } = renderHook(() => useServerPagination(20));

    act(() => result.current.setPage(4));
    expect(result.current.page).toBe(4);

    act(() => result.current.setPageSize(50));
    expect(result.current.page).toBe(1);
    expect(result.current.pageSize).toBe(50);

    act(() => result.current.setPage(-2));
    expect(result.current.page).toBe(1);
  });
});
