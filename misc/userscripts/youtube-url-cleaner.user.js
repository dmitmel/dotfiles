// ==UserScript==
// @name         YouTube URL cleaner
// @version      1.0
// @description  Strips parameters like ?t= and ?app= from the URLs of YouTube pages once they get loaded
// @icon         https://upload.wikimedia.org/wikipedia/commons/0/09/YouTube_full-color_icon_(2017).svg
// @match        https://www.youtube.com/*
// @match        https://youtube.com/*
// @match        https://m.youtube.com/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(() => {
  'use strict';

  // don't run inside iframes
  if (window.self !== window.top) {
    return;
  }

  function run() {
    let url = new URL(window.location.href);
    let dirty = false;

    function remove(param) {
      if (url.searchParams.has(param)) {
        url.searchParams.delete(param);
        dirty = true;
      }
    }

    if (url.pathname === '/watch') remove('t');
    // gets automatically set to `desktop` when opening `m.youtube.com` links in a desktop browser
    remove('app');
    // tracking parameters
    remove('si');
    remove('pp');

    if (dirty) {
      history.replaceState(history.state, '', url);
    }
  }

  if (document.readyState === 'complete') {
    run();
  } else {
    window.addEventListener('load', run);
  }

  window.addEventListener('yt-navigate-finish', run);
})();
