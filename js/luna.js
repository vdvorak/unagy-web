/**
 * luna.js — Rive companion (Luna) pro Unagy landing page.
 * Vanilla JS, žádný framework. Rive runtime z CDN (@rive-app/canvas@2 → window.rive).
 *
 * Postava je řízená state machine + data binding (view model "RJ_Data"):
 *   - CharacterSelect: která postava (Orson/Merv) — pevná volba, ne picker
 *   - FaceEmotion: výraz (Neutral/Happy/Eating/…) — periodicky náhodně střídáme
 * State machine řídí rig, takže oživení NEděláme přes play(anim_*), ale přes enum.
 */

(function () {
  "use strict";

  var VIEW_MODEL = "RJ_Data";
  var CHARACTER_PROP = "CharacterSelect";
  var CHARACTER = "Orson";

  var FACE_PROP = "FaceEmotion";
  // Pozitivní/klidné výrazy (terapeutický tón). Neutral má vyšší váhu = převažuje klid.
  var FACE_VARIETY = ["Neutral", "Neutral", "Happy", "Happy", "Eating"];
  var VARIETY_MIN_MS = 4000;
  var VARIETY_MAX_MS = 8000;

  function randomBetween(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  function randomFrom(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
  }

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
    var varietyTimer = null;
    var faceEnum = null;

    function scheduleVariety() {
      if (destroyed || !faceEnum) return;
      varietyTimer = setTimeout(function () {
        varietyTimer = null;
        if (destroyed) return;
        try { faceEnum.value = randomFrom(FACE_VARIETY); } catch (_) {}
        scheduleVariety();
      }, randomBetween(VARIETY_MIN_MS, VARIETY_MAX_MS));
    }

    var riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      // Bez explicitního stateMachines přehraje Rive výchozí state machine artboardu.
      autoplay: true,
      layout: new R.Layout({ fit: R.Fit.Contain, alignment: R.Alignment.Center }),
      onLoad: function () {
        // Bez resize renderuje Rive do špatně dimenzovaného plátna (často prázdné/rozmazané).
        try { riveInstance.resizeDrawingSurfaceToCanvas(); } catch (_) {}

        // Data binding: pevná postava + reference na enum výrazu pro oživení.
        try {
          var vm = riveInstance.viewModelByName(VIEW_MODEL);
          var inst = vm && vm.instance();
          if (inst) {
            riveInstance.bindViewModelInstance(inst);
            var charEnum = inst.enum(CHARACTER_PROP);
            if (charEnum) charEnum.value = CHARACTER;
            faceEnum = inst.enum(FACE_PROP);
          }
          console.log("luna.js: data binding ok, faceEnum =", !!faceEnum);
        } catch (e) {
          console.warn("luna.js: data binding selhalo:", e);
        }

        canvas.classList.add("luna-loaded");
        if (fallback) fallback.style.display = "none";

        scheduleVariety();
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
      if (varietyTimer) clearTimeout(varietyTimer);
      try { riveInstance.cleanup(); } catch (_) {}
    }, { once: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLuna);
  } else {
    initLuna();
  }
})();
