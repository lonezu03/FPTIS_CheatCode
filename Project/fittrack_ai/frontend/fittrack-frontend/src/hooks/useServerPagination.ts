import { useState } from "react";

export function useServerPagination(initialPageSize = 20) {
  const [page, setPageState] = useState(1);
  const [pageSize, setPageSizeState] = useState(initialPageSize);
  const setPage = (value: number) => setPageState(Math.max(value, 1));
  const setPageSize = (value: number) => {
    setPageSizeState(value);
    setPageState(1);
  };

  return {
    page,
    pageSize,
    setPage,
    setPageSize,
    resetPage: () => setPageState(1),
  };
}
