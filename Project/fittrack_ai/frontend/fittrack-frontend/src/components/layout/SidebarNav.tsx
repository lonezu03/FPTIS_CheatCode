import { useRef, useState, type KeyboardEvent } from "react";
import { NavLink, useMatch, useNavigate } from "react-router-dom";
import { ChevronDown, Pin, PinOff, Search, X } from "lucide-react";
import { searchNav, type NavGroup, type NavItem } from "@/lib/navigation";
import type { NavPrefs } from "@/lib/navigation-prefs";

type SidebarNavProps = {
  groups: NavGroup[];
  activeGroupId: string | null;
  prefs: NavPrefs;
  isOpen: (id: string) => boolean;
  hasExtraOpen: boolean;
  onTogglePin: (to: string) => void;
  onToggleGroup: (id: string) => void;
  onCollapseAll: () => void;
  onNavigate?: () => void;
  label: string;
};

/**
 * Sidebar with a module filter, pinned shortcuts and collapsible groups so a long
 * module list stays scannable. Only the current module is expanded by default.
 */
export default function SidebarNav({ groups, activeGroupId, prefs, isOpen, hasExtraOpen, onTogglePin, onToggleGroup, onCollapseAll, onNavigate, label }: SidebarNavProps) {
  const navigate = useNavigate();
  const [query, setQuery] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const searching = query.trim().length > 0;
  const matches = searching ? searchNav(groups, query) : [];
  const allItems = groups.flatMap((group) => group.items);
  const pinnedItems = prefs.pinned.map((to) => allItems.find((item) => item.to === to)).filter((item): item is NavItem => !!item);
  const totalItems = allItems.length;

  const onSearchKey = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "Escape") {
      setQuery("");
    } else if (event.key === "Enter" && matches[0]) {
      event.preventDefault();
      navigate(matches[0].item.to);
      setQuery("");
      onNavigate?.();
    }
  };

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="px-3 pb-2">
        <label className="relative block">
          <span className="sr-only">Tìm chức năng</span>
          <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-emerald-50/40" aria-hidden="true" />
          <input
            ref={inputRef}
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={onSearchKey}
            placeholder={`Tìm trong ${totalItems} chức năng…`}
            className="h-10 w-full rounded-xl border border-white/10 bg-white/[0.06] pr-9 pl-9 text-sm text-white placeholder:text-emerald-50/40 outline-none transition focus:border-emerald-300/60 focus:bg-white/[0.09] [&::-webkit-search-cancel-button]:hidden"
          />
          {searching && (
            <button
              type="button"
              onClick={() => {
                setQuery("");
                inputRef.current?.focus();
              }}
              aria-label="Xóa từ khóa"
              className="absolute top-1/2 right-2 grid size-6 -translate-y-1/2 place-items-center rounded-md text-emerald-50/55 hover:bg-white/10 hover:text-white"
            >
              <X className="size-3.5" />
            </button>
          )}
        </label>
      </div>

      <nav className="min-h-0 flex-1 overflow-y-auto px-3 pb-4" aria-label={label}>
        {searching ? (
          <div className="pt-1">
            <p className="mb-1.5 px-3 text-[0.68rem] font-semibold tracking-[0.16em] text-emerald-50/35 uppercase" aria-live="polite">
              {matches.length ? `${matches.length} kết quả · Enter để mở` : "Không tìm thấy chức năng"}
            </p>
            <div className="space-y-1">
              {matches.map(({ item, group }) => (
                <SidebarLink
                  key={item.to}
                  item={item}
                  caption={group.label}
                  pinned={prefs.pinned.includes(item.to)}
                  onTogglePin={onTogglePin}
                  onClick={() => {
                    setQuery("");
                    onNavigate?.();
                  }}
                />
              ))}
            </div>
          </div>
        ) : (
          <>
            {pinnedItems.length > 0 && (
              <section className="mb-3">
                <p className="mb-1.5 px-3 text-[0.68rem] font-semibold tracking-[0.16em] text-amber-200/60 uppercase">Đã ghim</p>
                <div className="space-y-1">
                  {pinnedItems.map((item) => (
                    <SidebarLink key={item.to} item={item} pinned onTogglePin={onTogglePin} onClick={onNavigate} />
                  ))}
                </div>
              </section>
            )}

            <div className="mb-1 flex items-center justify-between px-3">
              <p className="text-[0.68rem] font-semibold tracking-[0.16em] text-emerald-50/35 uppercase">Module</p>
              {hasExtraOpen && (
                <button type="button" onClick={onCollapseAll} className="rounded-md px-1.5 py-0.5 text-[0.68rem] text-emerald-50/45 hover:bg-white/10 hover:text-white">
                  Thu gọn
                </button>
              )}
            </div>

            <div className="space-y-0.5">
              {groups.map((group) => {
                const GroupIcon = group.icon;
                const open = isOpen(group.id);
                const active = group.id === activeGroupId;
                const panelId = `${label === "Điều hướng chính" ? "nav" : "mnav"}-${group.id}`;
                return (
                  <section key={group.id}>
                    <button
                      type="button"
                      onClick={() => onToggleGroup(group.id)}
                      aria-expanded={open}
                      aria-controls={panelId}
                      className={[
                        "flex min-h-10 w-full items-center gap-3 rounded-xl px-3 text-left text-sm font-semibold transition",
                        active ? "text-white" : "text-emerald-50/70 hover:bg-white/[0.06] hover:text-white",
                      ].join(" ")}
                    >
                      <GroupIcon className={["size-4 shrink-0", active ? "text-emerald-300" : "text-emerald-50/45"].join(" ")} aria-hidden="true" />
                      <span className="min-w-0 flex-1 truncate">{group.label}</span>
                      <span className="rounded-full bg-white/[0.07] px-1.5 text-[0.65rem] font-medium text-emerald-50/50">{group.items.length}</span>
                      <ChevronDown className={["size-4 shrink-0 text-emerald-50/40 transition-transform", open ? "rotate-180" : ""].join(" ")} aria-hidden="true" />
                    </button>
                    {open && (
                      <div id={panelId} className="mt-0.5 mb-2 ml-[1.15rem] space-y-0.5 border-l border-white/10 pl-2">
                        {group.items.map((item) => (
                          <SidebarLink key={item.to} item={item} compact pinned={prefs.pinned.includes(item.to)} onTogglePin={onTogglePin} onClick={onNavigate} />
                        ))}
                      </div>
                    )}
                  </section>
                );
              })}
            </div>
          </>
        )}
      </nav>
    </div>
  );
}

function SidebarLink({
  item,
  caption,
  compact = false,
  pinned,
  onTogglePin,
  onClick,
}: {
  item: NavItem;
  caption?: string;
  compact?: boolean;
  pinned: boolean;
  onTogglePin: (to: string) => void;
  onClick?: () => void;
}) {
  const Icon = item.icon;
  const PinIcon = pinned ? PinOff : Pin;
  const active = !!useMatch({ path: item.to, end: true });
  return (
    <div className="group/link relative">
      <NavLink
        to={item.to}
        end
        onClick={onClick}
        className={({ isActive }) =>
          [
            "flex items-center gap-3 rounded-xl pr-9 pl-3 text-sm font-medium transition-all",
            compact ? "min-h-9 py-1.5" : "min-h-11 py-2",
            isActive
              ? "bg-white text-[#0c2821] shadow-sm"
              : item.highlight
                ? "bg-emerald-400/12 text-emerald-100 hover:bg-emerald-400/20 hover:text-white"
                : "text-emerald-50/62 hover:bg-white/[0.07] hover:text-white",
          ].join(" ")
        }
      >
        {({ isActive }) => (
          <>
            <span
              className={[
                "grid shrink-0 place-items-center rounded-lg transition-colors",
                compact ? "size-7" : "size-8",
                isActive ? "bg-emerald-100 text-emerald-800" : item.highlight ? "bg-emerald-400/15 text-emerald-300" : "bg-white/[0.05] text-emerald-50/65",
              ].join(" ")}
            >
              <Icon className="size-4" />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block truncate">{item.label}</span>
              {caption && <span className={["block truncate text-[0.68rem]", isActive ? "text-emerald-800/60" : "text-emerald-50/40"].join(" ")}>{caption}</span>}
            </span>
            {item.highlight && !isActive && <span className="size-1.5 rounded-full bg-amber-300" aria-hidden="true" />}
          </>
        )}
      </NavLink>
      <button
        type="button"
        onClick={() => onTogglePin(item.to)}
        aria-label={pinned ? `Bỏ ghim ${item.label}` : `Ghim ${item.label}`}
        title={pinned ? "Bỏ ghim" : "Ghim lên đầu menu"}
        className={[
          "absolute top-1/2 right-1.5 grid size-7 -translate-y-1/2 place-items-center rounded-lg transition",
          active ? "text-emerald-800/60 hover:bg-emerald-100 hover:text-emerald-900" : "text-emerald-50/50 hover:bg-white/15 hover:text-amber-200",
          "focus-visible:opacity-100",
          pinned ? "opacity-70" : "opacity-0 group-hover/link:opacity-100 [@media(hover:none)]:opacity-60",
        ].join(" ")}
      >
        <PinIcon className="size-3.5" />
      </button>
    </div>
  );
}
