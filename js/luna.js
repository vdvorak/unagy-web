/**
 * luna.js — Rive companion (Luna) pro Unagy landing page.
 * Vanilla JS, žádný framework. Rive runtime z CDN (@rive-app/canvas@2 → window.rive).
 *
 * Pozn.: luna.riv řídí state machine "00main", která se přehrává sama (idle/blink…).
 * Lineární animace (anim_idle, anim_wave, …) nepřehráváme ručně.
 */

(function () {
  "use strict";

  var STATE_MACHINE = "00main";

  function initLuna() {
    var canvas = document.getElementById("luna-canvas");
    var fallback = document.getElementById("luna-fallback");
    if (!canvas) return;

    if (typeof window.rive === "undefined") {
      console.warn("luna.js: Rive runtime nedostupný, ponechávám fallback.");
      return;
    }

    var R = window.rive;
    var riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      autoplay: true,
      stateMachines: STATE_MACHINE,
      layout: new R.Layout({ fit: R.Fit.Contain, alignment: R.Alignment.Center }),
      onLoad: function () {
        // Bez resize renderuje Rive do špatně dimenzovaného plátna (často prázdné/rozmazané).
        try { riveInstance.resizeDrawingSurfaceToCanvas(); } catch (_) {}

        canvas.classList.add("luna-loaded");
        if (fallback) fallback.style.display = "none";
      },
      onLoadError: function () {
        console.warn("luna.js: luna.riv se nepodařilo načíst, ponechávám fallback.");
      },
    });

    var resizeRaf = null;
    window.addEventListener("resize", function () {
      if (resizeRaf) cancelAnimationFrame(resizeRaf);
      resizeRaf = requestAnimationFrame(function () {
        try { riveInstance.resizeDrawingSurfaceToCanvas(); } catch (_) {}
      });
    });

    window.addEventListener("pagehide", function () {
      try { riveInstance.cleanup(); } catch (_) {}
    }, { once: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLuna);
  } else {
    initLuna();
  }
})();
