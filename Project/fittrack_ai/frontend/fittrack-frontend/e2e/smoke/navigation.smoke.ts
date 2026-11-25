import { expect, test, type Page } from "@playwright/test";
import { installApiMock, SAVINGS_GOAL_TITLE } from "./mock-api";

async function openDashboard(page: Page) {
  await page.goto("/dashboard");
  await expect(page.getByRole("heading", { level: 1, name: /^Hôm nay/ })).toBeVisible();
}

test.describe("Điều hướng sau đăng nhập", () => {
  test.beforeEach(async ({ context }) => {
    await installApiMock(context, { loggedIn: true });
  });

  test("sidebar hai cột: chọn nhóm ở rail đổi panel, bấm trang trong panel mở module", async ({ page }) => {
    await openDashboard(page);

    const financeGroup = page.getByRole("button", { name: "Tài chính", exact: true });
    await expect(financeGroup).toBeVisible();
    await expect(financeGroup).toHaveAttribute("aria-pressed", "false");

    await financeGroup.click();
    await expect(financeGroup).toHaveAttribute("aria-pressed", "true");
    // Switching group only changes the panel; it never navigates by itself.
    await expect(page.getByRole("heading", { name: "Tài chính", exact: true })).toBeVisible();
    await expect(page).toHaveURL(/\/dashboard$/);
    await expect(page.getByRole("link", { name: "Thu chi & ngân sách", exact: true })).toBeVisible();
    await expect(page.getByRole("link", { name: "Chi tiêu chung", exact: true })).toBeVisible();

    await page.getByRole("link", { name: "Mục tiêu tiết kiệm", exact: true }).click();
    await expect(page).toHaveURL(/\/finance\/savings$/);
    await expect(page.getByRole("heading", { name: "Mục tiêu tiết kiệm", level: 1 })).toBeVisible();
    await expect(page.getByRole("heading", { name: SAVINGS_GOAL_TITLE })).toBeVisible();

    // Pick another group: the panel follows the rail again.
    const workGroup = page.getByRole("button", { name: "Công việc & thời gian", exact: true });
    await workGroup.click();
    await expect(workGroup).toHaveAttribute("aria-pressed", "true");
    await expect(page.getByRole("link", { name: "Việc cần làm", exact: true })).toBeVisible();
  });

  test("Ctrl+K mở bảng tìm chức năng và Enter mở trang đã chọn", async ({ page }) => {
    await openDashboard(page);

    await page.keyboard.press("Control+k");
    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    // The palette's caption may change ("Tìm chức năng" / "Tìm nhanh"); it has one combobox.
    const search = dialog.getByRole("combobox");
    await expect(search).toBeFocused();

    await search.fill("tiet kiem");
    await expect(dialog.getByRole("option").first()).toContainText("Mục tiêu tiết kiệm");
    await search.press("Enter");

    await expect(dialog).toBeHidden();
    await expect(page).toHaveURL(/\/finance\/savings$/);
    await expect(page.getByRole("heading", { name: SAVINGS_GOAL_TITLE })).toBeVisible();

    // Escape closes the palette without navigating.
    await page.keyboard.press("Control+k");
    await expect(page.getByRole("dialog")).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog")).toBeHidden();
    await expect(page).toHaveURL(/\/finance\/savings$/);
  });
});
