import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { ArrowRight, Beef, CheckCircle2, ChefHat, Dumbbell, Flame, ListTodo, Soup, Trophy } from "lucide-react";
import { toast } from "sonner";
import { getAchievementSummary } from "../api/achievement.api";
import { getProgressDashboard, getTodayDashboard } from "../api/dashboard.api";
import { seedDemoData } from "../api/demo.api";
import { getWeeklyRecommendations } from "../api/recommendation.api";
import { useAuthStore } from "../store/auth.store";
import ErrorState from "../components/common/ErrorState";
import PageLoading from "../components/common/PageLoading";
import DeferredFitnessTrendCharts from "../components/DeferredFitnessTrendCharts";
import MacroProgressCard from "../components/MacroProgressCard";
import PageHeader from "../components/PageHeader";
import RecommendationCard from "../components/RecommendationCard";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function DashboardPage() {
  const queryClient = useQueryClient();
  const authUser = useAuthStore((state) => state.user);
  const seedMutation = useMutation({ mutationFn: seedDemoData, onSuccess: (data) => { toast.success(data.message); queryClient.invalidateQueries(); }, onError: (error) => { const message = axios.isAxiosError<{ message?: string }>(error) ? error.response?.data?.message : undefined; toast.error(message || "Không thể tạo dữ liệu mẫu"); } });
  const todayQuery = useQuery({ queryKey: ["dashboard-today"], queryFn: getTodayDashboard });
  const today = todayQuery.data;
  const fitnessEnabled = today?.fitnessEnabled ?? authUser?.fitnessEnabled ?? false;
  const healthEnabled = today?.healthEnabled ?? authUser?.healthEnabled ?? false;
  const lunchEnabled = today?.lunchEnabled ?? authUser?.lunchEnabled ?? false;
  const todoEnabled = today?.todoEnabled ?? authUser?.todoEnabled ?? false;
  const scheduleEnabled = today?.scheduleEnabled ?? authUser?.scheduleEnabled ?? false;
  const progressQuery = useQuery({ queryKey: ["dashboard-progress"], queryFn: getProgressDashboard, enabled: fitnessEnabled || healthEnabled });
  const recommendationQuery = useQuery({ queryKey: ["weekly-recommendations"], queryFn: () => getWeeklyRecommendations(), enabled: healthEnabled });
  const achievementQuery = useQuery({ queryKey: ["achievements"], queryFn: getAchievementSummary, enabled: fitnessEnabled });
  if (todayQuery.isLoading || (fitnessEnabled && progressQuery.isLoading)) return <PageLoading />;
  if (todayQuery.isError || !today) return <ErrorState title="Không thể tải trang tổng quan" message="Vui lòng kiểm tra kết nối hoặc đăng nhập lại." />;
  const points = progressQuery.data?.points ?? [];
  const topRecommendations = recommendationQuery.data?.recommendations.slice(0, 2) ?? [];
  const cards = [
    { title: "Bữa hôm nay", value: today.mealCount, detail: lunchEnabled ? "đã ghi nhận" : "hoạt động", icon: Soup, tone: "from-emerald-50 to-teal-50/50", iconTone: "bg-emerald-100 text-emerald-700" },
    ...(healthEnabled ? [{ title: "Năng lượng", value: today.totalCalories, detail: "kcal đã nạp", icon: Flame, tone: "from-amber-50 to-orange-50/50", iconTone: "bg-orange-100 text-orange-700" }] : []),
    ...(healthEnabled ? [{ title: "Chất đạm", value: `${today.totalProtein}g`, detail: "đã nạp", icon: Beef, tone: "from-rose-50 to-pink-50/50", iconTone: "bg-rose-100 text-rose-700" }] : []),
    ...(fitnessEnabled ? [{ title: "Luyện tập", value: today.workoutCount, detail: "buổi tập", icon: Dumbbell, tone: "from-blue-50 to-indigo-50/50", iconTone: "bg-blue-100 text-blue-700" }] : []),
  ];
  return <div className="space-y-6 md:space-y-8">
    <div className="flex flex-col gap-4 rounded-3xl bg-[#0c2821] px-5 py-6 text-white shadow-xl shadow-emerald-950/10 sm:px-7 sm:py-8 lg:flex-row lg:items-end lg:justify-between"><div><p className="text-sm font-medium text-emerald-200/70">Không gian cá nhân của bạn</p><h2 className="mt-2 max-w-2xl text-3xl font-semibold tracking-[-0.04em] sm:text-4xl">Một ngày tốt bắt đầu từ một bước nhỏ.</h2><p className="mt-3 max-w-xl text-sm leading-6 text-emerald-50/65">Theo dõi điều quan trọng, hoàn thành đúng nhịp và để FitTrack nhắc bạn khi cần.</p></div><div className="flex flex-wrap gap-2">{lunchEnabled&&<Button asChild className="bg-emerald-300 text-[#0c2821] hover:bg-emerald-200"><Link to="/lunch"><Soup className="size-4"/>Đặt cơm hôm nay</Link></Button>}{todoEnabled&&<Button asChild variant="outline" className="border-white/20 bg-white/10 text-white hover:bg-white/20"><Link to="/todos"><ListTodo className="size-4"/>Xem việc cần làm</Link></Button>}{authUser?.role === "ADMIN" && <Button variant="outline" onClick={() => seedMutation.mutate()} disabled={seedMutation.isPending} className="border-white/20 bg-white/10 text-white hover:bg-white/20">{seedMutation.isPending ? "Đang tạo..." : "Tạo dữ liệu mẫu"}</Button>}</div></div>
    <PageHeader title="Tổng quan hôm nay" description={healthEnabled || fitnessEnabled ? "Nắm nhanh tiến độ dinh dưỡng, luyện tập và các việc cần ưu tiên." : "Các thông tin liên quan đến quyền Đặt cơm và hồ sơ cá nhân của bạn."} />
    <div className={`grid gap-4 sm:grid-cols-2 ${cards.length >= 4 ? "xl:grid-cols-4" : "xl:grid-cols-3"}`}>{cards.map((card) => { const Icon = card.icon; return <Card key={card.title} className={`border-0 bg-gradient-to-br ${card.tone}`}><CardHeader className="flex flex-row items-center justify-between pb-0"><CardTitle className="text-sm text-muted-foreground">{card.title}</CardTitle><span className={`grid size-9 place-items-center rounded-xl ${card.iconTone}`}><Icon className="size-4"/></span></CardHeader><CardContent><p className="text-3xl font-semibold tracking-[-0.04em]">{card.value}</p><p className="mt-1 text-xs text-muted-foreground">{card.detail}</p></CardContent></Card>; })}</div>
    {todoEnabled || scheduleEnabled ? <div className="grid gap-4 md:grid-cols-2">{todoEnabled&&<QuickLinkCard icon={ListTodo} title="Việc cần làm" description="Giữ các việc quan trọng trong tầm mắt và đánh dấu khi hoàn tất." to="/todos" action="Mở danh sách việc"/>}{scheduleEnabled&&<QuickLinkCard icon={CheckCircle2} title="Thời khóa biểu" description="Xếp mốc thời gian và nhận thông báo trước khi hoạt động bắt đầu." to="/schedule" action="Mở thời khóa biểu"/>}</div>:null}
    {healthEnabled&&<div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4"><MacroProgressCard title="Mục tiêu năng lượng" current={today.totalCalories} target={today.targetCalories} unit="kcal" percent={today.caloriesProgressPercent}/><MacroProgressCard title="Mục tiêu chất đạm" current={today.totalProtein} target={today.targetProtein} unit="g" percent={today.proteinProgressPercent}/><MacroProgressCard title="Mục tiêu tinh bột" current={today.totalCarbs} target={today.targetCarbs} unit="g" percent={today.carbsProgressPercent}/><MacroProgressCard title="Mục tiêu chất béo" current={today.totalFat} target={today.targetFat} unit="g" percent={today.fatProgressPercent}/></div>}
    {healthEnabled&&topRecommendations.length>0&&<section className="space-y-4"><div className="flex items-center justify-between"><h2 className="text-xl font-semibold">Gợi ý dành cho bạn</h2><Link className="text-sm font-semibold text-emerald-700 hover:text-emerald-800" to="/health">Xem sức khỏe <ArrowRight className="ml-1 inline size-4"/></Link></div><div className="grid gap-4 md:grid-cols-2">{topRecommendations.map((item,index)=><RecommendationCard key={index} item={item}/>)}</div></section>}
    {fitnessEnabled&&achievementQuery.data&&<Card><CardHeader><CardTitle className="flex items-center gap-2"><Trophy className="size-5 text-amber-600"/>Tiến độ tuần này</CardTitle></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2 md:grid-cols-4"><AchievementMetric label="Chuỗi ngày ghi bữa" value={`${achievementQuery.data.mealLoggingStreak} ngày`} className="bg-emerald-50"/><AchievementMetric label="Chuỗi ngày tập" value={`${achievementQuery.data.workoutStreak} ngày`} className="bg-blue-50"/><AchievementMetric label="Ngày đạt protein" value={achievementQuery.data.proteinHitDaysThisWeek} className="bg-amber-50"/><AchievementMetric label="Ngày ghi số đo" value={achievementQuery.data.bodyTrackingDaysThisWeek} className="bg-violet-50"/></CardContent></Card>}
    {(fitnessEnabled||healthEnabled)&&<DeferredFitnessTrendCharts points={points}/>} {healthEnabled&&<Card className="border-emerald-200 bg-gradient-to-r from-emerald-50 to-white"><CardHeader><CardTitle>Báo cáo tuần</CardTitle></CardHeader><CardContent className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"><p className="text-sm text-muted-foreground">Tập trung vào xu hướng và hành động cụ thể thay vì chỉ nhìn con số.</p><Button asChild><Link to="/reports/weekly">Xem báo cáo</Link></Button></CardContent></Card>}
    {fitnessEnabled&&<Card><CardHeader><CardTitle>Buổi tập gần nhất hôm nay</CardTitle></CardHeader><CardContent className="text-sm text-muted-foreground">{today.latestWorkoutNote ?? "Hôm nay chưa ghi nhận buổi tập."}</CardContent></Card>}
    {!healthEnabled&&!fitnessEnabled&&<Card className="border-dashed bg-muted/30"><CardContent className="flex flex-col items-center gap-3 py-10 text-center"><ChefHat className="size-8 text-emerald-700"/><p className="font-semibold">Tài khoản của bạn đang ở chế độ Đặt cơm</p><p className="max-w-md text-sm leading-6 text-muted-foreground">Bạn chỉ thấy menu, đơn đặt cơm, tổng quan rút gọn và hồ sơ cá nhân. Admin có thể cấp thêm module khi cần.</p><Button asChild variant="outline"><Link to="/profile">Mở hồ sơ cá nhân</Link></Button></CardContent></Card>}
  </div>;
}
function QuickLinkCard({icon:Icon,title,description,to,action}:{icon:typeof ListTodo;title:string;description:string;to:string;action:string}){return <Card className="group transition hover:-translate-y-0.5 hover:shadow-md"><CardContent className="flex items-start gap-4 p-5"><span className="grid size-11 shrink-0 place-items-center rounded-2xl bg-emerald-100 text-emerald-800"><Icon className="size-5"/></span><div className="min-w-0 flex-1"><p className="font-semibold">{title}</p><p className="mt-1 text-sm leading-6 text-muted-foreground">{description}</p><Link to={to} className="mt-3 inline-flex items-center text-sm font-semibold text-emerald-700">{action}<ArrowRight className="ml-1 size-4 transition group-hover:translate-x-0.5"/></Link></div></CardContent></Card>}
function AchievementMetric({label,value,className}:{label:string;value:string|number;className:string}){return <div className={`rounded-xl p-4 ${className}`}><p className="text-sm text-muted-foreground">{label}</p><p className="mt-1 text-xl font-bold md:text-2xl">{value}</p></div>}
