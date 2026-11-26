import type {
  ImportLunchMenuInput,
  LunchFundAdjustmentAction,
  LunchMenu,
  LunchMenuNotificationResult,
  LunchOrder,
} from "@/api/lunch.api";

export type MenuAction = {
  menu: LunchMenu;
  action: "close" | "reopen";
};

export const DEFAULT_PRICE = 35_000;
export const FUND_PRESETS = [100_000, 200_000, 500_000];
export const ADMIN_LUNCH_TABS = ["menu", "orders", "funds", "payments"] as const;
export type AdminLunchTab = (typeof ADMIN_LUNCH_TABS)[number];

/** `?tab=` value, falling back to the menu tab for anything unknown. */
export function resolveAdminLunchTab(requested: string | null): AdminLunchTab {
  return (ADMIN_LUNCH_TABS as readonly string[]).includes(requested ?? "") ? requested as AdminLunchTab : "menu";
}

/** Search params for a tab: the default tab keeps the URL clean. */
export function tabSearchParams(tab: string): Record<string, string> {
  return tab === "menu" ? {} : { tab };
}

// ---- Payments -------------------------------------------------------------------------

export function isUnpaid(status: string): boolean {
  return status.toUpperCase() === "UNPAID";
}

export function isFundPayment(status: string): boolean {
  return status.toUpperCase().includes("FUND");
}

export function isExternalPayment(status: string): boolean {
  return status.toUpperCase().includes("EXTERNAL");
}

export function countOrderPayments(orders: LunchOrder[]) {
  return {
    total: orders.length,
    fund: orders.filter((order) => isFundPayment(order.paymentStatus)).length,
    external: orders.filter((order) => isExternalPayment(order.paymentStatus)).length,
    unpaid: orders.filter((order) => isUnpaid(order.paymentStatus)).length,
  };
}

// ---- Fund adjustments -----------------------------------------------------------------

export function fundSuccessMessage(action: LunchFundAdjustmentAction): string {
  return action === "ADD_FUND" ? "Đã cộng tiền vào quỹ." : action === "REMOVE_FUND" ? "Đã trừ tiền khỏi quỹ." : action === "ADD_DEBT" ? "Đã ghi tăng công nợ." : "Đã ghi giảm công nợ.";
}

export function fundButtonVerb(action: LunchFundAdjustmentAction): string {
  return action === "ADD_FUND" ? "Cộng" : action === "REMOVE_FUND" ? "Trừ" : action === "ADD_DEBT" ? "Ghi nợ" : "Giảm nợ";
}

export function fundActionHint(action: LunchFundAdjustmentAction): string {
  return {
    ADD_FUND: "Cộng tiền đã nhận hoặc khoản được admin xác nhận vào quỹ.",
    REMOVE_FUND: "Chỉ trừ trong phạm vi số dư quỹ hiện có; không tạo số dư âm.",
    ADD_DEBT: "Ghi thêm công nợ thủ công, dùng cho các khoản cần đối soát ngoài đơn.",
    REMOVE_DEBT: "Giảm công nợ hiện có; số tiền không được vượt quá công nợ.",
  }[action];
}

export function fundAmountLabel(action: LunchFundAdjustmentAction): string {
  return action.includes("DEBT") ? "Số tiền công nợ" : "Số tiền điều chỉnh";
}

/** Error shown before sending a fund adjustment, or null when it can be sent. */
export function validateFundAdjustment(memberId: string, amount: number): string | null {
  if (!memberId) return "Vui lòng chọn thành viên.";
  if (!Number.isInteger(amount) || amount <= 0) return "Số tiền điều chỉnh phải là số nguyên dương.";
  return null;
}

// ---- Menu editor ----------------------------------------------------------------------

/** Error shown before importing/updating a menu, or null when it can be sent. */
export function validateMenuPayload(payload: ImportLunchMenuInput, menuTextValid: boolean): string | null {
  if (!payload.menuDate || !payload.cutoffAt || !payload.orderLabel || !payload.vendorName) {
    return "Vui lòng điền đủ ngày, tiêu đề, tên quán và giờ chốt.";
  }
  if (!Number.isInteger(payload.price) || payload.price <= 0) {
    return "Giá phần ăn phải là số nguyên dương.";
  }
  if (!menuTextValid) {
    return "Menu chưa đúng định dạng. Vui lòng kiểm tra phần xem trước.";
  }
  return null;
}

/** Raw text that re-creates the menu's dishes in the editor (regular, "+", single dishes). */
export function menuToRawText(menu: Pick<LunchMenu, "regularItems" | "specialItems">): string {
  return [
    ...menu.regularItems.map((item) => item.name),
    "+",
    ...menu.specialItems.map((item) => item.name),
  ].join("\n");
}

export function summaryButtonLabel(summarizing: boolean, summarized: boolean, hasSummary: boolean): string {
  if (summarizing) return "Đang tổng hợp...";
  if (!summarized) return "Chốt & tổng hợp";
  return hasSummary ? "Tải lại tổng hợp" : "Xem lại tổng hợp";
}

// ---- Notifications --------------------------------------------------------------------

export function notifyResultToast(result: LunchMenuNotificationResult): { level: "success" | "warning"; message: string } {
  if (result.emailFailedCount > 0) {
    return {
      level: "warning",
      message: `Đã tạo thông báo cho ${result.recipientCount} tài khoản; email đủ điều kiện ${result.emailEligibleCount}, gửi thành công ${result.emailSentCount}, thất bại thật ${result.emailFailedCount}, bỏ qua do tắt email ${result.emailSkippedCount}.`,
    };
  }
  if (result.emailSkippedCount === result.recipientCount) {
    return { level: "success", message: `Đã tạo thông báo trong ứng dụng cho ${result.recipientCount} tài khoản; chưa có tài khoản bật email.` };
  }
  if (result.emailSkippedCount > 0) {
    return {
      level: "success",
      message: `Đã tạo thông báo; email thành công ${result.emailSentCount}/${result.emailEligibleCount}. ${result.emailSkippedCount} tài khoản đang tắt email.`,
    };
  }
  return { level: "success", message: `Đã gửi thông báo và email tới ${result.emailSentCount} tài khoản đang bật email.` };
}
