import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";

import type {
  FinanceAccount,
  FinanceBudget,
  FinanceCategory,
  FinanceRecurring,
  FinanceTransaction,
} from "@/api/finance.api";
import { readConvenience, writeConvenience } from "@/lib/convenience-storage";
import { useAuthStore } from "@/store/auth.store";
import { isFinanceView, monthNow, resolveInitialFinanceView } from "./finance-utils";

/**
 * Month, filters, page and tab of the finance screen. Restores the per-user saved view;
 * a quick-search link (`?q=…&month=…`) opens the matching transactions instead.
 */
export function useFinanceView() {
  const userId = useAuthStore((state) => state.user?.userId);
  const [searchParams] = useSearchParams();
  const [preferenceOwner] = useState(userId);
  const preferenceKey = userId && preferenceOwner === userId ? `fittrack:finance-view:${userId}` : null;
  const [initial] = useState(() => resolveInitialFinanceView(
    { q: searchParams.get("q"), month: searchParams.get("month") },
    readConvenience(preferenceKey, isFinanceView),
    monthNow,
  ));
  const [month, setMonth] = useState(initial.month);
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState(initial.search);
  const [typeFilter, setTypeFilter] = useState(initial.type);
  const [accountFilter, setAccountFilter] = useState(initial.account);
  const [categoryFilter, setCategoryFilter] = useState(initial.category);
  const [tab, setTab] = useState(initial.tab);

  useEffect(() => {
    writeConvenience(preferenceKey, { month, search, type: typeFilter, account: accountFilter, category: categoryFilter, tab });
  }, [preferenceKey, month, search, typeFilter, accountFilter, categoryFilter, tab]);

  return {
    month,
    page,
    search,
    typeFilter,
    accountFilter,
    categoryFilter,
    tab,
    setTab,
    setPage,
    changeMonth: (value: string) => { setMonth(value); setPage(0); },
    changeSearch: (value: string) => { setSearch(value); setPage(0); },
    // Changing the type clears the category, which belongs to one type.
    changeType: (value: string) => { setTypeFilter(value); setCategoryFilter(""); setPage(0); },
    changeAccount: (value: string) => { setAccountFilter(value); setPage(0); },
    changeCategory: (value: string) => { setCategoryFilter(value); setPage(0); },
  };
}

export type FinanceViewState = ReturnType<typeof useFinanceView>;

type Editing<T> = T | "new" | null;

/** Which editor dialog is open. `?action=new` opens the new-transaction dialog. */
export function useFinanceDialogs() {
  const [searchParams] = useSearchParams();
  const [transaction, setTransaction] = useState<Editing<FinanceTransaction>>(() => searchParams.get("action") === "new" ? "new" : null);
  const [account, setAccount] = useState<Editing<FinanceAccount>>(null);
  const [reconcile, setReconcile] = useState<FinanceAccount | null>(null);
  const [category, setCategory] = useState<Editing<FinanceCategory>>(null);
  const [budget, setBudget] = useState<Editing<FinanceBudget>>(null);
  const [recurring, setRecurring] = useState<Editing<FinanceRecurring>>(null);
  return {
    transaction, setTransaction,
    account, setAccount,
    reconcile, setReconcile,
    category, setCategory,
    budget, setBudget,
    recurring, setRecurring,
  };
}

export type FinanceDialogs = ReturnType<typeof useFinanceDialogs>;
