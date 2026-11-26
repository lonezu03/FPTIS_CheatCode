import { describe, expect, it } from "vitest";

import type { WorkoutIntelligence, WorkoutSession, WorkoutSetResponse } from "@/api/workout.api";
import {
  appendSet,
  applyProgressionSets,
  buildSessionPayload,
  formatClock,
  groupSessionSets,
  intelligenceKey,
  isValidWorkoutDraft,
  makeExercise,
  makeSet,
  moveItem,
  potentialRecords,
  removeLastSet,
  restAfterSet,
  missingExerciseCount,
  seedFromLatestSession,
  seedFromPastSession,
  seedFromSession,
  sessionVolume,
  summarizeSessions,
  supersetProgressMessage,
  type DraftExercise,
} from "./workout-utils";

const set = (overrides: Partial<WorkoutSetResponse> = {}): WorkoutSetResponse => ({
  id: Math.random().toString(36), exerciseId: "bench", exerciseName: "Đẩy ngực", muscleGroup: "Ngực", setNumber: 1,
  exerciseOrder: 1, setType: "NORMAL", weight: 50, reps: 10, rir: 2, restSeconds: 90, completed: true, ...overrides,
});
const session = (sets: WorkoutSetResponse[], overrides: Partial<WorkoutSession> = {}): WorkoutSession => ({
  id: "s1", sessionDate: "2026-11-20", note: "Ngực", durationMinutes: 45, createdAt: "2026-11-20T08:00:00", sets, ...overrides,
});
const insight = (heaviest: number, e1rm: number): WorkoutIntelligence => ({
  exerciseId: "bench", exerciseName: "Đẩy ngực", previousPerformance: null,
  progression: { action: "INCREASE_WEIGHT", previousWeight: 50, suggestedWeight: 52.5, suggestedSets: 2, suggestedMinReps: 8, suggestedMaxReps: 12, targetRir: 1, explanation: "", hasEnoughData: true },
  personalBests: [{ type: "HEAVIEST_WEIGHT", value: heaviest }, { type: "ESTIMATED_1RM", value: e1rm }] as WorkoutIntelligence["personalBests"],
});

describe("thống kê buổi tập", () => {
  it("volume và tổng set bỏ set khởi động và set chưa xong", () => {
    const value = session([set(), set({ setType: "WARMUP", weight: 20 }), set({ completed: false })]);
    expect(sessionVolume(value)).toBe(500);
    expect(summarizeSessions([value, session([set({ weight: 10 })], { durationMinutes: 15 })])).toEqual({ totalSets: 2, totalVolume: 600, totalMinutes: 60 });
  });

  it("nhóm set theo thứ tự bài, cùng bài ở hai vị trí tách riêng", () => {
    const groups = groupSessionSets([set(), set({ exerciseId: "row", exerciseOrder: 2 }), set({ exerciseOrder: 3 }), set({ setNumber: 2 })]);
    expect(groups.map(items => items.length)).toEqual([2, 1, 1]);
  });
});

describe("tạo buổi tập", () => {
  it("dùng lại buổi gần đây bỏ bài không còn trong kho", () => {
    const seed = seedFromLatestSession(session([set(), set({ exerciseId: "old" })]), [{ id: "bench" } as never]);
    expect(seed.exercises.map(item => item.exerciseId)).toEqual(["bench"]);
    expect(seed.exercises[0].sets[0]).toMatchObject({ weight: 50, reps: 10, completed: false });
  });

  it("lặp lại buổi cũ tạo buổi mới cùng bài, set chưa hoàn thành", () => {
    const past = session([set(), set({ setNumber: 2, weight: 55, reps: 8 }), set({ exerciseId: "old" })]);
    const seed = seedFromPastSession(past, [{ id: "bench" } as never]);
    expect(seed).toMatchObject({ title: "Lặp lại: Ngực" });
    expect(seed.sessionId).toBeUndefined();
    expect(seed.exercises[0].sets.map(item => [item.weight, item.reps, item.completed])).toEqual([[50, 10, false], [55, 8, false]]);
    expect(missingExerciseCount(past, [{ id: "bench" } as never])).toBe(1);
    expect(seedFromPastSession(session([set()], { note: undefined }), [{ id: "bench" } as never]).title).toBe("Lặp lại buổi trước");
  });

  it("chỉnh sửa buổi giữ tên bài lịch sử và các set đã lưu", () => {
    const seed = seedFromSession(session([set(), set({ setNumber: 2, completed: true })]));
    expect(seed).toMatchObject({ title: "Ngực", sessionId: "s1", sessionDate: "2026-11-20", durationMinutes: 45 });
    expect(seed.exercises[0]).toMatchObject({ historicalExerciseName: "Đẩy ngực", restSeconds: 90 });
    expect(seed.exercises[0].sets).toHaveLength(2);
  });
});

describe("thao tác trong buổi", () => {
  it("đổi chỗ bài trong giới hạn danh sách", () => {
    expect(moveItem([1, 2, 3], 0, 1)).toEqual([2, 1, 3]);
    const items = [1, 2];
    expect(moveItem(items, 0, -1)).toBe(items);
  });

  it("thêm set sao chép set cuối và không bỏ set cuối cùng", () => {
    const group = makeExercise("bench", { sets: [makeSet({ weight: 40, reps: 6, rir: 1, completed: true })] });
    expect(appendSet(group).sets[1]).toMatchObject({ weight: 40, reps: 6, rir: 1, completed: false });
    expect(removeLastSet(group).sets).toHaveLength(1);
  });

  it("nghỉ theo bài, nghỉ giữa bài và giữa vòng của superset", () => {
    const a = makeExercise("a", { groupKey: "A", betweenExerciseRestSeconds: 20, betweenRoundRestSeconds: 120 });
    const b = makeExercise("b", { groupKey: "A" });
    const solo = makeExercise("c", { restSeconds: 60 });
    expect(restAfterSet([a, b, solo], a)).toBe(20);
    expect(restAfterSet([a, b, solo], b)).toBe(90);
    expect(restAfterSet([a, b, solo], solo)).toBe(60);
  });

  it("báo bài tiếp theo trong superset", () => {
    const a = makeExercise("a", { groupKey: "A" });
    const b = makeExercise("b", { groupKey: "A" });
    const name = (id: string) => ({ a: "Kéo xà", b: "Hít đất" })[id];
    expect(supersetProgressMessage([a, b], a, a.sets[0].key, name)).toBe("Nhóm A · tiếp theo: Hít đất · vòng 1");
    expect(supersetProgressMessage([a, b], b, b.sets[0].key, name)).toBe("Nhóm A · tiếp theo: Kéo xà · vòng 2");
    expect(supersetProgressMessage([makeExercise("c")], makeExercise("c"), "x", name)).toBeNull();
  });

  it("PR chỉ tính set chính, e1RM theo Epley", () => {
    expect(potentialRecords(insight(50, 70), makeSet({ weight: 60, reps: 5 })).map(item => item.text)).toEqual(["Mức tạ mới 60 kg"]);
    expect(potentialRecords(insight(80, 60), makeSet({ weight: 60, reps: 5 })).map(item => item.text)).toEqual(["e1RM ước tính 70 kg"]);
    expect(potentialRecords(insight(0, 0), makeSet({ setType: "WARMUP", weight: 60 }))).toEqual([]);
    expect(potentialRecords(undefined, makeSet({ weight: 60 }))).toEqual([]);
  });

  it("áp mức đề xuất tạo lại set và giữ loại set", () => {
    const group = makeExercise("bench", { sets: [makeSet({ setType: "WARMUP" })] });
    const next = applyProgressionSets(group, insight(0, 0).progression);
    expect(next.sets.map(item => [item.setType, item.weight, item.reps, item.rir])).toEqual([["WARMUP", 52.5, 8, 1], ["NORMAL", 52.5, 8, 1]]);
  });

  it("khóa gợi ý gồm bài và mục tiêu", () => {
    expect(intelligenceKey({ exerciseId: "x", targetSets: 3, minReps: 8, maxReps: 12, targetRir: 2 })).toBe("x:3:8:12:2");
  });
});

describe("kết thúc buổi", () => {
  const groups: DraftExercise[] = [
    makeExercise("a", { sets: [makeSet({ completed: true }), makeSet()] }),
    makeExercise("b", { restSeconds: 60, sets: [makeSet({ completed: true, restSeconds: 30 })] }),
  ];

  it("chỉ gửi set đã xong, đánh số lại và ghép tên với ghi chú", () => {
    const payload = buildSessionPayload({ groups, title: " Ngực ", note: " mệt ", sessionDate: "2026-11-26", isEditing: false, durationMinutes: 1, elapsedSeconds: 61 });
    expect(payload).toMatchObject({ note: "Ngực · mệt", durationMinutes: 2, sessionDate: "2026-11-26" });
    expect(payload?.sets.map(item => [item.exerciseId, item.exerciseOrder, item.setNumber, item.restSeconds])).toEqual([["a", 1, 1, 90], ["b", 2, 1, 30]]);
  });

  it("chỉnh sửa giữ thời lượng nhập tay; không có set xong thì trả null", () => {
    expect(buildSessionPayload({ groups, title: "", note: "", sessionDate: "d", isEditing: true, durationMinutes: 40, elapsedSeconds: 5 })?.durationMinutes).toBe(40);
    expect(buildSessionPayload({ groups: [makeExercise("a")], title: "", note: "", sessionDate: "d", isEditing: false, durationMinutes: 1, elapsedSeconds: 0 })).toBeNull();
  });
});

describe("bản nháp và định dạng", () => {
  it("từ chối bản nháp hỏng", () => {
    expect(isValidWorkoutDraft({ title: "x", exercises: [makeExercise("a")] })).toBe(true);
    expect(isValidWorkoutDraft({ title: "x", exercises: [] })).toBe(false);
    expect(isValidWorkoutDraft({ title: "x", exercises: [makeExercise("a", { sets: [makeSet({ restSeconds: 5000 })] })] })).toBe(false);
  });

  it("định dạng đồng hồ mm:ss", () => {
    expect(formatClock(0)).toBe("00:00");
    expect(formatClock(125)).toBe("02:05");
  });
});
