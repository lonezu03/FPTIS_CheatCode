import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

type TableLoadingProps = {
  /** Số dòng giả lập, mặc định 5. */
  rows?: number;
  /** Lớp cho từng dòng, ví dụ "h-24" khi nội dung là thẻ. */
  rowClassName?: string;
  className?: string;
  label?: string;
};

export default function TableLoading({ rows = 5, rowClassName, className, label = "Đang tải" }: TableLoadingProps = {}) {
  return (
    <div className={cn("space-y-3", className)} role="status" aria-label={label} aria-busy="true">
      {Array.from({ length: rows }).map((_, index) => (
        <Skeleton key={index} className={cn("h-12 w-full rounded-xl", rowClassName)} />
      ))}
    </div>
  );
}
