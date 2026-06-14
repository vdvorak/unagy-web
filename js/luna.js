/**
 * luna.js — Rive companion (Luna) pro Unagy landing page. (verze 8)
 * Vanilla JS, žádný framework. Rive runtime z CDN (@rive-app/canvas@2 → window.rive).
 *
 * Přehrávání (lineární animace, názvy z .riv):
 *   - na load jednou "wave" (zamávání)
 *   - pak "idle" jako klidný základ (smyčka)
 *   - občas (náhodný interval) jedna z VARIETY, po krátké době zpět na idle
 *   - stop() před každou animací → žádné překrývání
 *   - řízeno ČASOVAČEM, ne onStop (onStop = stop() způsoboval rekurzi a rychlé blikání)
 *
 * Debug: ?debug=1 vypíše state machine a animace přímo na stránku.
 */

(function () {
  "use strict";

  var VERSION = 8;

  var IDLE = "idle";
  var INTRO = "wave";                 // jednou po načtení
  var VARIETY = ["happy", "wave", "eat-cookie", "breathIN-OUT"];
  var VARIETY_MIN_MS = 7000;          // jak často oživit
  var VARIETY_MAX_MS = 13000;
  var ONESHOT_MS = 2600;              // přibližná délka one-shot animace než se vrátí idle

  var VIEW_MODEL = "RJ_Data";
  var CHARACTER_PROP = "CharacterSelect";
  var CHARACTER = "Orson";
  var FACE_PROP = "FaceEmotion";
  var FACE_DEFAULT = "Neutral";

  var DEBUG = /[?&]debug=1\b/.test(location.search);

  function randomBetween(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }
  function randomFrom(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
  }

  function showDebug(lines) {
    var box = document.createElement("pre");
    box.style.cssText =
      "position:fixed;left:8px;bottom:8px;z-index:9999;max-width:96vw;" +
      "max-height:50vh;overflow:auto;margin:0;padding:10px 12px;" +
      "background:rgba(0,0,0,.85);color:#8bff9b;font:12px/1.5 monospace;" +
      "border:1px solid #4a3a31;border-radius:8px;white-space:pre-wrap;";
    box.textContent = "luna debug (v" + VERSION + ")\n" + lines.join("\n");
    document.body.appendChild(box);
  }

  function initLuna() {
    console.log("luna.js v" + VERSION + " loaded");

    var canvas = document.getElementById("luna-canvas");
    var fallback = document.getElementById("luna-fallback");
    if (!canvas) return;

    if (typeof window.rive === "undefined") {
      console.warn("luna.js: Rive runtime nedostupný, ponechávám fallback.");
      if (DEBUG) showDebug(["CHYBA: window.rive nedostupný (CSP/CDN?)"]);
      return;
    }

    var R = window.rive;
    var destroyed = false;
    var varietyTimer = null;
    var oneShotTimer = null;

    function play(name) {
      // stop() ukončí vše ostatní → na plátně běží jen jedna animace (žádné překrývání)
      try { riveInstance.stop(); } catch (_) {}
      try { riveInstance.play(name); } catch (_) {}
    }

    function goIdle() {
      play(IDLE);
      scheduleVariety();
    }

    function scheduleVariety() {
      if (varietyTimer) clearTimeout(varietyTimer);
      varietyTimer = setTimeout(function () {
        if (destroyed) return;
        play(randomFrom(VARIETY));
        if (oneShotTimer) clearTimeout(oneShotTimer);
        oneShotTimer = setTimeout(function () {
          if (!destroyed) goIdle();
        }, ONESHOT_MS);
      }, randomBetween(VARIETY_MIN_MS, VARIETY_MAX_MS));
    }

    var riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      autoplay: false,                // přehrávání řídíme sami
      layout: new R.Layout({ fit: R.Fit.Contain, alignment: R.Alignment.Center }),
      onLoad: function () {
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

        // Intro: zamávání po načtení, pak přechod na idle.
        play(INTRO);
        oneShotTimer = setTimeout(function () {
          if (!destroyed) goIdle();
        }, ONESHOT_MS);

        if (DEBUG) {
          var lines = [];
          try {
            lines.push("stateMachines = " + JSON.stringify(riveInstance.stateMachineNames));
            lines.push("animations = " + JSON.stringify(riveInstance.animationNames));
          } catch (e) { lines.push("diag ERR " + e); }
          showDebug(lines);
        }
      },
      onLoadError: function () {
        console.warn("luna.js: luna.riv se nepodařilo načíst, ponechávám fallback.");
        if (DEBUG) showDebug(["CHYBA: luna.riv se nenačetl"]);
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
      if (oneShotTimer) clearTimeout(oneShotTimer);
      try { riveInstance.cleanup(); } catch (_) {}
    }, { once: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLuna);
  } else {
    initLuna();
  }
})();
