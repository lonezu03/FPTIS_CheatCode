import { useEffect, useRef } from "react";
import { NavLink, useLocation } from "react-router-dom";
import type { NavGroup } from "@/lib/navigation";

/** Sibling pages of the current module, so related screens are one click apart. */
export default function ModuleTabs({ group }: { group: NavGroup }) {
  const scroller = useRef<HTMLElement>(null);
  const { pathname } = useLocation();

  // On narrow screens keep the current tab visible inside the horizontal strip.
  useEffect(() => {
    const strip = scroller.current;
    const current = strip?.querySelector<HTMLElement>('[aria-current="page"]');
    if (!strip || !current) return;
    strip.scrollLeft = current.offsetLeft - (strip.clientWidth - current.offsetWidth) / 2;
  }, [pathname]);

  if (!group.tabs || group.items.length < 2) return null;
  return (
    <nav ref={scroller} aria-label={`Các trang trong ${group.label}`} className="-mx-4 mb-5 overflow-x-auto px-4 [scrollbar-width:none] sm:-mx-6 sm:px-6 lg:mx-0 lg:px-0">
      <div className="relative flex w-max min-w-full gap-1 rounded-2xl border border-border/70 bg-card p-1 shadow-[0_1px_2px_rgba(15,43,35,0.04)] lg:w-auto">
        {group.items.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              end
              className={({ isActive }) =>
                [
                  "flex min-h-9 shrink-0 items-center gap-2 rounded-xl px-3 text-sm font-medium whitespace-nowrap transition-colors",
                  isActive ? "bg-[#0c2821] text-white shadow-sm" : "text-muted-foreground hover:bg-muted hover:text-foreground",
                ].join(" ")
              }
            >
              <Icon className="size-4" aria-hidden="true" />
              {item.label}
            </NavLink>
          );
        })}
      </div>
    </nav>
  );
}
