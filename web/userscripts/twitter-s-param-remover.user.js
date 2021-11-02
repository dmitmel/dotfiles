// ==UserScript==
// @name     twitter ?s=20 and ?t= query parameter remover
// @version  4
// @grant    none
// @match    https://twitter.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';
  let searchParams = new URLSearchParams(window.location.search);
  let dirty = false;
  for (let param of ['s', 't']) {
    if (searchParams.has(param)) {
      searchParams.delete(param);
      dirty = true;
    }
  }
  if (dirty) {
    window.location.search = searchParams.toString();
  }
})();
