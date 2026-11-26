import { expect, test } from "@playwright/test";
import { installApiMock } from "./mock-api";

test.describe("Âm nhạc", () => {
  test("Luyện tập hôm nay: thống kê, ghi nhanh buổi tập và xóa buổi tập", async ({ context, page }) => {
    const api = await installApiMock(context, { loggedIn: true });

    await page.goto("/dashboard");
    await page.getByRole("button", { name: "Âm nhạc", exact: true }).click();
    await page.getByRole("link", { name: "Luyện tập hôm nay", exact: true }).click();
    await expect(page).toHaveURL(/\/music$/);
    await expect(page.getByRole("heading", { level: 1, name: "Luyện tập hôm nay" })).toBeVisible();

    // Summary + best BPM + recent sessions from the mocked API.
    await expect(page.getByText("Chuỗi ngày tập")).toBeVisible();
    await expect(page.getByText("64 BPM").first()).toBeVisible();
    await expect(page.getByText("Ngón 4 còn yếu")).toBeVisible();

    // Routine steps for guitar are listed.
    await expect(page.getByText(/^Khởi động · 2 phút$/)).toBeVisible();

    // Quick log with BPM.
    const minutes = page.getByLabel("Số phút", { exact: true });
    await minutes.fill("20");
    await page.getByLabel(/BPM đạt được/).fill("70");
    await page.getByRole("button", { name: "Lưu buổi tập" }).click();
    await expect(page.getByText("Đã ghi 20 phút luyện tập.")).toBeVisible();
    const post = api.calls.find((call) => call.method === "POST" && call.path === "/api/music/sessions");
    expect(post?.body).toMatchObject({ instrument: "GUITAR", minutes: 20, bpm: 70, exerciseKey: "guitar-spider" });
    await expect(page.getByText("70 BPM").first()).toBeVisible();

    // Delete asks for confirmation first.
    await page.getByRole("button", { name: "Xóa buổi tập Ngân dài" }).click();
    await expect(page.getByRole("alertdialog")).toContainText("Xóa buổi tập?");
    await page.getByRole("button", { name: "Xóa", exact: true }).click();
    await expect(page.getByText("Đã xóa buổi tập.")).toBeVisible();
    expect(api.calls.some((call) => call.method === "DELETE" && call.path.startsWith("/api/music/sessions/m0000000"))).toBe(true);
  });

  test("Ghi-ta và sáo: sơ đồ hợp âm, thế bấm sáo và công cụ", async ({ context, page }) => {
    await installApiMock(context, { loggedIn: true });

    await page.goto("/music/guitar");
    await expect(page.getByRole("heading", { level: 1, name: "Ghi-ta" })).toBeVisible();
    await expect(page.getByRole("img", { name: /^Hợp âm C:/ })).toBeVisible();
    await page.getByRole("tab", { name: "Đổi hợp âm 1 phút" }).click();
    await expect(page).toHaveURL(/tab=one-minute/);
    await expect(page.getByRole("button", { name: "Bắt đầu 1 phút" })).toBeVisible();

    await page.goto("/music/flute");
    await expect(page.getByRole("heading", { level: 1, name: "Sáo trúc C5" })).toBeVisible();
    await expect(page.getByRole("img", { name: "Thế bấm Đô: lỗ 1 bịt, lỗ 2 bịt, lỗ 3 bịt, lỗ 4 bịt, lỗ 5 bịt, lỗ 6 bịt" })).toBeVisible();
    await expect(page.getByText("523,25 Hz").first()).toBeVisible();

    await page.goto("/music/tools");
    await expect(page.getByRole("heading", { level: 1, name: "Máy đếm nhịp & lên dây" })).toBeVisible();
    await expect(page.getByRole("slider", { name: "Tốc độ (BPM)" })).toHaveValue("60");
    await page.getByRole("button", { name: "Tăng 5 BPM" }).click();
    await expect(page.getByRole("slider", { name: "Tốc độ (BPM)" })).toHaveValue("65");
    await expect(page.getByRole("button", { name: "Bật micro" })).toBeVisible();
  });
});
