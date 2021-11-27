// ==UserScript==
// @name     GitHub Codespaces hotkey (.) disabler
// @version  2
// @grant    none
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';

  function main() {
    document.querySelectorAll('.js-github-dev-shortcut').forEach((elem) => {
      delete elem.dataset.hotkey;
    });
  }

  if (document.readyState !== 'loading') {
    main();
  } else {
    document.addEventListener('readystatechange', () => {
      if (document.readyState === 'loading') return;
      main();
    });
  }
})();
