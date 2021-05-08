// ==UserScript==
// @name     twitter ?s=20 remover
// @version  1
// @grant    none
// @match    https://twitter.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';
  let searchParams = new URLSearchParams(window.location.search);
  let strangeValue = searchParams.get('s');
  if (/[0-9]+/.test(strangeValue)) {
    searchParams.delete('s');
    window.location.search = searchParams.toString();
  }
})();
