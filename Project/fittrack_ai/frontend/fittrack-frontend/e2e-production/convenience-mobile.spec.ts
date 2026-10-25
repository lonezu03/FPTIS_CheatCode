import { expect, test } from '@playwright/test';

for (const width of [320, 375, 390]) {
  test(`planner mobile ${width}px opens forms without posting data`, async ({ page }) => {
    await page.setViewportSize({ width, height: 820 });
    let writes = 0;
    await page.route('**/api/**', async route => {
      const path = new URL(route.request().url()).pathname;
      if (route.request().method() !== 'GET' && !path.endsWith('/auth/refresh')) writes++;
      const user = { id: 'owner', userId: 'owner', token: 'test-session', fullName: 'Người kiểm thử', email: 'test@example.invalid', role: 'USER', todoEnabled: true, scheduleEnabled: true, passwordChangeRequired: false };
      let json: unknown = [];
      if (path.endsWith('/auth/refresh') || path.endsWith('/users/me')) json = user;
      if (path.endsWith('/notifications')) json = { notifications: [], unreadCount: 0 };
      if (path.endsWith('/todos/page')) json = { content: [], totalElements: 0, totalPages: 0, counts: { today: 0, overdue: 0, upcoming: 0, done: 0, all: 0 } };
      await route.fulfill({ json });
    });
    await page.goto('/schedule');
    await expect(page.getByRole('heading', { name: 'Thời khóa biểu', exact: true }).first()).toBeVisible();
    await page.getByRole('button', { name: 'Tháng', exact: true }).click();
    const overflow = await page.evaluate(() => [...document.querySelectorAll('main *')].filter(element => element.getBoundingClientRect().right > window.innerWidth + 1).map(element => ({ tag: element.tagName, text: element.textContent?.slice(0, 60), classes: element.className })).slice(-8));
    expect(overflow).toEqual([]);
    await page.getByRole('button', { name: 'Mở menu' }).click();
    await expect(page.getByRole('navigation', { name: 'Điều hướng di động' })).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    await page.goto('/todos?action=new');
    const title = page.getByRole('textbox', { name: 'Tên công việc', exact: true });
    await expect(title).toBeFocused();
    await title.fill('Việc đang soạn');
    await page.reload();
    await expect(page.getByRole('button', { name: 'Khôi phục', exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Khôi phục', exact: true }).click();
    await expect(title).toHaveValue('Việc đang soạn');
    expect(writes).toBe(0);
  });
}
