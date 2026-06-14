/**
 * luna.js — Rive companion (Luna) pro Unagy landing page.
 * Vanilla JS, žádný framework. Rive runtime z CDN (@rive-app/canvas@2 → window.rive).
 *
 * Záměrně přehráváme JEDINOU klidnou idle animaci ("anim_idle") ve smyčce —
 * žádné překrývání / rychlé cyklení. Postavu vybíráme přes data binding (RJ_Data).
 */

(function () {
  "use strict";

  var IDLE_ANIM = "anim_idle";

  var VIEW_MODEL = "RJ_Data";
  var CHARACTER_PROP = "CharacterSelect";
  var CHARACTER = "Orson";
  var FACE_PROP = "FaceEmotion";
  var FACE_DEFAULT = "Neutral";

  function initLuna() {
    var canvas = document.getElementById("luna-canvas");
    var fallback = document.getElementById("luna-fallback");
    if (!canvas) return;

    if (typeof window.rive === "undefined") {
      console.warn("luna.js: Rive runtime nedostupný, ponechávám fallback.");
      return;
    }

    var R = window.rive;
    var destroyed = false;

    function playIdle() {
      try { riveInstance.play(IDLE_ANIM); } catch (_) {}
    }

    var riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      // Nepřehráváme state machine ani autoplay — řídíme jen jednu idle animaci.
      autoplay: false,
      layout: new R.Layout({ fit: R.Fit.Contain, alignment: R.Alignment.Center }),
      onLoad: function () {
        // Bez resize renderuje Rive do špatně dimenzovaného plátna (často prázdné/rozmazané).
        try { riveInstance.resizeDrawingSurfaceToCanvas(); } catch (_) {}

        // Data binding: pevná postava + klidný výraz.
        try {
          var vm = riveInstance.viewModelByName(VIEW_MODEL);
          var inst = vm && vm.instance();
          if (inst) {
            riveInstance.bindViewModelInstance(inst);
            var charEnum = inst.enum(CHARACTER_PROP);
            if (charEnum) charEnum.value = CHARACTER;
            var faceEnum = inst.enum(FACE_PROP);
            if (faceEnum) faceEnum.value = FACE_DEFAULT;
          }
        } catch (_) {}

        canvas.classList.add("luna-loaded");
        if (fallback) fallback.style.display = "none";

        playIdle();
      },
      onStop: function () {
        // Idle udržuj ve smyčce (jediná přehrávaná animace).
        if (!destroyed) playIdle();
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
      destroyed = true;
      try { riveInstance.cleanup(); } catch (_) {}
    }, { once: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLuna);
  } else {
    initLuna();
  }
})();
