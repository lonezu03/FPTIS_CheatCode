import { CalendarCheck, Clock3, Flame, Gauge } from "lucide-react";

import type { MusicSummary } from "@/api/music.api";
import EmptyState from "@/components/common/EmptyState";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { formatShortDate } from "@/lib/format";
import { exerciseLabel, INSTRUMENT_LABEL } from "./exercises";
import { formatMinutes, streakMessage, weekBars } from "./music-utils";
import { SectionCard } from "./MusicParts";

function Metric({ icon: Icon, label, value, hint, tone }: { icon: typeof Flame; label: string; value: string; hint?: string; tone: string }) {
  return (
    <Card size="sm">
      <CardContent className="flex items-center gap-3">
        <span className={`flex size-10 shrink-0 items-center justify-center rounded-xl ${tone}`}>
          <Icon className="size-5" />
        </span>
        <div className="min-w-0">
          <p className="text-xs text-muted-foreground">{label}</p>
          <p className="text-xl font-semibold tabular-nums">{value}</p>
          {hint && <p className="truncate text-xs text-muted-foreground">{hint}</p>}
        </div>
      </CardContent>
    </Card>
  );
}

export function MusicMetrics({ summary }: { summary: MusicSummary }) {
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      <Metric icon={Flame} label="Chuỗi ngày tập" value={`${summary.streakDays} ngày`} hint={streakMessage(summary.streakDays, summary.todayMinutes)} tone="bg-orange-100 text-orange-700" />
      <Metric icon={Clock3} label="Hôm nay" value={formatMinutes(summary.todayMinutes)} hint={summary.todayMinutes >= 15 ? "Đủ mục tiêu 15 phút" : `Còn ${15 - summary.todayMinutes} phút tới 15 phút`} tone="bg-emerald-100 text-emerald-700" />
      <Metric icon={CalendarCheck} label="7 ngày qua" value={formatMinutes(summary.weekMinutes)} tone="bg-sky-100 text-sky-700" />
      <Metric
        icon={Gauge}
        label="Tổng cộng"
        value={`${summary.sessionsCount} buổi`}
        hint={`Ghi-ta ${formatMinutes(summary.totalMinutesByInstrument.GUITAR ?? 0)} · Sáo ${formatMinutes(summary.totalMinutesByInstrument.FLUTE ?? 0)}`}
        tone="bg-violet-100 text-violet-700"
      />
    </div>
  );
}

export function MusicMetricsSkeleton() {
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      {[0, 1, 2, 3].map((index) => (
        <Skeleton key={index} className="h-20 rounded-2xl" />
      ))}
    </div>
  );
}

/** Stacked bars: guitar (emerald) and flute (amber) minutes for the last 7 days. */
export function WeekChart({ summary }: { summary: MusicSummary }) {
  const { bars, max } = weekBars(summary.weekByDay);
  return (
    <SectionCard title="7 ngày gần đây" description={`Cột cao nhất = ${max} phút`}>
      <div className="flex h-40 items-end gap-2" role="img" aria-label={bars.map((bar) => `${bar.label}: ${bar.total} phút`).join(", ")}>
        {bars.map((bar) => (
          <div key={bar.date} className="flex h-full flex-1 flex-col items-center gap-1">
            <span className="text-[11px] tabular-nums text-muted-foreground">{bar.total || ""}</span>
            <div className="flex w-full max-w-10 flex-1 flex-col-reverse overflow-hidden rounded-lg bg-muted/60">
              <div className="bg-emerald-500" style={{ height: `${bar.guitarPct}%` }} title={`Ghi-ta ${bar.guitarMinutes} phút`} />
              <div className="bg-amber-400" style={{ height: `${bar.flutePct}%` }} title={`Sáo ${bar.fluteMinutes} phút`} />
            </div>
            <span className="text-xs font-medium text-muted-foreground">{bar.label}</span>
          </div>
        ))}
      </div>
      <div className="flex gap-4 text-xs text-muted-foreground">
        <span className="flex items-center gap-1.5">
          <span className="size-2.5 rounded-sm bg-emerald-500" /> Ghi-ta
        </span>
        <span className="flex items-center gap-1.5">
          <span className="size-2.5 rounded-sm bg-amber-400" /> Sáo
        </span>
      </div>
    </SectionCard>
  );
}

export function BestBpmCard({ summary }: { summary: MusicSummary }) {
  const records = summary.bestBpmByExercise;
  return (
    <SectionCard title="Kỷ lục BPM" description="Tốc độ cao nhất bạn đã chơi sạch ở từng bài.">
      {records.length === 0 ? (
        <EmptyState compact kind="progress" title="Chưa có kỷ lục" description="Khi ghi buổi tập, nhập BPM đạt được để theo dõi tiến bộ." />
      ) : (
        <ul className="divide-y">
          {records.map((record) => (
            <li key={`${record.exerciseKey}|${record.instrument}`} className="flex items-center justify-between gap-3 py-2">
              <div className="min-w-0">
                <p className="truncate text-sm font-medium">{exerciseLabel(record.exerciseKey)}</p>
                <p className="text-xs text-muted-foreground">
                  {INSTRUMENT_LABEL[record.instrument]} · đạt lần đầu {formatShortDate(record.practicedOn)}
                </p>
              </div>
              <span className="shrink-0 rounded-full bg-emerald-50 px-2.5 py-1 text-sm font-semibold tabular-nums text-emerald-800">{record.bpm} BPM</span>
            </li>
          ))}
        </ul>
      )}
    </SectionCard>
  );
}
