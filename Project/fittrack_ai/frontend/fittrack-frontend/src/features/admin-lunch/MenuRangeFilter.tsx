import { AlertTriangle } from "lucide-react";

import type { LunchMenu } from "@/api/lunch.api";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { formatShortDate } from "@/lib/format";
import type { AdminLunchSelection } from "./useAdminLunchData";

/** Date range and the menu every tab works on. */
export default function MenuRangeFilter({ selection, menus, activeMenu, loading }: {
  selection: AdminLunchSelection;
  menus: LunchMenu[];
  activeMenu: LunchMenu | null;
  loading: boolean;
}) {
  const { fromDate, toDate } = selection;
  return (
    <>
      <Card>
        <CardContent className="grid gap-3 md:grid-cols-[1fr_1fr_minmax(220px,1.2fr)] md:items-end">
          <div className="space-y-1.5">
            <Label htmlFor="admin-lunch-from">Từ ngày</Label>
            <Input id="admin-lunch-from" type="date" value={fromDate} onChange={(event) => selection.setFromDate(event.target.value)} />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="admin-lunch-to">Đến ngày</Label>
            <Input id="admin-lunch-to" type="date" value={toDate} onChange={(event) => selection.setToDate(event.target.value)} />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="admin-active-menu">Menu đang thao tác</Label>
            <select
              id="admin-active-menu"
              value={activeMenu?.id ?? ""}
              onChange={(event) => selection.selectMenu(event.target.value)}
              disabled={loading || menus.length === 0}
              className="h-8 w-full rounded-lg border border-input bg-background px-2.5 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:opacity-50"
            >
              {menus.length === 0 ? (
                <option value="">Chưa có menu trong khoảng ngày</option>
              ) : (
                menus.map((menu) => (
                  <option key={menu.id} value={menu.id}>
                    {formatShortDate(menu.menuDate)} · {menu.orderLabel}
                  </option>
                ))
              )}
            </select>
          </div>
        </CardContent>
      </Card>

      {fromDate > toDate && (
        <Alert variant="destructive">
          <AlertTriangle />
          <AlertTitle>Khoảng ngày không hợp lệ</AlertTitle>
          <AlertDescription>“Từ ngày” phải nhỏ hơn hoặc bằng “Đến ngày”.</AlertDescription>
        </Alert>
      )}
    </>
  );
}
