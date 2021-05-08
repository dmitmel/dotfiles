// ==UserScript==
// @name     GitHub tab size 4
// @version  3
// @grant    none
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';

  const TAB_SIZE = '4';

  function addStylesheet() {
    let style = document.createElement('style');
    style.append(
      '* {\n',
      `  -moz-tab-size: ${TAB_SIZE} !important;\n`,
      `  tab-size: ${TAB_SIZE} !important;\n`,
      '}\n',
    );
    document.head.appendChild(style);
  }

  if (document.readyState !== 'loading') {
    addStylesheet();
  } else {
    document.addEventListener('readystatechange', () => {
      if (document.readyState === 'loading') return;
      addStylesheet();
    });
  }
})();
