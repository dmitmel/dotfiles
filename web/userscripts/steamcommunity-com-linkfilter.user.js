// ==UserScript==
// @name     steamcommunity.com linkfilter disabler
// @version  1
// @grant    none
// @run-at   document-start
// @match    https://steamcommunity.com/linkfilter/*
// ==/UserScript==

(() => {
  'use strict';
  let searchParams = new URLSearchParams(window.location.search);
  let url = searchParams.get('url');
  if (url) {
    window.location.replace(url);
  }
})();
