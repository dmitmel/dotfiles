// ==UserScript==
// @name     GitHub line-height
// @version  5
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
    style.textContent = [
      '.blob-num, .blob-code, .markdown-body .highlight pre, .markdown-body pre, \n',
      '.cm-s-github-light .CodeMirror-lines, textarea.file-editor-textarea,\n',
      '.react-code-cell, .react-code-cell > button, .react-code-blob-table \n',
      '.react-code-cell, .react-code-blob-table .react-code-cell > button {\n',
      `  line-height: ${LINE_HEIGHT};\n`,
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
