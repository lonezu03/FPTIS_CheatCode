/**
 * Registers the AnCai service worker (public/sw.js) in production builds only.
 * Dev/preview-less runs never get a worker, so Vite HMR and mocked e2e API
 * routes are unaffected. Imported for its side effect from main.tsx.
 */
export function registerServiceWorker(): void {
  if (!import.meta.env.PROD || typeof window === "undefined" || !("serviceWorker" in navigator)) return;
  window.addEventListener("load", () => {
    // updateViaCache "none": always revalidate sw.js so a new deploy is picked up.
    navigator.serviceWorker.register("/sw.js", { scope: "/", updateViaCache: "none" }).catch(() => {
      /* Installability is optional; the app works without a worker. */
    });
  });
}

registerServiceWorker();
