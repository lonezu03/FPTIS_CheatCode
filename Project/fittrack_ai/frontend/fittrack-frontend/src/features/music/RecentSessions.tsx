import { useState } from "react";
import { Download, Guitar, Trash2, Wind } from "lucide-react";
import { toast } from "sonner";

import { getMusicSessions, type MusicSession } from "@/api/music.api";

import { useConfirm } from "@/components/common/ConfirmDialog";
import EmptyState from "@/components/common/EmptyState";
import ErrorState from "@/components/common/ErrorState";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { collectPages, csvDate, csvFileDate, downloadCsv, type CsvColumn } from "@/lib/csv";
import { formatDate, getApiErrorMessage } from "@/lib/format";
import { INSTRUMENT_LABEL, exerciseLabel } from "./exercises";
import { formatMinutes } from "./music-utils";
import { SectionCard } from "./MusicParts";
import { useDeleteMusicSession, useRecentMusicSessions } from "./useMusicQueries";

/** Export reads at most 50 pages × 100 sessions. */
const MUSIC_EXPORT_MAX_PAGES = 50;
const musicCsvColumns: CsvColumn<MusicSession>[] = [
  { header: "Ngày", value: (row) => csvDate(row.practicedOn) },
  { header: "Nhạc cụ", value: (row) => INSTRUMENT_LABEL[row.instrument] ?? row.instrument },
  { header: "Bài tập", value: (row) => exerciseLabel(row.exerciseKey) },
  { header: "Số phút", value: (row) => row.minutes },
  { header: "BPM", value: (row) => row.bpm },
  { header: "Ghi chú", value: (row) => row.note },
];

export default function RecentSessions({ onStart }: { onStart: () => void }) {
  const sessions = useRecentMusicSessions();
  const remove = useDeleteMusicSession();
  const confirm = useConfirm();
  const [exporting, setExporting] = useState(false);

  const exportCsv = async () => {
    setExporting(true);
    try {
      const { items, truncated } = await collectPages((page) => getMusicSessions({ page, size: 100 }), { maxPages: MUSIC_EXPORT_MAX_PAGES });
      if (!items.length) { toast.info("Chưa có buổi tập để xuất."); return; }
      const rows = [...items].sort((a, b) => a.practicedOn.localeCompare(b.practicedOn) || a.createdAt.localeCompare(b.createdAt));
      downloadCsv(`luyen-nhac-${csvFileDate()}`, rows, musicCsvColumns);
      if (truncated) toast.warning(`Chỉ xuất ${rows.length} buổi tập gần nhất.`);
      else toast.success(`Đã xuất ${rows.length} buổi tập.`);
    } catch (error) {
      toast.error(getApiErrorMessage(error, "Không xuất được buổi tập."));
    } finally {
      setExporting(false);
    }
  };

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
    <SectionCard
      title="Buổi tập gần đây"
      action={sessions.data?.content.length ? (
        <Button type="button" variant="outline" size="sm" disabled={exporting} onClick={() => void exportCsv()} title="Xuất toàn bộ buổi tập ra CSV">
          <Download className="size-4" /> {exporting ? "Đang xuất..." : "Xuất CSV"}
        </Button>
      ) : undefined}
    >
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
