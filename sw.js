/* Palmstead (PEP Landbank) — service worker
   Provides an installable, offline-tolerant app shell.
   Your data (leads, enquiries, etc.) always comes live from Supabase when online —
   this only caches the app shell so the portal still opens with no signal. */

const CACHE_NAME = 'pep-portal-v3';
const APP_SHELL = [
  './index.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png',
  './favicon-32.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  // Never cache Supabase API calls or auth — those must always be live.
  if (req.url.includes('supabase.co')) return;

  // App shell: network-first so staff always get the newest build when online,
  // falling back to the cached copy the moment the connection drops. cache:
  // 'no-store' matters here -- without it, the browser's own HTTP cache (not
  // just this service worker's cache) can silently satisfy this fetch with a
  // stale response, which defeats "network-first" entirely and is exactly
  // what let a stale build linger during testing.
  if (req.mode === 'navigate' || APP_SHELL.some((p) => req.url.endsWith(p.replace('./', '')))) {
    event.respondWith(
      fetch(req, { cache: 'no-store' })
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => caches.match(req).then((res) => res || caches.match('./index.html')))
    );
    return;
  }

  // Everything else (fonts, Supabase JS CDN, etc.): cache-first, refresh in background.
  event.respondWith(
    caches.match(req).then((cached) => {
      const fetchPromise = fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => cached);
      return cached || fetchPromise;
    })
  );
});
