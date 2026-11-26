import { CalendarCheck2, Play } from "lucide-react";

import type { WorkoutPlan, WorkoutPlanDay } from "@/api/workout-plan.api";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";

export type PlanDayOption = { plan: WorkoutPlan; day: WorkoutPlanDay };

/** Khối bắt đầu buổi tập: tự do, lặp lại buổi gần đây hoặc theo giáo án. */
export default function WorkoutStartCard({
  canReuseLatest,
  planDays,
  selectedPlanDay,
  onSelectPlanDay,
  onStartFree,
  onReuseLatest,
  onStartPlan,
}: {
  canReuseLatest: boolean;
  planDays: PlanDayOption[];
  selectedPlanDay: string;
  onSelectPlanDay: (value: string) => void;
  onStartFree: () => void;
  onReuseLatest: () => void;
  onStartPlan: () => void;
}) {
  return (
    <Card className="overflow-hidden border-emerald-200 bg-gradient-to-br from-emerald-950 to-emerald-800 text-white">
      <CardContent className="grid gap-6 p-6 lg:grid-cols-[1.2fr_1fr] lg:items-center">
        <div>
          <p className="mb-2 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-200">Workout mode</p>
          <h2 className="text-2xl font-bold">Hôm nay bạn muốn tập gì?</h2>
          <p className="mt-2 max-w-xl text-sm text-emerald-100/80">
            Mỗi buổi có nhiều bài, mỗi bài có nhiều set. Đồng hồ nghỉ sẽ tự chạy sau khi hoàn thành set.
          </p>
          <Button className="mt-5 bg-white text-emerald-950 hover:bg-emerald-50" onClick={onStartFree}>
            <Play /> Bắt đầu buổi tập tự do
          </Button>
          {canReuseLatest && <Button className="mt-3 sm:ml-2" variant="secondary" onClick={onReuseLatest}>Dùng lại bài và mức tạ gần đây</Button>}
        </div>
        <div className="rounded-2xl border border-white/15 bg-white/10 p-4 backdrop-blur">
          <label className="text-sm font-semibold" htmlFor="workout-plan-day">Hoặc tập theo giáo án</label>
          <select
            id="workout-plan-day"
            className="mt-2 h-11 w-full rounded-xl border border-white/20 bg-emerald-950/60 px-3 text-sm text-white"
            value={selectedPlanDay}
            onChange={(event) => onSelectPlanDay(event.target.value)}
          >
            <option value="">Chọn giáo án và ngày tập</option>
            {planDays.map(({ plan, day }) => (
              <option key={`${plan.id}:${day.id}`} value={`${plan.id}:${day.id}`}>
                {plan.name} · {day.name} ({day.exercises.length} bài)
              </option>
            ))}
          </select>
          <Button variant="secondary" className="mt-3 w-full" onClick={onStartPlan} disabled={!planDays.length}>
            <CalendarCheck2 /> Bắt đầu theo giáo án
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
