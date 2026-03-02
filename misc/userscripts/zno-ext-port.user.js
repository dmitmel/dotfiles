// ==UserScript==
// @name        Переглядач коментарів zno.osvita.ua
// @description Порт додатку для Google Chrome для безкоштовного перегляду коментарів на сайті zno.osvita.ua.
// @homepage    https://github.com/Blaumaus/zno-ext/tree/415add75513b734597ca8765bf1658b1b3bd087f
// @version     4
// @grant       none
// @match       https://zno.osvita.ua/*
// @run-at      document-end
// ==/UserScript==

(() => {
  'use strict';
  if (!(document.referrer != null && document.referrer.includes('zno.osvita.ua'))) {
    window.location.replace(location.href);
  }

  let comments = new Map();
  for (let item of document.querySelectorAll('.explanation')) {
    item.style.setProperty('display', 'inline-block', 'important');
    comments.set(item.id, item.innerHTML);
  }

  if (window.onload != null) {
    window.onload = null;
  } else {
    setInterval(() => {
      for (let item of document.querySelectorAll('.explanation')) {
        item.style.setProperty('display', 'inline-block', 'important');
        if (comments.has(item.id)) {
          item.innerHTML = comments.get(item.id);
        }
      }
    }, 1000);
  }
})();
