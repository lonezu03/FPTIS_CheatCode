import { useMemo, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { ArrowLeft, Compass, LayoutDashboard, Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuthStore } from "@/store/auth.store";
import { searchNav, visibleNavGroups } from "@/lib/navigation";

/** Shown for any unknown address inside the app; suggests pages close to what was typed. */
export default function NotFoundPage() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const user = useAuthStore((state) => state.user);
  const groups = useMemo(() => visibleNavGroups(user, user?.role === "ADMIN"), [user]);
  // "/finanse/savings" → "finanse savings": the typo-tolerant search usually finds the page meant.
  const fromUrl = decodeURIComponent(pathname).replace(/[/_-]+/g, " ").trim();
  const [query, setQuery] = useState("");
  const term = query.trim() || fromUrl;
  const matches = term ? searchNav(groups, term).slice(0, 6) : [];

  return (
    <section className="mx-auto flex max-w-xl flex-col items-center py-10 text-center sm:py-16" aria-labelledby="not-found-title">
      <span className="grid size-16 place-items-center rounded-3xl bg-emerald-50 text-emerald-700" aria-hidden="true">
        <Compass className="size-8" />
      </span>
      <h1 id="not-found-title" className="mt-5 text-2xl font-bold tracking-tight sm:text-3xl">
        Không tìm thấy trang
      </h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Địa chỉ <code className="rounded bg-muted px-1.5 py-0.5 text-foreground">{pathname}</code> không có trong AnCai. Có thể đường dẫn đã đổi hoặc gõ nhầm.
      </p>

      <div className="mt-6 flex flex-wrap justify-center gap-2">
        <Button asChild>
          <Link to="/dashboard">
            <LayoutDashboard className="size-4" />
            Về trang Tổng quan
          </Link>
        </Button>
        <Button type="button" variant="outline" onClick={() => navigate(-1)}>
          <ArrowLeft className="size-4" />
          Quay lại
        </Button>
      </div>

      <div className="mt-8 w-full text-left">
        <label className="relative block">
          <span className="sr-only">Tìm chức năng</span>
          <Search className="pointer-events-none absolute top-1/2 left-3.5 size-4 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
          <input
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter" && matches[0]) navigate(matches[0].item.to);
            }}
            placeholder="Tìm chức năng, ví dụ: chi tiêu, cân nặng, đặt cơm"
            className="h-11 w-full rounded-2xl border border-border bg-card pr-3 pl-10 text-sm outline-none transition placeholder:text-muted-foreground focus:border-ring focus:ring-3 focus:ring-ring/20"
          />
        </label>
        <p className="mt-3 px-1 text-xs text-muted-foreground" aria-live="polite">
          {matches.length ? (query.trim() ? "Kết quả tìm" : "Có thể bạn đang tìm") : query.trim() ? "Không tìm thấy chức năng phù hợp" : ""}
        </p>
        {matches.length > 0 && (
          <ul className="mt-1.5 space-y-1">
            {matches.map(({ item, group }) => {
              const Icon = item.icon;
              return (
                <li key={item.to}>
                  <Link to={item.to} className="flex items-center gap-3 rounded-2xl px-3 py-2.5 transition hover:bg-muted">
                    <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-muted text-muted-foreground" aria-hidden="true">
                      <Icon className="size-4" />
                    </span>
                    <span className="min-w-0">
                      <span className="block truncate text-sm font-medium">{item.label}</span>
                      <span className="block truncate text-xs text-muted-foreground">{group.label}</span>
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </section>
  );
}
