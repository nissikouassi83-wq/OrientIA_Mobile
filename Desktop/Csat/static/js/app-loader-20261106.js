(function () {
  "use strict";

  const loadApplication = () => {
    const script = document.createElement("script");
    script.src = "/static/js/app.js";
    document.head.append(script);
  };

  if (window.portalServiceWorkerRefresh) {
    window.portalServiceWorkerRefresh.then(loadApplication);
  } else {
    loadApplication();
  }
})();
