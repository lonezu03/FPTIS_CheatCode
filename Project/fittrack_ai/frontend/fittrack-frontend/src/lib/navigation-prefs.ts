import { useCallback, useState } from "react";
import { readConvenience, writeConvenience } from "@/lib/convenience-storage";

/** Per-account sidebar conveniences kept in the browser only; they never affect access. */
export type NavPrefs = { pinned: string[]; open: string[] };

const MAX_PINNED = 8;
const EMPTY: NavPrefs = { pinned: [], open: [] };

export function isNavPrefs(value: unknown): value is NavPrefs {
  if (!value || typeof value !== "object") return false;
  const candidate = value as Record<string, unknown>;
  const isStringList = (list: unknown) => Array.isArray(list) && list.every((entry) => typeof entry === "string");
  return isStringList(candidate.pinned) && isStringList(candidate.open);
}

export function navPrefsKey(userId: string | number | null | undefined) {
  return userId == null || userId === "" ? null : `fittrack:nav:${userId}`;
}

/** Pin or unpin a route; the newest pins are kept when the limit is reached. */
export function togglePinned(pinned: string[], to: string): string[] {
  return pinned.includes(to) ? pinned.filter((entry) => entry !== to) : [...pinned, to].slice(-MAX_PINNED);
}

export function useNavPrefs(userId: string | number | null | undefined, activeGroupId: string | null) {
  const key = navPrefsKey(userId);
  const [stored, setStored] = useState(() => ({ key, prefs: readConvenience(key, isNavPrefs) ?? EMPTY }));
  // Re-read during render when another account signs in within the same tab.
  let current = stored;
  if (stored.key !== key) {
    current = { key, prefs: readConvenience(key, isNavPrefs) ?? EMPTY };
    setStored(current);
  }
  const prefs = current.prefs;

  // The current module is shown expanded unless the user folds it. Visiting a page
  // never adds to the saved open list, so the sidebar does not grow back into one
  // long list; the fold resets automatically when the user moves to another module.
  const [foldedGroup, setFoldedGroup] = useState<string | null>(null);

  const update = useCallback(
    (change: (value: NavPrefs) => NavPrefs) => {
      setStored((value) => {
        const next = change(value.prefs);
        writeConvenience(value.key, next);
        return { key: value.key, prefs: next };
      });
    },
    [],
  );

  const isOpen = useCallback(
    (id: string) => (id === activeGroupId ? foldedGroup !== id : prefs.open.includes(id)),
    [activeGroupId, foldedGroup, prefs.open],
  );

  const togglePin = useCallback((to: string) => update((value) => ({ ...value, pinned: togglePinned(value.pinned, to) })), [update]);

  const toggleGroup = useCallback(
    (id: string) => {
      if (id === activeGroupId) {
        setFoldedGroup((value) => (value === id ? null : id));
        return;
      }
      update((value) => ({
        ...value,
        open: value.open.includes(id) ? value.open.filter((entry) => entry !== id) : [...value.open, id],
      }));
    },
    [activeGroupId, update],
  );

  const collapseAll = useCallback(() => {
    setFoldedGroup(null);
    update((value) => ({ ...value, open: [] }));
  }, [update]);

  const hasExtraOpen = prefs.open.some((id) => id !== activeGroupId);

  return { prefs, isOpen, hasExtraOpen, togglePin, toggleGroup, collapseAll };
}
