import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "../ui/button";

type DataPaginationProps = {
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  onPageSizeChange: (pageSize: number) => void;
};

export default function DataPagination({
  page,
  pageSize,
  totalItems,
  totalPages,
  onPageChange,
  onPageSizeChange,
}: DataPaginationProps) {
  if (totalItems === 0) return null;

  const firstItem = (page - 1) * pageSize + 1;
  const lastItem = Math.min(page * pageSize, totalItems);

  return (
    <div className="flex flex-col gap-3 border-t border-slate-200 px-3 py-4 text-sm text-slate-600 sm:flex-row sm:items-center sm:justify-between">
      <p>
        Hiển thị <strong className="text-slate-900">{firstItem}–{lastItem}</strong> trong{" "}
        <strong className="text-slate-900">{totalItems}</strong> mục
      </p>

      <div className="flex flex-wrap items-center gap-2">
        <label className="flex items-center gap-2">
          Số dòng
          <select
            className="h-9 rounded-xl border border-slate-200 bg-white px-2 text-slate-900 outline-none focus:border-emerald-500"
            value={pageSize}
            onChange={(event) => onPageSizeChange(Number(event.target.value))}
          >
            {[10, 20, 50].map((size) => (
              <option key={size} value={size}>
                {size}
              </option>
            ))}
          </select>
        </label>

        <Button
          type="button"
          variant="outline"
          size="icon"
          aria-label="Trang trước"
          disabled={page <= 1}
          onClick={() => onPageChange(page - 1)}
        >
          <ChevronLeft className="size-4" />
        </Button>
        <span className="min-w-20 text-center font-medium text-slate-900">
          {page}/{totalPages}
        </span>
        <Button
          type="button"
          variant="outline"
          size="icon"
          aria-label="Trang sau"
          disabled={page >= totalPages}
          onClick={() => onPageChange(page + 1)}
        >
          <ChevronRight className="size-4" />
        </Button>
      </div>
    </div>
  );
}
