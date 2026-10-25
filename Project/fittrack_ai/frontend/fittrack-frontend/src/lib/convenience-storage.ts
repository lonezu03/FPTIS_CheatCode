/** Optional browser conveniences must never prevent API-backed screens loading. */
export function readConvenience<T>(key: string | null, validate: (value: unknown) => value is T): T | null {
  if (!key) return null;
  try {
    let value: unknown = JSON.parse(localStorage.getItem(key) ?? "null");
    if (key.includes("-draft:")) {
      if (!value || typeof value !== "object" || !("savedAt" in value) || !("data" in value) || typeof value.savedAt !== "number" || !Number.isFinite(value.savedAt) || value.savedAt > Date.now() || Date.now() - value.savedAt > 7 * 86400000) return null;
      value = value.data;
    }
    return validate(value) ? value : null;
  } catch { return null; }
}

export function writeConvenience(key: string | null, value: unknown): void {
  if (!key) return;
  try {
    if (value === null) localStorage.removeItem(key);
    else localStorage.setItem(key, JSON.stringify(key.includes("-draft:") ? { savedAt: Date.now(), data: value } : value));
  } catch { /* Storage may be disabled or full; saving to the server still works. */ }
}
