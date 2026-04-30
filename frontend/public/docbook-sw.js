// DocBook Service Worker — offline reading for dist/chunked formats.
// Cache-first for static assets, stale-while-revalidate for content.

const CACHE_NAME = 'docbook-cache-v1'

// Static assets: cache on install
const STATIC_ASSETS = [
  '/app.iife.js',
  '/app.css',
]

// Install: pre-cache known static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS).catch(() => {
        // Some assets may not exist on all formats — that's fine
      })
    })
  )
  self.skipWaiting()
})

// Activate: clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      )
    )
  )
  self.clients.claim()
})

// Fetch strategy:
// - HTML pages: network-first, cache fallback
// - JSON content (manifest, sections, docbook.data.json): stale-while-revalidate
// - CSS/JS: cache-first
// - Images: cache-first with long expiry
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url)

  // Only handle same-origin requests
  if (url.origin !== location.origin) return

  // Skip non-GET requests
  if (event.request.method !== 'GET') return

  // JSON content: stale-while-revalidate
  if (url.pathname.endsWith('.json') ||
      url.pathname.includes('/sections/') ||
      url.pathname === '/manifest.json') {
    event.respondWith(staleWhileRevalidate(event.request))
    return
  }

  // CSS/JS: cache-first
  if (url.pathname.endsWith('.js') || url.pathname.endsWith('.css')) {
    event.respondWith(cacheFirst(event.request))
    return
  }

  // Images: cache-first
  if (url.pathname.match(/\.(png|jpg|jpeg|gif|svg|webp|ico)$/)) {
    event.respondWith(cacheFirst(event.request))
    return
  }

  // HTML pages: network-first
  if (url.pathname.endsWith('.html') || url.pathname.endsWith('/') ||
      event.request.headers.get('accept')?.includes('text/html')) {
    event.respondWith(networkFirst(event.request))
    return
  }
})

async function cacheFirst(request) {
  const cached = await caches.match(request)
  if (cached) return cached

  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    return new Response('Offline', { status: 503 })
  }
}

async function networkFirst(request) {
  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    const cached = await caches.match(request)
    if (cached) return cached
    return new Response('Offline', { status: 503 })
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(CACHE_NAME)
  const cached = await cache.match(request)

  // Return cached immediately if available, otherwise wait for network
  const fetchPromise = fetch(request).then((response) => {
    if (response.ok) {
      cache.put(request, response.clone())
    }
    return response
  }).catch(() => cached)

  return cached || fetchPromise
}
