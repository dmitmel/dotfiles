// ==UserScript==
// @name     GitHub tab size 4
// @version  2
// @grant    GM_addStyle
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';
  const TAB_SIZE = '4';
  GM_addStyle(`
    * {
      -moz-tab-size: ${TAB_SIZE} !important;
      tab-size: ${TAB_SIZE} !important;
    }
  `);
})();
