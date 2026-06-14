/**
 * luna.js — Rive companion (Luna) pro Unagy landing page.
 * Vanilla JS, žádný framework. Rive runtime z CDN (@rive-app/canvas@2 → window.rive).
 *
 * Postavu řídí VÝCHOZÍ state machine artboardu (má vlastní klidný idle/blink) —
 * jen ji necháme běžet (autoplay) a přes data binding vybereme postavu + klidný výraz.
 * Žádné vlastní střídání animací (to se přehrávalo přes sebe a moc rychle).
 */

(function () {
  "use strict";

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
    var riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      // Výchozí state machine se rozběhne sama a drží klidný idle.
      autoplay: true,
      layout: new R.Layout({ fit: R.Fit.Contain, alignment: R.Alignment.Center }),
      onLoad: function () {
        // Bez resize renderuje Rive do špatně dimenzovaného plátna (často prázdné/rozmazané).
        try { riveInstance.resizeDrawingSurfaceToCanvas(); } catch (_) {}

        // Data binding: pevná postava + klidný výraz (ne picker, jen výchozí stav).
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

        // DIAGNOSTIKA: vypiš state machine a jejich vstupy (kvůli napojení mávnutí).
        try {
          var sms = riveInstance.stateMachineNames || [];
          console.log("luna.js: stateMachineNames =", sms,
                      "| animationNames =", riveInstance.animationNames);
          sms.forEach(function (sm) {
            try {
              var inputs = (riveInstance.stateMachineInputs(sm) || []).map(function (i) {
                return i.name + " (type " + i.type + ")";
              });
              console.log("luna.js: inputs[" + sm + "] =", inputs);
            } catch (e) { console.warn("luna.js: inputs err", sm, e); }
          });
        } catch (e) { console.warn("luna.js: diag err", e); }
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
