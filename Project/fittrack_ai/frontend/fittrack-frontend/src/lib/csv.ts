/**
 * Client-side CSV export shared by every module.
 *
 * Format (one convention for the whole app, tuned for Excel on Vietnamese Windows):
 * - UTF-8 with BOM so Excel shows Vietnamese correctly;
 * - `;` as the column separator and `,` as the decimal mark (vi-VN list/decimal separators);
 * - dates dd/mm/yyyy, money and counts as plain integers (no thousands separator);
 * - CRLF line endings;
 * - text cells starting with =, +, -, @, tab or CR get a leading apostrophe so a
 *   spreadsheet never runs them as a formula (CSV injection).
 */

export type CsvValue = string | number | null | undefined;

export type CsvColumn<T> = {
  header: string;
  value: (row: T) => CsvValue;
};

export const CSV_DELIMITER = ";";
const FORMULA_PREFIX = /^[=+\-@\t\r]/;

/** Formats a number: integers as-is, decimals with up to 2 digits and a comma. */
export function formatCsvNumber(value: number, maxDecimals = 2): string {
  if (!Number.isFinite(value)) return "";
  const factor = 10 ** maxDecimals;
  const rounded = Math.round(value * factor) / factor;
  return String(rounded).replace(".", ",");
}

/** Money as a plain integer string (VND has no minor unit). */
export function csvMoney(value: number | null | undefined): number | null {
  return value == null || !Number.isFinite(value) ? null : Math.round(value);
}

function cellText(value: CsvValue): string {
  if (value == null) return "";
  if (typeof value === "number") return formatCsvNumber(value);
  return FORMULA_PREFIX.test(value) ? `'${value}` : value;
}

/** Quotes a cell when it contains the separator, a quote or a line break. */
export function escapeCsvCell(value: CsvValue): string {
  const text = cellText(value);
  return /[;",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

export function buildCsv<T>(rows: readonly T[], columns: readonly CsvColumn<T>[]): string {
  const lines = [
    columns.map((column) => escapeCsvCell(column.header)).join(CSV_DELIMITER),
    ...rows.map((row) => columns.map((column) => escapeCsvCell(column.value(row))).join(CSV_DELIMITER)),
  ];
  return `${lines.join("\r\n")}\r\n`;
}

/** Builds the CSV and lets the browser save it. */
export function downloadCsv<T>(filename: string, rows: readonly T[], columns: readonly CsvColumn<T>[]): void {
  const blob = new Blob(["﻿", buildCsv(rows, columns)], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename.endsWith(".csv") ? filename : `${filename}.csv`;
  link.style.display = "none";
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 1_000);
}

const pad = (value: number) => String(value).padStart(2, "0");

function toDate(value: string | Date): Date | null {
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  const dateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  const date = dateOnly
    ? new Date(Number(dateOnly[1]), Number(dateOnly[2]) - 1, Number(dateOnly[3]))
    : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

/** dd/mm/yyyy; date-only strings are read as local dates (no timezone shift). */
export function csvDate(value: string | Date | null | undefined): string {
  const date = value == null ? null : toDate(value);
  return date ? `${pad(date.getDate())}/${pad(date.getMonth() + 1)}/${date.getFullYear()}` : "";
}

/** HH:mm in local time. */
export function csvTime(value: string | Date | null | undefined): string {
  const date = value == null ? null : toDate(value);
  return date ? `${pad(date.getHours())}:${pad(date.getMinutes())}` : "";
}

/** yyyymmdd for file names. */
export function csvFileDate(value: string | Date = new Date()): string {
  const date = toDate(value) ?? new Date();
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}`;
}

export type PageSlice<T> = { content: T[]; last: boolean };

/**
 * Reads pages until the last one, `stop` says enough, or `maxPages` is reached.
 * `truncated` is true only when more data was left unread because of the cap.
 */
export async function collectPages<T>(
  fetchPage: (page: number) => Promise<PageSlice<T>>,
  { maxPages, stop }: { maxPages: number; stop?: (page: T[]) => boolean },
): Promise<{ items: T[]; truncated: boolean }> {
  const items: T[] = [];
  for (let page = 0; page < maxPages; page += 1) {
    const result = await fetchPage(page);
    items.push(...result.content);
    if (result.last || result.content.length === 0 || stop?.(result.content)) {
      return { items, truncated: false };
    }
  }
  return { items, truncated: true };
}
