/*
 * AnCai service worker.
 *
 * Rules (do not relax without reviewing deploy behaviour):
 *  - /api/* and every non-GET or cross-origin request is never intercepted or cached.
 *  - Navigations are network-first; the last good HTML is only an offline fallback,
 *    so a new deploy is served as soon as the network answers.
 *  - Only content-hashed /assets/* files are cached (cache-first, immutable).
 */
const VERSION = "v1";
const ASSET_CACHE = `ancai-assets-${VERSION}`;
const SHELL_CACHE = `ancai-shell-${VERSION}`;
const SHELL_KEY = "/__ancai-shell__";
const MAX_ASSETS = 150;

self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const keep = new Set([ASSET_CACHE, SHELL_CACHE]);
      const names = await caches.keys();
      await Promise.all(names.filter((name) => name.startsWith("ancai-") && !keep.has(name)).map((name) => caches.delete(name)));
      await self.clients.claim();
    })(),
  );
});

function isHashedAsset(url) {
  return url.pathname.startsWith("/assets/");
}

async function trimAssets() {
  const cache = await caches.open(ASSET_CACHE);
  const keys = await cache.keys();
  for (let index = 0; index < keys.length - MAX_ASSETS; index++) await cache.delete(keys[index]);
}

async function networkFirstNavigation(request) {
  try {
    const response = await fetch(request);
    if (response.ok && response.type === "basic" && (response.headers.get("content-type") || "").includes("text/html")) {
      const cache = await caches.open(SHELL_CACHE);
      await cache.put(SHELL_KEY, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await caches.match(SHELL_KEY, { cacheName: SHELL_CACHE });
    if (cached) return cached;
    throw error;
  }
}

async function cacheFirstAsset(request) {
  const cache = await caches.open(ASSET_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok && response.type === "basic") {
    await cache.put(request, response.clone());
    trimAssets();
  }
  return response;
}

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname === "/api" || url.pathname.startsWith("/api/")) return;

  if (request.mode === "navigate") {
    event.respondWith(networkFirstNavigation(request));
    return;
  }
  if (isHashedAsset(url)) {
    event.respondWith(cacheFirstAsset(request));
  }
  // Everything else (manifest, icons, sw.js, branding) goes straight to the network.
});
