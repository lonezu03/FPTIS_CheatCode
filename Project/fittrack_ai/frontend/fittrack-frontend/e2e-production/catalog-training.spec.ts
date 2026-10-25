import { expect, test, type Page } from '@playwright/test';

const exercise = { id: 'exercise', name: 'Smith Squat', muscleGroup: 'Legs', equipment: 'Smith Machine', active: true, approvalStatus: 'APPROVED' };
const plan = { id: 'plan', name: 'Giáo án test', version: 0, days: [{ id: 'day', name: 'Chân', dayOrder: 1, exercises: [{ exerciseId: 'exercise', exerciseName: 'Smith Squat', exerciseOrder: 1, targetSets: 3, targetReps: 10, targetWeight: 20, targetRir: 2, restSeconds: 120, minReps: 8, maxReps: 12, coachingNote: 'Giữ lưng ổn định' }] }] };

async function mockApi(page: Page, onWrite: (path: string) => void) {
  await page.route('**/api/**', async route => {
    const path = new URL(route.request().url()).pathname;
    if (route.request().method() !== 'GET' && !path.endsWith('/auth/refresh')) onWrite(path);
    const user = { id: 'admin', userId: 'admin', token: 'test', role: 'ADMIN', fullName: 'Kiểm thử', email: 'test@example.invalid', fitnessEnabled: true, healthEnabled: true };
    let json: unknown = [];
    if (path.endsWith('/auth/refresh') || path.endsWith('/users/me')) json = user;
    else if (path.endsWith('/notifications')) json = { unreadCount: 0, notifications: [] };
    else if (path.endsWith('/exercises/facets')) json = { muscleGroups: ['Legs'], equipment: ['Smith Machine'] };
    else if (path.endsWith('/exercises/page')) json = { content: [exercise], totalPages: 1, totalElements: 1, page: 0, size: 20 };
    else if (path.endsWith('/exercises')) json = [exercise];
    else if (path.endsWith('/workout-plans/page')) json = { content: [plan], totalPages: 1, totalElements: 1, page: 0, size: 12 };
    else if (path.endsWith('/workout-plans')) json = [plan];
    else if (path.endsWith('/sessions/history')) json = { content: [], totalPages: 0, totalElements: 0, page: 0, size: 12 };
    else if (path.endsWith('/workouts/weekly-volume')) json = { weekStart: '2026-10-19', weekEnd: '2026-10-25', totalWorkingSets: 0, totalVolume: 0, muscleGroups: [], disclaimer: '' };
    else if (path.endsWith('/catalog-imports/EXERCISE/preview')) json = { id: 'batch', kind: 'EXERCISE', createdAt: '2026-10-25T12:00:00', committedAt: null, rows: [{ number: 2, values: { name: 'Smith Squat', muscleGroup: 'Legs', equipment: 'Smith' }, before: {}, after: { name: 'Smith Squat', muscleGroup: 'Legs', equipment: 'Smith Machine' }, errors: [], warnings: [], suggestedAction: 'CREATE', resultId: null }] };
    else if (path.endsWith('/batch/commit')) json = { id: 'batch', kind: 'EXERCISE', createdAt: '2026-10-25T12:00:00', committedAt: '2026-10-25T12:01:00', rows: [] };
    else if (path.includes('/intelligence') || path.includes('/previous-performance')) json = null;
    await route.fulfill({ json });
  });
}

test('mobile import requires explicit preview and confirmation', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const writes: string[] = [];
  await mockApi(page, path => writes.push(path));
  await page.goto('/exercises');
  await page.getByRole('button', { name: 'Nhập hàng loạt' }).click();
  await page.getByRole('textbox', { name: /Hoặc dán bảng/ }).fill('name\tmuscleGroup\tequipment\nSmith Squat\tLegs\tSmith');
  await page.getByRole('button', { name: 'Kiểm tra và xem trước' }).click();
  const commit = page.getByRole('button', { name: 'Xác nhận nhập 1 dòng' });
  await expect(commit).toBeDisabled();
  expect(writes.some(path => path.endsWith('/commit'))).toBe(false);
  await page.getByRole('checkbox', { name: /Tôi đã kiểm tra/ }).check();
  await expect(commit).toBeEnabled();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await commit.click();
  await expect(page.getByRole('dialog')).not.toBeVisible();
  expect(writes.filter(path => path.endsWith('/commit'))).toHaveLength(1);
});

test('start from plan opens live workout without creating history', async ({ page }) => {
  const writes: string[] = [];
  await mockApi(page, path => writes.push(path));
  await page.goto('/workout-plans');
  await page.getByRole('button', { name: 'Bắt đầu tập', exact: true }).first().click();
  await expect(page.getByRole('dialog')).toBeVisible();
  await expect(page.getByRole('heading', { name: /Buổi tập trực tiếp/ })).toBeVisible();
  await expect(page.getByText('Giữ lưng ổn định', { exact: true })).toBeVisible();
  expect(writes).toEqual([]);
});
