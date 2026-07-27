import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { Activity, Beef, Dumbbell, Flame, Soup, Trophy } from "lucide-react";
import { toast } from "sonner";
import { getAchievementSummary } from "../api/achievement.api";
import { getProgressDashboard, getTodayDashboard } from "../api/dashboard.api";
import { seedDemoData } from "../api/demo.api";
import { getWeeklyRecommendations } from "../api/recommendation.api";
import { useAuthStore } from "../store/auth.store";
import ErrorState from "../components/common/ErrorState";
import PageLoading from "../components/common/PageLoading";
import FitnessTrendCharts from "../components/FitnessTrendCharts";
import MacroProgressCard from "../components/MacroProgressCard";
import PageHeader from "../components/PageHeader";
import RecommendationCard from "../components/RecommendationCard";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

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
      toast.error(message || "Không thể tạo dữ liệu mẫu");
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

  if (todayQuery.isError || progressQuery.isError || !todayQuery.data) {
    return (
      <ErrorState
        title="Không thể tải trang tổng quan"
        message="Vui lòng kiểm tra kết nối hoặc đăng nhập lại."
      />
    );
  }

  const today = todayQuery.data;
  const points = progressQuery.data?.points ?? [];
  const topRecommendations = recommendationQuery.data?.recommendations.slice(0, 2) ?? [];

  const cards = [
    {
      title: "Năng lượng",
      value: today.totalCalories,
      detail: "kcal hôm nay",
      icon: Flame,
      cardClass: "from-amber-50 to-orange-50/50",
      iconClass: "bg-orange-100 text-orange-700",
    },
    {
      title: "Chất đạm",
      value: `${today.totalProtein}g`,
      detail: "đã nạp",
      icon: Beef,
      cardClass: "from-rose-50 to-pink-50/50",
      iconClass: "bg-rose-100 text-rose-700",
    },
    {
      title: "Bữa ăn",
      value: today.mealCount,
      detail: "bữa đã ghi",
      icon: Activity,
      cardClass: "from-emerald-50 to-teal-50/50",
      iconClass: "bg-emerald-100 text-emerald-700",
    },
    {
      title: "Luyện tập",
      value: today.workoutCount,
      detail: "buổi tập",
      icon: Dumbbell,
      cardClass: "from-blue-50 to-indigo-50/50",
      iconClass: "bg-blue-100 text-blue-700",
    },
  ];

  return (
    <div className="space-y-5 md:space-y-7">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <PageHeader
          title="Tổng quan hôm nay"
          description="Theo dõi dinh dưỡng, luyện tập và tiến độ cơ thể của bạn."
        />
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

          return (
            <Card key={card.title} className={`border-0 bg-gradient-to-br ${card.cardClass}`}>
              <CardHeader className="flex flex-row items-center justify-between pb-0">
                <CardTitle className="text-sm text-muted-foreground">{card.title}</CardTitle>
                <span className={`grid size-9 place-items-center rounded-xl ${card.iconClass}`}>
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
          title="Mục tiêu năng lượng"
          current={today.totalCalories}
          target={today.targetCalories}
          unit="kcal"
          percent={today.caloriesProgressPercent}
        />
        <MacroProgressCard
          title="Mục tiêu chất đạm"
          current={today.totalProtein}
          target={today.targetProtein}
          unit="g"
          percent={today.proteinProgressPercent}
        />
        <MacroProgressCard
          title="Mục tiêu tinh bột"
          current={today.totalCarbs}
          target={today.targetCarbs}
          unit="g"
          percent={today.carbsProgressPercent}
        />
        <MacroProgressCard
          title="Mục tiêu chất béo"
          current={today.totalFat}
          target={today.targetFat}
          unit="g"
          percent={today.fatProgressPercent}
        />
      </div>

      {topRecommendations.length > 0 && (
        <section className="space-y-4">
          <h2 className="text-xl font-semibold">Gợi ý dành cho bạn</h2>
          <div className="grid gap-4 md:grid-cols-2">
            {topRecommendations.map((item, index) => (
              <RecommendationCard key={index} item={item} />
            ))}
          </div>
        </section>
      )}

      {achievementQuery.data && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Trophy className="size-5 text-amber-600" />
              Thành tích tuần này
            </CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2 md:grid-cols-4">
            <AchievementMetric
              label="Chuỗi ngày ghi bữa"
              value={`${achievementQuery.data.mealLoggingStreak} ngày`}
              className="bg-emerald-50"
            />
            <AchievementMetric
              label="Chuỗi ngày tập"
              value={`${achievementQuery.data.workoutStreak} ngày`}
              className="bg-blue-50"
            />
            <AchievementMetric
              label="Ngày đạt protein"
              value={achievementQuery.data.proteinHitDaysThisWeek}
              className="bg-amber-50"
            />
            <AchievementMetric
              label="Ngày ghi số đo"
              value={achievementQuery.data.bodyTrackingDaysThisWeek}
              className="bg-violet-50"
            />
          </CardContent>
        </Card>
      )}

      <FitnessTrendCharts points={points} />

      <Card className="border-emerald-200 bg-gradient-to-r from-emerald-50 to-white">
        <CardHeader>
          <CardTitle>Báo cáo hằng tuần</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-muted-foreground">
            Xem lại dinh dưỡng, luyện tập và thay đổi cơ thể trong tuần.
          </p>
          <Button asChild>
            <Link to="/reports/weekly">Xem báo cáo</Link>
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Buổi tập gần nhất hôm nay</CardTitle>
        </CardHeader>
        <CardContent className="text-sm text-muted-foreground">
          {today.latestWorkoutNote ?? "Hôm nay chưa ghi nhận buổi tập."}
        </CardContent>
      </Card>
    </div>
  );
}

function AchievementMetric({
  label,
  value,
  className,
}: {
  label: string;
  value: string | number;
  className: string;
}) {
  return (
    <div className={`rounded-xl p-4 ${className}`}>
      <p className="text-sm text-muted-foreground">{label}</p>
      <p className="mt-1 text-xl font-bold md:text-2xl">{value}</p>
    </div>
  );
}
