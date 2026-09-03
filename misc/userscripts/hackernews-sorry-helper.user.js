// ==UserScript==
// @name         Sorry, Hacker News, not sorry
// @version      1.0
// @description  Attempts to fix the "Sorry." responses from Hacker News
// @icon         https://news.ycombinator.com/y18.svg
// @match        https://news.ycombinator.com/*
// @grant        GM_xmlhttpRequest
// @connect      hn.algolia.com
// @run-at       document-start
// ==/UserScript==

(() => {
  'use strict';

  async function main() {
    // <https://developer.mozilla.org/en-US/docs/Web/API/Document/readyState>
    while (document.readyState === 'loading') {
      await waitForEvent([document], 'readystatechange');
    }

    // // Make any page into a "Sorry." page for testing.
    // if (!isSorryPage()) {
    //   // <https://searchfox.org/firefox-main/rev/56036ccaf45df86c0155e9b9cf3d9f240888db0b/layout/style/res/plaintext.css>
    //   document.head.innerHTML = '<style>:root{color-scheme:light dark}</style>';
    //   document.body.innerHTML = '<pre>Sorry.</pre>';
    // }

    if (!isSorryPage()) {
      return;
    }

    let page = parseHnPageUrl();
    if (!(page && page.kind === 'item')) {
      addMessage(
        'The "sorry" helper script is sorry as well, it couldn\'t figure out what kind of page this is.',
      );
      return;
    }

    let tryToFix = makeButton('Try to fix');
    let openInBhn = makeButton('Open in bhn.vercel.app');
    addMessage(tryToFix, '  ', openInBhn);
    let { currentTarget: clickedButton } = await waitForEvent([tryToFix, openInBhn], 'click');
    tryToFix.disabled = true;
    openInBhn.disabled = true;

    // API docs: <https://hn.algolia.com/api>
    // Example response: <https://hn.algolia.com/api/v1/items/1>
    let algoliaApiUrl = `https://hn.algolia.com/api/v1/items/${page.id}`;

    let loadingSpinner = makeSpinner(['/', '-', '\\', '|'], 120);
    addMessage('Loading data from ', makeLink(algoliaApiUrl), '... ', loadingSpinner.element);
    let item;
    try {
      item = await request('GET', algoliaApiUrl);
      loadingSpinner.stop();
      loadingSpinner.setText('OK');
      console.log(algoliaApiUrl, item);
    } catch (err) {
      loadingSpinner.stop();
      loadingSpinner.setText(`ERROR: ${err.message}`);
      return;
    }

    // Initially I thought about walking the chain of `parent_id`s to get to the
    // top-level post, but apparently, the comment objects returned from the API
    // already have the ID of the post they belong to, stored in `story_id`.
    // Both of these fields were added in the same commit:
    // <https://github.com/algolia/hn-search/commit/56b8f78d236c23d8e1256e8176d254c063c4718e>,
    // so it's not like I need to or would be able to handle the situation where
    // `story_id` doesn't exist.
    if (!item || !item['story_id']) {
      addMessage("Algolia's API returned invalid data; can't help with this page, sorry.");
      return;
    }

    let redirectUrl;
    if (clickedButton === openInBhn) {
      redirectUrl = `https://bhn.vercel.app/post/${item['story_id']}`;
      if (page.id !== item['story_id']) redirectUrl += `#comment-${page.id}`;
    } else if (clickedButton === tryToFix) {
      if (page.id === item['story_id']) {
        addMessage(
          "Can't help with this page: it is already a top-level post, if it doesn't load - you are out of luck.",
        );
        return;
      }
      redirectUrl = new URL(window.location.href);
      redirectUrl.searchParams.set('id', item['story_id']);
      if (!redirectUrl.hash) redirectUrl.hash = `#${page.id}`;
    } else {
      addMessage('Sorry, what did you click?');
      return;
    }

    addMessage('Opening ', makeLink(redirectUrl), '...');
    window.location.assign(redirectUrl);
    // Execution of JavaScript code will continue after a redirect is initiated,
    // at least until the end of the current event loop tick, meaning that
    // we have some time to cover our bases.

    // It is actually possible for the user to return to this "Sorry." page in
    // its current state (i.e. with the now non-functional buttons and our
    // status messages): right before the user navigates away from a page, the
    // browser makes a full snapshot of the said page, including the state of
    // its DOM and its JavaScript heap, and puts it in the so-called bfcache
    // ("back/forward cache"), which it can use to instantly restore pages if
    // the user decides to go backwards or forwards through the navigation
    // history. So, if the user clicks the "back" button in their browser after
    // being redirected to a different page by us, they will return to this
    // page, but won't be able to click the "Try to fix" button again. To reset
    // this page when that happens, we can listen for the `pageshow` event,
    // which the browser will trigger if it restored this page from the bfcache.
    // More info about bfcache, `pageshow` and other such events:
    // <https://developer.mozilla.org/en-US/docs/Glossary/bfcache>
    // <https://web.dev/articles/bfcache>
    // <https://developer.mozilla.org/en-US/docs/Web/API/Window/pageshow_event>
    // <https://developer.chrome.com/docs/web-platform/page-lifecycle-api>
    // <https://developer.mozilla.org/en-US/docs/Web/API/Window/unload_event>
    waitForEvent([window], 'pageshow').then((event) => {
      // `persisted` will be `true` if the page got restored from bfcache
      if (event.persisted) {
        removeAllMessages();
        main();
      }
    });
  }

  function sleep(/** @type {number} */ timeout) {
    return new Promise((resolve) => setTimeout(resolve, timeout));
  }

  function waitForEvent(/** @type {EventTarget[]} */ targets, /** @type {string} */ eventName) {
    return new Promise((resolve) => {
      function listener(event) {
        for (let target of targets) target.removeEventListener(eventName, listener);
        resolve(event);
      }
      for (let target of targets) target.addEventListener(eventName, listener);
    });
  }

  function isSorryPage() {
    if (!document.body) {
      return false; // The page has not loaded yet -- can't tell
    }
    if (document.getElementById('hnmain')) {
      return false; // The page has loaded fine -- `#hnmain` is part of the normal layout
    }
    // Different browsers generate slightly different HTML layouts for
    // presenting plain-text responses from the server (use this snippet from
    // <https://stackoverflow.com/a/35917227/12005228> to check the full HTML:
    // `new XMLSerializer().serializeToString(document)`). For example,
    // Firefox wraps the text in a <pre> element without any attributes, and
    // Chrome adds some inline styles to this <pre>. I think the most simple and
    // straightforward way would be the most portable and reliable here.
    return document.body.innerText === 'Sorry.';
  }

  function parseHnPageUrl() {
    let url = new URL(window.location.href);

    if (url.pathname === '/item') {
      let id = url.searchParams.get('id');
      if (id && /^\d+$/.test(id)) {
        id = parseInt(id, 10);
        if (isFinite(id)) {
          return { kind: 'item', id };
        }
      }
    }

    return null;
  }

  function request(
    /** @type {string} */ method,
    /** @type {string} */ url,
    /** @type {number?} */ timeout = 10 * 1000,
  ) {
    return new Promise((resolve, reject) => {
      // <https://www.tampermonkey.net/documentation.php?locale=en&q=GM_xmlhttpRequest>
      // <https://violentmonkey.github.io/api/gm/#gm_xmlhttprequest>
      GM_xmlhttpRequest({
        method,
        url,
        timeout,
        onload(res) {
          if (200 <= res.status && res.status < 300) {
            try {
              resolve(JSON.parse(res.responseText));
            } catch (e) {
              reject(e);
            }
          } else {
            reject(new Error(`HTTP ${res.status} ${res.statusText}`));
          }
        },
        onerror: () => reject(new Error('Network error')),
        ontimeout: () => reject(new Error('Request timed out')),
      });
    });
  }

  const MESSAGE_ELEMENTS_CLASS = 'hackernews-sorry-user-js-message';

  function addMessage(/** @type {Array<string | Node>} */ ...children) {
    let pre = document.createElement('pre');
    pre.className = MESSAGE_ELEMENTS_CLASS;
    pre.append(...children);
    document.body.appendChild(pre);
    return pre;
  }

  function removeAllMessages() {
    // NOTE: The result of `getElementsByClassName` is a live collection that
    // gets updated together with the document if relevant elements get added or
    // removed. See <https://stackoverflow.com/a/26665963/12005228> and
    // <https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByClassName#:~:text=Warning,purposes>
    let buttons = document.getElementsByClassName(MESSAGE_ELEMENTS_CLASS);
    for (let i = buttons.length - 1; i >= 0; i--) {
      buttons.item(i).remove();
    }
  }

  function makeLink(/** @type {string | URL} */ url) {
    let a = document.createElement('a');
    a.href = String(url);
    a.append(url);
    return a;
  }

  function makeButton(/** @type {string} */ text) {
    let btn = document.createElement('button');
    btn.type = 'button';
    btn.style.font = 'inherit';
    btn.append(text);
    return btn;
  }

  function makeSpinner(/** @type {string[]} */ characters, /** @type {number} */ intervalMs) {
    let span = document.createElement('span');

    function setText(/** @type {string} */ text) {
      span.textContent = text;
    }

    let i = 0;
    function update() {
      setText(characters[i]);
      i = (i + 1) % characters.length;
    }

    update();

    let id = setInterval(update, intervalMs);
    function stop() {
      clearInterval(id);
    }

    return { element: span, setText, update, stop };
  }

  main();
})();
