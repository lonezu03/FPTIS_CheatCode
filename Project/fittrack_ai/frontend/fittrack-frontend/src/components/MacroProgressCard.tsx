import { Progress } from "@/components/ui/progress";

type MacroProgressCardProps = {
  title: string;
  current: number;
  target: number;
  unit: string;
  percent: number;
};

export default function MacroProgressCard({ title, current, target, unit, percent }: MacroProgressCardProps) {
  const safePercent = Math.min(percent, 100);

  return (
    <div className="rounded-2xl border bg-white p-5">
      <div className="mb-3 flex items-center justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{title}</p>
          <h3 className="text-2xl font-bold">
            {current.toFixed(0)}
            <span className="ml-1 text-sm font-normal text-muted-foreground">
              / {target.toFixed(0)} {unit}
            </span>
          </h3>
        </div>

        <span className="rounded-full bg-slate-100 px-3 py-1 text-sm font-medium">{percent.toFixed(0)}%</span>
      </div>

      <Progress value={safePercent} />

      {percent > 100 && <p className="mt-2 text-xs text-orange-600">You are over your target.</p>}
    </div>
  );
}
