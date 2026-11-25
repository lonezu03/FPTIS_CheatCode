import { useState } from "react";
import { useMutation, useQuery, useQueryClient, type UseQueryResult } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { ArrowRight, ChefHat, Dumbbell, Soup, Trophy } from "lucide-react";
import { toast } from "sonner";
import { getAchievementSummary } from "../api/achievement.api";
import { getProgressDashboard, getTodayDashboard, type DashboardToday } from "../api/dashboard.api";
import { seedDemoData } from "../api/demo.api";
import { requestFitnessModuleAccess } from "../api/notification.api";
import DeferredFitnessTrendCharts from "../components/DeferredFitnessTrendCharts";
import MacroProgressCard from "../components/MacroProgressCard";
import DailyQuoteCard from "../components/quotes/DailyQuoteCard";
import SectionBoundary from "@/components/dashboard/SectionBoundary";
import TodayFinanceSection from "@/components/dashboard/TodayFinanceSection";
import TodayHabitsSection from "@/components/dashboard/TodayHabitsSection";
import TodayMealsSection from "@/components/dashboard/TodayMealsSection";
import TodayTodosSection from "@/components/dashboard/TodayTodosSection";
import TodayWorkoutSection from "@/components/dashboard/TodayWorkoutSection";
import { QuickAddDialog, type MealType, type QuickAddTab } from "@/components/quickadd";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { canUseFeature } from "@/lib/feature-access";
import { getApiErrorMessage } from "@/lib/format";
import { useAuthStore } from "../store/auth.store";

type QuickAddState = { tab: QuickAddTab; mealType?: MealType } | null;

export default function DashboardPage() {
  const queryClient = useQueryClient();
  const authUser = useAuthStore((state) => state.user);
  const isAdmin = authUser?.role === "ADMIN";
  const can = {
    lunch: canUseFeature(authUser, "lunchEnabled"),
    fitness: canUseFeature(authUser, "fitnessEnabled"),
    health: canUseFeature(authUser, "healthEnabled"),
    todo: canUseFeature(authUser, "todoEnabled"),
    schedule: canUseFeature(authUser, "scheduleEnabled"),
    quote: canUseFeature(authUser, "quoteEnabled"),
    finance: canUseFeature(authUser, "financeEnabled"),
    journal: canUseFeature(authUser, "journalEnabled"),
  };
  const lunchOnly = !isAdmin && can.lunch && !can.fitness && !can.health && !can.todo && !can.schedule
    && !can.quote && !can.finance && !can.journal && !authUser?.chatbotEnabled;
  const hasActionSections = can.todo || can.health || can.fitness || can.finance;
  const [quickAdd, setQuickAdd] = useState<QuickAddState>(null);

  const seedMutation = useMutation({
    mutationFn: seedDemoData,
    onSuccess: (data) => { toast.success(`${data.message}: ${data.quotesCreated} câu nói, ${data.workoutSessionsCreated} buổi tập mới.`); void queryClient.invalidateQueries(); },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể tạo dữ liệu mẫu")),
  });
  const accessRequestMutation = useMutation({
    mutationFn: requestFitnessModuleAccess,
    onSuccess: (data) => toast.success(data.message),
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể gửi yêu cầu mở module Rèn luyện")),
  });
  const todayQuery = useQuery({ queryKey: ["dashboard-today"], queryFn: getTodayDashboard, enabled: can.health || can.fitness });

  const dateLabel = new Date().toLocaleDateString("vi-VN", { weekday: "long", day: "numeric", month: "numeric" });
  const firstName = authUser?.fullName?.trim().split(/\s+/).pop();

  return (
    <div className="space-y-5 md:space-y-6">
      <header className="relative overflow-hidden rounded-3xl bg-[#0c2821] px-5 py-5 text-white shadow-xl shadow-emerald-950/10 sm:px-7">
        <div className="pointer-events-none absolute -right-16 -top-16 size-48 rounded-full border border-emerald-200/10" />
        <p className="text-sm font-medium capitalize text-emerald-200/75">{dateLabel}</p>
        <h1 className="mt-1 text-2xl font-semibold tracking-[-0.03em] sm:text-3xl">Hôm nay{firstName ? `, ${firstName}` : ""}</h1>
        <p className="mt-1 max-w-xl text-sm text-emerald-50/70">Việc cần làm ngay, xử lý trực tiếp tại đây.</p>
        {lunchOnly && (
          <p className="mt-3 max-w-2xl text-sm leading-6 text-emerald-100/80">
            Liên hệ bạn Vũ (<a className="font-semibold underline underline-offset-4" href="mailto:lonezu03@gmail.com">lonezu03@gmail.com</a>)
            để mở khóa module Rèn luyện nếu bạn chưa được phân quyền, hoặc gửi yêu cầu trực tiếp cho admin.
          </p>
        )}
        {(can.lunch || lunchOnly || isAdmin) && (
          <div className="mt-4 flex flex-wrap gap-2">
            {can.lunch && <Button asChild className="bg-emerald-300 text-[#0c2821] hover:bg-emerald-200"><Link to="/lunch"><Soup className="size-4" />Đặt cơm hôm nay</Link></Button>}
            {lunchOnly && (
              <Button variant="outline" className="border-white/25 bg-white/10 text-white hover:bg-white/20 hover:text-white"
                onClick={() => accessRequestMutation.mutate()} disabled={accessRequestMutation.isPending}>
                <Dumbbell className="size-4" />{accessRequestMutation.isPending ? "Đang gửi..." : "Yêu cầu mở Rèn luyện"}
              </Button>
            )}
            {isAdmin && (
              <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}
                className="border-white/20 bg-white/10 text-white hover:bg-white/20">
                {seedMutation.isPending ? "Đang tạo..." : "Tạo dữ liệu mẫu"}
              </Button>
            )}
          </div>
        )}
      </header>

      {todayQuery.data?.coachInsight && (
        <Card className="border-emerald-200 bg-emerald-50/60 dark:border-emerald-900 dark:bg-emerald-950/30">
          <CardContent className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div><p className="text-sm font-bold text-emerald-900 dark:text-emerald-200">AnCai Coach hôm nay</p><p className="mt-1 text-sm text-emerald-950/75 dark:text-emerald-100/80">{todayQuery.data.coachInsight}</p></div>
            {todayQuery.data.coachActionPath && <Button asChild size="sm"><Link to={todayQuery.data.coachActionPath}>Thực hiện ngay <ArrowRight className="size-4" /></Link></Button>}
          </CardContent>
        </Card>
      )}

      {hasActionSections && (
        <div className="grid gap-4 lg:grid-cols-2">
          {can.todo && <SectionBoundary title="Việc hôm nay"><TodayTodosSection onAdd={() => setQuickAdd({ tab: "todo" })} /></SectionBoundary>}
          {can.todo && <SectionBoundary title="Thói quen"><TodayHabitsSection /></SectionBoundary>}
          {can.health && <SectionBoundary title="Bữa ăn hôm nay"><TodayMealsSection onLog={(mealType) => setQuickAdd({ tab: "meal", mealType })} /></SectionBoundary>}
          {can.fitness && <SectionBoundary title="Buổi tập hôm nay"><TodayWorkoutSection canSchedule={can.schedule} /></SectionBoundary>}
          {can.finance && <SectionBoundary title="Chi tiêu"><TodayFinanceSection onAdd={() => setQuickAdd({ tab: "finance" })} /></SectionBoundary>}
        </div>
      )}

      {can.quote && <SectionBoundary title="Câu nói hôm nay"><DailyQuoteCard /></SectionBoundary>}

      {(can.health || can.fitness) && <SectionBoundary title="Tiến độ"><ProgressOverview health={can.health} fitness={can.fitness} today={todayQuery} /></SectionBoundary>}

      {can.lunch && !hasActionSections && (
        <Card className="border-dashed bg-muted/30">
          <CardContent className="flex flex-col items-center gap-3 py-10 text-center">
            <ChefHat className="size-8 text-emerald-700" />
            <p className="font-semibold">Tài khoản của bạn đang ở chế độ Đặt cơm</p>
            <p className="max-w-md text-sm leading-6 text-muted-foreground">Cần thêm mục nào, hãy nhờ admin mở quyền.</p>
            <Button asChild variant="outline"><Link to="/profile">Mở hồ sơ cá nhân</Link></Button>
          </CardContent>
        </Card>
      )}

      <QuickAddDialog open={quickAdd !== null} onOpenChange={(open) => { if (!open) setQuickAdd(null); }}
        initialTab={quickAdd?.tab} initialMealType={quickAdd?.mealType} />
    </div>
  );
}

function ProgressOverview({ health, fitness, today }: { health: boolean; fitness: boolean; today: UseQueryResult<DashboardToday> }) {
  const progressQuery = useQuery({ queryKey: ["dashboard-progress"], queryFn: getProgressDashboard });
  const achievementQuery = useQuery({ queryKey: ["achievements"], queryFn: getAchievementSummary, enabled: fitness });
  const data = today.data;

  return (
    <section className="space-y-4" aria-labelledby="progress-title">
      <div className="flex items-center justify-between gap-3">
        <h2 id="progress-title" className="text-lg font-semibold">Tiến độ</h2>
        {health && <Link className="text-sm font-semibold text-emerald-700 hover:text-emerald-800" to="/reports/weekly">Báo cáo tuần <ArrowRight className="ml-1 inline size-4" /></Link>}
      </div>
      {health && (today.isLoading ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{[0, 1, 2, 3].map((index) => <Skeleton key={index} className="h-28 rounded-2xl" />)}</div>
      ) : today.isError || !data ? (
        <p role="alert" className="text-sm text-destructive">Không tải được mục tiêu dinh dưỡng. <button className="underline" onClick={() => void today.refetch()}>Thử lại</button></p>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <MacroProgressCard title="Mục tiêu năng lượng" current={data.totalCalories} target={data.targetCalories} unit="kcal" percent={data.caloriesProgressPercent} />
          <MacroProgressCard title="Mục tiêu chất đạm" current={data.totalProtein} target={data.targetProtein} unit="g" percent={data.proteinProgressPercent} />
          <MacroProgressCard title="Mục tiêu tinh bột" current={data.totalCarbs} target={data.targetCarbs} unit="g" percent={data.carbsProgressPercent} />
          <MacroProgressCard title="Mục tiêu chất béo" current={data.totalFat} target={data.targetFat} unit="g" percent={data.fatProgressPercent} />
        </div>
      ))}
      {fitness && achievementQuery.data && (
        <Card>
          <CardHeader><CardTitle className="flex items-center gap-2"><Trophy className="size-5 text-amber-600" />Tuần này</CardTitle></CardHeader>
          <CardContent className="grid gap-3 sm:grid-cols-2 md:grid-cols-4">
            <Metric label="Chuỗi ngày ghi bữa" value={`${achievementQuery.data.mealLoggingStreak} ngày`} className="bg-emerald-50 dark:bg-emerald-950/30" />
            <Metric label="Chuỗi ngày tập" value={`${achievementQuery.data.workoutStreak} ngày`} className="bg-blue-50 dark:bg-blue-950/30" />
            <Metric label="Ngày đạt protein" value={achievementQuery.data.proteinHitDaysThisWeek} className="bg-amber-50 dark:bg-amber-950/30" />
            <Metric label="Ngày ghi số đo" value={achievementQuery.data.bodyTrackingDaysThisWeek} className="bg-violet-50 dark:bg-violet-950/30" />
          </CardContent>
        </Card>
      )}
      {progressQuery.isError
        ? <p role="alert" className="text-sm text-destructive">Không tải được biểu đồ xu hướng. <button className="underline" onClick={() => void progressQuery.refetch()}>Thử lại</button></p>
        : <DeferredFitnessTrendCharts points={progressQuery.data?.points ?? []} />}
    </section>
  );
}

function Metric({ label, value, className }: { label: string; value: string | number; className: string }) {
  return <div className={`rounded-xl p-4 ${className}`}><p className="text-sm text-muted-foreground">{label}</p><p className="mt-1 text-xl font-bold">{value}</p></div>;
}
