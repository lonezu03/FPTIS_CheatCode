import { BellRing, CalendarDays, ChartNoAxesColumnIncreasing, Dumbbell, Salad, Sparkles } from "lucide-react";

export type EmptyStateArtworkKind = "generic" | "workout" | "food" | "calendar" | "progress" | "notification";

const icons = {
  generic: Sparkles,
  workout: Dumbbell,
  food: Salad,
  calendar: CalendarDays,
  progress: ChartNoAxesColumnIncreasing,
  notification: BellRing,
};

export default function EmptyStateArtwork({ kind = "generic" }: { kind?: EmptyStateArtworkKind }) {
  const Icon = icons[kind];
  return (
    <div className="relative mb-5 h-24 w-36" aria-hidden="true">
      <div className="absolute inset-x-4 bottom-0 h-8 rounded-[50%] bg-emerald-950/10 blur-lg" />
      <div className="absolute left-0 top-7 size-10 rounded-2xl bg-amber-100/90 rotate-[-12deg]" />
      <div className="absolute right-1 top-2 size-12 rounded-full bg-emerald-100" />
      <div className="absolute left-1/2 top-1/2 grid size-20 -translate-x-1/2 -translate-y-1/2 place-items-center rounded-[1.7rem] border border-white bg-gradient-to-br from-emerald-50 to-emerald-200 text-emerald-800 shadow-[0_16px_35px_-20px_rgba(6,78,59,.7)]">
        <Icon className="size-8" strokeWidth={1.8} />
      </div>
      <span className="absolute right-5 top-2 size-2 rounded-full bg-emerald-400" />
      <span className="absolute bottom-5 left-5 size-1.5 rounded-full bg-amber-400" />
    </div>
  );
}
