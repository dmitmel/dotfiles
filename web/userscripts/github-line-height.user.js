// ==UserScript==
// @name     GitHub line-height
// @version  6
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
      '.blob-num,\n',
      '.blob-code,\n',
      '.markdown-body .highlight pre,\n',
      '.markdown-body pre,\n',
      '.cm-s-github-light .CodeMirror-lines,\n',
      'textarea.file-editor-textarea,\n',
      '.react-code-text,\n',
      '.react-code-cell,\n',
      '.react-code-cell > button,\n',
      '.react-code-blob-table .react-code-cell,\n',
      '.react-code-blob-table .react-code-cell > button\n',
      '{\n',
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
