import { useEffect, useState } from "react";
import {
  getProgressDashboard,
  getTodayDashboard,
  type DashboardToday,
  type ProgressPoint,
} from "../api/dashboard.api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts";
import { Activity, Beef, Dumbbell, Flame } from "lucide-react";

export default function DashboardPage() {
  const [today, setToday] = useState<DashboardToday | null>(null);
  const [points, setPoints] = useState<ProgressPoint[]>([]);

  useEffect(() => {
    getTodayDashboard().then(setToday);
    getProgressDashboard().then((response) => setPoints(response.points));
  }, []);

  if (!today) {
    return <div>Loading dashboard...</div>;
  }

  const cards = [
    { title: "Calories", value: today.totalCalories, icon: Flame },
    { title: "Protein", value: `${today.totalProtein}g`, icon: Beef },
    { title: "Meals", value: today.mealCount, icon: Activity },
    { title: "Workouts", value: today.workoutCount, icon: Dumbbell },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground">Track your training, nutrition and body progress.</p>
      </div>

      <div className="grid gap-6 md:grid-cols-4">
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
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={points}>
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Line type="monotone" dataKey="weight" strokeWidth={2} />
                <Line type="monotone" dataKey="waist" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Calories & Protein</CardTitle>
          </CardHeader>

          <CardContent className="h-[320px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={points}>
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="calories" />
                <Bar dataKey="protein" />
              </BarChart>
            </ResponsiveContainer>
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
