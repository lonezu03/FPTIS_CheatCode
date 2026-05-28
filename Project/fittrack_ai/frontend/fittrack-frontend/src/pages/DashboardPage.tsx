import { getProgressDashboard, getTodayDashboard } from "../api/dashboard.api";
import { useQuery } from "@tanstack/react-query";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts";
import { Activity, Beef, Dumbbell, Flame } from "lucide-react";
import PageHeader from "../components/PageHeader";
import PageLoading from "../components/common/PageLoading";
import ErrorState from "../components/common/ErrorState";
import EmptyState from "../components/common/EmptyState";

export default function DashboardPage() {
  const todayQuery = useQuery({
    queryKey: ["dashboard-today"],
    queryFn: getTodayDashboard,
  });

  const progressQuery = useQuery({
    queryKey: ["dashboard-progress"],
    queryFn: getProgressDashboard,
  });

  if (todayQuery.isLoading || progressQuery.isLoading) {
    return <PageLoading />;
  }

  if (todayQuery.isError || progressQuery.isError) {
    return <ErrorState title="Cannot load dashboard" message="Please check your connection or login again." />;
  }

  const today = todayQuery.data;
  const points = progressQuery.data?.points ?? [];

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
          <CardTitle>Latest Workout</CardTitle>
        </CardHeader>
        <CardContent>{today.latestWorkoutNote ?? "No workout today"}</CardContent>
      </Card>
    </div>
  );
}
