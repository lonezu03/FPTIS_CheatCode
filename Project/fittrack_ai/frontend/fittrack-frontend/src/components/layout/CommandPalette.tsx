import { useEffect, useMemo, useRef, useState, type ElementType, type KeyboardEvent } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { BookHeart, Carrot, CornerDownLeft, Dumbbell, LoaderCircle, Pin, ReceiptText, Search } from "lucide-react";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { searchAll, type NavCommandId, type NavGroup, type SearchResult } from "@/lib/navigation";
import { getFinanceTransactions } from "@/api/finance.api";
import { getJournalEntries } from "@/api/journal.api";
import { getFoodsManagementPageApi } from "@/api/food.api";
import { getExercisesPageApi } from "@/api/exercise.api";

type CommandPaletteProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  groups: NavGroup[];
  pinned: string[];
  /** Handlers for commands that are not pages; commands without a handler are hidden. */
  onCommand?: Partial<Record<NavCommandId, () => void>>;
};

type Entry = { key: string; label: string; caption: string; icon: ElementType; to?: string; run?: () => void; pinned?: boolean };

/** Ctrl/⌘ + K: jump to a module, or find records (transactions, journal, foods, exercises) by keyword. */
export default function CommandPalette({ open, onOpenChange, groups, pinned, onCommand }: CommandPaletteProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="top-[12vh] translate-y-0 gap-0 overflow-hidden p-0 sm:max-w-xl sm:p-0" showCloseButton={false}>
        <DialogTitle className="sr-only">Tìm nhanh</DialogTitle>
        <DialogDescription className="sr-only">Gõ tên chức năng hoặc nội dung cần tìm, dùng phím mũi tên để chọn và Enter để mở.</DialogDescription>
        {/* Mounted only while open, so the query and selection start fresh every time. */}
        <PaletteBody groups={groups} pinned={pinned} onCommand={onCommand} onClose={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

const money = new Intl.NumberFormat("vi-VN");
const shortDate = (iso: string) => (iso ? iso.slice(0, 10).split("-").reverse().join("/") : "");
const withQuery = (path: string, query: string) => `${path}?q=${encodeURIComponent(query)}`;

/** Record search runs only for modules the user can open; each source fails on its own. */
function useDataSearch(query: string, groups: NavGroup[]) {
  const [debounced, setDebounced] = useState("");
  useEffect(() => {
    const timer = window.setTimeout(() => setDebounced(query.trim()), 300);
    return () => window.clearTimeout(timer);
  }, [query]);

  const routes = useMemo(() => new Set(groups.flatMap((group) => group.items.map((item) => item.to))), [groups]);
  const sources = ["/finance", "/journal", "/foods", "/exercises"].filter((route) => routes.has(route));

  const result = useQuery({
    queryKey: ["palette-search", debounced, sources],
    enabled: debounced.length >= 2 && sources.length > 0,
    staleTime: 30_000,
    retry: false,
    queryFn: async (): Promise<Entry[]> => {
      const q = debounced;
      const tasks: Promise<Entry[]>[] = [];
      if (sources.includes("/finance")) {
        tasks.push(
          getFinanceTransactions({ q, page: 0, size: 4 }).then((page) =>
            page.content.map((tx) => ({
              key: `tx-${tx.id}`,
              label: tx.merchant || tx.note || tx.categoryName || "Giao dịch",
              caption: `${tx.type === "INCOME" ? "Thu" : tx.type === "EXPENSE" ? "Chi" : "Chuyển"} ${money.format(tx.amount)} ₫ · ${shortDate(tx.occurredAt)}`,
              icon: ReceiptText,
              to: `${withQuery("/finance", q)}&month=${tx.occurredAt.slice(0, 7)}`,
            })),
          ),
        );
      }
      if (sources.includes("/journal")) {
        tasks.push(
          getJournalEntries({ q, page: 0, size: 4 }).then((page) =>
            page.content.map((entry) => ({
              key: `journal-${entry.id}`,
              label: entry.title || entry.body.slice(0, 70) || "Trang nhật ký",
              caption: `Nhật ký · ${shortDate(entry.entryDate)}`,
              icon: BookHeart,
              to: withQuery("/journal", q),
            })),
          ),
        );
      }
      if (sources.includes("/foods")) {
        tasks.push(
          getFoodsManagementPageApi(q, false, 0, 4).then((page) =>
            page.content.map((food) => ({
              key: `food-${food.id}`,
              label: food.name,
              caption: `Thực phẩm · ${Math.round(food.calories)} kcal`,
              icon: Carrot,
              to: withQuery("/foods", q),
            })),
          ),
        );
      }
      if (sources.includes("/exercises")) {
        tasks.push(
          getExercisesPageApi(q, false, 0, 4).then((page) =>
            page.content.map((exercise) => ({ key: `exercise-${exercise.id}`, label: exercise.name, caption: "Bài tập", icon: Dumbbell, to: withQuery("/exercises", q) })),
          ),
        );
      }
      // A locked journal or a module error must not hide results from the other sources.
      const settled = await Promise.allSettled(tasks);
      return settled.flatMap((entry) => (entry.status === "fulfilled" ? entry.value : []));
    },
  });

  const active = debounced.length >= 2 && sources.length > 0;
  return { entries: active ? (result.data ?? []) : [], loading: active && (result.isFetching || debounced !== query.trim()) };
}

function PaletteBody({ groups, pinned, onCommand, onClose }: { groups: NavGroup[]; pinned: string[]; onCommand?: CommandPaletteProps["onCommand"]; onClose: () => void }) {
  const navigate = useNavigate();
  const [query, setQuery] = useState("");
  const [cursor, setCursor] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);

  const navEntries = useMemo<Entry[]>(() => {
    const found = searchAll(groups, query);
    const isPage = (to: string) => (result: SearchResult) => result.kind === "page" && result.item.to === to;
    const ordered = query.trim()
      ? found
      : [
          // Without a query, pinned shortcuts come first, then everything in menu order.
          ...pinned.map((to) => found.find(isPage(to))).filter((result): result is SearchResult => !!result),
          ...found.filter((result) => result.kind !== "page" || !pinned.includes(result.item.to)),
        ];
    return ordered.flatMap((result): Entry[] => {
      if (result.kind === "page") {
        const { item, group } = result;
        return [{ key: item.to, label: item.label, caption: group.label, icon: item.icon, to: item.to, pinned: pinned.includes(item.to) }];
      }
      const { command } = result;
      const run = onCommand?.[command.id];
      if (!run && !command.to) return [];
      return [{ key: `cmd-${command.id}`, label: command.label, caption: "Thao tác", icon: command.icon, to: run ? undefined : command.to, run }];
    });
  }, [groups, pinned, query, onCommand]);

  const data = useDataSearch(query, groups);
  const entries = [...navEntries, ...data.entries];
  const safeCursor = Math.min(cursor, Math.max(0, entries.length - 1));

  useEffect(() => {
    listRef.current?.querySelector<HTMLElement>(`[data-index="${safeCursor}"]`)?.scrollIntoView({ block: "nearest" });
  }, [safeCursor]);

  const go = (entry: Entry | undefined) => {
    if (!entry) return;
    onClose();
    if (entry.run) entry.run();
    else if (entry.to) navigate(entry.to);
  };

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      setCursor(Math.min(entries.length - 1, safeCursor + 1));
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      setCursor(Math.max(0, safeCursor - 1));
    } else if (event.key === "Enter") {
      event.preventDefault();
      go(entries[safeCursor]);
    }
  };

  const renderEntry = (entry: Entry, index: number) => {
    const Icon = entry.icon;
    const selected = index === safeCursor;
    return (
      <button
        type="button"
        key={entry.key}
        id={`cmd-${index}`}
        data-index={index}
        role="option"
        tabIndex={-1}
        aria-selected={selected}
        onMouseMove={() => setCursor(index)}
        onClick={() => go(entry)}
        className={["flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-colors", selected ? "bg-emerald-50 text-emerald-950" : "text-foreground"].join(" ")}
      >
        <span className={["grid size-8 shrink-0 place-items-center rounded-lg", selected ? "bg-emerald-100 text-emerald-800" : "bg-muted text-muted-foreground"].join(" ")}>
          <Icon className="size-4" />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-sm font-medium">{entry.label}</span>
          <span className="block truncate text-xs text-muted-foreground">{entry.caption}</span>
        </span>
        {entry.pinned && <Pin className="size-3.5 text-amber-500" aria-label="Đã ghim" />}
        {selected && <CornerDownLeft className="size-4 text-emerald-700" aria-hidden="true" />}
      </button>
    );
  };

  const searching = query.trim().length >= 2;
  return (
    <>
      <div className="flex items-center gap-3 border-b px-4">
        <Search className="size-4 shrink-0 text-muted-foreground" aria-hidden="true" />
        <input
          autoFocus
          value={query}
          onChange={(event) => {
            setQuery(event.target.value);
            setCursor(0);
          }}
          onKeyDown={onKeyDown}
          placeholder="Tìm chức năng hoặc dữ liệu (giao dịch, nhật ký, món ăn…)"
          aria-label="Tìm nhanh"
          role="combobox"
          aria-expanded="true"
          aria-controls="command-palette-list"
          aria-activedescendant={entries[safeCursor] ? `cmd-${safeCursor}` : undefined}
          className="h-14 min-w-0 flex-1 bg-transparent text-base outline-none placeholder:text-muted-foreground"
        />
        {data.loading && <LoaderCircle className="size-4 shrink-0 animate-spin text-muted-foreground" aria-label="Đang tìm" />}
        <kbd className="hidden rounded-md border bg-muted px-1.5 py-0.5 text-[0.65rem] text-muted-foreground sm:inline">Esc</kbd>
      </div>
      <div ref={listRef} id="command-palette-list" role="listbox" aria-label="Kết quả" className="max-h-[55vh] overflow-y-auto p-2">
        {navEntries.length > 0 && searching && <p className="px-3 pt-1 pb-1 text-[0.7rem] font-medium text-muted-foreground">Chức năng</p>}
        {navEntries.map((entry, index) => renderEntry(entry, index))}
        {data.entries.length > 0 && <p className="px-3 pt-3 pb-1 text-[0.7rem] font-medium text-muted-foreground">Dữ liệu</p>}
        {data.entries.map((entry, index) => renderEntry(entry, navEntries.length + index))}
        {entries.length === 0 && !data.loading && (
          <p className="px-3 py-8 text-center text-sm text-muted-foreground">
            Không tìm thấy “{query}”. Thử từ khác, ví dụ: chi tiêu, cân nặng, lịch, đặt cơm.
          </p>
        )}
      </div>
      <div className="flex items-center gap-4 border-t bg-muted/40 px-4 py-2 text-[0.7rem] text-muted-foreground">
        <span>↑ ↓ chọn</span>
        <span>Enter mở</span>
        <span className="ml-auto">Ctrl K mở nhanh ở mọi trang</span>
      </div>
    </>
  );
}
