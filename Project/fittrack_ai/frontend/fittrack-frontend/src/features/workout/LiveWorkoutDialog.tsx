import { useEffect, useState } from "react";
import { CheckCircle2, Plus, Timer, X } from "lucide-react";
import { toast } from "sonner";

import type { AlternativeExercise, Exercise } from "@/api/workout.api";
import { useConfirm } from "@/components/common/ConfirmDialog";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { toLocalDateInput } from "@/lib/format";
import { writeSessionDraft } from "@/lib/sessionDraft";
import { workoutElapsedSeconds } from "@/lib/workoutDraftTime";
import { substituteUnfinished } from "@/lib/workoutSubstitution";
import LiveExerciseCard from "./LiveExerciseCard";
import RestTimerBanner from "./RestTimerBanner";
import {
  useExerciseAlternatives,
  useExercisePreferences,
  useRestTimer,
  useWorkoutIntelligence,
} from "./useLiveWorkoutInsights";
import {
  applyProgressionSets,
  buildSessionPayload,
  draftKey,
  formatClock,
  intelligenceKey,
  makeExercise,
  moveItem,
  potentialRecords,
  restAfterSet,
  supersetProgressMessage,
  toggleSetCompleted,
  type DraftExercise,
  type DraftSet,
  type WorkoutSeed,
  type WorkoutSessionPayload,
} from "./workout-utils";

/** Hộp thoại buổi tập trực tiếp hoặc chỉnh sửa buổi đã lưu. */
export default function LiveWorkoutDialog({
  owner,
  seed,
  exercises,
  saving,
  onClose,
  onFinish,
}: {
  owner: string;
  seed: WorkoutSeed;
  exercises: Exercise[];
  saving: boolean;
  onClose: () => void;
  onFinish: (payload: WorkoutSessionPayload) => Promise<void>;
}) {
  const confirm = useConfirm();
  const confirmDiscard = async () => {
    const ok = await confirm({
      title: "Hủy buổi tập?",
      description: "Buổi tập đang thực hiện sẽ đóng; dữ liệu chưa lưu sẽ mất.",
      confirmText: "Hủy buổi tập",
      cancelText: "Tập tiếp",
      destructive: true,
    });
    if (ok) onClose();
  };
  const editingSession = !!seed.sessionId;
  const [title, setTitle] = useState(seed.title);
  const [note, setNote] = useState(seed.note ?? "");
  const [sessionDate, setSessionDate] = useState(seed.sessionDate ?? toLocalDateInput());
  const [durationMinutes, setDurationMinutes] = useState(seed.durationMinutes ?? 1);
  const [groups, setGroups] = useState(seed.exercises.length ? seed.exercises : [makeExercise(exercises[0]?.id ?? "")]);
  const [startedAt] = useState(() => Date.now());
  const [elapsed, setElapsed] = useState(seed.elapsedSeconds ?? 0);
  const [announcedRecords] = useState(() => new Set<string>());
  const rest = useRestTimer();
  const intelligence = useWorkoutIntelligence(groups);
  const { preferences, updatePreference } = useExercisePreferences();
  const { alternatives, equipment, setEquipment, loadAlternatives, closeAlternatives } = useExerciseAlternatives();

  useEffect(() => {
    const persist = () => writeSessionDraft(owner, "workout", { title, note, exercises: groups, appointmentId: seed.appointmentId, sessionId: seed.sessionId, sessionDate, durationMinutes, elapsedSeconds: workoutElapsedSeconds(seed.elapsedSeconds ?? 0, startedAt, Date.now()) });
    persist();
    window.addEventListener("pagehide", persist);
    return () => window.removeEventListener("pagehide", persist);
  }, [owner, title, note, groups, startedAt, seed.elapsedSeconds, seed.sessionId, seed.appointmentId, elapsed, sessionDate, durationMinutes]);

  useEffect(() => {
    const timer = window.setInterval(() => setElapsed(workoutElapsedSeconds(seed.elapsedSeconds ?? 0, startedAt, Date.now())), 1000);
    return () => window.clearInterval(timer);
  }, [startedAt, seed.elapsedSeconds]);

  const updateGroup = (groupKey: string, updater: (group: DraftExercise) => DraftExercise) => {
    setGroups((current) => current.map((group) => (group.key === groupKey ? updater(group) : group)));
  };

  const announcePotentialRecord = (group: DraftExercise, set: DraftSet) => {
    for (const record of potentialRecords(intelligence[intelligenceKey(group)], set)) {
      if (!announcedRecords.has(record.key)) {
        announcedRecords.add(record.key);
        toast.success("🏆 Có thể là PR mới", { description: record.text });
      }
    }
  };

  const toggleSet = (groupKey: string, setKey: string) => {
    const group = groups.find((item) => item.key === groupKey);
    const target = group?.sets.find((item) => item.key === setKey);
    const willComplete = target ? !target.completed : false;
    updateGroup(groupKey, (item) => toggleSetCompleted(item, setKey));
    if (willComplete && group) rest.startRest(restAfterSet(groups, group));
    if (willComplete && group && target) {
      announcePotentialRecord(group, target);
      const message = supersetProgressMessage(groups, group, setKey, (id) => exercises.find(e => e.id === id)?.name);
      if (message) toast.info(message);
    }
  };

  const applyProgression = (group: DraftExercise) => {
    const suggestion = intelligence[intelligenceKey(group)]?.progression;
    if (!suggestion || suggestion.suggestedWeight == null) return;
    updateGroup(group.key, (current) => applyProgressionSets(current, suggestion));
    toast.success("Đã áp dụng mức đề xuất vào buổi tập");
  };

  const changeExercise = async (group: DraftExercise, exerciseId: string) => {
    if (!editingSession) {
      if (!(await confirm({ title: "Đổi bài tập?", description: "Chỉ đổi các hiệp chưa làm; hiệp đã xong giữ nguyên. Mức tạ bài mới đặt về 0 kg, hãy kiểm tra lại trước khi tập.", confirmText: "Đổi bài" }))) return;
      setGroups(current => substituteUnfinished(current, group.key, exerciseId, draftKey, false));
      return;
    }
    updateGroup(group.key, (item) => ({ ...item, exerciseId, historicalExerciseName: undefined }));
    closeAlternatives(group.key);
  };

  const pickAlternative = async (group: DraftExercise, item: AlternativeExercise) => {
    if (!(await confirm({ title: `Thay bằng ${item.exercise.name}?`, description: "Chỉ thay các hiệp chưa làm; hiệp đã xong giữ nguyên. Mức tạ bài mới đặt về 0 kg.", confirmText: "Thay bài" }))) return;
    setGroups(current => substituteUnfinished(current, group.key, item.exercise.id, draftKey));
    closeAlternatives(group.key);
  };

  const finish = async () => {
    const payload = buildSessionPayload({ groups, title, note, sessionDate, isEditing: editingSession, durationMinutes, elapsedSeconds: elapsed });
    if (!payload) {
      toast.error("Hãy hoàn thành ít nhất một set trước khi kết thúc buổi tập");
      return;
    }
    await onFinish(payload);
  };

  return (
    <Dialog open onOpenChange={(open) => {
      if (!open) void confirmDiscard();
    }}>
      <DialogContent className="flex max-h-[96dvh] w-[calc(100vw-1rem)] max-w-6xl flex-col gap-0 overflow-hidden p-0 sm:w-[calc(100vw-2rem)]">
        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto px-4 pt-5 pb-4 sm:px-6 sm:pt-6">
          <DialogHeader>
            <DialogTitle className="flex flex-wrap items-center justify-between gap-3 pr-8">
              <span>{editingSession ? "Chỉnh sửa buổi tập" : "Buổi tập trực tiếp"}</span>
              <span className="rounded-full bg-emerald-100 px-3 py-1 text-sm font-semibold text-emerald-800">
                <Timer className="mr-1 inline h-4 w-4" /> {formatClock(elapsed)}
              </span>
            </DialogTitle>
          </DialogHeader>
          {editingSession && <div className="grid gap-3 sm:grid-cols-2"><label className="text-sm">Ngày tập<Input type="date" value={sessionDate} onChange={event => setSessionDate(event.target.value)} /></label><label className="text-sm">Thời lượng (phút)<Input type="number" min={1} max={600} value={durationMinutes} onChange={event => setDurationMinutes(Number(event.target.value))} /></label></div>}

          {rest.restRunning && <RestTimerBanner seconds={rest.restSeconds} onAdjust={rest.adjustRest} onSkip={rest.skipRest} />}

          <details className="rounded-2xl border border-slate-200 bg-slate-50 p-3">
            <summary className="cursor-pointer text-sm font-semibold">Tên buổi tập và ghi chú</summary>
            <div className="mt-3 grid gap-3 sm:grid-cols-2">
              <label className="text-sm font-medium">Tên buổi tập<Input className="mt-1" value={title} onChange={(event) => setTitle(event.target.value)} /></label>
              <label className="text-sm font-medium">Ghi chú<Input className="mt-1" value={note} onChange={(event) => setNote(event.target.value)} placeholder="Cảm nhận, mục tiêu hôm nay..." /></label>
            </div>
          </details>

          <div className="space-y-4">
            {groups.map((group, groupIndex) => (
              <LiveExerciseCard
                key={group.key}
                group={group}
                index={groupIndex}
                total={groups.length}
                exercises={exercises}
                editingSession={editingSession}
                insight={intelligence[intelligenceKey(group)]}
                preference={preferences[group.exerciseId] ?? "NORMAL"}
                alternativesOpened={Object.prototype.hasOwnProperty.call(alternatives, group.key)}
                alternativeState={alternatives[group.key]}
                alternativeEquipment={equipment}
                onUpdate={(updater) => updateGroup(group.key, updater)}
                onMove={(direction) => setGroups((current) => moveItem(current, groupIndex, direction))}
                onRemove={() => setGroups((current) => current.filter((item) => item.key !== group.key))}
                onChangeExercise={(exerciseId) => void changeExercise(group, exerciseId)}
                onToggleSet={(setKey) => toggleSet(group.key, setKey)}
                onApplyProgression={() => applyProgression(group)}
                onPreferenceChange={(preference) => updatePreference(group.exerciseId, preference)}
                onLoadAlternatives={() => void loadAlternatives(group)}
                onEquipmentChange={(value) => { setEquipment(value); void loadAlternatives(group, value); }}
                onPickAlternative={(item) => void pickAlternative(group, item)}
              />
            ))}
          </div>

          <Button variant="outline" onClick={() => setGroups((current) => [...current, makeExercise(exercises[0]?.id ?? "")])} disabled={!exercises.length}>
            <Plus /> Thêm bài tập
          </Button>
        </div>
        <div className="flex shrink-0 flex-col-reverse gap-2 border-t bg-white p-4 sm:flex-row sm:justify-end sm:px-6">
          <Button variant="destructive" onClick={() => void confirmDiscard()}><X />Hủy buổi tập</Button>
          <Button onClick={finish} disabled={saving}><CheckCircle2 />{saving ? "Đang lưu..." : editingSession ? "Lưu thay đổi" : "Hoàn thành buổi tập"}</Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
