import type { Exercise } from "@/api/workout.api";

export type ExerciseSearchFilters = {
  query: string;
  muscleGroup: string;
  equipment: string;
};

export function normalizeExerciseSearch(value: string) {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "D")
    .toLocaleLowerCase("vi-VN")
    .trim();
}

export function filterExercises(
  exercises: Exercise[],
  { query, muscleGroup, equipment }: ExerciseSearchFilters,
) {
  const tokens = normalizeExerciseSearch(query).split(/\s+/).filter(Boolean);

  return exercises
    .filter((exercise) => {
      if (muscleGroup && exercise.muscleGroup !== muscleGroup) return false;
      if (equipment && exercise.equipment !== equipment) return false;
      if (tokens.length === 0) return true;

      const searchable = normalizeExerciseSearch(
        [exercise.name, exercise.muscleGroup, exercise.equipment, exercise.description]
          .filter(Boolean)
          .join(" "),
      );
      return tokens.every((token) => searchable.includes(token));
    })
    .sort((left, right) => left.name.localeCompare(right.name, "vi"));
}

export function getExerciseFacets(exercises: Exercise[]) {
  const muscleGroups = uniqueSorted(exercises.map((exercise) => exercise.muscleGroup));
  const equipment = uniqueSorted(exercises.map((exercise) => exercise.equipment));
  return { muscleGroups, equipment };
}

function uniqueSorted(values: string[]) {
  return [...new Set(values.map((value) => value?.trim()).filter(Boolean))].sort((left, right) =>
    left.localeCompare(right, "vi"),
  );
}
