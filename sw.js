/* Step Teller — service worker. A ogni rilascio incrementare CACHE. */
const CACHE = 'stepteller-v4.0';
const ASSETS = ['./', 'index.html', 'manifest.webmanifest', 'icon-180.png', 'icon-192.png', 'icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  const isPage = req.mode === 'navigate' || /\.(html|js)$/.test(new URL(req.url).pathname);
  if (isPage) { // network-first: gli aggiornamenti arrivano subito, offline si usa la cache
    e.respondWith(fetch(req).then(r => { const cp = r.clone(); caches.open(CACHE).then(c => c.put(req, cp)); return r; })
      .catch(() => caches.match(req, {ignoreSearch: true}).then(r => r || caches.match('index.html'))));
  } else {     // cache-first sugli asset statici
    e.respondWith(caches.match(req).then(r => r || fetch(req)));
  }
});
