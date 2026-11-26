import { afterEach, describe, expect, it, vi } from "vitest";
import { buildCsv, collectPages, csvDate, csvFileDate, csvMoney, csvTime, downloadCsv, escapeCsvCell, formatCsvNumber, type CsvColumn } from "./csv";

type Row = { name: string; amount: number; note?: string | null };
const columns: CsvColumn<Row>[] = [
  { header: "Tên", value: (row) => row.name },
  { header: "Số tiền", value: (row) => csvMoney(row.amount) },
  { header: "Ghi chú", value: (row) => row.note },
];

describe("buildCsv", () => {
  it("dùng dấu ; , xuống dòng CRLF và giữ tiếng Việt", () => {
    expect(buildCsv([{ name: "Ăn trưa", amount: 45000.4, note: null }], columns))
      .toBe("Tên;Số tiền;Ghi chú\r\nĂn trưa;45000;\r\n");
  });

  it("bọc ngoặc kép khi có dấu ngăn cách, ngoặc kép hoặc xuống dòng", () => {
    expect(escapeCsvCell('Cà phê "sữa"')).toBe('"Cà phê ""sữa"""');
    expect(escapeCsvCell("a;b")).toBe('"a;b"');
    expect(escapeCsvCell("dòng 1\ndòng 2")).toBe('"dòng 1\ndòng 2"');
    expect(escapeCsvCell("a,b")).toBe('"a,b"');
  });

  it("chặn công thức ở ô chữ nhưng không đổi số âm", () => {
    expect(escapeCsvCell("=SUM(A1:A2)")).toBe("'=SUM(A1:A2)");
    expect(escapeCsvCell("+84 90")).toBe("'+84 90");
    expect(escapeCsvCell("-giảm giá")).toBe("'-giảm giá");
    expect(escapeCsvCell("@cmd")).toBe("'@cmd");
    expect(escapeCsvCell('=HYPERLINK("x";"y")')).toBe(`"'=HYPERLINK(""x"";""y"")"`);
    expect(escapeCsvCell(-5)).toBe("-5");
  });

  it("số thập phân dùng dấu phẩy, tối đa 2 chữ số", () => {
    expect(formatCsvNumber(70.456)).toBe("70,46");
    expect(formatCsvNumber(12)).toBe("12");
    expect(formatCsvNumber(Number.NaN)).toBe("");
    expect(escapeCsvCell(70.5)).toBe('"70,5"');
    expect(escapeCsvCell(null)).toBe("");
  });
});

describe("ngày giờ", () => {
  it("định dạng dd/mm/yyyy không lệch múi giờ", () => {
    expect(csvDate("2026-01-05")).toBe("05/01/2026");
    expect(csvDate("2026-11-20T23:45:00")).toBe("20/11/2026");
    expect(csvTime("2026-11-20T08:05:00")).toBe("08:05");
    expect(csvDate("không phải ngày")).toBe("");
    expect(csvDate(null)).toBe("");
    expect(csvFileDate("2026-03-09")).toBe("20260309");
  });
});

describe("collectPages", () => {
  const pages = [[1, 2], [3, 4], [5]];
  const fetchPage = (page: number) => Promise.resolve({ content: pages[page] ?? [], last: page >= pages.length - 1 });

  it("đọc tới trang cuối", async () => {
    await expect(collectPages(fetchPage, { maxPages: 10 })).resolves.toEqual({ items: [1, 2, 3, 4, 5], truncated: false });
  });

  it("báo bị cắt khi chạm giới hạn trang", async () => {
    await expect(collectPages(fetchPage, { maxPages: 2 })).resolves.toEqual({ items: [1, 2, 3, 4], truncated: true });
  });

  it("dừng sớm khi stop trả về true", async () => {
    await expect(collectPages(fetchPage, { maxPages: 2, stop: (page) => page.includes(2) })).resolves.toEqual({ items: [1, 2], truncated: false });
  });
});

describe("downloadCsv", () => {
  afterEach(() => vi.restoreAllMocks());

  it("tạo file UTF-8 có BOM và đặt tên .csv", async () => {
    let blob: Blob | undefined;
    const createUrl = vi.fn((value: Blob) => { blob = value; return "blob:csv"; });
    Object.defineProperty(URL, "createObjectURL", { configurable: true, value: createUrl });
    Object.defineProperty(URL, "revokeObjectURL", { configurable: true, value: vi.fn() });
    let downloadName = "";
    vi.spyOn(HTMLAnchorElement.prototype, "click").mockImplementation(function (this: HTMLAnchorElement) { downloadName = this.download; });

    downloadCsv("giao-dich", [{ name: "Ăn", amount: 1 }], columns);

    expect(downloadName).toBe("giao-dich.csv");
    expect(blob?.type).toBe("text/csv;charset=utf-8");
    const buffer = await new Promise<ArrayBuffer>((resolve) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as ArrayBuffer);
      reader.readAsArrayBuffer(blob!);
    });
    const bytes = new Uint8Array(buffer);
    expect([...bytes.slice(0, 3)]).toEqual([0xef, 0xbb, 0xbf]);
    expect(new TextDecoder().decode(bytes.slice(3))).toBe("Tên;Số tiền;Ghi chú\r\nĂn;1;\r\n");
  });
});
