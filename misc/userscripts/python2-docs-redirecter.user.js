// ==UserScript==
// @name     Python 2 to 3 documentation redirecter
// @version  1
// @grant    none
// @match    https://docs.python.org/2*
// @run-at   document-end
// ==/UserScript==

(() => {
  'use strict';

  let link = document.querySelector(
    'body > #outdated-warning > a[href^="https://docs.python.org/3"]',
  );
  if (link != null) {
    window.location.pathname = link.pathname;
  }
})();
