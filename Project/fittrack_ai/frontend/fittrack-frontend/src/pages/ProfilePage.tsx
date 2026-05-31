import { useEffect, useState } from "react";
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

export default function ProfilePage() {
  const queryClient = useQueryClient();
  const [draft, setDraft] = useState<UserProfile | null>(null);

  const profileQuery = useQuery({
    queryKey: ["profile"],
    queryFn: getProfile,
  });

  useEffect(() => {
    if (profileQuery.data) {
      setDraft(profileQuery.data);
    }
  }, [profileQuery.data]);

  const profile = draft ?? profileQuery.data ?? null;

  const updateMutation = useMutation({
    mutationFn: updateProfile,
    onSuccess: (updated) => {
      setDraft(updated);
      toast.success("Profile updated");
      queryClient.invalidateQueries({ queryKey: ["profile"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard-today"] });
      queryClient.invalidateQueries({ queryKey: ["weekly-recommendations"] });
      queryClient.invalidateQueries({ queryKey: ["achievements"] });
    },
    onError: (error) => {
      const message = axios.isAxiosError(error) ? error.response?.data?.message : undefined;
      toast.error(message || "Cannot update profile");
    },
  });

  if (profileQuery.isError) {
    return <ErrorState title="Cannot load profile" message="Please login again or refresh the page." />;
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
    { title: "Calories Target", value: profile.targetCalories, icon: Target },
    { title: "Protein Target", value: `${profile.targetProtein}g`, icon: Beef },
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Profile" description="Update your personal data and nutrition targets." />

      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
        {metrics.map((item) => {
          const Icon = item.icon;

          return (
            <Card key={item.title}>
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle className="text-sm text-muted-foreground">{item.title}</CardTitle>
                <Icon className="h-5 w-5 text-muted-foreground" />
              </CardHeader>

              <CardContent>
                <p className="text-2xl font-bold">{item.value}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>User Information</CardTitle>
        </CardHeader>

        <CardContent className="grid gap-4 md:grid-cols-2">
          <Input
            value={profile.fullName ?? ""}
            onChange={(event) => setDraft({ ...profile, fullName: event.target.value })}
            placeholder="Full name"
          />

          <Input value={profile.email ?? ""} disabled />

          <Input
            type="number"
            value={profile.age ?? 23}
            onChange={(event) => setDraft({ ...profile, age: Number(event.target.value) })}
            placeholder="Age"
          />

          <Input
            type="number"
            value={profile.height ?? 160}
            onChange={(event) => setDraft({ ...profile, height: Number(event.target.value) })}
            placeholder="Height"
          />

          <Input
            type="number"
            value={profile.weight ?? 60}
            onChange={(event) => setDraft({ ...profile, weight: Number(event.target.value) })}
            placeholder="Weight"
          />

          <select
            className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
            value={profile.gender ?? "MALE"}
            onChange={(event) => setDraft({ ...profile, gender: event.target.value })}
          >
            <option value="MALE">Male</option>
            <option value="FEMALE">Female</option>
          </select>

          <select
            className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
            value={profile.goal ?? "LEAN_BULK"}
            onChange={(event) => setDraft({ ...profile, goal: event.target.value })}
          >
            <option value="CUT">Cut</option>
            <option value="MAINTAIN">Maintain</option>
            <option value="LEAN_BULK">Lean Bulk</option>
          </select>

          <select
            className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
            value={profile.activityLevel ?? "MODERATE"}
            onChange={(event) => setDraft({ ...profile, activityLevel: event.target.value })}
          >
            <option value="SEDENTARY">Sedentary</option>
            <option value="LIGHT">Light</option>
            <option value="MODERATE">Moderate</option>
            <option value="ACTIVE">Active</option>
          </select>

          <Button onClick={handleSave} className="md:col-span-2" disabled={updateMutation.isPending}>
            {updateMutation.isPending ? "Saving..." : "Save Profile"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
