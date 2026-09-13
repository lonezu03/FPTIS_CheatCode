import api from "./axios";
import type { PageResponse } from "./pagination";

export type Exercise = {
  id: string;
  name: string;
  muscleGroup: string;
  equipment: string;
  description: string;
  imageUrl?: string | null;
};

export type WorkoutSetResponse = {
  id: string;
  exerciseId: string;
  exerciseName: string;
  muscleGroup: string;
  setNumber: number;
  exerciseOrder: number;
  setType: WorkoutSetType;
  weight: number;
  reps: number;
  rir: number;
  restSeconds: number;
  completed: boolean;
};

export type WorkoutSetType = "WARMUP" | "NORMAL" | "DROP" | "FAILURE";

export type PreviousWorkoutPerformance = {
  exerciseId: string;
  exerciseName: string;
  sessionDate: string;
  sets: WorkoutSetResponse[];
};

export type WorkoutSession = {
  id: string;
  sessionDate: string;
  note: string;
  durationMinutes: number;
  createdAt: string;
  sets: WorkoutSetResponse[];
  newPersonalRecords?: NewPersonalRecord[];
};

export type ProgressionAction =
  | "NO_DATA"
  | "INCREASE_WEIGHT"
  | "BUILD_REPS"
  | "DECREASE_OR_HOLD";

export type ProgressionSuggestion = {
  action: ProgressionAction;
  previousWeight: number | null;
  suggestedWeight: number | null;
  suggestedSets: number;
  suggestedMinReps: number;
  suggestedMaxReps: number;
  targetRir: number;
  explanation: string;
  hasEnoughData: boolean;
};

export type PersonalBest = {
  type: "HEAVIEST_WEIGHT" | "MAX_REPS_AT_WEIGHT" | "ESTIMATED_1RM" | "MAX_SESSION_VOLUME";
  value: number;
  weight: number | null;
  reps: number | null;
  achievedOn: string | null;
};

export type NewPersonalRecord = {
  type: PersonalBest["type"];
  exerciseId: string;
  exerciseName: string;
  previousValue: number | null;
  newValue: number;
  weight: number | null;
  reps: number | null;
  unit: string;
};

export type WorkoutIntelligence = {
  exerciseId: string;
  exerciseName: string;
  previousPerformance: PreviousWorkoutPerformance | null;
  progression: ProgressionSuggestion;
  personalBests: PersonalBest[];
};

export type MuscleVolume = {
  muscleGroup: string;
  workingSets: number;
  previousWeekSets: number;
  totalVolume: number;
  changeSets: number;
};

export type WeeklyWorkoutVolume = {
  weekStart: string;
  weekEnd: string;
  totalWorkingSets: number;
  totalVolume: number;
  muscleGroups: MuscleVolume[];
  disclaimer: string;
};

export type ExercisePreference = "FAVORITE" | "NORMAL" | "LESS" | "EXCLUDED";

export type ExercisePreferenceResponse = {
  exerciseId: string;
  preference: ExercisePreference;
};

export type AlternativeExercise = {
  exercise: Exercise;
  preference: ExercisePreference;
  sameEquipment: boolean;
};

export const getExercises = async (): Promise<Exercise[]> => {
  const response = await api.get("/exercises");

  return response.data;
};

export const getWorkoutSessions = async (): Promise<WorkoutSession[]> => {
  const response = await api.get("/workouts/sessions");

  return response.data;
};

export const getWorkoutSessionsPage = async (
  page = 0,
  size = 20,
): Promise<PageResponse<WorkoutSession>> => {
  const response = await api.get<PageResponse<WorkoutSession>>("/workouts/sessions/page", {
    params: { page, size },
  });
  return response.data;
};

export const createWorkoutSession = async (payload: {
  sessionDate: string;
  note: string;
  durationMinutes: number;
  sets: {
    exerciseId: string;
    setNumber: number;
    exerciseOrder: number;
    setType: WorkoutSetType;
    weight: number;
    reps: number;
    rir: number;
    restSeconds: number;
    completed: boolean;
  }[];
}): Promise<WorkoutSession> => {
  const response = await api.post("/workouts/sessions", payload);

  return response.data;
};

export const getPreviousWorkoutPerformance = async (
  exerciseId: string,
): Promise<PreviousWorkoutPerformance | null> => {
  const response = await api.get<PreviousWorkoutPerformance | undefined>(
    "/workouts/previous-performance",
    { params: { exerciseId } },
  );
  return response.data ?? null;
};

export const getWorkoutIntelligence = async (
  exerciseId: string,
  targets: { targetSets: number; minReps: number; maxReps: number; targetRir: number },
): Promise<WorkoutIntelligence> => {
  const response = await api.get<WorkoutIntelligence>("/workouts/intelligence", {
    params: { exerciseId, ...targets },
  });
  return response.data;
};

export const getWeeklyWorkoutVolume = async (): Promise<WeeklyWorkoutVolume> => {
  const response = await api.get<WeeklyWorkoutVolume>("/workouts/weekly-volume");
  return response.data;
};

export const getExercisePreferences = async (): Promise<ExercisePreferenceResponse[]> => {
  const response = await api.get<ExercisePreferenceResponse[]>("/workouts/exercise-preferences");
  return response.data;
};

export const setExercisePreference = async (
  exerciseId: string,
  preference: ExercisePreference,
): Promise<ExercisePreferenceResponse> => {
  const response = await api.put<ExercisePreferenceResponse>(
    `/workouts/exercise-preferences/${exerciseId}`,
    { preference },
  );
  return response.data;
};

export const getAlternativeExercises = async (
  exerciseId: string,
): Promise<AlternativeExercise[]> => {
  const response = await api.get<AlternativeExercise[]>(
    `/workouts/exercises/${exerciseId}/alternatives`,
  );
  return response.data;
};

export const deleteWorkoutSession = async (id: string): Promise<void> => {
  await api.delete(`/workouts/sessions/${id}`);
};

export const updateWorkoutSession = async (
  id: string,
  payload: {
    sessionDate: string;
    note: string;
    durationMinutes: number;
    weight: number;
    reps: number;
    rir: number;
  }
): Promise<WorkoutSession> => {
  const response = await api.put(`/workouts/sessions/${id}`, payload);

  return response.data;
};
