import axios from "axios";

const currencyFormatter = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
  maximumFractionDigits: 0,
});

const dateFormatter = new Intl.DateTimeFormat("vi-VN", {
  weekday: "long",
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
});

const shortDateFormatter = new Intl.DateTimeFormat("vi-VN", {
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
});

const dateTimeFormatter = new Intl.DateTimeFormat("vi-VN", {
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
});

export function formatCurrency(value: number | null | undefined): string {
  return currencyFormatter.format(Number.isFinite(value) ? (value ?? 0) : 0);
}

export function formatDate(value: string | Date): string {
  const date = parseDate(value);
  return date ? dateFormatter.format(date) : "—";
}

export function formatShortDate(value: string | Date): string {
  const date = parseDate(value);
  return date ? shortDateFormatter.format(date) : "—";
}

export function formatDateTime(value: string | Date): string {
  const date = parseDate(value);
  return date ? dateTimeFormatter.format(date) : "—";
}

export function toLocalDateInput(date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function toLocalDateTimeInput(date = new Date()): string {
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${toLocalDateInput(date)}T${hours}:${minutes}`;
}

export function getDefaultLunchCutoff(date = new Date()): string {
  const cutoff = new Date(date);
  cutoff.setHours(10, 30, 0, 0);

  if (date.getTime() >= cutoff.getTime()) {
    cutoff.setDate(cutoff.getDate() + 1);
  }

  return toLocalDateTimeInput(cutoff);
}

export function getApiErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError<{ message?: string }>(error)) {
    return error.response?.data?.message?.trim() || fallback;
  }

  if (error instanceof Error && error.message.trim()) {
    return error.message;
  }

  return fallback;
}

export type ParsedLunchMenu = {
  regularItems: string[];
  specialItems: string[];
  errors: string[];
  isValid: boolean;
};

export function parseLunchMenu(rawMenuText: string): ParsedLunchMenu {
  const lines = rawMenuText
    .split(/\r?\n/)
    .map((line) => line.trim().replace(/\s+/g, " "))
    .filter(Boolean);

  const separators = lines.reduce<number[]>((indexes, line, index) => {
    if (line === "+") {
      indexes.push(index);
    }
    return indexes;
  }, []);

  const errors: string[] = [];

  if (separators.length > 1) {
    errors.push('Menu chỉ được có một dòng phân cách "+".');
  }

  const separatorIndex = separators[0] ?? lines.length;
  const regularSource = lines.slice(0, separatorIndex).filter((line) => line !== "+");
  const specialSource =
    separators.length > 0
      ? lines.slice(separatorIndex + 1).filter((line) => line !== "+")
      : [];
  const seen = new Set<string>();
  const duplicateNames = new Set<string>();

  const deduplicate = (items: string[]) =>
    items.filter((item) => {
      const key = item.toLocaleLowerCase("vi-VN");
      if (seen.has(key)) {
        duplicateNames.add(item);
        return false;
      }
      seen.add(key);
      return true;
    });

  const regularItems = deduplicate(regularSource);
  const specialItems = deduplicate(specialSource);

  if (regularItems.length === 1) {
    errors.push("Nhóm cơm phần cần ít nhất 2 món để người dùng chọn.");
  }

  if (regularItems.length === 0 && specialItems.length === 0) {
    errors.push("Menu cần có ít nhất một món ăn.");
  }

  if (separators.length > 0 && specialItems.length === 0) {
    errors.push('Thêm ít nhất 1 món đơn ở dưới dấu "+".');
  }

  if (duplicateNames.size > 0) {
    errors.push(`Tên món bị trùng: ${[...duplicateNames].join(", ")}.`);
  }

  const longNames = [...regularItems, ...specialItems].filter((item) => item.length > 255);
  if (longNames.length > 0) {
    errors.push(`Tên món không được dài quá 255 ký tự: ${longNames.join(", ")}.`);
  }

  return {
    regularItems,
    specialItems,
    errors,
    isValid: errors.length === 0,
  };
}

export function getCutoffDistance(cutoffAt: string, now = Date.now()): {
  closed: boolean;
  label: string;
} {
  const cutoff = new Date(cutoffAt).getTime();

  if (!Number.isFinite(cutoff)) {
    return { closed: false, label: "Chưa xác định giờ chốt" };
  }

  const distance = cutoff - now;

  if (distance <= 0) {
    return { closed: true, label: "Đã qua giờ chốt" };
  }

  const totalMinutes = Math.ceil(distance / 60_000);
  const days = Math.floor(totalMinutes / 1_440);
  const hours = Math.floor((totalMinutes % 1_440) / 60);
  const minutes = totalMinutes % 60;

  if (days > 0) {
    return { closed: false, label: `Còn ${days} ngày ${hours} giờ` };
  }

  if (hours > 0) {
    return { closed: false, label: `Còn ${hours} giờ ${minutes} phút` };
  }

  return { closed: false, label: `Còn ${minutes} phút` };
}

function parseDate(value: string | Date): Date | null {
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }

  const dateOnlyMatch = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  const date = dateOnlyMatch
    ? new Date(Number(dateOnlyMatch[1]), Number(dateOnlyMatch[2]) - 1, Number(dateOnlyMatch[3]))
    : new Date(value);

  return Number.isNaN(date.getTime()) ? null : date;
}
