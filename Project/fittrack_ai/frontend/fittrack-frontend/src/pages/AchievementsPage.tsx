import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, Dumbbell, Scale, Target, Trophy, Utensils } from "lucide-react";
import { getAchievementSummary } from "../api/achievement.api";
import PageHeader from "../components/PageHeader";
import AchievementCard from "../components/AchievementCard";
import EmptyState from "../components/common/EmptyState";
import ErrorState from "../components/common/ErrorState";
import PageLoading from "../components/common/PageLoading";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";

export default function AchievementsPage() {
  const query = useQuery({ queryKey: ["achievements"], queryFn: getAchievementSummary });
  if (query.isLoading) return <PageLoading />;
  if (query.isError || !query.data) return <ErrorState title="Không thể tải thành tích" message="Vui lòng tải lại trang." />;
  const summary = query.data;
  const stats = [
    { title: "Chuỗi ghi bữa", value: summary.mealLoggingStreak, goal: 7, suffix: "ngày", icon: Utensils, tone: "bg-emerald-50 text-emerald-800" },
    { title: "Chuỗi ngày tập", value: summary.workoutStreak, goal: 3, suffix: "ngày", icon: Dumbbell, tone: "bg-blue-50 text-blue-800" },
    { title: "Đạt protein", value: summary.proteinHitDaysThisWeek, goal: 5, suffix: "/ 5 ngày", icon: Target, tone: "bg-amber-50 text-amber-800" },
    { title: "Ghi chỉ số", value: summary.bodyTrackingDaysThisWeek, goal: 2, suffix: "/ 2 lần", icon: Scale, tone: "bg-violet-50 text-violet-800" },
  ];
  const next = stats.reduce((best, item) => item.value / item.goal < best.value / best.goal ? item : best, stats[0]);
  return <div className="space-y-6 md:space-y-8"><PageHeader title="Tiến độ & cột mốc" description="Mỗi cột mốc được gắn với một thói quen cụ thể để bạn biết bước tiếp theo là gì."/><Card className="overflow-hidden border-0 bg-[#0c2821] text-white"><CardContent className="grid gap-5 p-5 sm:p-7 md:grid-cols-[1fr_auto] md:items-center"><div><div className="flex items-center gap-2 text-emerald-200/70"><Trophy className="size-4"/> Bảng điều khiển tiến độ</div><h2 className="mt-2 text-2xl font-semibold tracking-tight">Bạn đang xây một nhịp sống bền vững.</h2><p className="mt-2 max-w-2xl text-sm leading-6 text-emerald-50/65">Thành tích không chỉ là điểm số. Hãy chọn một thói quen nhỏ, lặp lại đủ lâu và để dữ liệu phản hồi cho bạn.</p></div><div className="rounded-2xl bg-white/10 p-4 md:min-w-48"><p className="text-xs text-emerald-100/60">Ưu tiên tiếp theo</p><p className="mt-1 font-semibold">{next.title}</p><Badge className="mt-2 bg-emerald-300 text-[#0c2821]">Còn {Math.max(next.goal-next.value,0)} {next.suffix.replace('/ 5 ngày','ngày').replace('/ 2 lần','lần')}</Badge></div></CardContent></Card><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">{stats.map(stat=>{const Icon=stat.icon;const percent=Math.min(100,Math.round(stat.value/stat.goal*100));return <Card key={stat.title}><CardHeader className="flex flex-row items-center justify-between pb-2"><CardTitle className="text-sm text-muted-foreground">{stat.title}</CardTitle><span className={`grid size-9 place-items-center rounded-xl ${stat.tone}`}><Icon className="size-4"/></span></CardHeader><CardContent><p className="text-3xl font-semibold">{stat.value}<span className="ml-1 text-sm font-normal text-muted-foreground">{stat.suffix}</span></p><Progress value={percent} className="mt-3 h-2"/><p className="mt-2 text-xs text-muted-foreground">{percent >= 100 ? "Đã đạt mục tiêu" : `Tiến độ ${percent}% · mục tiêu ${stat.goal}`}</p></CardContent></Card>})}</div><div className="flex items-start gap-3 rounded-2xl border border-emerald-200 bg-emerald-50/60 p-4 text-sm text-emerald-950"><CheckCircle2 className="mt-0.5 size-5 shrink-0 text-emerald-700"/><p><strong>Gợi ý thực tế:</strong> {next.title === "Chuỗi ngày tập" ? "đặt một buổi tập ngắn 20–30 phút trong lịch hôm nay." : next.title === "Đạt protein" ? "chọn một nguồn đạm rõ ràng cho bữa tiếp theo." : next.title === "Ghi chỉ số" ? "chọn một khung giờ cố định để ghi số đo, không cần đợi đến cuối tuần." : "ghi lại bữa ăn ngay sau khi dùng để giữ mạch liên tục."}</p></div>{summary.achievements.length===0?<EmptyState title="Chưa có thành tích" description="Tiếp tục ghi dữ liệu để mở khóa các cột mốc đầu tiên."/>:<div className="grid gap-4 md:grid-cols-2">{summary.achievements.map(achievement=><AchievementCard key={achievement.code} achievement={achievement}/>)}</div>}</div>;
}
