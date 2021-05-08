// ==UserScript==
// @name     GitHub line-height
// @version  3
// @grant    none
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// ==/UserScript==

(() => {
  'use strict';

  const LINE_HEIGHT = '1.2';

  function addStylesheet() {
    let style = document.createElement('style');
    style.append(
      '.blob-num, .blob-code, .markdown-body .highlight pre, .markdown-body pre, \n',
      '.cm-s-github-light .CodeMirror-lines, textarea.file-editor-textarea {\n',
      `  line-height: ${LINE_HEIGHT};\n`,
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
