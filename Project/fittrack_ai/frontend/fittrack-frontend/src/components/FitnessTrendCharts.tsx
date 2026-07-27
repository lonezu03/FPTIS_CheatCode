import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Activity, Dumbbell, Scale } from "lucide-react";
import type { ProgressPoint } from "../api/dashboard.api";
import EmptyState from "./common/EmptyState";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

const compactNumber = new Intl.NumberFormat("vi-VN", {
  maximumFractionDigits: 1,
});

function parseLocalDate(value: string) {
  return new Date(`${value}T00:00:00`);
}

function formatShortDate(value: string) {
  return new Intl.DateTimeFormat("vi-VN", {
    day: "2-digit",
    month: "2-digit",
  }).format(parseLocalDate(value));
}

function formatLongDate(value: string) {
  return new Intl.DateTimeFormat("vi-VN", {
    weekday: "short",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(parseLocalDate(value));
}

const tooltipStyle = {
  border: "1px solid #e2e8f0",
  borderRadius: "12px",
  boxShadow: "0 10px 30px rgba(15, 23, 42, 0.08)",
  fontSize: "12px",
};

export default function FitnessTrendCharts({ points }: { points: ProgressPoint[] }) {
  const bodyPoints = points
    .filter((point) => point.weight != null || point.waist != null)
    .slice(-12);
  const activityPoints = points
    .filter((point) => point.calories > 0 || point.protein > 0 || point.workoutCount > 0)
    .slice(-14);

  const mealDays = activityPoints.filter((point) => point.calories > 0 || point.protein > 0).length;
  const workoutDays = activityPoints.filter((point) => point.workoutCount > 0).length;

  return (
    <div className="grid gap-4 md:gap-6 lg:grid-cols-2">
      <Card className="overflow-hidden">
        <CardHeader className="gap-2">
          <div className="flex items-start justify-between gap-3">
            <div>
              <CardTitle className="flex items-center gap-2">
                <Scale className="size-5 text-emerald-600" />
                Cân nặng và vòng eo
              </CardTitle>
              <p className="mt-1 text-sm text-muted-foreground">12 lần đo gần nhất</p>
            </div>
            <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-medium text-emerald-700">
              {bodyPoints.length} lần đo
            </span>
          </div>
        </CardHeader>

        <CardContent className="h-[280px] pl-1 pr-3 sm:h-[330px] sm:pl-3 sm:pr-5">
          {bodyPoints.length === 0 ? (
            <EmptyState
              title="Chưa có số đo cơ thể"
              description="Thêm cân nặng hoặc vòng eo để theo dõi thay đổi."
            />
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={bodyPoints} margin={{ top: 10, right: 4, left: -8, bottom: 4 }} accessibilityLayer>
                <CartesianGrid strokeDasharray="3 5" stroke="#e2e8f0" vertical={false} />
                <XAxis
                  dataKey="date"
                  tickFormatter={formatShortDate}
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  tickLine={false}
                  axisLine={false}
                  minTickGap={22}
                />
                <YAxis
                  yAxisId="weight"
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  tickLine={false}
                  axisLine={false}
                  width={40}
                  domain={["auto", "auto"]}
                />
                <YAxis
                  yAxisId="waist"
                  orientation="right"
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  tickLine={false}
                  axisLine={false}
                  width={38}
                  domain={["auto", "auto"]}
                />
                <Tooltip
                  labelFormatter={(label) => formatLongDate(String(label))}
                  formatter={(value, name) => [
                    `${compactNumber.format(Number(value))}${name === "Cân nặng" ? " kg" : " cm"}`,
                    name,
                  ]}
                  contentStyle={tooltipStyle}
                />
                <Legend
                  verticalAlign="top"
                  align="right"
                  height={34}
                  iconType="circle"
                  wrapperStyle={{ fontSize: 12 }}
                />
                <Line
                  yAxisId="weight"
                  type="monotone"
                  dataKey="weight"
                  name="Cân nặng"
                  stroke="#059669"
                  strokeWidth={2.75}
                  dot={{ r: 3, fill: "#ffffff", strokeWidth: 2 }}
                  activeDot={{ r: 5 }}
                  connectNulls
                />
                <Line
                  yAxisId="waist"
                  type="monotone"
                  dataKey="waist"
                  name="Vòng eo"
                  stroke="#f59e0b"
                  strokeWidth={2.75}
                  dot={{ r: 3, fill: "#ffffff", strokeWidth: 2 }}
                  activeDot={{ r: 5 }}
                  connectNulls
                />
              </LineChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>

      <Card className="overflow-hidden">
        <CardHeader className="gap-2">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <Activity className="size-5 text-blue-600" />
                Dinh dưỡng và luyện tập
              </CardTitle>
              <p className="mt-1 text-sm text-muted-foreground">14 ngày có hoạt động gần nhất</p>
            </div>
            <div className="flex gap-2 text-xs">
              <span className="rounded-full bg-emerald-50 px-2.5 py-1 font-medium text-emerald-700">
                {mealDays} ngày ăn
              </span>
              <span className="flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-1 font-medium text-blue-700">
                <Dumbbell className="size-3" />
                {workoutDays} ngày tập
              </span>
            </div>
          </div>
        </CardHeader>

        <CardContent className="h-[280px] pl-1 pr-3 sm:h-[330px] sm:pl-3 sm:pr-5">
          {activityPoints.length === 0 ? (
            <EmptyState
              title="Chưa có dữ liệu hoạt động"
              description="Ghi bữa ăn hoặc buổi tập để xem xu hướng tại đây."
            />
          ) : (
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart
                data={activityPoints}
                margin={{ top: 10, right: 4, left: -8, bottom: 4 }}
                accessibilityLayer
              >
                <CartesianGrid strokeDasharray="3 5" stroke="#e2e8f0" vertical={false} />
                <XAxis
                  dataKey="date"
                  tickFormatter={formatShortDate}
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  tickLine={false}
                  axisLine={false}
                  minTickGap={22}
                />
                <YAxis
                  yAxisId="calories"
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  tickLine={false}
                  axisLine={false}
                  width={43}
                />
                <YAxis
                  yAxisId="macro"
                  orientation="right"
                  tick={{ fontSize: 11, fill: "#64748b" }}
                  tickLine={false}
                  axisLine={false}
                  width={34}
                />
                <YAxis yAxisId="workout" hide domain={[0, "dataMax + 1"]} />
                <Tooltip
                  labelFormatter={(label) => formatLongDate(String(label))}
                  formatter={(value, name) => {
                    const unit = name === "Năng lượng" ? " kcal" : name === "Chất đạm" ? " g" : " buổi";
                    return [`${compactNumber.format(Number(value))}${unit}`, name];
                  }}
                  contentStyle={tooltipStyle}
                  cursor={{ fill: "#f1f5f9", opacity: 0.65 }}
                />
                <Legend
                  verticalAlign="top"
                  align="right"
                  height={34}
                  iconType="circle"
                  wrapperStyle={{ fontSize: 12 }}
                />
                <Bar
                  yAxisId="calories"
                  dataKey="calories"
                  name="Năng lượng"
                  fill="#10b981"
                  fillOpacity={0.82}
                  radius={[6, 6, 0, 0]}
                  maxBarSize={32}
                />
                <Line
                  yAxisId="macro"
                  type="monotone"
                  dataKey="protein"
                  name="Chất đạm"
                  stroke="#f59e0b"
                  strokeWidth={2.5}
                  dot={{ r: 2.5, fill: "#ffffff", strokeWidth: 2 }}
                  activeDot={{ r: 5 }}
                />
                <Line
                  yAxisId="workout"
                  type="monotone"
                  dataKey="workoutCount"
                  name="Buổi tập"
                  stroke="#2563eb"
                  strokeWidth={2.5}
                  dot={{ r: 3, fill: "#ffffff", strokeWidth: 2 }}
                  activeDot={{ r: 5 }}
                />
              </ComposedChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
