import { describe, expect, it } from "vitest";

import type { Exercise } from "@/api/workout.api";
import { filterExercises, getExerciseFacets } from "./exercise-search";

const exercises: Exercise[] = [
  {
    id: "1",
    name: "Đẩy ngực tạ đơn",
    muscleGroup: "Ngực",
    equipment: "Tạ đơn",
    description: "Nằm ghế và đẩy tạ",
  },
  {
    id: "2",
    name: "Kéo xô máy",
    muscleGroup: "Lưng",
    equipment: "Máy kéo xô",
    description: "Kéo thanh về phía ngực",
  },
  {
    id: "3",
    name: "Hít đất",
    muscleGroup: "Ngực",
    equipment: "Trọng lượng cơ thể",
    description: "Giữ thân người thẳng",
  },
];

describe("exercise search", () => {
  it("tìm không phân biệt dấu và trên nhiều trường", () => {
    expect(
      filterExercises(exercises, {
        query: "nguc ta don",
        muscleGroup: "",
        equipment: "",
      }).map((exercise) => exercise.id),
    ).toEqual(["1"]);
  });

  it("kết hợp nhóm cơ cha và dụng cụ", () => {
    expect(
      filterExercises(exercises, {
        query: "",
        muscleGroup: "Ngực",
        equipment: "Trọng lượng cơ thể",
      }).map((exercise) => exercise.id),
    ).toEqual(["3"]);
  });

  it("tạo danh sách facet không trùng", () => {
    expect(getExerciseFacets(exercises)).toEqual({
      muscleGroups: ["Lưng", "Ngực"],
      equipment: ["Máy kéo xô", "Tạ đơn", "Trọng lượng cơ thể"],
    });
  });
});
