import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, Dumbbell, Play } from "lucide-react";
import { Link } from "react-router-dom";
import { getTodayDashboard } from "@/api/dashboard.api";
import { trainingAppointments } from "@/api/training-program.api";
import { Button } from "@/components/ui/button";
import TodaySection from "./TodaySection";
import { nextDayKey, timeLabel, todayKey } from "./today-utils";

const iconTone = "bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-200";

/**
 * Today's planned training. Appointments need the schedule module too, so
 * users with fitness only see today's logged-session count instead.
 */
export default function TodayWorkoutSection({ canSchedule }: { canSchedule: boolean }) {
  return canSchedule ? <PlannedWorkouts /> : <LoggedWorkouts />;
}

function PlannedWorkouts() {
  const today = todayKey();
  const query = useQuery({
    queryKey: ["training-appointments", "today-center", today],
    queryFn: () => trainingAppointments(`${today}T00:00:00`, `${nextDayKey(today)}T00:00:00`),
  });
  const items = query.data ?? [];
  const done = items.filter((item) => item.completedSessionId).length;

  return (
    <TodaySection id="today-workouts" title="Buổi tập hôm nay" icon={Dumbbell} iconClassName={iconTone} skeletonRows={2}
      state={query.isLoading ? "loading" : query.isError ? "error" : items.length === 0 ? "empty" : "ready"}
      errorText="Không tải được lịch tập." onRetry={() => void query.refetch()}
      link={{ to: "/workout-plans", label: "Giáo án" }}
      meta={items.length > 0 && <span>Xong {done}/{items.length}</span>}
      empty={<div className="grid justify-items-center gap-2"><p>Hôm nay không có lịch tập.</p><Button asChild size="sm" variant="outline"><Link to="/workouts?action=new"><Play className="size-3.5" />Tập tự do</Link></Button></div>}>
      <ul className="grid gap-1.5">
        {items.map((item) => (
          <li key={item.id} className="flex min-h-12 items-center gap-2 rounded-xl border px-3 py-1.5">
            <div className="min-w-0 flex-1">
              <p className="truncate font-medium">{item.title}</p>
              <p className="text-xs text-muted-foreground">{timeLabel(item.startAt)}{item.weekNumber ? ` · Tuần ${item.weekNumber}` : ""}</p>
            </div>
            {item.completedSessionId ? (
              <span className="flex items-center gap-1 text-xs font-semibold text-emerald-700"><CheckCircle2 className="size-4" />Đã tập</span>
            ) : (
              <Button asChild size="sm"><Link to={`/workouts?appointment=${encodeURIComponent(item.id)}`}><Play className="size-3.5" />Bắt đầu</Link></Button>
            )}
          </li>
        ))}
      </ul>
    </TodaySection>
  );
}

function LoggedWorkouts() {
  const query = useQuery({ queryKey: ["dashboard-today"], queryFn: getTodayDashboard });
  const count = query.data?.workoutCount ?? 0;
  return (
    <TodaySection id="today-workouts" title="Buổi tập hôm nay" icon={Dumbbell} iconClassName={iconTone} skeletonRows={1}
      state={query.isLoading ? "loading" : query.isError ? "error" : "ready"}
      errorText="Không tải được buổi tập." onRetry={() => void query.refetch()}
      link={{ to: "/workouts", label: "Buổi tập" }}>
      <div className="flex min-h-12 items-center gap-2 rounded-xl border px-3 py-1.5">
        <p className="min-w-0 flex-1 text-sm">{count > 0 ? `Đã ghi ${count} buổi tập hôm nay.` : "Hôm nay chưa ghi buổi tập."}</p>
        <Button asChild size="sm" variant={count > 0 ? "outline" : "default"}><Link to="/workouts?action=new"><Play className="size-3.5" />Bắt đầu tập</Link></Button>
      </div>
    </TodaySection>
  );
}
