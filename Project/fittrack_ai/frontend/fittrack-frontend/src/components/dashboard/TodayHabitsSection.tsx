import { useState } from "react";
import { useMutation, useQueries, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, Repeat, SkipForward } from "lucide-react";
import { toast } from "sonner";
import api from "@/api/axios";
import { personalTrackingApi, type TrackingEntry } from "@/api/personaltracking.api";
import { Button } from "@/components/ui/button";
import { getApiErrorMessage } from "@/lib/format";
import TodaySection from "./TodaySection";
import { todayKey } from "./today-utils";

const HABITS_PATH = "/todos/habits";
type HabitDay = { cells: { day: string; status: string; scheduled: boolean }[] };

/** Today's cell from the server calendar (it already applies the habit schedule). */
const getHabitToday = async (id: string, day: string) =>
  (await api.get<HabitDay>(`${HABITS_PATH}/${encodeURIComponent(id)}/calendar`, { params: { from: day, to: day } })).data.cells[0] ?? null;

export default function TodayHabitsSection() {
  const queryClient = useQueryClient();
  const today = todayKey();
  const list = useQuery({
    queryKey: ["personal-tracking", HABITS_PATH, "today-center"],
    queryFn: () => personalTrackingApi.list(HABITS_PATH, 0, false),
  });
  const habits = (list.data?.content ?? []).filter((habit) => !habit.archived && habit.startDate <= today);
  const days = useQueries({
    queries: habits.map((habit) => ({
      queryKey: ["habit-calendar", habit.id, today, today, "today-center"],
      queryFn: () => getHabitToday(habit.id, today),
    })),
  });
  const [pendingId, setPendingId] = useState<string | null>(null);
  const checkin = useMutation({
    mutationFn: ({ habit, status }: { habit: TrackingEntry; status: "DONE" | "SKIPPED" }) =>
      personalTrackingApi.checkin(HABITS_PATH, habit.id, today, { status }),
    onMutate: ({ habit }) => setPendingId(habit.id),
    onSuccess: (_, { habit, status }) => {
      toast.success(status === "DONE" ? `Đã xong: ${habit.title}` : `Đã bỏ qua: ${habit.title}`);
      void queryClient.invalidateQueries({ queryKey: ["habit-calendar"] });
      void queryClient.invalidateQueries({ queryKey: ["personal-tracking"] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không đánh dấu được thói quen")),
    onSettled: () => setPendingId(null),
  });

  const rows = habits.map((habit, index) => ({ habit, day: days[index] }));
  const pending = rows.filter(({ day }) => day?.isError || (day?.data?.scheduled && day.data.status === "PENDING"));
  const scheduled = rows.filter(({ day }) => day?.data?.scheduled);
  const marked = scheduled.filter(({ day }) => day?.data?.status === "DONE" || day?.data?.status === "SKIPPED").length;
  const loading = list.isLoading || days.some((day) => day.isLoading);
  const state = loading ? "loading" : list.isError ? "error" : pending.length === 0 ? "empty" : "ready";
  const more = (list.data?.totalElements ?? 0) > (list.data?.content.length ?? 0);

  return (
    <TodaySection id="today-habits" title="Thói quen" icon={Repeat} iconClassName="bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-200"
      state={state} errorText="Không tải được thói quen." onRetry={() => void list.refetch()}
      link={{ to: "/habits", label: "Tất cả" }}
      meta={scheduled.length > 0 && <span>Đã đánh dấu {marked}/{scheduled.length}</span>}
      empty={habits.length === 0 ? "Chưa có thói quen nào." : scheduled.length === 0 ? "Hôm nay là ngày nghỉ của các thói quen." : "Đã đánh dấu hết thói quen hôm nay."}>
      <ul className="grid gap-1.5">
        {pending.map(({ habit, day }) => {
          const busy = pendingId === habit.id;
          return (
            <li key={habit.id} className="flex min-h-12 items-center gap-2 rounded-xl border px-3 py-1.5">
              <p className="min-w-0 flex-1 truncate font-medium">{habit.title}</p>
              {day?.isError ? (
                <Button size="sm" variant="ghost" onClick={() => void day.refetch()}>Tải lại</Button>
              ) : (
                <>
                  <Button size="sm" variant="ghost" disabled={busy} aria-label={`Bỏ qua ${habit.title}`}
                    onClick={() => checkin.mutate({ habit, status: "SKIPPED" })}><SkipForward className="size-3.5" /></Button>
                  <Button size="sm" disabled={busy} aria-label={`Đã làm ${habit.title}`}
                    onClick={() => checkin.mutate({ habit, status: "DONE" })}><Check className="size-3.5" />Xong</Button>
                </>
              )}
            </li>
          );
        })}
      </ul>
      {more && <p className="text-xs text-muted-foreground">Một số thói quen khác xem tại trang Thói quen.</p>}
    </TodaySection>
  );
}
