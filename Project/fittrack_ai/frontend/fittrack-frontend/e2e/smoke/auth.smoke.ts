import { expect, test } from "@playwright/test";
import { installApiMock, smokeUser, TEST_EMAIL, TEST_PASSWORD } from "./mock-api";

test.describe("Đăng nhập", () => {
  test("trang đăng nhập hiển thị và đăng nhập thành công vào Tổng quan", async ({ context, page }) => {
    const api = await installApiMock(context);

    await page.goto("/login");
    await expect(page.getByRole("heading", { name: "Đăng nhập tài khoản" })).toBeVisible();
    const email = page.getByLabel("Email", { exact: true });
    const password = page.getByLabel("Mật khẩu", { exact: true });
    await expect(email).toBeVisible();
    await expect(password).toBeVisible();

    // Client-side validation before any request is sent.
    await page.getByRole("button", { name: "Đăng nhập", exact: true }).click();
    await expect(page.getByRole("alert")).toContainText("Vui lòng nhập đầy đủ email và mật khẩu");
    expect(api.calls.filter((call) => call.path === "/api/auth/login")).toHaveLength(0);

    await email.fill(TEST_EMAIL);
    await password.fill(TEST_PASSWORD);
    await page.getByRole("button", { name: "Đăng nhập", exact: true }).click();

    await expect(page).toHaveURL(/\/dashboard$/);
    const login = api.calls.find((call) => call.path === "/api/auth/login");
    expect(login?.body).toEqual({ email: TEST_EMAIL, password: TEST_PASSWORD });

    // Dashboard renders data from the mocked endpoints.
    await expect(page.getByRole("heading", { level: 1, name: /^Hôm nay/ })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Việc hôm nay" })).toBeVisible();
    await expect(page.getByRole("heading", { name: "Chi tiêu" })).toBeVisible();
    await expect(page.getByRole("link", { name: /Hồ sơ của Nguyễn Văn An/ })).toBeVisible();
    expect(api.calls.some((call) => call.path === "/api/todos")).toBe(true);
    expect(await page.evaluate(() => JSON.parse(localStorage.getItem("fittrack-user") ?? "null")?.email)).toBe(smokeUser.email);
  });

  test("sai mật khẩu hiển thị lỗi và ở lại trang đăng nhập", async ({ context, page }) => {
    await installApiMock(context);

    await page.goto("/login");
    await page.getByLabel("Email", { exact: true }).fill(TEST_EMAIL);
    await page.getByLabel("Mật khẩu", { exact: true }).fill("sai-mat-khau");
    await page.getByRole("button", { name: "Đăng nhập", exact: true }).click();

    await expect(page.getByRole("alert")).toContainText("Email hoặc mật khẩu không đúng.");
    await expect(page).toHaveURL(/\/login$/);
  });
});

test.describe("Hết phiên (401 ở /api/auth/refresh)", () => {
  test("mở trang được bảo vệ khi không còn phiên thì chuyển về /login", async ({ context, page }) => {
    const api = await installApiMock(context, { loggedIn: false });

    await page.goto("/dashboard");

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByRole("heading", { name: "Đăng nhập tài khoản" })).toBeVisible();
    expect(api.calls.some((call) => call.path === "/api/auth/refresh")).toBe(true);
    expect(api.calls.some((call) => call.path === "/api/dashboard/today")).toBe(false);
  });

  test("đang dùng thì API trả 401 và refresh cũng 401 → đăng xuất về /login", async ({ context, page }) => {
    const api = await installApiMock(context, { loggedIn: true });

    await page.goto("/dashboard");
    await expect(page.getByRole("heading", { level: 1, name: /^Hôm nay/ })).toBeVisible();

    // The access token expires and the refresh cookie is revoked server-side.
    api.session = false;
    api.unauthorizedPaths.add("/api/finance/savings");
    const refreshesBefore = api.calls.filter((call) => call.path === "/api/auth/refresh").length;

    await page.getByRole("button", { name: "Tài chính", exact: true }).click();
    await page.getByRole("link", { name: "Mục tiêu tiết kiệm", exact: true }).click();

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByRole("heading", { name: "Đăng nhập tài khoản" })).toBeVisible();
    expect(api.calls.filter((call) => call.path === "/api/auth/refresh").length).toBeGreaterThan(refreshesBefore);
    expect(await page.evaluate(() => localStorage.getItem("fittrack-user"))).toBeNull();
  });
});
