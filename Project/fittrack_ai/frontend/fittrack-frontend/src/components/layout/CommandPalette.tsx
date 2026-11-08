import { useEffect, useMemo, useRef, useState, type KeyboardEvent } from "react";
import { useNavigate } from "react-router-dom";
import { CornerDownLeft, Pin, Search } from "lucide-react";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/components/ui/dialog";
import { searchNav, type NavGroup, type NavMatch } from "@/lib/navigation";

type CommandPaletteProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  groups: NavGroup[];
  pinned: string[];
};

/** Ctrl/⌘ + K quick switcher: type part of a module name (accents optional), arrow keys, Enter. */
export default function CommandPalette({ open, onOpenChange, groups, pinned }: CommandPaletteProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="top-[12vh] translate-y-0 gap-0 overflow-hidden p-0 sm:max-w-xl sm:p-0" showCloseButton={false}>
        <DialogTitle className="sr-only">Tìm chức năng</DialogTitle>
        <DialogDescription className="sr-only">Gõ tên chức năng, dùng phím mũi tên để chọn và Enter để mở.</DialogDescription>
        {/* Mounted only while open, so the query and selection start fresh every time. */}
        <PaletteBody groups={groups} pinned={pinned} onClose={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

function PaletteBody({ groups, pinned, onClose }: { groups: NavGroup[]; pinned: string[]; onClose: () => void }) {
  const navigate = useNavigate();
  const [query, setQuery] = useState("");
  const [cursor, setCursor] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);

  const results = useMemo<NavMatch[]>(() => {
    const found = searchNav(groups, query);
    if (query.trim()) return found;
    // Without a query, pinned shortcuts come first, then everything in menu order.
    const pinnedFirst = pinned.map((to) => found.find((match) => match.item.to === to)).filter((match): match is NavMatch => !!match);
    return [...pinnedFirst, ...found.filter((match) => !pinned.includes(match.item.to))];
  }, [groups, pinned, query]);

  useEffect(() => {
    listRef.current?.querySelector<HTMLElement>(`[data-index="${cursor}"]`)?.scrollIntoView({ block: "nearest" });
  }, [cursor]);

  const go = (match: NavMatch | undefined) => {
    if (!match) return;
    onClose();
    navigate(match.item.to);
  };

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      setCursor((value) => Math.min(results.length - 1, value + 1));
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      setCursor((value) => Math.max(0, value - 1));
    } else if (event.key === "Enter") {
      event.preventDefault();
      go(results[cursor]);
    }
  };

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
            placeholder="Tìm chức năng… (vd: tiet kiem, com, giao an)"
            aria-label="Tìm chức năng"
            role="combobox"
            aria-expanded="true"
            aria-controls="command-palette-list"
            aria-activedescendant={results[cursor] ? `cmd-${cursor}` : undefined}
            className="h-14 min-w-0 flex-1 bg-transparent text-base outline-none placeholder:text-muted-foreground/75"
          />
          <kbd className="hidden rounded-md border bg-muted px-1.5 py-0.5 text-[0.65rem] text-muted-foreground sm:inline">Esc</kbd>
        </div>
        <div ref={listRef} id="command-palette-list" role="listbox" aria-label="Kết quả" className="max-h-[55vh] overflow-y-auto p-2">
          {results.length === 0 ? (
            <p className="px-3 py-8 text-center text-sm text-muted-foreground">Không có chức năng phù hợp với “{query}”.</p>
          ) : (
            results.map((match, index) => {
              const Icon = match.item.icon;
              const selected = index === cursor;
              return (
                <button
                  type="button"
                  key={match.item.to}
                  id={`cmd-${index}`}
                  data-index={index}
                  role="option"
                  aria-selected={selected}
                  onMouseMove={() => setCursor(index)}
                  onClick={() => go(match)}
                  className={[
                    "flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-colors",
                    selected ? "bg-emerald-50 text-emerald-950" : "text-foreground",
                  ].join(" ")}
                >
                  <span className={["grid size-8 shrink-0 place-items-center rounded-lg", selected ? "bg-emerald-100 text-emerald-800" : "bg-muted text-muted-foreground"].join(" ")}>
                    <Icon className="size-4" />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-medium">{match.item.label}</span>
                    <span className="block truncate text-xs text-muted-foreground">{match.group.label}</span>
                  </span>
                  {pinned.includes(match.item.to) && <Pin className="size-3.5 text-amber-500" aria-label="Đã ghim" />}
                  {selected && <CornerDownLeft className="size-4 text-emerald-700" aria-hidden="true" />}
                </button>
              );
            })
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
