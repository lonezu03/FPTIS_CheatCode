import { getAchievementSummary } from "../api/achievement.api";
import { getProgressDashboard, getTodayDashboard } from "../api/dashboard.api";
import { seedDemoData } from "../api/demo.api";
import { getWeeklyRecommendations } from "../api/recommendation.api";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts";
import { Activity, Beef, Dumbbell, Flame, Trophy } from "lucide-react";
import PageHeader from "../components/PageHeader";
import PageLoading from "../components/common/PageLoading";
import ErrorState from "../components/common/ErrorState";
import EmptyState from "../components/common/EmptyState";
import MacroProgressCard from "../components/MacroProgressCard";
import RecommendationCard from "../components/RecommendationCard";

export default function DashboardPage() {
  const queryClient = useQueryClient();

  const seedMutation = useMutation({
    mutationFn: seedDemoData,
    onSuccess: (data) => {
      toast.success(data.message);

      queryClient.invalidateQueries();
    },
    onError: (err: any) => {
      toast.error(err.response?.data?.message || "Cannot seed demo data");
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
    { title: "Calories", value: today.totalCalories, icon: Flame },
    { title: "Protein", value: `${today.totalProtein}g`, icon: Beef },
    { title: "Meals", value: today.mealCount, icon: Activity },
    { title: "Workouts", value: today.workoutCount, icon: Dumbbell },
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Dashboard" description="Track your training, nutrition and body progress." />

      <div className="flex justify-end">
        <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending}>
          {seedMutation.isPending ? "Seeding..." : "Seed Demo Data"}
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
        {cards.map((card) => {
          const Icon = card.icon;

          return (
            <Card key={card.title}>
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle className="text-sm text-muted-foreground">{card.title}</CardTitle>
                <Icon className="h-5 w-5 text-muted-foreground" />
              </CardHeader>

              <CardContent>
                <p className="text-3xl font-bold">{card.value}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
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
            <div className="rounded-xl bg-slate-100 p-4">
              <p className="text-sm text-muted-foreground">Meal Streak</p>
              <p className="text-2xl font-bold">{achievementQuery.data.mealLoggingStreak} days</p>
            </div>

            <div className="rounded-xl bg-slate-100 p-4">
              <p className="text-sm text-muted-foreground">Workout Streak</p>
              <p className="text-2xl font-bold">{achievementQuery.data.workoutStreak} days</p>
            </div>

            <div className="rounded-xl bg-slate-100 p-4">
              <p className="text-sm text-muted-foreground">Protein Hits</p>
              <p className="text-2xl font-bold">{achievementQuery.data.proteinHitDaysThisWeek}</p>
            </div>

            <div className="rounded-xl bg-slate-100 p-4">
              <p className="text-sm text-muted-foreground">Body Logs</p>
              <p className="text-2xl font-bold">{achievementQuery.data.bodyTrackingDaysThisWeek}</p>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Weight & Waist Progress</CardTitle>
          </CardHeader>

          <CardContent className="h-[320px]">
            {points.length === 0 ? (
              <EmptyState
                title="No progress data yet"
                description="Add body measurements and meal logs to see your progress chart."
              />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={points}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="weight" strokeWidth={2} />
                  <Line type="monotone" dataKey="waist" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Calories & Protein</CardTitle>
          </CardHeader>

          <CardContent className="h-[320px]">
            {points.length === 0 ? (
              <EmptyState title="No nutrition trend yet" description="Log meals to see calories and protein trends." />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={points}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="calories" />
                  <Bar dataKey="protein" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
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
