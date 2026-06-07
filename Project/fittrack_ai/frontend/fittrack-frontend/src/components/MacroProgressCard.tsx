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
    <div className="rounded-2xl border bg-white p-3 sm:p-5">
      <div className="mb-2 flex items-center justify-between sm:mb-3">
        <div>
          <p className="text-xs text-muted-foreground sm:text-sm">{title}</p>
          <h3 className="text-xl font-bold sm:text-2xl">
            {current.toFixed(0)}
            <span className="ml-1 text-sm font-normal text-muted-foreground">
              / {target.toFixed(0)} {unit}
            </span>
          </h3>
        </div>

        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium sm:px-3 sm:py-1 sm:text-sm">
          {percent.toFixed(0)}%
        </span>
      </div>

      <Progress value={safePercent} />

      {percent > 100 && <p className="mt-2 text-xs text-orange-600">You are over your target.</p>}
    </div>
  );
}
