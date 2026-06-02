import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Lock, Trophy } from "lucide-react";
import type { Achievement } from "../api/achievement.api";

export default function AchievementCard({ achievement }: { achievement: Achievement }) {
  const percent = achievement.target === 0 ? 0 : Math.min((achievement.progress / achievement.target) * 100, 100);

  return (
    <Card className={achievement.unlocked ? "border-yellow-300" : ""}>
      <CardHeader className="flex flex-row items-start justify-between gap-4">
        <div>
          <CardTitle className="flex items-center gap-2 text-base">
            {achievement.unlocked ? (
              <Trophy className="h-5 w-5 text-yellow-500" />
            ) : (
              <Lock className="h-5 w-5 text-muted-foreground" />
            )}
            {achievement.title}
          </CardTitle>

          <p className="mt-1 text-sm text-muted-foreground">{achievement.description}</p>
        </div>

        <Badge variant={achievement.unlocked ? "default" : "secondary"}>{achievement.unlocked ? "Unlocked" : "Locked"}</Badge>
      </CardHeader>

      <CardContent className="space-y-2">
        <div className="flex justify-between text-sm">
          <span>
            {achievement.progress}/{achievement.target}
          </span>
          <span>{percent.toFixed(0)}%</span>
        </div>

        <Progress value={percent} />
      </CardContent>
    </Card>
  );
}
