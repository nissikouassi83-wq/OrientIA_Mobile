(function () {
  "use strict";

  const search = document.querySelector("#search");
  const results = document.querySelector("#search-results");
  const index = document.querySelector("#search-index");
  const connectionStatus = document.querySelector("[data-connection-status]");
  const installButton = document.querySelector("[data-install-app]");
  let installPrompt;
  let cacheIsReady = false;

  if (window.location.hash) {
    const target = document.getElementById(window.location.hash.slice(1));
    if (target && target.tagName === "DETAILS") {
      target.open = true;
      target.scrollIntoView({ block: "start" });
    }
  }

  if (search && results && index) {
    const searchIndex = JSON.parse(index.textContent);
    const sections = searchIndex.sections;
    const textFromHtml = (value) => {
      const documentFragment = new DOMParser().parseFromString(value, "text/html");
      return documentFragment.body.textContent || "";
    };

    search.addEventListener("input", () => {
      const query = search.value.trim().toLocaleLowerCase("fr");
      results.replaceChildren();
      if (!query) return;

      const matches = [];
      Object.entries(sections).forEach(([key, section]) => {
        section.items.forEach((item, position) => {
          const text = `${section.t} ${section.d} ${item.t} ${textFromHtml(item.b)}`;
          if (text.toLocaleLowerCase("fr").includes(query)) {
            matches.push({
              title: item.t,
              section: section.t,
              url: `/rubrique/${encodeURIComponent(key)}#prestation-${position}`,
            });
          }
        });
      });

      searchIndex.extras.forEach((item) => {
        const text = `Plateformes digitales et centre de contacts ${item.title} ${item.description}`;
        if (text.toLocaleLowerCase("fr").includes(query)) {
          matches.push({
            title: item.title,
            section: "Plateformes digitales et centre de contacts",
            url: `/rubrique/plateformes${item.id === "appointment" ? "#agences" : ""}`,
          });
        }
      });
      if (`Réclamation ${searchIndex.complaints.join(" ")}`.toLocaleLowerCase("fr").includes(query)) {
        matches.push({
          title: "Réclamation",
          section: "Aide et réclamation",
          url: "/reclamation",
        });
      }
      searchIndex.complaints.forEach((method) => {
        if (method.toLocaleLowerCase("fr").includes(query)) {
          matches.push({ title: method, section: "Réclamation", url: "/reclamation" });
        }
      });

      if (!matches.length) {
        const empty = document.createElement("p");
        empty.className = "no-results";
        empty.textContent = "Aucun résultat. Essayez un autre mot ou appelez le 1396.";
        results.append(empty);
        return;
      }

      matches.forEach((match) => {
        const link = document.createElement("a");
        link.className = "result";
        link.href = match.url;
        const title = document.createElement("strong");
        title.textContent = match.title;
        const section = document.createElement("small");
        section.textContent = match.section;
        link.append(title, section);
        results.append(link);
      });
    });
  }

  if ("serviceWorker" in navigator) {
    (window.portalServiceWorkerRefresh || navigator.serviceWorker.register("/service-worker-v16.js"))
      .then(() => navigator.serviceWorker.ready)
      .then(async () => {
        await cachePortalResources();
      })
      .catch((error) => {
        console.error("Le mode hors connexion n’a pas pu être activé.", error);
        if (connectionStatus) connectionStatus.textContent = "La consultation hors connexion n’a pas pu être préparée.";
      });
  } else if (connectionStatus) {
    connectionStatus.textContent = "Sans compte · ouvrez ce portail avec une connexion Internet.";
  }

  window.addEventListener("online", () => {
    updateConnectionStatus();
    flushPendingComplaints();
  });
  window.addEventListener("offline", updateConnectionStatus);
  updateConnectionStatus();

  window.addEventListener("beforeinstallprompt", (event) => {
    if (!installButton) return;
    event.preventDefault();
    installPrompt = event;
    installButton.hidden = false;
  });

  if (installButton) {
    installButton.addEventListener("click", async () => {
      if (!installPrompt) return;
      await installPrompt.prompt();
      installPrompt = null;
      installButton.hidden = true;
    });
  }

  document.addEventListener("submit", async (event) => {
    const form = event.target;
    if (!form.matches(".complaint-form")) return;
    if (!form.reportValidity()) return;

    event.preventDefault();
    const ticketField = form.elements.namedItem("offline_ticket");
    if (!ticketField.value) ticketField.value = newTicket();
    const payload = Object.fromEntries(new FormData(form).entries());
    const submitButton = form.querySelector('button[type="submit"]');
    submitButton.disabled = true;

    if (!navigator.onLine) {
      await queueComplaint(payload, form, submitButton);
      return;
    }

    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: new FormData(form),
        credentials: "same-origin",
      });
      const responseDocument = new DOMParser().parseFromString(await response.text(), "text/html");
      if (response.ok && responseDocument.querySelector(".confirmation")) {
        replaceApp(responseDocument);
        return;
      }
      if (!response.ok) {
        replaceApp(responseDocument);
        return;
      }
      throw new Error("La confirmation de l’envoi est introuvable.");
    } catch (error) {
      console.warn("Envoi différé : la connexion au portail est indisponible.", error);
      await queueComplaint(payload, form, submitButton);
    }
  });

  navigator.serviceWorker?.addEventListener("message", (event) => {
    if (event.data?.type === "complaints-sent") {
      updateConnectionStatus();
    }
  });

  document.querySelectorAll("[data-share]").forEach((button) => {
    button.addEventListener("click", async () => {
      const url = button.dataset.shareUrl || window.location.href.split("#")[0];
      try {
        if (navigator.share) {
          await navigator.share({ title: "CNPS — Guide des prestations", url });
        } else if (navigator.clipboard) {
          await navigator.clipboard.writeText(url);
          announce("Lien copié.");
        } else {
          window.prompt("Copiez ce lien :", url);
        }
      } catch (error) {
        if (error.name !== "AbortError") announce("Le partage n’a pas abouti. Vous pouvez copier le lien.");
      }
    });
  });

  document.querySelectorAll("[data-copy]").forEach((button) => {
    button.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(button.dataset.copy);
        announce("Lien copié.");
      } catch (_error) {
        window.prompt("Copiez ce lien :", button.dataset.copy);
      }
    });
  });

  function announce(message) {
    const status = document.querySelector("#share-status");
    if (status) status.textContent = message;
  }

  function updateConnectionStatus() {
    if (!connectionStatus) return;
    connectionStatus.textContent = navigator.onLine
      ? cacheIsReady
        ? "Sans compte · vos rubriques sont disponibles hors connexion"
        : "Sans compte · préparation du portail hors connexion…"
      : "Hors connexion · le portail reste disponible sur cet appareil";
    document.documentElement.classList.toggle("is-offline", !navigator.onLine);
    updatePendingCount();
  }

  async function cachePortalResources() {
    const requiredResources = [
      "/", "/accueil", "/rubrique/sal", "/rubrique/ind", "/rubrique/ent",
      "/rubrique/plateformes", "/reclamation", "/offline.html",
      "/static/css/style.css", "/static/js/app.js", "/static/manifest.webmanifest",
      "/static/cnps_logo.jpeg", "/static/icons/cnps-192.png",
      "/static/icons/cnps-512.png", "/static/favicon.ico",
      "/static/brochures/assurance-maternite.pdf",
      "/static/brochures/accidents-travail.pdf",
      "/static/brochures/assurance-vieillesse.pdf",
      "/static/brochures/affiliation-entreprise-cnps.pdf",
    ];
    if (!navigator.onLine || !("caches" in window)) return;
    try {
      const cache = await caches.open("cnps-portail-v16");
      const cached = await Promise.all(requiredResources.map(async (url) => {
        try {
          let response = await cache.match(url);
          if (!response) {
            response = await fetch(url, { cache: "no-store", credentials: "same-origin" });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            await cache.put(url, response.clone());
          }
          return true;
        } catch (error) {
          console.warn("Ressource indisponible hors connexion :", url, error);
          return false;
        }
      }));
      cacheIsReady = cached.every(Boolean);
      updateConnectionStatus();
    } catch (error) {
      console.error("La préparation du portail hors connexion a échoué.", error);
      if (connectionStatus) {
        connectionStatus.textContent = "Le portail est accessible, mais le mode hors connexion n’a pas pu être préparé.";
      }
    }
  }

  function newTicket() {
    const bytes = new Uint8Array(4);
    crypto.getRandomValues(bytes);
    const suffix = Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("").toUpperCase();
    return `CNPS-${new Date().getFullYear()}-${suffix}`;
  }

  function openQueue() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open("cnps-portail", 1);
      request.onupgradeneeded = () => {
        request.result.createObjectStore("reclamations", { keyPath: "offline_ticket" });
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  async function queueComplaint(payload, form, submitButton) {
    try {
      const database = await openQueue();
      const transaction = database.transaction("reclamations", "readwrite");
      transaction.objectStore("reclamations").put(payload);
      transaction.oncomplete = () => {
        database.close();
        showQueuedConfirmation(form, payload.offline_ticket);
        registerBackgroundSync();
        updatePendingCount();
      };
      transaction.onerror = () => {
        database.close();
        submitButton.disabled = false;
        announceFormError(form, "Impossible d’enregistrer votre demande sur cet appareil. Veuillez réessayer.");
      };
    } catch (error) {
      console.error("Échec de l’enregistrement local de la réclamation.", error);
      submitButton.disabled = false;
      announceFormError(form, "Le stockage hors connexion est indisponible sur cet appareil.");
    }
  }

  function showQueuedConfirmation(form, ticket) {
    form.hidden = true;
    const confirmation = document.createElement("section");
    confirmation.className = "confirmation offline-confirmation";
    confirmation.setAttribute("role", "status");
    confirmation.setAttribute("aria-live", "polite");
    const title = document.createElement("h2");
    title.textContent = "Votre demande est enregistrée sur cet appareil.";
    const number = document.createElement("p");
    number.textContent = "Numéro de suivi :";
    const code = document.createElement("p");
    code.className = "ticket";
    code.textContent = ticket;
    const notice = document.createElement("p");
    notice.textContent = "Elle sera transmise à la CNPS dès le retour de la connexion. Gardez ce numéro de suivi.";
    confirmation.append(title, number, code, notice);
    form.before(confirmation);
  }

  function announceFormError(form, message) {
    let notice = form.previousElementSibling;
    if (!notice || !notice.matches(".local-form-error")) {
      notice = document.createElement("p");
      notice.className = "notice error local-form-error";
      notice.setAttribute("role", "alert");
      form.before(notice);
    }
    notice.textContent = message;
  }

  async function updatePendingCount() {
    if (!("indexedDB" in window)) return;
    try {
      const database = await openQueue();
      const count = await new Promise((resolve, reject) => {
        const request = database.transaction("reclamations").objectStore("reclamations").count();
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      database.close();
      if (count && connectionStatus) {
        connectionStatus.textContent += ` · ${count} réclamation${count > 1 ? "s" : ""} en attente`;
      }
    } catch (error) {
      console.error("Impossible de lire la file de réclamations hors connexion.", error);
    }
  }

  async function registerBackgroundSync() {
    try {
      const registration = await navigator.serviceWorker.ready;
      if ("sync" in registration) await registration.sync.register("cnps-send-complaints");
      if (navigator.onLine) await flushPendingComplaints();
    } catch (error) {
      console.warn("La synchronisation sera relancée à la prochaine ouverture.", error);
    }
  }

  async function flushPendingComplaints() {
    if (!navigator.onLine || !("indexedDB" in window)) return;
    let database;
    try {
      database = await openQueue();
      const pending = await new Promise((resolve, reject) => {
        const request = database.transaction("reclamations").objectStore("reclamations").getAll();
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      for (const complaint of pending) {
        const page = await fetch("/reclamation", { cache: "no-store", credentials: "same-origin" });
        if (!page.ok) throw new Error("Impossible de préparer l’envoi de la réclamation.");
        const html = await page.text();
        const token = html.match(/name="csrf_token"\s+value="([^"]+)"/);
        if (!token) throw new Error("Jeton de formulaire introuvable.");
        const body = new URLSearchParams({ ...complaint, csrf_token: token[1] });
        const response = await fetch("/reclamation", {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body,
          credentials: "same-origin",
        });
        const responseHtml = await response.text();
        if (!response.ok || !responseHtml.includes(complaint.offline_ticket)) {
          throw new Error("La réclamation est toujours en attente d’envoi.");
        }
        await new Promise((resolve, reject) => {
          const transaction = database.transaction("reclamations", "readwrite");
          transaction.objectStore("reclamations").delete(complaint.offline_ticket);
          transaction.oncomplete = resolve;
          transaction.onerror = () => reject(transaction.error);
        });
      }
      if (pending.length && connectionStatus) {
        connectionStatus.textContent = "Connexion rétablie · vos réclamations ont été transmises";
      }
      database.close();
      updatePendingCount();
    } catch (error) {
      database?.close();
      console.warn("Une ou plusieurs réclamations restent en attente.", error);
    }
  }

  function replaceApp(responseDocument) {
    const currentApp = document.querySelector(".app");
    const nextApp = responseDocument.querySelector(".app");
    if (currentApp && nextApp) currentApp.replaceWith(nextApp.cloneNode(true));
    document.title = responseDocument.title;
  }
})();
