// ==UserScript==
// @name     GitHub Codespaces hotkey (.) disabler
// @version  4
// @grant    none
// @match    https://github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';

  function blockEvent(/** @type {Event} */ e) {
    e.preventDefault();
    e.stopPropagation();
  }

  function main() {
    document.querySelectorAll('[data-hotkey]').forEach((elem) => {
      // Make sure only one listener is ever installed if this script gets
      // triggered repeatedly
      elem.removeEventListener('click', blockEvent, /* useCapture */ true);

      if (
        elem instanceof HTMLAnchorElement &&
        (elem.hostname === 'github.dev' ||
          (elem.hostname === 'github.com' && elem.pathname.startsWith('/codespaces/')))
      ) {
        elem.addEventListener('click', blockEvent, /* useCapture */ true);
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', main);
  } else {
    main();
  }

  document.addEventListener('turbo:load', main);
  document.addEventListener('turbo:frame-load', main);
})();
