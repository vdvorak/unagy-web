/**
 * luna.js — Rive companion initialization for Unagy landing page
 * Vanilla JS, no framework. Rive runtime loaded from CDN (@rive-app/canvas@2).
 * Companion animations from manifest: idle="idle", variety=["wave","eat-cookie","happy"]
 * Pattern adapted from UnagyDev/clients/web/src/companion/CompanionWidget.tsx (Solid-js removed).
 */

(function () {
  "use strict";

  var VARIETY_MIN_MS = 5000;
  var VARIETY_MAX_MS = 8000;
  var MAX_ANIM_MS = 3500;

  var IDLE_ANIM = "idle";
  var VARIETY_ANIMS = ["wave", "eat-cookie", "happy"];

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

    // Rive runtime must be available as window.rive (from @rive-app/canvas CDN build)
    if (typeof window.rive === "undefined") {
      console.warn("luna.js: Rive runtime not available, keeping fallback.");
      return;
    }

    var R = window.rive;
    var currentTrigger = null;
    var varietyTimeout = null;
    var animFallback = null;
    var riveInstance = null;
    var destroyed = false;

    function clearVarietyTimeout() {
      if (varietyTimeout !== null) {
        clearTimeout(varietyTimeout);
        varietyTimeout = null;
      }
    }

    function clearAnimFallback() {
      if (animFallback !== null) {
        clearTimeout(animFallback);
        animFallback = null;
      }
    }

    function playIdle() {
      if (!riveInstance) return;
      try { riveInstance.play(IDLE_ANIM); } catch (_) {}
    }

    function startAnimFallback(anim) {
      clearAnimFallback();
      animFallback = setTimeout(function () {
        animFallback = null;
        if (destroyed || currentTrigger !== anim) return;
        try { riveInstance && riveInstance.stop(anim); } catch (_) {}
        currentTrigger = null;
        playIdle();
        scheduleVariety();
      }, MAX_ANIM_MS);
    }

    function scheduleVariety() {
      clearVarietyTimeout();
      if (VARIETY_ANIMS.length === 0) return;
      varietyTimeout = setTimeout(function () {
        varietyTimeout = null;
        if (destroyed || !riveInstance || currentTrigger) return;
        var anim = randomFrom(VARIETY_ANIMS);
        currentTrigger = anim;
        try {
          riveInstance.stop(IDLE_ANIM);
          riveInstance.play(anim);
        } catch (_) {
          currentTrigger = null;
          playIdle();
          return;
        }
        startAnimFallback(anim);
      }, randomBetween(VARIETY_MIN_MS, VARIETY_MAX_MS));
    }

    riveInstance = new R.Rive({
      src: "/assets/luna/luna.riv",
      canvas: canvas,
      autoplay: false,
      layout: new R.Layout({
        fit: R.Fit.Contain,
        alignment: R.Alignment.Center,
      }),
      onLoad: function () {
        if (destroyed) return;

        // Show canvas, hide CSS fallback
        canvas.classList.add("luna-loaded");
        if (fallback) fallback.style.display = "none";

        playIdle();
        scheduleVariety();
      },
      onStop: function () {
        if (destroyed) return;
        // If no active trigger, idle ended (one-shot) — restart it
        if (!currentTrigger) {
          playIdle();
        } else {
          // Triggered anim finished
          clearAnimFallback();
          currentTrigger = null;
          playIdle();
          scheduleVariety();
        }
      },
      onLoadError: function () {
        // Asset failed to load — fallback stays visible
        console.warn("luna.js: Failed to load luna.riv, keeping fallback.");
      },
    });

    // Cleanup on page unload (GitHub Pages SPA: none; but good practice)
    window.addEventListener("pagehide", function () {
      destroyed = true;
      clearVarietyTimeout();
      clearAnimFallback();
      try { riveInstance && riveInstance.cleanup(); } catch (_) {}
    }, { once: true });
  }

  // Wait for DOM + Rive script to be ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initLuna);
  } else {
    initLuna();
  }
})();
