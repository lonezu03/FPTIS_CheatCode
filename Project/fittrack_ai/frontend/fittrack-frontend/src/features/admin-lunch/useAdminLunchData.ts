import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import {
  getAdminLunchMembers,
  getAdminLunchMenus,
  getAdminLunchOrders,
  lunchKeys,
  type LunchMenu,
  type LunchSummary,
} from "@/api/lunch.api";
import { toLocalDateInput } from "@/lib/format";

/** Date range, chosen menu and the summary created for it. */
export function useAdminLunchSelection() {
  const today = toLocalDateInput();
  const [fromDate, setFromDate] = useState(today);
  const [toDate, setToDate] = useState(today);
  const [selectedMenuId, setSelectedMenuId] = useState("");
  const [summaryResult, setSummaryResult] = useState<{ menuId: string; summary: LunchSummary } | null>(null);

  return {
    fromDate,
    toDate,
    selectedMenuId,
    summaryResult,
    setFromDate,
    setToDate,
    setSelectedMenuId,
    setSummaryResult,
    /** Jump to a saved menu: narrow the range to its day and select it. */
    showMenu: (menu: LunchMenu) => {
      setFromDate(menu.menuDate);
      setToDate(menu.menuDate);
      setSelectedMenuId(menu.id);
    },
    selectMenu: (menuId: string) => {
      setSelectedMenuId(menuId);
      setSummaryResult(null);
    },
  };
}

export type AdminLunchSelection = ReturnType<typeof useAdminLunchSelection>;

/** Menus in range (auto refresh), orders of the active menu and members' funds. */
export function useAdminLunchData(selection: AdminLunchSelection) {
  const { fromDate, toDate, selectedMenuId, summaryResult } = selection;
  const menusQuery = useQuery({
    queryKey: lunchKeys.adminMenus(fromDate, toDate),
    queryFn: () => getAdminLunchMenus(fromDate, toDate),
    enabled: fromDate <= toDate,
    refetchInterval: 30_000,
  });

  const menus = menusQuery.data ?? [];
  const activeMenu = menus.find((menu) => menu.id === selectedMenuId) ?? menus[0] ?? null;

  const ordersQuery = useQuery({
    queryKey: lunchKeys.adminOrders(activeMenu?.id ?? "none"),
    queryFn: () => (activeMenu ? getAdminLunchOrders(activeMenu.id) : Promise.resolve([])),
    enabled: !!activeMenu,
    refetchInterval: activeMenu?.acceptingOrders ? 30_000 : false,
  });

  const membersQuery = useQuery({
    queryKey: lunchKeys.adminMembers(),
    queryFn: getAdminLunchMembers,
    staleTime: 30_000,
  });

  return {
    menusQuery,
    ordersQuery,
    membersQuery,
    menus,
    activeMenu,
    orders: ordersQuery.data ?? [],
    members: membersQuery.data ?? [],
    displayedSummary: summaryResult && summaryResult.menuId === activeMenu?.id ? summaryResult.summary : null,
  };
}
