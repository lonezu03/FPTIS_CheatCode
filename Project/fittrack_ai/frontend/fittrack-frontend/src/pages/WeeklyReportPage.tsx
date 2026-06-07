import { useState } from "react";
import type { ElementType } from "react";
import { useQuery } from "@tanstack/react-query";
import { getWeeklyRecommendations, type WeeklyRecommendation } from "../api/recommendation.api";
import { getWeeklyReport, type WeeklyReport } from "../api/report.api";

import PageHeader from "../components/PageHeader";
import MacroProgressCard from "../components/MacroProgressCard";
import RecommendationCard from "../components/RecommendationCard";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import PageLoading from "../components/common/PageLoading";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

import { Bar, BarChart, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { Beef, CalendarDays, Dumbbell, Flame, Lightbulb, Ruler, Scale, Utensils } from "lucide-react";

function getDefaultToDate() {
  return new Date().toISOString().slice(0, 10);
}

function getDefaultFromDate() {
  const date = new Date();
  date.setDate(date.getDate() - 6);

  return date.toISOString().slice(0, 10);
}

export default function WeeklyReportPage() {
  const [fromDate, setFromDate] = useState(getDefaultFromDate());
  const [toDate, setToDate] = useState(getDefaultToDate());

  const reportQuery = useQuery({
    queryKey: ["weekly-report", fromDate, toDate],
    queryFn: () => getWeeklyReport({ fromDate, toDate }),
  });

  const recommendationQuery = useQuery({
    queryKey: ["weekly-recommendations", fromDate, toDate],
    queryFn: () => getWeeklyRecommendations({ fromDate, toDate }),
  });

  const report = reportQuery.data;
  const recommendations = recommendationQuery.data;

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader
        title="Weekly Report"
        description="Review your weekly nutrition, training consistency and body progress."
      />

      <Card>
        <CardHeader>
          <CardTitle>Report Range</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-3">
          <Input type="date" value={fromDate} onChange={(event) => setFromDate(event.target.value)} />

          <Input type="date" value={toDate} onChange={(event) => setToDate(event.target.value)} />

          <Button
            variant="outline"
            onClick={() => {
              setFromDate(getDefaultFromDate());
              setToDate(getDefaultToDate());
            }}
          >
            Reset to last 7 days
          </Button>
        </CardContent>
      </Card>

      {reportQuery.isLoading && <PageLoading />}

      {reportQuery.isError && (
        <ErrorState title="Cannot load weekly report" message="Please check your connection or login again." />
      )}

      {report && <WeeklyReportContent report={report} recommendations={recommendations} />}
    </div>
  );
}

function WeeklyReportContent({
  report,
  recommendations,
}: {
  report: WeeklyReport;
  recommendations?: WeeklyRecommendation;
}) {
  const overviewCards = [
    {
      title: "Avg Calories",
      value: report.averageCalories,
      suffix: "kcal",
      icon: Flame,
    },
    {
      title: "Avg Protein",
      value: report.averageProtein,
      suffix: "g",
      icon: Beef,
    },
    {
      title: "Meals",
      value: report.totalMeals,
      suffix: "",
      icon: Utensils,
    },
    {
      title: "Workouts",
      value: report.totalWorkouts,
      suffix: "",
      icon: Dumbbell,
    },
  ];

  return (
    <>
      <div className="flex flex-wrap gap-2">
        <Badge variant="secondary">
          <CalendarDays className="mr-1 h-3 w-3" />
          {report.fromDate} - {report.toDate}
        </Badge>

        <Badge variant="secondary">{report.workoutDays} workout days</Badge>
      </div>

      <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
        {overviewCards.map((item) => {
          const Icon = item.icon;

          return (
            <Card key={item.title}>
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle className="text-sm text-muted-foreground">{item.title}</CardTitle>
                <Icon className="h-5 w-5 text-muted-foreground" />
              </CardHeader>

              <CardContent>
                <p className="text-2xl font-bold md:text-3xl">
                  {item.value}
                  {item.suffix && <span className="ml-1 text-sm font-normal text-muted-foreground">{item.suffix}</span>}
                </p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
        <MacroProgressCard
          title="Calories Compliance"
          current={report.averageCalories}
          target={report.targetCalories}
          unit="kcal"
          percent={report.caloriesCompliancePercent}
        />

        <MacroProgressCard
          title="Protein Compliance"
          current={report.averageProtein}
          target={report.targetProtein}
          unit="g"
          percent={report.proteinCompliancePercent}
        />

        <BodyChangeCard
          title="Weight Change"
          start={report.startWeight}
          end={report.endWeight}
          change={report.weightChange}
          unit="kg"
          icon={Scale}
        />

        <BodyChangeCard
          title="Waist Change"
          start={report.startWaist}
          end={report.endWaist}
          change={report.waistChange}
          unit="cm"
          icon={Ruler}
        />
      </div>

      <div className="grid gap-4 md:gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Daily Calories</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[320px]">
            {report.dailyNutrition.length === 0 ? (
              <EmptyState title="No nutrition data" description="Log meals during this range to see calorie trends." />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={report.dailyNutrition}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="calories" />
                  <Bar dataKey="targetCalories" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Daily Protein</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[320px]">
            {report.dailyNutrition.length === 0 ? (
              <EmptyState title="No protein data" description="Log meals during this range to see protein trends." />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={report.dailyNutrition}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="protein" strokeWidth={2} />
                  <Line type="monotone" dataKey="targetProtein" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>
            <div className="flex items-center gap-2">
              <Lightbulb className="h-5 w-5" />
              Weekly Insights
            </div>
          </CardTitle>
        </CardHeader>

        <CardContent>
          {report.insights.length === 0 ? (
            <EmptyState title="No insights yet" description="Add more nutrition, workout and body data for this range." />
          ) : (
            <ul className="space-y-3">
              {report.insights.map((insight, index) => (
                <li key={index} className="rounded-xl border bg-slate-50 p-3 text-sm sm:p-4">
                  {insight}
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Smart Recommendations</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          {recommendations ? (
            recommendations.recommendations.length === 0 ? (
              <EmptyState title="No recommendations yet" description={recommendations.summary} />
            ) : (
              <>
                <div className="rounded-xl bg-slate-50 p-4 text-sm text-muted-foreground">{recommendations.summary}</div>

                <div className="grid gap-4 md:grid-cols-2">
                  {recommendations.recommendations.map((item, index) => (
                    <RecommendationCard key={index} item={item} />
                  ))}
                </div>
              </>
            )
          ) : (
            <p className="text-sm text-muted-foreground">Loading recommendations...</p>
          )}
        </CardContent>
      </Card>
    </>
  );
}

function BodyChangeCard({
  title,
  start,
  end,
  change,
  unit,
  icon: Icon,
}: {
  title: string;
  start: number | null;
  end: number | null;
  change: number | null;
  unit: string;
  icon: ElementType;
}) {
  const displayChange = change == null ? "No data" : `${change > 0 ? "+" : ""}${change} ${unit}`;

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-sm text-muted-foreground">{title}</CardTitle>
        <Icon className="h-5 w-5 text-muted-foreground" />
      </CardHeader>

      <CardContent>
        <p className="text-xl font-bold md:text-2xl">{displayChange}</p>

        {start != null && end != null && (
          <p className="mt-1 text-sm text-muted-foreground">
            {start} - {end} {unit}
          </p>
        )}
      </CardContent>
    </Card>
  );
}
