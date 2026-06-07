import { useQuery } from "@tanstack/react-query";
import { getAchievementSummary } from "../api/achievement.api";

import PageHeader from "../components/PageHeader";
import AchievementCard from "../components/AchievementCard";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import PageLoading from "../components/common/PageLoading";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dumbbell, Scale, Target, Utensils } from "lucide-react";

export default function AchievementsPage() {
  const summaryQuery = useQuery({
    queryKey: ["achievements"],
    queryFn: getAchievementSummary,
  });

  if (summaryQuery.isLoading) {
    return <PageLoading />;
  }

  if (summaryQuery.isError || !summaryQuery.data) {
    return <ErrorState title="Cannot load achievements" message="Please try refreshing the page." />;
  }

  const summary = summaryQuery.data;

  const stats = [
    {
      title: "Meal Streak",
      value: summary.mealLoggingStreak,
      suffix: "days",
      icon: Utensils,
    },
    {
      title: "Workout Streak",
      value: summary.workoutStreak,
      suffix: "days",
      icon: Dumbbell,
    },
    {
      title: "Protein Hit Days",
      value: summary.proteinHitDaysThisWeek,
      suffix: "this week",
      icon: Target,
    },
    {
      title: "Body Tracking Days",
      value: summary.bodyTrackingDaysThisWeek,
      suffix: "this week",
      icon: Scale,
    },
  ];

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Achievements" description="Track consistency, streaks, and weekly progress milestones." />

      <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;

          return (
            <Card key={stat.title}>
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle className="text-sm text-muted-foreground">{stat.title}</CardTitle>
                <Icon className="h-5 w-5 text-muted-foreground" />
              </CardHeader>

              <CardContent>
                <p className="text-2xl font-bold md:text-3xl">
                  {stat.value}
                  <span className="ml-1 text-sm font-normal text-muted-foreground">{stat.suffix}</span>
                </p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {summary.achievements.length === 0 ? (
        <EmptyState title="No achievements yet" description="Keep logging meals, workouts and body measurements to unlock milestones." />
      ) : (
        <div className="grid gap-4 md:grid-cols-2 md:gap-6">
          {summary.achievements.map((achievement) => (
            <AchievementCard key={achievement.code} achievement={achievement} />
          ))}
        </div>
      )}
    </div>
  );
}
