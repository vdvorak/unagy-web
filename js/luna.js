/**
 * luna.js — Rive companion (Luna) pro Unagy landing page. (verze 9)
 * Vanilla JS, žádný framework. Rive runtime z CDN (@rive-app/canvas@2 → window.rive).
 *
 * Přehrávání (lineární animace, názvy z .riv) — animace VŽDY doběhnou do konce:
 *   - na load jednou "wave", pak "idle" jako klidný základ (smyčka)
 *   - po náhodném intervalu se idle přeruší, přehraje se jedna VARIETY do konce,
 *     a pak zpět na idle
 *   - přepínání řízeno událostí onStop (konec animace) + příznakem pendingVariety,
 *     takže nikdy nehrají dvě animace přes sebe a žádná se neuřízne.
 *
 * Debug: ?debug=1 vypíše state machine a animace přímo na stránku.
 */

(function () {
  "use strict";

  var VERSION = 9;

  var IDLE = "idle";
  var INTRO = "wave";                 // jednou po načtení
  var VARIETY = ["happy", "wave", "eat-cookie", "breathIN-OUT"];
  var VARIETY_MIN_MS = 7000;          // jak dlouho zůstat v idle než přijde oživení
  var VARIETY_MAX_MS = 13000;

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
    var mode = "variety";        // "variety" = hraje one-shot, "idle" = klidný základ
    var pendingVariety = null;   // nastaveno před přerušením idle; onStop ho vyzvedne
    var varietyTimer = null;

    function scheduleVariety() {
      if (varietyTimer) clearTimeout(varietyTimer);
      varietyTimer = setTimeout(function () {
        if (destroyed) return;
        // Přeruš idle — onStop pak rozjede vybranou variety animaci.
        pendingVariety = randomFrom(VARIETY);
        try { riveInstance.stop(IDLE); } catch (_) {}
      }, randomBetween(VARIETY_MIN_MS, VARIETY_MAX_MS));
    }

    var riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      autoplay: false,
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

        // Intro zamávání; chová se jako variety → po doběhnutí přejde na idle.
        mode = "variety";
        try { riveInstance.play(INTRO); } catch (_) {}

        if (DEBUG) {
          var lines = [];
          try {
            lines.push("stateMachines = " + JSON.stringify(riveInstance.stateMachineNames));
            lines.push("animations = " + JSON.stringify(riveInstance.animationNames));
          } catch (e) { lines.push("diag ERR " + e); }
          showDebug(lines);
        }
      },
      onStop: function () {
        if (destroyed) return;

        if (pendingVariety) {
          // Idle bylo přerušeno kvůli oživení → přehraj vybranou animaci do konce.
          var v = pendingVariety;
          pendingVariety = null;
          mode = "variety";
          try { riveInstance.play(v); } catch (_) {}
          return;
        }

        if (mode === "variety") {
          // One-shot (intro/variety) doběhl → zpět na klidné idle a naplánuj další.
          mode = "idle";
          try { riveInstance.play(IDLE); } catch (_) {}
          scheduleVariety();
        } else {
          // idle není smyčka a doběhlo → znovu spusť (variety časovač běží dál).
          try { riveInstance.play(IDLE); } catch (_) {}
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
      try { riveInstance.cleanup(); } catch (_) {}
    }, { once: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLuna);
  } else {
    initLuna();
  }
})();
