import { create } from "zustand";

export type AuthUser = {
  userId: string;
  email: string;
  fullName: string;
  role: "USER" | "ADMIN";
  lunchEnabled: boolean;
  fitnessEnabled: boolean;
  healthEnabled: boolean;
  chatbotEnabled: boolean;
  todoEnabled: boolean;
  scheduleEnabled: boolean;
  quoteEnabled: boolean;
  financeEnabled: boolean;
  journalEnabled: boolean;
  passwordChangeRequired: boolean;
};

type AuthState = {
  token: string | null;
  user: AuthUser | null;
  initialized: boolean;
  setSession: (token: string, user: AuthUser) => void;
  setInitialized: (initialized: boolean) => void;
  updateUser: (user: Partial<AuthUser>) => void;
  logout: () => void;
};

const readStoredUser = (): AuthUser | null => {
  try {
    const raw = localStorage.getItem("fittrack-user");
    return raw ? (JSON.parse(raw) as AuthUser) : null;
  } catch {
    localStorage.removeItem("fittrack-user");
    return null;
  }
};

// Access tokens are kept in memory only. Remove the legacy persistent token
// once so an XSS issue cannot reuse it after a browser restart.
localStorage.removeItem("token");
const initialToken: string | null = null;
const initialUser = readStoredUser();

export const useAuthStore = create<AuthState>((set) => ({
  token: initialToken,
  user: initialUser,
  initialized: false,

  setSession: (token, user) => {
    localStorage.setItem("fittrack-user", JSON.stringify(user));
    set({ token, user });
  },

  setInitialized: (initialized) => set({ initialized }),

  updateUser: (partialUser) => {
    set((state) => {
      if (!state.user) return state;
      const user = { ...state.user, ...partialUser };
      localStorage.setItem("fittrack-user", JSON.stringify(user));
      return { user };
    });
  },

  logout: () => {
    const owner = useAuthStore.getState().user?.userId;
    if (owner) {
      try {
        const prefixes = [`fittrack:meal-draft:${owner}:`, `fittrack-session-draft:${owner}:`];
        const exactKeys = [`fittrack:todo:${owner}:draft`, `fittrack:schedule:${owner}:draft`, `fittrack:finance-draft:${owner}`];
        for (const storage of [localStorage, sessionStorage]) {
          for (let index = storage.length - 1; index >= 0; index--) {
            const key = storage.key(index);
            if (key && (exactKeys.includes(key) || prefixes.some(prefix => key === prefix || key.startsWith(prefix)))) storage.removeItem(key);
          }
        }
      } catch { /* Browser storage may be unavailable. */ }
    }
    localStorage.removeItem("fittrack-user");
    set({ token: null, user: null });
  },
}));
