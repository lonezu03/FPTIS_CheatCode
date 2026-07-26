import { getAchievementSummary } from "../api/achievement.api";
import { getProgressDashboard, getTodayDashboard } from "../api/dashboard.api";
import { seedDemoData } from "../api/demo.api";
import { getWeeklyRecommendations } from "../api/recommendation.api";
import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { toast } from "sonner";
import { useAuthStore } from "../store/auth.store";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  CartesianGrid,
  Legend,
} from "recharts";
import { Activity, Beef, Dumbbell, Flame, Soup, Trophy } from "lucide-react";
import PageHeader from "../components/PageHeader";
import PageLoading from "../components/common/PageLoading";
import ErrorState from "../components/common/ErrorState";
import EmptyState from "../components/common/EmptyState";
import MacroProgressCard from "../components/MacroProgressCard";
import RecommendationCard from "../components/RecommendationCard";

export default function DashboardPage() {
  const queryClient = useQueryClient();
  const authUser = useAuthStore((state) => state.user);

  const seedMutation = useMutation({
    mutationFn: seedDemoData,
    onSuccess: (data) => {
      toast.success(data.message);

      queryClient.invalidateQueries();
    },
    onError: (error) => {
      const message = axios.isAxiosError<{ message?: string }>(error)
        ? error.response?.data?.message
        : undefined;
      toast.error(message || "Cannot seed demo data");
    },
  });

  const todayQuery = useQuery({
    queryKey: ["dashboard-today"],
    queryFn: getTodayDashboard,
  });

  const progressQuery = useQuery({
    queryKey: ["dashboard-progress"],
    queryFn: getProgressDashboard,
  });

  const recommendationQuery = useQuery({
    queryKey: ["weekly-recommendations"],
    queryFn: () => getWeeklyRecommendations(),
  });

  const achievementQuery = useQuery({
    queryKey: ["achievements"],
    queryFn: getAchievementSummary,
  });

  if (todayQuery.isLoading || progressQuery.isLoading) {
    return <PageLoading />;
  }

  if (todayQuery.isError || progressQuery.isError) {
    return <ErrorState title="Cannot load dashboard" message="Please check your connection or login again." />;
  }

  const today = todayQuery.data;
  const points = progressQuery.data?.points ?? [];
  const topRecommendations = recommendationQuery.data?.recommendations.slice(0, 2) ?? [];

  if (!today) {
    return <ErrorState title="Cannot load dashboard" message="Please check your connection or login again." />;
  }

  const cards = [
    {
      title: "Calories",
      value: today.totalCalories,
      detail: "kcal hôm nay",
      icon: Flame,
      tone: "from-amber-50 to-orange-50/50 text-orange-700 bg-orange-100",
    },
    {
      title: "Protein",
      value: `${today.totalProtein}g`,
      detail: "đã nạp",
      icon: Beef,
      tone: "from-rose-50 to-pink-50/50 text-rose-700 bg-rose-100",
    },
    {
      title: "Meals",
      value: today.mealCount,
      detail: "bữa đã ghi",
      icon: Activity,
      tone: "from-emerald-50 to-teal-50/50 text-emerald-700 bg-emerald-100",
    },
    {
      title: "Workouts",
      value: today.workoutCount,
      detail: "buổi tập",
      icon: Dumbbell,
      tone: "from-blue-50 to-indigo-50/50 text-blue-700 bg-blue-100",
    },
  ];

  return (
    <div className="space-y-5 md:space-y-7">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader title="Tổng quan hôm nay" description="Theo dõi luyện tập, dinh dưỡng và tiến độ cơ thể của bạn." />
        <div className="flex flex-wrap gap-2">
          <Button asChild variant="outline" className="border-emerald-200 bg-emerald-50 text-emerald-800">
            <Link to="/lunch">
              <Soup className="size-4" />
              Đặt cơm hôm nay
            </Link>
          </Button>
          {authUser?.role === "ADMIN" && (
            <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
              {seedMutation.isPending ? "Đang tạo..." : "Tạo dữ liệu mẫu"}
            </Button>
          )}
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {cards.map((card) => {
          const Icon = card.icon;
          const [gradient, , iconText, iconBg] = card.tone.split(" ");

          return (
            <Card key={card.title} className={`border-0 bg-gradient-to-br ${gradient} ${card.tone.split(" ")[1]}`}>
              <CardHeader className="flex flex-row items-center justify-between pb-0">
                <CardTitle className="text-sm text-muted-foreground">{card.title}</CardTitle>
                <span className={`grid size-9 place-items-center rounded-xl ${iconBg} ${iconText}`}>
                  <Icon className="size-4" />
                </span>
              </CardHeader>

              <CardContent>
                <p className="text-3xl font-semibold tracking-[-0.04em]">{card.value}</p>
                <p className="mt-1 text-xs text-muted-foreground">{card.detail}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
        <MacroProgressCard
          title="Calories Goal"
          current={today.totalCalories}
          target={today.targetCalories}
          unit="kcal"
          percent={today.caloriesProgressPercent}
        />

        <MacroProgressCard
          title="Protein Goal"
          current={today.totalProtein}
          target={today.targetProtein}
          unit="g"
          percent={today.proteinProgressPercent}
        />

        <MacroProgressCard
          title="Carbs Goal"
          current={today.totalCarbs}
          target={today.targetCarbs}
          unit="g"
          percent={today.carbsProgressPercent}
        />

        <MacroProgressCard
          title="Fat Goal"
          current={today.totalFat}
          target={today.targetFat}
          unit="g"
          percent={today.fatProgressPercent}
        />
      </div>

      {topRecommendations.length > 0 && (
        <div className="space-y-4">
          <h2 className="text-xl font-semibold">Smart Suggestions</h2>

          <div className="grid gap-4 md:grid-cols-2">
            {topRecommendations.map((item, index) => (
              <RecommendationCard key={index} item={item} />
            ))}
          </div>
        </div>
      )}

      {achievementQuery.data && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Trophy className="h-5 w-5" />
              Achievement Progress
            </CardTitle>
          </CardHeader>

          <CardContent className="grid gap-4 md:grid-cols-4">
            <div className="rounded-xl bg-emerald-50 p-4">
              <p className="text-sm text-muted-foreground">Meal Streak</p>
              <p className="text-xl font-bold md:text-2xl">{achievementQuery.data.mealLoggingStreak} days</p>
            </div>

            <div className="rounded-xl bg-blue-50 p-4">
              <p className="text-sm text-muted-foreground">Workout Streak</p>
              <p className="text-xl font-bold md:text-2xl">{achievementQuery.data.workoutStreak} days</p>
            </div>

            <div className="rounded-xl bg-amber-50 p-4">
              <p className="text-sm text-muted-foreground">Protein Hits</p>
              <p className="text-xl font-bold md:text-2xl">{achievementQuery.data.proteinHitDaysThisWeek}</p>
            </div>

            <div className="rounded-xl bg-violet-50 p-4">
              <p className="text-sm text-muted-foreground">Body Logs</p>
              <p className="text-xl font-bold md:text-2xl">{achievementQuery.data.bodyTrackingDaysThisWeek}</p>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid gap-4 md:gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Weight & Waist Progress</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[320px]">
            {points.length === 0 ? (
              <EmptyState
                title="No progress data yet"
                description="Add body measurements and meal logs to see your progress chart."
              />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={points}>
                  <CartesianGrid strokeDasharray="4 4" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="date" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis yAxisId="weight" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis
                    yAxisId="waist"
                    orientation="right"
                    tick={{ fontSize: 11 }}
                    tickLine={false}
                    axisLine={false}
                  />
                  <Tooltip />
                  <Legend />
                  <Line
                    yAxisId="weight"
                    type="monotone"
                    dataKey="weight"
                    name="Cân nặng (kg)"
                    stroke="#059669"
                    strokeWidth={2.5}
                    dot={false}
                  />
                  <Line
                    yAxisId="waist"
                    type="monotone"
                    dataKey="waist"
                    name="Vòng eo (cm)"
                    stroke="#f59e0b"
                    strokeWidth={2.5}
                    dot={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Calories & Protein</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[320px]">
            {points.length === 0 ? (
              <EmptyState title="No nutrition trend yet" description="Log meals to see calories and protein trends." />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={points}>
                  <CartesianGrid strokeDasharray="4 4" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="date" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis yAxisId="calories" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis
                    yAxisId="protein"
                    orientation="right"
                    tick={{ fontSize: 11 }}
                    tickLine={false}
                    axisLine={false}
                  />
                  <Tooltip />
                  <Legend />
                  <Bar
                    yAxisId="calories"
                    dataKey="calories"
                    name="Calories (kcal)"
                    fill="#10b981"
                    radius={[5, 5, 0, 0]}
                  />
                  <Bar
                    yAxisId="protein"
                    dataKey="protein"
                    name="Protein (g)"
                    fill="#f59e0b"
                    radius={[5, 5, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>

      <Card className="border-emerald-200 bg-gradient-to-r from-emerald-50 to-white">
        <CardHeader>
          <CardTitle>Weekly Report</CardTitle>
        </CardHeader>

        <CardContent className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-muted-foreground">Review your weekly nutrition, workouts and body progress.</p>

          <Button asChild>
            <Link to="/reports/weekly">View Report</Link>
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Latest Workout</CardTitle>
        </CardHeader>
        <CardContent>{today.latestWorkoutNote ?? "No workout today"}</CardContent>
      </Card>
    </div>
  );
}
