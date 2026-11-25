export type FieldErrors<K extends string> = Partial<Record<K, string>>;

export function hasErrors(errors: Record<string, string | undefined>) {
  return Object.values(errors).some(Boolean);
}

/** Parses a decimal typed with "," or "." as the decimal separator. Empty input returns null. */
export function parseDecimal(text: string): number | null {
  const value = text.trim().replace(",", ".");
  if (!value) return null;
  if (!/^\d+(\.\d+)?$/.test(value)) return Number.NaN;
  return Number(value);
}

/**
 * Parses a VND amount such as "50000", "50.000", "50,000" or "50k".
 * Returns NaN for text that is not an amount and null for empty input.
 */
export function parseMoney(text: string): number | null {
  const value = text.trim().toLowerCase().replace(/\s/g, "");
  if (!value) return null;
  const thousand = value.endsWith("k");
  const digits = thousand ? value.slice(0, -1) : value;
  if (thousand) {
    const base = Number(digits.replace(",", "."));
    return /^\d+([.,]\d+)?$/.test(digits) ? Math.round(base * 1000) : Number.NaN;
  }
  if (!/^\d{1,3}([.,]\d{3})*$|^\d+$/.test(digits)) return Number.NaN;
  return Number(digits.replace(/[.,]/g, ""));
}

export function validateTodo(input: { title: string; dueAt: string }, now: Date) {
  const errors: FieldErrors<"title" | "dueAt"> = {};
  const title = input.title.trim();
  if (!title) errors.title = "Nhập tên việc.";
  else if (title.length > 180) errors.title = "Tối đa 180 ký tự.";
  if (input.dueAt) {
    const due = new Date(input.dueAt);
    if (Number.isNaN(due.getTime())) errors.dueAt = "Hạn không hợp lệ.";
    else if (due.getTime() < now.getTime() - 60_000) errors.dueAt = "Hạn đã qua.";
  }
  return errors;
}

export function validateMeal(input: { foodId: string | null; amount: string; unit: "SERVING" | "GRAM"; servingSizeGrams?: number | null }) {
  const errors: FieldErrors<"food" | "amount"> = {};
  if (!input.foodId) errors.food = "Chọn một món.";
  const amount = parseDecimal(input.amount);
  if (amount === null) errors.amount = "Nhập lượng.";
  else if (!Number.isFinite(amount) || amount <= 0) errors.amount = "Lượng phải lớn hơn 0.";
  else if (input.unit === "SERVING" && amount > 50) errors.amount = "Tối đa 50 khẩu phần.";
  else if (input.unit === "GRAM" && amount > 5000) errors.amount = "Tối đa 5.000 g.";
  else if (input.unit === "GRAM" && !input.servingSizeGrams) errors.amount = "Món này chưa có khối lượng khẩu phần, hãy nhập theo khẩu phần.";
  return errors;
}

export function validateFinance(input: { amount: string; accountId: string; categoryId: string; note: string }) {
  const errors: FieldErrors<"amount" | "accountId" | "categoryId" | "note"> = {};
  const amount = parseMoney(input.amount);
  if (amount === null) errors.amount = "Nhập số tiền.";
  else if (!Number.isFinite(amount) || amount <= 0) errors.amount = "Số tiền không hợp lệ.";
  else if (amount > 1_000_000_000_000) errors.amount = "Số tiền quá lớn.";
  if (!input.accountId) errors.accountId = "Chọn tài khoản.";
  if (!input.categoryId) errors.categoryId = "Chọn danh mục.";
  if (input.note.trim().length > 1000) errors.note = "Tối đa 1.000 ký tự.";
  return errors;
}

export function validateBody(input: { weight: string; waist: string; recordDate: string }, today: string) {
  const errors: FieldErrors<"weight" | "waist" | "recordDate"> = {};
  const weight = parseDecimal(input.weight);
  if (weight === null) errors.weight = "Nhập cân nặng.";
  else if (!Number.isFinite(weight) || weight < 20 || weight > 400) errors.weight = "Cân nặng từ 20 đến 400 kg.";
  const waist = parseDecimal(input.waist);
  if (waist !== null && (!Number.isFinite(waist) || waist < 30 || waist > 250)) errors.waist = "Vòng eo từ 30 đến 250 cm.";
  if (!input.recordDate) errors.recordDate = "Chọn ngày.";
  else if (input.recordDate > today) errors.recordDate = "Không chọn ngày tương lai.";
  return errors;
}

export function validateJournal(input: { title: string; body: string }) {
  const errors: FieldErrors<"title" | "body"> = {};
  if (input.title.trim().length > 200) errors.title = "Tối đa 200 ký tự.";
  const body = input.body.trim();
  if (!body) errors.body = "Viết vài dòng trước khi lưu.";
  else if (body.length > 20000) errors.body = "Tối đa 20.000 ký tự.";
  return errors;
}
