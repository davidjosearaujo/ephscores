// Offline cache for the EPHScores PWA. scripts/build_web.sh fills in the
// version and the precache list; every build produces a new cache.
const VERSION = '__VERSION__';
const PRECACHE = __PRECACHE__;
const CACHE = `ephscores-${VERSION}`;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // Bypass the HTTP cache so a new version never mixes in stale files.
    await cache.addAll(PRECACHE.map((url) => new Request(url, { cache: 'reload' })));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('ephscores-') && key !== CACHE) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

// Cache first. Files outside the precache list (the renderer, which differs
// per browser) are cached the first time they load.
self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    if (request.mode === 'navigate') {
      const shell = await cache.match('index.html');
      if (shell) return shell;
    }
    const hit = await cache.match(request, { ignoreSearch: true });
    if (hit) return hit;
    const response = await fetch(request);
    if (response.ok) cache.put(request, response.clone());
    return response;
  })());
});
