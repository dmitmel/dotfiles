// ==UserScript==
// @name     GitHub Codespaces hotkey (.) disabler
// @version  3
// @grant    none
// @match    https://github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';

  function main() {
    for (let elem of document.querySelectorAll(
      '.js-github-dev-shortcut, .js-github-dev-new-tab-shortcut',
    )) {
      delete elem.dataset.hotkey;
    }
  }

  if (document.readyState !== 'loading') {
    main();
  } else {
    document.addEventListener('readystatechange', () => {
      if (document.readyState === 'loading') return;
      main();
    });
  }

  document.addEventListener('turbo:load', () => {
    main();
  });
})();
