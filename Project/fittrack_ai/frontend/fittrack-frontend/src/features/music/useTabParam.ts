import { useCallback } from "react";
import { useSearchParams } from "react-router-dom";

/** Active tab kept in ?tab= so routine links can open a section directly. */
export function useTabParam<T extends string>(tabs: readonly T[], fallback: T) {
  const [params, setParams] = useSearchParams();
  const raw = params.get("tab");
  const tab = (tabs as readonly string[]).includes(raw ?? "") ? (raw as T) : fallback;
  const setTab = useCallback(
    (value: string) =>
      setParams(
        (current) => {
          const next = new URLSearchParams(current);
          if (value === fallback) next.delete("tab");
          else next.set("tab", value);
          return next;
        },
        { replace: true },
      ),
    [setParams, fallback],
  );
  return [tab, setTab] as const;
}
