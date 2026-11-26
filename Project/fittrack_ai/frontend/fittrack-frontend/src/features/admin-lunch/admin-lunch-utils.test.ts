import { describe, expect, it } from "vitest";

import type { ImportLunchMenuInput, LunchMenuItem, LunchOrder } from "@/api/lunch.api";
import {
  countOrderPayments,
  fundActionHint,
  fundAmountLabel,
  fundButtonVerb,
  fundSuccessMessage,
  menuToRawText,
  notifyResultToast,
  resolveAdminLunchTab,
  summaryButtonLabel,
  tabSearchParams,
  validateFundAdjustment,
  validateMenuPayload,
} from "./admin-lunch-utils";

const payload: ImportLunchMenuInput = {
  menuDate: "2026-11-25",
  orderLabel: "Vũ",
  vendorName: "Quán A",
  cutoffAt: "2026-11-25T10:30",
  price: 35_000,
  rawMenuText: "Tôm\nThịt",
};
const order = (paymentStatus: string) => ({ paymentStatus }) as LunchOrder;
const item = (name: string) => ({ name }) as LunchMenuItem;

describe("tabs", () => {
  it("keeps known tabs and falls back to menu", () => {
    expect(resolveAdminLunchTab("funds")).toBe("funds");
    expect(resolveAdminLunchTab("payments")).toBe("payments");
    expect(resolveAdminLunchTab("other")).toBe("menu");
    expect(resolveAdminLunchTab(null)).toBe("menu");
  });

  it("drops ?tab= for the menu tab", () => {
    expect(tabSearchParams("menu")).toEqual({});
    expect(tabSearchParams("orders")).toEqual({ tab: "orders" });
  });
});

describe("validateMenuPayload", () => {
  it("accepts a complete menu", () => {
    expect(validateMenuPayload(payload, true)).toBeNull();
  });

  it("requires date, label, vendor and cutoff", () => {
    expect(validateMenuPayload({ ...payload, vendorName: "" }, true)).toBe("Vui lòng điền đủ ngày, tiêu đề, tên quán và giờ chốt.");
  });

  it("requires a positive whole price", () => {
    expect(validateMenuPayload({ ...payload, price: 0 }, true)).toBe("Giá phần ăn phải là số nguyên dương.");
    expect(validateMenuPayload({ ...payload, price: 1.5 }, true)).toBe("Giá phần ăn phải là số nguyên dương.");
  });

  it("requires a parsable menu", () => {
    expect(validateMenuPayload(payload, false)).toBe("Menu chưa đúng định dạng. Vui lòng kiểm tra phần xem trước.");
  });
});

describe("menu helpers", () => {
  it("rebuilds the raw text with the + separator", () => {
    expect(menuToRawText({ regularItems: [item("Tôm"), item("Thịt")], specialItems: [item("Phở")] })).toBe("Tôm\nThịt\n+\nPhở");
  });

  it("labels the summary button", () => {
    expect(summaryButtonLabel(true, true, true)).toBe("Đang tổng hợp...");
    expect(summaryButtonLabel(false, false, false)).toBe("Chốt & tổng hợp");
    expect(summaryButtonLabel(false, true, false)).toBe("Xem lại tổng hợp");
    expect(summaryButtonLabel(false, true, true)).toBe("Tải lại tổng hợp");
  });
});

describe("payments", () => {
  it("counts orders by payment status", () => {
    expect(countOrderPayments([order("PAID_FUND"), order("paid_external"), order("UNPAID"), order("unpaid")])).toEqual({
      total: 4, fund: 1, external: 1, unpaid: 2,
    });
  });
});

describe("fund adjustment", () => {
  it("validates member and amount", () => {
    expect(validateFundAdjustment("", 100_000)).toBe("Vui lòng chọn thành viên.");
    expect(validateFundAdjustment("u1", 0)).toBe("Số tiền điều chỉnh phải là số nguyên dương.");
    expect(validateFundAdjustment("u1", 100_000)).toBeNull();
  });

  it("labels each action", () => {
    expect(fundSuccessMessage("REMOVE_DEBT")).toBe("Đã ghi giảm công nợ.");
    expect(fundButtonVerb("ADD_DEBT")).toBe("Ghi nợ");
    expect(fundAmountLabel("ADD_FUND")).toBe("Số tiền điều chỉnh");
    expect(fundAmountLabel("REMOVE_DEBT")).toBe("Số tiền công nợ");
    expect(fundActionHint("REMOVE_FUND")).toContain("không tạo số dư âm");
  });
});

describe("notifyResultToast", () => {
  const base = { message: "", recipientCount: 10, emailEligibleCount: 6, emailSentCount: 6, emailFailedCount: 0, emailSkippedCount: 4 };

  it("warns when emails fail", () => {
    expect(notifyResultToast({ ...base, emailSentCount: 5, emailFailedCount: 1 }).level).toBe("warning");
  });

  it("explains when nobody has email on", () => {
    expect(notifyResultToast({ ...base, emailSkippedCount: 10 }).message).toContain("chưa có tài khoản bật email");
  });

  it("reports skipped and fully sent emails", () => {
    expect(notifyResultToast(base).message).toBe("Đã tạo thông báo; email thành công 6/6. 4 tài khoản đang tắt email.");
    expect(notifyResultToast({ ...base, emailSkippedCount: 0 }).message).toBe("Đã gửi thông báo và email tới 6 tài khoản đang bật email.");
  });
});
