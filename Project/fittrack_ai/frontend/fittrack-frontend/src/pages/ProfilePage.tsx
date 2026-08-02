import { useState } from "react";
import axios from "axios";
import { getProfile, updateProfile, type UserProfile } from "../api/user.api";
import { toast } from "sonner";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Calculator, Flame, Target, Beef } from "lucide-react";
import PageHeader from "../components/PageHeader";
import PageLoading from "../components/common/PageLoading";
import ErrorState from "../components/common/ErrorState";
import FormField from "../components/common/FormField";

export default function ProfilePage() {
  const queryClient = useQueryClient();
  const [draft, setDraft] = useState<UserProfile | null>(null);

  const profileQuery = useQuery({
    queryKey: ["profile"],
    queryFn: getProfile,
  });

  const profile = draft ?? profileQuery.data ?? null;

  const updateMutation = useMutation({
    mutationFn: updateProfile,
    onSuccess: (updated) => {
      setDraft(updated);
      toast.success("Đã cập nhật hồ sơ");
      queryClient.invalidateQueries({ queryKey: ["profile"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Không thể cập nhật hồ sơ");
    },
  });

  if (profileQuery.isError) {
    return <ErrorState title="Không thể tải hồ sơ" message="Vui lòng đăng nhập lại hoặc tải lại trang." />;
  }

  if (profileQuery.isLoading || !profile) {
    return <PageLoading />;
  }

  const handleSave = () => {
    updateMutation.mutate(profile);
  };

  const metrics = [
    { title: "BMR", value: profile.bmr, icon: Calculator },
    { title: "TDEE", value: profile.tdee, icon: Flame },
    { title: "Mục tiêu năng lượng", value: profile.targetCalories, icon: Target },
    { title: "Mục tiêu chất đạm", value: `${profile.targetProtein}g`, icon: Beef },
  ];

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader title="Hồ sơ cá nhân" description="Cập nhật thông tin cá nhân và mục tiêu dinh dưỡng." />

      <div className="grid gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4">
        {metrics.map((item) => {
          const Icon = item.icon;

          return (
            <Card key={item.title}>
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle className="text-sm text-muted-foreground">{item.title}</CardTitle>
                <Icon className="h-5 w-5 text-muted-foreground" />
              </CardHeader>

              <CardContent>
                <p className="text-xl font-bold md:text-2xl">{item.value}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Thông tin người dùng</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-3 sm:gap-4 md:grid-cols-2">
          <FormField label="Họ và tên" htmlFor="profile-name" required>
            <Input id="profile-name" value={profile.fullName ?? ""} onChange={(event) => setDraft({ ...profile, fullName: event.target.value })} />
          </FormField>
          <FormField label="Email đăng nhập" htmlFor="profile-email" hint="Email chỉ có thể thay đổi qua quy trình xác thực.">
            <Input id="profile-email" value={profile.email ?? ""} disabled />
          </FormField>
          <FormField label="Tuổi" htmlFor="profile-age" unit="năm" hint="Dùng để ước tính nhu cầu năng lượng cơ bản." required>
            <Input id="profile-age" type="number" min={13} max={120} value={profile.age ?? 23} onChange={(event) => setDraft({ ...profile, age: Number(event.target.value) })} />
          </FormField>
          <FormField label="Chiều cao" htmlFor="profile-height" unit="cm" hint="Đo khi đứng thẳng, không mang giày." required>
            <Input id="profile-height" type="number" min={100} max={250} step={0.1} value={profile.height ?? 160} onChange={(event) => setDraft({ ...profile, height: Number(event.target.value) })} />
          </FormField>
          <FormField label="Cân nặng hiện tại" htmlFor="profile-weight" unit="kg" hint="Dùng để tính BMR và mục tiêu dinh dưỡng." required>
            <Input id="profile-weight" type="number" min={20} max={350} step={0.1} value={profile.weight ?? 60} onChange={(event) => setDraft({ ...profile, weight: Number(event.target.value) })} />
          </FormField>
          <FormField label="Giới tính sinh học" htmlFor="profile-gender" hint="Được dùng trong công thức ước tính BMR.">
            <select id="profile-gender" className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" value={profile.gender ?? "MALE"} onChange={(event) => setDraft({ ...profile, gender: event.target.value })}>
              <option value="MALE">Nam</option>
              <option value="FEMALE">Nữ</option>
            </select>
          </FormField>
          <FormField label="Mục tiêu" htmlFor="profile-goal" hint="FitTrack sẽ điều chỉnh mục tiêu năng lượng theo lựa chọn này.">
            <select id="profile-goal" className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" value={profile.goal ?? "LEAN_BULK"} onChange={(event) => setDraft({ ...profile, goal: event.target.value })}>
              <option value="CUT">Giảm mỡ</option>
              <option value="MAINTAIN">Duy trì cân nặng</option>
              <option value="LEAN_BULK">Tăng cơ</option>
            </select>
          </FormField>
          <FormField label="Mức độ vận động" htmlFor="profile-activity" hint="Chọn mức gần nhất với sinh hoạt trung bình hằng tuần.">
            <select id="profile-activity" className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" value={profile.activityLevel ?? "MODERATE"} onChange={(event) => setDraft({ ...profile, activityLevel: event.target.value })}>
              <option value="SEDENTARY">Ít vận động</option>
              <option value="LIGHT">Nhẹ · 1–3 buổi/tuần</option>
              <option value="MODERATE">Vừa · 3–5 buổi/tuần</option>
              <option value="ACTIVE">Cao · 6–7 buổi/tuần</option>
            </select>
          </FormField>

          <label className="flex items-start gap-3 rounded-xl border p-4 md:col-span-2">
            <input
              type="checkbox"
              className="mt-1 size-4 accent-emerald-700"
              checked={profile.emailNotificationsEnabled ?? false}
              onChange={(event) =>
                setDraft({ ...profile, emailNotificationsEnabled: event.target.checked })
              }
            />
            <span>
              <span className="block font-medium">Nhận thông báo qua email</span>
              <span className="mt-1 block text-sm text-muted-foreground">
                Gửi nhắc nhở sức khỏe, thông báo quản trị và cập nhật thanh toán ngay cả khi bạn đã đóng trình duyệt.
              </span>
            </span>
          </label>

          <Button onClick={handleSave} className="md:col-span-2" disabled={updateMutation.isPending}>
            {updateMutation.isPending ? "Đang lưu..." : "Lưu hồ sơ"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
