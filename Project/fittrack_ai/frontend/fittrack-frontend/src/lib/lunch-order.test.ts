import { describe, expect, it } from "vitest";

import { cannotAffordSponsoredPortions } from "./lunch-order";

describe("cannotAffordSponsoredPortions", () => {
  it("không chặn giỏ chỉ có phần tự đặt khi người dùng đang nợ", () => {
    expect(cannotAffordSponsoredPortions(-35_000, 0)).toBe(false);
  });

  it("chặn đặt hộ khi số dư ròng đang âm", () => {
    expect(cannotAffordSponsoredPortions(-35_000, 35_000)).toBe(true);
  });

  it("chặn khi tổng tiền đặt hộ vượt quỹ khả dụng", () => {
    expect(cannotAffordSponsoredPortions(35_000, 70_000)).toBe(true);
  });

  it("cho đặt hộ khi quỹ khả dụng đủ", () => {
    expect(cannotAffordSponsoredPortions(70_000, 70_000)).toBe(false);
  });
});
