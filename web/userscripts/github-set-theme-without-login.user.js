// ==UserScript==
// @name     GitHub set theme without login
// @version  1
// @grant    none
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';

  let $html = document.documentElement;
  $html.dataset.colorMode = 'dark';
  $html.dataset.darkTheme = 'dark_dimmed';
  $html.dataset.lightTheme = 'light';
})();
