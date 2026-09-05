import { useMemo, useState } from "react";
import { Check, ChevronDown, Dumbbell, ImageOff, Search, SlidersHorizontal, X } from "lucide-react";

import type { Exercise } from "@/api/workout.api";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { filterExercises, getExerciseFacets } from "./exercise-search";

export default function ExercisePicker({
  id,
  exercises,
  value,
  onChange,
}: {
  id: string;
  exercises: Exercise[];
  value: string;
  onChange: (exerciseId: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [muscleGroup, setMuscleGroup] = useState("");
  const [equipment, setEquipment] = useState("");
  const selected = exercises.find((exercise) => exercise.id === value);
  const facets = useMemo(() => getExerciseFacets(exercises), [exercises]);
  const results = useMemo(
    () => filterExercises(exercises, { query, muscleGroup, equipment }),
    [equipment, exercises, muscleGroup, query],
  );
  const groupedResults = useMemo(() => {
    const groups = new Map<string, Exercise[]>();
    for (const exercise of results) {
      const parent = exercise.muscleGroup || "Chưa phân nhóm";
      groups.set(parent, [...(groups.get(parent) ?? []), exercise]);
    }
    return [...groups.entries()];
  }, [results]);
  const hasFilters = !!query || !!muscleGroup || !!equipment;

  const clearFilters = () => {
    setQuery("");
    setMuscleGroup("");
    setEquipment("");
  };

  const choose = (exerciseId: string) => {
    onChange(exerciseId);
    setOpen(false);
  };

  return (
    <>
      <button
        id={id}
        type="button"
        onClick={() => setOpen(true)}
        className="flex min-h-12 w-full items-center gap-3 rounded-xl border border-input bg-background px-3 py-2 text-left text-sm transition hover:border-emerald-400 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-emerald-500/20"
        aria-haspopup="dialog"
      >
        <ExerciseThumb exercise={selected} compact />
        <span className="min-w-0 flex-1">
          <span className="block truncate font-semibold">
            {selected?.name ?? "Chọn bài tập"}
          </span>
          <span className="block truncate text-xs text-muted-foreground">
            {selected
              ? `${selected.muscleGroup || "Chưa phân nhóm"} · ${selected.equipment || "Không dụng cụ"}`
              : "Tìm theo tên, nhóm cơ hoặc dụng cụ"}
          </span>
        </span>
        <ChevronDown className="size-4 shrink-0 text-muted-foreground" />
      </button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="h-[min(92vh,820px)] grid-rows-[auto_auto_minmax(0,1fr)] gap-0 overflow-hidden p-0 sm:max-w-3xl sm:p-0">
          <DialogHeader className="border-b bg-slate-50 px-5 py-5 pr-14 sm:px-6">
            <DialogTitle className="flex items-center gap-2 text-lg font-bold">
              <Dumbbell className="size-5 text-emerald-700" />
              Chọn bài tập
            </DialogTitle>
            <DialogDescription>
              Nhóm cơ được dùng như nhóm cha; sau đó có thể thu hẹp thêm theo dụng cụ hoặc từ khóa.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 border-b p-4 sm:p-5">
            <label className="relative block">
              <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                autoFocus
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Tìm tên, nhóm cơ, dụng cụ hoặc nội dung hướng dẫn..."
                aria-label="Tìm bài tập"
                className="h-11 pl-10 pr-10"
              />
              {query && (
                <button
                  type="button"
                  onClick={() => setQuery("")}
                  className="absolute right-2 top-1/2 grid size-7 -translate-y-1/2 place-items-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground"
                  aria-label="Xóa từ khóa"
                >
                  <X className="size-4" />
                </button>
              )}
            </label>

            <div className="grid gap-3 sm:grid-cols-2">
              <label className="space-y-1.5 text-xs font-semibold">
                <span>Nhóm cơ chính</span>
                <select
                  value={muscleGroup}
                  onChange={(event) => setMuscleGroup(event.target.value)}
                  className="h-10 w-full rounded-xl border border-input bg-background px-3 text-sm font-normal"
                >
                  <option value="">Tất cả nhóm cơ</option>
                  {facets.muscleGroups.map((item) => (
                    <option key={item} value={item}>{item}</option>
                  ))}
                </select>
              </label>
              <label className="space-y-1.5 text-xs font-semibold">
                <span>Dụng cụ</span>
                <select
                  value={equipment}
                  onChange={(event) => setEquipment(event.target.value)}
                  className="h-10 w-full rounded-xl border border-input bg-background px-3 text-sm font-normal"
                >
                  <option value="">Tất cả dụng cụ</option>
                  {facets.equipment.map((item) => (
                    <option key={item} value={item}>{item}</option>
                  ))}
                </select>
              </label>
            </div>

            <div className="flex items-center justify-between gap-3 text-xs text-muted-foreground">
              <span className="inline-flex items-center gap-1.5">
                <SlidersHorizontal className="size-3.5" />
                Tìm thấy <strong className="text-foreground">{results.length}</strong>/{exercises.length} bài
              </span>
              {hasFilters && (
                <Button type="button" variant="ghost" size="xs" onClick={clearFilters}>
                  Xóa bộ lọc
                </Button>
              )}
            </div>
          </div>

          <div className="min-h-0 flex-1 overflow-y-auto p-4 sm:p-5">
            {groupedResults.length === 0 ? (
              <div className="grid min-h-56 place-items-center rounded-2xl border border-dashed bg-slate-50 p-8 text-center">
                <div>
                  <Search className="mx-auto mb-3 size-8 text-slate-400" />
                  <p className="font-semibold">Không tìm thấy bài tập phù hợp</p>
                  <p className="mt-1 text-sm text-muted-foreground">Thử từ khóa ngắn hơn hoặc xóa một bộ lọc.</p>
                  <Button type="button" variant="outline" size="sm" className="mt-4" onClick={clearFilters}>
                    Hiện tất cả bài tập
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-5">
                {groupedResults.map(([parent, items]) => (
                  <section key={parent}>
                    <div className="mb-2 flex items-center gap-2">
                      <h3 className="text-xs font-bold uppercase tracking-[0.12em] text-emerald-800">{parent}</h3>
                      <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-[0.65rem] text-emerald-700">{items.length} bài</span>
                    </div>
                    <div className="grid gap-2 sm:grid-cols-2">
                      {items.map((exercise) => {
                        const active = exercise.id === value;
                        return (
                          <button
                            key={exercise.id}
                            type="button"
                            onClick={() => choose(exercise.id)}
                            className={[
                              "flex min-h-24 items-start gap-3 rounded-xl border p-3 text-left transition",
                              active
                                ? "border-emerald-500 bg-emerald-50 ring-2 ring-emerald-100"
                                : "border-slate-200 bg-white hover:border-emerald-300 hover:bg-emerald-50/40",
                            ].join(" ")}
                          >
                            <ExerciseThumb exercise={exercise} />
                            <span className="min-w-0 flex-1">
                              <span className="flex items-start justify-between gap-2">
                                <span className="font-bold leading-5">{exercise.name}</span>
                                {active && <Check className="mt-0.5 size-4 shrink-0 text-emerald-700" />}
                              </span>
                              <span className="mt-1 block text-xs font-medium text-emerald-800">
                                {exercise.equipment || "Không dụng cụ"}
                              </span>
                              <span className="mt-1 line-clamp-2 block text-xs leading-4 text-muted-foreground">
                                {exercise.description || "Chưa có mô tả kỹ thuật."}
                              </span>
                            </span>
                          </button>
                        );
                      })}
                    </div>
                  </section>
                ))}
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}

function ExerciseThumb({ exercise, compact = false }: { exercise?: Exercise; compact?: boolean }) {
  const sizeClass = compact ? "size-9" : "size-16";
  if (!exercise?.imageUrl) {
    return (
      <span className={`grid ${sizeClass} shrink-0 place-items-center rounded-xl border bg-slate-50 text-slate-400`}>
        <ImageOff className={compact ? "size-4" : "size-5"} />
      </span>
    );
  }
  return (
    <img
      src={exercise.imageUrl}
      alt=""
      className={`${sizeClass} shrink-0 rounded-xl border bg-slate-50 object-cover`}
      loading="lazy"
    />
  );
}
