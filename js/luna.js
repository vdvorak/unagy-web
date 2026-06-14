/**
 * luna.js — Rive companion (Luna) pro Unagy landing page. (verze 7)
 * Vanilla JS, žádný framework. Rive runtime z CDN (@rive-app/canvas@2 → window.rive).
 *
 * Model přehrávání (lineární animace, jejich názvy jsou z .riv souboru):
 *   - na load jednou "wave" (zamávání)
 *   - pak "idle" jako klidný základ
 *   - občas (náhodný interval) jedna z VARIETY, pak zpět na idle
 *   - před každou animací stop() → žádné překrývání
 * Postavu vybíráme přes data binding (RJ_Data / CharacterSelect).
 *
 * Debug: ?debug=1 vypíše state machine, vstupy a animace přímo na stránku.
 */

(function () {
  "use strict";

  var VERSION = 7;

  var IDLE = "idle";
  var INTRO = "wave"; // přehraje se jednou po načtení
  var VARIETY = ["happy", "wave", "eat-cookie", "breathIN-OUT"];
  var VARIETY_MIN_MS = 6000;
  var VARIETY_MAX_MS = 12000;

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
    var current = null;       // název právě hrané NE-idle animace, jinak null (= idle)
    var varietyTimer = null;

    function clearVarietyTimer() {
      if (varietyTimer) { clearTimeout(varietyTimer); varietyTimer = null; }
    }

    function play(name) {
      try { riveInstance.stop(); } catch (_) {}
      try { riveInstance.play(name); } catch (_) {}
    }

    function enterIdle() {     // klidný základ + naplánuj další oživení
      current = null;
      play(IDLE);
      scheduleVariety();
    }

    function playVariety() {
      if (destroyed) return;
      current = randomFrom(VARIETY);
      play(current);           // po doběhnutí onStop vrátí na idle
    }

    function scheduleVariety() {
      clearVarietyTimer();
      varietyTimer = setTimeout(playVariety, randomBetween(VARIETY_MIN_MS, VARIETY_MAX_MS));
    }

    var riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      autoplay: false,         // řídíme přehrávání sami
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

        // Intro: zamávání po načtení.
        current = INTRO;
        play(INTRO);

        if (DEBUG) {
          var lines = [];
          try {
            var sms = riveInstance.stateMachineNames || [];
            lines.push("stateMachines = " + JSON.stringify(sms));
            lines.push("animations = " + JSON.stringify(riveInstance.animationNames));
          } catch (e) { lines.push("diag ERR " + e); }
          showDebug(lines);
        }
      },
      onStop: function () {
        if (destroyed) return;
        // onStop přijde po doběhnutí one-shot animace (intro/variety).
        // Pokud zrovna nehrajeme variety/intro, jen udržuj idle ve smyčce.
        if (current !== null) {
          enterIdle();
        } else {
          play(IDLE);
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
      clearVarietyTimer();
      try { riveInstance.cleanup(); } catch (_) {}
    }, { once: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLuna);
  } else {
    initLuna();
  }
})();
