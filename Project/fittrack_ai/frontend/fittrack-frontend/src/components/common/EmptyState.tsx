import type { ReactNode } from "react";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import EmptyStateArtwork, { type EmptyStateArtworkKind } from "../visuals/EmptyStateArtwork";

type EmptyStateProps = {
  title: string;
  description?: string;
  kind?: EmptyStateArtworkKind;
  /** Nhãn nút chính, ví dụ "Tạo mục tiêu đầu tiên". Chỉ hiện khi có cả onAction. */
  actionLabel?: string;
  onAction?: () => void;
  actionDisabled?: boolean;
  /** Nội dung hành động tùy biến, thay cho nút mặc định. */
  action?: ReactNode;
  /** Bản gọn cho khu vực nhỏ (thẻ, cột bên). */
  compact?: boolean;
  className?: string;
};

export default function EmptyState({
  title,
  description,
  kind = "generic",
  actionLabel,
  onAction,
  actionDisabled,
  action,
  compact = false,
  className,
}: EmptyStateProps) {
  return (
    <div
      className={cn(
        "relative flex flex-col items-center justify-center overflow-hidden rounded-3xl border border-dashed border-emerald-200 bg-gradient-to-b from-white via-white to-emerald-50/70 text-center",
        compact ? "min-h-40 p-5" : "min-h-56 p-6 sm:p-10",
        className,
      )}
    >
      <div className="pointer-events-none absolute -left-12 -top-16 size-36 rounded-full bg-emerald-100/50 blur-2xl" />
      <div className="pointer-events-none absolute -bottom-16 -right-10 size-32 rounded-full bg-amber-100/45 blur-2xl" />
      {!compact && <EmptyStateArtwork kind={kind} />}

      <h3 className="text-base font-semibold tracking-tight sm:text-lg">{title}</h3>

      {description && <p className="mt-1.5 max-w-md text-sm leading-6 text-muted-foreground">{description}</p>}

      {action ?? (actionLabel && onAction && (
        <Button type="button" className="relative mt-4" disabled={actionDisabled} onClick={onAction}>
          <Plus className="size-4" />
          {actionLabel}
        </Button>
      ))}
    </div>
  );
}
