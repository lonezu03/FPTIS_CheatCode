import { Button } from "@/components/ui/button";
import { formatClock } from "./workout-utils";

export default function RestTimerBanner({
  seconds,
  onAdjust,
  onSkip,
}: {
  seconds: number;
  onAdjust: (delta: number) => void;
  onSkip: () => void;
}) {
  return (
    <div className="sticky top-0 z-10 flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-emerald-950 p-4 text-white shadow-lg">
      <div><p className="text-xs uppercase tracking-wider text-emerald-200">Đang nghỉ</p><p className="text-3xl font-black tabular-nums">{formatClock(seconds)}</p></div>
      <div className="flex gap-2">
        <Button variant="secondary" size="sm" onClick={() => onAdjust(-15)}>-15 giây</Button>
        <Button variant="secondary" size="sm" onClick={() => onAdjust(15)}>+15 giây</Button>
        <Button variant="secondary" size="sm" onClick={onSkip}>Bỏ qua</Button>
      </div>
    </div>
  );
}
