import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Activity, BellPlus, Droplets, HeartPulse, Trash2 } from "lucide-react";
import { toast } from "sonner";
import {
  createHealthReminder,
  deleteHealthReminder,
  getHealthReminders,
  getHealthSummary,
} from "@/api/health.api";
import PageHeader from "@/components/PageHeader";
import EmptyState from "@/components/common/EmptyState";
import ErrorState from "@/components/common/ErrorState";
import PageLoading from "@/components/common/PageLoading";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Progress } from "@/components/ui/progress";
import { getApiErrorMessage } from "@/lib/format";
import FormField from "@/components/common/FormField";

const dayOptions = [
  ["MONDAY", "T2"],
  ["TUESDAY", "T3"],
  ["WEDNESDAY", "T4"],
  ["THURSDAY", "T5"],
  ["FRIDAY", "T6"],
  ["SATURDAY", "T7"],
  ["SUNDAY", "CN"],
] as const;

export default function HealthPage() {
  const queryClient = useQueryClient();
  const [period, setPeriod] = useState(30);
  const [type, setType] = useState("WATER");
  const [title, setTitle] = useState("Uống nước");
  const [message, setMessage] = useState("Đã đến giờ bổ sung nước.");
  const [time, setTime] = useState("10:00");
  const [days, setDays] = useState<string[]>(dayOptions.slice(0, 5).map(([value]) => value));

  const summaryQuery = useQuery({
    queryKey: ["health-summary", period],
    queryFn: () => getHealthSummary(period),
  });
  const remindersQuery = useQuery({
    queryKey: ["health-reminders"],
    queryFn: getHealthReminders,
  });
  const createMutation = useMutation({
    mutationFn: createHealthReminder,
    onSuccess: () => {
      toast.success("Đã tạo nhắc nhở");
      void queryClient.invalidateQueries({ queryKey: ["health-reminders"] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể tạo nhắc nhở")),
  });
  const deleteMutation = useMutation({
    mutationFn: deleteHealthReminder,
    onSuccess: () => {
      toast.success("Đã xóa nhắc nhở");
      void queryClient.invalidateQueries({ queryKey: ["health-reminders"] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không thể xóa nhắc nhở")),
  });

  if (summaryQuery.isLoading) return <PageLoading />;
  if (summaryQuery.isError || !summaryQuery.data) {
    return <ErrorState title="Không thể tải báo cáo sức khỏe" message="Vui lòng tải lại trang." />;
  }
  const summary = summaryQuery.data;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <PageHeader title="Sức khỏe toàn diện" description="Tổng hợp dinh dưỡng, vận động, cơ thể và nhắc nhở cá nhân." />
        <select
          value={period}
          onChange={(event) => setPeriod(Number(event.target.value))}
          className="h-10 rounded-xl border bg-white px-3 text-sm"
        >
          <option value={7}>7 ngày</option>
          <option value={30}>30 ngày</option>
          <option value={90}>90 ngày</option>
        </select>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Metric title="Điểm sức khỏe" value={`${summary.overallScore}/100`} icon={HeartPulse} />
        <Metric title="BMI" value={summary.bmi ? `${summary.bmi} · ${summary.bmiCategory}` : "Chưa đủ dữ liệu"} icon={Activity} />
        <Metric title="Vận động" value={`${summary.workoutSessions} buổi · ${summary.workoutMinutes} phút`} icon={Activity} />
        <Metric title="Ngày ghi dinh dưỡng" value={`${summary.trackedNutritionDays}/${summary.periodDays}`} icon={Droplets} />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Dinh dưỡng trung bình mỗi ngày</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {summary.nutrients.map((nutrient) => (
            <div key={nutrient.key} className="rounded-2xl border bg-slate-50/60 p-4">
              <div className="mb-2 flex items-center justify-between gap-2">
                <p className="font-medium">{nutrient.label}</p>
                <Badge variant={nutrient.status === "GOOD" ? "default" : "outline"}>
                  {nutrient.status === "GOOD" ? "Cân bằng" : nutrient.status === "LOW" ? "Còn thấp" : "Cao"}
                </Badge>
              </div>
              <p className="mb-3 text-sm text-muted-foreground">
                <strong className="text-foreground">{nutrient.average}</strong> / {nutrient.target} {nutrient.unit}
              </p>
              <Progress value={Math.min(100, nutrient.progressPercent)} />
            </div>
          ))}
        </CardContent>
      </Card>

      <div className="grid gap-4 xl:grid-cols-[0.9fr_1.1fr]">
        <Card>
          <CardHeader><CardTitle>Gợi ý từ dữ liệu</CardTitle></CardHeader>
          <CardContent>
            <ul className="space-y-3 text-sm">
              {summary.insights.map((insight) => (
                <li key={insight} className="rounded-xl bg-emerald-50 p-3 text-emerald-900">{insight}</li>
              ))}
            </ul>
            <p className="mt-4 text-xs text-muted-foreground">{summary.disclaimer}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="flex items-center gap-2"><BellPlus className="size-5" />Tạo nhắc nhở</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <FormField label="Loại nhắc nhở" htmlFor="reminder-type" hint="Giúp phân loại thông báo." required>
                <select id="reminder-type" value={type} onChange={(event) => setType(event.target.value)} className="h-10 w-full rounded-xl border bg-white px-3 text-sm">
                  <option value="WATER">Uống nước</option>
                  <option value="MEAL">Bữa ăn</option>
                  <option value="WORKOUT">Luyện tập</option>
                  <option value="MEDICATION">Thuốc</option>
                  <option value="SLEEP">Giấc ngủ</option>
                  <option value="CUSTOM">Khác</option>
                </select>
              </FormField>
              <FormField label="Giờ thông báo" htmlFor="reminder-time" hint="Theo múi giờ Việt Nam." required>
                <Input id="reminder-time" type="time" value={time} onChange={(event) => setTime(event.target.value)} />
              </FormField>
            </div>
            <FormField label="Tiêu đề thông báo" htmlFor="reminder-title" required><Input id="reminder-title" value={title} onChange={(event) => setTitle(event.target.value)} /></FormField>
            <FormField label="Nội dung" htmlFor="reminder-message" hint="Mô tả ngắn hành động cần thực hiện."><Input id="reminder-message" value={message} onChange={(event) => setMessage(event.target.value)} /></FormField>
            <div>
              <Label className="font-semibold text-slate-800">Lặp lại vào</Label>
              <p className="mb-2 mt-1 text-xs text-muted-foreground">Chọn những ngày bạn muốn nhận thông báo.</p>
            <div className="flex flex-wrap gap-2">
              {dayOptions.map(([value, label]) => (
                <Button
                  key={value}
                  type="button"
                  size="sm"
                  variant={days.includes(value) ? "default" : "outline"}
                  onClick={() => setDays((current) => current.includes(value) ? current.filter((day) => day !== value) : [...current, value])}
                >
                  {label}
                </Button>
              ))}
            </div>
            </div>
            <Button
              className="w-full"
              disabled={createMutation.isPending || !title.trim() || days.length === 0}
              onClick={() => createMutation.mutate({ type, title: title.trim(), message: message.trim(), reminderTime: time, daysOfWeek: days, enabled: true })}
            >
              {createMutation.isPending ? "Đang tạo..." : "Tạo nhắc nhở"}
            </Button>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader><CardTitle>Nhắc nhở của tôi</CardTitle></CardHeader>
        <CardContent>
          {(remindersQuery.data ?? []).length === 0 ? (
            <EmptyState title="Chưa có nhắc nhở" description="Tạo nhắc nhở phù hợp với lịch sinh hoạt của bạn." />
          ) : (
            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
              {remindersQuery.data?.map((reminder) => (
                <div key={reminder.id} className="flex items-start justify-between gap-3 rounded-2xl border p-4">
                  <div>
                    <p className="font-semibold">{reminder.title}</p>
                    <p className="mt-1 text-sm text-muted-foreground">{reminder.reminderTime.slice(0, 5)} · {reminder.daysOfWeek.length} ngày/tuần</p>
                  </div>
                  <Button size="icon" variant="ghost" aria-label="Xóa nhắc nhở" onClick={() => deleteMutation.mutate(reminder.id)}>
                    <Trash2 className="size-4 text-red-600" />
                  </Button>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function Metric({ title, value, icon: Icon }: { title: string; value: string; icon: typeof Activity }) {
  return (
    <Card>
      <CardContent className="flex items-center gap-4 p-5">
        <span className="grid size-11 place-items-center rounded-2xl bg-emerald-100 text-emerald-800"><Icon /></span>
        <div><p className="text-xs text-muted-foreground">{title}</p><p className="mt-1 font-semibold">{value}</p></div>
      </CardContent>
    </Card>
  );
}
