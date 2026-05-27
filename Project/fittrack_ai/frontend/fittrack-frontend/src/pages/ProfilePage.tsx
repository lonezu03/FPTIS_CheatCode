import { useEffect, useState } from "react";
import { getProfile, updateProfile, type UserProfile } from "../api/user.api";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Calculator, Flame, Target, Beef } from "lucide-react";

export default function ProfilePage() {
  const [profile, setProfile] = useState<UserProfile | null>(null);

  const load = async () => {
    setProfile(await getProfile());
  };

  useEffect(() => {
    load();
  }, []);

  const handleSave = async () => {
    if (!profile) {
      return;
    }

    try {
      const updated = await updateProfile(profile);
      setProfile(updated);
      toast.success("Profile updated");
    } catch (error) {
      const message =
        typeof error === "object" && error && "response" in error
          ? (error as { response?: { data?: { message?: string } } }).response?.data?.message
          : undefined;
      toast.error(message || "Cannot update profile");
    }
  };

  if (!profile) {
    return <div>Loading profile...</div>;
  }

  const metrics = [
    { title: "BMR", value: profile.bmr, icon: Calculator },
    { title: "TDEE", value: profile.tdee, icon: Flame },
    { title: "Calories Target", value: profile.targetCalories, icon: Target },
    { title: "Protein Target", value: `${profile.targetProtein}g`, icon: Beef },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Profile</h1>
        <p className="text-muted-foreground">Update your personal data and nutrition targets.</p>
      </div>

      <div className="grid gap-6 md:grid-cols-4">
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
            onChange={(event) => setProfile({ ...profile, fullName: event.target.value })}
            placeholder="Full name"
          />

          <Input value={profile.email ?? ""} disabled />

          <Input
            type="number"
            value={profile.age ?? 23}
            onChange={(event) => setProfile({ ...profile, age: Number(event.target.value) })}
            placeholder="Age"
          />

          <Input
            type="number"
            value={profile.height ?? 160}
            onChange={(event) => setProfile({ ...profile, height: Number(event.target.value) })}
            placeholder="Height"
          />

          <Input
            type="number"
            value={profile.weight ?? 60}
            onChange={(event) => setProfile({ ...profile, weight: Number(event.target.value) })}
            placeholder="Weight"
          />

          <select className="rounded-md border px-3 py-2" value={profile.gender ?? "MALE"} onChange={(event) => setProfile({ ...profile, gender: event.target.value })}>
            <option value="MALE">Male</option>
            <option value="FEMALE">Female</option>
          </select>

          <select className="rounded-md border px-3 py-2" value={profile.goal ?? "LEAN_BULK"} onChange={(event) => setProfile({ ...profile, goal: event.target.value })}>
            <option value="CUT">Cut</option>
            <option value="MAINTAIN">Maintain</option>
            <option value="LEAN_BULK">Lean Bulk</option>
          </select>

          <select
            className="rounded-md border px-3 py-2"
            value={profile.activityLevel ?? "MODERATE"}
            onChange={(event) => setProfile({ ...profile, activityLevel: event.target.value })}
          >
            <option value="SEDENTARY">Sedentary</option>
            <option value="LIGHT">Light</option>
            <option value="MODERATE">Moderate</option>
            <option value="ACTIVE">Active</option>
          </select>

          <Button onClick={handleSave} className="md:col-span-2">
            Save Profile
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
