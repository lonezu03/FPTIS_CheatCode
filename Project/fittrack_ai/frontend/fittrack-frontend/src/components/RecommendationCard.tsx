import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertTriangle, CheckCircle2, Info, Lightbulb } from "lucide-react";
import type { RecommendationItem } from "../api/recommendation.api";

function getSeverityStyle(severity: string) {
  switch (severity) {
    case "HIGH":
      return {
        badge: "destructive" as const,
        icon: AlertTriangle,
      };
    case "MEDIUM":
      return {
        badge: "secondary" as const,
        icon: Info,
      };
    default:
      return {
        badge: "outline" as const,
        icon: CheckCircle2,
      };
  }
}

export default function RecommendationCard({ item }: { item: RecommendationItem }) {
  const style = getSeverityStyle(item.severity);
  const Icon = style.icon;

  return (
    <Card>
      <CardHeader className="flex flex-row items-start justify-between gap-4">
        <div className="space-y-1">
          <CardTitle className="flex items-center gap-2 text-base">
            <Icon className="h-5 w-5" />
            {item.title}
          </CardTitle>

          <p className="text-sm text-muted-foreground">{item.message}</p>
        </div>

        <Badge variant={style.badge}>{item.severity}</Badge>
      </CardHeader>

      <CardContent>
        <div className="rounded-xl bg-slate-50 p-4 text-sm">
          <div className="mb-1 flex items-center gap-2 font-medium">
            <Lightbulb className="h-4 w-4" />
            Suggested action
          </div>

          <p className="text-muted-foreground">{item.action}</p>
        </div>
      </CardContent>
    </Card>
  );
}
