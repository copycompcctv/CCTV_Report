/* Service worker: membuat aplikasi bisa dibuka tanpa sinyal.
   Naikkan angka versi di bawah setiap kali index.html diubah, supaya HP mengambil versi baru. */
var CACHE = 'laporan-cctv-v66';
var SHELL = ['./', 'index.html', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png', 'apple-touch-icon.png', 'logo-copy-computer.PNG', 'cctv.html', 'servisan/index.html', 'servisan/app.html', 'nota.html', 'cek-servisan.html'];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE).then(function (c) { return c.addAll(SHELL); }).then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  var ok = url.origin === self.location.origin || url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com';
  if (!ok) return;
  e.respondWith(
    caches.open(CACHE).then(function (cache) {
      // Always check the network first so GitHub Pages updates are not hidden by an old cached app.
      return fetch(req).then(function (res) {
        if (res && (res.ok || res.type === 'opaque')) cache.put(req, res.clone());
        return res;
      }).catch(function () {
        return cache.match(req, { ignoreSearch: true }).then(function (hit) {
          return hit || cache.match('index.html');
        });
      });
    })
  );
});
