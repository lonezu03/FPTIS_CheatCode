import { useRef, useState, type KeyboardEvent } from "react";
import { Link, NavLink, useLocation, useNavigate } from "react-router-dom";
import { CircleHelp, LogOut, Pin, PinOff, Search, Settings, X } from "lucide-react";
import { searchAll, type NavCommand, type NavGroup, type NavItem } from "@/lib/navigation";

type TwoPaneNavProps = {
  groups: NavGroup[];
  activeGroupId: string | null;
  pinned: string[];
  onTogglePin: (to: string) => void;
  displayName: string;
  initials: string;
  onHelp: () => void;
  onLogout: () => void;
  /** Called after a page is opened (closes the mobile sheet). */
  onNavigate?: () => void;
  label: string;
};

/**
 * Two-column navigation: a narrow rail of module groups and a panel listing the
 * pages of the selected group. Picking a group in the rail only switches the panel;
 * opening a page happens in the panel, so browsing modules never navigates by accident.
 */
export default function TwoPaneNav({ groups, activeGroupId, pinned, onTogglePin, displayName, initials, onHelp, onLogout, onNavigate, label }: TwoPaneNavProps) {
  const { pathname } = useLocation();
  // The panel follows the current page until the user picks another group; the pick
  // is forgotten on the next navigation so the panel always matches where you are.
  const [picked, setPicked] = useState<{ path: string; id: string } | null>(null);
  const selectedId = picked && picked.path === pathname ? picked.id : (activeGroupId ?? groups[0]?.id ?? null);
  const selected = groups.find((group) => group.id === selectedId) ?? groups[0];

  return (
    <div className="flex h-full min-h-0">
      <nav aria-label={`${label}: nhóm chức năng`} className="flex w-[4.5rem] shrink-0 flex-col items-center gap-2 border-r border-border/60 bg-muted/60 py-4">
        <Link to="/profile" onClick={onNavigate} className="relative mb-1 rounded-2xl outline-none focus-visible:ring-2 focus-visible:ring-ring" aria-label={`Hồ sơ của ${displayName}`} title={displayName}>
          <span className="grid size-11 place-items-center rounded-2xl bg-gradient-to-br from-emerald-300 to-emerald-600 text-sm font-bold text-white shadow-sm">{initials}</span>
          <span className="absolute -right-0.5 -bottom-0.5 size-3.5 rounded-full border-2 border-muted bg-emerald-500" aria-hidden="true" />
        </Link>
        <span className="my-1 h-px w-8 bg-border" aria-hidden="true" />

        <div className="flex min-h-0 w-full flex-1 flex-col items-center gap-1.5 overflow-y-auto px-2 [scrollbar-width:none]">
          {groups.map((group) => {
            const Icon = group.icon;
            const isSelected = group.id === selected?.id;
            const hasCurrent = group.id === activeGroupId;
            return (
              <button
                key={group.id}
                type="button"
                onClick={() => setPicked({ path: pathname, id: group.id })}
                aria-pressed={isSelected}
                aria-label={group.label}
                title={group.label}
                className={[
                  "relative grid size-12 shrink-0 place-items-center rounded-2xl transition",
                  isSelected ? "bg-card text-emerald-600 shadow-sm ring-1 ring-border/60" : "text-muted-foreground hover:bg-card/70 hover:text-foreground",
                ].join(" ")}
              >
                <Icon className="size-5" aria-hidden="true" />
                {hasCurrent && !isSelected && <span className="absolute top-2 right-2 size-1.5 rounded-full bg-emerald-500" aria-hidden="true" />}
              </button>
            );
          })}
        </div>

        <span className="my-1 h-px w-8 bg-border" aria-hidden="true" />
        <button type="button" onClick={onHelp} aria-label="Hướng dẫn sử dụng" title="Hướng dẫn sử dụng" className="grid size-11 place-items-center rounded-2xl text-muted-foreground transition hover:bg-card/70 hover:text-foreground">
          <CircleHelp className="size-5" />
        </button>
        <button type="button" onClick={onLogout} aria-label="Đăng xuất" title="Đăng xuất" className="grid size-11 place-items-center rounded-2xl text-muted-foreground transition hover:bg-red-50 hover:text-red-600">
          <LogOut className="size-5" />
        </button>
      </nav>

      {selected && <GroupPanel group={selected} groups={groups} pinned={pinned} onTogglePin={onTogglePin} onNavigate={onNavigate} onHelp={onHelp} onLogout={onLogout} label={label} />}
    </div>
  );
}

function GroupPanel({ group, groups, pinned, onTogglePin, onNavigate, onHelp, onLogout, label }: { group: NavGroup; groups: NavGroup[]; pinned: string[]; onTogglePin: (to: string) => void; onNavigate?: () => void; onHelp: () => void; onLogout: () => void; label: string }) {
  const navigate = useNavigate();
  const [query, setQuery] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const searching = query.trim().length > 0;
  // Pages and account actions (đăng xuất, đổi mật khẩu, hướng dẫn…) ranked together.
  const results = searching ? searchAll(groups, query) : [];
  const runCommand = (command: NavCommand) => {
    setQuery("");
    if (command.id === "help") onHelp();
    else if (command.id === "logout") onLogout();
    else if (command.to) {
      navigate(command.to);
      onNavigate?.();
    }
  };
  const allItems = groups.flatMap((entry) => entry.items);
  const pinnedItems = pinned.map((to) => allItems.find((item) => item.to === to)).filter((item): item is NavItem => !!item);

  const open = () => {
    setQuery("");
    onNavigate?.();
  };
  const onSearchKey = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "Escape") setQuery("");
    else if (event.key === "Enter" && results[0]) {
      event.preventDefault();
      const first = results[0];
      if (first.kind === "command") runCommand(first.command);
      else {
        navigate(first.item.to);
        open();
      }
    }
  };

  return (
    <div className="flex min-w-0 flex-1 flex-col bg-card">
      <div className="flex items-center justify-between gap-2 px-5 pt-5 pb-4">
        <h2 className="truncate text-2xl font-bold tracking-tight">{group.label}</h2>
        <Link to="/profile" onClick={onNavigate} aria-label="Cài đặt tài khoản" title="Cài đặt tài khoản" className="grid size-11 shrink-0 place-items-center rounded-full bg-muted text-foreground/80 transition hover:bg-muted/70 hover:text-foreground">
          <Settings className="size-5" />
        </Link>
      </div>

      <div className="px-4 pb-3">
        <label className="relative block">
          <span className="sr-only">Tìm chức năng</span>
          <Search className="pointer-events-none absolute top-1/2 left-3.5 size-4 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
          <input
            ref={inputRef}
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={onSearchKey}
            placeholder="Tìm kiếm"
            className="h-11 w-full rounded-2xl border border-border bg-card pr-9 pl-10 text-sm outline-none transition placeholder:text-muted-foreground focus:border-ring focus:ring-3 focus:ring-ring/40 [&::-webkit-search-cancel-button]:hidden"
          />
          {searching && (
            <button
              type="button"
              onClick={() => {
                setQuery("");
                inputRef.current?.focus();
              }}
              aria-label="Xóa từ khóa"
              className="absolute top-1/2 right-2 grid size-7 -translate-y-1/2 place-items-center rounded-lg text-muted-foreground hover:bg-muted hover:text-foreground"
            >
              <X className="size-3.5" />
            </button>
          )}
        </label>
      </div>

      <nav className="min-h-0 flex-1 overflow-y-auto px-3 pb-4" aria-label={`${label}: ${searching ? "kết quả tìm" : group.label}`}>
        {searching ? (
          <>
            <p className="px-3 pb-1.5 text-xs text-muted-foreground" aria-live="polite">
              {results.length ? `${results.length} kết quả · Enter để mở` : "Không tìm thấy chức năng. Thử từ khác hoặc nhấn Ctrl K để tìm cả dữ liệu."}
            </p>
            <ul className="space-y-1">
              {results.map((result) => {
                if (result.kind === "page") {
                  const { item, group: owner } = result;
                  return (
                    <li key={item.to}>
                      <PanelLink item={item} caption={owner.label} pinned={pinned.includes(item.to)} onTogglePin={onTogglePin} onClick={open} />
                    </li>
                  );
                }
                const { command } = result;
                const Icon = command.icon;
                return (
                  <li key={command.id}>
                    <button type="button" onClick={() => runCommand(command)} className="flex min-h-12 w-full items-center gap-3.5 rounded-2xl pr-10 pl-4 text-left text-[0.95rem] text-foreground/85 transition hover:bg-muted/60 hover:text-foreground">
                      <Icon className="size-5 shrink-0" aria-hidden="true" />
                      <span className="min-w-0 flex-1">
                        <span className="line-clamp-2 leading-snug">{command.label}</span>
                        <span className="block truncate text-xs text-muted-foreground">Thao tác</span>
                      </span>
                    </button>
                  </li>
                );
              })}
            </ul>
          </>
        ) : (
          <>
            <ul className="space-y-1">
              {group.items.map((item) => (
                <li key={item.to}>
                  <PanelLink item={item} pinned={pinned.includes(item.to)} onTogglePin={onTogglePin} onClick={open} />
                </li>
              ))}
            </ul>
            {pinnedItems.length > 0 && (
              <section className="mt-5 border-t border-border/70 pt-4">
                <p className="px-3 pb-1.5 text-xs font-medium text-muted-foreground">Đã ghim</p>
                <ul className="space-y-1">
                  {pinnedItems.map((item) => (
                    <li key={item.to}>
                      <PanelLink item={item} pinned onTogglePin={onTogglePin} onClick={open} />
                    </li>
                  ))}
                </ul>
              </section>
            )}
          </>
        )}
      </nav>
    </div>
  );
}

function PanelLink({ item, caption, pinned, onTogglePin, onClick }: { item: NavItem; caption?: string; pinned: boolean; onTogglePin: (to: string) => void; onClick?: () => void }) {
  const Icon = item.icon;
  const PinIcon = pinned ? PinOff : Pin;
  return (
    <div className="group/link relative">
      <NavLink
        to={item.to}
        end
        onClick={onClick}
        className={({ isActive }) =>
          [
            "flex min-h-12 items-center gap-3.5 rounded-2xl pr-10 pl-4 text-[0.95rem] transition",
            isActive ? "bg-muted font-semibold text-foreground" : "text-foreground/85 hover:bg-muted/60 hover:text-foreground",
          ].join(" ")
        }
      >
        <Icon className="size-5 shrink-0" aria-hidden="true" />
        <span className="min-w-0 flex-1">
          <span className="line-clamp-2 leading-snug">{item.label}</span>
          {caption && <span className="block truncate text-xs text-muted-foreground">{caption}</span>}
        </span>
        {item.highlight && <span className="size-1.5 shrink-0 rounded-full bg-amber-400" aria-hidden="true" />}
      </NavLink>
      <button
        type="button"
        onClick={() => onTogglePin(item.to)}
        aria-label={pinned ? `Bỏ ghim ${item.label}` : `Ghim ${item.label}`}
        title={pinned ? "Bỏ ghim" : "Ghim"}
        className={[
          "absolute top-1/2 right-2 grid size-7 -translate-y-1/2 place-items-center rounded-lg text-muted-foreground transition hover:bg-card hover:text-amber-600 focus-visible:opacity-100",
          pinned ? "opacity-70" : "opacity-0 group-hover/link:opacity-100 [@media(hover:none)]:opacity-50",
        ].join(" ")}
      >
        <PinIcon className="size-3.5" />
      </button>
    </div>
  );
}
