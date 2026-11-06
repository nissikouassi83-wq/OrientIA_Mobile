(function () {
  "use strict";

  if (!("serviceWorker" in navigator)) return;

  const workerUrl = new URL("/service-worker-v17.js", window.location.origin).href;
  let refreshing = false;
  navigator.serviceWorker.addEventListener("controllerchange", () => {
    if (refreshing) return;
    refreshing = true;
    window.location.reload();
  });

  window.portalServiceWorkerRefresh = (async () => {
    const registrations = await navigator.serviceWorker.getRegistrations();
    const cacheNames = await caches.keys();
    const currentRegistration = registrations.some((registration) =>
      [registration.active, registration.waiting, registration.installing]
        .some((worker) => worker?.scriptURL === workerUrl)
    );
    const portalCaches = cacheNames.filter((name) => name.startsWith("cnps-portail-"));
    const cachesToDelete = currentRegistration
      ? portalCaches.filter((name) => name !== "cnps-portail-v17")
      : portalCaches;

    if (cachesToDelete.length || (registrations.length && !currentRegistration)) {
      await Promise.all(registrations.map((registration) => registration.unregister()));
      await Promise.all(cachesToDelete.map((name) => caches.delete(name)));
    }

    return navigator.serviceWorker.register(workerUrl, { updateViaCache: "none" });
  })()
    .catch((error) => {
      console.error("La mise à jour du portail n’a pas pu être vérifiée.", error);
      return navigator.serviceWorker.register(workerUrl);
    });
})();
