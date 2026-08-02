import { expect, test } from "@playwright/test";

for (const route of ["/foods", "/workouts", "/health", "/admin/users"]) {
  test(`tải trực tiếp route SPA ${route} không trả 404`, async ({ page }) => {
    const response = await page.goto(route);

    expect(response?.status()).toBe(200);
    await expect(page).not.toHaveTitle(/404|NOT_FOUND/i);
  });
}
