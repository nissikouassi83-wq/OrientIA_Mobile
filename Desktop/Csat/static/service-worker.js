"use strict";

const CACHE_NAME = "cnps-portail-v11";

self.addEventListener("install", (event) => {
  event.waitUntil((async () => {
    await caches.open(CACHE_NAME);
    await self.skipWaiting();
  })());
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys
      .filter((key) => key.startsWith("cnps-portail-") && key !== CACHE_NAME)
      .map((key) => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);
  if (request.method !== "GET" || url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    if (url.pathname === "/qr") {
      event.respondWith((async () => {
        try {
          return await fetch(request);
        } catch (_error) {
          return (await caches.match("/offline.html"));
        }
      })());
      return;
    }

    event.respondWith((async () => {
      try {
        const response = await fetch(request);
        if (response.ok && response.headers.get("Cache-Control") !== "no-store") {
          const cache = await caches.open(CACHE_NAME);
          await cache.put(request, response.clone());
        }
        return response;
      } catch (_error) {
        return (await caches.match(request, { ignoreSearch: true }))
          || (await caches.match(url.pathname, { ignoreSearch: true }))
          || (await caches.match("/offline.html"));
      }
    })());
    return;
  }

  if (url.pathname.startsWith("/static/")) {
    event.respondWith((async () => {
      const cached = await caches.match(request, { ignoreSearch: true });
      if (cached) return cached;
      const response = await fetch(request);
      if (response.ok) {
        const cache = await caches.open(CACHE_NAME);
        await cache.put(request, response.clone());
      }
      return response;
    })());
  }
});

self.addEventListener("sync", (event) => {
  if (event.tag === "cnps-send-complaints") {
    event.waitUntil(sendQueuedComplaints());
  }
});

async function sendQueuedComplaints() {
  const database = await openQueueDatabase();
  const pending = await readQueue(database);
  if (!pending.length) return;

  for (const complaint of pending) {
    const page = await fetch("/reclamation", { cache: "no-store" });
    if (!page.ok) throw new Error("Impossible de préparer l’envoi de la réclamation.");
    const pageHtml = await page.text();
    const token = pageHtml.match(/name="csrf_token"\s+value="([^"]+)"/);
    if (!token) throw new Error("Jeton de formulaire introuvable.");
    const body = new URLSearchParams({ ...complaint, csrf_token: token[1] });
    const response = await fetch("/reclamation", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
      redirect: "follow",
    });
    if (!response.ok) throw new Error("L’envoi de la réclamation a échoué.");
    const result = await response.text();
    if (!result.includes(complaint.offline_ticket)) {
      throw new Error("La confirmation de la réclamation est introuvable.");
    }
    await deleteQueuedComplaint(database, complaint.offline_ticket);
  }
  database.close();
  const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
  windows.forEach((client) => client.postMessage({ type: "complaints-sent" }));
}

function openQueueDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open("cnps-portail", 1);
    request.onupgradeneeded = () => {
      request.result.createObjectStore("reclamations", { keyPath: "offline_ticket" });
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function readQueue(database) {
  return new Promise((resolve, reject) => {
    const request = database.transaction("reclamations").objectStore("reclamations").getAll();
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

function deleteQueuedComplaint(database, ticket) {
  return new Promise((resolve, reject) => {
    const transaction = database.transaction("reclamations", "readwrite");
    transaction.objectStore("reclamations").delete(ticket);
    transaction.oncomplete = resolve;
    transaction.onerror = () => reject(transaction.error);
  });
}
