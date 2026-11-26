import { TrendingUp } from "lucide-react";

import type { WeeklyWorkoutVolume } from "@/api/workout.api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { formatNumber } from "./workout-utils";

function WeeklyVolumeSkeleton() {
  return (
    <Card aria-busy="true">
      <CardContent className="space-y-3 p-5">
        <span className="sr-only">Đang tổng hợp khối lượng tập tuần này...</span>
        <Skeleton className="h-5 w-56 max-w-full" />
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 3 }).map((_, index) => <Skeleton key={index} className="h-20 rounded-2xl" />)}
        </div>
      </CardContent>
    </Card>
  );
}

/** Số set chính và volume theo nhóm cơ trong tuần. */
export default function WeeklyVolumeCard({ loading, data }: { loading: boolean; data?: WeeklyWorkoutVolume }) {
  if (loading) return <WeeklyVolumeSkeleton />;
  if (!data) return null;
  const maxSets = Math.max(1, ...data.muscleGroups.map((item) => item.workingSets));
  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <CardTitle className="flex items-center gap-2"><TrendingUp className="h-5 w-5 text-emerald-600" />Khối lượng theo nhóm cơ</CardTitle>
            <p className="mt-1 text-sm text-muted-foreground">{data.weekStart} đến {data.weekEnd} · chỉ tính set chính đã hoàn thành.</p>
          </div>
          <div className="flex gap-2 text-sm">
            <span className="rounded-full bg-emerald-50 px-3 py-1 font-semibold text-emerald-700">{data.totalWorkingSets} set</span>
            <span className="rounded-full bg-slate-100 px-3 py-1 font-semibold text-slate-700">{formatNumber(data.totalVolume)} kg</span>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {!data.muscleGroups.length ? (
          <p className="rounded-xl bg-slate-50 p-4 text-sm text-muted-foreground">Chưa có set chính nào trong tuần này.</p>
        ) : (
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {data.muscleGroups.map((item) => (
              <div key={item.muscleGroup} className="rounded-2xl border p-3">
                <div className="flex items-center justify-between gap-2">
                  <p className="font-semibold">{item.muscleGroup}</p>
                  <span className={`text-xs font-semibold ${item.changeSets >= 0 ? "text-emerald-700" : "text-amber-700"}`}>
                    {item.changeSets >= 0 ? "+" : ""}{item.changeSets} set so với tuần trước
                  </span>
                </div>
                <div className="mt-2 h-2 overflow-hidden rounded-full bg-slate-100">
                  <div className="h-full rounded-full bg-emerald-500" style={{ width: `${Math.max(5, item.workingSets / maxSets * 100)}%` }} />
                </div>
                <p className="mt-2 text-xs text-muted-foreground">{item.workingSets} set · {formatNumber(item.totalVolume)} kg volume</p>
              </div>
            ))}
          </div>
        )}
        <p className="mt-3 text-xs text-muted-foreground">{data.disclaimer}</p>
      </CardContent>
    </Card>
  );
}
