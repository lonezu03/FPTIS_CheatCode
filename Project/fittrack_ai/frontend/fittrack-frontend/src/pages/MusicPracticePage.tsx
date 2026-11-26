import { useRef, useState } from "react";

import ErrorState from "@/components/common/ErrorState";
import PageHeader from "@/components/PageHeader";
import { Skeleton } from "@/components/ui/skeleton";
import { getApiErrorMessage } from "@/lib/format";
import { BestBpmCard, MusicMetrics, MusicMetricsSkeleton, WeekChart } from "@/features/music/MusicStats";
import QuickLogCard from "@/features/music/QuickLogCard";
import RecentSessions from "@/features/music/RecentSessions";
import RoutineCard, { type LogPrefill } from "@/features/music/RoutineCard";
import { useMusicSummary } from "@/features/music/useMusicQueries";

export default function MusicPracticePage() {
  const summary = useMusicSummary();
  const [prefill, setPrefill] = useState<{ value: LogPrefill | null; version: number }>({ value: null, version: 0 });
  const logRef = useRef<HTMLDivElement>(null);
  const routineRef = useRef<HTMLDivElement>(null);

  const openLog = (value: LogPrefill) => {
    setPrefill((current) => ({ value, version: current.version + 1 }));
    logRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  return (
    <div className="space-y-6">
      <PageHeader title="Luyện tập hôm nay" description="Mỗi ngày 15–20 phút cho ghi-ta hoặc sáo trúc. Tập ngắn mà đều sẽ tiến bộ nhanh hơn tập dồn." />

      {summary.isLoading ? (
        <MusicMetricsSkeleton />
      ) : summary.isError || !summary.data ? (
        <ErrorState
          title="Không tải được thống kê luyện tập"
          message={getApiErrorMessage(summary.error, "Bạn vẫn có thể tập theo bài hôm nay.")}
          onRetry={() => void summary.refetch()}
          retrying={summary.isFetching}
        />
      ) : (
        <MusicMetrics summary={summary.data} />
      )}

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_360px]">
        <div ref={routineRef} className="scroll-mt-20">
          <RoutineCard best={summary.data?.bestBpmByExercise ?? []} onLog={openLog} />
        </div>
        <div ref={logRef} className="scroll-mt-20">
          <QuickLogCard key={prefill.version} prefill={prefill.value} />
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {summary.isLoading ? (
          <>
            <Skeleton className="h-64 rounded-2xl" />
            <Skeleton className="h-64 rounded-2xl" />
          </>
        ) : summary.data ? (
          <>
            <WeekChart summary={summary.data} />
            <BestBpmCard summary={summary.data} />
          </>
        ) : null}
        <RecentSessions onStart={() => routineRef.current?.scrollIntoView({ behavior: "smooth", block: "start" })} />
      </div>
    </div>
  );
}
