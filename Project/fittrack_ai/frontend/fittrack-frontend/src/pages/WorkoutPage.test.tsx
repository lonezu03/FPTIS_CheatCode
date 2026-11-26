import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";

import WorkoutPage from "./WorkoutPage";
import { ConfirmProvider } from "@/components/common/ConfirmDialog";
import {
  getExercisePreferences,
  getExercises,
  getWeeklyWorkoutVolume,
  getWorkoutIntelligence,
  getWorkoutSessionsPage,
  type Exercise,
} from "@/api/workout.api";
import { getWorkoutPlans } from "@/api/workout-plan.api";
import { getTrainingAppointment } from "@/api/training-program.api";

vi.mock("sonner", () => ({ toast: { success: vi.fn(), info: vi.fn(), error: vi.fn() } }));
vi.mock("@/api/workout.api", () => ({
  getExercises: vi.fn(), getWorkoutSessionsPage: vi.fn(), getWeeklyWorkoutVolume: vi.fn(), getWorkoutIntelligence: vi.fn(),
  getExercisePreferences: vi.fn(), setExercisePreference: vi.fn(), getAlternativeExercises: vi.fn(),
  createWorkoutSession: vi.fn(), replaceWorkoutSession: vi.fn(), deleteWorkoutSession: vi.fn(),
}));
vi.mock("@/api/workout-plan.api", () => ({ getWorkoutPlans: vi.fn() }));
vi.mock("@/api/training-program.api", () => ({ getTrainingAppointment: vi.fn(), completeTraining: vi.fn() }));

const bench = { id: "bench", name: "Đẩy ngực", muscleGroup: "Ngực", equipment: "Tạ đòn" } as Exercise;

function show(path = "/workouts") {
  render(
    <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } })}>
      <ConfirmProvider><MemoryRouter initialEntries={[path]}><WorkoutPage /></MemoryRouter></ConfirmProvider>
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  sessionStorage.clear();
  vi.mocked(getExercises).mockResolvedValue([bench]);
  vi.mocked(getWorkoutPlans).mockResolvedValue([]);
  vi.mocked(getWorkoutSessionsPage).mockResolvedValue({ content: [], totalElements: 0, totalPages: 0, number: 0, size: 12 } as never);
  vi.mocked(getWeeklyWorkoutVolume).mockResolvedValue({ weekStart: "2026-11-23", weekEnd: "2026-11-29", totalWorkingSets: 0, totalVolume: 0, muscleGroups: [], disclaimer: "Tham khảo" } as never);
  vi.mocked(getExercisePreferences).mockResolvedValue([]);
  vi.mocked(getWorkoutIntelligence).mockRejectedValue(new Error("offline"));
});
afterEach(() => { cleanup(); vi.clearAllMocks(); });

describe("WorkoutPage", () => {
  it("hiển thị trạng thái trống của lịch sử", async () => {
    show();
    expect(await screen.findByText("Chưa có buổi tập")).toBeInTheDocument();
    expect(screen.getByText("Chưa có set chính nào trong tuần này.")).toBeInTheDocument();
  });

  it("mở buổi tập tự do và tải gợi ý bằng TanStack Query", async () => {
    show();
    fireEvent.click(await screen.findByRole("button", { name: /Bắt đầu buổi tập tự do/ }));
    expect(await screen.findByText("Buổi tập trực tiếp")).toBeInTheDocument();
    await waitFor(() => expect(getWorkoutIntelligence).toHaveBeenCalledWith("bench", { targetSets: 3, minReps: 8, maxReps: 12, targetRir: 2 }));
    expect(getExercisePreferences).toHaveBeenCalledTimes(1);
    expect(await screen.findByText("Chưa thể tải đề xuất. Bạn vẫn có thể tập và lưu bình thường.")).toBeInTheDocument();
  });

  it("tự mở lần tập trong lịch từ ?appointment=", async () => {
    vi.mocked(getTrainingAppointment).mockResolvedValue({
      id: "ap1", title: "Ngày ngực", startAt: "2026-11-26T07:00:00", version: 1,
      day: { id: "d1", name: "Ngực", dayOrder: 1, exercises: [{ id: "x", exerciseId: "bench", exerciseName: "Đẩy ngực", muscleGroup: "Ngực", equipment: null, description: null, imageUrl: null, exerciseOrder: 1, targetSets: 2, targetReps: 8, targetWeight: 60, targetRir: 2 }] },
    });
    show("/workouts?appointment=ap1");
    expect(await screen.findByText("Buổi tập trực tiếp")).toBeInTheDocument();
    expect(getTrainingAppointment).toHaveBeenCalledWith("ap1");
    expect(screen.getAllByLabelText(/mức tạ kg/)).toHaveLength(2);
  });
});
