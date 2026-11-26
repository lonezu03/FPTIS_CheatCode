import { Guitar, Trash2, Wind } from "lucide-react";

import { useConfirm } from "@/components/common/ConfirmDialog";
import EmptyState from "@/components/common/EmptyState";
import ErrorState from "@/components/common/ErrorState";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { formatDate, getApiErrorMessage } from "@/lib/format";
import { exerciseLabel } from "./exercises";
import { formatMinutes } from "./music-utils";
import { SectionCard } from "./MusicParts";
import { useDeleteMusicSession, useRecentMusicSessions } from "./useMusicQueries";

export default function RecentSessions({ onStart }: { onStart: () => void }) {
  const sessions = useRecentMusicSessions();
  const remove = useDeleteMusicSession();
  const confirm = useConfirm();

  const askDelete = async (id: string, label: string, date: string) => {
    const ok = await confirm({
      title: "Xóa buổi tập?",
      description: `${label} ngày ${formatDate(date)} sẽ bị xóa khỏi thống kê và chuỗi ngày.`,
      confirmText: "Xóa",
      destructive: true,
    });
    if (ok) remove.mutate(id);
  };

  return (
    <SectionCard title="Buổi tập gần đây">
      {sessions.isLoading ? (
        <div className="space-y-2">
          {[0, 1, 2].map((index) => (
            <Skeleton key={index} className="h-12 rounded-xl" />
          ))}
        </div>
      ) : sessions.isError ? (
        <ErrorState
          title="Không tải được buổi tập"
          message={getApiErrorMessage(sessions.error, "Vui lòng thử lại.")}
          onRetry={() => void sessions.refetch()}
          retrying={sessions.isFetching}
        />
      ) : !sessions.data?.content.length ? (
        <EmptyState compact title="Chưa có buổi tập nào" description="Tập theo bài hôm nay rồi bấm Ghi buổi tập." actionLabel="Bắt đầu bài hôm nay" onAction={onStart} />
      ) : (
        <ul className="divide-y">
          {sessions.data.content.map((session) => {
            const Icon = session.instrument === "GUITAR" ? Guitar : Wind;
            const label = exerciseLabel(session.exerciseKey);
            return (
              <li key={session.id} className="flex items-start gap-3 py-2.5">
                <span className={`mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-lg ${session.instrument === "GUITAR" ? "bg-emerald-100 text-emerald-700" : "bg-amber-100 text-amber-700"}`}>
                  <Icon className="size-4" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">{label}</p>
                  <p className="text-xs text-muted-foreground">
                    {formatDate(session.practicedOn)} · {formatMinutes(session.minutes)}
                    {session.bpm ? ` · ${session.bpm} BPM` : ""}
                  </p>
                  {session.note && <p className="mt-0.5 line-clamp-2 text-xs text-muted-foreground">{session.note}</p>}
                </div>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  aria-label={`Xóa buổi tập ${label}`}
                  disabled={remove.isPending && remove.variables === session.id}
                  onClick={() => void askDelete(session.id, label, session.practicedOn)}
                >
                  <Trash2 className="size-4" />
                </Button>
              </li>
            );
          })}
        </ul>
      )}
    </SectionCard>
  );
}
