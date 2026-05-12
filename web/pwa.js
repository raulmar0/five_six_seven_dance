// PWA bridge — exposes install + update affordances to the Flutter app.
// Surfaces:
//   window.pwa567.canInstall()      -> bool
//   window.pwa567.isIOS()           -> bool
//   window.pwa567.isStandalone()    -> bool (running as installed PWA)
//   window.pwa567.install()         -> Promise<'accepted'|'dismissed'|'unavailable'>
//   window.pwa567.updateAvailable() -> bool
//   window.pwa567.checkForUpdate()  -> Promise<bool>
//   window.pwa567.applyUpdate()     -> reloads with the new SW active

(function () {
  var deferredInstallPrompt = null;
  var updateAvailable = false;
  var waitingWorker = null;
  var swRegistration = null;

  function isIOS() {
    var ua = window.navigator.userAgent || '';
    var iOSDevice = /iPad|iPhone|iPod/.test(ua);
    // iPadOS 13+ reports as Mac with touch support
    var iPadMac = ua.includes('Mac') && 'ontouchend' in document;
    return iOSDevice || iPadMac;
  }

  function isStandalone() {
    return (
      window.matchMedia('(display-mode: standalone)').matches ||
      window.matchMedia('(display-mode: minimal-ui)').matches ||
      window.matchMedia('(display-mode: fullscreen)').matches ||
      window.navigator.standalone === true
    );
  }

  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    deferredInstallPrompt = e;
    document.dispatchEvent(new CustomEvent('pwa567:installable'));
  });

  window.addEventListener('appinstalled', function () {
    deferredInstallPrompt = null;
    document.dispatchEvent(new CustomEvent('pwa567:installed'));
  });

  function notifyUpdateAvailable() {
    updateAvailable = true;
    document.dispatchEvent(new CustomEvent('pwa567:update-available'));
  }

  function trackWaiting(reg) {
    if (!reg) return;
    if (reg.waiting && navigator.serviceWorker.controller) {
      waitingWorker = reg.waiting;
      notifyUpdateAvailable();
    }
    reg.addEventListener('updatefound', function () {
      var newWorker = reg.installing;
      if (!newWorker) return;
      newWorker.addEventListener('statechange', function () {
        if (
          newWorker.state === 'installed' &&
          navigator.serviceWorker.controller
        ) {
          waitingWorker = newWorker;
          notifyUpdateAvailable();
        }
      });
    });
  }

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange', function () {
      // After applyUpdate -> skipWaiting -> activated, controller swaps.
      // Reload once to make sure the page is running new assets.
      if (window.__pwa567Reloading) return;
      window.__pwa567Reloading = true;
      window.location.reload();
    });
    // Wait for Flutter to register its own service worker, then attach.
    var attachAttempts = 0;
    var attachInterval = setInterval(function () {
      attachAttempts += 1;
      navigator.serviceWorker.getRegistration().then(function (reg) {
        if (reg) {
          swRegistration = reg;
          trackWaiting(reg);
          clearInterval(attachInterval);
        } else if (attachAttempts > 40) {
          // ~20s. Give up gracefully.
          clearInterval(attachInterval);
        }
      });
    }, 500);
  }

  window.pwa567 = {
    canInstall: function () {
      return deferredInstallPrompt !== null;
    },
    isIOS: function () {
      return isIOS();
    },
    isStandalone: function () {
      return isStandalone();
    },
    install: function () {
      if (!deferredInstallPrompt) {
        return Promise.resolve('unavailable');
      }
      var prompt = deferredInstallPrompt;
      deferredInstallPrompt = null;
      prompt.prompt();
      return prompt.userChoice.then(function (choice) {
        return choice && choice.outcome ? choice.outcome : 'dismissed';
      });
    },
    updateAvailable: function () {
      return updateAvailable;
    },
    checkForUpdate: function () {
      if (!swRegistration) {
        return Promise.resolve(false);
      }
      return swRegistration
        .update()
        .then(function () {
          return updateAvailable;
        })
        .catch(function () {
          return false;
        });
    },
    applyUpdate: function () {
      // Flutter's service worker listens for the literal string 'skipWaiting'.
      if (waitingWorker) {
        waitingWorker.postMessage('skipWaiting');
      } else if (swRegistration && swRegistration.waiting) {
        swRegistration.waiting.postMessage('skipWaiting');
      } else {
        window.location.reload();
      }
    },
    primeOfflineCache: function () {
      // Asks Flutter's SW to download all known resources for offline use.
      if (navigator.serviceWorker && navigator.serviceWorker.controller) {
        navigator.serviceWorker.controller.postMessage('downloadOffline');
      }
    },
  };
})();
