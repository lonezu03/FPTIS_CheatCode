export const DUPLICATE_MUTATION_MESSAGE =
  "Thao tác này đang được xử lý. Vui lòng chờ API phản hồi.";

export type ApiActivitySnapshot = {
  pendingRequests: number;
  pendingMutations: number;
};

type Listener = () => void;

export class ApiActivityStore {
  private readonly activeRequests = new Map<number, boolean>();
  private readonly listeners = new Set<Listener>();
  private nextId = 1;
  private snapshot: ApiActivitySnapshot = {
    pendingRequests: 0,
    pendingMutations: 0,
  };

  readonly subscribe = (listener: Listener): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  readonly getSnapshot = (): ApiActivitySnapshot => this.snapshot;

  begin(isMutation: boolean): () => void {
    const id = this.nextId++;
    this.activeRequests.set(id, isMutation);
    this.publish();

    let finished = false;
    return () => {
      if (finished) return;
      finished = true;
      this.activeRequests.delete(id);
      this.publish();
    };
  }

  private publish(): void {
    let pendingMutations = 0;
    for (const isMutation of this.activeRequests.values()) {
      if (isMutation) pendingMutations += 1;
    }
    this.snapshot = {
      pendingRequests: this.activeRequests.size,
      pendingMutations,
    };
    this.listeners.forEach((listener) => listener());
  }
}

export class MutationRequestGuard {
  private readonly activeKeys = new Set<string>();

  acquire(key: string): (() => void) | null {
    if (this.activeKeys.has(key)) return null;
    this.activeKeys.add(key);

    let released = false;
    return () => {
      if (released) return;
      released = true;
      this.activeKeys.delete(key);
    };
  }
}

export const apiActivityStore = new ApiActivityStore();

export function isMutationMethod(method?: string): boolean {
  return ["post", "put", "patch", "delete"].includes(method?.toLowerCase() ?? "");
}

export function createMutationKey(input: {
  method?: string;
  baseURL?: string;
  url?: string;
  params?: unknown;
  data?: unknown;
}): string {
  return [
    input.method?.toLowerCase() ?? "post",
    input.baseURL ?? "",
    input.url ?? "",
    stableSerialize(input.params),
    stableSerialize(input.data),
  ].join(":");
}

function stableSerialize(value: unknown): string {
  try {
    return JSON.stringify(toStableValue(value, new WeakSet<object>())) ?? "";
  } catch {
    return String(value ?? "");
  }
}

function toStableValue(value: unknown, seen: WeakSet<object>): unknown {
  if (value == null || typeof value !== "object") return value;
  if (value instanceof Date) return value.toISOString();
  if (typeof URLSearchParams !== "undefined" && value instanceof URLSearchParams) {
    return [...value.entries()].sort(([left], [right]) => left.localeCompare(right));
  }
  if (typeof FormData !== "undefined" && value instanceof FormData) {
    return [...value.entries()]
      .map(([key, entry]) => [key, describeFormEntry(entry)])
      .sort(([left], [right]) => String(left).localeCompare(String(right)));
  }
  if (seen.has(value)) return "[Circular]";
  seen.add(value);

  const result = Array.isArray(value)
    ? value.map((item) => toStableValue(item, seen))
    : Object.fromEntries(
        Object.entries(value)
          .sort(([left], [right]) => left.localeCompare(right))
          .map(([key, item]) => [key, toStableValue(item, seen)]),
      );
  seen.delete(value);
  return result;
}

function describeFormEntry(value: FormDataEntryValue): unknown {
  if (typeof value === "string") return value;
  return {
    name: value.name,
    size: value.size,
    type: value.type,
    lastModified: value.lastModified,
  };
}
