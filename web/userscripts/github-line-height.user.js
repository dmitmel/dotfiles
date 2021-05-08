// ==UserScript==
// @name     GitHub line-height
// @version  2
// @grant    GM_addStyle
// @match    https://github.com/*
// @match    https://gist.github.com/*
// @run-at   document-start
// @supportURL		https://github.com/dmitmel/dotfiles/issues
// @updateURL		  https://github.com/dmitmel/dotfiles/raw/master/web/userscripts/github-line-height.user.js
// @downloadURL		https://github.com/dmitmel/dotfiles/raw/master/web/userscripts/github-line-height.user.js
// ==/UserScript==

(() => {
  'use strict';
  const LINE_HEIGHT = '1.2';
  GM_addStyle(`
    .blob-num, .blob-code, .markdown-body .highlight pre, .markdown-body pre,
    .cm-s-github-light .CodeMirror-lines, textarea.file-editor-textarea {
      line-height: ${LINE_HEIGHT};
    }
  `);
})();
