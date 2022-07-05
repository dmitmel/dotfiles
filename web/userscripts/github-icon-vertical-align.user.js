// ==UserScript==
// @name     GitHub icon vertical alignment fix
// @version  4
// @grant    none
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';

  function addStylesheet() {
    let style = document.createElement('style');
    style.textContent = [
      //
      '.btn-sm .octicon {\n',
      '  vertical-align: middle;\n',
      '}\n',
    ].join('');
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
