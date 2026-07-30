import { useMemo, useState } from "react";

export function usePagination<T>(items: T[], initialPageSize = 10) {
  const [page, setPage] = useState(1);
  const [pageSize, setPageSizeState] = useState(initialPageSize);
  const totalItems = items.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
  const safePage = Math.min(page, totalPages);

  const paginatedItems = useMemo(() => {
    const start = (safePage - 1) * pageSize;
    return items.slice(start, start + pageSize);
  }, [items, safePage, pageSize]);

  const setPageSize = (value: number) => {
    setPageSizeState(value);
    setPage(1);
  };

  return {
    page: safePage,
    pageSize,
    totalItems,
    totalPages,
    paginatedItems,
    setPage,
    setPageSize,
    resetPage: () => setPage(1),
  };
}
