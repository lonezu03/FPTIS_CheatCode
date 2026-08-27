import { useState } from "react";
import type { ElementType } from "react";
import { useQuery } from "@tanstack/react-query";
import { getWeeklyRecommendations, type WeeklyRecommendation } from "../api/recommendation.api";
import { getWeeklyReport, type WeeklyReport } from "../api/report.api";
import { toLocalDateInput } from "../lib/format";

import PageHeader from "../components/PageHeader";
import MacroProgressCard from "../components/MacroProgressCard";
import RecommendationCard from "../components/RecommendationCard";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import FormField from "../components/common/FormField";
import PageLoading from "../components/common/PageLoading";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

import { Bar, BarChart, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { Beef, CalendarDays, Dumbbell, Flame, Lightbulb, Ruler, Scale, Utensils } from "lucide-react";

function getDefaultToDate() {
  return toLocalDateInput();
}

function getDefaultFromDate() {
  const date = new Date();
  date.setDate(date.getDate() - 6);

  return toLocalDateInput(date);
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
        title="Báo cáo tuần"
        description="Đánh giá dinh dưỡng, mức độ luyện tập đều đặn và tiến độ cơ thể."
      />

      <Card>
        <CardHeader>
          <CardTitle>Khoảng báo cáo</CardTitle>
        </CardHeader>

        <CardContent className="grid items-end gap-4 md:grid-cols-3">
          <FormField label="Từ ngày" hint="Ngày bắt đầu của khoảng báo cáo.">
            <Input type="date" value={fromDate} onChange={(event) => setFromDate(event.target.value)} />
          </FormField>

          <FormField label="Đến ngày" hint="Ngày kết thúc của khoảng báo cáo.">
            <Input type="date" value={toDate} onChange={(event) => setToDate(event.target.value)} />
          </FormField>

          <Button
            variant="outline"
            onClick={() => {
              setFromDate(getDefaultFromDate());
              setToDate(getDefaultToDate());
            }}
          >
            Đặt lại 7 ngày gần nhất
          </Button>
        </CardContent>
      </Card>

      {reportQuery.isLoading && <PageLoading />}

      {reportQuery.isError && (
        <ErrorState title="Không thể tải báo cáo tuần" message="Vui lòng kiểm tra kết nối hoặc đăng nhập lại." />
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
      title: "Năng lượng trung bình",
      value: report.averageCalories,
      suffix: "kcal",
      icon: Flame,
    },
    {
      title: "Protein trung bình",
      value: report.averageProtein,
      suffix: "g",
      icon: Beef,
    },
    {
      title: "Bữa ăn",
      value: report.totalMeals,
      suffix: "",
      icon: Utensils,
    },
    {
      title: "Buổi tập",
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

        <Badge variant="secondary">{report.workoutDays} ngày luyện tập</Badge>
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

      <div className="rounded-2xl border border-emerald-200 bg-emerald-50/60 p-4 sm:p-5">
        <div className="flex items-start gap-3"><Lightbulb className="mt-0.5 size-5 shrink-0 text-emerald-700"/><div><p className="font-semibold text-emerald-950">Tóm tắt để hành động</p><p className="mt-1 text-sm leading-6 text-emerald-900/70">{buildActionSummary(report)}</p></div></div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
        <MacroProgressCard
          title="Mức đạt năng lượng"
          current={report.averageCalories}
          target={report.targetCalories}
          unit="kcal"
          percent={report.caloriesCompliancePercent}
        />

        <MacroProgressCard
          title="Mức đạt protein"
          current={report.averageProtein}
          target={report.targetProtein}
          unit="g"
          percent={report.proteinCompliancePercent}
        />

        <BodyChangeCard
          title="Thay đổi cân nặng"
          start={report.startWeight}
          end={report.endWeight}
          change={report.weightChange}
          unit="kg"
          icon={Scale}
        />

        <BodyChangeCard
          title="Thay đổi vòng eo"
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
            <CardTitle>Năng lượng mỗi ngày</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[320px]">
            {report.dailyNutrition.length === 0 ? (
              <EmptyState title="Chưa có dữ liệu dinh dưỡng" description="Ghi bữa ăn trong khoảng này để xem xu hướng năng lượng." />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={report.dailyNutrition}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="calories" name="Năng lượng thực tế" />
                  <Bar dataKey="targetCalories" name="Mục tiêu năng lượng" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Chất đạm mỗi ngày</CardTitle>
          </CardHeader>

          <CardContent className="h-[240px] md:h-[320px]">
            {report.dailyNutrition.length === 0 ? (
              <EmptyState title="Chưa có dữ liệu chất đạm" description="Ghi bữa ăn trong khoảng này để xem xu hướng chất đạm." />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={report.dailyNutrition}>
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="protein" name="Protein thực tế" strokeWidth={2} />
                  <Line type="monotone" dataKey="targetProtein" name="Mục tiêu protein" strokeWidth={2} />
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
              Nhận xét trong tuần
            </div>
          </CardTitle>
        </CardHeader>

        <CardContent>
          {report.insights.length === 0 ? (
            <EmptyState title="Chưa có nhận xét" description="Thêm dữ liệu dinh dưỡng, buổi tập và cơ thể trong khoảng này." />
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
          <CardTitle>Khuyến nghị thông minh</CardTitle>
        </CardHeader>

        <CardContent className="space-y-4">
          {recommendations ? (
            recommendations.recommendations.length === 0 ? (
              <EmptyState title="Chưa có khuyến nghị" description={recommendations.summary} />
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
            <p className="text-sm text-muted-foreground">Đang tải khuyến nghị...</p>
          )}
        </CardContent>
      </Card>
    </>
  );
}

function buildActionSummary(report: WeeklyReport) {
  if (report.totalMeals === 0 && report.totalWorkouts === 0) return "Chưa đủ dữ liệu để đánh giá. Hãy bắt đầu bằng việc ghi một bữa ăn và một hoạt động trong hôm nay.";
  if (report.caloriesCompliancePercent < 85) return "Năng lượng trung bình đang thấp. Ưu tiên thêm một bữa phụ có tinh bột lành mạnh và theo dõi phản hồi cơ thể trong 2–3 ngày.";
  if (report.proteinCompliancePercent < 85) return "Protein đang dưới mục tiêu. Chọn trước một nguồn đạm cho bữa tiếp theo thay vì cố bù dồn vào cuối ngày.";
  if (report.workoutDays < 3) return "Tuần này vận động chưa đều. Đặt ngay một lịch tập ngắn 20–30 phút để tạo điểm neo cho tuần sau.";
  return "Các chỉ số chính đang đi đúng hướng. Giữ nguyên thói quen hiện tại và chỉ thay đổi một yếu tố mỗi tuần để biết điều gì thực sự hiệu quả.";
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
  const displayChange = change == null ? "Chưa có dữ liệu" : `${change > 0 ? "+" : ""}${change} ${unit}`;

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
