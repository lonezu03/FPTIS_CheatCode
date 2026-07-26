import { create } from "zustand";

export type AuthUser = {
  userId: string;
  email: string;
  fullName: string;
  role: "USER" | "ADMIN";
};

type AuthState = {
  token: string | null;
  user: AuthUser | null;
  setSession: (token: string, user: AuthUser) => void;
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

const readUserFromToken = (token: string | null): AuthUser | null => {
  if (!token) return null;

  try {
    const encodedPayload = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const paddedPayload = encodedPayload.padEnd(Math.ceil(encodedPayload.length / 4) * 4, "=");
    const payload = JSON.parse(atob(paddedPayload)) as {
      userId?: string;
      sub?: string;
      role?: string;
    };

    if (!payload.userId || !payload.sub) return null;

    return {
      userId: payload.userId,
      email: payload.sub,
      fullName: payload.sub.split("@")[0],
      role: payload.role === "ADMIN" ? "ADMIN" : "USER",
    };
  } catch {
    return null;
  }
};

const initialToken = localStorage.getItem("token");
const initialUser = readStoredUser() ?? readUserFromToken(initialToken);

export const useAuthStore = create<AuthState>((set) => ({
  token: initialToken,
  user: initialUser,

  setSession: (token, user) => {
    localStorage.setItem("token", token);
    localStorage.setItem("fittrack-user", JSON.stringify(user));
    set({ token, user });
  },

  updateUser: (partialUser) => {
    set((state) => {
      if (!state.user) return state;
      const user = { ...state.user, ...partialUser };
      localStorage.setItem("fittrack-user", JSON.stringify(user));
      return { user };
    });
  },

  logout: () => {
    localStorage.removeItem("token");
    localStorage.removeItem("fittrack-user");
    set({ token: null, user: null });
  },
}));
