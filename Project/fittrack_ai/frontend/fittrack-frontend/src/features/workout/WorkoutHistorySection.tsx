import { History } from "lucide-react";

import type { Exercise, WorkoutSession } from "@/api/workout.api";
import DataPagination from "@/components/common/DataPagination";
import EmptyState from "@/components/common/EmptyState";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import SessionHistoryCard from "./SessionHistoryCard";
import type { HistoryFilters } from "./useWorkoutData";

/** Lịch sử buổi tập: bộ lọc, danh sách và phân trang. */
export default function WorkoutHistorySection({
  filters,
  onFilterChange,
  exercises,
  sessions,
  page,
  pageSize,
  totalItems,
  totalPages,
  onPageChange,
  onPageSizeChange,
  onEdit,
  onDelete,
}: {
  filters: HistoryFilters;
  onFilterChange: (patch: Partial<HistoryFilters>) => void;
  exercises: Exercise[];
  sessions: WorkoutSession[];
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  onPageSizeChange: (pageSize: number) => void;
  onEdit: (session: WorkoutSession) => void;
  onDelete: (session: WorkoutSession) => void;
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2"><History className="h-5 w-5 text-emerald-600" />Lịch sử gần đây</CardTitle>
        <p className="text-sm text-muted-foreground">Mỗi thẻ là một buổi tập hoàn chỉnh, bên trong được nhóm theo từng bài.</p>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="grid gap-3 sm:grid-cols-3">
          <label className="text-sm">Từ ngày<Input type="date" value={filters.from} onChange={event => onFilterChange({ from: event.target.value })} /></label>
          <label className="text-sm">Đến ngày<Input type="date" value={filters.to} onChange={event => onFilterChange({ to: event.target.value })} /></label>
          <label className="text-sm">Bài tập<select className="h-11 w-full rounded-xl border px-3" value={filters.exerciseId} onChange={event => onFilterChange({ exerciseId: event.target.value })}><option value="">Tất cả bài tập</option>{exercises.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
        </div>
        {!sessions.length ? (
          <EmptyState kind="workout" title="Chưa có buổi tập" description="Bắt đầu workout đầu tiên để theo dõi tiến độ." />
        ) : (
          sessions.map((session) => (
            <SessionHistoryCard key={session.id} session={session} onEdit={() => onEdit(session)} onDelete={() => onDelete(session)} />
          ))
        )}
        <DataPagination
          page={page}
          pageSize={pageSize}
          totalItems={totalItems}
          totalPages={totalPages}
          onPageChange={onPageChange}
          onPageSizeChange={onPageSizeChange}
        />
      </CardContent>
    </Card>
  );
}
