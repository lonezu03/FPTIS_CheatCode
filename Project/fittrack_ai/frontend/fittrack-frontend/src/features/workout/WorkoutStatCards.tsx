import { Activity, Dumbbell, Timer, TrendingUp } from "lucide-react";

import type { WorkoutSession } from "@/api/workout.api";
import { Card, CardContent } from "@/components/ui/card";
import { summarizeSessions } from "./workout-utils";

const tones = {
  emerald: "bg-emerald-100 text-emerald-700",
  amber: "bg-amber-100 text-amber-700",
  sky: "bg-sky-100 text-sky-700",
  slate: "bg-slate-100 text-slate-700",
};

function StatCard({ icon: Icon, label, value, tone = "slate" }: { icon: typeof Activity; label: string; value: string; tone?: keyof typeof tones }) {
  return <Card><CardContent className="flex items-center gap-3 p-4"><div className={`rounded-xl p-2.5 ${tones[tone]}`}><Icon className="h-5 w-5" /></div><div><p className="text-xs font-medium text-muted-foreground">{label}</p><p className="text-xl font-bold">{value}</p></div></CardContent></Card>;
}

/** Bốn chỉ số tổng hợp của trang lịch sử đang xem. */
export default function WorkoutStatCards({ sessions }: { sessions: WorkoutSession[] }) {
  const { totalSets, totalVolume, totalMinutes } = summarizeSessions(sessions);
  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      <StatCard icon={Activity} label="Buổi gần đây" value={sessions.length.toString()} tone="emerald" />
      <StatCard icon={Dumbbell} label="Tổng set" value={totalSets.toString()} />
      <StatCard icon={TrendingUp} label="Tổng volume" value={`${Math.round(totalVolume).toLocaleString("vi-VN")} kg`} tone="amber" />
      <StatCard icon={Timer} label="Thời lượng" value={`${totalMinutes} phút`} tone="sky" />
    </div>
  );
}
