// Generated releases substitute the file digests and version before deployment.
const resources = __ASSET_DIGESTS__;
const scope = self.registration.scope;
const prefix = "little-bumpy:" + scope + ":";
const releaseCache = prefix + __RELEASE__;
// Static hosts may redirect index.html to the directory URL. Cache the
// canonical navigation response so it can be replayed offline.
const urls = new Map(Object.keys(resources).map(path =>
  [path === "index.html" ? scope : new URL(path, scope).href, path]));

self.addEventListener("install", event => {
  event.waitUntil((async () => {
    const cache = await caches.open(releaseCache);
    try {
      // One incomplete or mismatched file leaves the previous release active.
      await cache.addAll(Array.from(urls, ([url, path]) =>
        new Request(url, {cache: "reload", integrity: resources[path]})));
    } catch (error) {
      await caches.delete(releaseCache);
      throw error;
    }
  })());
});

self.addEventListener("activate", event => {
  event.waitUntil((async () => {
    for (const name of await caches.keys()) {
      if (name.startsWith(prefix) && name !== releaseCache) await caches.delete(name);
    }
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  url.search = "";
  const key = url.href === new URL("index.html", scope).href ? scope : url.href;
  if (!urls.has(key)) return;
  event.respondWith((async () => {
    const cache = await caches.open(releaseCache);
    return await cache.match(key) || fetch(event.request);
  })());
});
