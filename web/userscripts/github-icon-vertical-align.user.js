// ==UserScript==
// @name     GitHub icon vertical alignment fix
// @version  2
// @grant    GM_addStyle
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';
  GM_addStyle(`
    .btn-sm .octicon {
      vertical-align: middle;
    }
  `);
})();
